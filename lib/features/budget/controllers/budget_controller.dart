import 'dart:async';
import 'package:flutter/material.dart';

import '../../../data/models/budget_model.dart';
import '../../../data/repositories/budget_repository.dart';

class BudgetController extends ChangeNotifier {
  final BudgetRepository budgetRepository;

  BudgetController({
    required this.budgetRepository,
  });

  List<BudgetModel> budgets = [];
  bool isLoading = false;
  String? errorMessage;

  StreamSubscription? _sub;

  void load(String uid) {
    _sub?.cancel();

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _sub = budgetRepository.streamBudgets(uid).listen(
          (data) {
        budgets = data;
        unawaited(
          budgetRepository.ensureEnglishTranslations(uid: uid, budgets: data),
        );
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        budgets = [];
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      },
    );
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
        return rawName == normalized || englishName == normalized;
      });
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}