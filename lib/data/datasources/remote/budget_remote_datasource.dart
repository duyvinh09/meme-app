import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/budget_model.dart';

class BudgetRemoteDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('budgets');
  }

  Future<void> createBudget(String uid, BudgetModel budget) async {
    await _collection(uid).doc(budget.id).set(budget.toMap());
  }

  Stream<List<BudgetModel>> streamBudgets(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.id, doc.data()))
          .where((budget) => budget.isDefault == false)
          .toList();
    });
  }
}