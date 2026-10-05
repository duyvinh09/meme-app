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
import '../../../data/models/budget_model.dart';
import '../services/budget_cycle_helper.dart';

class BudgetHistoryScreen extends StatefulWidget {
  final BudgetModel? budget;
  final String budgetName;
  final String? budgetNameEn;
  final double limitAmount;
  final int iconCodePoint;
  final String colorHex;

  const BudgetHistoryScreen({
    super.key,
    this.budget,
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

  List<_BudgetPeriodData> _buildPeriods(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final b = widget.budget ??
        BudgetModel(
          id: '',
          userId: '',
          name: widget.budgetName,
          nameEn: widget.budgetNameEn,
          iconCodePoint: widget.iconCodePoint,
          colorHex: widget.colorHex,
          limitAmount: widget.limitAmount,
          spentAmount: 0,
          isDefault: false,
          createdAt: DateTime.now(),
          period: 'monthly',
          budgetType: 'category',
        );

    final isEn = Localizations.localeOf(context).languageCode == 'en';

    final historyCycles = BudgetCycleHelper.getHistoricalCycles(
      b,
      transactions,
      count: selectedPeriodCount,
      refDate: now,
      isEnglish: isEn,
    );

    return historyCycles.asMap().entries.map((entry) {
      final idx = entry.key;
      final cycle = entry.value;
      final isCurrent = idx == historyCycles.length - 1;

      return _BudgetPeriodData(
        date: cycle.startDate,
        endDate: cycle.endDate,
        total: cycle.spentAmount,
        isCurrent: isCurrent,
        isOverLimit: cycle.isOverLimit,
        percent: cycle.percent,
        label: cycle.label,
        shortLabel: cycle.shortLabel,
      );
    }).toList();
  }

  String _monthLabel(DateTime date) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return isEn
        ? 'Month ${date.month}/${date.year}'
        : 'Tháng ${date.month}/${date.year}';
  }

  String _shortMonthLabel(DateTime date) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return isEn ? 'M${date.month}' : 'T${date.month}';
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

    final periods = _buildPeriods(stats.transactions);

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

    String periodLimitText(String? period, double limitAmount) {
      final String periodName;
      switch (period) {
        case 'daily':
          periodName = l10n.daily;
          break;
        case 'weekly':
          periodName = l10n.weekly;
          break;
        case 'biweekly':
          periodName = l10n.biweekly;
          break;
        case 'yearly':
          periodName = l10n.yearly;
          break;
        case 'custom':
          periodName = l10n.custom;
          break;
        case 'monthly':
        default:
          periodName = l10n.monthly;
          break;
      }
      return '${money(limitAmount)} / $periodName';
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
            16,
            12,
            16,
            AppSizes.bottomNavSafePadding,
          ),
          children: [
            _HistoryHeader(
              title: l10n.budgetHistory,
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: 14),

            _BudgetSummaryCard(
              budgetName: BudgetNameLocalizer.display(
                context,
                widget.budgetName,
                budgetNameEn: widget.budgetNameEn,
              ),
              limitText: periodLimitText(
                widget.budget?.period ?? 'monthly',
                widget.limitAmount,
              ),
              icon: icon,
              color: color,
              averageText: money(average),
              overText: '$overCount/${periods.length}',
              bestText: money(best),
              worstText: money(worst),
            ),

            const SizedBox(height: 12),

            _PeriodCountSelector(
              selected: selectedPeriodCount,
              onChanged: (value) {
                setState(() {
                  selectedPeriodCount = value;
                });
              },
            ),

            const SizedBox(height: 12),

            _BudgetChartCard(
              periods: periods,
              limitAmount: widget.limitAmount,
              color: color,
              compactMoney: _compactMoney,
              monthLabel: _shortMonthLabel,
            ),

            const SizedBox(height: 12),

            _PeriodDetailCard(
              periods: periods.reversed.toList(),
              limitAmount: widget.limitAmount,
              money: money,
              monthLabel: _monthLabel,
              onPeriodTap: (item) {
                final b = widget.budget ??
                    BudgetModel(
                      id: '',
                      userId: '',
                      name: widget.budgetName,
                      nameEn: widget.budgetNameEn,
                      iconCodePoint: widget.iconCodePoint,
                      colorHex: widget.colorHex,
                      limitAmount: widget.limitAmount,
                      spentAmount: 0,
                      isDefault: false,
                      createdAt: DateTime.now(),
                      period: 'monthly',
                      budgetType: 'category',
                    );

                final list = stats.transactions.where((tx) {
                  if (tx.type != 'expense') return false;
                  if (!BudgetCycleHelper.matchesCategory(b, tx.category)) {
                    return false;
                  }
                  if (item.endDate != null) {
                    return !tx.createdAt.isBefore(item.date) &&
                        !tx.createdAt.isAfter(item.endDate!);
                  }
                  return tx.createdAt.year == item.date.year &&
                      tx.createdAt.month == item.date.month;
                }).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CategoryDetailScreen(
                      category: BudgetNameLocalizer.display(
                        context,
                        widget.budgetName,
                        budgetNameEn: widget.budgetNameEn,
                      ),
                      type: 'expense',
                      periodTitle: item.label ?? _monthLabel(item.date),
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
            borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card(context),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary(context),
                size: 16,
              ),
            ),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle(context).copyWith(
            fontSize: 19,
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budgetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle(context).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      limitText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(
            color: AppColors.border(context),
          ),

          const SizedBox(height: 14),

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

          const SizedBox(height: 14),

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
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.cardTitle(context).copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary(context).copyWith(
            fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Row(
            children: values.map((value) {
              final active = value == selected;

              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 32,
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
                        fontSize: 13,
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

class _BudgetChartCard extends StatefulWidget {
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
  State<_BudgetChartCard> createState() => _BudgetChartCardState();
}

class _BudgetChartCardState extends State<_BudgetChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _BudgetChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periods != widget.periods) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final periods = widget.periods;
    final maxSpent = periods.isEmpty
        ? 0.0
        : periods.map((e) => e.total).reduce(math.max);

    final maxY = math.max(
      widget.limitAmount <= 0 ? 1 : widget.limitAmount,
      maxSpent <= 0 ? 1 : maxSpent,
    ) * 1.22;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
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
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 6,
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

          const SizedBox(height: 16),

          SizedBox(
            height: 230,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final animValue = _animation.value;
                return BarChart(
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
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= periods.length) {
                              return const SizedBox.shrink();
                            }

                            final item = periods[index];
                            final label = item.shortLabel ?? widget.monthLabel(item.date);
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                label,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontSize: 11,
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
                        if (widget.limitAmount > 0)
                          HorizontalLine(
                            y: widget.limitAmount,
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
                            toY: item.total * animValue,
                            width: 26,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
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
                            widget.compactMoney(rod.toY),
                            TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
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
            width: 18,
            height: 2.5,
            color: color,
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.bodySecondary(context).copyWith(
            fontSize: 12,
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
  final void Function(_BudgetPeriodData item) onPeriodTap;

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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
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
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...periods.map((item) {
            return _PeriodDetailItem(
              item: item,
              limitAmount: limitAmount,
              money: money,
              monthLabel: monthLabel,
              onTap: () => onPeriodTap(item),
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

    const radius = Radius.circular(16);

    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(radius),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: item.isCurrent
                ? AppColors.primaryBlue.withValues(alpha: 0.10)
                : AppColors.surface(context).withValues(
                    alpha: AppColors.isDark(context) ? 0.72 : 0.92,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isCurrent
                  ? AppColors.primaryBlue.withValues(alpha: 0.42)
                  : item.isOverLimit
                      ? AppColors.expense.withValues(alpha: 0.35)
                      : AppColors.innerBorder(context),
              width: item.isCurrent ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark(context) ? 0.10 : 0.03,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: item.isOverLimit
                        ? AppColors.expense
                        : item.isCurrent
                            ? AppColors.primaryBlue
                            : AppColors.income,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (item.isCurrent) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
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
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],

                            Text(
                              item.label ?? monthLabel(item.date),
                              maxLines: 1,
                              softWrap: false,
                              style: AppTextStyles.cardTitle(context).copyWith(
                                fontSize: 14,
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    percentText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.caption(context).copyWith(
                                      fontSize: 11,
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
                              size: 18,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: item.percent,
                            minHeight: 6,
                            backgroundColor: AppColors.card(context),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (item.isOverLimit) ...[
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.expense,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        l10n.overBudgetWarning,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.expense,
                                          fontSize: 11.5,
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
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            Flexible(
                              child: Text(
                                l10n.budgetLimitLabel(money(limitAmount)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.bodySecondary(context).copyWith(
                                  fontSize: 11.5,
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
  final DateTime? endDate;
  final double total;
  final bool isCurrent;
  final bool isOverLimit;
  final double percent;
  final String? label;
  final String? shortLabel;

  const _BudgetPeriodData({
    required this.date,
    this.endDate,
    required this.total,
    required this.isCurrent,
    required this.isOverLimit,
    required this.percent,
    this.label,
    this.shortLabel,
  });
}
