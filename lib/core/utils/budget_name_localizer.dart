import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../extensions/localization_extension.dart';
import '../../features/budget/controllers/budget_controller.dart';
import '../../features/profile/controllers/user_category_controller.dart';

class BudgetNameLocalizer {
  const BudgetNameLocalizer._();

  // Thin display wrapper:
  // 1) default categories -> l10n
  // 2) personal budget -> translated nameEn from data
  static String display(
    BuildContext context,
    String rawName, {
    String? budgetNameEn,
  }) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return rawName;

    final l10n = context.l10n;

    if (Localizations.localeOf(context).languageCode != 'en') {
      switch (trimmed) {
        case 'Ăn uống':
        case 'Food':
          return l10n.food;
        case 'Mua sắm':
        case 'Shopping':
          return l10n.shopping;
        case 'Đi lại':
        case 'Di chuyển':
        case 'Transport':
          return l10n.transport;
        case 'Giải trí':
        case 'Entertainment':
          return l10n.entertainment;
        case 'Học tập':
        case 'Giáo dục':
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
        case 'Quỹ nhóm':
        case 'Group Fund':
          return l10n.groupFundCategory;
      }

      BudgetController? budgetControllerNonEn;
      try {
        budgetControllerNonEn = Provider.of<BudgetController>(
          context,
          listen: true,
        );
      } catch (_) {
        budgetControllerNonEn = null;
      }
      final budgetMatch = budgetControllerNonEn?.findBudgetByName(trimmed);
      if (budgetMatch != null) {
        return budgetMatch.name.trim();
      }

      UserCategoryController? userCatControllerNonEn;
      try {
        userCatControllerNonEn = Provider.of<UserCategoryController>(
          context,
          listen: true,
        );
      } catch (_) {
        userCatControllerNonEn = null;
      }
      final userCatMatch = userCatControllerNonEn?.findByName(trimmed);
      if (userCatMatch != null) {
        return userCatMatch.name.trim();
      }

      return trimmed;
    }

    switch (trimmed) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Mua sắm':
      case 'Shopping':
        return l10n.shopping;
      case 'Đi lại':
      case 'Di chuyển':
      case 'Transport':
        return l10n.transport;
      case 'Giải trí':
      case 'Entertainment':
        return l10n.entertainment;
      case 'Học tập':
      case 'Giáo dục':
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
      case 'Quỹ nhóm':
      case 'Group Fund':
        return l10n.groupFundCategory;
    }

    final translatedFromArg = budgetNameEn?.trim();
    if (translatedFromArg != null && translatedFromArg.isNotEmpty) {
      return translatedFromArg;
    }

    BudgetController? budgetController;
    try {
      budgetController = Provider.of<BudgetController>(
        context,
        listen: false,
      );
    } catch (_) {
      budgetController = null;
    }
    final budget = budgetController?.findBudgetByName(trimmed);
    final translatedFromBudget = budget?.nameEn?.trim();
    if (translatedFromBudget != null && translatedFromBudget.isNotEmpty) {
      return translatedFromBudget;
    }

    UserCategoryController? userCategoryController;
    try {
      userCategoryController = Provider.of<UserCategoryController>(
        context,
        listen: true,
      );
    } catch (_) {
      userCategoryController = null;
    }
    final userCat = userCategoryController?.findByName(trimmed);
    final translatedFromUserCat = userCat?.nameEn?.trim();
    if (translatedFromUserCat != null && translatedFromUserCat.isNotEmpty) {
      return translatedFromUserCat;
    }

    return trimmed;
  }
}
