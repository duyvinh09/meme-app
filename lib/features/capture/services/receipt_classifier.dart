import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/receipt_scan_result.dart';
import 'receipt_text.dart';
import 'receipt_item_evidence.dart';

/// Uses the receipt-ai model, with explicit merchant/item evidence before ML.
class ReceiptClassifier {
  const ReceiptClassifier(this.labels, this.bias, this.size, this.weights);
  final List<String> labels;
  final List<double> bias;
  final int size;
  final ByteData weights;

  static Future<ReceiptClassifier> load() async {
    final model =
        jsonDecode(await rootBundle.loadString('assets/receipt/model.json'))
            as Map<String, dynamic>;
    return ReceiptClassifier(
        List<String>.from(model['labels']),
        List<double>.from(model['bias']),
        model['size'] as int,
        await rootBundle.load('assets/receipt/weights.bin'));
  }

  static const _canonical = {
    'food': 'Ăn uống',
    'shopping': 'Mua sắm',
    'transport': 'Đi lại',
    'entertainment': 'Giải trí',
    'education': 'Học tập',
    'gift': 'Quà tặng',
    'other': 'Khác',
  };
  static const _evidence = {
    'food': [
      'phuc long',
      'highlands',
      'starbucks',
      'the coffee house',
      'the noodle house',
      'katinat',
      'gong cha',
      'tra sua',
      'ca phe',
      'quan an',
      'nha hang',
      'com tam',
      'bun bo',
      'pho bo',
      'pizza',
      'kfc',
      'lotteria',
      'jollibee',
      'com ga',
      'com suon',
      'com chien',
      'com rang',
      'pho ga',
      'bun cha',
      'hu tieu',
      'banh mi',
      'banh ngot',
      'sua tuoi',
      'tra dao',
      'hong tra',
      'nuoc ep',
      'coffee',
      'milk tea',
      'noodles',
      'noodle',
      'mi xao',
      'mi kho',
      'fried rice',
      'sandwich',
      'latte',
      'espresso',
      'cappuccino'
    ],
    'shopping': [
      'fpt shop',
      'the gioi di dong',
      'dien may xanh',
      'cellphones',
      'nguyen kim',
      'iphone',
      'dien thoai',
      'quan ao',
      'giay dep',
      'my pham',
      'uniqlo',
      'shopee',
      'lazada'
    ],
    'transport': [
      'taxi',
      'mai linh',
      'vinasun',
      'petrolimex',
      'ron95',
      'tien xang',
      'cuoc xe',
      'gui xe',
      've xe',
      'grabcar',
      'grabbike'
    ],
    'entertainment': [
      'rap chieu phim',
      'phong chieu phim',
      'lotte cinema',
      'cgv',
      've xem phim',
      'karaoke',
      'netflix',
      'spotify'
    ],
    'education': [
      'nha sach',
      'fahasa',
      'sach giao khoa',
      'giao trinh',
      'hoc phi',
      'khoa hoc',
      'but bi',
      'vo hoc sinh'
    ],
    'gift': ['qua tang', 'dien hoa', 'bo hoa', 'hoa sinh nhat'],
  };

  static const _merchants = {
    'food': [
      'phuc long',
      'highlands',
      'starbucks',
      'the coffee house',
      'katinat',
      'gong cha',
      'kfc',
      'lotteria',
      'jollibee',
      'nha hang',
      'quan an'
    ],
    'shopping': [
      'fpt shop',
      'the gioi di dong',
      'dien may xanh',
      'cellphones',
      'nguyen kim',
      'uniqlo',
      'shopee',
      'lazada'
    ],
    'transport': ['mai linh', 'vinasun', 'petrolimex'],
    'entertainment': ['lotte cinema', 'cgv', 'netflix', 'spotify'],
    'education': ['nha sach', 'fahasa'],
  };

  Set<String> _matches(Map<String, List<String>> rules, String words) => {
        for (final entry in rules.entries)
          if (entry.value.any((phrase) =>
              RegExp('(?:^| )${RegExp.escape(phrase)}(?: |\$)')
                  .hasMatch(words)))
            entry.key,
      };

  ReceiptCategorySuggestion? suggest(String input) {
    final normalized = normalizeReceiptText(input);
    final words = normalized.replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();
    final merchants = _matches(_merchants, words);
    if (merchants.length > 1) return null;
    if (merchants.length == 1) {
      final category = _canonical[merchants.single];
      if (category != null) return ReceiptCategorySuggestion(category, 0.95);
    }
    final hits = ReceiptItemEvidence.categories(normalized);
    for (final entry in _evidence.entries) {
      if (normalized.split('\n').any((line) {
        return entry.value.any((phrase) =>
            ReceiptItemEvidence.matchesLine(line, phrase.split(' ')));
      })) {
        hits.add(entry.key);
      }
    }
    if (hits.length == 1) {
      final category = _canonical[hits.single];
      if (category != null) return ReceiptCategorySuggestion(category, 0.95);
    }
    // Mixed purchases must not be forced into a category by a weak model.
    if (hits.length > 1) return null;
    final text =
        ' ${RegExp('[a-z]+').allMatches(normalized).map((match) => match.group(0)).join(' ')} ';
    final ids = <int>{};
    for (final n in [3, 4, 5]) {
      for (var i = 0; i + n <= text.length; i++) {
        var hash = 0;
        for (var j = i; j < i + n; j++) {
          hash = (hash * 31 + text.codeUnitAt(j)) % size;
        }
        ids.add(hash);
      }
    }
    if (ids.isEmpty) return null;
    final scores = List<double>.from(bias);
    for (var k = 0; k < labels.length; k++) {
      for (final id in ids) {
        scores[k] += weights.getFloat32(4 * (k * size + id), Endian.little) /
            math.sqrt(ids.length);
      }
    }
    var best = 0;
    for (var k = 1; k < scores.length; k++) {
      if (scores[k] > scores[best]) best = k;
    }
    final confidence = 1 /
        scores.fold<double>(
            0, (sum, value) => sum + math.exp(value - scores[best]));
    final category = _canonical[labels[best]];
    // This is an autofill safety gate, not a claim of calibrated accuracy.
    if (confidence < 0.65 || category == null || category == 'Khác') {
      return null;
    }
    return ReceiptCategorySuggestion(category, confidence);
  }
}
