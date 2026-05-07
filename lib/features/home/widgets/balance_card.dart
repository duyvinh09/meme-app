import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../profile/controllers/profile_controller.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;

    final balanceText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: balance,
      currency: currency,
    );

    final incomeText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: income,
      currency: currency,
    );

    final expenseText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: expense,
      currency: currency,
    );

    final balanceColor = balance < 0
        ? AppColors.expense
        : AppColors.textPrimary(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              AppColors.isDark(context) ? 0.16 : 0.045,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Số dư hiện tại',
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              balanceText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.pageTitle(context).copyWith(
                color: balanceColor,
                fontSize: 30,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'Tổng thu',
                    value: incomeText,
                    valueColor: AppColors.income,
                    icon: Icons.south_west_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    label: 'Tổng chi',
                    value: expenseText,
                    valueColor: AppColors.expense,
                    icon: Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: valueColor.withOpacity(
                AppColors.isDark(context) ? 0.18 : 0.14,
              ),
            ),
            child: Icon(
              icon,
              color: valueColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}