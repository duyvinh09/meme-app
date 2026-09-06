import 'dart:async';
import 'package:flutter/material.dart';

import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../services/budget_cycle_helper.dart';

class BudgetController extends ChangeNotifier {
  final BudgetRepository budgetRepository;
  final TransactionRepository? transactionRepository;

  BudgetController({
    required this.budgetRepository,
    this.transactionRepository,
  });

  List<BudgetModel> _rawBudgets = [];
  List<BudgetModel> budgets = [];
  List<TransactionModel> transactions = [];
  bool isLoading = false;
  String? errorMessage;

  StreamSubscription? _budgetSub;
  StreamSubscription? _txSub;

  void load(String uid) {
    _budgetSub?.cancel();
    _txSub?.cancel();

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _budgetSub = budgetRepository.streamBudgets(uid).listen(
      (data) {
        _rawBudgets = data;
        _recalculateSpending();
        unawaited(
          budgetRepository.ensureEnglishTranslations(uid: uid, budgets: data),
        );
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _rawBudgets = [];
        budgets = [];
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      },
    );

    if (transactionRepository != null) {
      _txSub = transactionRepository!.streamTransactions(uid).listen(
        (txList) {
          transactions = txList;
          _recalculateSpending();
          notifyListeners();
        },
        onError: (_) {
          // Keep transactions as is or empty if error
        },
      );
    }
  }

  void _recalculateSpending() {
    if (transactions.isEmpty) {
      budgets = _rawBudgets.map((b) {
        final spent = BudgetCycleHelper.calculateCycleSpent(b, transactions);
        return b.copyWith(spentAmount: spent);
      }).toList();
      return;
    }

    budgets = _rawBudgets.map((b) {
      final dynamicSpent = BudgetCycleHelper.calculateCycleSpent(b, transactions);
      return b.copyWith(spentAmount: dynamicSpent);
    }).toList();
  }

  Future<void> createBudget({
    required String uid,
    String? name,
    int? iconCodePoint,
    String? colorHex,
    String? category,
    required String period,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryKey,
    required double limitAmount,
    required String budgetType,
    bool inputLocaleIsEnglish = false,
  }) async {
    await budgetRepository.createBudget(
      uid: uid,
      name: name,
      category: category,
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      limitAmount: limitAmount,
      period: period,
      startDate: startDate,
      endDate: endDate,
      categoryKey: categoryKey,
      budgetType: budgetType,
      inputLocaleIsEnglish: inputLocaleIsEnglish,
    );
  }

  Future<void> deleteBudget({
    required String uid,
    required String budgetId,
  }) async {
    await budgetRepository.deleteBudget(
      uid: uid,
      budgetId: budgetId,
    );
  }

  Future<void> updateBudget({
    required String uid,
    required String budgetId,
    required String name,
    required double limitAmount,
    required int iconCodePoint,
    required String colorHex,
    required String period,
    required String budgetType,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryKey,
    bool inputLocaleIsEnglish = false,
  }) async {
    await budgetRepository.updateBudget(
      uid: uid,
      budgetId: budgetId,
      name: name,
      limitAmount: limitAmount,
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      period: period,
      budgetType: budgetType,
      startDate: startDate,
      endDate: endDate,
      categoryKey: categoryKey,
      inputLocaleIsEnglish: inputLocaleIsEnglish,
    );
  }

  bool isDefaultCategory(String name) {
    return BudgetRepository.defaultCategoryNames.contains(name.trim());
  }

  bool isPersonalBudget(String name) {
    return budgets.any((budget) {
      return budget.name.trim().toLowerCase() == name.trim().toLowerCase();
    });
  }

  BudgetModel? findBudgetByName(String name) {
    final normalized = name.trim().toLowerCase();
    try {
      return budgets.firstWhere((budget) {
        final rawName = budget.name.trim().toLowerCase();
        final englishName = (budget.nameEn ?? '').trim().toLowerCase();
        if (rawName == normalized || englishName == normalized) return true;
        return BudgetCycleHelper.canonicalCategory(rawName) ==
            BudgetCycleHelper.canonicalCategory(normalized);
      });
    } catch (_) {
      return null;
    }
  }

  /// Finds the applicable budget for a given expense category.
  /// Priority:
  /// 1. Specific budget matching [category].
  /// 2. Total budget ('total') with total name as fallback.
  BudgetModel? findApplicableBudgetForExpense({required String category}) {
    for (final budget in budgets) {
      if (BudgetCycleHelper.matchesCategory(budget, category)) {
        return budget;
      }
    }

    for (final budget in budgets) {
      if (budget.budgetType == 'total' &&
          BudgetCycleHelper.isTotalBudgetName(budget.name)) {
        return budget;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _budgetSub?.cancel();
    _txSub?.cancel();
    super.dispose();
  }
}