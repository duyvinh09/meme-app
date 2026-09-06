import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/localization_extension.dart';

enum RewindPeriodType {
  week,
  month,
  quarter,
  year,
}

class RewindPeriod {
  final RewindPeriodType type;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final DateTime previousStartDateTime;
  final DateTime previousEndDateTime;

  const RewindPeriod({
    required this.type,
    required this.startDateTime,
    required this.endDateTime,
    required this.previousStartDateTime,
    required this.previousEndDateTime,
  });

  /// Tuần này (Thứ 2 đến Chủ nhật)
  factory RewindPeriod.thisWeek([DateTime? ref]) {
    final now = ref ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);

    final prevStart = start.subtract(const Duration(days: 7));
    final prevEnd = DateTime(prevStart.year, prevStart.month, prevStart.day + 6, 23, 59, 59, 999);

    return RewindPeriod(
      type: RewindPeriodType.week,
      startDateTime: start,
      endDateTime: end,
      previousStartDateTime: prevStart,
      previousEndDateTime: prevEnd,
    );
  }

  /// Tháng này
  factory RewindPeriod.thisMonth([DateTime? ref]) {
    final now = ref ?? DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final nextMonthFirst = DateTime(now.year, now.month + 1, 1);
    final end = nextMonthFirst.subtract(const Duration(milliseconds: 1));

    final prevStart = DateTime(now.year, now.month - 1, 1);
    final prevEnd = start.subtract(const Duration(milliseconds: 1));

    return RewindPeriod(
      type: RewindPeriodType.month,
      startDateTime: start,
      endDateTime: end,
      previousStartDateTime: prevStart,
      previousEndDateTime: prevEnd,
    );
  }

  /// Quý này
  factory RewindPeriod.thisQuarter([DateTime? ref]) {
    final now = ref ?? DateTime.now();
    final currentQuarter = ((now.month - 1) ~/ 3) + 1; // 1, 2, 3, 4
    final startMonth = (currentQuarter - 1) * 3 + 1;
    final start = DateTime(now.year, startMonth, 1);
    final nextQuarterFirst = DateTime(now.year, startMonth + 3, 1);
    final end = nextQuarterFirst.subtract(const Duration(milliseconds: 1));

    final prevStart = DateTime(now.year, startMonth - 3, 1);
    final prevEnd = start.subtract(const Duration(milliseconds: 1));

    return RewindPeriod(
      type: RewindPeriodType.quarter,
      startDateTime: start,
      endDateTime: end,
      previousStartDateTime: prevStart,
      previousEndDateTime: prevEnd,
    );
  }

  /// Năm này
  factory RewindPeriod.thisYear([DateTime? ref]) {
    final now = ref ?? DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);

    final prevStart = DateTime(now.year - 1, 1, 1);
    final prevEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59, 999);

    return RewindPeriod(
      type: RewindPeriodType.year,
      startDateTime: start,
      endDateTime: end,
      previousStartDateTime: prevStart,
      previousEndDateTime: prevEnd,
    );
  }

  factory RewindPeriod.fromType(RewindPeriodType type, [DateTime? ref]) {
    switch (type) {
      case RewindPeriodType.week:
        return RewindPeriod.thisWeek(ref);
      case RewindPeriodType.month:
        return RewindPeriod.thisMonth(ref);
      case RewindPeriodType.quarter:
        return RewindPeriod.thisQuarter(ref);
      case RewindPeriodType.year:
        return RewindPeriod.thisYear(ref);
    }
  }

  String getTitle(BuildContext context) {
    switch (type) {
      case RewindPeriodType.week:
        return context.l10n.rewindThisWeek;
      case RewindPeriodType.month:
        return context.l10n.rewindThisMonth;
      case RewindPeriodType.quarter:
        final currentQuarter = ((startDateTime.month - 1) ~/ 3) + 1;
        return '${context.l10n.rewindQuarter} $currentQuarter / ${startDateTime.year}';
      case RewindPeriodType.year:
        return '${context.l10n.rewindYear} ${startDateTime.year}';
    }
  }

  String getTypeName(BuildContext context) {
    switch (type) {
      case RewindPeriodType.week:
        return context.l10n.rewindWeek;
      case RewindPeriodType.month:
        return context.l10n.rewindMonth;
      case RewindPeriodType.quarter:
        return context.l10n.rewindQuarter;
      case RewindPeriodType.year:
        return context.l10n.rewindYear;
    }
  }

  String getDateRangeText() {
    final startFmt = DateFormat('dd/MM').format(startDateTime);
    final endFmt = DateFormat('dd/MM').format(endDateTime);
    if (type == RewindPeriodType.year) {
      return '${startDateTime.year}';
    }
    return '$startFmt → $endFmt';
  }
}
