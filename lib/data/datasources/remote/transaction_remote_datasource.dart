import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';

class TransactionRemoteDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('transactions');
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _collection(transaction.userId)
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Stream<List<TransactionModel>> streamTransactions(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final transactions = <TransactionModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();

          transactions.add(
            TransactionModel.fromMap({
              ...data,
              'id': data['id'] ?? doc.id,
            }),
          );
        } catch (e, stackTrace) {
          debugPrint('Transaction parse error at doc ${doc.id}: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      return transactions;
    });
  }

  Future<List<TransactionModel>> fetchTransactions(String uid) async {
    final snapshot = await _collection(uid)
        .orderBy('createdAt', descending: true)
        .get();

    final transactions = <TransactionModel>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        transactions.add(
          TransactionModel.fromMap({
            ...data,
            'id': data['id'] ?? doc.id,
          }),
        );
      } catch (e, stackTrace) {
        debugPrint('Transaction fetch parse error at doc ${doc.id}: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return transactions;
  }

  Future<void> deleteTransaction(String uid, String transactionId) async {
    await _collection(uid).doc(transactionId).delete();
  }

  /// Rewrites [category] on all transactions when a budget or user category is renamed.
  /// Call before updating the budget/category document so stored keys stay in sync.
  Future<void> migrateTransactionsCategoryName({
    required String uid,
    required String oldName,
    required String newName,
  }) async {
    final trimmedOld = oldName.trim();
    final trimmedNew = newName.trim();
    if (trimmedOld.isEmpty || trimmedOld == trimmedNew) return;

    final snap = await _collection(uid)
        .where('category', isEqualTo: trimmedOld)
        .get();

    const batchLimit = 450;
    final docs = snap.docs;
    for (var i = 0; i < docs.length; i += batchLimit) {
      final batch = _db.batch();
      for (final doc in docs.skip(i).take(batchLimit)) {
        batch.update(doc.reference, {'category': trimmedNew});
      }
      await batch.commit();
    }
  }
}