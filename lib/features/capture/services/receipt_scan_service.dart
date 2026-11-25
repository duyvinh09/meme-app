import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/receipt_scan_result.dart';
import 'receipt_amount_reader.dart';
import 'receipt_classifier.dart';
import 'receipt_layout.dart';

class ReceiptScanService {
  static Future<ReceiptClassifier>? _model;
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  Future<ReceiptScanResult> scan(File file) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer
          .processImage(InputImage.fromFile(file))
          .timeout(const Duration(seconds: 20));
      final lines = result.blocks
          .expand((block) => block.lines)
          .map((line) => ReceiptLine(line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              width: line.boundingBox.width,
              height: line.boundingBox.height,
              angle: line.angle ?? 0))
          .toList();
      if (lines.isEmpty && result.text.trim().isNotEmpty) {
        lines.addAll(result.text
            .split('\n')
            .where((text) => text.trim().isNotEmpty)
            .map(ReceiptLine.new));
      }
      final model = await (_model ??= ReceiptClassifier.load());
      return await compute(_analyze, _ReceiptAnalysis(lines, model));
    } finally {
      await recognizer.close();
    }
  }
}

class _ReceiptAnalysis {
  const _ReceiptAnalysis(this.lines, this.model);
  final List<ReceiptLine> lines;
  final ReceiptClassifier model;
}

ReceiptScanResult _analyze(_ReceiptAnalysis input) {
  final rows = reconstructReceiptRows(input.lines);
  final text = rows.map((line) => line.text).join('\n');
  final foreign = ReceiptAmountReader.hasForeignCurrency(rows);
  return ReceiptScanResult(
    recognizedText: text,
    hasText: text.trim().isNotEmpty,
    foreignCurrency: foreign,
    amountVnd: foreign ? null : ReceiptAmountReader.fromLines(rows),
    category: input.model.suggest(text),
  );
}
