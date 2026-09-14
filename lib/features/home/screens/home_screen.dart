import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/meme_logo.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';
import '../controllers/home_controller.dart';
import '../services/daily_moment_service.dart';
import '../widgets/balance_card.dart';
import '../widgets/calendar_section.dart';
import '../widgets/recent_transaction_card.dart';
import '../widgets/streak_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool loaded = false;
  Timer? _timeUpdateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Tự động cập nhật greeting theo thời gian thực mỗi phút
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Cập nhật lại ngay khi người dùng quay lại app từ màn hình khác / background
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final uid = context.read<AuthController>().user?.uid;
      if (uid != null) {
        context.read<HomeController>().load(uid);
        context.read<BudgetController>().load(uid);
      }
      loaded = true;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildTodaySummary({
    required HomeController home,
    required String currency,
  }) {
    final now = DateTime.now();

    final todayTransactions = home.transactions
        .where((tx) => _isSameDate(tx.createdAt, now))
        .toList();

    if (todayTransactions.isEmpty) {
      return Text(
        context.l10n.noTransactionsToday,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context).copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      );
    }

    final todayIncome = todayTransactions
        .where((tx) => tx.isPersonalIncome)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final todayExpense = todayTransactions
        .where((tx) => tx.isPersonalExpense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    String money(double value) {
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: value,
        currency: currency,
      );
    }

    final chips = <Widget>[];

    if (todayIncome > 0) {
      chips.add(
        _SummaryChip(
          icon: Icons.south_west_rounded,
          text: context.l10n.receivedToday(money(todayIncome)),
          accentColor: AppColors.income,
        ),
      );
    }

    if (todayExpense > 0) {
      chips.add(
        _SummaryChip(
          icon: Icons.north_east_rounded,
          text: context.l10n.spentToday(money(todayExpense)),
          accentColor: AppColors.expense,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips.map((chip) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
              ),
              child: chip,
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final profileController = context.watch<ProfileController>();
    final budgetController = context.watch<BudgetController>();

    final currency = profileController.currency;
    final localeLang = Localizations.localeOf(context).languageCode;
    final languageCode = profileController.languageCode.isNotEmpty
        ? profileController.languageCode
        : localeLang;

    final momentData = DailyMomentService.resolveMoment(
      context: context,
      profile: home.profile,
      transactions: home.transactions,
      budgets: budgetController.budgets,
      languageCode: languageCode,
    );

    final avatarUrl = home.profile?.avatarUrl ?? '';
    final now = DateTime.now();
    final currentMonthTransactions = home.transactions
        .where((tx) => tx.createdAt.year == now.year && tx.createdAt.month == now.month)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: home.isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : ListView(
          cacheExtent: 800,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            12,
            AppSizes.pagePadding,
            AppSizes.bottomNavSafePadding,
          ),
          children: [
            Row(
              children: [
                const MemeLogo(
                  height: 44,
                  showSubtitle: true,
                ),
                const Spacer(),
                _TopActionButton(
                  icon: Icons.calendar_month_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.calendar);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sectionGap),

            _WelcomeCard(
              avatarUrl: avatarUrl,
              avatarFrame: home.profile?.avatarFrame ?? 'plain',
              greetingIcon: momentData.greetingIcon,
              greetingText: momentData.greetingText,
              userName: home.profile?.name ?? context.l10n.you,
              todaySummary: _buildTodaySummary(
                home: home,
                currency: currency,
              ),
            ),

            const SizedBox(height: 16),

            BalanceCard(
              transactions: home.transactions,
            ),

            const SizedBox(height: 16),

            StreakCard(
              streak: home.profile?.currentStreak ?? 0,
              onStartTap: () {
                Navigator.pushNamed(context, RouteNames.addTransaction);
              },
            ),

            const SizedBox(height: 16),

            _SectionContainer(
              clipBehavior: Clip.antiAlias,
              child: const CalendarSection(),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.recentTransactions,
                    style: AppTextStyles.sectionTitle(context),
                  ),
                ),
                if (currentMonthTransactions.isNotEmpty)
                  Text(
                    context.l10n.transactionCount(currentMonthTransactions.length),
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (currentMonthTransactions.isEmpty)
              const _EmptyTransactionCard()
            else
              ...currentMonthTransactions
                  .take(5)
                  .map((e) => RecentTransactionCard(transaction: e)),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String avatarUrl;
  final String avatarFrame;
  final String greetingIcon;
  final String greetingText;
  final String userName;
  final Widget todaySummary;

  const _WelcomeCard({
    required this.avatarUrl,
    required this.avatarFrame,
    required this.greetingIcon,
    required this.greetingText,
    required this.userName,
    required this.todaySummary,
  });

  @override
  Widget build(BuildContext context) {
    final textLength = greetingText.length;
    final double dynamicFontSize = textLength > 36
        ? 12.0
        : (textLength > 24 ? 13.0 : 14.0);

    return _SectionContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarWithFrame(
            avatarUrl: avatarUrl,
            frameId: avatarFrame,
            size: 54,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$greetingIcon  ',
                          style: TextStyle(
                            fontSize: dynamicFontSize + 2,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: greetingText,
                          style: AppTextStyles.bodySecondary(context).copyWith(
                            fontSize: dynamicFontSize,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                    key: ValueKey('$greetingIcon-$greetingText'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle(context).copyWith(
                    fontSize: 22,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                todaySummary,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  const _SectionContainer({
    required this.child,
    this.padding,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.18 : 0.05,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: AppColors.border(context),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }
}

class _EmptyTransactionCard extends StatelessWidget {
  const _EmptyTransactionCard();

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface(context),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.textSecondary(context),
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.noTransactions,
            style: AppTextStyles.sectionTitle(context).copyWith(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.addFirstTransaction,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary(context),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accentColor;

  const _SummaryChip({
    required this.icon,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 9, 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: AppColors.isDark(context) ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.12),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: accentColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: accentColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}