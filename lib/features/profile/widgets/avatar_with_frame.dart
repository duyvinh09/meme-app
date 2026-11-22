import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/avatar_frames.dart';
import 'avatar_frame_painter.dart';

class AvatarWithFrame extends StatelessWidget {
  final String avatarUrl;
  final String? frameId;

  /// Original avatar diameter; ornaments may extend slightly beyond the rim.
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
    final isHighTier = frame.requiredStreak >= 100;
    final isUltraTier = frame.requiredStreak >= 400;
    final borderWidth =
        (size * (isUltraTier ? 0.075 : (isHighTier ? 0.065 : 0.055)))
            .clamp(2.0, 5.5);
    final innerPadding = (borderWidth * 0.9).clamp(2.0, 4.0);

    final avatarCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: frame.gradient,
        boxShadow: showGlow && frame.glowColor != Colors.transparent
            ? [
                BoxShadow(
                  color: frame.glowColor.withValues(alpha: 0.18),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ]
            : null,
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
                ? CachedNetworkImageProvider(avatarUrl.trim())
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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: AvatarFramePainter(
          frame: frame,
          size: size,
          showGlow: showGlow,
        ),
        child: avatarCore,
      ),
    );
  }
}
