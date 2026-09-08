import 'dart:async';
import 'package:flutter/material.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

class StatsController extends ChangeNotifier {
  final TransactionRepository transactionRepository;

  StatsController({
    required this.transactionRepository,
  });

  List<TransactionModel> transactions = [];
  StreamSubscription? _sub;

  bool isLoading = false;
  String? errorMessage;

  void load(String uid) {
    _sub?.cancel();

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _sub = transactionRepository.streamTransactions(uid).listen(
          (data) {
        transactions = data;

        transactions.sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
        );

        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        isLoading = false;
        errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  bool _isPersonalExpense(TransactionModel e) {
    return (e.type == 'expense' && !e.isGroupExpense) || e.isGroupContribution;
  }

  bool _isPersonalIncome(TransactionModel e) {
    return e.type == 'income' && !e.isGroupContribution;
  }

  double get monthlyIncome {
    final now = DateTime.now();

    return transactions
        .where((e) {
      return _isPersonalIncome(e) &&
          e.createdAt.month == now.month &&
          e.createdAt.year == now.year;
    })
        .fold<double>(
      0,
          (sum, e) => sum + e.amount,
    );
  }

  double get monthlyExpense {
    final now = DateTime.now();

    return transactions
        .where((e) {
      return _isPersonalExpense(e) &&
          e.createdAt.month == now.month &&
          e.createdAt.year == now.year;
    })
        .fold<double>(
      0,
          (sum, e) => sum + e.amount,
    );
  }

  Map<String, double> get expenseByCategory {
    final result = <String, double>{};

    for (final tx in transactions.where(_isPersonalExpense)) {
      final cat = tx.isGroupContribution
          ? (tx.category.isNotEmpty ? tx.category : 'Quỹ nhóm')
          : tx.category;
      result[cat] = (result[cat] ?? 0) + tx.amount;
    }

    return result;
  }

  Map<String, double> get incomeByCategory {
    final result = <String, double>{};

    for (final tx in transactions.where(_isPersonalIncome)) {
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }

    return result;
  }

  double get totalIncome {
    return transactions
        .where(_isPersonalIncome)
        .fold<double>(
      0,
          (sum, e) => sum + e.amount,
    );
  }

  double get totalExpense {
    return transactions
        .where(_isPersonalExpense)
        .fold<double>(
      0,
          (sum, e) => sum + e.amount,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}