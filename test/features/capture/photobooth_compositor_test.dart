import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meme_app/features/capture/services/photobooth_compositor.dart';

Uint8List solid(int red, int green, int blue, {int alpha = 255}) {
  final image = img.Image(width: 80, height: 80, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(red, green, blue, alpha));
  return img.encodePng(image);
}

void main() {
  test('Compose_FourSlots_PreservesCaptureOrderAndOverlay', () {
    final overlay = img.decodePng(solid(0, 0, 0, alpha: 0))!;
    img.fillRect(overlay,
        x1: 0, y1: 0, x2: 79, y2: 5, color: img.ColorRgba8(255, 255, 255, 255));
    final result = composePhotobooth(PhotoboothComposition(
      overlay: img.encodePng(overlay),
      photos: [
        solid(230, 0, 0),
        solid(0, 230, 0),
        solid(0, 0, 230),
        solid(230, 230, 0)
      ],
      slots: const [
        [0, 0, 540, 540],
        [540, 0, 540, 540],
        [0, 540, 540, 540],
        [540, 540, 540, 540]
      ],
      outputSize: 80,
    ));
    final output = img.decodeJpg(result.image)!;
    expect(output.getPixel(20, 20).r, greaterThan(200));
    expect(output.getPixel(60, 20).g, greaterThan(200));
    expect(output.getPixel(20, 60).b, greaterThan(200));
    expect(output.getPixel(60, 60).r, greaterThan(200));
    expect(output.getPixel(60, 60).g, greaterThan(200));
    expect(output.getPixel(40, 2).b, greaterThan(220));
    expect(img.decodeJpg(result.thumbnail)!.width, 180);
  });

  test('Compose_OverlappingSlots_MasksKeepEachPhotoInItsOwnOpening', () {
    final left = img.decodePng(solid(0, 0, 0, alpha: 0))!;
    final right = img.decodePng(solid(0, 0, 0, alpha: 0))!;
    img.fillRect(left,
        x1: 0,
        y1: 0,
        x2: 39,
        y2: 79,
        color: img.ColorRgba8(255, 255, 255, 255));
    img.fillRect(right,
        x1: 40,
        y1: 0,
        x2: 79,
        y2: 79,
        color: img.ColorRgba8(255, 255, 255, 255));
    final result = composePhotobooth(PhotoboothComposition(
      overlay: solid(0, 0, 0, alpha: 0),
      photos: [solid(230, 0, 0), solid(0, 0, 230)],
      slots: const [
        [0, 0, 1080, 1080],
        [0, 0, 1080, 1080]
      ],
      masks: [img.encodePng(left), img.encodePng(right)],
      outputSize: 80,
    ));
    final output = img.decodeJpg(result.image)!;
    expect(output.getPixel(20, 40).r, greaterThan(200));
    expect(output.getPixel(20, 40).b, lessThan(30));
    expect(output.getPixel(60, 40).b, greaterThan(200));
    expect(output.getPixel(60, 40).r, lessThan(30));
  });

  test('Compose_WidePhoto_CenterCropsInsteadOfStretching', () {
    final photo = img.Image(width: 160, height: 80);
    img.fill(photo, color: img.ColorRgb8(230, 0, 0));
    img.fillRect(photo,
        x1: 40, y1: 0, x2: 119, y2: 79, color: img.ColorRgb8(0, 230, 0));
    final result = composePhotobooth(PhotoboothComposition(
      overlay: solid(0, 0, 0, alpha: 0),
      photos: [img.encodePng(photo)],
      slots: const [
        [0, 0, 1080, 1080]
      ],
      outputSize: 80,
    ));
    final output = img.decodeJpg(result.image)!;
    expect(output.getPixel(5, 40).g, greaterThan(200));
    expect(output.getPixel(74, 40).g, greaterThan(200));
  });

  test('Compose_PartialSequence_LeavesRemainingSlotEmpty', () {
    final result = composePhotobooth(PhotoboothComposition(
      overlay: solid(0, 0, 0, alpha: 0),
      photos: [solid(230, 0, 0)],
      slots: const [
        [0, 0, 540, 1080],
        [540, 0, 540, 1080]
      ],
      outputSize: 80,
    ));
    final output = img.decodeJpg(result.image)!;
    expect(output.getPixel(20, 40).r, greaterThan(200));
    expect(output.getPixel(60, 40).g, greaterThan(220));
    expect(output.getPixel(60, 40).b, greaterThan(220));
  });
}
