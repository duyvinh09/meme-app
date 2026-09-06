import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/budget_translation_service.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final TransactionRemoteDataSource _transactions = TransactionRemoteDataSource();

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('budgets');
  }

  static const Set<String> defaultCategoryNames = {
    'Ăn uống',
    'Mua sắm',
    'Đi lại',
    'Giải trí',
    'Học tập',
    'Khác',
  };

  Stream<List<BudgetModel>> streamBudgets(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.id, doc.data()))
          .where((budget) => budget.isDefault == false)
          .toList();

      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return items;
    });
  }

  Future<void> createBudget({
    required String uid,
    String? name,
    String? category,

    int? iconCodePoint,
    String? colorHex,

    required double limitAmount,
    required String budgetType,

    required String period,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryKey,

    /// English UI: user types English — store Vietnamese [name] + English [nameEn].
    bool inputLocaleIsEnglish = false,
  }) async {
    final id = _uuid.v4();
    final safeName = (name ?? category ?? '').trim();

    if (safeName.isEmpty) {
      throw Exception('Tên chủ đề không được để trống');
    }

    if (limitAmount <= 0) {
      throw Exception('Số tiền mục tiêu phải lớn hơn 0');
    }

    late final String canonicalName;
    late final String? nameEnValue;

    if (inputLocaleIsEnglish) {
      final vi =
          await BudgetTranslationService.translateEnglishToVietnamese(safeName);
      canonicalName =
          (vi != null && vi.trim().isNotEmpty) ? vi.trim() : safeName;
      nameEnValue = BudgetTranslationService.sentenceCase(safeName);
    } else {
      canonicalName = safeName;
      nameEnValue =
          await BudgetTranslationService.translateVietnameseToEnglish(safeName);
    }

    final existed = await _collection(uid)
        .where('name', isEqualTo: canonicalName)
        .where('isDefault', isEqualTo: false)
        .limit(1)
        .get();

    if (existed.docs.isNotEmpty) {
      throw Exception('Chủ đề này đã tồn tại');
    }

    final budget = BudgetModel(
      id: id,
      userId: uid,
      name: canonicalName,
      nameEn: nameEnValue,
      iconCodePoint:
          iconCodePoint ?? 0xe57f, // Icons.account_balance_wallet_outlined
      colorHex: colorHex ?? '#79AFFF',
      limitAmount: limitAmount,
      spentAmount: 0,
      isDefault: false,
      createdAt: DateTime.now(),
      period: period,
      budgetType: budgetType,
      startDate: startDate,
      endDate: endDate,
      categoryKey: categoryKey,
    );

    await _collection(uid).doc(id).set(budget.toMap());
  }

  Future<void> ensureEnglishTranslations({
    required String uid,
    required List<BudgetModel> budgets,
  }) async {
    for (final budget in budgets) {
      if (budget.name.trim().isEmpty) continue;
      if ((budget.nameEn ?? '').trim().isNotEmpty) continue;

      final translated = await BudgetTranslationService
          .translateVietnameseToEnglish(budget.name);
      if (translated == null || translated.trim().isEmpty) continue;

      await _collection(uid).doc(budget.id).update({'nameEn': translated});
    }
  }

  Future<void> ensureDefaultBudgets(String uid) async {}

  Future<BudgetModel?> findPersonalBudgetByName({
    required String uid,
    required String name,
  }) async {
    final snapshot = await _collection(uid)
        .where('name', isEqualTo: name.trim())
        .where('isDefault', isEqualTo: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return BudgetModel.fromMap(doc.id, doc.data());
  }

  Future<bool> isPersonalBudgetName({
    required String uid,
    required String name,
  }) async {
    final budget = await findPersonalBudgetByName(
      uid: uid,
      name: name,
    );

    return budget != null;
  }

  Future<bool> willExceedLimit({
    required String uid,
    required String budgetName,
    required double addingAmount,
  }) async {
    final budget = await findPersonalBudgetByName(
      uid: uid,
      name: budgetName,
    );

    if (budget == null) return false;
    if (budget.limitAmount <= 0) return false;

    return budget.spentAmount + addingAmount > budget.limitAmount;
  }

  Future<void> addSpentAmount({
    required String uid,
    required String budgetName,
    required double amount,
  }) async {
    final snapshot = await _collection(uid)
        .where('name', isEqualTo: budgetName.trim())
        .where('isDefault', isEqualTo: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.update({
      'spentAmount': FieldValue.increment(amount),
    });
  }

  Future<void> removeSpentAmount({
    required String uid,
    required String budgetName,
    required double amount,
  }) async {
    final snapshot = await _collection(uid)
        .where('name', isEqualTo: budgetName.trim())
        .where('isDefault', isEqualTo: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final doc = snapshot.docs.first;
    final data = doc.data();

    final current = data['spentAmount'] is num
        ? (data['spentAmount'] as num).toDouble()
        : 0.0;

    await doc.reference.update({
      'spentAmount': (current - amount).clamp(0.0, double.infinity),
    });
  }

  Future<void> deleteBudget({
    required String uid,
    required String budgetId,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(budgetId)
        .delete();
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
    final safeName = name.trim();

    if (safeName.isEmpty) {
      throw Exception('Tên chủ đề không được để trống');
    }

    if (limitAmount <= 0) {
      throw Exception('Số tiền mục tiêu phải lớn hơn 0');
    }

    late final String canonicalName;
    late final String? nameEnValue;

    if (inputLocaleIsEnglish) {
      final vi =
          await BudgetTranslationService.translateEnglishToVietnamese(safeName);
      canonicalName =
          (vi != null && vi.trim().isNotEmpty) ? vi.trim() : safeName;
      nameEnValue = BudgetTranslationService.sentenceCase(safeName);
    } else {
      canonicalName = safeName;
      nameEnValue =
          await BudgetTranslationService.translateVietnameseToEnglish(safeName);
    }

    final existed = await _collection(uid)
        .where('name', isEqualTo: canonicalName)
        .where('isDefault', isEqualTo: false)
        .limit(1)
        .get();

    final hasDuplicate = existed.docs.any((doc) => doc.id != budgetId);
    if (hasDuplicate) {
      throw Exception('Chủ đề này đã tồn tại');
    }

    final budgetRef = _collection(uid).doc(budgetId);
    final existingSnap = await budgetRef.get();
    if (!existingSnap.exists) {
      throw Exception('Không tìm thấy ngân sách');
    }
    final prevName = (existingSnap.data()?['name'] ?? '').toString().trim();

    if (prevName.isNotEmpty && prevName != canonicalName) {
      await _transactions.migrateTransactionsCategoryName(
        uid: uid,
        oldName: prevName,
        newName: canonicalName,
      );
    }

    final updateData = <String, dynamic>{
      'name': canonicalName,
      'nameEn': nameEnValue,
      'limitAmount': limitAmount,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
      'period': period,
      'budgetType': budgetType,
    };
    if (startDate != null) updateData['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) updateData['endDate'] = Timestamp.fromDate(endDate);
    if (categoryKey != null) updateData['categoryKey'] = categoryKey;

    await budgetRef.update(updateData);
  }
}