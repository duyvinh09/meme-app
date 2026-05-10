import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  final VoidCallback? onStartTap;

  const StreakCard({
    super.key,
    required this.streak,
    this.onStartTap,
  });

  bool get canStart => streak < 3;

  String badgeText(BuildContext context) {
    if (streak >= 30) return context.l10n.streakLevel1;
    if (streak >= 14) return context.l10n.streakLevel2;
    if (streak >= 7) return context.l10n.streakLevel3;
    if (streak >= 3) return context.l10n.streakLevel4;
    return context.l10n.streakLevel5;
  }

  Color get fireColor {
    if (streak >= 30) return const Color(0xFFFF5A36);
    if (streak >= 14) return const Color(0xFFFF6B3D);
    if (streak >= 7) return const Color(0xFFFF8447);
    if (streak >= 3) return const Color(0xFFFF9B54);
    return const Color(0xFFFFB36B);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final cardStart = isDark
        ? Color.lerp(AppColors.darkCard, fireColor, 0.08)!
        : Color.lerp(AppColors.lightCard, fireColor, 0.08)!;

    final cardEnd = isDark
        ? Color.lerp(AppColors.darkSurface, fireColor, 0.12)!
        : Color.lerp(const Color(0xFFFFF8F2), fireColor, 0.12)!;

    final cardBorder = isDark
        ? fireColor.withOpacity(0.24)
        : fireColor.withOpacity(0.18);

    final badge = _StartBadge(
      text: badgeText(context),
      isClickable: canStart && onStartTap != null,
      onTap: canStart ? onStartTap : null,
      accentColor: fireColor,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardStart,
            cardEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: fireColor.withOpacity(isDark ? 0.10 : 0.07),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fireColor.withOpacity(isDark ? 0.16 : 0.14),
                border: Border.all(
                  color: fireColor.withOpacity(0.28),
                ),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 40,
                color: fireColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.streak,
                    style: AppTextStyles.cardTitle(context).copyWith(
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.daysStreak(streak),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: fireColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  badge,
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.bolt_rounded,
              color: AppColors.textSecondary(context).withOpacity(0.75),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _StartBadge extends StatelessWidget {
  final String text;
  final bool isClickable;
  final VoidCallback? onTap;
  final Color accentColor;

  const _StartBadge({
    required this.text,
    required this.isClickable,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = accentColor.withOpacity(
      AppColors.isDark(context) ? 0.18 : 0.13,
    );

    final borderColor = accentColor.withOpacity(
      AppColors.isDark(context) ? 0.18 : 0.12,
    );

    final content = Container(
      padding: EdgeInsets.fromLTRB(
        isClickable ? 11 : 12,
        7,
        12,
        7,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isClickable) ...[
            Icon(
              Icons.add_a_photo_rounded,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ],
      ),
    );

    if (!isClickable) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        child: content,
      ),
    );
  }
}