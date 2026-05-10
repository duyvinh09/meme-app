import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/user_category_model.dart';
import '../../../data/repositories/user_category_repository.dart';

class UserCategoryController extends ChangeNotifier {
  UserCategoryController({required UserCategoryRepository repository})
      : _repository = repository;

  final UserCategoryRepository _repository;

  List<UserCategoryModel> categories = [];
  StreamSubscription<List<UserCategoryModel>>? _sub;

  void load(String uid) {
    _sub?.cancel();

    categories = [];
    notifyListeners();

    _sub = _repository.streamCategories(uid).listen(
      (list) {
        categories = list;

        notifyListeners();
      },
      onError: (Object e) {
        categories = [];
        notifyListeners();
      },
    );
  }

  Future<void> addCategory({
    required String uid,
    required String name,
    required String type,
    required int iconCodePoint,
    required String colorHex,
    bool inputLocaleIsEnglish = false,
  }) {
    return _repository.createCategory(
      uid: uid,
      name: name,
      type: type,
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      inputLocaleIsEnglish: inputLocaleIsEnglish,
    );
  }

  Future<void> deleteCategory({
    required String uid,
    required String categoryId,
  }) {
    return _repository.deleteCategory(uid: uid, categoryId: categoryId);
  }

  Future<void> updateCategory({
    required String uid,
    required String categoryId,
    required String name,
    required String type,
    required int iconCodePoint,
    required String colorHex,
    bool inputLocaleIsEnglish = false,
  }) {
    return _repository.updateCategory(
      uid: uid,
      categoryId: categoryId,
      name: name,
      type: type,
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      inputLocaleIsEnglish: inputLocaleIsEnglish,
    );
  }

  List<UserCategoryModel> categoriesForExpense() =>
      categories.where((c) => c.isExpense).toList();

  List<UserCategoryModel> categoriesForIncome() =>
      categories.where((c) => !c.isExpense).toList();

  UserCategoryModel? findByName(String rawName) {
    final n = rawName.trim().toLowerCase();
    if (n.isEmpty) return null;
    try {
      return categories.firstWhere(
        (c) =>
            c.name.trim().toLowerCase() == n ||
            ((c.nameEn ?? '').trim().toLowerCase() == n &&
                (c.nameEn ?? '').trim().isNotEmpty),
      );
    } catch (_) {
      return null;
    }
  }

  bool isBuiltInExpenseName(String name) =>
      UserCategoryRepository.systemExpenseCanonicalNames.contains(name.trim());

  bool isBuiltInIncomeName(String name) =>
      UserCategoryRepository.systemIncomeCanonicalNames.contains(name.trim());

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
