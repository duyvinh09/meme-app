import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/core/services/tflite_service.dart';
import 'package:meme_app/features/capture/models/image_category_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? suggest(String label,
          {String type = 'expense',
          double confidence = 0.9,
          bool edited = false,
          bool bill = false,
          bool contribution = false}) =>
      ImageCategoryPolicy.categoryFor(
          AiCategoryResult(label: label, confidence: confidence),
          type: type,
          manualEdit: edited,
          isBill: bill,
          isContribution: contribution);

  test('Model assets include eight expected category labels', () async {
    final labels = (await rootBundle.loadString('assets/models/labels.txt'))
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    expect(labels.length, 8);
    final model = await rootBundle.load('assets/models/model.tflite');
    expect(String.fromCharCodes(model.buffer.asUint8List(4, 4)), 'TFL3');
  });
  test('Maps image labels to valid expense categories', () {
    for (final entry in {
      'Ăn uống': 'Ăn uống',
      'Mua sắm': 'Mua sắm',
      'Di chuyển': 'Đi lại',
      'Giải trí': 'Giải trí',
      'Giáo dục': 'Học tập',
      'Khác': 'Khác',
    }.entries) {
      expect(suggest(entry.key), entry.value);
    }
  });
  test('Cannot overwrite manual choice, bill OCR or group contribution', () {
    expect(suggest('Mua sắm', edited: true), isNull);
    expect(suggest('Mua sắm', bill: true), isNull);
    expect(suggest('Mua sắm', contribution: true), isNull);
  });
  test('Weak or invalid scores do not apply a category', () {
    for (final score in [0.39, -1.0, double.nan, double.infinity]) {
      expect(suggest('Ăn uống', confidence: score), isNull);
    }
    expect(suggest('invalid'), isNull);
  });
  test('Income predictions never silently change expense type', () {
    expect(suggest('Lương'), isNull);
    expect(suggest('Quà tặng'), isNull);
    expect(suggest('Lương', type: 'income'), 'Lương');
    expect(suggest('Quà tặng', type: 'income'), 'Quà tặng');
    expect(suggest('Ăn uống', type: 'income'), isNull);
  });
}
