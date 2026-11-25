import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Matches the center square shown by CameraPreview's BoxFit.cover.
/// Keep an upright, readable image for OCR instead of mirroring receipt text.
Future<File> cropReceiptFrame(File source) async {
  final path = await compute(_cropReceiptFrame, source.path);
  return File(path);
}

String _cropReceiptFrame(String sourcePath) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(File(sourcePath).readAsBytesSync());
  } on RangeError {
    throw const FormatException('Could not decode receipt capture');
  }
  if (decoded == null) {
    throw const FormatException('Could not decode receipt capture');
  }
  final image = img.bakeOrientation(decoded);
  final side = math.min(image.width, image.height);
  final square = img.copyCrop(image,
      x: (image.width - side) ~/ 2,
      y: (image.height - side) ~/ 2,
      width: side,
      height: side);
  final output = File('$sourcePath.receipt.jpg');
  output.writeAsBytesSync(img.encodeJpg(square, quality: 95), flush: true);
  return output.path;
}
