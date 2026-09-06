import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../models/rewind_period.dart';

class RewindPeriodPickerSheet extends StatelessWidget {
  final RewindPeriod currentPeriod;
  final ValueChanged<RewindPeriod> onPeriodSelected;

  const RewindPeriodPickerSheet({
    super.key,
    required this.currentPeriod,
    required this.onPeriodSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required RewindPeriod currentPeriod,
    required ValueChanged<RewindPeriod> onPeriodSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RewindPeriodPickerSheet(
        currentPeriod: currentPeriod,
        onPeriodSelected: onPeriodSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final l10n = context.l10n;

    final periods = [
      RewindPeriod.thisWeek(),
      RewindPeriod.thisMonth(),
      RewindPeriod.thisQuarter(),
      RewindPeriod.thisYear(),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Row(
                children: [
                  Text(
                    l10n.rewindSelectPeriod,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: textPrimary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...periods.map((period) {
                final isSelected = period.type == currentPeriod.type;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                      onPeriodSelected(period);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.primaryBlue.withValues(alpha: 0.15)
                                : const Color(0xFFEFF6FF))
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryBlue.withValues(alpha: 0.45)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  period.getTitle(context),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                    color: isSelected ? AppColors.primaryBlue : textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  period.getDateRangeText(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : (isDark ? Colors.white38 : Colors.black26),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
