import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/stats_controller.dart';
import '../../../data/models/transaction_model.dart';
import 'category_detail_screen.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../profile/controllers/profile_controller.dart';
import '../widgets/transaction_map_panel.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';

enum _MoneyType {
  expense,
  income,
}

enum _ViewMode {
  month,
  year,
}

enum _StatsContentTab {
  category,
  map,
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool loaded = false;
  bool mapInteractionEnabled = false;

  _MoneyType selectedType = _MoneyType.expense;
  _ViewMode selectedViewMode = _ViewMode.month;
  DateTime selectedDate = DateTime.now();
  _StatsContentTab selectedContentTab = _StatsContentTab.category;

  final List<Color> pieColors = const [
    Color(0xFFFF7A7A),
    Color(0xFF7DDC86),
    Color(0xFF79AFFF),
    Color(0xFFFFC857),
    Color(0xFFB68CFF),
    Color(0xFF59D4C8),
    Color(0xFFFF8FD8),
    Color(0xFFFFA45B),
  ];

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

  bool _isSameMonth(DateTime date, DateTime selected) {
    return date.year == selected.year && date.month == selected.month;
  }

  bool _isSameYear(DateTime date, DateTime selected) {
    return date.year == selected.year;
  }

  DateTime _previousPeriod(DateTime date) {
    if (selectedViewMode == _ViewMode.month) {
      return DateTime(date.year, date.month - 1);
    }

    return DateTime(date.year - 1);
  }

  DateTime _nextPeriod(DateTime date) {
    if (selectedViewMode == _ViewMode.month) {
      return DateTime(date.year, date.month + 1);
    }

    return DateTime(date.year + 1);
  }

  DateTime _backPeriod(DateTime date) {
    if (selectedViewMode == _ViewMode.month) {
      return DateTime(date.year, date.month - 1);
    }

    return DateTime(date.year - 1);
  }

  List<dynamic> _filterTransactions(
      List<dynamic> transactions,
      DateTime date,
      ) {
    return transactions.where((tx) {
      final samePeriod = selectedViewMode == _ViewMode.month
          ? _isSameMonth(tx.createdAt, date)
          : _isSameYear(tx.createdAt, date);

      return samePeriod && tx.type == selectedType.name;
    }).toList();
  }

  List<dynamic> _filterTransactionsByType(
      List<dynamic> transactions,
      DateTime date,
      _MoneyType type,
      ) {
    return transactions.where((tx) {
      final samePeriod = selectedViewMode == _ViewMode.month
          ? _isSameMonth(tx.createdAt, date)
          : _isSameYear(tx.createdAt, date);

      return samePeriod && tx.type == type.name;
    }).toList();
  }

  double _getTotal(List<dynamic> transactions) {
    return transactions.fold<double>(
      0,
          (sum, tx) => sum + tx.amount,
    );
  }

  Map<String, double> _groupByCategory(List<dynamic> transactions) {
    final result = <String, double>{};

    for (final tx in transactions) {
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }

    return result;
  }

  Color? _parseColorHex(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    var cleaned = value.trim().replaceAll('#', '');

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) return null;

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return null;
    }
  }

  Color _fallbackCategoryColor(String category, int index) {
    final defaultColor = _defaultCategoryColor(category);

    if (defaultColor != null) {
      return defaultColor;
    }

    return pieColors[index % pieColors.length];
  }

  Color? _defaultCategoryColor(String category) {
    switch (category) {
      case 'Ăn uống':
      case 'Food':
        return AppColors.income;
      case 'Mua sắm':
      case 'Shopping':
        return AppColors.primaryPink;
      case 'Đi lại':
      case 'Transport':
        return AppColors.primaryBlue;
      case 'Giải trí':
      case 'Entertainment':
        return AppColors.warning;
      case 'Học tập':
      case 'Education':
        return AppColors.primaryPurple;
      case 'Lương':
      case 'Salary':
        return AppColors.income;
      case 'Quà tặng':
      case 'Gift':
        return AppColors.expense;
      case 'Khác':
      case 'Other':
        return const Color(0xFFAAAAAA);
      default:
        return null;
    }
  }

  String _localizedCategoryLabel(String category) {
    final l10n = context.l10n;
    switch (category.trim()) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Mua sắm':
      case 'Shopping':
        return l10n.shopping;
      case 'Đi lại':
      case 'Transport':
        return l10n.transport;
      case 'Giải trí':
      case 'Entertainment':
        return l10n.entertainment;
      case 'Học tập':
      case 'Education':
        return l10n.education;
      case 'Lương':
      case 'Salary':
        return l10n.salary;
      case 'Quà tặng':
      case 'Gift':
        return l10n.gift;
      case 'Khác':
      case 'Other':
        return l10n.other;
      default:
        return BudgetNameLocalizer.display(context, category);
    }
  }

  Color _categoryColorFromTransactions({
    required String category,
    required List<dynamic> transactions,
    required int fallbackIndex,
  }) {
    for (final tx in transactions) {
      if (tx is! TransactionModel) continue;
      if (tx.category != category) continue;

      final savedColor = _parseColorHex(tx.categoryColorHex);

      if (savedColor != null) {
        return savedColor;
      }
    }

    return _fallbackCategoryColor(category, fallbackIndex);
  }

  double _getChangePercent(double current, double previous) {
    if (previous == 0 && current == 0) return 0;
    if (previous == 0 && current > 0) return 100;

    return ((current - previous) / previous) * 100;
  }

  String _formatPeriodTitle() {
    if (selectedViewMode == _ViewMode.month) {
      return context.l10n.monthYear(selectedDate.month, selectedDate.year);
    }

    return '${context.l10n.year} ${selectedDate.year}';
  }

  bool _isCurrentPeriod() {
    final now = DateTime.now();

    if (selectedViewMode == _ViewMode.month) {
      return selectedDate.year == now.year && selectedDate.month == now.month;
    }

    return selectedDate.year == now.year;
  }

  void _goToCurrentPeriod() {
    final now = DateTime.now();

    setState(() {
      selectedDate = DateTime(now.year, now.month);
    });
  }

  Future<void> _showPeriodPicker() async {
    if (selectedViewMode == _ViewMode.month) {
      await _showMonthYearPicker();
    } else {
      await _showYearPicker();
    }
  }

  Future<void> _showMonthYearPicker() async {
    final now = DateTime.now();
    int selectedYear = selectedDate.year;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: _StatsPalette.of(context).cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final palette = _StatsPalette.of(context);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: palette.textSecondary.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Text(
                          context.l10n.selectMonthStats,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                              DateTime(now.year, now.month),
                            );
                          },
                          child: Text(context.l10n.current),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.innerTileBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: palette.innerTileBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          _SmallIconButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () {
                              setSheetState(() {
                                selectedYear--;
                              });
                            },
                            palette: palette,
                          ),

                          Expanded(
                            child: Center(
                              child: Text(
                                '$selectedYear',
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),

                          _SmallIconButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: () {
                              setSheetState(() {
                                selectedYear++;
                              });
                            },
                            palette: palette,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.25,
                      ),
                      itemBuilder: (context, index) {
                        final month = index + 1;

                        final isSelected =
                            selectedYear == selectedDate.year &&
                                month == selectedDate.month;

                        final isCurrent =
                            selectedYear == now.year && month == now.month;

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                              DateTime(selectedYear, month),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withOpacity(0.16)
                                  : palette.innerTileBackground,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : isCurrent
                                    ? AppColors.primaryBlue.withOpacity(0.45)
                                    : palette.innerTileBorder,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Text(
                              context.l10n.monthLabel(month),
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : palette.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedDate = DateTime(picked.year, picked.month);
    });
  }

  Future<void> _showYearPicker() async {
    final now = DateTime.now();

    int startYear = selectedDate.year - 5;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: _StatsPalette.of(context).cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final palette = _StatsPalette.of(context);

            final years = List.generate(
              12,
                  (index) => startYear + index,
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: palette.textSecondary.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Text(
                          context.l10n.selectYearStats,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                              DateTime(now.year, now.month),
                            );
                          },
                          child: Text(context.l10n.current),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setSheetState(() {
                                startYear -= 12;
                              });
                            },
                            icon: const Icon(Icons.chevron_left_rounded),
                            label: Text(context.l10n.olderYears),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setSheetState(() {
                                startYear += 12;
                              });
                            },
                            icon: const Icon(Icons.chevron_right_rounded),
                            label: Text(context.l10n.newerYears),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: years.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.3,
                      ),
                      itemBuilder: (context, index) {
                        final year = years[index];

                        final isSelected = year == selectedDate.year;
                        final isCurrent = year == now.year;

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                              DateTime(year, selectedDate.month),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withOpacity(0.16)
                                  : palette.innerTileBackground,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : isCurrent
                                    ? AppColors.primaryBlue.withOpacity(0.45)
                                    : palette.innerTileBorder,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Text(
                              '$year',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : palette.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedDate = DateTime(picked.year, picked.month);
    });
  }

  String _formatCompareTitle() {
    if (selectedViewMode == _ViewMode.month) {
      return context.l10n.compareToPreviousMonth;
    }

    return context.l10n.compareToPreviousYear;
  }

  String _getChartTitle() {
    final isExpense = selectedType == _MoneyType.expense;

    if (selectedViewMode == _ViewMode.month) {
      return isExpense
          ? context.l10n.expenseByCategoryMonth
          : context.l10n.incomeByCategoryMonth;
    }

    return isExpense
        ? context.l10n.expenseByCategoryYear
        : context.l10n.incomeByCategoryYear;
  }

  String _getEmptyChartText() {
    final isExpense = selectedType == _MoneyType.expense;

    if (selectedViewMode == _ViewMode.month) {
      return isExpense
          ? context.l10n.noExpenseDataMonth
          : context.l10n.noIncomeDataMonth;
    }

    return isExpense
        ? context.l10n.noExpenseDataYear
        : context.l10n.noIncomeDataYear;
  }

  String _getAnalysisText(double percent) {
    final isExpense = selectedType == _MoneyType.expense;
    final absPercent = percent.abs().toStringAsFixed(1);

    if (percent == 0) {
      return isExpense
          ? context.l10n.expenseNoChange
          : context.l10n.incomeNoChange;
    }

    if (percent > 0) {
      return isExpense
          ? context.l10n.expenseMore(absPercent)
          : context.l10n.incomeMore(absPercent);
    }

    return isExpense
        ? context.l10n.expenseLess(absPercent)
        : context.l10n.incomeLess(absPercent);
  }

  int _getPercent(
      double value,
      List<MapEntry<String, double>> entries,
      ) {
    final total = entries.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) return 0;
    return ((value / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsController>();
    final currency = context.watch<ProfileController>().currency;
    final palette = _StatsPalette.of(context);

    String money(double value) {
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: value,
        currency: currency,
      );
    }

    String moneyCompactTop(double value) {
      return AppCurrencyFormatter.truncateFormattedMoneyDigits(
        money(value),
        7,
      );
    }

    final currentTransactions = _filterTransactions(
      stats.transactions,
      selectedDate,
    );

    final previousTransactions = _filterTransactions(
      stats.transactions,
      _previousPeriod(selectedDate),
    );

    final currentTotal = _getTotal(currentTransactions);
    final previousTotal = _getTotal(previousTransactions);
    final changePercent = _getChangePercent(currentTotal, previousTotal);

    final incomeTotal = _getTotal(
      _filterTransactionsByType(
        stats.transactions,
        selectedDate,
        _MoneyType.income,
      ),
    );

    final expenseTotal = _getTotal(
      _filterTransactionsByType(
        stats.transactions,
        selectedDate,
        _MoneyType.expense,
      ),
    );

    final categoryEntries = _groupByCategory(currentTransactions)
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoryColorMap = <String, Color>{};

    for (int i = 0; i < categoryEntries.length; i++) {
      final category = categoryEntries[i].key;

      categoryColorMap[category] = _categoryColorFromTransactions(
        category: category,
        transactions: currentTransactions,
        fallbackIndex: i,
      );
    }

    final isExpense = selectedType == _MoneyType.expense;

    final mainColor = isExpense ? AppColors.expense : AppColors.income;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: stats.isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: palette.textPrimary,
          ),
        )
            : ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 190),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  _TopCircleButton(
                    icon: Icons.bar_chart_rounded,
                    palette: palette,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.l10n.statsTitle,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _MoneyTypeSelector(
              selectedType: selectedType,
              incomeAmount: moneyCompactTop(incomeTotal),
              expenseAmount: moneyCompactTop(expenseTotal),
              onChanged: (type) {
                setState(() {
                  selectedType = type;
                });
              },
              palette: palette,
            ),

            const SizedBox(height: 14),

            _RowSegment(
              selectedIndex:
              selectedViewMode == _ViewMode.month ? 0 : 1,
              labels: [context.l10n.month, context.l10n.year],
              onChanged: (index) {
                setState(() {
                  selectedViewMode =
                  index == 0 ? _ViewMode.month : _ViewMode.year;

                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                  );
                });
              },
              palette: palette,
            ),

            const SizedBox(height: 12),

            _PeriodSelector(
              title: _formatPeriodTitle(),
              palette: palette,
              showCurrentButton: !_isCurrentPeriod(),
              currentButtonText: selectedViewMode == _ViewMode.month
                  ? context.l10n.backToThisMonth
                  : context.l10n.backToThisYear,
              onTapTitle: _showPeriodPicker,
              onGoCurrent: _goToCurrentPeriod,
              onPrevious: () {
                setState(() {
                  selectedDate = _backPeriod(selectedDate);
                });
              },
              onNext: () {
                setState(() {
                  selectedDate = _nextPeriod(selectedDate);
                });
              },
            ),

            const SizedBox(height: 18),

            _AnalysisCard(
              title: isExpense ? context.l10n.totalExpenseLabel : context.l10n.totalIncomeLabel,
              period: _formatPeriodTitle(),
              amount: money(currentTotal),
              previousAmount: money(previousTotal),
              compareText: _formatCompareTitle(),
              analysisText: _getAnalysisText(changePercent),
              percent: changePercent,
              accent: mainColor,
              icon: isExpense
                  ? Icons.north_east_rounded
                  : Icons.south_west_rounded,
              palette: palette,
              isExpense: isExpense,
            ),

            const SizedBox(height: 18),

            _RowSegment(
              selectedIndex: selectedContentTab.index,
              labels: [context.l10n.categories, context.l10n.map],
              onChanged: (value) {
                setState(() {
                  selectedContentTab = _StatsContentTab.values[value];
                  mapInteractionEnabled = false;
                });
              },
              palette: palette,
            ),

            const SizedBox(height: 18),

            if (selectedContentTab == _StatsContentTab.map)
              _SafeMapPanel(
                palette: palette,
                interactionEnabled: mapInteractionEnabled,
                onToggleInteraction: () {
                  setState(() {
                    mapInteractionEnabled = !mapInteractionEnabled;
                  });
                },
                transactions: currentTransactions
                    .whereType<TransactionModel>()
                    .toList(),
              )
            else Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: palette.cardBackground,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: palette.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.045,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getChartTitle(),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: mainColor.withOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          _formatPeriodTitle(),
                          style: TextStyle(
                            color: mainColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (categoryEntries.isEmpty)
                    SizedBox(
                      height: 260,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.innerTileBackground,
                                border: Border.all(color: palette.innerTileBorder),
                              ),
                              child: Icon(
                                Icons.pie_chart_outline_rounded,
                                color: palette.textSecondary,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _getEmptyChartText(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 285,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              centerSpaceRadius: 74,
                              sectionsSpace: 3,
                              startDegreeOffset: -90,
                              borderData: FlBorderData(show: false),
                              pieTouchData: PieTouchData(enabled: true),
                              sections: categoryEntries.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final percent = _getPercent(item.value, categoryEntries);
                                final color = categoryColorMap[item.key] ??
                                    _fallbackCategoryColor(item.key, index);

                                return PieChartSectionData(
                                  value: item.value,
                                  color: color,
                                  radius: 42,
                                  title: percent >= 8 ? '$percent%' : '',
                                  titlePositionPercentageOffset: 0.58,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          _ChartCenterInfo(
                            title: isExpense ? context.l10n.totalExpenseLabel : context.l10n.totalIncomeLabel,
                            amount: money(currentTotal),
                            accent: mainColor,
                            palette: palette,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Column(
                      children: categoryEntries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final percent = _getPercent(item.value, categoryEntries);

                        final color = categoryColorMap[item.key] ??
                            _fallbackCategoryColor(item.key, index);

                        return _ChartLegendTile(
                          color: color,
                          title: _localizedCategoryLabel(item.key),
                          percent: percent,
                          amount: money(item.value),
                          palette: palette,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (selectedContentTab != _StatsContentTab.map &&
                categoryEntries.isNotEmpty) ...[
              Text(
                isExpense ? context.l10n.expenseDetails : context.l10n.incomeDetails,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (selectedContentTab != _StatsContentTab.map)
              ...categoryEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final percent = _getPercent(item.value, categoryEntries);

                final categoryTransactions = currentTransactions
                    .where((tx) => tx.category == item.key)
                    .cast<TransactionModel>()
                    .toList();

                final color = categoryColorMap[item.key] ??
                    _fallbackCategoryColor(item.key, index);

                return _DetailCategoryTile(
                  color: color,
                  title: _localizedCategoryLabel(item.key),
                  subtitle: isExpense 
                      ? context.l10n.percentOfTotalExpense(percent)
                      : context.l10n.percentOfTotalIncome(percent),
                  value: money(item.value),
                  palette: palette,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(
                          category: item.key,
                          type: selectedType.name,
                          periodTitle: _formatPeriodTitle(),
                          transactions: categoryTransactions,
                        ),
                      ),
                    );
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SafeMapPanel extends StatelessWidget {
  final _StatsPalette palette;
  final bool interactionEnabled;
  final VoidCallback onToggleInteraction;
  final List<TransactionModel> transactions;

  const _SafeMapPanel({
    required this.palette,
    required this.interactionEnabled,
    required this.onToggleInteraction,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = (screenHeight * 0.44).clamp(310.0, 420.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: palette.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.045,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.map_rounded,
                color: palette.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.transactionMap,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggleInteraction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: interactionEnabled
                        ? AppColors.primaryBlue.withOpacity(0.14)
                        : palette.innerTileBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: interactionEnabled
                          ? AppColors.primaryBlue.withOpacity(0.28)
                          : palette.innerTileBorder,
                    ),
                  ),
                  child: Text(
                    interactionEnabled ? context.l10n.controlling : context.l10n.mapControl,
                    style: TextStyle(
                      color: interactionEnabled
                          ? AppColors.primaryBlue
                          : palette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: mapHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !interactionEnabled,
                      child: TransactionMapPanel(
                        transactions: transactions,
                      ),
                    ),
                  ),

                  if (!interactionEnabled)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: onToggleInteraction,
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.42),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.touch_app_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  context.l10n.tapToControlMap,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            interactionEnabled
                ? context.l10n.tapControllingToDisable
                : context.l10n.recentTransactionsOverview,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCenterInfo extends StatelessWidget {
  final String title;
  final String amount;
  final Color accent;
  final _StatsPalette palette;

  const _ChartCenterInfo({
    required this.title,
    required this.amount,
    required this.accent,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.cardBackground,
        border: Border.all(
          color: accent.withOpacity(0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegendTile extends StatelessWidget {
  final Color color;
  final String title;
  final int percent;
  final String amount;
  final _StatsPalette palette;

  const _ChartLegendTile({
    required this.color,
    required this.title,
    required this.percent,
    required this.amount,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.innerTileBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.innerTileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyTypeSelector extends StatelessWidget {
  final _MoneyType selectedType;
  final String incomeAmount;
  final String expenseAmount;
  final ValueChanged<_MoneyType> onChanged;
  final _StatsPalette palette;

  const _MoneyTypeSelector({
    required this.selectedType,
    required this.incomeAmount,
    required this.expenseAmount,
    required this.onChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MoneyTypeCard(
            title: context.l10n.income,
            amount: incomeAmount,
            icon: Icons.south_west_rounded,
            accent: const Color(0xFF7DDC86),
            selected: selectedType == _MoneyType.income,
            onTap: () => onChanged(_MoneyType.income),
            palette: palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MoneyTypeCard(
            title: context.l10n.expense,
            amount: expenseAmount,
            icon: Icons.north_east_rounded,
            accent: const Color(0xFFFF7A7A),
            selected: selectedType == _MoneyType.expense,
            onTap: () => onChanged(_MoneyType.expense),
            palette: palette,
          ),
        ),
      ],
    );
  }
}

class _MoneyTypeCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final _StatsPalette palette;

  const _MoneyTypeCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? accent.withOpacity(0.08) : palette.cardBackground,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: selected ? accent.withOpacity(0.68) : palette.cardBorder,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: accent.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent : accent.withOpacity(0.14),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? accent : palette.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? accent : palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final String period;
  final String amount;
  final String previousAmount;
  final String compareText;
  final String analysisText;
  final double percent;
  final Color accent;
  final IconData icon;
  final _StatsPalette palette;
  final bool isExpense;

  const _AnalysisCard({
    required this.title,
    required this.period,
    required this.amount,
    required this.previousAmount,
    required this.compareText,
    required this.analysisText,
    required this.percent,
    required this.accent,
    required this.icon,
    required this.palette,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = percent > 0;
    final percentText = '${percent.abs().toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.15),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$title - $period',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: accent.withOpacity(0.16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: accent,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$percentText $compareText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            analysisText,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.previousPeriodAmount(previousAmount),
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTapTitle;
  final VoidCallback onGoCurrent;
  final bool showCurrentButton;
  final String currentButtonText;
  final _StatsPalette palette;

  const _PeriodSelector({
    required this.title,
    required this.onPrevious,
    required this.onNext,
    required this.onTapTitle,
    required this.onGoCurrent,
    required this.showCurrentButton,
    required this.currentButtonText,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Row(
            children: [
              _SmallIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrevious,
                palette: palette,
              ),

              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTapTitle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: palette.textSecondary,
                          size: 21,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _SmallIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
                palette: palette,
              ),
            ],
          ),
        ),

        if (showCurrentButton) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              onTap: onGoCurrent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.today_rounded,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentButtonText,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final _StatsPalette palette;

  const _SmallIconButton({
    required this.icon,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: palette.innerTileBackground,
          shape: BoxShape.circle,
          border: Border.all(color: palette.innerTileBorder),
        ),
        child: Icon(
          icon,
          color: palette.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}

class _RowSegment extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  final _StatsPalette palette;

  const _RowSegment({
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? palette.textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? palette.background : palette.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DetailCategoryTile extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final _StatsPalette palette;
  final VoidCallback? onTap;

  const _DetailCategoryTile({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.palette,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final _StatsPalette palette;

  const _TopCircleButton({
    required this.icon,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.topButtonBg,
        border: Border.all(color: palette.topButtonBorder),
      ),
      child: Icon(
        icon,
        color: palette.textPrimary,
      ),
    );
  }
}

class _StatsPalette {
  final Color background;
  final Color cardBackground;
  final Color cardBorder;
  final Color innerTileBackground;
  final Color innerTileBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color topButtonBg;
  final Color topButtonBorder;

  const _StatsPalette({
    required this.background,
    required this.cardBackground,
    required this.cardBorder,
    required this.innerTileBackground,
    required this.innerTileBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.topButtonBg,
    required this.topButtonBorder,
  });

  factory _StatsPalette.of(BuildContext context) {
    return _StatsPalette(
      background: AppColors.background(context),
      cardBackground: AppColors.card(context),
      cardBorder: AppColors.border(context),
      innerTileBackground: AppColors.surface(context),
      innerTileBorder: AppColors.innerBorder(context),
      textPrimary: AppColors.textPrimary(context),
      textSecondary: AppColors.textSecondary(context),
      topButtonBg: AppColors.card(context),
      topButtonBorder: AppColors.border(context),
    );
  }
}