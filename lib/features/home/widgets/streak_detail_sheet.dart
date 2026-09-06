import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/avatar_frames.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';
import '../controllers/home_controller.dart';

class StreakDetailSheet extends StatefulWidget {
  final UserModel? user;
  final bool hasPostedToday;

  const StreakDetailSheet({
    super.key,
    required this.user,
    this.hasPostedToday = false,
  });

  static Future<void> show(
    BuildContext context, {
    UserModel? user,
    bool? hasPostedToday,
  }) {
    final home = context.read<HomeController>();
    final targetUser = user ?? home.profile;
    final now = DateTime.now();

    final postedToday = hasPostedToday ??
        home.transactions.any((tx) {
          return tx.createdAt.year == now.year &&
              tx.createdAt.month == now.month &&
              tx.createdAt.day == now.day;
        });

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreakDetailSheet(
        user: targetUser,
        hasPostedToday: postedToday,
      ),
    );
  }

  @override
  State<StreakDetailSheet> createState() => _StreakDetailSheetState();
}

class _StreakDetailSheetState extends State<StreakDetailSheet> {
  late String _equippedFrameId;

  @override
  void initState() {
    super.initState();
    _equippedFrameId = widget.user?.avatarFrame ?? 'plain';
  }

  Future<void> _handleSelectFrame(AvatarFrameItem frame) async {
    final streak = widget.user?.currentStreak ?? 0;
    final bestStreak = widget.user?.bestStreak ?? 0;
    if (!frame.isUnlocked(streak, bestStreak: bestStreak)) {
      AppToast.show(
        context,
        context.l10n.needStreakToUnlock(frame.requiredStreak, frame.name),
        icon: Icons.lock_rounded,
      );
      return;
    }

    if (_equippedFrameId == frame.id) return;

    HapticFeedback.selectionClick();

    setState(() {
      _equippedFrameId = frame.id;
    });

    final uid = widget.user?.uid ?? context.read<AuthController>().user?.uid;
    if (uid != null) {
      await context
          .read<ProfileController>()
          .updateAvatarFrame(uid, frame.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final user = widget.user;
    final currentStreak = user?.currentStreak ?? 0;
    final bestStreak = user?.bestStreak ?? 0;
    final effectiveStreak = currentStreak > bestStreak ? currentStreak : bestStreak;
    final avatarUrl = user?.avatarUrl ?? '';
    final nextMilestone = AvatarFrames.getNextMilestone(currentStreak, bestStreak: bestStreak);

    final sheetBg = isDark ? const Color(0xFF141722) : AppColors.card(context);
    final cardBg = isDark ? const Color(0xFF1C1F2B) : AppColors.surface(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final maxRatio = screenHeight < 700 ? 0.80 : 0.82;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * maxRatio,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle and Close Button Row
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [

              // Title with Flame Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF416C).withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF416C).withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF416C),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.dailyMemeStreak,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3-Column Stats: Streak | Best Streak | Collection
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Streak Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2232) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFF5722).withValues(alpha: 0.12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Color(0xFFFF5722),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.l10n.daysStreak(currentStreak),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.l10n.streakMaintaining,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Best Streak Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2232) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFB300).withValues(alpha: 0.14),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  color: Color(0xFFFFB300),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.l10n.daysStreak(bestStreak),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.l10n.bestStreakLabel,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Collection Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2232) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF388AF6).withValues(alpha: 0.12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Color(0xFF388AF6),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.l10n.framesCount(
                                  AvatarFrames.getUnlockedCount(currentStreak, bestStreak: bestStreak),
                                  AvatarFrames.all.length,
                                ),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.l10n.unlockedStatus,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Streak Subtitle & Motivation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181B26) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.hasPostedToday
                      ? context.l10n.hasPostedStreakMotivation
                      : context.l10n.notPostedStreakMotivation,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section: Khung viền avatar & Collection Badge
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.avatarFrameCollectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      context.l10n.unlockedBadgeCount(
                        AvatarFrames.getUnlockedCount(currentStreak, bestStreak: bestStreak),
                        AvatarFrames.all.length,
                      ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Avatar Frames List
              SizedBox(
                height: 148,
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: AvatarFrames.all.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final frame = AvatarFrames.all[index];
                    final isUnlocked = frame.isUnlocked(currentStreak, bestStreak: bestStreak);
                    final isEquipped = _equippedFrameId == frame.id;

                    return GestureDetector(
                      onTap: () => _handleSelectFrame(frame),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Frame Preview Circle
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Halo if equipped
                                if (isEquipped)
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (frame.glowColor != Colors.transparent
                                                  ? frame.glowColor
                                                  : const Color(0xFF388AF6))
                                              .withValues(alpha: 0.55),
                                          blurRadius: 16,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),

                                // Avatar with frame
                                Opacity(
                                  opacity: isUnlocked ? 1.0 : 0.45,
                                  child: AvatarWithFrame(
                                    avatarUrl: avatarUrl,
                                    frameId: frame.id,
                                    size: 54,
                                    showGlow: isEquipped,
                                  ),
                                ),

                                // Lock badge if locked
                                if (!isUnlocked)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E212E)
                                            : const Color(0xFF4A4E5C),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: sheetBg,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.lock_rounded,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Frame Name
                            Text(
                              frame.getName(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isEquipped ? FontWeight.w800 : FontWeight.w600,
                                color: isEquipped
                                    ? (isDark ? Colors.white : AppColors.primaryBlueDark)
                                    : textPrimary,
                              ),
                            ),

                            const SizedBox(height: 2),

                            // Required streak or Equipped Pill
                            if (isEquipped)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                                ),
                                child: Text(
                                  context.l10n.currentEquipped,
                                  style: const TextStyle(
                                    color: Color(0xFF60A5FA),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                              )
                            else
                              Text(
                                '${frame.requiredStreak}+',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 26),

              // Section: Mốc tiếp theo
              Text(
                context.l10n.nextMilestone,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 12),

              // Next Milestone Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 1.2,
                  ),
                ),
                child: nextMilestone != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.daysLeftToUnlock(
                              nextMilestone.requiredStreak - effectiveStreak,
                              nextMilestone.getName(context),
                            ),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (effectiveStreak / nextMilestone.requiredStreak)
                                  .clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF388AF6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$effectiveStreak / ${nextMilestone.requiredStreak}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.celebration_rounded,
                                    color: Color(0xFF10B981),
                                    size: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.l10n.allFramesUnlocked,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 1.0,
                              minHeight: 7,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF34C759),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy tiếp tục duy trì chuỗi khoảnh khắc tuyệt vời mỗi ngày!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
),
);
  }
}
