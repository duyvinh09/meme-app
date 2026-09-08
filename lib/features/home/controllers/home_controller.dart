import 'dart:async';
import 'package:flutter/material.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';

class HomeController extends ChangeNotifier {
  final TransactionRepository transactionRepository;
  final UserRepository userRepository;

  HomeController({
    required this.transactionRepository,
    required this.userRepository,
  });

  UserModel? profile;
  List<TransactionModel> transactions = [];
  bool isLoading = false;

  StreamSubscription<UserModel?>? _profileSub;
  StreamSubscription<List<TransactionModel>>? _txSub;

  double get totalIncome => transactions
      .where((e) => e.type == 'income' && !e.isGroupContribution)
      .fold(0, (sum, e) => sum + e.amount);

  double get totalExpense => transactions
      .where((e) =>
          (e.type == 'expense' && !e.isGroupExpense) || e.isGroupContribution)
      .fold(0, (sum, e) => sum + e.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> load(String uid) async {
    isLoading = true;
    notifyListeners();

    await _profileSub?.cancel();
    await _txSub?.cancel();

    _profileSub = userRepository.streamUserProfile(uid).listen((userData) {
      profile = userData;
      notifyListeners();
    });

    _txSub = transactionRepository.streamTransactions(uid).listen((data) {
      transactions = data;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> refreshProfile(String uid) async {
    profile = await userRepository.getUserProfile(uid);
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _txSub?.cancel();
    super.dispose();
  }
}