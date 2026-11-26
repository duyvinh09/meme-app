class ReceiptAutofillPolicy {
  const ReceiptAutofillPolicy(
      {required this.amountRevision,
      required this.categoryRevision,
      required this.currency});
  final int amountRevision;
  final int categoryRevision;
  final String currency;

  bool canFillAmount(
          {required int currentRevision,
          String receiptCurrency = 'VND',
          required String currentText,
          required String currentCurrency,
          required bool isExpense}) =>
      isExpense &&
      amountRevision == 0 &&
      currentRevision == amountRevision &&
      currentText.trim().isEmpty &&
      currency == receiptCurrency &&
      currentCurrency == currency;

  bool canFillCategory(
          {required int currentRevision, required bool isExpense}) =>
      isExpense && categoryRevision == 0 && currentRevision == categoryRevision;
}
