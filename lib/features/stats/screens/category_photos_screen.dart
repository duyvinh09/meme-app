import 'package:flutter/material.dart';
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

class CategoryPhotosScreen extends StatelessWidget {
  final String category;
  final String type;
  final String periodTitle;
  final List<TransactionModel> transactions;

  const CategoryPhotosScreen({
    super.key,
    required this.category,
    required this.type,
    required this.periodTitle,
    required this.transactions,
  });

  String _localizedCategoryLabel(BuildContext context, String categoryValue) {
    final l10n = context.l10n;
    switch (categoryValue.trim()) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Mua sắm':
      case 'Shopping':
        return l10n.shopping;
      case 'Đi lại':
      case 'Transport':
        return l10n.transport;
      case 'Học tập':
      case 'Education':
        return l10n.education;
      case 'Giải trí':
      case 'Entertainment':
        return l10n.entertainment;
      case 'Lương':
      case 'Salary':
        return l10n.salary;
      case 'Quà tặng':
      case 'Gift':
        return l10n.gift;
      case 'Khác':
      case 'Other':
        return l10n.other;
      case 'Quỹ nhóm':
      case 'Group Fund':
        return l10n.groupFundCategory;
      default:
        return BudgetNameLocalizer.display(context, categoryValue);
    }
  }

  Color _categoryColor(String category, String type) {
    switch (category.trim()) {
      case 'Ăn uống':
      case 'Food':
        return const Color(0xFFFF7A7A);
      case 'Mua sắm':
      case 'Shopping':
        return const Color(0xFF79AFFF);
      case 'Đi lại':
      case 'Transport':
        return const Color(0xFFFFC857);
      case 'Giải trí':
      case 'Entertainment':
        return const Color(0xFFB68CFF);
      case 'Học tập':
      case 'Education':
        return const Color(0xFF59D4C8);
      case 'Lương':
      case 'Salary':
        return const Color(0xFF7DDC86);
      case 'Quà tặng':
      case 'Gift':
        return const Color(0xFFFF8FD8);
      case 'Khác':
      case 'Other':
        return const Color(0xFFFFA45B);
      case 'Quỹ nhóm':
      case 'Group Fund':
        return const Color(0xFF10B981);
      default:
        return type == 'income' ? AppColors.income : AppColors.expense;
    }
  }

  IconData _categoryIcon(String category, String type) {
    switch (category.trim()) {
      case 'Ăn uống':
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Mua sắm':
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Đi lại':
      case 'Transport':
        return Icons.directions_bus_rounded;
      case 'Giải trí':
      case 'Entertainment':
        return Icons.movie_creation_rounded;
      case 'Học tập':
      case 'Education':
        return Icons.school_rounded;
      case 'Lương':
      case 'Salary':
        return Icons.payments_rounded;
      case 'Quà tặng':
      case 'Gift':
        return Icons.card_giftcard_rounded;
      case 'Khác':
      case 'Other':
        return Icons.more_horiz_rounded;
      case 'Quỹ nhóm':
      case 'Group Fund':
        return Icons.savings_rounded;
      default:
        return type == 'income'
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
    }
  }

  String _formatCompactMoney(TransactionModel tx, String currency) {
    final prefix = tx.type == 'income' ? '+' : '-';
    return '$prefix${AppCurrencyFormatter.formatFromVnd(
      amountVnd: tx.amount,
      currency: currency,
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = context.watch<ProfileController>().currency;

    final bgColor = isDark ? const Color(0xFF0F1015) : const Color(0xFFF4F6FA);
    final cardColor = isDark ? const Color(0xFF171821) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2D3B) : const Color(0xFFE3E7F0);
    final primaryText = isDark ? Colors.white : const Color(0xFF14151B);
    final secondaryText = isDark ? const Color(0xFFA3A6B2) : const Color(0xFF74788A);

    final accent = _categoryColor(category, type);
    final icon = _categoryIcon(category, type);

    final photoTransactions = transactions
        .where((tx) => tx.displayImageUrl.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: primaryText,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.allPhotos,
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${_localizedCategoryLabel(context, category)} • ${photoTransactions.length} ${l10n.allPhotos.toLowerCase()}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.15),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // GRID CONTENT
            Expanded(
              child: photoTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cardColor,
                              border: Border.all(color: borderColor),
                            ),
                            child: Icon(
                              Icons.photo_library_outlined,
                              color: secondaryText,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.noPhotosInFeed,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                      itemCount: photoTransactions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final tx = photoTransactions[index];

                        return RepaintBoundary(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MomentViewerScreen(
                                    transactions: photoTransactions,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Positioned.fill(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final size = constraints.maxWidth;
                                        return TransactionMomentImage(
                                          imageUrl: tx.displayImageUrl,
                                          category: tx.category,
                                          categoryIconCodePoint:
                                              tx.categoryIconCodePoint,
                                          categoryColorHex:
                                              tx.categoryColorHex,
                                          caption: null,
                                          width: size,
                                          height: size,
                                          fit: BoxFit.cover,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          isVideo: tx.isVideo,
                                          showVideoBadge: tx.isVideo,
                                        );
                                      },
                                    ),
                                  ),

                                  // Bottom Gradient
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.65),
                                          ],
                                          stops: const [0.0, 0.45, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Top-Right Amount Pill
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.60),
                                        borderRadius:
                                            BorderRadius.circular(AppSizes.radiusPill),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.20),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        _formatCompactMoney(tx, currency),
                                        style: TextStyle(
                                          color: tx.type == 'income'
                                              ? const Color(0xFF7DDC86)
                                              : Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bottom Caption if available
                                  if (tx.caption.trim().isNotEmpty)
                                    Positioned(
                                      left: 8,
                                      right: 8,
                                      bottom: 6,
                                      child: Text(
                                        tx.caption.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
