class ReceiptLine {
  const ReceiptLine(this.text,
      {this.left = 0,
      this.top = 0,
      this.width = 0,
      this.height = 0,
      this.angle = 0});
  final double angle;
  final String text;
  final double left;
  final double top;
  final double width;
  final double height;
  double get right => left + width;
  double get centerY => top + height / 2;
}

class ReceiptCategorySuggestion {
  const ReceiptCategorySuggestion(this.category, this.confidence);
  final String category;
  final double confidence;
}

class ReceiptScanResult {
  const ReceiptScanResult(
      {this.amountVnd,
      this.usdCents,
      this.explicitUsd = false,
      this.category,
      this.hasText = true,
      this.foreignCurrency = false,
      this.recognizedText = ''});
  final String recognizedText;
  final int? amountVnd;
  final int? usdCents;
  final bool explicitUsd;

  String? get usdText {
    final cents = usdCents;
    if (cents == null) return null;
    return '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
  }
  final ReceiptCategorySuggestion? category;
  final bool hasText;
  final bool foreignCurrency;
}

/// A completed camera scan, including failures, passed to Preview without rescanning.
class ReceiptScanSnapshot {
  const ReceiptScanSnapshot({this.result, this.requiresRestart = false});
  final ReceiptScanResult? result;
  final bool requiresRestart;
}
