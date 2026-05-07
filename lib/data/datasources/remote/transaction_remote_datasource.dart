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
}