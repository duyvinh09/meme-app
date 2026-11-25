import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Isolate-safe input. No platform channels or UI objects cross into rendering.
class PhotoboothComposition {
  const PhotoboothComposition({
    required this.overlay,
    required this.photos,
    required this.slots,
    this.masks = const [],
    this.outputSize = 1080,
  });

  final Uint8List overlay;
  final List<Uint8List> photos;
  final List<List<int>> slots;
  final List<Uint8List> masks;
  final int outputSize;
}

class PhotoboothComposite {
  const PhotoboothComposite(this.image, this.thumbnail);
  final Uint8List image;
  final Uint8List thumbnail;
}

/// Match the source template's cover crop, slot order, alpha, and ownership masks.
PhotoboothComposite composePhotobooth(PhotoboothComposition input) {
  final decodedOverlay = _decodeImage(input.overlay);
  if (input.photos.length > input.slots.length) {
    throw const FormatException('Invalid photobooth composition');
  }
  final size = input.outputSize;
  final scale = size / 1080;
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(235, 238, 245, 255));
  for (var i = 0; i < input.photos.length; i++) {
    final decoded = _decodeImage(input.photos[i]);
    final photo = img.bakeOrientation(decoded);
    final slot = input.slots[i];
    final width = (slot[2] * scale).round().clamp(1, size);
    final height = (slot[3] * scale).round().clamp(1, size);
    final targetRatio = width / height;
    final sourceRatio = photo.width / photo.height;
    final cropWidth = sourceRatio > targetRatio
        ? (photo.height * targetRatio).round()
        : photo.width;
    final cropHeight = sourceRatio > targetRatio
        ? photo.height
        : (photo.width / targetRatio).round();
    final cropped = img.copyCrop(photo,
        x: (photo.width - cropWidth) ~/ 2,
        y: (photo.height - cropHeight) ~/ 2,
        width: cropWidth,
        height: cropHeight);
    final fitted = img.copyResize(cropped,
        width: width, height: height, interpolation: img.Interpolation.average);
    img.Image? mask;
    if (input.masks.isNotEmpty) {
      if (input.masks.length != input.slots.length) {
        throw const FormatException('Missing slot ownership masks');
      }
      final decodedMask = _decodeImage(input.masks[i]);
      mask = img.copyResize(decodedMask, width: size, height: size);
    }
    img.compositeImage(canvas, fitted,
        dstX: (slot[0] * scale).round(),
        dstY: (slot[1] * scale).round(),
        mask: mask,
        maskChannel: img.Channel.alpha);
  }
  final overlay = img.copyResize(decodedOverlay,
      width: size, height: size, interpolation: img.Interpolation.average);
  img.compositeImage(canvas, overlay);
  return PhotoboothComposite(
    img.encodeJpg(canvas, quality: 92),
    img.encodeJpg(img.copyResize(canvas, width: 180, height: 180), quality: 85),
  );
}

img.Image _decodeImage(Uint8List bytes) {
  if (bytes.length < 12) throw const FormatException('Truncated image data');
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Unsupported image data');
    return decoded;
  } on RangeError catch (error) {
    throw FormatException('Malformed image data: $error');
  }
}
