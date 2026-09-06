import 'package:flutter/material.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../models/rewind_data.dart';

class RewindHighlightStory extends StatelessWidget {
  final RewindData data;

  const RewindHighlightStory({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final highlight = data.highlight;
    if (highlight == null) return const SizedBox.shrink();

    String title;
    String description;
    switch (highlight.type) {
      case RewindHighlightType.dominantCategory:
        final catDisplay = BudgetNameLocalizer.display(
          context,
          highlight.categoryName ?? '',
        );
        title = l10n.rewindHighlightDominantTitle;
        description = l10n.rewindHighlightDominantDesc(
          catDisplay,
          highlight.percentStr ?? '',
        );
        break;
      case RewindHighlightType.peakDay:
        title = l10n.rewindHighlightPeakDayTitle;
        description = l10n.rewindHighlightPeakDayDesc(
          highlight.dateStr ?? '',
          highlight.percentStr ?? '',
        );
        break;
      case RewindHighlightType.biggestExpense:
        final catDisplay = BudgetNameLocalizer.display(
          context,
          highlight.categoryName ?? '',
        );
        title = l10n.rewindHighlightBiggestExpenseTitle;
        description = l10n.rewindHighlightBiggestExpenseDesc(catDisplay);
        break;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌟', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  l10n.rewindHighlightTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Big Graphic Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFA21CAF).withValues(alpha: 0.35),
                  const Color(0xFF701A75).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFE879F9).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA21CAF).withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  highlight.emoji,
                  style: const TextStyle(fontSize: 54),
                ),
                const SizedBox(height: 20),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
