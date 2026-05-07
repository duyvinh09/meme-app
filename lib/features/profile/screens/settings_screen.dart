import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/profile_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();

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
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Cài đặt',
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
              title: 'Ngôn ngữ',
              children: [
                _SettingsOptionTile(
                  flagEmoji: '🇻🇳',
                  iconColor: AppColors.expense,
                  title: 'Tiếng Việt',
                  selected: profile.languageCode == 'vi',
                  onTap: () => profile.setLanguage('vi'),
                ),
                _SettingsOptionTile(
                  flagEmoji: '🇺🇸',
                  iconColor: AppColors.primaryBlue,
                  title: 'English',
                  selected: profile.languageCode == 'en',
                  onTap: () => profile.setLanguage('en'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsSection(
              title: 'Giao diện',
              children: [
                _SettingsOptionTile(
                  icon: Icons.light_mode_outlined,
                  iconColor: AppColors.warning,
                  title: 'Sáng',
                  selected: profile.themeMode.name == 'light',
                  onTap: () => profile.setThemeMode('light'),
                ),
                _SettingsOptionTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: AppColors.primaryPurple,
                  title: 'Tối',
                  selected: profile.themeMode.name == 'dark',
                  onTap: () => profile.setThemeMode('dark'),
                ),
                _SettingsOptionTile(
                  icon: Icons.settings_suggest_outlined,
                  iconColor: AppColors.primaryBlue,
                  title: 'Theo hệ thống',
                  selected: profile.themeMode.name == 'system',
                  onTap: () => profile.setThemeMode('system'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsSection(
              title: 'Tiền tệ',
              children: [
                _SettingsOptionTile(
                  flagEmoji: '🇻🇳',
                  iconColor: AppColors.income,
                  title: 'VNĐ',
                  selected: profile.currency == 'VND',
                  onTap: () => profile.setCurrency('VND'),
                ),
                _SettingsOptionTile(
                  flagEmoji: '🇺🇸',
                  iconColor: AppColors.primaryBlue,
                  title: 'USD',
                  selected: profile.currency == 'USD',
                  onTap: () => profile.setCurrency('USD'),
                ),
                const _ExchangeRateRow(),
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
        width: 52,
        height: 52,
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
        ? AppColors.primaryBlue.withOpacity(0.10)
        : const Color(0xFFF0F6FF);

    final selectedTileBorder = AppColors.isDark(context)
        ? AppColors.primaryBlue.withOpacity(0.32)
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
                color: iconColor.withOpacity(0.14),
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
        content: Text(
          'Đã cập nhật tỷ giá: ${AppCurrencyFormatter.rateText()}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              isUpdating ? 'Đang cập nhật' : 'Cập nhật',
            ),
          ),
        ],
      ),
    );
  }
}