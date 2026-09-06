import '../../../data/models/transaction_model.dart';
import 'rewind_period.dart';

class RewindCategoryItem {
  final String name;
  final double amount;
  final double percentage;
  final int? iconCodePoint;
  final String? colorHex;
  final int count;

  const RewindCategoryItem({
    required this.name,
    required this.amount,
    required this.percentage,
    this.iconCodePoint,
    this.colorHex,
    required this.count,
  });
}

class RewindDaySpending {
  final DateTime date;
  final double amount;
  final int count;

  const RewindDaySpending({
    required this.date,
    required this.amount,
    required this.count,
  });
}

class RewindBiggestDay {
  final DateTime date;
  final double amount;
  final int transactionCount;
  final List<RewindDaySpending> dailySpendings;

  const RewindBiggestDay({
    required this.date,
    required this.amount,
    required this.transactionCount,
    required this.dailySpendings,
  });
}

enum RewindHighlightType {
  dominantCategory,
  peakDay,
  biggestExpense,
}

class RewindHighlight {
  final RewindHighlightType type;
  final String emoji;
  final String? categoryName;
  final String? percentStr;
  final String? dateStr;

  const RewindHighlight({
    required this.type,
    required this.emoji,
    this.categoryName,
    this.percentStr,
    this.dateStr,
  });
}

class RewindData {
  final RewindPeriod period;
  final double totalExpense;
  final double totalIncome;
  final double balance;
  final int totalTransactions;
  final int expenseCount;
  final int incomeCount;

  // Previous period comparison
  final double prevTotalExpense;
  final double prevTotalIncome;
  final int prevTotalTransactions;
  final double? expenseChangePercent;
  final int transactionChangeDiff;

  // Breakdown & features
  final List<RewindCategoryItem> categories;
  final int streakDays;
  final Set<String> activeDateKeys; // 'yyyy-MM-dd'
  final List<TransactionModel> topExpenses;
  final RewindBiggestDay? biggestDay;
  final List<TransactionModel> momentTransactions;
  final RewindHighlight? highlight;

  const RewindData({
    required this.period,
    required this.totalExpense,
    required this.totalIncome,
    required this.balance,
    required this.totalTransactions,
    required this.expenseCount,
    required this.incomeCount,
    required this.prevTotalExpense,
    required this.prevTotalIncome,
    required this.prevTotalTransactions,
    this.expenseChangePercent,
    required this.transactionChangeDiff,
    required this.categories,
    required this.streakDays,
    required this.activeDateKeys,
    required this.topExpenses,
    this.biggestDay,
    required this.momentTransactions,
    this.highlight,
  });

  bool get hasTransactions => totalTransactions > 0;
  bool get hasExpenses => totalExpense > 0;
  bool get hasIncome => totalIncome > 0;
  bool get hasMoments => momentTransactions.isNotEmpty;
  bool get hasPreviousComparison => prevTotalTransactions > 0 || prevTotalExpense > 0;
}
