import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';

class BudgetCycleInfo {
  final DateTime startDate;
  final DateTime endDate;
  final int daysRemaining;
  final String label;
  final bool isExpired;

  const BudgetCycleInfo({
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.label,
    this.isExpired = false,
  });
}

class BudgetCycleHistoryItem {
  final String label;
  final String shortLabel;
  final DateTime startDate;
  final DateTime endDate;
  final double spentAmount;
  final double limitAmount;

  const BudgetCycleHistoryItem({
    required this.label,
    required this.shortLabel,
    required this.startDate,
    required this.endDate,
    required this.spentAmount,
    required this.limitAmount,
  });

  bool get isOverLimit => limitAmount > 0 && spentAmount > limitAmount;
  double get percent => limitAmount <= 0 ? 0.0 : (spentAmount / limitAmount).clamp(0.0, 1.0);
}

class BudgetCycleHelper {
  const BudgetCycleHelper._();

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Canonical category normalization for matching between Vietnamese & English default names.
  static String canonicalCategory(String raw) {
    final s = raw.trim().toLowerCase();
    switch (s) {
      case 'ăn uống':
      case 'an uong':
      case 'food':
      case 'dining':
        return 'food';
      case 'mua sắm':
      case 'mua sam':
      case 'shopping':
        return 'shopping';
      case 'đi lại':
      case 'di lai':
      case 'transport':
      case 'transportation':
        return 'transport';
      case 'giải trí':
      case 'giai tri':
      case 'entertainment':
        return 'entertainment';
      case 'học tập':
      case 'hoc tap':
      case 'education':
        return 'education';
      case 'khác':
      case 'khac':
      case 'other':
      case 'others':
        return 'other';
      default:
        return s;
    }
  }

  /// Checks if a budget name indicates overall total expenses.
  static bool isTotalBudgetName(String name) {
    final s = name.trim().toLowerCase();
    return s == 'tổng chi tiêu' ||
        s == 'tong chi tieu' ||
        s == 'tổng' ||
        s == 'tong' ||
        s == 'total' ||
        s == 'total expenses' ||
        s == 'all spending';
  }

  /// Checks if a transaction's category matches the budget criteria.
  static bool matchesCategory(BudgetModel budget, String txCategory) {
    // Only genuine overall total spending budgets match all transactions
    if (budget.budgetType == 'total' && isTotalBudgetName(budget.name)) {
      return true;
    }

    final rawTx = txCategory.trim().toLowerCase();
    final rawName = budget.name.trim().toLowerCase();
    final rawNameEn = (budget.nameEn ?? '').trim().toLowerCase();
    final rawKey = (budget.categoryKey ?? '').trim().toLowerCase();

    if (rawTx == rawName || (rawNameEn.isNotEmpty && rawTx == rawNameEn) || (rawKey.isNotEmpty && rawTx == rawKey)) {
      return true;
    }

    final cTx = canonicalCategory(rawTx);
    final cName = canonicalCategory(rawName);
    final cKey = rawKey.isNotEmpty ? canonicalCategory(rawKey) : '';

    if (cTx == cName && cTx.isNotEmpty) return true;
    if (cKey.isNotEmpty && cTx == cKey) return true;

    return false;
  }

  /// Calculates the active cycle range for a given budget relative to [refDate] (defaults to now).
  static BudgetCycleInfo getCurrentCycle(
    BudgetModel budget, [
    DateTime? refDate,
    bool isEnglish = false,
  ]) {
    final now = refDate ?? DateTime.now();

    switch (budget.period) {
      case 'daily': {
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return BudgetCycleInfo(
          startDate: start,
          endDate: end,
          daysRemaining: 0,
          label: '${_pad(now.day)}/${_pad(now.month)}',
          isExpired: false,
        );
      }

      case 'weekly': {
        // Dart weekday: 1 (Mon) .. 7 (Sun)
        final start = DateTime(now.year, now.month, now.day - (now.weekday - 1), 0, 0, 0, 0);
        final end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
        final daysRemaining = 7 - now.weekday;
        return BudgetCycleInfo(
          startDate: start,
          endDate: end,
          daysRemaining: daysRemaining,
          label: '${_pad(start.day)}/${_pad(start.month)} - ${_pad(end.day)}/${_pad(end.month)}',
          isExpired: false,
        );
      }

      case 'biweekly': {
        DateTime anchor = budget.startDate ?? budget.createdAt;
        anchor = DateTime(anchor.year, anchor.month, anchor.day, 0, 0, 0, 0);

        DateTime cycleStart;
        if (now.isBefore(anchor)) {
          cycleStart = anchor;
        } else {
          final diffDays = now.difference(anchor).inDays;
          final cycleIndex = diffDays ~/ 14;
          cycleStart = anchor.add(Duration(days: cycleIndex * 14));
        }
        final cycleEnd = cycleStart.add(
          const Duration(days: 13, hours: 23, minutes: 59, seconds: 59, milliseconds: 999),
        );
        final daysRemaining = (cycleEnd.difference(now).inDays).clamp(0, 14);

        return BudgetCycleInfo(
          startDate: cycleStart,
          endDate: cycleEnd,
          daysRemaining: daysRemaining,
          label: '${_pad(cycleStart.day)}/${_pad(cycleStart.month)} - ${_pad(cycleEnd.day)}/${_pad(cycleEnd.month)}',
          isExpired: false,
        );
      }

      case 'yearly': {
        final start = DateTime(now.year, 1, 1, 0, 0, 0, 0);
        final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        final daysRemaining = end.difference(now).inDays;
        return BudgetCycleInfo(
          startDate: start,
          endDate: end,
          daysRemaining: daysRemaining,
          label: '${now.year}',
          isExpired: false,
        );
      }

      case 'custom': {
        DateTime start = budget.startDate ?? budget.createdAt;
        start = DateTime(start.year, start.month, start.day, 0, 0, 0, 0);
        DateTime end = budget.endDate ?? start.add(const Duration(days: 30));
        end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

        final isExpired = now.isAfter(end);
        final daysRemaining = isExpired ? 0 : end.difference(now).inDays;

        return BudgetCycleInfo(
          startDate: start,
          endDate: end,
          daysRemaining: daysRemaining,
          label: '${_pad(start.day)}/${_pad(start.month)}/${start.year} - ${_pad(end.day)}/${_pad(end.month)}/${end.year}',
          isExpired: isExpired,
        );
      }

      case 'monthly':
      default: {
        final start = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final end = DateTime(now.year, now.month, lastDay, 23, 59, 59, 999);
        final daysRemaining = lastDay - now.day;
        return BudgetCycleInfo(
          startDate: start,
          endDate: end,
          daysRemaining: daysRemaining,
          label: isEnglish ? 'M${now.month}/${now.year}' : 'T${now.month}/${now.year}',
          isExpired: false,
        );
      }
    }
  }

  /// Calculates dynamically the total spent amount for [budget] during its current active cycle.
  static double calculateCycleSpent(
    BudgetModel budget,
    List<TransactionModel> transactions, [
    DateTime? refDate,
  ]) {
    final cycle = getCurrentCycle(budget, refDate);
    return calculateSpentInPeriod(
      budget,
      transactions,
      startDate: cycle.startDate,
      endDate: cycle.endDate,
    );
  }

  /// Calculates spending within an arbitrary [startDate] and [endDate] window.
  static double calculateSpentInPeriod(
    BudgetModel budget,
    List<TransactionModel> transactions, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    double total = 0.0;

    for (final tx in transactions) {
      if (tx.type != 'expense') continue;

      if (tx.createdAt.isBefore(startDate) || tx.createdAt.isAfter(endDate)) {
        continue;
      }

      if (matchesCategory(budget, tx.category)) {
        total += tx.amount;
      }
    }

    return total;
  }

  /// Human-friendly cycle subtitle for budget cards.
  static String formatCycleSubtitle(
    BudgetModel budget, {
    bool isEnglish = false,
  }) {
    final cycle = getCurrentCycle(budget, null, isEnglish);

    if (budget.period == 'custom') {
      if (cycle.isExpired) {
        return isEnglish
            ? 'Expired • ${cycle.label}'
            : 'Đã hết hạn • ${cycle.label}';
      }
      return isEnglish
          ? '${cycle.daysRemaining} days left • ${cycle.label}'
          : 'Còn ${cycle.daysRemaining} ngày • ${cycle.label}';
    }

    if (budget.period == 'daily') {
      return isEnglish ? 'Daily • Today' : 'Hôm nay • Hằng ngày';
    }

    final daysText = isEnglish
        ? '${cycle.daysRemaining} days left'
        : 'Còn ${cycle.daysRemaining} ngày';

    return '$daysText • ${cycle.label}';
  }

  /// Returns historical cycle data for [budget] to power the budget history chart.
  static List<BudgetCycleHistoryItem> getHistoricalCycles(
    BudgetModel budget,
    List<TransactionModel> transactions, {
    int count = 6,
    DateTime? refDate,
    bool isEnglish = false,
  }) {
    final now = refDate ?? DateTime.now();
    final items = <BudgetCycleHistoryItem>[];

    switch (budget.period) {
      case 'daily': {
        for (int i = count - 1; i >= 0; i--) {
          final dayDate = now.subtract(Duration(days: i));
          final start = DateTime(dayDate.year, dayDate.month, dayDate.day, 0, 0, 0, 0);
          final end = DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59, 999);
          final spent = calculateSpentInPeriod(budget, transactions, startDate: start, endDate: end);
          final label = '${_pad(dayDate.day)}/${_pad(dayDate.month)}';
          items.add(BudgetCycleHistoryItem(
            label: label,
            shortLabel: _pad(dayDate.day),
            startDate: start,
            endDate: end,
            spentAmount: spent,
            limitAmount: budget.limitAmount,
          ));
        }
        break;
      }

      case 'weekly': {
        final thisWeekMon = DateTime(now.year, now.month, now.day - (now.weekday - 1), 0, 0, 0, 0);
        for (int i = count - 1; i >= 0; i--) {
          final start = thisWeekMon.subtract(Duration(days: i * 7));
          final end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
          final spent = calculateSpentInPeriod(budget, transactions, startDate: start, endDate: end);
          final label = '${_pad(start.day)}/${_pad(start.month)} - ${_pad(end.day)}/${_pad(end.month)}';
          final shortLabel = '${_pad(start.day)}/${_pad(start.month)}';
          items.add(BudgetCycleHistoryItem(
            label: label,
            shortLabel: shortLabel,
            startDate: start,
            endDate: end,
            spentAmount: spent,
            limitAmount: budget.limitAmount,
          ));
        }
        break;
      }

      case 'biweekly': {
        final currentCycle = getCurrentCycle(budget, now, isEnglish);
        for (int i = count - 1; i >= 0; i--) {
          final start = currentCycle.startDate.subtract(Duration(days: i * 14));
          final end = start.add(
            const Duration(days: 13, hours: 23, minutes: 59, seconds: 59, milliseconds: 999),
          );
          final spent = calculateSpentInPeriod(budget, transactions, startDate: start, endDate: end);
          final label = '${_pad(start.day)}/${_pad(start.month)} - ${_pad(end.day)}/${_pad(end.month)}';
          final shortLabel = '${_pad(start.day)}/${_pad(start.month)}';
          items.add(BudgetCycleHistoryItem(
            label: label,
            shortLabel: shortLabel,
            startDate: start,
            endDate: end,
            spentAmount: spent,
            limitAmount: budget.limitAmount,
          ));
        }
        break;
      }

      case 'yearly': {
        for (int i = count - 1; i >= 0; i--) {
          final yr = now.year - i;
          final start = DateTime(yr, 1, 1, 0, 0, 0, 0);
          final end = DateTime(yr, 12, 31, 23, 59, 59, 999);
          final spent = calculateSpentInPeriod(budget, transactions, startDate: start, endDate: end);
          items.add(BudgetCycleHistoryItem(
            label: '$yr',
            shortLabel: '$yr',
            startDate: start,
            endDate: end,
            spentAmount: spent,
            limitAmount: budget.limitAmount,
          ));
        }
        break;
      }

      case 'custom': {
        DateTime start = budget.startDate ?? budget.createdAt;
        start = DateTime(start.year, start.month, start.day, 0, 0, 0, 0);
        DateTime end = budget.endDate ?? start.add(const Duration(days: 30));
        end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

        final totalDays = end.difference(start).inDays + 1;
        if (totalDays <= count) {
          // Break day by day
          for (int i = 0; i < totalDays; i++) {
            final d = start.add(Duration(days: i));
            final dStart = DateTime(d.year, d.month, d.day, 0, 0, 0, 0);
            final dEnd = DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
            final spent = calculateSpentInPeriod(budget, transactions, startDate: dStart, endDate: dEnd);
            items.add(BudgetCycleHistoryItem(
              label: '${_pad(d.day)}/${_pad(d.month)}',
              shortLabel: _pad(d.day),
              startDate: dStart,
              endDate: dEnd,
              spentAmount: spent,
              limitAmount: budget.limitAmount / totalDays,
            ));
          }
        } else {
          // Break into `count` segments
          final segmentDays = (totalDays / count).ceil();
          for (int i = 0; i < count; i++) {
            final segStart = start.add(Duration(days: i * segmentDays));
            if (segStart.isAfter(end)) break;
            DateTime segEnd = segStart.add(Duration(days: segmentDays - 1, hours: 23, minutes: 59, seconds: 59));
            if (segEnd.isAfter(end)) segEnd = end;

            final spent = calculateSpentInPeriod(budget, transactions, startDate: segStart, endDate: segEnd);
            final label = '${_pad(segStart.day)}/${_pad(segStart.month)} - ${_pad(segEnd.day)}/${_pad(segEnd.month)}';
            items.add(BudgetCycleHistoryItem(
              label: label,
              shortLabel: '${_pad(segStart.day)}/${_pad(segStart.month)}',
              startDate: segStart,
              endDate: segEnd,
              spentAmount: spent,
              limitAmount: budget.limitAmount / count,
            ));
          }
        }
        break;
      }

      case 'monthly':
      default: {
        for (int i = count - 1; i >= 0; i--) {
          final monthDate = DateTime(now.year, now.month - i, 1);
          final start = DateTime(monthDate.year, monthDate.month, 1, 0, 0, 0, 0);
          final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0).day;
          final end = DateTime(monthDate.year, monthDate.month, lastDay, 23, 59, 59, 999);
          final spent = calculateSpentInPeriod(budget, transactions, startDate: start, endDate: end);
          final label = isEnglish
              ? 'Month ${monthDate.month}/${monthDate.year}'
              : 'Tháng ${monthDate.month}/${monthDate.year}';
          final shortLabel = isEnglish ? 'M${monthDate.month}' : 'T${monthDate.month}';
          items.add(BudgetCycleHistoryItem(
            label: label,
            shortLabel: shortLabel,
            startDate: start,
            endDate: end,
            spentAmount: spent,
            limitAmount: budget.limitAmount,
          ));
        }
        break;
      }
    }

    return items;
  }
}
