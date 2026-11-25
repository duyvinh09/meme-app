import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/receipt_scan_controller.dart';
import '../models/receipt_scan_result.dart';

class ReceiptScanFeedback extends StatelessWidget {
  const ReceiptScanFeedback(
      {required this.phase,
      required this.result,
      required this.onRetry,
      required this.currency,
      this.categoryLabel,
      this.requiresRestart = false,
      this.retake = false,
      super.key});
  final ReceiptScanPhase phase;
  final ReceiptScanResult? result;
  final VoidCallback onRetry;
  final String currency;
  final String? categoryLabel;
  final bool requiresRestart;
  final bool retake;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loading =
        phase == ReceiptScanPhase.loading || phase == ReceiptScanPhase.idle;
    final data = result;
    final amount = data?.amountVnd;
    final label = categoryLabel;
    final title = loading
        ? l10n.receiptReading
        : phase == ReceiptScanPhase.failed
            ? (requiresRestart
                ? l10n.receiptRestartRequired
                : l10n.receiptFailed)
            : data?.hasText == false
                ? l10n.receiptNoText
                : l10n.receiptReviewHint;
    return Semantics(
        liveRegion: true,
        child: Material(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 10, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                              child: loading
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Icon(Icons.receipt_long_outlined,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(title,
                                  style: AppTextStyles.body(context))),
                        ]),
                    if (!loading) ...[
                      if (phase == ReceiptScanPhase.ready &&
                          data?.hasText == true) ...[
                        if (data != null && data.usdText != null)
                          Text(
                              l10n.receiptDetectedAmount(
                                  '${data.explicitUsd || currency == "USD" ? "USD " : r"$"}${data.usdText}'),
                              style: AppTextStyles.bodySecondary(context))
                        else if (amount != null)
                          Text(
                              l10n.receiptDetectedAmount(
                                  AppCurrencyFormatter.formatFromVnd(
                                      amountVnd: amount.toDouble(),
                                      currency: 'VND')),
                              style: AppTextStyles.bodySecondary(context))
                        else
                          Text(
                              data?.foreignCurrency == true
                                  ? l10n.receiptForeignCurrency
                                  : l10n.receiptAmountUnknown,
                              style: AppTextStyles.bodySecondary(context)),
                        if (amount != null && currency != 'VND')
                          Text(l10n.receiptCurrencyNotice,
                              style: AppTextStyles.bodySecondary(context)),
                        Text(
                            label == null
                                ? l10n.receiptCategoryUnknown
                                : l10n.receiptDetectedCategory(label),
                            style: AppTextStyles.bodySecondary(context)),
                        if (data != null && data.recognizedText.isNotEmpty)
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(l10n.receiptReadText,
                                style: AppTextStyles.caption(context)),
                            children: [
                              SizedBox(
                                  height: 160,
                                  child: SingleChildScrollView(
                                      child: SelectableText(data.recognizedText,
                                          style: AppTextStyles.bodySecondary(
                                              context))))
                            ],
                          ),
                      ],
                      Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                              onPressed: onRetry,
                              child: Text(retake
                                  ? l10n.receiptRetake
                                  : l10n.receiptRetry))),
                    ],
                  ])),
        ));
  }
}
