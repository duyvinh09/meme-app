import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/localization_extension.dart';
import 'streak_detail_sheet.dart';

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

  String _motivationalText(BuildContext context, bool isVi) {
    if (streak >= 100) {
      return isVi
          ? 'Huyền thoại bất bại! 👑'
          : 'Undefeated Legend! 👑';
    }
    if (streak >= 60) {
      return isVi
          ? 'Kỷ lục siêu ấn tượng! 💎'
          : 'Incredible Milestone! 💎';
    }
    if (streak >= 30) {
      return isVi
          ? 'Xuất sắc! Phong độ đỉnh cao! 🏆'
          : 'Legendary streak! Keep it up! 🏆';
    }
    if (streak >= 21) {
      return isVi
          ? 'Thói quen vững vàng! 🎯'
          : 'Solid Habit Master! 🎯';
    }
    if (streak >= 14) {
      return isVi
          ? 'Tuyệt đỉnh! Chuỗi bùng cháy! 🔥'
          : 'On fire! Keep shining! 🔥';
    }
    if (streak >= 7) {
      return isVi
          ? 'Rất chăm chỉ! Duy trì đều đặn! ⭐'
          : 'Great habit! Keep going! ⭐';
    }
    if (streak >= 3) {
      return isVi
          ? 'Đang vào guồng rất tốt! 🚀'
          : 'Building momentum! 🚀';
    }
    if (streak >= 1) {
      return isVi
          ? 'Khởi đầu tuyệt vời! ✨'
          : 'Great start today! ✨';
    }
    return isVi
        ? 'Ghi chép khoảnh khắc hôm nay! ✨'
        : 'Log a moment today! ✨';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    // Original Streak color palette blending with theme
    final cardStart = isDark
        ? Color.lerp(AppColors.darkCard, fireColor, 0.08)!
        : Color.lerp(AppColors.lightCard, fireColor, 0.08)!;

    final cardEnd = isDark
        ? Color.lerp(AppColors.darkSurface, fireColor, 0.12)!
        : Color.lerp(const Color(0xFFFFF8F2), fireColor, 0.12)!;

    final cardBorder = isDark
        ? fireColor.withValues(alpha: 0.24)
        : fireColor.withValues(alpha: 0.18);

    final topLayerBg = cardStart.withValues(alpha: isDark ? 0.38 : 0.45);
    final midLayerBg = cardStart.withValues(alpha: isDark ? 0.68 : 0.75);

    final mainCard = GestureDetector(
      onTap: () => StreakDetailSheet.show(context),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card Body with Bottom-Right Cutout Pocket
          ClipPath(
            clipper: const _StreakCardClipper(
              cornerRadius: 24,
              cutoutWidth: 120,
              cutoutHeight: 44,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardStart,
                    cardEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: fireColor.withValues(alpha: isDark ? 0.12 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Fire Circle Icon + Streak Title + Motivational Subtitle + Raised Dots
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular container with red/fire theme
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fireColor.withValues(alpha: isDark ? 0.18 : 0.14),
                          border: Border.all(
                            color: fireColor.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: fireColor.withValues(alpha: 0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            size: 30,
                            color: fireColor,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Text info (Title: Streak, Subtitle: Motivational text)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.streak,
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _motivationalText(context, isVi),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fireColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Middle Row: Single Tag (Top Legend / Cực đỉnh)
                  Padding(
                    padding: const EdgeInsets.only(left: 62),
                    child: _StreakTag(
                      text: badgeText(context),
                      color: fireColor,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Bottom Row: Streak Days info on left
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Text(
                          '$streak ${isVi ? 'Ngày' : 'Days'}',
                          style: TextStyle(
                            color: fireColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          isVi ? ' /liên tục' : ' /consecutive',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom-Right Cutout Button: "Chi tiết ↗" nestled snugly in pocket
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => StreakDetailSheet.show(context),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cardBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.22 : 0.08,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isVi ? 'Chi tiết' : 'Details',
                        style: TextStyle(
                          color: fireColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.north_east_rounded,
                        size: 14,
                        color: fireColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lớp xếp chồng thứ 1 (trên cùng, lùi về sau, nhô cao hơn)
        Positioned(
          top: 0,
          left: 28,
          right: 28,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: topLayerBg,
              border: Border.all(
                color: cardBorder.withValues(alpha: isDark ? 0.16 : 0.12),
              ),
            ),
          ),
        ),
        // Lớp xếp chồng thứ 2 (ở giữa, nhô ra vừa phải)
        Positioned(
          top: 10,
          left: 14,
          right: 14,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: midLayerBg,
              border: Border.all(
                color: cardBorder.withValues(alpha: isDark ? 0.20 : 0.15),
              ),
            ),
          ),
        ),
        // Thẻ chính phía trước (offset top 20px để 2 lớp sau lộ rõ ràng hơn)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: mainCard,
        ),
      ],
    );
  }
}

class _StreakTag extends StatelessWidget {
  final String text;
  final Color color;

  const _StreakTag({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.5,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.16),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

class _StreakCardClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double cutoutWidth;
  final double cutoutHeight;

  const _StreakCardClipper({
    this.cornerRadius = 24,
    this.cutoutWidth = 120,
    this.cutoutHeight = 44,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final cutW = cutoutWidth;
    final cutH = cutoutHeight;
    const fillet = 16.0;

    final path = Path();

    // 1. Start at top-left
    path.moveTo(0, r);
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 2. Top edge
    path.lineTo(w - r, 0);

    // 3. Top-right corner
    path.arcToPoint(
      Offset(w, r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 4. Right edge down towards cutout pocket
    path.lineTo(w, h - cutH - fillet);

    // 5. Concave fillet into horizontal cutout top line
    path.quadraticBezierTo(
      w,
      h - cutH,
      w - fillet,
      h - cutH,
    );

    // 6. Horizontal line along top of cutout pocket
    path.lineTo(w - cutW + fillet, h - cutH);

    // 7. Concave fillet curving down into vertical cutout left wall
    path.quadraticBezierTo(
      w - cutW,
      h - cutH,
      w - cutW,
      h - cutH + fillet,
    );

    // 8. Vertical line down
    path.lineTo(w - cutW, h - fillet);

    // 9. Fillet curve from vertical cutout wall into bottom edge
    path.quadraticBezierTo(
      w - cutW,
      h,
      w - cutW - fillet,
      h,
    );

    // 10. Bottom edge to bottom-left corner
    path.lineTo(r, h);

    // 11. Bottom-left corner
    path.arcToPoint(
      Offset(0, h - r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _StreakCardClipper oldClipper) => false;
}