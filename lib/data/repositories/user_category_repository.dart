import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/budget_translation_service.dart';
import '../../data/models/user_category_model.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import 'budget_repository.dart';

class UserCategoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final TransactionRemoteDataSource _transactions = TransactionRemoteDataSource();

  static const String collectionName = 'user_categories';

  static const Set<String> systemExpenseCanonicalNames =
      BudgetRepository.defaultCategoryNames;

  static const Set<String> systemIncomeCanonicalNames = {
    'Lương',
    'Quà tặng',
    'Khác',
  };

  static bool _isReservedName({
    required String name,
    required String type,
  }) {
    final n = name.trim();
    if (type == 'expense') {
      return systemExpenseCanonicalNames.contains(n);
    }
    return systemIncomeCanonicalNames.contains(n);
  }

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return _db.collection('users').doc(uid).collection(collectionName);
  }

  Stream<List<UserCategoryModel>> streamCategories(String uid) {
    return _col(uid).orderBy('createdAt', descending: false).snapshots().map(
          (snap) =>
              snap.docs.map((d) => UserCategoryModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> createCategory({
    required String uid,
    required String name,
    required String type,
    required int iconCodePoint,
    required String colorHex,
    bool inputLocaleIsEnglish = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('empty_category_name');
    }
    if (trimmed.length > 50) {
      throw ArgumentError('category_name_too_long');
    }

    final t = type.trim() == 'income' ? 'income' : 'expense';

    late final String canonicalName;
    late final String? nameEnValue;

    if (inputLocaleIsEnglish) {
      final vi =
          await BudgetTranslationService.translateEnglishToVietnamese(trimmed);
      canonicalName =
          (vi != null && vi.trim().isNotEmpty) ? vi.trim() : trimmed;
      nameEnValue = BudgetTranslationService.sentenceCase(trimmed);
    } else {
      canonicalName = trimmed;
      nameEnValue =
          await BudgetTranslationService.translateVietnameseToEnglish(trimmed);
    }

    if (_isReservedName(name: canonicalName, type: t)) {
      throw ArgumentError('reserved_category_name');
    }

    final dup =
        await _col(uid).where('name', isEqualTo: canonicalName).limit(1).get();
    if (dup.docs.isNotEmpty) {
      throw ArgumentError('duplicate_category');
    }

    final id = _uuid.v4();
    final doc = UserCategoryModel(
      id: id,
      userId: uid,
      name: canonicalName,
      nameEn: nameEnValue,
      type: t,
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    await _col(uid).doc(id).set(doc.toMap());
  }

  Future<void> deleteCategory({
    required String uid,
    required String categoryId,
  }) async {
    await _col(uid).doc(categoryId).delete();
  }

  Future<void> updateCategory({
    required String uid,
    required String categoryId,
    required String name,
    required String type,
    required int iconCodePoint,
    required String colorHex,
    bool inputLocaleIsEnglish = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('empty_category_name');
    }
    if (trimmed.length > 50) {
      throw ArgumentError('category_name_too_long');
    }

    final t = type.trim() == 'income' ? 'income' : 'expense';

    final docRef = _col(uid).doc(categoryId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw ArgumentError('category_not_found');
    }

    final prevName = (snap.data()?['name'] ?? '').toString().trim();
    final prevNameEn = snap.data()?['nameEn']?.toString();

    late final String canonicalName;
    late final String nameEn;

    if (inputLocaleIsEnglish) {
      final vi =
          await BudgetTranslationService.translateEnglishToVietnamese(trimmed);
      canonicalName =
          (vi != null && vi.trim().isNotEmpty) ? vi.trim() : trimmed;
      nameEn = BudgetTranslationService.sentenceCase(trimmed);
    } else {
      canonicalName = trimmed;
      if (trimmed == prevName) {
        nameEn = prevNameEn?.trim() ?? '';
      } else {
        final translated =
            await BudgetTranslationService.translateVietnameseToEnglish(trimmed);
        nameEn = translated?.trim() ?? '';
      }
    }

    if (_isReservedName(name: canonicalName, type: t)) {
      throw ArgumentError('reserved_category_name');
    }

    final dup =
        await _col(uid).where('name', isEqualTo: canonicalName).limit(10).get();
    for (final d in dup.docs) {
      if (d.id != categoryId) {
        throw ArgumentError('duplicate_category');
      }
    }

    if (prevName.isNotEmpty && prevName != canonicalName) {
      await _transactions.migrateTransactionsCategoryName(
        uid: uid,
        oldName: prevName,
        newName: canonicalName,
      );
    }

    await docRef.update({
      'name': canonicalName,
      'nameEn': nameEn,
      'type': t,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
    });
  }
}
