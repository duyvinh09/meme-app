import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Duration duration = const Duration(milliseconds: 1800),
    bool isError = false,
    double bottomMargin = 20,
  }) {
    if (!context.mounted) return;

    try {
      HapticFeedback.lightImpact();

      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger == null) return;
      scaffoldMessenger.clearSnackBars();

      final isDark = AppColors.isDark(context);
      final bgColor = isError
          ? AppColors.expense
          : (isDark ? const Color(0xFF222634) : const Color(0xFF1E293B));
      final textColor = Colors.white;

      scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 6,
        backgroundColor: bgColor,
        margin: EdgeInsets.only(
          bottom: bottomMargin,
          left: 20,
          right: 20,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          side: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.08),
            width: 1,
          ),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: textColor,
                size: 18,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    } catch (_) {}
  }
}
