import 'package:intl/intl.dart';

import '../../../data/models/transaction_model.dart';
import '../models/rewind_data.dart';
import '../models/rewind_period.dart';
import '../models/rewind_story.dart';

class RewindAggregationService {
  static final DateFormat _dayKeyFormat = DateFormat('yyyy-MM-dd');

  /// Aggregate all metrics for a given period from the user's transaction list
  static RewindData aggregate({
    required List<TransactionModel> allTransactions,
    required RewindPeriod period,
    int? currentStreak,
  }) {
    final start = period.startDateTime;
    final end = period.endDateTime;
    final prevStart = period.previousStartDateTime;
    final prevEnd = period.previousEndDateTime;

    // Filter transactions in current period
    final currentTxs = allTransactions.where((tx) {
      return tx.createdAt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          tx.createdAt.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();

    // Filter transactions in previous period
    final prevTxs = allTransactions.where((tx) {
      return tx.createdAt.isAfter(prevStart.subtract(const Duration(milliseconds: 1))) &&
          tx.createdAt.isBefore(prevEnd.add(const Duration(milliseconds: 1)));
    }).toList();

    // Current period calculations
    double totalExpense = 0;
    double totalIncome = 0;
    int expenseCount = 0;
    int incomeCount = 0;

    final Map<String, _CategoryAccumulator> categoryMap = {};
    final Map<String, _DayAccumulator> dayMap = {};
    final Set<String> activeDateKeys = {};
    final List<TransactionModel> moments = [];

    for (final tx in currentTxs) {
      final dateKey = _dayKeyFormat.format(tx.createdAt);
      activeDateKeys.add(dateKey);

      if (tx.type == 'expense') {
        totalExpense += tx.amount;
        expenseCount++;

        // Accumulate category
        final catKey = tx.category.trim().isEmpty ? 'Khác' : tx.category.trim();
        final acc = categoryMap.putIfAbsent(
          catKey,
          () => _CategoryAccumulator(
            name: catKey,
            iconCodePoint: tx.categoryIconCodePoint,
            colorHex: tx.categoryColorHex,
          ),
        );
        acc.amount += tx.amount;
        acc.count++;

        // Accumulate day spending
        final dayAcc = dayMap.putIfAbsent(
          dateKey,
          () => _DayAccumulator(date: DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day)),
        );
        dayAcc.amount += tx.amount;
        dayAcc.count++;
      } else if (tx.type == 'income') {
        totalIncome += tx.amount;
        incomeCount++;
      }

      if (tx.displayImageUrl.isNotEmpty) {
        moments.add(tx);
      }
    }

    // Previous period calculations
    double prevTotalExpense = 0;
    double prevTotalIncome = 0;
    for (final tx in prevTxs) {
      if (tx.type == 'expense') {
        prevTotalExpense += tx.amount;
      } else if (tx.type == 'income') {
        prevTotalIncome += tx.amount;
      }
    }

    double? expenseChangePercent;
    if (prevTotalExpense > 0) {
      expenseChangePercent = ((totalExpense - prevTotalExpense) / prevTotalExpense) * 100;
    }

    // Categories list sorted by amount descending
    final categories = categoryMap.values.map((acc) {
      final percentage = totalExpense > 0 ? (acc.amount / totalExpense) * 100 : 0.0;
      return RewindCategoryItem(
        name: acc.name,
        amount: acc.amount,
        percentage: percentage,
        iconCodePoint: acc.iconCodePoint,
        colorHex: acc.colorHex,
        count: acc.count,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Top 5 expenses
    final topExpenses = currentTxs
        .where((tx) => tx.type == 'expense')
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top5 = topExpenses.take(5).toList();

    // Biggest Day
    RewindBiggestDay? biggestDay;
    if (dayMap.isNotEmpty) {
      final sortedDays = dayMap.values.toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
      final topDay = sortedDays.first;

      // Build daily spendings timeline
      final dailyList = dayMap.values
          .map((d) => RewindDaySpending(date: d.date, amount: d.amount, count: d.count))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      biggestDay = RewindBiggestDay(
        date: topDay.date,
        amount: topDay.amount,
        transactionCount: topDay.count,
        dailySpendings: dailyList,
      );
    }

    // Moments: limit to 8 items, prioritizing transactions with images and higher amounts
    moments.sort((a, b) {
      if (a.isImage && !b.isImage) return -1;
      if (!a.isImage && b.isImage) return 1;
      return b.amount.compareTo(a.amount);
    });
    final limitedMoments = moments.take(8).toList();

    // Streak calculation
    int calculatedStreak = currentStreak ?? 0;
    if (calculatedStreak == 0 && activeDateKeys.isNotEmpty) {
      calculatedStreak = activeDateKeys.length;
    }

    // Highlight generation
    RewindHighlight? highlight;
    if (categories.isNotEmpty && categories.first.percentage >= 30) {
      final topCat = categories.first;
      highlight = RewindHighlight(
        type: RewindHighlightType.dominantCategory,
        emoji: '🎯',
        categoryName: topCat.name,
        percentStr: topCat.percentage.toStringAsFixed(0),
      );
    } else if (biggestDay != null && totalExpense > 0 && (biggestDay.amount / totalExpense) >= 0.35) {
      final pct = (biggestDay.amount / totalExpense) * 100;
      final dateStr = DateFormat('dd/MM').format(biggestDay.date);
      highlight = RewindHighlight(
        type: RewindHighlightType.peakDay,
        emoji: '⚡',
        dateStr: dateStr,
        percentStr: pct.toStringAsFixed(0),
      );
    } else if (top5.isNotEmpty) {
      highlight = RewindHighlight(
        type: RewindHighlightType.biggestExpense,
        emoji: '💸',
        categoryName: top5.first.category.isNotEmpty ? top5.first.category : "Khác",
      );
    }

    return RewindData(
      period: period,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      balance: totalIncome - totalExpense,
      totalTransactions: currentTxs.length,
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      prevTotalExpense: prevTotalExpense,
      prevTotalIncome: prevTotalIncome,
      prevTotalTransactions: prevTxs.length,
      expenseChangePercent: expenseChangePercent,
      transactionChangeDiff: currentTxs.length - prevTxs.length,
      categories: categories,
      streakDays: calculatedStreak,
      activeDateKeys: activeDateKeys,
      topExpenses: top5,
      biggestDay: biggestDay,
      momentTransactions: limitedMoments,
      highlight: highlight,
    );
  }

  /// Build a dynamic list of stories tailored specifically to the user's data
  static List<RewindStory> buildStories(RewindData data) {
    if (!data.hasTransactions) {
      return [
        const RewindStory(
          id: 'empty',
          type: RewindStoryType.empty,
          duration: Duration(milliseconds: 6000),
          backgroundGradient: RewindStory.defaultGradient,
        ),
      ];
    }

    final stories = <RewindStory>[];

    // 1. Overview Story
    stories.add(
      const RewindStory(
        id: 'overview',
        type: RewindStoryType.overview,
        duration: Duration(milliseconds: 5500),
        backgroundGradient: RewindStory.overviewGradient,
      ),
    );

    // 2. Categories Breakdown Story
    if (data.categories.isNotEmpty) {
      stories.add(
        const RewindStory(
          id: 'categories',
          type: RewindStoryType.categories,
          duration: Duration(milliseconds: 5500),
          backgroundGradient: RewindStory.categoryGradient,
        ),
      );
    }

    // 3. Streak Story
    stories.add(
      const RewindStory(
        id: 'streak',
        type: RewindStoryType.streak,
        duration: Duration(milliseconds: 5000),
        backgroundGradient: RewindStory.streakGradient,
      ),
    );

    // 4. Top Spending Story
    if (data.topExpenses.isNotEmpty) {
      stories.add(
        const RewindStory(
          id: 'topExpenses',
          type: RewindStoryType.topExpenses,
          duration: Duration(milliseconds: 5500),
          backgroundGradient: RewindStory.topExpensesGradient,
        ),
      );
    }

    // 5. Biggest Spending Day Story
    if (data.biggestDay != null && data.biggestDay!.amount > 0) {
      stories.add(
        const RewindStory(
          id: 'biggestDay',
          type: RewindStoryType.biggestDay,
          duration: Duration(milliseconds: 5500),
          backgroundGradient: RewindStory.biggestDayGradient,
        ),
      );
    }

    // 6. Moments Story (Polaroid floating signature feature)
    // ONLY included when there are real moments/photos!
    if (data.hasMoments) {
      stories.add(
        const RewindStory(
          id: 'moments',
          type: RewindStoryType.moments,
          duration: Duration(milliseconds: 6500),
          backgroundGradient: RewindStory.momentsGradient,
        ),
      );
    }

    // 7. Highlight Story
    if (data.highlight != null) {
      stories.add(
        const RewindStory(
          id: 'highlight',
          type: RewindStoryType.highlight,
          duration: Duration(milliseconds: 5000),
          backgroundGradient: RewindStory.highlightGradient,
        ),
      );
    }

    // 8. Comparison Story (only if previous period data exists)
    if (data.hasPreviousComparison) {
      stories.add(
        const RewindStory(
          id: 'comparison',
          type: RewindStoryType.comparison,
          duration: Duration(milliseconds: 5500),
          backgroundGradient: RewindStory.comparisonGradient,
        ),
      );
    }

    // 9. Final Recap & Shareable Memory Card
    stories.add(
      const RewindStory(
        id: 'summary',
        type: RewindStoryType.summary,
        duration: Duration(milliseconds: 7000),
        backgroundGradient: RewindStory.summaryGradient,
      ),
    );

    return stories;
  }
}

class _CategoryAccumulator {
  final String name;
  final int? iconCodePoint;
  final String? colorHex;
  double amount = 0;
  int count = 0;

  _CategoryAccumulator({
    required this.name,
    this.iconCodePoint,
    this.colorHex,
  });
}

class _DayAccumulator {
  final DateTime date;
  double amount = 0;
  int count = 0;

  _DayAccumulator({required this.date});
}
