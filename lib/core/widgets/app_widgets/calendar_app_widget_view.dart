import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';

enum CalendarCellTone {
  none, // Ngày không có giao dịch -> màu xám
  incomeOnly, // Ngày chỉ có thu nhập -> màu xanh lá
  lowExpense, // Tiêu ít dưới 100k -> màu vàng nhạt
  mediumExpense, // Tiêu dưới 500k -> màu cam
  highExpense, // Tiêu trên 500k -> màu đỏ
  both, // Ngày vừa tiêu vừa thu -> màu tím
}

class CalendarDayInfo {
  final int day;
  final double expense; // in base VND
  final double income; // in base VND
  final bool hasPhoto;
  final bool isToday;

  const CalendarDayInfo({
    required this.day,
    this.expense = 0.0,
    this.income = 0.0,
    this.hasPhoto = false,
    this.isToday = false,
  });

  bool get hasExpense => expense > 0;
  bool get hasIncome => income > 0;
  bool get hasTransaction => hasExpense || hasIncome;
}

class CalendarWidgetData {
  final String monthLabel;
  final int streak;
  final String totalExpenseCompact;
  final int transactionCount;
  final String totalIncomeCompact;
  final int year;
  final int month;
  final Map<int, CalendarDayInfo> days;
  final Map<int, Uint8List> dayThumbnails; // Kept for backward compatibility
  final Set<int> daysWithSpending; // Kept for backward compatibility
  final Set<int> daysWithPhoto; // Kept for backward compatibility
  final int? today; // Today's day of month
  final bool isDark;
  final String currency; // 'VND' or 'USD'
  final bool isEn;
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
    this.days = const {},
    this.dayThumbnails = const {},
    this.daysWithSpending = const {},
    this.daysWithPhoto = const {},
    this.today,
    this.isDark = true,
    this.currency = 'VND',
    this.isEn = false,
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

  static String formatCellAmount({
    required double amountVnd,
    required String currency,
    required bool isEn,
    bool showPlus = false,
  }) {
    if (amountVnd <= 0) return '';
    final normCurrency = AppCurrencyFormatter.normalizeCurrency(currency);

    if (normCurrency == 'USD') {
      final usd =
          AppCurrencyFormatter.fromVnd(amountVnd: amountVnd, currency: 'USD');
      final prefix = showPlus ? '+\$' : '\$';
      if (usd < 1000) {
        final val = usd.round();
        return '$prefix$val';
      } else if (usd < 1000000) {
        final k = usd / 1000;
        final text = (k >= 10 || k % 1 == 0)
            ? k.round().toString()
            : k.toStringAsFixed(1);
        return '$prefix${text}k';
      } else {
        final m = usd / 1000000;
        final text = (m >= 10 || m % 1 == 0)
            ? m.round().toString()
            : m.toStringAsFixed(1);
        return '$prefix${text}M';
      }
    }

    // VND
    final prefix = showPlus ? '+' : '';
    if (amountVnd < 1000) {
      return '$prefix${amountVnd.round()}';
    } else if (amountVnd < 1000000) {
      final k = (amountVnd / 1000).round();
      return '$prefix${k}k';
    } else if (amountVnd < 1000000000) {
      final m = amountVnd / 1000000;
      final text =
          (m >= 10 || m % 1 == 0) ? m.round().toString() : m.toStringAsFixed(1);
      final unit = isEn ? 'M' : 'tr';
      return '$prefix$text$unit';
    } else {
      final b = amountVnd / 1000000000;
      final text =
          (b >= 10 || b % 1 == 0) ? b.round().toString() : b.toStringAsFixed(1);
      final unit = isEn ? 'B' : 'tỷ';
      return '$prefix$text$unit';
    }
  }

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

    // Dynamic Theme Colors (Default Dark Theme for Launcher Widgets)
    final bgColor = isDark ? const Color(0xFF14151A) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE5E9F2);
    final monthTextColor = isDark ? Colors.white : const Color(0xFF181922);
    final summaryBgColor =
        isDark ? const Color(0xFF1E2028) : const Color(0xFFF1F4F9);
    final summarySubColor =
        isDark ? const Color(0xFF9EA2B4) : const Color(0xFF74788A);
    final weekdayTextColor =
        isDark ? const Color(0xFF9EA2B4) : const Color(0xFF74788A);

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: monthTextColor,
                      ),
                    ),

                    // Streak Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
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
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${data.streak}',
                            style: const TextStyle(
                              fontFamily: 'ProximaSoft',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),

                // 2. Summary Overview Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: summaryBgColor,
                    borderRadius: BorderRadius.circular(15),
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
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                data.totalExpenseCompact,
                                style: TextStyle(
                                  fontFamily: 'ProximaSoft',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFFFF5B5B)
                                      : const Color(0xFFE53935),
                                ),
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
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${data.transactionCount}',
                                style: TextStyle(
                                  fontFamily: 'ProximaSoft',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFF7DDC86)
                                      : const Color(0xFF10B981),
                                ),
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
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                data.totalIncomeCompact,
                                style: TextStyle(
                                  fontFamily: 'ProximaSoft',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFF59D4C8)
                                      : const Color(0xFF00ACC1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),

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
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: weekdayTextColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 5),

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
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Row(
              children: rowCells.map((day) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
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

    final isToday = data.today == day;
    final dayInfo = data.days[day];

    final double expense = dayInfo?.expense ?? 0.0;
    final double income = dayInfo?.income ?? 0.0;
    final bool hasPhoto = (dayInfo?.hasPhoto ?? false) ||
        data.daysWithPhoto.contains(day) ||
        (data.dayThumbnails[day]?.isNotEmpty ?? false);

    final hasExp = expense > 0 || data.daysWithSpending.contains(day);
    final hasInc = income > 0;

    // Phân loại mức độ theo yêu cầu:
    // - Màu xanh: Ngày chỉ có thu nhập
    // - Màu vàng nhạt: Tiêu ít dưới 100k
    // - Màu cam: Tiêu dưới 500k
    // - Màu đỏ: Tiêu trên 500k
    // - Màu tím: Ngày vừa tiêu vừa thu
    // - Màu xám: Ngày không có giao dịch
    CalendarCellTone tone;
    if (!hasExp && !hasInc) {
      tone = CalendarCellTone.none;
    } else if (hasInc && !hasExp) {
      tone = CalendarCellTone.incomeOnly;
    } else if (hasInc && hasExp) {
      tone = CalendarCellTone.both;
    } else {
      // Expense only (100k VND và 500k VND)
      if (expense < 100000) {
        tone = CalendarCellTone.lowExpense;
      } else if (expense <= 500000) {
        tone = CalendarCellTone.mediumExpense;
      } else {
        tone = CalendarCellTone.highExpense;
      }
    }

    Color cardColor;
    Color borderColor;
    Color dayNumColor;
    Color amountColor;
    String? amountText;
    String? incomeText;
    String? expenseText;

    switch (tone) {
      case CalendarCellTone.none:
        if (isToday) {
          // Hôm nay chưa có giao dịch: Vùng xanh nổi bật rõ rệt
          cardColor =
              isDark ? const Color(0xFF142B4D) : const Color(0xFFE8F1FF);
          borderColor = const Color(0xFF2979FF);
          dayNumColor =
              isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
          amountColor = Colors.transparent;
          amountText = null;
        } else {
          // Ngày không có giao dịch: Màu xám
          cardColor =
              isDark ? const Color(0xFF21232D) : const Color(0xFFF1F3F8);
          borderColor =
              isDark ? const Color(0xFF303444) : const Color(0xFFE0E4EE);
          dayNumColor =
              isDark ? const Color(0xFF868C9E) : const Color(0xFF8E95A5);
          amountColor = Colors.transparent;
          amountText = null;
        }
        break;

      case CalendarCellTone.incomeOnly:
        // Màu xanh: Ngày chỉ có thu nhập
        cardColor = isDark ? const Color(0xFF133526) : const Color(0xFFE6F7ED);
        borderColor = isToday
            ? const Color(0xFF2979FF)
            : (isDark ? const Color(0xFF10B981) : const Color(0xFF22C55E));
        dayNumColor =
            isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857);
        amountColor =
            isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669);
        amountText = formatCellAmount(
          amountVnd: income,
          currency: data.currency,
          isEn: data.isEn,
          showPlus: true,
        );
        break;

      case CalendarCellTone.lowExpense:
        // Màu vàng nhạt: Tiêu ít dưới 100k
        cardColor = isDark ? const Color(0xFF383115) : const Color(0xFFFEF9C3);
        borderColor = isToday
            ? const Color(0xFF2979FF)
            : (isDark ? const Color(0xFFFACC15) : const Color(0xFFEAB308));
        dayNumColor =
            isDark ? const Color(0xFFFEF08A) : const Color(0xFF854D0E);
        amountColor =
            isDark ? const Color(0xFFFDE047) : const Color(0xFFB45309);
        amountText =
            '-${formatCellAmount(amountVnd: expense, currency: data.currency, isEn: data.isEn)}';
        break;

      case CalendarCellTone.mediumExpense:
        // Màu cam: Tiêu dưới 500k
        cardColor = isDark ? const Color(0xFF3F2110) : const Color(0xFFFFEDD5);
        borderColor = isToday
            ? const Color(0xFF2979FF)
            : (isDark ? const Color(0xFFFB923C) : const Color(0xFFF97316));
        dayNumColor =
            isDark ? const Color(0xFFFFEDD5) : const Color(0xFF9A3412);
        amountColor =
            isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C);
        amountText =
            '-${formatCellAmount(amountVnd: expense, currency: data.currency, isEn: data.isEn)}';
        break;

      case CalendarCellTone.highExpense:
        // Màu đỏ: Tiêu trên 500k
        cardColor = isDark ? const Color(0xFF42141A) : const Color(0xFFFEE2E2);
        borderColor = isToday
            ? const Color(0xFF2979FF)
            : (isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444));
        dayNumColor =
            isDark ? const Color(0xFFFEE2E2) : const Color(0xFF991B1B);
        amountColor =
            isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
        amountText =
            '-${formatCellAmount(amountVnd: expense, currency: data.currency, isEn: data.isEn)}';
        break;

      case CalendarCellTone.both:
        // Màu tím: Ngày vừa tiêu vừa thu (Hiện cả số tiền thu và số tiền chi, kiểu +150k / -45k)
        cardColor = isDark ? const Color(0xFF2E1945) : const Color(0xFFF3E8FF);
        borderColor = isToday
            ? const Color(0xFF2979FF)
            : (isDark ? const Color(0xFFA855F7) : const Color(0xFF9333EA));
        dayNumColor =
            isDark ? const Color(0xFFF3E8FF) : const Color(0xFF6B21A8);
        amountColor =
            isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE);

        incomeText =
            '+${formatCellAmount(amountVnd: income, currency: data.currency, isEn: data.isEn)}';
        expenseText =
            '-${formatCellAmount(amountVnd: expense, currency: data.currency, isEn: data.isEn)}';
        break;
    }

    final double borderWidth = isToday ? 1.0 : 0.45;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dòng trên: Số ngày (Nếu là hôm nay: có badge xanh nổi bật "vùng xanh") + icon ảnh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isToday
                  ? Container(
                      width: 12.0,
                      height: 12.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2979FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          fontFamily: 'ProximaSoft',
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    )
                  : Text(
                      '$day',
                      style: TextStyle(
                        fontFamily: 'ProximaSoft',
                        fontSize: 8.5,
                        fontWeight: (tone != CalendarCellTone.none || isToday)
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: dayNumColor,
                        height: 1.0,
                      ),
                    ),
              if (hasPhoto)
                Icon(
                  Icons.camera_alt_rounded,
                  size: 7.0,
                  color: dayNumColor.withValues(alpha: 0.85),
                ),
            ],
          ),

          // Dòng dưới: Số tiền hiển thị trong khung
          if (incomeText != null && expenseText != null)
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        incomeText,
                        style: TextStyle(
                          fontFamily: 'ProximaSoft',
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF059669),
                          letterSpacing: -0.3,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 0.5),
                      Text(
                        expenseText,
                        style: TextStyle(
                          fontFamily: 'ProximaSoft',
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFDC2626),
                          letterSpacing: -0.3,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (amountText != null && amountText.isNotEmpty)
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: Text(
                    amountText,
                    style: TextStyle(
                      fontFamily: 'ProximaSoft',
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                      letterSpacing: -0.3,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}
