import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/avatar_frames.dart';
import 'avatar_frame_painter.dart';

class AvatarWithFrame extends StatelessWidget {
  final String avatarUrl;
  final String? frameId;
  final double size;
  final VoidCallback? onTap;
  final IconData placeholderIcon;
  final bool showGlow;

  const AvatarWithFrame({
    super.key,
    required this.avatarUrl,
    this.frameId,
    this.size = 54.0,
    this.onTap,
    this.placeholderIcon = Icons.person_rounded,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final frame = AvatarFrames.getById(frameId);
    final hasGlow = showGlow && frame.glowColor != Colors.transparent;
    final isHighTier = frame.requiredStreak >= 100;
    final isUltraTier = frame.requiredStreak >= 400;

    final borderWidth = (size * (isUltraTier ? 0.075 : (isHighTier ? 0.065 : 0.055)))
        .clamp(2.0, 5.5);
    final innerPadding = (borderWidth * 0.9).clamp(2.0, 4.0);

    // Multi-layered box shadows for ultra-rich glowing aura
    List<BoxShadow>? shadows;
    if (hasGlow) {
      final List<BoxShadow> list = [
        BoxShadow(
          color: frame.glowColor.withValues(alpha: isUltraTier ? 0.55 : 0.40),
          blurRadius: size * (isUltraTier ? 0.32 : 0.22),
          spreadRadius: isUltraTier ? 2.5 : (isHighTier ? 1.5 : 0.8),
        ),
      ];

      if (frame.secondaryGlowColor != null) {
        list.add(
          BoxShadow(
            color: frame.secondaryGlowColor!.withValues(alpha: isUltraTier ? 0.45 : 0.30),
            blurRadius: size * (isUltraTier ? 0.45 : 0.35),
            spreadRadius: isUltraTier ? 3.5 : 2.0,
          ),
        );
      }

      if (isUltraTier) {
        list.add(
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.30),
            blurRadius: size * 0.15,
            spreadRadius: 0.5,
          ),
        );
      }

      shadows = list;
    }

    Widget avatarCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: frame.gradient,
        boxShadow: shadows,
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPadding),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.card(context),
          ),
          padding: const EdgeInsets.all(2.0),
          child: CircleAvatar(
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
            backgroundImage: avatarUrl.trim().isNotEmpty
                ? NetworkImage(avatarUrl.trim())
                : null,
            child: avatarUrl.trim().isEmpty
                ? Icon(
                    placeholderIcon,
                    color: AppColors.primaryBlue,
                    size: size * 0.48,
                  )
                : null,
          ),
        ),
      ),
    );

    // Wrap with detailed vector frame painter (Wings, Horns, Crown, Orbit, Flares, Stars)
    Widget decoratedAvatar = CustomPaint(
      painter: AvatarFramePainter(
        frame: frame,
        size: size,
        showGlow: showGlow,
      ),
      child: avatarCore,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: decoratedAvatar,
      );
    }

    return decoratedAvatar;
  }
}
