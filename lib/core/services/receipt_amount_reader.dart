import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptAmountReader {
  static final _label = RegExp(
    r'^(?:tổng tiền thanh toán|tổng thanh toán|tổng cộng|'
    r'tiền thanh toán|tổng phải trả|khách cần trả|'
    r'tổng\s+\d+\s*sp|grand total|amount due)'
    r'(?=\s|[:：]|$)\s*[:：]?\s*',
    caseSensitive: false,
  );

  static int? _readVnd(String text) {
    final cleaned = text
        .trim()
        .replaceFirst(RegExp(r'\s*(?:vnd|vnđ|đ|₫)$', caseSensitive: false), '')
        .trim();
    final valid = RegExp(r'^(?:\d+|\d{1,3}(?:[., ]\d{3})+)$');
    if (!valid.hasMatch(cleaned)) return null;
    return int.tryParse(cleaned.replaceAll(RegExp(r'\D'), ''));
  }

  static int? fromLines(List<TextLine> lines) {
    final text = lines.map((l) => l.text).join('\n');
    if (RegExp(r'\b(?:USD|KHR|EUR)\b|[$€៛]', caseSensitive: false)
        .hasMatch(text)) {
      return null;
    }

    final totals = <int>{};
    for (final line in lines) {
      final content = line.text.trim();
      final label = _label.firstMatch(content);
      if (label == null) continue;

      final suffix = content.substring(label.end).trim();
      if (suffix.isNotEmpty) {
        final amount = _readVnd(suffix);
        if (amount != null) totals.add(amount);
        continue;
      }

      // ML Kit đôi khi tách nhãn và số tiền thành hai dòng cùng độ cao.
      final box = line.boundingBox;
      final sameRow = lines.where((other) {
        final b = other.boundingBox;
        return b.left >= box.right &&
            (b.center.dy - box.center.dy).abs() <= box.height * 0.65;
      });
      final candidates = sameRow
          .map((l) => _readVnd(l.text))
          .whereType<int>()
          .toList();
      if (candidates.length == 1) totals.add(candidates.single);
    }
    return totals.length == 1 ? totals.single : null;
  }
}