import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/calendar_section.dart';
import '../widgets/recent_transaction_card.dart';
import '../widgets/streak_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final uid = context.read<AuthController>().user?.uid;
      if (uid != null) {
        context.read<HomeController>().load(uid);
      }
      loaded = true;
    }
  }

  String _getGreetingByTime() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;

    if (hour < 12) return '☀️';
    if (hour < 18) return '🌤️';
    return '🌙';
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
        'Hôm nay bạn chưa thêm giao dịch nào.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context).copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      );
    }

    final todayIncome = todayTransactions
        .where((tx) => tx.type == 'income')
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final todayExpense = todayTransactions
        .where((tx) => tx.type == 'expense')
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
          text: 'Đã nhận ${money(todayIncome)} hôm nay',
          accentColor: AppColors.income,
        ),
      );
    }

    if (todayExpense > 0) {
      chips.add(
        _SummaryChip(
          icon: Icons.north_east_rounded,
          text: 'Đã chi ${money(todayExpense)} hôm nay',
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
    final currency = context.watch<ProfileController>().currency;

    final greetingText = _getGreetingByTime();
    final greetingIcon = _getGreetingIcon();
    final avatarUrl = home.profile?.avatarUrl ?? '';

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
                Expanded(
                  child: Text(
                    'Meme',
                    style: AppTextStyles.pageTitle(context),
                  ),
                ),
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
              greetingIcon: greetingIcon,
              greetingText: greetingText,
              userName: home.profile?.name ?? 'Bạn',
              todaySummary: _buildTodaySummary(
                home: home,
                currency: currency,
              ),
            ),

            const SizedBox(height: 16),

            BalanceCard(
              balance: home.balance,
              income: home.totalIncome,
              expense: home.totalExpense,
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
                    'Giao dịch gần đây',
                    style: AppTextStyles.sectionTitle(context),
                  ),
                ),
                if (home.transactions.isNotEmpty)
                  Text(
                    '${home.transactions.length} giao dịch',
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (home.transactions.isEmpty)
              const _EmptyTransactionCard()
            else
              ...home.transactions
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
  final String greetingIcon;
  final String greetingText;
  final String userName;
  final Widget todaySummary;

  const _WelcomeCard({
    required this.avatarUrl,
    required this.greetingIcon,
    required this.greetingText,
    required this.userName,
    required this.todaySummary,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.22),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.10),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
                backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryBlue,
                  size: 28,
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      greetingIcon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        greetingText,
                        style: AppTextStyles.bodySecondary(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$userName ✨',
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
            color: Colors.black.withOpacity(
              AppColors.isDark(context) ? 0.18 : 0.05,
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
            'Chưa có giao dịch nào',
            style: AppTextStyles.sectionTitle(context).copyWith(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy thêm giao dịch đầu tiên để bắt đầu theo dõi chi tiêu',
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
      padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(AppColors.isDark(context) ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: accentColor.withOpacity(0.12),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: accentColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: accentColor,
                fontSize: 12.5,
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