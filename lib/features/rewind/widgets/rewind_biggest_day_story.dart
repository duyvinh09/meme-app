import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/rewind_data.dart';

class RewindBiggestDayStory extends StatelessWidget {
  final RewindData data;
  final String currency;

  const RewindBiggestDayStory({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final biggest = data.biggestDay;
    if (biggest == null) return const SizedBox.shrink();

    final dateStr = DateFormat('dd/MM').format(biggest.date);
    final allDays = biggest.dailySpendings;

    // Filter to at most 7 days centered around the biggest day to prevent UI overflow
    List<RewindDaySpending> displayDays = allDays;
    if (allDays.length > 7) {
      final peakIndex = allDays.indexWhere((d) =>
          d.date.year == biggest.date.year &&
          d.date.month == biggest.date.month &&
          d.date.day == biggest.date.day);
      int startIdx = 0;
      if (peakIndex != -1) {
        startIdx = (peakIndex - 3).clamp(0, math.max(0, allDays.length - 7));
      }
      displayDays = allDays.skip(startIdx).take(7).toList();
    }

    final maxAmount = displayDays.fold<double>(
      0.0,
      (max, d) => math.max(max, d.amount),
    );

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
                const Text('📅', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  l10n.rewindBiggestDayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Subtitle
          Text(
            l10n.rewindBiggestDaySubtitle(dateStr),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Big Amount
          Text(
            AppCurrencyFormatter.formatFromVnd(
              amountVnd: biggest.amount,
              currency: currency,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            l10n.rewindTransactionsOnDay(biggest.transactionCount),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Mini Bar Timeline Container
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF6EE7B7),
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.rewindDailySpendingDistribution,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                SizedBox(
                  height: 96,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: displayDays.map((d) {
                      final isPeak = d.date.year == biggest.date.year &&
                          d.date.month == biggest.date.month &&
                          d.date.day == biggest.date.day;

                      final heightFactor = maxAmount > 0
                          ? (d.amount / maxAmount).clamp(0.18, 1.0)
                          : 0.18;

                      final barHeight = 54.0 * heightFactor;
                      final dayLabel = DateFormat('dd').format(d.date);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isPeak
                                  ? const Color(0xFF10B981)
                                  : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isPeak
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayLabel,
                            style: TextStyle(
                              color: isPeak
                                  ? const Color(0xFF6EE7B7)
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              height: 1.1,
                              fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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
