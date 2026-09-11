import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/streak_milestones.dart';
import '../../../core/extensions/localization_extension.dart';
import 'streak_milestone_painter.dart';

class StreakMilestoneDialog extends StatefulWidget {
  final StreakMilestone milestone;

  const StreakMilestoneDialog({
    super.key,
    required this.milestone,
  });

  /// Shows the streak milestone celebration dialog.
  static Future<void> show(
    BuildContext context, {
    required StreakMilestone milestone,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StreakMilestoneDismiss',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StreakMilestoneDialog(milestone: milestone);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.easeOutCubic.transform(anim1.value);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * curve,
            sigmaY: 8.0 * curve,
          ),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<StreakMilestoneDialog> createState() => _StreakMilestoneDialogState();
}

class _StreakMilestoneDialogState extends State<StreakMilestoneDialog>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _ambientController;

  // Staggered Animation Intervals
  late final Animation<double> _cardScaleAnimation;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _iconGlowAnimation;
  late final Animation<double> _burstAnimation;
  late final Animation<double> _numberScaleAnimation;
  late final Animation<double> _numberFadeAnimation;
  late final Animation<double> _messageFadeAnimation;
  late final Animation<Offset> _messageSlideAnimation;
  late final Animation<double> _buttonFadeAnimation;
  late final Animation<double> _buttonScaleAnimation;

  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();

    final tier = widget.milestone.tier;
    final introDuration = switch (tier) {
      MilestoneTier.tier1 => const Duration(milliseconds: 1300),
      MilestoneTier.tier2 => const Duration(milliseconds: 1600),
      MilestoneTier.tier3 => const Duration(milliseconds: 1900),
      MilestoneTier.tier4 => const Duration(milliseconds: 2200),
    };

    _introController = AnimationController(
      vsync: this,
      duration: introDuration,
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    // 1. Overall Card Scale / Pop
    _cardScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack),
      ),
    );

    // 2. Icon Scale & Glow
    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.10, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _iconGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.15, 0.60, curve: Curves.easeOut),
      ),
    );

    // 3. Particle Burst
    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.18, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Milestone Number Display
    _numberScaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.72, curve: Curves.easeOutBack),
      ),
    );

    _numberFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    // 5. Relationship Message Narrative
    _messageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.60, 0.88, curve: Curves.easeOut),
      ),
    );

    _messageSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.60, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // 6. Continue Button
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _introController.addListener(() {
      if (_introController.value >= 0.25 && !_hasTriggeredHaptic) {
        _hasTriggeredHaptic = true;
        _triggerHapticFeedback(tier);
      }
    });

    _introController.forward();
  }

  void _triggerHapticFeedback(MilestoneTier tier) {
    switch (tier) {
      case MilestoneTier.tier1:
        HapticFeedback.mediumImpact();
        break;
      case MilestoneTier.tier2:
        HapticFeedback.heavyImpact();
        break;
      case MilestoneTier.tier3:
      case MilestoneTier.tier4:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 120), () {
          HapticFeedback.mediumImpact();
        });
        break;
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final milestone = widget.milestone;
    final primary = milestone.primaryColor;
    final secondary = milestone.secondaryColor;
    final glow = milestone.glowColor;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: Listenable.merge([_introController, _ambientController]),
          builder: (context, child) {
            final burstValue = _burstAnimation.value;
            final ambientValue = _ambientController.value;

            // Compute count-up for number
            final startCount = (milestone.days * 0.85).floor().clamp(1, milestone.days);
            final countRange = milestone.days - startCount;
            final countProgress = (_numberScaleAnimation.value).clamp(0.0, 1.0);
            final currentDisplayedDays = (startCount + (countRange * countProgress)).round();

            return ScaleTransition(
              scale: _cardScaleAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141722) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glow.withValues(alpha: isDark ? 0.35 : 0.20),
                      blurRadius: 36,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Top Ambient Background Glow
                      Positioned(
                        top: -60,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                glow.withValues(alpha: isDark ? 0.25 : 0.18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top Tag: "Mở khóa cột mốc mới!"
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.30),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.l10n.streakMilestoneUnlocked,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Flame Icon with Dynamic CustomPainter Burst
                            SizedBox(
                              width: 170,
                              height: 150,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Particle & Shockwave Canvas
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: StreakMilestonePainter(
                                        burstProgress: burstValue,
                                        ambientProgress: ambientValue,
                                        tier: milestone.tier,
                                        primaryColor: primary,
                                        secondaryColor: secondary,
                                        glowColor: glow,
                                      ),
                                    ),
                                  ),
                                  // Central Floating Flame Badge with Dynamic Blazing Animation
                                  Builder(
                                    builder: (context) {
                                      final flameBreathing = 1.0 +
                                          math.sin(ambientValue * 2 * math.pi) *
                                              (0.04 + milestone.tier.index * 0.025);
                                      final angle = ambientValue * 2 * math.pi;
                                      final gradAlignA = Alignment(math.cos(angle) * 0.7, math.sin(angle) * 0.7);
                                      final gradAlignB = Alignment(-math.cos(angle) * 0.7, -math.sin(angle) * 0.7);

                                      return Transform.scale(
                                        scale: _iconScaleAnimation.value * flameBreathing,
                                        child: Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: gradAlignA,
                                              end: gradAlignB,
                                              colors: [
                                                primary,
                                                secondary,
                                                if (milestone.tier == MilestoneTier.tier4)
                                                  const Color(0xFFFFE57F),
                                              ],
                                            ),
                                            boxShadow: [
                                              // Inner intense fire glow
                                              BoxShadow(
                                                color: primary.withValues(
                                                  alpha: 0.65 * _iconGlowAnimation.value,
                                                ),
                                                blurRadius: 18 + milestone.tier.index * 6,
                                                spreadRadius: 2 + milestone.tier.index * 1.5,
                                              ),
                                              // Outer expansive blazing aura
                                              BoxShadow(
                                                color: glow.withValues(
                                                  alpha: (0.40 + milestone.tier.index * 0.08) *
                                                      _iconGlowAnimation.value,
                                                ),
                                                blurRadius: 36 + milestone.tier.index * 10,
                                                spreadRadius: 4 + milestone.tier.index * 2.5,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.local_fire_department_rounded,
                                              color: Colors.white,
                                              size: switch (milestone.tier) {
                                                MilestoneTier.tier1 => 46,
                                                MilestoneTier.tier2 => 50,
                                                MilestoneTier.tier3 => 54,
                                                MilestoneTier.tier4 => 56,
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Days Milestone Headline with Scale & Fade
                            Opacity(
                              opacity: _numberFadeAnimation.value,
                              child: Transform.scale(
                                scale: _numberScaleAnimation.value,
                                child: Column(
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [
                                          primary,
                                          secondary,
                                          if (milestone.tier == MilestoneTier.tier4)
                                            const Color(0xFFFFFFFF),
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        context.l10n.streakMilestoneDaysLabel(
                                          currentDisplayedDays,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.8,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      milestone.getTitle(context),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary(context),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Relationship Story Message (Fade + Slide up)
                            SlideTransition(
                              position: _messageSlideAnimation,
                              child: FadeTransition(
                                opacity: _messageFadeAnimation,
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E2232).withValues(alpha: 0.8)
                                            : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.06),
                                        ),
                                      ),
                                      child: Text(
                                        '“${milestone.getMessage(context)}”',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.italic,
                                          color: isDark
                                              ? const Color(0xFFE2E8F0)
                                              : const Color(0xFF334155),
                                          height: 1.45,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),

                                    // Action / Discovery Reward Hint Banner
                                    Container(
                                      margin: const EdgeInsets.only(top: 10),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: primary.withValues(alpha: 0.25),
                                          width: 0.9,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: primary.withValues(alpha: 0.18),
                                            ),
                                            child: Icon(
                                              milestone.days == 3
                                                  ? Icons.photo_camera_rounded
                                                  : Icons.workspace_premium_rounded,
                                              size: 16,
                                              color: primary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              milestone.days == 3
                                                  ? context.l10n.streakRewardCameraThemeHint
                                                  : context.l10n.streakRewardAvatarFrameHint,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? const Color(0xFFCBD5E1)
                                                    : const Color(0xFF475569),
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // "Tiếp tục" Action Button
                            FadeTransition(
                              opacity: _buttonFadeAnimation,
                              child: ScaleTransition(
                                scale: _buttonScaleAnimation,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            primary,
                                            secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withValues(alpha: 0.35),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          context.l10n.streakMilestoneContinue,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
