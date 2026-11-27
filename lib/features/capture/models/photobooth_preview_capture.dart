import 'dart:io';
import 'dart:typed_data';

import '../services/photobooth_canvas.dart';

/// Preview owns cheap image-handle clones while the camera finishes its export.
class PhotoboothPreviewCapture {
  PhotoboothPreviewCapture({required PhotoboothScene scene, required this.file})
      : scene = PhotoboothScene(
          frame: scene.frame,
          shots: scene.shots
              .map((shot) => PhotoboothShot(
                    shot.image.clone(),
                    mirrored: shot.mirrored,
                  ))
              .toList(growable: false),
          artwork: scene.artwork == null
              ? null
              : PhotoboothArtwork(
                  scene.artwork!.overlay.clone(),
                  scene.artwork!.masks
                      .map((mask) => mask.clone())
                      .toList(growable: false),
                ),
        );

  final PhotoboothScene scene;
  final Future<File?> file;
  bool _disposed = false;
  Future<Uint8List>? _categoryImage;

  Future<Uint8List> get categoryImage =>
      _categoryImage ??= createPhotoboothCategoryImage(scene);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final shot in scene.shots) {
      shot.image.dispose();
    }
    scene.artwork?.dispose();
  }
}
