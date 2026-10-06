import 'dart:typed_data';
import 'package:flutter/material.dart';

class CalendarWidgetData {
  final String monthLabel;
  final int streak;
  final String totalExpenseCompact;
  final int transactionCount;
  final String totalIncomeCompact;
  final int year;
  final int month;
  final Map<int, Uint8List> dayThumbnails; // Day -> Image bytes
  final Set<int> daysWithSpending; // Days that had transactions
  final int? today; // Today's day of month
  final bool isDark;
  final String expenseLabel;
  final String txCountLabel;
  final String incomeLabel;
  final List<String> weekdayLabels;

  const CalendarWidgetData({
    required this.monthLabel,
    required this.streak,
    required this.totalExpenseCompact,
    required this.transactionCount,
    required this.totalIncomeCompact,
    required this.year,
    required this.month,
    required this.dayThumbnails,
    this.daysWithSpending = const {},
    this.today,
    this.isDark = true,
    this.expenseLabel = 'Chi tiêu',
    this.txCountLabel = 'Số giao dịch',
    this.incomeLabel = 'Thu vào',
    this.weekdayLabels = const [
      'Th 2',
      'Th 3',
      'Th 4',
      'Th 5',
      'Th 6',
      'Th 7',
      'CN',
    ],
  });
}

class CalendarAppWidgetView extends StatelessWidget {
  final CalendarWidgetData data;

  const CalendarAppWidgetView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = data.isDark;

    final firstDayOfMonth = DateTime(data.year, data.month, 1);
    final lastDayOfMonth = DateTime(data.year, data.month + 1, 0);

    // Monday is 1, Sunday is 7. Empty slots before 1st day = (weekday - 1).
    final emptyLeadingDays = firstDayOfMonth.weekday - 1;
    final totalDays = lastDayOfMonth.day;

    final cells = <int?>[];
    for (int i = 0; i < emptyLeadingDays; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= totalDays; d++) {
      cells.add(d);
    }

    // Dynamic Theme Colors
    final bgColor = isDark ? const Color(0xFF18191E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E9F2);
    final monthTextColor =
        isDark ? const Color(0xFFE4E4E8) : const Color(0xFF181922);
    final summaryBgColor =
        isDark ? const Color(0xFF24252C) : const Color(0xFFF1F4F9);
    final summarySubColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF74788A);
    final weekdayTextColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF74788A);

    return MediaQuery(
      data: const MediaQueryData(
        size: Size(370, 380),
        devicePixelRatio: 2.5,
        textScaler: TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 370,
            height: 380,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header: Month title + Streak Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      data.monthLabel,
                      style: TextStyle(
                        fontFamily: 'ProximaSoft',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: monthTextColor,
                      ),
                    ),

                    // Streak Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${data.streak}',
                            style: const TextStyle(
                              fontFamily: 'ProximaSoft',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Summary Overview Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: summaryBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Expense
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              data.expenseLabel,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.totalExpenseCompact,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? const Color(0xFFFF5B5B)
                                    : const Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Number of transactions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              data.txCountLabel,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${data.transactionCount}',
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? const Color(0xFF7DDC86)
                                    : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Income
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              data.incomeLabel,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.totalIncomeCompact,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? const Color(0xFF59D4C8)
                                    : const Color(0xFF00ACC1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Weekday Row
                Row(
                  children: data.weekdayLabels
                      .map(
                        (w) => Expanded(
                          child: Center(
                            child: Text(
                              w,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: weekdayTextColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),

                // 4. Calendar Days Grid
                Expanded(
                  child: _buildDaysGrid(cells, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysGrid(List<int?> cells, bool isDark) {
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final rowCells =
          cells.sublist(i, (i + 7 > cells.length) ? cells.length : i + 7);
      while (rowCells.length < 7) {
        rowCells.add(null);
      }

      rows.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: rowCells.map((day) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _buildDayCell(day, isDark),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(int? day, bool isDark) {
    if (day == null) {
      return const SizedBox.shrink();
    }

    final imageBytes = data.dayThumbnails[day];
    final hasSpending = data.daysWithSpending.contains(day);
    final isToday = data.today == day;

    // 1. Cell with Photo Moment
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: isToday
              ? Border.all(color: const Color(0xFF388AF6), width: 1.5)
              : Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.5,
                ),
          image: DecorationImage(
            image: MemoryImage(imageBytes),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$day',
              style: const TextStyle(
                fontFamily: 'ProximaSoft',
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Cell with Spending (Active transaction day but no photo)
    if (hasSpending) {
      final cardColor =
          isDark ? const Color(0xFF2C2D38) : const Color(0xFFFFECEE);
      final borderColor = isToday
          ? const Color(0xFF388AF6)
          : (isDark
              ? const Color(0xFFFF5B5B).withValues(alpha: 0.4)
              : const Color(0xFFFF7A7A).withValues(alpha: 0.4));
      final numColor =
          isDark ? Colors.white : const Color(0xFFD84B4B);

      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: borderColor,
            width: isToday ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: 'ProximaSoft',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: numColor,
                ),
              ),
            ),
            // Spending dot indicator
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 4.5,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 1, right: 1),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5B5B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Cell without Spending (Empty Day Card)
    final emptyCardColor =
        isDark ? const Color(0xFF22232A) : const Color(0xFFF2F5FA);
    final emptyBorderColor = isToday
        ? const Color(0xFF388AF6)
        : (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFE2E7F0));
    final emptyNumColor =
        isDark ? const Color(0xFF6E7280) : const Color(0xFFA0A5B5);

    return Container(
      decoration: BoxDecoration(
        color: emptyCardColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: emptyBorderColor,
          width: isToday ? 1.5 : 0.5,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          '$day',
          style: TextStyle(
            fontFamily: 'ProximaSoft',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: emptyNumColor,
          ),
        ),
      ),
    );
  }
}
