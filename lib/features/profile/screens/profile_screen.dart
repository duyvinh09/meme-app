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
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/async_filled_button.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../home/controllers/home_controller.dart';
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
  final ScrollController _scrollController = ScrollController();
  String? _loadedUid;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uid = context.watch<AuthController>().user?.uid;
    if (uid != null && uid.isNotEmpty && uid != _loadedUid) {
      _loadedUid = uid;
      context.read<ProfileController>().loadUser(uid);
    }
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

  Future<void> _pickAndSaveDateOfBirth(
    BuildContext context,
    UserModel? user,
  ) async {
    final now = DateTime.now();
    DateTime tempDate = user?.dateOfBirth ?? DateTime(now.year, now.month, now.day);
    final isDark = AppColors.isDark(context);
    final l10n = context.l10n;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1D29) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryPink.withValues(alpha: 0.15),
                          ),
                          child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.selectBirthday,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy').format(tempDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark
                              ? ColorScheme.dark(
                                  primary: AppColors.primaryBlue,
                                  onPrimary: Colors.white,
                                  surface: const Color(0xFF1B1D29),
                                  onSurface: Colors.white,
                                )
                              : ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: tempDate.isAfter(now) ? now : tempDate,
                          firstDate: DateTime(1900),
                          lastDate: now,
                          onDateChanged: (newDate) {
                            setSheetState(() {
                              tempDate = newDate;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetCtx, tempDate),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.confirm,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null && context.mounted) {
      final profileCtrl = context.read<ProfileController>();
      final authCtrl = context.read<AuthController>();
      final homeCtrl = context.read<HomeController>();
      final myUid = authCtrl.user?.uid ?? user?.uid;
      if (myUid != null && myUid.isNotEmpty) {
        final success = await profileCtrl.updateProfile(
          uid: myUid,
          name: user?.name ?? '',
          dateOfBirth: picked,
          updateDateOfBirth: true,
        );
        if (success) {
          await homeCtrl.refreshProfile(myUid);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.birthdayUpdatedSuccess),
                backgroundColor: AppColors.income,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();
    final user = profile.user ??
        home.profile ??
        (auth.user != null
            ? context.read<UserRepository>().getCachedUserProfile(auth.user!.uid)
            : null);

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
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // 1. Scrollable Content underneath the floating header
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: () async {
                  final uid = context.read<AuthController>().user?.uid;
                  if (uid != null && uid.isNotEmpty) {
                    await Future.wait([
                      context.read<ProfileController>().refreshUser(uid),
                      context.read<HomeController>().refreshProfile(uid),
                    ]);
                  }
                },
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    68,
                    AppSizes.pagePadding,
                    AppSizes.bottomNavSafePadding,
                  ),
                  children: [
          // Hero User Profile Card (Redesigned based on reference mockup)
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.border(context),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppColors.isDark(context) ? 0.16 : 0.04,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Top Cover Banner with Edit button & Overlapping Avatar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // Banner Cover with water blue background like the budget overview card
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFA8D4FF),
                            width: 1.2,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE2F0FD),
                              Color(0xFFC0E2FF),
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned(
                                right: -15,
                                bottom: 30,
                                child: Transform.rotate(
                                  angle: -0.16,
                                  child: Opacity(
                                    opacity: 0.18,
                                    child: Image.asset(
                                      'assets/icons/meme_wordmark.png',
                                      width: 230,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Edit Profile Button (top-right round button)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RouteNames.editProfile,
                              );
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 19,
                                color: Color(0xFF102A45),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Avatar positioned overlapping the banner bottom edge
                      Padding(
                        padding: const EdgeInsets.only(top: 105),
                        child: AvatarWithFrame(
                          avatarUrl: avatarUrl,
                          frameId: user?.avatarFrame,
                          size: 110,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Display Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle(context).copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Username below name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '@$username',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Joined Date pill below username
                _InfoPill(
                  icon: Icons.calendar_month_rounded,
                  text: context.l10n.joined(createdAtText),
                ),
                const SizedBox(height: 16),
                // Gamification & Streak Stats Card (Replaces likes / posts / views)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: GestureDetector(
                    onTap: () {
                      StreakDetailSheet.show(
                        context,
                        user: user,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.innerBorder(context),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Streak
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFF5722)
                                        .withValues(alpha: 0.12),
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
                                Text(
                                  '${user?.currentStreak ?? 0}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary(context),
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.l10n.daysUnit,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context)
                                        .withValues(alpha: 0.85),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  context.l10n.streakMaintaining,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary(context),
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatDivider(context),
                          // Best Streak
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFB300)
                                        .withValues(alpha: 0.14),
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
                                Text(
                                  '${user?.bestStreak ?? 0}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary(context),
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.l10n.daysUnit,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context)
                                        .withValues(alpha: 0.85),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  context.l10n.bestStreakLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary(context),
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatDivider(context),
                          // Collection
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF388AF6)
                                        .withValues(alpha: 0.12),
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
                                Text(
                                  '${AvatarFrames.getUnlockedCount(user?.currentStreak ?? 0, bestStreak: user?.bestStreak ?? 0)}/${AvatarFrames.all.length}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary(context),
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.l10n.framesUnit,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context)
                                        .withValues(alpha: 0.85),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  context.l10n.avatarCollection,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary(context),
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // GROUP 1: Overview & Connections
          _SectionTitle(title: context.l10n.generalOverview),
          _SectionCard(
            children: [
              StreamBuilder<List<String>>(
                initialData: auth.user == null
                    ? const []
                    : context
                        .read<UserRepository>()
                        .getCachedFriendIds(auth.user!.uid),
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
              _ProfileMenuTile(
                icon: Icons.cake_outlined,
                title: context.l10n.birthday,
                trailingWidget: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (user?.dateOfBirth != null
                            ? AppColors.primaryPink
                            : AppColors.primaryBlue)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.dateOfBirth != null
                        ? DateFormat('dd/MM').format(user!.dateOfBirth!)
                        : context.l10n.setBirthday,
                    style: TextStyle(
                      color: user?.dateOfBirth != null
                          ? AppColors.primaryPink
                          : const Color(0xFF388AF6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () => _pickAndSaveDateOfBirth(context, user),
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
                  context.read<ProfileController>().clear();
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
    ),
  ),

            // 2. Floating Transparent Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  12,
                  AppSizes.pagePadding,
                  12,
                ),
                child: Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      const AppBackButton(),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          final offset = _scrollController.hasClients
                              ? _scrollController.offset
                              : 0.0;
                          final titleOpacity =
                              (1.0 - (offset / 80.0)).clamp(0.0, 1.0);
                          return Opacity(
                            opacity: titleOpacity,
                            child: child,
                          );
                        },
                        child: Text(
                          context.l10n.profile,
                          style: AppTextStyles.pageTitle(context).copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
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
    );
  }


  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border(context).withValues(alpha: 0.25),
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
    final isDark = AppColors.isDark(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: isDark
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
            size: 15,
            color: AppColors.textSecondary(context),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
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
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? titleColor;
  final Widget? trailingWidget;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
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
              child: Text(
                title,
                style: AppTextStyles.body(context).copyWith(
                  color: titleColor ?? AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
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