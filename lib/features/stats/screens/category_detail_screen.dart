import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../home/screens/moment_viewer_screen.dart';
import '../../profile/controllers/profile_controller.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String category;
  final String type;
  final String periodTitle;
  final List<TransactionModel> transactions;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.type,
    required this.periodTitle,
    required this.transactions,
  });

  Color _categoryColor(String categoryName, String categoryType) {
    if (categoryType == 'income') {
      return AppColors.income;
    }

    switch (categoryName.trim()) {
      case 'Ăn uống':
        return const Color(0xFFFF8A00);
      case 'Mua sắm':
        return const Color(0xFF8B5CF6);
      case 'Đi lại':
        return const Color(0xFF388AF6);
      case 'Giải trí':
        return const Color(0xFFEC4899);
      case 'Học tập':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _categoryIcon(String categoryName, String categoryType) {
    if (categoryType == 'income') {
      return Icons.account_balance_wallet_rounded;
    }

    switch (categoryName.trim()) {
      case 'Ăn uống':
        return Icons.restaurant_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Đi lại':
        return Icons.directions_bus_rounded;
      case 'Giải trí':
        return Icons.movie_rounded;
      case 'Học tập':
        return Icons.menu_book_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _formatMoney(double value, String currency) {
    return AppCurrencyFormatter.formatFromVnd(
      amountVnd: value,
      currency: currency,
    );
  }

  String _formatCompactMoney(TransactionModel tx, String currency) {
    final formatted = AppCurrencyFormatter.formatFromVnd(
      amountVnd: tx.amount,
      currency: currency,
    );
    return '${tx.type == 'expense' ? '-' : '+'}$formatted';
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('HH:mm - dd/MM/yyyy').format(date);
  }

  String _localizedCategoryLabel(BuildContext context, String value) {
    final l10n = context.l10n;
    switch (value.trim()) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Mua sắm':
      case 'Shopping':
        return l10n.shopping;
      case 'Đi lại':
      case 'Transport':
        return l10n.transport;
      case 'Giải trí':
      case 'Entertainment':
        return l10n.entertainment;
      case 'Học tập':
      case 'Education':
        return l10n.education;
      case 'Lương':
      case 'Salary':
        return l10n.salary;
      case 'Quà tặng':
      case 'Gift':
        return l10n.gift;
      case 'Khác':
      case 'Other':
        return l10n.other;
      default:
        return BudgetNameLocalizer.display(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = context.watch<ProfileController>().currency;

    final bgColor = isDark ? const Color(0xFF090A0F) : const Color(0xFFF6F7FB);
    final cardColor = isDark ? const Color(0xFF171821) : Colors.white;
    final tileColor = isDark ? const Color(0xFF1D1E27) : const Color(0xFFF7F9FC);
    final borderColor = isDark ? const Color(0xFF2A2D3B) : const Color(0xFFE3E7F0);
    final primaryText = isDark ? Colors.white : const Color(0xFF14151B);
    final secondaryText = isDark ? const Color(0xFFA3A6B2) : const Color(0xFF74788A);

    final accent = _categoryColor(category, type);
    final icon = _categoryIcon(category, type);

    final total = transactions.fold<double>(
      0,
          (sum, tx) => sum + tx.amount,
    );

    final average = transactions.isEmpty ? 0.0 : total / transactions.length;

    final imageCount = transactions.where((tx) {
      return tx.imageUrl.trim().isNotEmpty;
    }).length;

    final previewTransactions = transactions.take(2).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 34, 18, 28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withValues(alpha: 0.95),
                              accent.withValues(alpha: 0.62),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.24),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _localizedCategoryLabel(context, category),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${l10n.transactionCount(transactions.length)} • $periodTitle',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatMoney(total, currency),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accent,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.card(context),
                        border: Border.all(
                          color: AppColors.border(context),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary(context),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      icon: Icons.format_list_bulleted_rounded,
                      iconColor: const Color(0xFF79AFFF),
                      value: '${transactions.length}',
                      label: l10n.total,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickStatCard(
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFF7DDC86),
                      value: _formatMoney(average, currency),
                      label: l10n.average,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickStatCard(
                      icon: Icons.camera_alt_rounded,
                      iconColor: const Color(0xFFFF7A7A),
                      value: '$imageCount',
                      label: l10n.allPhotos,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _SectionCard(
              title: l10n.allPhotos,
              icon: Icons.photo_library_outlined,
              actionText: transactions.length > 2 ? 'See all' : null,
              cardColor: cardColor,
              borderColor: borderColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
              accent: const Color(0xFF79AFFF),
              child: previewTransactions.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Center(
                  child: Text(
                    l10n.noPhotosInFeed,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  : Row(
                children: previewTransactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 0 && previewTransactions.length > 1 ? 10 : 0,
                        left: index == 1 ? 10 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MomentViewerScreen(
                                transactions: transactions,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: _ImagePreviewCard(
                          transaction: tx,
                          amountText: _formatCompactMoney(tx, currency),
                          categoryText: _localizedCategoryLabel(
                            context,
                            tx.category,
                          ),
                          cardColor: tileColor,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            _SectionCard(
              title: l10n.recentTransactions,
              icon: Icons.list_alt_rounded,
              cardColor: cardColor,
              borderColor: borderColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
              accent: const Color(0xFF79AFFF),
              child: Column(
                children: transactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value;

                  return _TransactionRow(
                    transaction: tx,
                    icon: icon,
                    accent: accent,
                    amountText: _formatCompactMoney(tx, currency),
                    categoryText: _localizedCategoryLabel(context, tx.category),
                    timeText: _formatDateTime(tx.createdAt),
                    cardColor: tileColor,
                    borderColor: borderColor,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MomentViewerScreen(
                            transactions: transactions,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color cardColor;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;

  const _QuickStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.cardColor,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 102),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionText;
  final Color cardColor;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.actionText,
    required this.cardColor,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: accent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (actionText != null)
                Row(
                  children: [
                    Text(
                      actionText!,
                      style: TextStyle(
                        color: accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  final TransactionModel transaction;
  final String amountText;
  final String categoryText;
  final Color cardColor;
  final Color primaryText;
  final Color secondaryText;

  const _ImagePreviewCard({
    required this.transaction,
    required this.amountText,
    required this.categoryText,
    required this.cardColor,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    final caption = transaction.caption.trim().isEmpty
        ? categoryText
        : transaction.caption.trim();

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: TransactionMomentImage(
            imageUrl: transaction.imageUrl,
            category: transaction.category,
            caption: transaction.caption,
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          amountText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final IconData icon;
  final Color accent;
  final String amountText;
  final String categoryText;
  final String timeText;
  final Color cardColor;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;
  final VoidCallback onTap;

  const _TransactionRow({
    required this.transaction,
    required this.icon,
    required this.accent,
    required this.amountText,
    required this.categoryText,
    required this.timeText,
    required this.cardColor,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = transaction.caption.trim().isEmpty
        ? categoryText
        : transaction.caption.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.14),
          ),
          child: Icon(
            icon,
            color: accent,
            size: 22,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          timeText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          amountText,
          style: TextStyle(
            color: transaction.type == 'expense'
                ? const Color(0xFFFF7A7A)
                : const Color(0xFF7DDC86),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}