import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meme_app/features/capture/services/receipt_frame_crop.dart';

void main() {
  late Directory temporary;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('receipt_roi_');
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });
  for (final portrait in [true, false]) {
    test('Only the visible center square reaches the saved receipt ($portrait)',
        () async {
      final image =
          img.Image(width: portrait ? 300 : 700, height: portrait ? 700 : 300);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      img.fillRect(image,
          x1: portrait ? 0 : 200,
          y1: portrait ? 200 : 0,
          x2: portrait ? 299 : 499,
          y2: portrait ? 499 : 299,
          color: img.ColorRgb8(255, 255, 255));
      final original = img.encodePng(image);
      final source =
          await File('${temporary.path}/capture.png').writeAsBytes(original);
      final cropped = await cropReceiptFrame(source);
      final result = img.decodeJpg(await cropped.readAsBytes())!;
      expect(result.width, 300);
      expect(result.height, 300);
      expect(cropped.path, isNot(source.path));
      expect(await source.readAsBytes(), original);
      for (final point in [
        [0, 0],
        [150, 150],
        [299, 299]
      ]) {
        final pixel = result.getPixel(point[0], point[1]);
        expect(pixel.g, greaterThan(240));
        expect(pixel.b, greaterThan(240));
      }
    });
  }
  test('Invalid capture fails instead of returning the uncropped source',
      () async {
    final source =
        await File('${temporary.path}/bad.jpg').writeAsBytes([1, 2, 3]);
    await expectLater(cropReceiptFrame(source), throwsFormatException);
  });
}
