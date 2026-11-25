import '../models/receipt_scan_result.dart';
import 'receipt_text.dart';
import 'receipt_total_inference.dart';

/// Only reads labelled amounts. Never guesses from the largest number on a bill.
class ReceiptAmountReader {
  static const maxAmount = 999999999999;
  static const _payableLabels = [
    'tong so tien thanh toan',
    'tong so tien can tra',
    'tong so tien phai tra',
    'tong so tien can thanh toan',
    'so tien can thanh toan',
    'tong tien thanh toan',
    'tong tien phai tra',
    'tong cong thanh toan',
    'so tien phai tra',
    'tien phai tra',
    'so tien can tra',
    'tien can tra',
    'tong cong phai tra',
    'tong cong can thanh toan',
    'so tien thanh toan',
    'tong thanh toan',
    'tong phai tra',
    'khach can tra',
    'khach phai tra',
    'can thanh toan',
    'tien thanh toan',
    'tinh tien',
    'thanh toan',
    'thuc tra',
    'phai tra',
    'grand total',
    'amount due',
    'balance due',
    'total due',
    'total payable',
    'payment total',
    'total payment',
    'net total',
    'net payable',
    'amount payable',
    'total amount due',
    'total amount payable',
    'final total',
  ];
  static const _totalLabels = [
    'tong gia tri hoa don',
    'tong so tien',
    'tong hoa don',
    'tong cong',
    'tong tien',
    'thanh tien',
    'total amount',
    'total',
    'tong',
  ];
  static final _payable = _labels(_payableLabels);
  static final _total = _labels(_totalLabels);
  static final _repairLabels = [..._payableLabels, ..._totalLabels]
    ..sort((a, b) => b.length.compareTo(a.length));
  static final _notTotal = RegExp(
      r'^(?:tong (?:so luong|diem|giam|tiet kiem|khuyen mai)|total (?:quantity|discount|savings))\b');
  static final _productTotal =
      RegExp(r'^tong\s+\d+\s*(?:sp|san pham)(?=\s|[:：]|$)\s*[:：]?\s*');
  static final _adjustment = RegExp(
      r'\b(?:giam gia|chiet khau|khuyen mai|discount|vat|thue|tax|phi dich vu|service charge|phu phi|surcharge)\b');
  static final _paymentMethod =
      RegExp(r'^thanh toan (?:bang|tien mat|the|chuyen khoan|qr)(?=\b|\d)');
  static final _foreign =
      RegExp(r'\b(?:usd|eur|khr|gbp|jpy|thb)\b|[€£¥៛฿]|\$\s*[0-9]|[0-9]\s*\$|^\s*\$\s*$', caseSensitive: false);

  static RegExp _labels(List<String> labels) {
    final longestFirst = [...labels]
      ..sort((a, b) => b.length.compareTo(a.length));
    return RegExp(
        '^(?:${longestFirst.map(RegExp.escape).join('|')})(?=\\s|[:：]|\$)\\s*[:：]?\\s*');
  }

  static bool hasForeignCurrency(List<ReceiptLine> lines) =>
      lines.any((line) => _foreign.hasMatch(line.text));

  // Match the entire label to the left of a valid amount. This permits OCR
  // punctuation/digits inside words without changing the amount itself.
  static String _repairNoisyLabel(String text) {
    if (text.length > 160) return text;
    for (final number
        in RegExp(r'\d[\d., ]*(?:vnd|d|₫|dong)?$').allMatches(text)) {
      if (number.start > 0 &&
          RegExp(r'[-−]').hasMatch(text[number.start - 1])) {
        continue;
      }
      final suffix = text.substring(number.start);
      if (readVnd(suffix) == null) continue;
      final label = _canonicalLabel(text.substring(0, number.start));
      if (label != null) return '$label: $suffix';
    }
    if (RegExp(r'\d{2}|\d[.,]\d').hasMatch(text)) return text;
    final label = _canonicalLabel(text);
    return label ?? text;
  }

  static String? _canonicalLabel(String input) {
    // A multi-digit group belongs to an amount, not an OCR-damaged label.
    if (RegExp(r'\d{2}').hasMatch(input)) return null;
    final compact = input
        .replaceAll('@', 'a')
        .replaceAll('!', 'i')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (compact.isEmpty || compact.length > 48) return null;
    final mapped = compact
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('8', 'b');
    final variants = {mapped, compact.replaceAll(RegExp(r'\d'), '')};
    // Exact matches win before fuzzy matching any other label.
    for (final label in _repairLabels) {
      if (variants.contains(label.replaceAll(' ', ''))) return label;
    }
    String? best;
    var bestDistance = 3;
    var ambiguous = false;
    for (final label in _repairLabels) {
      final expected = label.replaceAll(' ', '');
      if (expected.length <= 4) continue;
      final limit = expected.length >= 12 ? 2 : 1;
      for (final variant in variants) {
        final distance = _editDistance(variant, expected);
        if (distance > limit) continue;
        if (distance < bestDistance) {
          best = label;
          bestDistance = distance;
          ambiguous = false;
        } else if (distance == bestDistance && best != label) {
          ambiguous = true;
        }
      }
    }
    return ambiguous ? null : best;
  }

  static int _editDistance(String a, String b) {
    if ((a.length - b.length).abs() > 2) return 3;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final current = <int>[i + 1];
      for (var j = 0; j < b.length; j++) {
        final substitution = previous[j] + (a[i] == b[j] ? 0 : 1);
        final insertion = current[j] + 1;
        final deletion = previous[j + 1] + 1;
        current.add([substitution, insertion, deletion]
            .reduce((x, y) => x < y ? x : y));
      }
      previous = current;
    }
    return previous.last;
  }

  // Correct only short, recognisable label words; never alter monetary digits.
  static String _repairTotalLabel(String text) {
    // Do not fuzzy-convert a valid 'tong tien' into 'tinh tien'.
    if (_payable.hasMatch(text) || _total.hasMatch(text)) return text;
    final words = RegExp(r'[a-z01]+').allMatches(text).toList();
    if (words.isEmpty || words.first.start != 0) return text;
    for (final label in _repairLabels) {
      final expected = label.split(' ');
      if (words.length < expected.length) continue;
      var changed = 0;
      var matches = true;
      for (var i = 0; i < expected.length; i++) {
        if (i > 0 &&
            text
                .substring(words[i - 1].end, words[i].start)
                .trim()
                .isNotEmpty) {
          matches = false;
          break;
        }
        final actual =
            words[i].group(0)!.replaceAll('0', 'o').replaceAll('1', 'i');
        if (actual == expected[i]) continue;
        // A bare Vietnamese 'tong' is too short to safely fuzzy-match.
        if (label == 'tong' || !_oneEditApart(actual, expected[i])) {
          matches = false;
          break;
        }
        changed++;
      }
      if (!matches || changed > 2) continue;
      final end = words[expected.length - 1].end;
      if (end < text.length && !RegExp(r'[\s:：]').hasMatch(text[end])) continue;
      return '$label${text.substring(end)}';
    }
    return text;
  }

  static bool _oneEditApart(String actual, String expected) {
    if ((actual.length - expected.length).abs() > 1) return false;
    var a = 0;
    var b = 0;
    var edits = 0;
    while (a < actual.length && b < expected.length) {
      if (actual[a] == expected[b]) {
        a++;
        b++;
        continue;
      }
      if (++edits > 1) return false;
      if (actual.length >= expected.length) a++;
      if (expected.length >= actual.length) b++;
    }
    return edits + actual.length - a + expected.length - b <= 1;
  }

  static int? readVnd(String input) {
    var text = normalizeReceiptText(input)
        .replaceAll(RegExp(r'[\s\u2007\u202f]+'), ' ')
        .replaceFirst(RegExp(r'^(?:vnd|₫)\s*'), '')
        .replaceFirst(RegExp(r'\s*(?:vnd|vnd\.|d|₫|dong)$'), '')
        .replaceAllMapped(
            RegExp(r'(?<=\d)\s*([.,])\s*(?=\d)'), (match) => match.group(1)!)
        .trim();
    // POS receipts sometimes append a zero fractional part to integer VND.
    if (RegExp(r'^[\d., ]+[.,]00$').hasMatch(text) &&
        !RegExp(r'^\d{1,3}(?:[., ]\d{3})+$').hasMatch(text)) {
      text = text.substring(0, text.length - 3);
    }
    // Both dot and comma may indicate a decimal fraction; only the zero
    // fractional VND form handled above is unambiguous.
    if (text.contains('.') && text.contains(',')) return null;
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:[., ]\d{3})+)$').hasMatch(text)) {
      return null;
    }
    final value = int.tryParse(text.replaceAll(RegExp(r'\D'), ''));
    return value != null && value > 0 && value <= maxAmount ? value : null;
  }

  // Keep cents as integers. Match a complete total row so phone numbers,
  // cash, change and item amounts cannot supply a partial match.
  static final _usdRow = RegExp(
      r'^(.+?)\s*[:：]?\s*((?:us\$|\$|\(?usd\)?)?)\s*'
      r'(\d{1,3}(?:,\d{3})+(?:\.\d{2})?|\d+(?:[.,]\d{2})?)'
      r'\s*(usd|us\$|\$)?$');
  static final _explicitUsd = RegExp(r'\busd\b|\bus\$');
  static final _otherCurrency = RegExp(
      r'\b(?:eur|khr|gbp|jpy|thb|vnd|cad|aud|nzd|sgd|hkd)\b|[€£¥៛฿₫]|(?:ca?|au?|nz|sg?|hk)\$|\d\s*đ',
      caseSensitive: false);

  static bool explicitlyUsd(List<ReceiptLine> rows) =>
      rows.any((row) => _explicitUsd.hasMatch(row.text.toLowerCase()));

  static int? readUsdCents(List<ReceiptLine> rows) {
    final explicit = explicitlyUsd(rows);
    final mixed = rows.any((row) => _otherCurrency.hasMatch(row.text));
    final values = <int>{};
    final payable = <int>{};
    for (final row in rows) {
      final text = normalizeReceiptText(row.text);
      final match = _usdRow.firstMatch(text);
      if (match == null || _otherCurrency.hasMatch(row.text)) continue;
      final marker = '${match[2]}${match[4] ?? ''}';
      if (mixed && !_explicitUsd.hasMatch(marker)) continue;
      if (!explicit && marker.isEmpty) continue;
      final labelText = match[1]!.replaceFirst(RegExp(r'[\s:：]+$'), '');
      if (RegExp(r'[0-9.,$-]$').hasMatch(labelText.trim())) continue;
      final label = labelText.trim() == 'tong tt' ? 'tong thanh toan' : _canonicalLabel(labelText);
      if (label == null || label == 'thanh tien') continue;
      var number = match[3]!;
      if (RegExp(r'^\d+,\d{2}$').hasMatch(number)) {
        number = number.replaceAll(',', '.');
      }
      final digits = number.replaceAll(',', '').split('.');
      final dollars = int.tryParse(digits.first);
      if (dollars == null || dollars > maxAmount) continue;
      final cents = dollars * 100 + (digits.length == 2 ? int.parse(digits.last) : 0);
      if (cents > 0) {
        (_payableLabels.contains(label) ? payable : values).add(cents);
      }
    }
    final candidates = payable.isEmpty ? values : payable;
    return candidates.length == 1 ? candidates.single : null;
  }

  static int? fromLines(List<ReceiptLine> lines) {
    if (hasForeignCurrency(lines)) return null;
    final payable = <int>{};
    final totals = <int>{};
    final lineTotals = <int>{};
    final totalRows = <int, int>{};
    final adjustmentRows = <int>[];
    var unreadablePayable = false;
    for (var i = 0; i < lines.length; i++) {
      final text = _repairNoisyLabel(_repairTotalLabel(
          normalizeReceiptText(lines[i].text)
              .replaceFirst(RegExp(r'^[+\-•]+\s*'), '')
              .replaceAll(RegExp(r'[\(\[]\s*(?:vnd|d|₫|dong)\s*[\)\]]'), ' ')
              .trim()));
      final registration = RegExp(
              r'^(?:ma so thue|mst|tax id|vat (?:id|no|number|registration))\b')
          .hasMatch(text);
      if (!registration && _adjustment.hasMatch(text)) adjustmentRows.add(i);
      if (_notTotal.hasMatch(text)) continue;
      if (_paymentMethod.hasMatch(text)) continue;
      final finalLabel = _payable.firstMatch(text);
      final label = finalLabel ??
          _productTotal.firstMatch(text) ??
          _total.firstMatch(text);
      if (label == null) continue;
      final suffix = text.substring(label.end).trim();
      int? amount;
      if (suffix.isNotEmpty) {
        amount = _readLabelAmount(suffix, lines);
      } else {
        final row = lines[i];
        final sameRow = lines
            .where((other) =>
                !identical(other, row) &&
                row.height > 0 &&
                other.left >= row.right &&
                (other.centerY - row.centerY).abs() <= row.height * 0.65)
            .map((other) => readVnd(other.text))
            .whereType<int>()
            .toSet();
        if (sameRow.length == 1) amount = sameRow.single;
        if (sameRow.isEmpty) {
          if (row.height > 0) {
            // ML Kit groups columns into blocks; list order is not reading order.
            final below = lines
                .where((other) =>
                    other.top >= row.top + row.height * 0.8 &&
                    other.top - row.top <= row.height * 3)
                .toList()
              ..sort((a, b) => a.top.compareTo(b.top));
            if (below.isNotEmpty) {
              final nextRow = below
                  .where((other) =>
                      other.top - below.first.top <= row.height * 0.5)
                  .toList();
              final values =
                  nextRow.map((other) => readVnd(other.text)).toList();
              // Do not skip a cash/change label to borrow its number.
              if (values.every((value) => value != null) &&
                  values.toSet().length == 1) {
                amount = values.first;
              }
            }
          } else if (i + 1 < lines.length) {
            amount = readVnd(lines[i + 1].text);
          }
        }
      }
      if (amount != null) {
        final target = finalLabel != null
            ? payable
            : text.startsWith('thanh tien')
                ? lineTotals
                : totals;
        target.add(amount);
        if (identical(target, totals)) totalRows[i] = amount;
      } else if (finalLabel != null) {
        unreadablePayable = true;
      }
    }
    if (payable.isNotEmpty) return payable.length == 1 ? payable.single : null;
    if (unreadablePayable) return null;
    if (adjustmentRows.isNotEmpty) {
      // A plain 'Total' is usable below every tax/discount row. Use physical
      // positions when available, since OCR block order may be shuffled.
      final finalTotals = totalRows.entries
          .where((candidate) {
            final total = lines[candidate.key];
            return adjustmentRows.every((index) {
              final adjustment = lines[index];
              if (total.height > 0 && adjustment.height > 0) {
                return total.top >= adjustment.top + adjustment.height * 0.8;
              }
              return candidate.key > index;
            });
          })
          .map((entry) => entry.value)
          .toSet();
      if (finalTotals.isNotEmpty) {
        return finalTotals.length == 1 ? finalTotals.single : null;
      }
      return ReceiptTotalInference.infer(lines, readVnd);
    }
    if (totals.isNotEmpty) return totals.length == 1 ? totals.single : null;
    if (lineTotals.isNotEmpty) {
      return lineTotals.length == 1 ? lineTotals.single : null;
    }
    return ReceiptTotalInference.infer(lines, readVnd);
  }

  static int? _readLabelAmount(String suffix, List<ReceiptLine> lines) {
    final exact = readVnd(suffix);
    if (exact != null) return exact;
    final text = normalizeReceiptText(suffix);
    // A row reconstructed by OCR can accidentally include a nearby signature.
    // Strip only trailing words, never a second numeric field or numeric errors.
    final match =
        RegExp(r'^(\d[\d., ]*\d|\d)(?:\s+[a-z][a-z ]*)?$').firstMatch(text);
    if (match == null) return null;
    final numeric = match.group(1)!.trim();
    final clean = readVnd(numeric);
    if (clean != null) return clean;
    if (!RegExp(r'^\d+(?: +\d+)+$').hasMatch(numeric)) return null;
    final repaired = readVnd(numeric.replaceAll(' ', ''));
    if (repaired == null) return null;
    // Missing grouping spaces do not justify guessing. An independently read
    // cash-tendered row must agree exactly; a larger cash amount is not proof.
    for (final row in lines) {
      final cash = RegExp(
              r'^\s*[+]?\s*(?:khach dua|tien khach dua|cash tendered|amount tendered)\s*[:：]?\s*(.+)$')
          .firstMatch(normalizeReceiptText(row.text));
      if (cash != null && readVnd(cash.group(1)!) == repaired) return repaired;
    }
    return null;
  }
}
