import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../data/models/transaction_model.dart';
import '../../../features/capture/widgets/transaction_moment_image.dart';
import '../controllers/home_controller.dart';
import '../screens/moment_viewer_screen.dart';

class RecentTransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const RecentTransactionCard({
    super.key,
    required this.transaction,
  });

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatAmount(BuildContext context, double value) {
    final currency = context.watch<ProfileController>().currency;

    return AppCurrencyFormatter.formatFromVnd(
      amountVnd: value,
      currency: currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = transaction.type == 'expense'
        ? AppColors.expense
        : AppColors.income;

    final title = transaction.caption.trim().isEmpty
        ? transaction.category
        : transaction.caption.trim();

    final sign = transaction.type == 'expense' ? '-' : '+';

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(
            color: AppColors.border(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                AppColors.isDark(context) ? 0.14 : 0.035,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          onTap: () {
            final home = context.read<HomeController>();

            final sameDayTransactions = home.transactions
                .where((tx) => _sameDate(tx.createdAt, transaction.createdAt))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final initialIndex = sameDayTransactions.indexWhere(
                  (tx) => tx.id == transaction.id,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MomentViewerScreen(
                  transactions: sameDayTransactions.isEmpty
                      ? [transaction]
                      : sameDayTransactions,
                  initialIndex: initialIndex < 0 ? 0 : initialIndex,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                TransactionMomentImage(
                  imageUrl: transaction.displayImageUrl,
                  category: transaction.category,
                  categoryIconCodePoint: transaction.categoryIconCodePoint,
                  categoryColorHex: transaction.categoryColorHex,
                  caption: null,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(16),
                  isVideo: transaction.isVideo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle(context).copyWith(
                          fontSize: 15.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusPill,
                                ),
                                border: Border.all(
                                  color: AppColors.innerBorder(context),
                                ),
                              ),
                              child: Text(
                                transaction.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _formatTime(transaction.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: AppTextStyles.caption(context).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 74,
                    maxWidth: 116,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign${_formatAmount(context, transaction.amount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary(context).withOpacity(0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday =
        now.year == dateTime.year &&
            now.month == dateTime.month &&
            now.day == dateTime.day;

    if (isToday) {
      return DateFormat('HH:mm').format(dateTime);
    }

    return DateFormat('dd/MM • HH:mm').format(dateTime);
  }
}