import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import '../models/photobooth_frame.dart';

class PhotoboothShot {
  const PhotoboothShot(this.image, {this.mirrored = false});
  final ui.Image image;
  final bool mirrored;
}

class PhotoboothArtwork {
  const PhotoboothArtwork(this.overlay, this.masks);
  final ui.Image overlay;
  final List<ui.Image> masks;

  void dispose() {
    overlay.dispose();
    for (final mask in masks) {
      mask.dispose();
    }
  }
}

/// One scene drives both the small live view and the final full-size export.
@immutable
class PhotoboothScene {
  PhotoboothScene(
      {required this.frame, required List<PhotoboothShot> shots, this.artwork})
      : shots = List.unmodifiable(shots);
  final PhotoboothFrame frame;
  final List<PhotoboothShot> shots;
  final PhotoboothArtwork? artwork;

  @override
  bool operator ==(Object other) =>
      other is PhotoboothScene &&
      other.frame == frame &&
      other.artwork == artwork &&
      listEquals(other.shots, shots);
  @override
  int get hashCode => Object.hash(frame, artwork, Object.hashAll(shots));
}

class PhotoboothCanvasPainter extends CustomPainter {
  PhotoboothCanvasPainter(this.scene);
  final PhotoboothScene scene;
  final _imagePaint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  final _maskPaint = ui.Paint()
    ..blendMode = ui.BlendMode.dstIn
    ..filterQuality = ui.FilterQuality.medium;
  final _layerPaint = ui.Paint();
  final _backgroundPaint = ui.Paint()..color = const ui.Color(0xFFEBEEF5);
  static const _bounds = ui.Rect.fromLTWH(0, 0, 1080, 1080);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.save();
    canvas.scale(size.width / 1080, size.height / 1080);
    canvas.drawRect(_bounds, _backgroundPaint);
    for (var i = 0; i < scene.shots.length; i++) {
      final shot = scene.shots[i];
      final slot = scene.frame.slots[i];
      final mask = scene.artwork?.masks;
      final masked = mask != null && mask.isNotEmpty;
      if (masked) canvas.saveLayer(slot, _layerPaint);
      canvas.save();
      if (shot.mirrored) {
        canvas.translate(slot.left + slot.right, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(
          shot.image, _coverCrop(shot.image, slot), slot, _imagePaint);
      canvas.restore();
      if (masked) {
        canvas.drawImageRect(
            mask[i], _imageBounds(mask[i]), _bounds, _maskPaint);
        canvas.restore();
      }
    }
    final overlay = scene.artwork?.overlay;
    if (overlay != null) {
      canvas.drawImageRect(
          overlay, _imageBounds(overlay), _bounds, _imagePaint);
    }
    canvas.restore();
  }

  // Match the square camera viewport first, then cover the selected frame slot.
  ui.Rect _coverCrop(ui.Image image, ui.Rect slot) {
    final side = image.width < image.height ? image.width : image.height;
    final ratio = slot.width / slot.height;
    final width = ratio < 1 ? side * ratio : side.toDouble();
    final height = ratio > 1 ? side / ratio : side.toDouble();
    return ui.Rect.fromCenter(
        center: ui.Offset(image.width / 2, image.height / 2),
        width: width,
        height: height);
  }

  ui.Rect _imageBounds(ui.Image image) =>
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  @override
  bool shouldRepaint(covariant PhotoboothCanvasPainter oldDelegate) =>
      oldDelegate.scene != scene;
}

Future<ui.Image> decodePhotoboothImage(Uint8List bytes) async {
  if (bytes.length < 12) throw const FormatException('Truncated image data');
  try {
    final codec = await ui.instantiateImageCodec(bytes,
        targetWidth: 1080, allowUpscaling: false);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  } on Exception catch (error) {
    throw FormatException('Could not decode photobooth image: $error');
  }
}

Future<Uint8List> exportPhotobooth(PhotoboothScene scene) async {
  final recorder = ui.PictureRecorder();
  PhotoboothCanvasPainter(scene)
      .paint(ui.Canvas(recorder), const ui.Size(1080, 1080));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(1080, 1080);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode photobooth image');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

/// Keep the immediate canvas preview independent of upload-file encoding.
Future<Uint8List> exportPhotoboothJpeg(PhotoboothScene scene) async {
  final png = await exportPhotobooth(scene);
  return compute(_encodePhotoboothJpeg, png);
}

Uint8List _encodePhotoboothJpeg(Uint8List png) {
  final image = img.decodePng(png);
  if (image == null) throw StateError('Could not decode photobooth export');
  // JPEG has no alpha: flatten transparent parts onto white explicitly.
  final flattened = img.Image(width: image.width, height: image.height);
  img.fill(flattened, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(flattened, image);
  for (final quality in [92, 85, 75, 60]) {
    final bytes = img.encodeJpg(flattened, quality: quality);
    if (bytes.length < 6000000) return bytes;
  }
  throw StateError('Photobooth JPEG exceeds the 6 MB upload limit');
}
