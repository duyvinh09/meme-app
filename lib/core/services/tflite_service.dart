import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AiCategoryResult {
  final String label;
  final double confidence; // 0.0 - 1.0

  const AiCategoryResult({
    required this.label,
    required this.confidence,
  });
}

/// Offline image classification service (Teachable Machine / TFLite).
///
/// Loads the model + labels once, then classifies an image file and returns
/// the top label with its confidence. Throws with a readable message when the
/// model/labels/image cannot be loaded or inference fails.
class TFLiteService {
  TFLiteService._();

  static final TFLiteService instance = TFLiteService._();

  static const String _modelAsset = 'assets/models/model.tflite';
  static const String _labelsAsset = 'assets/models/labels.txt';
  static const int inputSize = 224;

  Interpreter? _interpreter;
  List<String> _labels = [];
  Future<void>? _loading;
  Future<void> _queue = Future<void>.value();

  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  Future<void> ensureLoaded() async {
    if (isReady) return;
    if (_loading != null) return _loading;
    _loading = _load();
    try {
      await _loading;
    } finally {
      _loading = null;
    }
  }

  Future<void> _load() async {
    try {
      final labelsRaw = await rootBundle.loadString(_labelsAsset);
      _labels = labelsRaw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) => line.replaceFirst(RegExp(r'^\d+\s*'), '').trim())
          .toList();
    } catch (e) {
      throw StateError('Không thể tải file nhãn danh mục ($_labelsAsset): $e');
    }

    try {
      // Cấu hình rõ ràng chạy trên CPU (không dùng GPU delegate)
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelAsset, options: options);
    } catch (e) {
      throw StateError('Không thể khởi tạo mô hình TFLite ($_modelAsset): $e');
    }

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    debugPrint(
      'TFLiteService: model=$_modelAsset '
      'input=${inputTensor.shape} ${inputTensor.type.name} '
      'output=${outputTensor.shape} ${outputTensor.type.name} '
      'labels=${_labels.length}',
    );

    if (_labels.length != outputTensor.shape.last) {
      dispose();
      throw StateError('Model output does not match category labels');
    }
  }

  /// Classifies the image at [imagePath] and returns the top label with its
  /// confidence (0.0 - 1.0).
  ///
  /// Throws when the model, labels or image cannot be loaded, or inference
  /// fails — callers must surface the error to the user.
  Future<AiCategoryResult> classifyImage(String imagePath) {
    return _enqueue(() => _classifyImage(imagePath));
  }

  /// Classify a small, undecorated in-memory image without writing a file.
  Future<AiCategoryResult> classifyImageBytes(Uint8List bytes) {
    return _enqueue(() => _classifyImage('', imageBytes: bytes));
  }

  Future<AiCategoryResult> _enqueue(
      Future<AiCategoryResult> Function() action) {
    final result = _queue.then((_) => action());
    _queue =
        result.then<void>((_) {}, onError: (Object error, StackTrace stack) {
      debugPrint('Image inference failed (${error.runtimeType})');
    });
    return result;
  }

  Future<AiCategoryResult> _classifyImage(String imagePath,
      {Uint8List? imageBytes}) async {
    final file = File(imagePath);
    if (imageBytes == null && !await file.exists()) {
      throw ArgumentError('Tệp ảnh không tồn tại: $imagePath');
    }

    await ensureLoaded();
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Mô hình phân loại ảnh chưa được tải thành công');
    }

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final inputShape = inputTensor.shape; // [1, 224, 224, 3]
    final numClasses = outputTensor.shape.last;

    final targetHeight = inputShape.length >= 3 ? inputShape[1] : inputSize;
    final targetWidth = inputShape.length >= 3 ? inputShape[2] : inputSize;

    final rgbBytes = await compute(
      _readImageAsRgbBytes,
      _ImageParams(
          imagePath: imagePath,
          width: targetWidth,
          height: targetHeight,
          bytes: imageBytes),
    );

    Object input;
    if (inputTensor.type == TensorType.uint8) {
      // Quantized model: keep raw pixel values 0-255, no normalization.
      input = rgbBytes.reshape<int>(inputShape);
    } else {
      // Float model (Teachable Machine / MobileNet unquantized):
      // Chuẩn hóa [-1.0, 1.0]: (pixel / 127.5) - 1.0
      final floatInput = Float32List(rgbBytes.length);
      for (int i = 0; i < rgbBytes.length; i++) {
        floatInput[i] = (rgbBytes[i] / 127.5) - 1.0;
      }
      input = floatInput.reshape<double>(inputShape);
    }

    // tflite_flutter writes results into the container passed to run(),
    // so scores must be read back from this object after inference.
    final isUint8Output = outputTensor.type == TensorType.uint8;
    final scores = await compute(_runCategoryInference,
        (interpreter.address, input, numClasses, isUint8Output));
    int bestIndex = 0;
    double bestScore = -1.0;
    for (int i = 0; i < numClasses; i++) {
      final score = scores[i].toDouble();
      if (!score.isNaN && score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    // Quantized output is a byte (0-255), convert to percentage.
    final confidence = isUint8Output
        ? (bestScore / 255.0).clamp(0.0, 1.0)
        : bestScore.clamp(0.0, 1.0);

    final label = (bestIndex >= 0 && bestIndex < _labels.length)
        ? _labels[bestIndex]
        : 'Khác';
    return AiCategoryResult(label: label, confidence: confidence);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = [];
  }
}

List<num> _runCategoryInference((int, Object, int, bool) params) {
  final (address, input, count, quantized) = params;
  final interpreter = Interpreter.fromAddress(address);
  final output = quantized
      ? <List<int>>[List<int>.filled(count, 0)]
      : <List<double>>[List<double>.filled(count, 0)];
  interpreter.run(input, output);
  // Native interpreter belongs to the app-level service, not this isolate.
  return output[0];
}

class _ImageParams {
  final Uint8List? bytes;
  final String imagePath;
  final int width;
  final int height;

  const _ImageParams({
    this.bytes,
    required this.imagePath,
    required this.width,
    required this.height,
  });
}

/// Runs on a background isolate: decodes the image file and resizes it to
/// [params.width]x[params.height], returning raw RGB bytes (3 channels, 0-255, no alpha).
Uint8List _readImageAsRgbBytes(_ImageParams params) {
  final file = File(params.imagePath);
  if (params.bytes == null && !file.existsSync()) {
    throw ArgumentError('Không tìm thấy tệp ảnh: ${params.imagePath}');
  }
  final bytes = params.bytes ?? file.readAsBytesSync();
  var decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw ArgumentError('Không đọc được định dạng ảnh: ${params.imagePath}');
  }

  // Chuẩn hóa hướng xoay EXIF để ảnh chụp chân dung/ngang không bị xoay lệch
  decoded = img.bakeOrientation(decoded);

  final resized = img.copyResize(
    decoded,
    width: params.width,
    height: params.height,
    interpolation: img.Interpolation.average,
  );

  final result = Uint8List(params.width * params.height * 3);
  int index = 0;
  for (int y = 0; y < params.height; y++) {
    for (int x = 0; x < params.width; x++) {
      final pixel = resized.getPixel(x, y);
      result[index++] = pixel.r.toInt();
      result[index++] = pixel.g.toInt();
      result[index++] = pixel.b.toInt();
    }
  }
  return result;
}
