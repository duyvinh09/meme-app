import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';
import 'moment_viewer_screen.dart';

class DayDetailScreen extends StatelessWidget {
  final DateTime selectedDate;

  const DayDetailScreen({
    super.key,
    required this.selectedDate,
  });

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatHeaderDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEEE, d MMM, y', locale).format(date);
  }

  String _formatCompactMoney({
    required double value,
    required String currency,
  }) {
    final amountText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: value.abs(),
      currency: currency,
    );

    return '${value >= 0 ? '+' : '-'}$amountText';
  }

  String _formatTime(DateTime createdAt) {
    return DateFormat('HH:mm').format(createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final currency = context.watch<ProfileController>().currency;

    final dayTransactions = home.transactions.where((tx) {
      return _sameDate(tx.createdAt, selectedDate);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalIncome = dayTransactions
        .where((e) => e.type == 'income')
        .fold<double>(0, (sum, e) => sum + e.amount);

    final totalExpense = dayTransactions
        .where((e) => e.type == 'expense')
        .fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: dayTransactions.isEmpty
            ? _EmptyDayView(
          selectedDateText: _formatHeaderDate(context, selectedDate),
        )
            : Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: Column(
            children: [
              _HeaderBar(
                title: _formatHeaderDate(context, selectedDate),
                onClose: () => Navigator.pop(context),
              ),

              const SizedBox(height: 12),

              _DailySummaryRow(
                totalExpenseText: AppCurrencyFormatter.formatFromVnd(
                  amountVnd: totalExpense,
                  currency: currency,
                ),
                totalIncomeText: AppCurrencyFormatter.formatFromVnd(
                  amountVnd: totalIncome,
                  currency: currency,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: GridView.builder(
                  cacheExtent: 700,
                  itemCount: dayTransactions.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final tx = dayTransactions[index];

                    return RepaintBoundary(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MomentViewerScreen(
                                transactions: dayTransactions,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: _MomentGridCard(
                          transaction: tx,
                          amountText: _formatCompactMoney(
                            value: tx.type == 'expense'
                                ? -tx.amount
                                : tx.amount,
                            currency: currency,
                          ),
                          timeText: _formatTime(tx.createdAt),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _HeaderBar({
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.subtleOverlay(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.glassBorder(context),
              ),
            ),
            child: Icon(
              Icons.close_rounded,
              color: AppColors.textPrimary(context),
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 52),
      ],
    );
  }
}

class _DailySummaryRow extends StatelessWidget {
  final String totalExpenseText;
  final String totalIncomeText;

  const _DailySummaryRow({
    required this.totalExpenseText,
    required this.totalIncomeText,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: [
        _SummaryPill(
          icon: Icons.north_east_rounded,
          text: totalExpenseText,
          color: AppColors.expense,
        ),
        _SummaryPill(
          icon: Icons.south_west_rounded,
          text: totalIncomeText,
          color: AppColors.income,
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SummaryPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 170,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(
          AppColors.isDark(context) ? 0.16 : 0.12,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayView extends StatelessWidget {
  final String selectedDateText;

  const _EmptyDayView({
    required this.selectedDateText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.subtleOverlay(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.glassBorder(context),
                ),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: AppColors.textSecondary(context),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              selectedDateText,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context).copyWith(
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.dayDetailEmpty,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentGridCard extends StatelessWidget {
  final TransactionModel transaction;
  final String amountText;
  final String timeText;

  const _MomentGridCard({
    required this.transaction,
    required this.amountText,
    required this.timeText,
  });

  String _localizedCategoryLabel(BuildContext context, String category) {
    final l10n = context.l10n;
    switch (category.trim()) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Lương':
      case 'Salary':
        return l10n.salary;
      case 'Mua sắm':
      case 'Shopping':
        return l10n.shopping;
      case 'Đi lại':
      case 'Transport':
        return l10n.transport;
      case 'Giải trí':
      case 'Entertainment':
        return l10n.entertainment;
      case 'Học tập':
      case 'Education':
        return l10n.education;
      case 'Quà tặng':
      case 'Gift':
        return l10n.gift;
      case 'Khác':
      case 'Other':
        return l10n.other;
      default:
        return BudgetNameLocalizer.display(context, category);
    }
  }

  Color _parseColorHex(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppColors.textSecondary(context);
    }

    var cleaned = value.trim().replaceAll('#', '');

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) {
      return AppColors.textSecondary(context);
    }

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return AppColors.textSecondary(context);
    }
  }

  Color _chipColor(BuildContext context) {
    final savedColor = _parseColorHex(
      context,
      transaction.categoryColorHex,
    );

    if (transaction.categoryColorHex != null &&
        transaction.categoryColorHex.toString().trim().isNotEmpty) {
      return savedColor;
    }

    switch (transaction.category) {
      case 'Ăn uống':
      case 'Food':
      case 'Lương':
      case 'Salary':
        return AppColors.income;
      case 'Mua sắm':
      case 'Shopping':
        return AppColors.primaryPink;
      case 'Đi lại':
      case 'Transport':
        return AppColors.primaryBlue;
      case 'Giải trí':
      case 'Entertainment':
        return AppColors.warning;
      case 'Học tập':
      case 'Education':
        return AppColors.primaryPurple;
      default:
        return AppColors.textSecondary(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _chipColor(context);
    final caption = transaction.caption.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          TransactionMomentImage(
            imageUrl: transaction.imageUrl,
            category: transaction.category,
            categoryIconCodePoint: transaction.categoryIconCodePoint,
            categoryColorHex: transaction.categoryColorHex,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(22),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.38),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8,
                  sigmaY: 8,
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 86,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: chipColor,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    _localizedCategoryLabel(context, transaction.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 10,
            top: 12,
            child: Text(
              timeText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (caption.isNotEmpty) ...[
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  amountText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}