import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';

class StatsWidgetData {
  final double totalExpense;
  final double? previousMonthExpense;
  final List<CategoryShare> categories;
  final String currency;
  final String monthLabel;
  final String noExpenseLabel;
  final bool isDark;
  final bool isEn;

  const StatsWidgetData({
    required this.totalExpense,
    this.previousMonthExpense,
    required this.categories,
    this.currency = 'VND',
    required this.monthLabel,
    this.noExpenseLabel = 'Chưa có chi tiêu',
    this.isDark = true,
    this.isEn = false,
  });

  double? get changePercent {
    if (previousMonthExpense == null || previousMonthExpense! <= 0) {
      return null;
    }
    return ((totalExpense - previousMonthExpense!) / previousMonthExpense!) * 100;
  }
}

class CategoryShare {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const CategoryShare({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class StatsAppWidgetView extends StatelessWidget {
  final StatsWidgetData data;

  const StatsAppWidgetView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = data.isDark;

    final formattedAmount = AppCurrencyFormatter.formatFromVnd(
      amountVnd: data.totalExpense,
      currency: data.currency,
    );

    final change = data.changePercent;
    final changeText = change == null
        ? null
        : change < 0
            ? '↓ ${(-change).toStringAsFixed(1)}%'
            : '↑ ${change.toStringAsFixed(1)}%';
    final changeColor = (change != null && change < 0)
        ? const Color(0xFF10B981)
        : (isDark ? const Color(0xFFFF5B5B) : const Color(0xFFE53935));

    // Dynamic Theme Colors
    final bgColor = isDark ? const Color(0xFF18191E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E9F2);
    final textSubColor = isDark ? const Color(0xFF9E9EA7) : const Color(0xFF74788A);
    final amountColor = isDark ? const Color(0xFFFF5B5B) : const Color(0xFFE53935);

    return MediaQuery(
      data: const MediaQueryData(
        size: Size(380, 180),
        devicePixelRatio: 2.5,
        textScaler: TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 380,
            height: 180,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Left Donut Chart
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      categories: data.categories,
                      totalExpense: data.totalExpense,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Right Info & Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Month Label
                      Text(
                        data.monthLabel,
                        style: TextStyle(
                          fontFamily: 'ProximaSoft',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSubColor,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Total Expense
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formattedAmount,
                          style: TextStyle(
                            fontFamily: 'ProximaSoft',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: amountColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      // Comparison Percentage
                      if (changeText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          changeText,
                          style: TextStyle(
                            fontFamily: 'ProximaSoft',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: changeColor,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Top Categories Legend (2 columns)
                      _buildLegendGrid(data.categories, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendGrid(List<CategoryShare> categories, bool isDark) {
    if (categories.isEmpty) {
      return Text(
        data.noExpenseLabel,
        style: TextStyle(
          fontFamily: 'ProximaSoft',
          fontSize: 11,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFFA0A4B5),
        ),
      );
    }

    final topCategories = categories.take(6).toList();
    final col1 = <CategoryShare>[];
    final col2 = <CategoryShare>[];

    for (int i = 0; i < topCategories.length; i++) {
      if (i % 2 == 0) {
        col1.add(topCategories[i]);
      } else {
        col2.add(topCategories[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: col1.map((cat) => _buildLegendItem(cat, isDark)).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: col2.map((cat) => _buildLegendItem(cat, isDark)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(CategoryShare cat, bool isDark) {
    final legendTextColor =
        isDark ? const Color(0xFFD1D1D6) : const Color(0xFF2E3240);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: cat.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${cat.percentage.toStringAsFixed(0)}% ${cat.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'ProximaSoft',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: legendTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategoryShare> categories;
  final double totalExpense;
  final bool isDark;

  _DonutChartPainter({
    required this.categories,
    required this.totalExpense,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 20.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (totalExpense <= 0 || categories.isEmpty) {
      paint.color = isDark ? const Color(0xFF2C2C32) : const Color(0xFFE2E7F0);
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;
    const gapAngle = 0.03; // small gap between arcs

    for (final cat in categories) {
      if (cat.amount <= 0) continue;
      final sweepAngle = (cat.amount / totalExpense) * 2 * math.pi;

      if (sweepAngle > gapAngle) {
        paint.color = cat.color;
        canvas.drawArc(
          rect,
          startAngle + gapAngle / 2,
          sweepAngle - gapAngle,
          false,
          paint,
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.totalExpense != totalExpense ||
        oldDelegate.categories != categories ||
        oldDelegate.isDark != isDark;
  }
}
