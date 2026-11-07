import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../widgets/transaction_map_panel.dart';

class TransactionMapScreen extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<TransactionModel>? allTransactions;
  final DateTime? initialMonth;
  final ValueChanged<DateTime>? onMonthChanged;
  final String? title;

  const TransactionMapScreen({
    super.key,
    required this.transactions,
    this.allTransactions,
    this.initialMonth,
    this.onMonthChanged,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: TransactionMapPanel(
        transactions: transactions,
        allTransactions: allTransactions,
        initialMonth: initialMonth,
        onMonthChanged: onMonthChanged,
        isFullScreen: true,
        title: title,
        onBack: () => Navigator.maybePop(context),
      ),
    );
  }
}
