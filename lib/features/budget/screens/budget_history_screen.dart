import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../stats/controllers/stats_controller.dart';
import '../../stats/screens/category_detail_screen.dart';
import '../../../data/models/transaction_model.dart';

class BudgetHistoryScreen extends StatefulWidget {
  final String budgetName;
  final String? budgetNameEn;
  final double limitAmount;
  final int iconCodePoint;
  final String colorHex;

  const BudgetHistoryScreen({
    super.key,
    required this.budgetName,
    this.budgetNameEn,
    required this.limitAmount,
    required this.iconCodePoint,
    required this.colorHex,
  });

  @override
  State<BudgetHistoryScreen> createState() => _BudgetHistoryScreenState();
}

class _BudgetHistoryScreenState extends State<BudgetHistoryScreen> {
  int selectedPeriodCount = 6;
  bool loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null) {
        context.read<StatsController>().load(uid);
      }

      loaded = true;
    }
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) {
      return AppColors.primaryBlue;
    }

    var cleaned = hex.trim().replaceAll('#', '');

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) {
      return AppColors.primaryBlue;
    }

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return AppColors.primaryBlue;
    }
  }

  IconData _budgetIcon(int codePoint) {
    if (codePoint <= 0) {
      return Icons.account_balance_wallet_outlined;
    }

    return AppIconRegistry.fromCodePoint(codePoint);
  }

  List<_BudgetPeriodData> _buildMonthlyPeriods(
      List<TransactionModel> transactions,
      ) {
    final now = DateTime.now();

    return List.generate(selectedPeriodCount, (index) {
      final monthDate = DateTime(
        now.year,
        now.month - (selectedPeriodCount - 1 - index),
      );

      final total = transactions
          .where((tx) {
        return tx.type == 'expense' &&
            tx.category == widget.budgetName &&
            tx.createdAt.year == monthDate.year &&
            tx.createdAt.month == monthDate.month;
      })
          .fold<double>(
        0,
            (sum, tx) => sum + tx.amount,
      );

      final isCurrent =
          monthDate.year == now.year && monthDate.month == now.month;

      final isOverLimit =
          widget.limitAmount > 0 && total > widget.limitAmount;

      final percent = widget.limitAmount <= 0
          ? 0.0
          : (total / widget.limitAmount).clamp(0.0, 1.0).toDouble();

      return _BudgetPeriodData(
        date: monthDate,
        total: total,
        isCurrent: isCurrent,
        isOverLimit: isOverLimit,
        percent: percent,
      );
    });
  }

  String _monthLabel(DateTime date) {
    return context.l10n.monthYear(date.month, date.year);
  }

  String _shortMonthLabel(DateTime date) {
    return context.l10n.shortMonth(date.month);
  }

  String _compactMoney(double value) {
    final abs = value.abs();

    if (abs >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }

    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }

    return value.toStringAsFixed(0);
  }

  double _average(List<_BudgetPeriodData> periods) {
    if (periods.isEmpty) return 0;

    final total = periods.fold<double>(
      0,
          (sum, item) => sum + item.total,
    );

    return total / periods.length;
  }

  int _overCount(List<_BudgetPeriodData> periods) {
    return periods.where((item) => item.isOverLimit).length;
  }

  double _bestValue(List<_BudgetPeriodData> periods) {
    if (periods.isEmpty) return 0;

    return periods.map((e) => e.total).reduce(math.min);
  }

  double _worstValue(List<_BudgetPeriodData> periods) {
    if (periods.isEmpty) return 0;

    return periods.map((e) => e.total).reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;
    final color = _parseHexColor(widget.colorHex);
    final icon = _budgetIcon(widget.iconCodePoint);
    final stats = context.watch<StatsController>();
    final l10n = context.l10n;

    // final periods = _buildMonthlyPeriods(
    //   stats.transactions.whereType<TransactionModel>().toList(),
    // );
    final periods = _buildMonthlyPeriods(stats.transactions);

    if (stats.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    String money(double value) {
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: value,
        currency: currency,
      );
    }

    final average = _average(periods);
    final best = _bestValue(periods);
    final worst = _worstValue(periods);
    final overCount = _overCount(periods);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            AppSizes.bottomNavSafePadding,
          ),
          children: [
            _HistoryHeader(
              title: l10n.budgetHistory,
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: 24),

            _BudgetSummaryCard(
              budgetName: BudgetNameLocalizer.display(
                context,
                widget.budgetName,
                budgetNameEn: widget.budgetNameEn,
              ),
              limitText: '${money(widget.limitAmount)} / ${l10n.monthly}',
              icon: icon,
              color: color,
              averageText: money(average),
              overText: '$overCount/${periods.length}',
              bestText: money(best),
              worstText: money(worst),
            ),

            const SizedBox(height: 18),

            _PeriodCountSelector(
              selected: selectedPeriodCount,
              onChanged: (value) {
                setState(() {
                  selectedPeriodCount = value;
                });
              },
            ),

            const SizedBox(height: 18),

            _BudgetChartCard(
              periods: periods,
              limitAmount: widget.limitAmount,
              color: color,
              compactMoney: _compactMoney,
              monthLabel: _shortMonthLabel,
            ),

            const SizedBox(height: 18),

            _PeriodDetailCard(
              periods: periods.reversed.toList(),
              limitAmount: widget.limitAmount,
              money: money,
              monthLabel: _monthLabel,
              onPeriodTap: (periodDate) {
                final list = stats.transactions
                    .where(
                      (tx) =>
                          tx.type == 'expense' &&
                          tx.category == widget.budgetName &&
                          tx.createdAt.year == periodDate.year &&
                          tx.createdAt.month == periodDate.month,
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CategoryDetailScreen(
                      category: widget.budgetName,
                      type: 'expense',
                      periodTitle: _monthLabel(periodDate),
                      transactions: list,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _HistoryHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card(context),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textPrimary(context),
                size: 36,
              ),
            ),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle(context).copyWith(
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final String budgetName;
  final String limitText;
  final IconData icon;
  final Color color;
  final String averageText;
  final String overText;
  final String bestText;
  final String worstText;

  const _BudgetSummaryCard({
    required this.budgetName,
    required this.limitText,
    required this.icon,
    required this.color,
    required this.averageText,
    required this.overText,
    required this.bestText,
    required this.worstText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 31,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budgetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle(context).copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      limitText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Divider(
            color: AppColors.border(context),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.show_chart_rounded,
                  iconColor: AppColors.primaryBlue,
                  value: averageText,
                  label: l10n.average,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.expense,
                  value: overText,
                  label: l10n.overBudget,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.income,
                  value: bestText,
                  label: l10n.bestPeriod,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.expense,
                  value: worstText,
                  label: l10n.worstPeriod,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryMetric({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 31,
        ),
        const SizedBox(height: 10),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.cardTitle(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PeriodCountSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PeriodCountSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const values = [3, 6, 12];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.periodCount,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Row(
            children: values.map((value) {
              final active = value == selected;

              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 58,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryBlue
                          : AppColors.surface(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active
                            ? AppColors.primaryBlue
                            : AppColors.innerBorder(context),
                      ),
                    ),
                    child: Text(
                      '$value',
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : AppColors.primaryBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BudgetChartCard extends StatelessWidget {
  final List<_BudgetPeriodData> periods;
  final double limitAmount;
  final Color color;
  final String Function(double value) compactMoney;
  final String Function(DateTime date) monthLabel;

  const _BudgetChartCard({
    required this.periods,
    required this.limitAmount,
    required this.color,
    required this.compactMoney,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxSpent = periods.isEmpty
        ? 0.0
        : periods.map((e) => e.total).reduce(math.max);

    final maxY = math.max(
      limitAmount <= 0 ? 1 : limitAmount,
      maxSpent <= 0 ? 1 : maxSpent,
    ) * 1.22;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.compareOverPeriods,
            style: AppTextStyles.sectionTitle(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(
                color: AppColors.warning,
                label: l10n.budgetLimitLegend,
                isLine: true,
              ),
              _LegendItem(
                color: AppColors.income,
                label: l10n.withinBudgetLegend,
              ),
              _LegendItem(
                color: AppColors.expense,
                label: l10n.overBudgetLegend,
              ),
            ],
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 285,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border(context),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= periods.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthLabel(periods[index].date),
                            style: AppTextStyles.caption(context).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (limitAmount > 0)
                      HorizontalLine(
                        y: limitAmount,
                        color: AppColors.warning,
                        strokeWidth: 1.4,
                        dashArray: [8, 6],
                      ),
                  ],
                ),
                barGroups: periods.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final barColor = item.isOverLimit
                      ? AppColors.expense
                      : AppColors.primaryBlue;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.total,
                        width: 36,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7),
                        ),
                        color: barColor,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            barColor.withValues(alpha: 0.92),
                            barColor.withValues(alpha: 0.42),
                          ],
                        ),
                      ),
                    ],
                    showingTooltipIndicators:
                    item.total > 0 ? [0] : const [],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 4,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        compactMoney(rod.toY),
                        TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLine;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(
            width: 24,
            height: 3,
            color: color,
          )
        else
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppTextStyles.bodySecondary(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PeriodDetailCard extends StatelessWidget {
  final List<_BudgetPeriodData> periods;
  final double limitAmount;
  final String Function(double value) money;
  final String Function(DateTime date) monthLabel;
  final void Function(DateTime periodDate) onPeriodTap;

  const _PeriodDetailCard({
    required this.periods,
    required this.limitAmount,
    required this.money,
    required this.monthLabel,
    required this.onPeriodTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.periodDetail,
            style: AppTextStyles.sectionTitle(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...periods.map((item) {
            return _PeriodDetailItem(
              item: item,
              limitAmount: limitAmount,
              money: money,
              monthLabel: monthLabel,
              onTap: () => onPeriodTap(item.date),
            );
          }),
        ],
      ),
    );
  }
}

class _PeriodDetailItem extends StatelessWidget {
  final _BudgetPeriodData item;
  final double limitAmount;
  final String Function(double value) money;
  final String Function(DateTime date) monthLabel;
  final VoidCallback onTap;

  const _PeriodDetailItem({
    required this.item,
    required this.limitAmount,
    required this.money,
    required this.monthLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = item.isOverLimit ? AppColors.expense : AppColors.primaryBlue;
    final remaining = limitAmount - item.total;
    final percentText = limitAmount <= 0
        ? '0%'
        : '${((item.total / limitAmount) * 100).toStringAsFixed(0)}%';

    const radius = Radius.circular(20);

    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(radius),
        child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: item.isCurrent
            ? AppColors.primaryBlue.withValues(alpha: 0.10)
            : AppColors.surface(context).withValues(
          alpha: AppColors.isDark(context) ? 0.72 : 0.92,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isCurrent
              ? AppColors.primaryBlue.withValues(alpha: 0.42)
              : item.isOverLimit
              ? AppColors.expense.withValues(alpha: 0.35)
              : AppColors.innerBorder(context),
          width: item.isCurrent ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.12 : 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: item.isOverLimit
                    ? AppColors.expense
                    : item.isCurrent
                    ? AppColors.primaryBlue
                    : AppColors.income,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (item.isCurrent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.currentPeriod,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                        ],

                        Text(
                          monthLabel(item.date),
                          maxLines: 1,
                          softWrap: false,
                          style: AppTextStyles.cardTitle(context).copyWith(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                money(item.total),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: item.isOverLimit
                                      ? AppColors.expense
                                      : AppColors.textPrimary(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                percentText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 2),

                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary(context),
                          size: 22,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.percent,
                        minHeight: 9,
                        backgroundColor: AppColors.card(context),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (item.isOverLimit) ...[
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.expense,
                                  size: 17,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    l10n.overBudgetWarning,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.expense,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: Text(
                                    l10n.remainingLabel(money(remaining < 0 ? 0 : remaining)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySecondary(context)
                                        .copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Flexible(
                          child: Text(
                            l10n.budgetLimitLabel(money(limitAmount)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.bodySecondary(context).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _BudgetPeriodData {
  final DateTime date;
  final double total;
  final bool isCurrent;
  final bool isOverLimit;
  final double percent;

  const _BudgetPeriodData({
    required this.date,
    required this.total,
    required this.isCurrent,
    required this.isOverLimit,
    required this.percent,
  });
}
