import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/theme/camera_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/profile_controller.dart';

class CameraThemePickerScreen extends StatelessWidget {
  const CameraThemePickerScreen({super.key});

  static const int requiredStreak = 3;

  void _selectTheme(
    BuildContext context,
    ProfileController profile,
    CameraThemeData theme,
    bool isLocked,
  ) {
    if (isLocked) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.cameraThemeLockedNotice,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    if (profile.cameraTheme == theme.id) return;

    final myUid = context.read<AuthController>().user?.uid;
    HapticFeedback.mediumImpact();
    profile.setCameraTheme(theme.id, myUid);

    final themeName = theme.getName(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.cameraThemeChangedSuccess(themeName),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.shutterAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final home = context.watch<HomeController>();
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final l10n = context.l10n;

    final currentStreak = home.profile?.currentStreak ?? profile.user?.currentStreak ?? 0;
    final isAllThemesUnlocked = currentStreak >= requiredStreak;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Standard Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                12,
                AppSizes.pagePadding,
                0,
              ),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.cameraTheme,
                      style: AppTextStyles.pageTitle(context).copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  10,
                  AppSizes.pagePadding,
                  32,
                ),
                children: [
                  // Streak Status Banner
                  _StreakStatusBanner(
                    currentStreak: currentStreak,
                    requiredStreak: requiredStreak,
                    isUnlocked: isAllThemesUnlocked,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      l10n.cameraThemePickerSubtitle,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),

                  // Theme Cards
                  ...CameraThemes.all.map((theme) {
                    final isDefaultTheme = theme.id == 'classic_dark';
                    final isLocked = !isAllThemesUnlocked && !isDefaultTheme;
                    final isSelected = profile.cameraTheme == theme.id && !isLocked;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CameraThemeCard(
                        theme: theme,
                        isSelected: isSelected,
                        isLocked: isLocked,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: () => _selectTheme(context, profile, theme, isLocked),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakStatusBanner extends StatelessWidget {
  final int currentStreak;
  final int requiredStreak;
  final bool isUnlocked;
  final bool isDark;

  const _StreakStatusBanner({
    required this.currentStreak,
    required this.requiredStreak,
    required this.isUnlocked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isUnlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF5722).withValues(alpha: isDark ? 0.18 : 0.10),
              const Color(0xFFFF9800).withValues(alpha: isDark ? 0.12 : 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF5722).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF5722).withValues(alpha: 0.20),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF5722),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.unlockedStatus,
                    style: const TextStyle(
                      color: Color(0xFFFF5722),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.cameraThemeUnlockedBanner(currentStreak),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final progress = (currentStreak / requiredStreak).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2232) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9800).withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFFF9800),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.cameraThemeStreakRequirement,
                          style: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.streakProgressFraction(currentStreak, requiredStreak),
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.cameraThemeStreakBanner(requiredStreak, currentStreak),
                      style: TextStyle(
                        color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF1F2937),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraThemeCard extends StatelessWidget {
  final CameraThemeData theme;
  final bool isSelected;
  final bool isLocked;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _CameraThemeCard({
    required this.theme,
    required this.isSelected,
    required this.isLocked,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E2B) : AppColors.card(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? theme.shutterAccent
                : (isLocked
                    ? AppColors.border(context).withValues(alpha: 0.6)
                    : AppColors.border(context)),
            width: isSelected ? 2.2 : 1.1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.shutterAccent.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Opacity(
          opacity: isLocked ? 0.68 : 1.0,
          child: Column(
            children: [
              Row(
                children: [
                  // Mini Mock Camera Viewfinder
                  Container(
                    width: 80,
                    height: 80,
                    padding: theme.frameGradient != null
                        ? const EdgeInsets.all(2.0)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      gradient: theme.frameGradient ?? theme.backgroundGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: theme.frameGradient != null
                          ? null
                          : Border.all(
                              color: theme.frameBorderColor,
                              width: 2.0,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.frameBorderColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        gradient: theme.backgroundGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Mini Flash & Zoom indicators
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: theme.glassButtonBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.glassButtonBorder,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.flash_on_rounded,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: theme.glassButtonBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.glassButtonBorder,
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  '1x',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Center Focus Target or Lock icon
                          if (isLocked)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: Color(0xFFFF9800),
                                size: 18,
                              ),
                            )
                          else
                            Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 26,
                            ),

                          // Mini Bottom Shutter Button
                          Positioned(
                            bottom: 6,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.shutterAccent,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Theme Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                theme.getName(context),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.shutterAccent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                                ),
                                child: Text(
                                  l10n.appIconInUse,
                                  style: TextStyle(
                                    color: theme.shutterAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ] else if (isLocked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                                  border: Border.all(
                                    color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lock_rounded,
                                      size: 10,
                                      color: Color(0xFFFF9800),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      l10n.cameraThemeStreakRequirement,
                                      style: const TextStyle(
                                        color: Color(0xFFFF9800),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          theme.getDescription(context),
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary.withValues(alpha: 0.85),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Palette Color Dots
                        Row(
                          children: theme.themePreviewDots.map((color) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.1),
                                  width: 1.2,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Radio or Lock Indicator
                  if (isLocked)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF9800).withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: Color(0xFFFF9800),
                      ),
                    )
                  else
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.shutterAccent
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? theme.shutterAccent
                              : textSecondary.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.black,
                            )
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

