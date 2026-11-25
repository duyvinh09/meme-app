import '../models/receipt_scan_result.dart';
import 'receipt_text.dart';

/// Infers a footer total from printed line amounts and geometry, without
/// requiring the footer label to belong to a predefined vocabulary.
class ReceiptTotalInference {
  static final _excluded = RegExp(
      r'\b(?:khach dua|khach tra|tien khach|tra lai|tien thua|tien du|tien mat|chuyen khoan|cash|tendered|change|paid|phone|tel|hotline|mst|ma so thue|tax id|ma hoa don|invoice|receipt no|ma giao dich|account|tai khoan|dia chi|address|so luong|quantity|diem|points)\b');
  static final _discount = RegExp(r'\b(?:giam gia|chiet khau|discount)\b');
  static final _charge = RegExp(
      r'\b(?:vat|thue|tax|phi dich vu|service charge|phu phi|surcharge)\b');
  static final _item = RegExp(r'^\s*\d+(?:[.,]\d+)?\s+[a-z]');
  static final _money = RegExp(
      r'(?:\d{1,3}(?:[., ]\d{3})+|\d{4,12})(?:\s*(?:vnd|d|dong|₫))?\s*$');

  static int? infer(List<ReceiptLine> input, int? Function(String) readAmount) {
    final rows = [...input];
    // Full-text OCR has no geometry; retain its reading order in that case.
    if (rows.every((row) => row.height > 0) &&
        rows.map((row) => row.top).toSet().length > 1) {
      rows.sort((a, b) => a.top.compareTo(b.top));
    }
    var itemCount = 0;
    var itemSum = 0;
    var adjustments = 0;
    var largestItem = 0;
    ReceiptLine? lastItem;
    int? candidate;
    for (final row in rows) {
      final text = normalizeReceiptText(row.text).replaceAllMapped(
          RegExp(r'(?<=\d)\s*([.,])\s*(?=\d)'), (match) => match.group(1)!);
      if (_excluded.hasMatch(text)) continue;
      final discount = _discount.hasMatch(text);
      final charge = _charge.hasMatch(text);
      final match = _money.firstMatch(text);
      final amount = match == null ? null : readAmount(match.group(0)!);
      if (discount || charge) {
        // Any later adjustment invalidates a previously observed footer.
        candidate = null;
        if (amount == null) return null;
        adjustments += discount ? -amount : amount;
        continue;
      }
      if (amount == null) continue;
      if (_item.hasMatch(text)) {
        itemCount++;
        itemSum += amount;
        if (amount > largestItem) largestItem = amount;
        lastItem = row;
        candidate = null;
        continue;
      }
      if (itemCount < 2 || lastItem == null) continue;
      final agreesWithItems = amount == itemSum + adjustments;
      final prominentFooter = adjustments == 0 &&
          row.height >= lastItem.height * 1.3 &&
          lastItem.height > 0 &&
          row.top >= lastItem.top + lastItem.height * 1.8 &&
          (row.right - lastItem.right).abs() <= lastItem.height * 2 &&
          amount >= largestItem;
      // Never replace a consistent footer with an unexplained later number.
      if (!agreesWithItems && !prominentFooter) return null;
      if (candidate != null && candidate != amount) return null;
      candidate = amount;
    }
    return candidate;
  }
}
