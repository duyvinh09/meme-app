import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/meme_logo.dart';

/// Shared brand treatment for the two account entry screens.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    required this.title,
    required this.subtitle,
    this.compact = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        children: [
          Semantics(
            label: 'Meme',
            image: true,
            child: const ExcludeSemantics(
              child: MemeLogo(height: 48, showSubtitle: false),
            ),
          ),
          SizedBox(height: compact ? AppSizes.gapLarge : AppSizes.gapXLarge),
          if (!compact) ...[
            const _MomentIllustration(),
            const SizedBox(height: AppSizes.gapXLarge),
          ],
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context),
            ),
          ),
          const SizedBox(height: AppSizes.gapSmall),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary(context),
          ),
        ],
      ),
    );
  }
}

class _MomentIllustration extends StatelessWidget {
  const _MomentIllustration();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 128,
        width: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PositionedDirectional(
              start: 22,
              child: Transform.rotate(
                angle: -0.14,
                child: const _MomentTile(
                  icon: Icons.photo_camera_rounded,
                  filled: true,
                ),
              ),
            ),
            PositionedDirectional(
              end: 22,
              top: 15,
              child: Transform.rotate(
                angle: 0.12,
                child: const _MomentTile(
                  icon: Icons.savings_outlined,
                  filled: false,
                ),
              ),
            ),
            const PositionedDirectional(
              end: 8,
              top: 0,
              child: Icon(Icons.auto_awesome, color: AppColors.primaryBlue),
            ),
            const PositionedDirectional(
              start: 8,
              bottom: 0,
              child: Icon(Icons.favorite_rounded,
                  size: AppSizes.iconSmall, color: AppColors.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({required this.icon, required this.filled});

  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(AppSizes.gapSmall),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border:
            Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.35)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled
              ? AppColors.primaryBlue
              : AppColors.primaryBlue.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: Icon(
          icon,
          size: 38,
          color: filled
              ? AppColors.foregroundOnAccent(AppColors.primaryBlue)
              : AppColors.textPrimary(context),
        ),
      ),
    );
  }
}
