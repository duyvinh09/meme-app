import 'dart:math' as math;

import '../models/receipt_scan_result.dart';

/// Rebuild printed rows from geometry, not ML Kit's column/block order.
List<ReceiptLine> reconstructReceiptRows(List<ReceiptLine> input) {
  if (input.isEmpty ||
      input.any((line) => line.height <= 0 || line.width <= 0)) {
    return List<ReceiptLine>.of(input);
  }
  final angles = input
      .where((line) =>
          line.angle.isFinite &&
          line.angle.abs() <= 20 &&
          line.width > line.height * 2)
      .map((line) => line.angle)
      .toList()
    ..sort();
  final angle = angles.isEmpty ? 0.0 : angles[angles.length ~/ 2];
  final slope = math.tan(angle * math.pi / 180);
  double baseline(ReceiptLine line) =>
      line.centerY - slope * (line.left + line.width / 2);
  final sorted = List<ReceiptLine>.of(input)
    ..sort((a, b) => baseline(a).compareTo(baseline(b)));
  final rows = <List<ReceiptLine>>[];
  for (final line in sorted) {
    final row = rows.isEmpty ? <ReceiptLine>[] : rows.last;
    final center = row.isEmpty
        ? 0
        : row.map(baseline).reduce((a, b) => a + b) / row.length;
    final height =
        row.isEmpty ? 0 : row.map((cell) => cell.height).reduce(math.min);
    final overlaps = row.any((cell) =>
        math.min(cell.right, line.right) - math.max(cell.left, line.left) >
        math.min(cell.width, line.width) * 0.2);
    if (row.isEmpty ||
        overlaps ||
        (center - baseline(line)).abs() >
            math.min(height, line.height) * 0.75) {
      rows.add([line]);
    } else {
      row.add(line);
    }
  }
  return rows.map((row) {
    row.sort((a, b) => a.left.compareTo(b.left));
    final left = row.map((cell) => cell.left).reduce(math.min);
    final right = row.map((cell) => cell.right).reduce(math.max);
    final top = row.map((cell) => cell.top).reduce(math.min);
    final bottom = row.map((cell) => cell.top + cell.height).reduce(math.max);
    return ReceiptLine(row.map((cell) => cell.text).join(' '),
        left: left, top: top, width: right - left, height: bottom - top);
  }).toList();
}
