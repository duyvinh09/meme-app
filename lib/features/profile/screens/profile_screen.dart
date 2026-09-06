import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/avatar_frames.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/async_filled_button.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../home/widgets/streak_detail_sheet.dart';
import '../controllers/profile_controller.dart';
import '../widgets/avatar_with_frame.dart';
import 'change_email_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null) {
        context.read<ProfileController>().loadUser(uid);
      }

      loaded = true;
    }
  }

  List<Color> _heroGradient(BuildContext context) {
    if (AppColors.isDark(context)) {
      return const [
        Color(0xFF191A27),
        Color(0xFF141522),
        Color(0xFF1A1825),
      ];
    }

    return const [
      Color(0xFFF8F5FF),
      Color(0xFFF2F5FF),
      Color(0xFFF8F7FB),
    ];
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (password == null || password.trim().isEmpty) return;

    if (!context.mounted) return;

    await _deleteAccount(
      context: context,
      password: password.trim(),
    );
  }

  Future<void> _deleteAccount({
    required BuildContext context,
    required String password,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    final authController = context.read<AuthController>();
    final authRepository = authController.authRepository;
    final firebaseUser = authController.user;

    final uid = firebaseUser?.uid;
    final email = firebaseUser?.email ?? '';

    if (firebaseUser == null || uid == null || email.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.accountNotFound),
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await authRepository.reauthenticateWithPassword(
        email: email,
        password: password,
      );

      await authRepository.deleteCurrentUser();

      if (context.mounted) {
        navigator.pop();
        navigator.pushNamedAndRemoveUntil(
          RouteNames.login,
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            duration: AppDurations.snackBar,
            content: Text(
              '${context.l10n.deleteAccount}: $e',
            ),
          ),
        );
      }
    }
  }

  void _showThemePickerBottomSheet(BuildContext context) {
    final profile = context.read<ProfileController>();
    final myUid = context.read<AuthController>().user?.uid;
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D28) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.selectThemeMode,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                _ModalOptionTile(
                  icon: Icons.light_mode_outlined,
                  iconColor: AppColors.warning,
                  title: l10n.light,
                  isSelected: profile.themeMode == ThemeMode.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    profile.setThemeMode('light', myUid);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 8),
                _ModalOptionTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: AppColors.primaryPurple,
                  title: l10n.dark,
                  isSelected: profile.themeMode == ThemeMode.dark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    profile.setThemeMode('dark', myUid);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 8),
                _ModalOptionTile(
                  icon: Icons.settings_suggest_outlined,
                  iconColor: AppColors.primaryBlue,
                  title: l10n.system,
                  isSelected: profile.themeMode == ThemeMode.system,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    profile.setThemeMode('system', myUid);
                    Navigator.pop(sheetCtx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguagePickerBottomSheet(BuildContext context) {
    final profile = context.read<ProfileController>();
    final myUid = context.read<AuthController>().user?.uid;
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D28) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.selectLanguage,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                _ModalOptionTile(
                  icon: Icons.devices_rounded,
                  iconColor: const Color(0xFF388AF6),
                  title: '${l10n.systemDefault} (Auto)',
                  isSelected: profile.rawLanguageCode == 'system',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    profile.setLanguage('system', myUid);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 8),
                _ModalOptionTile(
                  flagEmoji: '🇻🇳',
                  iconColor: AppColors.expense,
                  title: l10n.vietnamese,
                  isSelected: profile.rawLanguageCode == 'vi',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    profile.setLanguage('vi', myUid);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(height: 8),
                _ModalOptionTile(
                  flagEmoji: '🇺🇸',
                  iconColor: AppColors.primaryBlue,
                  title: l10n.english,
                  isSelected: profile.rawLanguageCode == 'en',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    profile.setLanguage('en', myUid);
                    Navigator.pop(sheetCtx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrencyPickerBottomSheet(BuildContext context) {
    final profile = context.read<ProfileController>();
    final myUid = context.read<AuthController>().user?.uid;
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);
    bool isRefreshing = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D28) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.selectCurrency,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ModalOptionTile(
                      flagEmoji: '🇻🇳',
                      iconColor: AppColors.income,
                      title: l10n.vndFull,
                      isSelected: profile.currency == 'VND',
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await profile.setCurrency('VND', myUid);
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      },
                    ),
                    const SizedBox(height: 8),
                    _ModalOptionTile(
                      flagEmoji: '🇺🇸',
                      iconColor: AppColors.primaryBlue,
                      title: l10n.usdFull,
                      isSelected: profile.currency == 'USD',
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await profile.setCurrency('USD', myUid);
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF12141E)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.currency_exchange_rounded,
                            size: 20,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppCurrencyFormatter.rateText(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: isRefreshing
                                ? null
                                : () async {
                                    setSheetState(() => isRefreshing = true);
                                    await ExchangeRateService.refresh();
                                    setSheetState(() => isRefreshing = false);
                                    if (mounted) setState(() {});
                                  },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isRefreshing)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                      color: Color(0xFF388AF6),
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.update,
                                    style: const TextStyle(
                                      color: Color(0xFF388AF6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getThemeModeLabel(ThemeMode mode, BuildContext context) {
    switch (mode) {
      case ThemeMode.light:
        return context.l10n.light;
      case ThemeMode.dark:
        return context.l10n.dark;
      case ThemeMode.system:
        return context.l10n.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final auth = context.watch<AuthController>();
    final user = profile.user;

    final createdAt = user?.createdAt;
    final createdAtText = createdAt != null
        ? DateFormat('MM/yyyy').format(createdAt)
        : DateFormat('MM/yyyy').format(DateTime.now());

    final displayName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : context.l10n.user;

    final username = (user?.username.trim().isNotEmpty ?? false)
        ? user!.username.trim()
        : 'username';

    final avatarUrl = user?.avatarUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          context.l10n.profile,
          style: AppTextStyles.sectionTitle(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          8,
          AppSizes.pagePadding,
          AppSizes.bottomNavSafePadding,
        ),
        children: [
          // Hero User Profile Card
          Container(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _heroGradient(context),
              ),
              border: Border.all(
                color: AppColors.border(context),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AvatarWithFrame(
                      avatarUrl: avatarUrl,
                      frameId: user?.avatarFrame,
                      size: 120,
                    ),
                    Positioned(
                      right: 2,
                      bottom: 4,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, RouteNames.editProfile);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 10,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryPink.withValues(alpha: 0.95),
                        size: 18,
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 12,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryPurple.withValues(alpha: 0.95),
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle(context).copyWith(
                      fontSize: 28,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(
                      icon: Icons.calendar_month_rounded,
                      text: context.l10n.joined(createdAtText),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Gamification & Collection Stats Card: Streak | Best Streak | Collection
          GestureDetector(
            onTap: () {
              StreakDetailSheet.show(
                context,
                user: user,
                hasPostedToday: true,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Streak Card
                  Expanded(
                    child: _buildAchievementStat(
                      context,
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF5722),
                      iconBgColor: const Color(0xFFFF5722).withValues(alpha: 0.12),
                      value: context.l10n.shortDaysStreak(user?.currentStreak ?? 0),
                      label: context.l10n.streakMaintaining,
                    ),
                  ),
                  _buildStatDivider(context),

                  // Best Streak Card
                  Expanded(
                    child: _buildAchievementStat(
                      context,
                      icon: Icons.emoji_events_rounded,
                      iconColor: const Color(0xFFFFB300),
                      iconBgColor: const Color(0xFFFFB300).withValues(alpha: 0.14),
                      value: context.l10n.shortDaysStreak(user?.bestStreak ?? 0),
                      label: context.l10n.bestStreakLabel,
                    ),
                  ),
                  _buildStatDivider(context),

                  // Collection Card
                  Expanded(
                    child: _buildAchievementStat(
                      context,
                      icon: Icons.workspace_premium_rounded,
                      iconColor: const Color(0xFF388AF6),
                      iconBgColor: const Color(0xFF388AF6).withValues(alpha: 0.12),
                      value: context.l10n.framesCount(
                        AvatarFrames.getUnlockedCount(
                          user?.currentStreak ?? 0,
                          bestStreak: user?.bestStreak ?? 0,
                        ),
                        AvatarFrames.all.length,
                      ),
                      label: context.l10n.avatarCollection,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // GROUP 1: Overview & Connections
          _SectionTitle(title: context.l10n.generalOverview),
          _SectionCard(
            children: [
              StreamBuilder<List<String>>(
                stream: auth.user == null
                    ? const Stream.empty()
                    : context
                        .read<UserRepository>()
                        .streamFriendIds(auth.user!.uid),
                builder: (context, snapshot) {
                  final friendCount = snapshot.data?.length ?? 0;

                  return _ProfileMenuTile(
                    icon: Icons.group_rounded,
                    title: context.l10n.friends(friendCount),
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.friends);
                    },
                  );
                },
              ),
              _ProfileMenuTile(
                icon: Icons.groups_2_outlined,
                title: context.l10n.groups,
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.groups);
                },
              ),
              _ProfileMenuTile(
                icon: Icons.category_outlined,
                title: context.l10n.manageCategories,
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.manageCategories);
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // GROUP 2: Appearance & Themes
          _SectionTitle(title: context.l10n.appearanceAndThemes),
          _SectionCard(
            children: [
              _ProfileMenuTile(
                icon: profile.themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : (profile.themeMode == ThemeMode.light
                        ? Icons.light_mode_outlined
                        : Icons.settings_suggest_outlined),
                title: context.l10n.themeModeLabel,
                subtitle: _getThemeModeLabel(profile.themeMode, context),
                trailingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getThemeModeLabel(profile.themeMode, context),
                    style: const TextStyle(
                      color: Color(0xFF388AF6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () => _showThemePickerBottomSheet(context),
              ),
              _ProfileMenuTile(
                icon: Icons.app_shortcut_rounded,
                title: context.l10n.appIcon,
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.appIcon);
                },
              ),
              _ProfileMenuTile(
                icon: Icons.camera_alt_outlined,
                title: context.l10n.cameraTheme,
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.cameraTheme);
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // GROUP 3: Preferences & System
          _SectionTitle(title: context.l10n.systemPreferences),
          _SectionCard(
            children: [
              _ProfileMenuTile(
                icon: Icons.language_rounded,
                title: context.l10n.language,
                subtitle: profile.rawLanguageCode == 'system'
                    ? '${context.l10n.systemDefault} (${profile.languageCode == 'vi' ? '🇻🇳 Tiếng Việt' : '🇺🇸 English'})'
                    : (profile.languageCode == 'vi'
                        ? '🇻🇳 Tiếng Việt'
                        : '🇺🇸 English'),
                trailingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    profile.rawLanguageCode == 'system'
                        ? '⚙️ Auto'
                        : (profile.languageCode == 'vi' ? '🇻🇳 VI' : '🇺🇸 EN'),
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () => _showLanguagePickerBottomSheet(context),
              ),
              _ProfileMenuTile(
                icon: Icons.currency_exchange_rounded,
                title: context.l10n.currency,
                subtitle: profile.currency == 'USD'
                    ? context.l10n.usdFull
                    : context.l10n.vndFull,
                trailingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    profile.currency == 'USD' ? '\$ USD' : '₫ VND',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () => _showCurrencyPickerBottomSheet(context),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // GROUP 4: Account & Support
          _SectionTitle(title: context.l10n.accountAndSupport),
          _SectionCard(
            children: [
              _ProfileMenuTile(
                icon: Icons.mail_outline_rounded,
                title: context.l10n.changeEmail,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangeEmailScreen(),
                    ),
                  );
                },
              ),
              _ProfileMenuTile(
                icon: Icons.feedback_outlined,
                title: context.l10n.feedback,
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.feedback);
                },
              ),
              _ProfileMenuTile(
                icon: Icons.delete_forever_rounded,
                title: context.l10n.deleteAccount,
                iconColor: AppColors.expense,
                iconBackgroundColor: AppColors.expense.withValues(alpha: 0.12),
                titleColor: AppColors.expense,
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
              ),
              _ProfileMenuTile(
                icon: Icons.logout_rounded,
                title: context.l10n.logout,
                iconColor: const Color(0xFFFF5252),
                iconBackgroundColor: const Color(0xFFFF5252).withValues(alpha: 0.12),
                titleColor: const Color(0xFFFF5252),
                onTap: () async {
                  context.read<ChatController>().disposeListeners();
                  await auth.logout();

                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.login,
                      (_) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStat(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBgColor,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.border(context).withValues(alpha: 0.25),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary(context).withValues(alpha: 0.85),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: AppColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border(context),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary(context),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.15 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.7,
                  indent: 64,
                  endIndent: 16,
                  color: AppColors.border(context).withValues(alpha: 0.6),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? titleColor;
  final Widget? trailingWidget;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleColor,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primaryBlue;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackgroundColor ??
                    effectiveIconColor.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      color: titleColor ?? AppColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              trailingWidget!,
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: titleColor == AppColors.expense
                  ? AppColors.expense.withValues(alpha: 0.75)
                  : AppColors.textSecondary(context).withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalOptionTile extends StatelessWidget {
  final IconData? icon;
  final String? flagEmoji;
  final Color iconColor;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModalOptionTile({
    this.icon,
    this.flagEmoji,
    required this.iconColor,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primaryBlue.withValues(alpha: 0.14)
                  : const Color(0xFFF0F6FF))
              : (isDark ? const Color(0xFF131520) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.14),
              ),
              child: Center(
                child: flagEmoji != null
                    ? Text(
                        flagEmoji!,
                        style: const TextStyle(fontSize: 20),
                      )
                    : Icon(
                        icon,
                        color: iconColor,
                        size: 19,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  void _cancel() {
    FocusManager.instance.primaryFocus?.unfocus();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      Navigator.pop(context, null);
    });
  }

  Future<void> _confirmAsync() async {
    final password = passwordController.text.trim();

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.pleaseEnterPassword),
        ),
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: keyboardBottom + 20,
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 360,
              maxHeight: 520,
            ),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.border(context),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.expense.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.expense,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          context.l10n.deleteAccountQuestion,
                          style: AppTextStyles.cardTitle(context).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.deleteAccountWarning,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.deleteAccountNote,
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: context.l10n.enterCurrentPassword,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancel,
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AsyncFilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.expense,
                          ),
                          onPressedAsync: () => _confirmAsync(),
                          child: Text(context.l10n.delete),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}