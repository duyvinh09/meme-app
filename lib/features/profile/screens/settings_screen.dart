import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final myUid = context.watch<AuthController>().user?.uid;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            12,
            AppSizes.pagePadding,
            24,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  _TopCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    l10n.settings,
                    style: AppTextStyles.pageTitle(context).copyWith(
                      fontSize: 26,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 52),
                ],
              ),
            ),

            _SettingsSection(
              title: l10n.language,
              children: [
                _SettingsOptionTile(
                  flagEmoji: '🇻🇳',
                  iconColor: AppColors.expense,
                  title: l10n.vietnamese,
                  selected: profile.languageCode == 'vi',
                  onTap: () => profile.setLanguage('vi', myUid),
                ),
                _SettingsOptionTile(
                  flagEmoji: '🇺🇸',
                  iconColor: AppColors.primaryBlue,
                  title: l10n.english,
                  selected: profile.languageCode == 'en',
                  onTap: () => profile.setLanguage('en', myUid),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsSection(
              title: l10n.appearance,
              children: [
                _SettingsOptionTile(
                  icon: Icons.light_mode_outlined,
                  iconColor: AppColors.warning,
                  title: l10n.light,
                  selected: profile.themeMode.name == 'light',
                  onTap: () => profile.setThemeMode('light', myUid),
                ),
                _SettingsOptionTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: AppColors.primaryPurple,
                  title: l10n.dark,
                  selected: profile.themeMode.name == 'dark',
                  onTap: () => profile.setThemeMode('dark', myUid),
                ),
                _SettingsOptionTile(
                  icon: Icons.settings_suggest_outlined,
                  iconColor: AppColors.primaryBlue,
                  title: l10n.system,
                  selected: profile.themeMode.name == 'system',
                  onTap: () => profile.setThemeMode('system', myUid),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsSection(
              title: l10n.appIconSection,
              children: [
                _SettingsActionTile(
                  icon: Icons.app_shortcut_rounded,
                  iconColor: AppColors.primaryBlue,
                  title: l10n.appIcon,
                  subtitle: l10n.appIconSubtitle,
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.appIcon);
                  },
                ),
                _SettingsActionTile(
                  icon: Icons.camera_alt_outlined,
                  iconColor: AppColors.primaryPurple,
                  title: l10n.cameraThemeSection,
                  subtitle: l10n.cameraThemeSubtitle,
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.cameraTheme);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsSection(
              title: l10n.currency,
              children: [
                _SettingsOptionTile(
                  flagEmoji: '🇻🇳',
                  iconColor: AppColors.income,
                  title: l10n.vnd,
                  selected: profile.currency == 'VND',
                  onTap: () => profile.setCurrency('VND', myUid),
                ),
                _SettingsOptionTile(
                  flagEmoji: '🇺🇸',
                  iconColor: AppColors.primaryBlue,
                  title: l10n.usd,
                  selected: profile.currency == 'USD',
                  onTap: () => profile.setCurrency('USD', myUid),
                ),
                const _ExchangeRateRow(),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsSection(
              title: l10n.privacySection,
              children: [
                _SettingsSwitchTile(
                  icon: Icons.sensors_rounded,
                  iconColor: profile.showActiveStatus
                      ? const Color(0xFF10B981)
                      : AppColors.textSecondary(context),
                  title: l10n.activeStatusTitle,
                  subtitle: l10n.activeStatusSubtitle,
                  value: profile.showActiveStatus,
                  onChanged: (val) => profile.setShowActiveStatus(val, myUid),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card(context),
          border: Border.all(
            color: AppColors.border(context),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary(context),
          size: 20,
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Text(
              title,
              style: AppTextStyles.sectionTitle(context).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsOptionTile extends StatelessWidget {
  final IconData? icon;
  final String? flagEmoji;
  final Color iconColor;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsOptionTile({
    this.icon,
    this.flagEmoji,
    required this.iconColor,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTileBg = AppColors.isDark(context)
        ? AppColors.primaryBlue.withValues(alpha: 0.10)
        : const Color(0xFFF0F6FF);

    final selectedTileBorder = AppColors.isDark(context)
        ? AppColors.primaryBlue.withValues(alpha: 0.32)
        : const Color(0xFFBFD7FF);

    final radioBorder = AppColors.isDark(context)
        ? const Color(0xFF4A5062)
        : const Color(0xFFC9D1DD);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected ? selectedTileBg : AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: selected ? selectedTileBorder : AppColors.innerBorder(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.14),
              ),
              child: Center(
                child: flagEmoji != null
                    ? Text(
                  flagEmoji!,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1,
                  ),
                )
                    : Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body(context).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primaryBlue : radioBorder,
                  width: 1.8,
                ),
              ),
              child: selected
                  ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: AppColors.innerBorder(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary(context).withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeRateRow extends StatefulWidget {
  const _ExchangeRateRow();

  @override
  State<_ExchangeRateRow> createState() => _ExchangeRateRowState();
}

class _ExchangeRateRowState extends State<_ExchangeRateRow> {
  bool isUpdating = false;

  Future<void> _refreshRate() async {
    if (isUpdating) return;

    setState(() {
      isUpdating = true;
    });

    await ExchangeRateService.refresh();

    if (!mounted) return;

    setState(() {
      isUpdating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: AppDurations.snackBar,
        content: Text(
          context.l10n.exchangeRateUpdated(AppCurrencyFormatter.rateText()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppCurrencyFormatter.rateText(),
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: isUpdating ? null : _refreshRate,
            icon: isUpdating
                ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label: Text(
              isUpdating ? l10n.updating : l10n.update,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: AppColors.innerBorder(context),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 12.5,
                        color: AppColors.textSecondary(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch.adaptive(
              value: value,
              activeTrackColor: AppColors.primaryBlue,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                onChanged(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}