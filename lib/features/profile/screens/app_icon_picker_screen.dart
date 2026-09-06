import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/services/app_icon_service.dart';
import '../../../core/widgets/app_back_button.dart';

class AppIconPickerScreen extends StatefulWidget {
  const AppIconPickerScreen({super.key});

  @override
  State<AppIconPickerScreen> createState() => _AppIconPickerScreenState();
}

class _AppIconPickerScreenState extends State<AppIconPickerScreen> {
  String _currentIcon = 'default';
  bool _isLoading = true;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentIcon();
  }

  Future<void> _loadCurrentIcon() async {
    final icon = await AppIconService.getCurrentIcon();
    if (mounted) {
      setState(() {
        _currentIcon = icon;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectIcon(AppIconOption option) async {
    if (_currentIcon == option.id || _isSwitching) return;

    setState(() {
      _isSwitching = true;
    });

    HapticFeedback.mediumImpact();

    final success = await AppIconService.setAppIcon(option.id);

    if (!mounted) return;

    setState(() {
      if (success) {
        _currentIcon = option.id;
      }
      _isSwitching = false;
    });

    final iconName = option.getName(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.appIconChangedSuccess(iconName),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primaryBlue,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.appIconChangeFailed,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.expense,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                      l10n.appIcon,
                      style: AppTextStyles.pageTitle(context).copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final isSmall = width < 370;
                        final isTablet = width >= 600;
                        final cols = isTablet ? 3 : 2;
                        final aspectRatio = isTablet ? 0.9 : (isSmall ? 0.76 : 0.80);

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.pagePadding,
                            6,
                            AppSizes.pagePadding,
                            32,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: aspectRatio,
                          ),
                          itemCount: AppIconService.availableIcons.length,
                          itemBuilder: (context, index) {
                            final option = AppIconService.availableIcons[index];
                            final isSelected = _currentIcon == option.id;

                            return _IconGridCard(
                              option: option,
                              isSelected: isSelected,
                              isDark: isDark,
                              isSmall: isSmall,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onTap: () => _selectIcon(option),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconGridCard extends StatelessWidget {
  final AppIconOption option;
  final bool isSelected;
  final bool isDark;
  final bool isSmall;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _IconGridCard({
    required this.option,
    required this.isSelected,
    required this.isDark,
    this.isSmall = false,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconBoxSize = isSmall ? 70.0 : 82.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 14,
          vertical: isSmall ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E2B) : AppColors.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.border(context),
            width: isSelected ? 2.2 : 1.1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview of Icon Image
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  option.assetPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Icon Name
            Text(
              option.getName(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 10),

            // Active Badge / Radio Check
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : textSecondary.withValues(alpha: 0.25),
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    isSelected ? l10n.appIconInUse : '',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : textSecondary.withValues(alpha: 0.6),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!isSelected)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
