import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/features/capture/models/receipt_scan_result.dart';
import 'package:meme_app/features/capture/services/receipt_layout.dart';
import 'package:meme_app/features/capture/services/receipt_amount_reader.dart';

List<ReceiptLine> bill(
    {bool tilted = false,
    String cash = '590,000',
    String subtotal = '590,000'}) {
  final angle = tilted ? 3.0 : 0.0;
  ReceiptLine cell(String text, double x, double row, double width) =>
      ReceiptLine(text,
          left: x,
          top: row + math.tan(angle * math.pi / 180) * (x + width / 2),
          width: width,
          height: 20,
          angle: angle);
  return [
    cell(cash, 500, 110, 100),
    cell('Tổng tiền:', 20, 70, 140),
    cell(subtotal, 500, 30, 100),
    cell('+Thanh toán tiền mặt', 20, 110, 250),
    cell('590,000', 500, 70, 100),
    cell('Thành tiền:', 20, 30, 150),
  ];
}

void main() {
  test(
      'Rejoins spaced total digits on supplied tax bill despite shuffled blocks',
      () {
    ReceiptLine cell(String text, double x, double y, double width) =>
        ReceiptLine(text, left: x, top: y, width: width, height: 20);
    final rows = reconstructReceiptRows([
      cell('925', 600, 100, 40),
      cell('Tiền thuế: 5%', 10, 60, 200),
      cell('041', 540, 100, 40),
      cell('573 425', 500, 60, 140),
      cell('Tiền hàng: 11 468 500', 10, 20, 630),
      cell('12', 500, 100, 25),
      cell('Tổng:', 10, 100, 100),
      cell('+ Khách đưa: 12 041 925', 10, 140, 630),
      cell('+ Trả lại: 0', 10, 180, 630),
    ]);
    expect(ReceiptAmountReader.fromLines(rows), 12041925);
  });
  for (final tilted in [false, true]) {
    test(
        'Reconstructs the supplied bill rows despite shuffled OCR blocks ($tilted)',
        () {
      final rows = reconstructReceiptRows(bill(tilted: tilted));
      expect(rows.map((row) => row.text), [
        'Thành tiền: 590,000',
        'Tổng tiền: 590,000',
        '+Thanh toán tiền mặt 590,000',
      ]);
      expect(ReceiptAmountReader.fromLines(rows), 590000);
    });
    test(
        'Uses the total row, not another nearby price or cash payment ($tilted)',
        () {
      final rows = reconstructReceiptRows(
          bill(tilted: tilted, cash: '600,000', subtotal: '700,000'));
      expect(ReceiptAmountReader.fromLines(rows), 590000);
    });
  }
  test('Keeps text-only OCR order when bounding boxes are unavailable', () {
    final lines = [
      const ReceiptLine('Tổng tiền:'),
      const ReceiptLine('590,000')
    ];
    final rows = reconstructReceiptRows(lines);
    expect(rows.map((row) => row.text), ['Tổng tiền:', '590,000']);
    expect(ReceiptAmountReader.fromLines(rows), 590000);
  });
}
