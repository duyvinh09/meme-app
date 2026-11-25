import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meme_app/features/capture/models/photobooth_frame.dart';
import 'package:meme_app/features/capture/services/photobooth_canvas.dart';

img.Image solid(int red, int green, int blue, {int alpha = 255}) {
  final image = img.Image(width: 32, height: 32, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(red, green, blue, alpha));
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const frame = PhotoboothFrame(
      id: 'two',
      name: 'two',
      asset: '',
      thumbnail: '',
      slots: [
        Rect.fromLTWH(0, 0, 1080, 1080),
        Rect.fromLTWH(0, 0, 1080, 1080)
      ]);

  test('NativeCanvas_OverlappingMasks_KeepBothPhotosAndOverlay', () async {
    final left = solid(0, 0, 0, alpha: 0);
    final right = solid(0, 0, 0, alpha: 0);
    final overlay = solid(0, 0, 0, alpha: 0);
    img.fillRect(left,
        x1: 0,
        y1: 0,
        x2: 15,
        y2: 31,
        color: img.ColorRgba8(255, 255, 255, 255));
    img.fillRect(right,
        x1: 16,
        y1: 0,
        x2: 31,
        y2: 31,
        color: img.ColorRgba8(255, 255, 255, 255));
    img.fillRect(overlay,
        x1: 0, y1: 0, x2: 31, y2: 2, color: img.ColorRgba8(255, 255, 255, 255));
    final images = await Future.wait([
      overlay,
      left,
      right,
      solid(230, 0, 0),
      solid(0, 0, 230),
    ].map((image) => decodePhotoboothImage(img.encodePng(image))));
    addTearDown(() {
      for (final image in images) {
        image.dispose();
      }
    });
    final bytes = await exportPhotobooth(PhotoboothScene(
      frame: frame,
      shots: [PhotoboothShot(images[3]), PhotoboothShot(images[4])],
      artwork: PhotoboothArtwork(images[0], [images[1], images[2]]),
    ));
    final output = img.decodePng(bytes)!;
    expect(output.getPixel(270, 540).r, greaterThan(220));
    expect(output.getPixel(270, 540).b, lessThan(10));
    expect(output.getPixel(810, 540).b, greaterThan(220));
    expect(output.getPixel(810, 540).r, lessThan(10));
    expect(output.getPixel(540, 20).g, greaterThan(245));
  });

  test('NativeCanvas_FrontCamera_MirrorsSquareCropOnce', () async {
    final photo = img.Image(width: 80, height: 40);
    img.fill(photo, color: img.ColorRgb8(0, 230, 0));
    img.fillRect(photo,
        x1: 20, y1: 0, x2: 39, y2: 39, color: img.ColorRgb8(230, 0, 0));
    img.fillRect(photo,
        x1: 40, y1: 0, x2: 59, y2: 39, color: img.ColorRgb8(0, 0, 230));
    final image = await decodePhotoboothImage(img.encodePng(photo));
    addTearDown(image.dispose);
    const single = PhotoboothFrame(
        id: 'single',
        name: '',
        asset: '',
        thumbnail: '',
        slots: [Rect.fromLTWH(0, 0, 1080, 1080)]);
    final bytes = await exportPhotobooth(PhotoboothScene(
        frame: single, shots: [PhotoboothShot(image, mirrored: true)]));
    final output = img.decodePng(bytes)!;
    expect(output.getPixel(270, 540).b, greaterThan(220));
    expect(output.getPixel(810, 540).r, greaterThan(220));
    expect(output.getPixel(50, 540).g, lessThan(10));
    expect(output.getPixel(1030, 540).g, lessThan(10));
  });
}
