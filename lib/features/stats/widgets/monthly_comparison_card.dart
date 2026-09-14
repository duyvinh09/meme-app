import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';

class MonthlyComparisonCard extends StatefulWidget {
  final List<dynamic> transactions;
  final DateTime referenceDate;
  final String currency;
  final Color cardBackground;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color innerTileBackground;
  final Color innerTileBorder;

  const MonthlyComparisonCard({
    super.key,
    required this.transactions,
    required this.referenceDate,
    required this.currency,
    required this.cardBackground,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.innerTileBackground,
    required this.innerTileBorder,
  });

  @override
  State<MonthlyComparisonCard> createState() => _MonthlyComparisonCardState();
}

class _MonthlyComparisonCardState extends State<MonthlyComparisonCard> {
  int _selectedMonths = 6;
  bool _isExpanded = false;
  int? _touchedGroupIndex;

  static const Color _incomeColor = Color(0xFF5CD97B);
  static const Color _expenseColor = Color(0xFFFF7A7A);

  bool _isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }

  bool _isExpenseTx(dynamic tx) {
    if (tx is TransactionModel) {
      return tx.isPersonalExpense;
    }
    final isGroupExp = tx.isGroupExpense == true;
    final isGroupContrib = tx.isGroupContribution == true;
    return (tx.type == 'expense' && !isGroupExp) || isGroupContrib;
  }

  bool _isIncomeTx(dynamic tx) {
    if (tx is TransactionModel) {
      return tx.isPersonalIncome;
    }
    final isGroupContrib = tx.isGroupContribution == true;
    return tx.type == 'income' && !isGroupContrib;
  }

  String _formatCompactValue(double value) {
    if (value <= 0) return '0';
    if (value >= 1000000000) {
      final v = value / 1000000000;
      return '${v.toStringAsFixed(v >= 10 || v % 1 == 0 ? 0 : 1)}B';
    }
    if (value >= 1000000) {
      final v = value / 1000000;
      return '${v.toStringAsFixed(v >= 10 || v % 1 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return '${v.toStringAsFixed(v >= 10 || v % 1 == 0 ? 0 : 1)}K';
    }
    return value.toInt().toString();
  }

  String _getMonthShortLabel(DateTime date, bool isEn) {
    if (isEn) {
      const enMonths = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      if (date.month >= 1 && date.month <= 12) {
        return enMonths[date.month - 1];
      }
      return 'M${date.month}';
    }
    if (_selectedMonths >= 9) {
      return 'T${date.month}';
    }
    return 'thg ${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final l10n = context.l10n;

    // Generate list of months
    final List<DateTime> months = List.generate(_selectedMonths, (i) {
      final offset = _selectedMonths - 1 - i;
      return DateTime(
        widget.referenceDate.year,
        widget.referenceDate.month - offset,
        1,
      );
    });

    final List<_MonthData> monthDataList = months.map((m) {
      double inc = 0;
      double exp = 0;

      for (final tx in widget.transactions) {
        final DateTime txDate = tx.createdAt;
        if (_isSameMonth(txDate, m)) {
          if (_isExpenseTx(tx)) {
            exp += (tx.amount as num).toDouble();
          } else if (_isIncomeTx(tx)) {
            inc += (tx.amount as num).toDouble();
          }
        }
      }

      return _MonthData(
        date: m,
        income: inc,
        expense: exp,
      );
    }).toList();

    // Average expense
    final double totalExpense =
        monthDataList.fold(0.0, (sum, item) => sum + item.expense);
    final double avgExpense =
        _selectedMonths > 0 ? totalExpense / _selectedMonths : 0.0;
    final String avgExpenseFormatted = AppCurrencyFormatter.formatFromVnd(
      amountVnd: avgExpense,
      currency: widget.currency,
    );

    // Max value for chart Y-Axis
    double maxVal = 0;
    for (final item in monthDataList) {
      if (item.income > maxVal) maxVal = item.income;
      if (item.expense > maxVal) maxVal = item.expense;
    }

    // Determine nice rounded maxY and step
    double maxY = maxVal <= 0 ? 1000000 : maxVal * 1.18;
    final double power =
        math.pow(10, (math.log(maxY) / math.ln10).floor()).toDouble();
    final double lead = maxY / power;
    if (lead <= 2) {
      maxY = 2 * power;
    } else if (lead <= 5) {
      maxY = 5 * power;
    } else {
      maxY = 10 * power;
    }

    final double step = maxY / 3;

    final String cardTitle =
        isEn ? 'Monthly comparison' : 'So sánh theo tháng';
    final String avgSubtitle = isEn
        ? 'Average expense · $avgExpenseFormatted'
        : 'Trung bình chi tiêu · $avgExpenseFormatted';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.cardBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: widget.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.18 : 0.045,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardTitle,
                        style: TextStyle(
                          color: widget.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        avgSubtitle,
                        style: TextStyle(
                          color: widget.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: widget.textSecondary,
                  size: 26,
                ),
              ],
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 16),

            // Segment Filter (3 months / 6 months / 9 months)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.innerTileBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: widget.innerTileBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [3, 6, 9].map((count) {
                    final isSelected = _selectedMonths == count;
                    final label = isEn ? '$count months' : '$count tháng';
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonths = count;
                          _touchedGroupIndex = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : widget.textSecondary,
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Bar Chart
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: widget.cardBorder.withValues(alpha: 0.6),
                        strokeWidth: 0.8,
                        dashArray: null,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: step,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > maxY) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              _formatCompactValue(value),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: widget.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= monthDataList.length) {
                            return const SizedBox.shrink();
                          }
                          final m = monthDataList[idx].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _getMonthShortLabel(m, isEn),
                              style: TextStyle(
                                color: widget.textSecondary,
                                fontSize: _selectedMonths >= 9 ? 10.5 : 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => isDark
                          ? const Color(0xFF1E2028)
                          : const Color(0xFF2C303E),
                      tooltipMargin: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = monthDataList[group.x.toInt()];
                        final isInc = rodIndex == 0;
                        final label = isInc ? l10n.income : l10n.expense;
                        final amount = isInc ? item.income : item.expense;
                        final color = isInc ? _incomeColor : _expenseColor;

                        final headerTitle = isEn
                            ? '${_getMonthShortLabel(item.date, true)} ${item.date.year}\n'
                            : 'Tháng ${item.date.month}/${item.date.year}\n';

                        return BarTooltipItem(
                          headerTitle,
                          const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '$label: ${AppCurrencyFormatter.formatFromVnd(amountVnd: amount, currency: widget.currency)}',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        setState(() {
                          _touchedGroupIndex = null;
                        });
                        return;
                      }
                      setState(() {
                        _touchedGroupIndex =
                            response.spot!.touchedBarGroupIndex;
                      });
                    },
                  ),
                  barGroups: monthDataList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isTouched = _touchedGroupIndex == index;

                    final double rodWidth = _selectedMonths >= 9
                        ? 6.5
                        : (_selectedMonths >= 6 ? 9.5 : 14.0);
                    final double barsSpace = _selectedMonths >= 9
                        ? 2.5
                        : (_selectedMonths >= 6 ? 3.5 : 5.0);

                    return BarChartGroupData(
                      x: index,
                      barsSpace: barsSpace,
                      barRods: [
                        // Income Rod
                        BarChartRodData(
                          toY: item.income,
                          color: _incomeColor,
                          width: rodWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                            bottom: Radius.circular(2),
                          ),
                        ),
                        // Expense Rod
                        BarChartRodData(
                          toY: item.expense,
                          color: _expenseColor,
                          width: rodWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                            bottom: Radius.circular(2),
                          ),
                        ),
                      ],
                      showingTooltipIndicators: isTouched ? [0, 1] : const [],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Legend Row
            Row(
              children: [
                _buildLegendItem(l10n.income, _incomeColor),
                const SizedBox(width: 18),
                _buildLegendItem(l10n.expense, _expenseColor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: widget.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MonthData {
  final DateTime date;
  final double income;
  final double expense;

  const _MonthData({
    required this.date,
    required this.income,
    required this.expense,
  });
}
