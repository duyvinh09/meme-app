import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/photobooth_frame.dart';
import '../services/photobooth_canvas.dart';

class PhotoboothController extends ChangeNotifier {
  PhotoboothFrame? _frame;
  final List<PhotoboothShot> _shots = [];
  PhotoboothArtwork? _artwork;
  Future<void>? _artworkReady;
  Object? _artworkError;
  bool _busy = false;
  bool _disposed = false;
  int _generation = 0;

  PhotoboothFrame? get frame => _frame;
  int get sessionId => _generation;
  int get capturedCount => _shots.length;
  List<PhotoboothShot> get shots => List.unmodifiable(_shots);
  PhotoboothArtwork? get artwork => _artwork;
  bool get busy => _busy;
  bool get complete => _frame != null && capturedCount == _frame!.shotCount;

  void select(PhotoboothFrame? value) {
    if (_busy || _disposed) return;
    _replace(value);
  }

  /// Explicit cancellation is allowed even while a camera image is arriving.
  void clear() {
    if (!_disposed) _replace(null);
  }

  void _replace(PhotoboothFrame? value) {
    _generation++;
    _releaseImages();
    _frame = value;
    _busy = false;
    _artworkError = null;
    _artworkReady = value == null ? null : _prepareArtwork(value, _generation);
    notifyListeners();
  }

  Future<void> _prepareArtwork(PhotoboothFrame frame, int generation) async {
    final decoded = <PhotoboothShot>[];
    try {
      for (final path in [frame.asset, ...frame.masks]) {
        final data = await rootBundle.load(path);
        final image = await decodePhotoboothImage(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        decoded.add(PhotoboothShot(image));
        if (_disposed || generation != _generation) {
          for (final shot in decoded) {
            shot.image.dispose();
          }
          return;
        }
      }
      if (_disposed || generation != _generation) {
        for (final shot in decoded) {
          shot.image.dispose();
        }
        return;
      }
      _artwork = PhotoboothArtwork(decoded.first.image,
          decoded.skip(1).map((shot) => shot.image).toList(growable: false));
      notifyListeners();
    } catch (error, stack) {
      for (final shot in decoded) {
        shot.image.dispose();
      }
      if (!_disposed && generation == _generation) {
        _artworkError = error;
        debugPrint('Photobooth artwork failed: $error\n$stack');
        notifyListeners();
      }
    }
  }

  /// Decode this shot once, show it immediately, and export only on the last slot.
  Future<File?> addPhoto(File photo,
      {bool mirrored = false, ValueChanged<PhotoboothScene>? onReady}) async {
    final selected = _frame;
    if (_busy || selected == null || complete || _disposed) return null;
    final generation = _generation;
    _busy = true;
    PhotoboothShot? added;
    try {
      final image = await decodePhotoboothImage(await photo.readAsBytes());
      if (_disposed || generation != _generation) {
        image.dispose();
        return null;
      }
      added = PhotoboothShot(image, mirrored: mirrored);
      _shots.add(added);
      notifyListeners();
      if (!complete) return null;
      await _artworkReady;
      if (_disposed || generation != _generation) return null;
      if (_artworkError != null || _artwork == null) {
        throw StateError('Could not prepare frame: $_artworkError');
      }
      final scene =
          PhotoboothScene(frame: selected, shots: _shots, artwork: _artwork);
      onReady?.call(scene);
      final bytes = await exportPhotoboothJpeg(scene);
      if (_disposed || generation != _generation) return null;
      final directory = await getTemporaryDirectory();
      if (_disposed || generation != _generation) return null;
      final session = await directory.createTemp('photobooth_');
      final output =
          await File('${session.path}/photo.jpg').writeAsBytes(bytes);
      if (_disposed || generation != _generation) return null;
      return output;
    } catch (_) {
      if (!_disposed && generation == _generation && added != null) {
        _shots.remove(added);
        added.image.dispose();
      }
      rethrow;
    } finally {
      if (!_disposed && generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  void _releaseImages() {
    for (final shot in _shots) {
      shot.image.dispose();
    }
    _shots.clear();
    _artwork?.dispose();
    _artwork = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _releaseImages();
    super.dispose();
  }
}
