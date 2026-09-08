import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../profile/controllers/profile_controller.dart';

enum SummaryPeriod { day, month }

class BalanceCard extends StatefulWidget {
  final List<TransactionModel> transactions;

  const BalanceCard({
    super.key,
    required this.transactions,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  SummaryPeriod _period = SummaryPeriod.day;
  bool _hideExpenseAmount = false;
  bool _hideIncomeAmount = false;

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;
    final now = DateTime.now();

    final todayTransactions = widget.transactions
        .where((tx) => _isSameDate(tx.createdAt, now))
        .toList();

    final monthTransactions = widget.transactions
        .where((tx) => _isSameMonth(tx.createdAt, now))
        .toList();

    final activeTransactions =
        _period == SummaryPeriod.day ? todayTransactions : monthTransactions;

    final income = activeTransactions
        .where((e) => e.type == 'income')
        .fold(0.0, (sum, e) => sum + e.amount);

    final expense = activeTransactions
        .where((e) => e.type == 'expense')
        .fold(0.0, (sum, e) => sum + e.amount);

    String formatDisplay(double amount, bool isHidden) {
      if (isHidden) return '****';
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: amount,
        currency: currency,
      );
    }

    final dayCount = todayTransactions.length;
    final monthCount = monthTransactions.length;

    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.card(context);
    final toggleBg = isDark ? const Color(0xFF171A26) : const Color(0xFFE9ECF2);
    final activeTabBg = isDark ? const Color(0xFF282D3D) : Colors.white;
    final actionBtnBg = isDark ? const Color(0xFF171A26) : const Color(0xFFE9ECF2);
    final actionIconColor = isDark ? const Color(0xFF79AFFF) : const Color(0xFF2563EB);

    final activeBadgeBg = const Color(0xFF388AF6);
    final inactiveBadgeBg =
        isDark ? const Color(0xFF383D50) : const Color(0xFFD4D8E3);
    final inactiveBadgeText =
        isDark ? Colors.white : const Color(0xFF333745);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Control Row: Tabs on Left + Top Eye Button on Right
        Row(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: toggleBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PeriodTabItem(
                    label: context.l10n.dayTab,
                    count: dayCount,
                    isSelected: _period == SummaryPeriod.day,
                    showGridIcon: _period == SummaryPeriod.day,
                    badgeColor: _period == SummaryPeriod.day
                        ? activeBadgeBg
                        : inactiveBadgeBg,
                    badgeTextColor: _period == SummaryPeriod.day
                        ? Colors.white
                        : inactiveBadgeText,
                    activeBackground: activeTabBg,
                    onTap: () {
                      if (_period != SummaryPeriod.day) {
                        setState(() => _period = SummaryPeriod.day);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _PeriodTabItem(
                    label: context.l10n.monthTab,
                    count: monthCount,
                    isSelected: _period == SummaryPeriod.month,
                    showGridIcon: _period == SummaryPeriod.month,
                    badgeColor: _period == SummaryPeriod.month
                        ? activeBadgeBg
                        : inactiveBadgeBg,
                    badgeTextColor: _period == SummaryPeriod.month
                        ? Colors.white
                        : inactiveBadgeText,
                    activeBackground: activeTabBg,
                    onTap: () {
                      if (_period != SummaryPeriod.month) {
                        setState(() => _period = SummaryPeriod.month);
                      }
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Nút Tìm kiếm — Duyệt giao dịch
            _HeaderIconButton(
              icon: Icons.search_rounded,
              backgroundColor: actionBtnBg,
              iconColor: actionIconColor,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(
                  context,
                  RouteNames.browseTransactions,
                  arguments: widget.transactions,
                );
              },
            ),

            const SizedBox(width: 8),

            // Top Button: Meme Rewind — Kỷ niệm chi tiêu
            _HeaderIconButton(
              icon: Icons.auto_awesome_rounded,
              backgroundColor: actionBtnBg,
              iconColor: actionIconColor,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, RouteNames.rewind);
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Income & Expense Cards Side-by-Side with Independent Eye Toggles
        Row(
          children: [
            // Expense Card (Chi)
            Expanded(
              child: _MetricCard(
                label: context.l10n.expenseLabel,
                amountText: formatDisplay(expense, _hideExpenseAmount),
                icon: Icons.north_east_rounded,
                badgeColor: const Color(0xFFFF5C5C),
                borderColor: AppColors.border(context),
                backgroundColor: cardBg,
                isAmountHidden: _hideExpenseAmount,
                onToggleHide: () {
                  setState(() => _hideExpenseAmount = !_hideExpenseAmount);
                },
              ),
            ),

            const SizedBox(width: 10),

            // Income Card (Thu)
            Expanded(
              child: _MetricCard(
                label: context.l10n.incomeLabel,
                amountText: formatDisplay(income, _hideIncomeAmount),
                icon: Icons.south_west_rounded,
                badgeColor: const Color(0xFF34C759),
                borderColor: AppColors.border(context),
                backgroundColor: cardBg,
                isAmountHidden: _hideIncomeAmount,
                onToggleHide: () {
                  setState(() => _hideIncomeAmount = !_hideIncomeAmount);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PeriodTabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final bool showGridIcon;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color activeBackground;
  final VoidCallback onTap;

  const _PeriodTabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    this.showGridIcon = false,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.activeBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? textPrimary : textSecondary,
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (showGridIcon) ...[
              const SizedBox(width: 5),
              Icon(
                Icons.grid_view_rounded,
                size: 13,
                color: isSelected ? textPrimary : textSecondary,
              ),
            ],
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(
                minWidth: 19,
                minHeight: 19,
              ),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.innerBorder(context),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String amountText;
  final IconData icon;
  final Color badgeColor;
  final Color borderColor;
  final Color backgroundColor;
  final bool isAmountHidden;
  final VoidCallback onToggleHide;

  const _MetricCard({
    required this.label,
    required this.amountText,
    required this.icon,
    required this.badgeColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.isAmountHidden,
    required this.onToggleHide,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Amount and Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amountText,
                    maxLines: 1,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Eye button inside card (independent hide/show)
          GestureDetector(
            onTap: onToggleHide,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                isAmountHidden
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: textSecondary.withValues(alpha: 0.75),
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}