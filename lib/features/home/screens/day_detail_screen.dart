import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/routes/route_names.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';
import 'moment_viewer_screen.dart';
import '../../../core/services/video_cache_service.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String? filterType;

  const DayDetailScreen({
    super.key,
    required this.selectedDate,
    this.filterType,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filterType;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatHeaderDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEEE, d MMM, y', locale).format(date);
  }

  String _formatCompactMoney({
    required double value,
    required String currency,
  }) {
    final amountText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: value.abs(),
      currency: currency,
    );

    return '${value >= 0 ? '+' : '-'}$amountText';
  }

  String _formatTime(DateTime createdAt) {
    return DateFormat('HH:mm').format(createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final currency = context.watch<ProfileController>().currency;

    final allDayTransactions = home.transactions.where((tx) {
      return _sameDate(tx.createdAt, widget.selectedDate);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Lọc theo bộ lọc hiện tại (null = tất cả, 'expense' = chỉ chi tiêu, 'income' = chỉ thu nhập)
    final filteredTransactions = allDayTransactions.where((tx) {
      if (_currentFilter == 'expense') return tx.isPersonalExpense;
      if (_currentFilter == 'income') return tx.isPersonalIncome;
      return true;
    }).toList();

    // Preload ngay các video của ngày này để khi bấm vào xem chi tiết là video phát ngay tức thì
    final videoUrls = filteredTransactions
        .where((tx) => tx.isVideo && tx.playableVideoUrl.isNotEmpty)
        .map((tx) => tx.playableVideoUrl)
        .toList();
    if (videoUrls.isNotEmpty) {
      VideoCacheService.instance.preloadBatch(videoUrls);
    }

    final totalIncome = allDayTransactions
        .where((e) => e.isPersonalIncome)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final totalExpense = allDayTransactions
        .where((e) => e.isPersonalExpense)
        .fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: allDayTransactions.isEmpty
            ? _EmptyDayView(
                selectedDateText: _formatHeaderDate(context, widget.selectedDate),
                onClose: () => Navigator.pop(context),
                onCamera: () =>
                    Navigator.pushNamed(context, RouteNames.addTransaction),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                child: Column(
                  children: [
                    _HeaderBar(
                      title: _formatHeaderDate(context, widget.selectedDate),
                      onClose: () => Navigator.pop(context),
                      onCamera: () =>
                          Navigator.pushNamed(context, RouteNames.addTransaction),
                    ),

                    const SizedBox(height: 12),

                    _DailySummaryRow(
                      totalExpenseText: AppCurrencyFormatter.formatFromVnd(
                        amountVnd: totalExpense,
                        currency: currency,
                      ),
                      totalIncomeText: AppCurrencyFormatter.formatFromVnd(
                        amountVnd: totalIncome,
                        currency: currency,
                      ),
                      activeFilter: _currentFilter,
                      onFilterChanged: (filter) {
                        setState(() {
                          _currentFilter = filter;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    Expanded(
                      child: filteredTransactions.isEmpty
                          ? Center(
                              child: Text(
                                _currentFilter == 'expense'
                                    ? (Localizations.localeOf(context).toString().toLowerCase().startsWith('vi')
                                        ? 'Không có giao dịch chi tiêu'
                                        : 'No expense transactions')
                                    : (Localizations.localeOf(context).toString().toLowerCase().startsWith('vi')
                                        ? 'Không có giao dịch thu nhập'
                                        : 'No income transactions'),
                                style: AppTextStyles.bodySecondary(context),
                              ),
                            )
                          : GridView.builder(
                              cacheExtent: 700,
                              itemCount: filteredTransactions.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) {
                                final tx = filteredTransactions[index];

                                return RepaintBoundary(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MomentViewerScreen(
                                            transactions: filteredTransactions,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    child: _MomentGridCard(
                                      transaction: tx,
                                      amountText: _formatCompactMoney(
                                        value: tx.type == 'expense'
                                            ? -tx.amount
                                            : tx.amount,
                                        currency: currency,
                                      ),
                                      timeText: _formatTime(tx.createdAt),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onCamera;

  const _HeaderBar({
    required this.title,
    required this.onClose,
    this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.subtleOverlay(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.glassBorder(context),
              ),
            ),
            child: Icon(
              Icons.close_rounded,
              color: AppColors.textPrimary(context),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle(context).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (onCamera != null)
          InkWell(
            onTap: onCamera,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.subtleOverlay(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.glassBorder(context),
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: AppColors.textPrimary(context),
                size: 20,
              ),
            ),
          )
        else
          const SizedBox(width: 44),
      ],
    );
  }
}

class _DailySummaryRow extends StatelessWidget {
  final String totalExpenseText;
  final String totalIncomeText;
  final String? activeFilter;
  final ValueChanged<String?> onFilterChanged;

  const _DailySummaryRow({
    required this.totalExpenseText,
    required this.totalIncomeText,
    this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: [
        _SummaryPill(
          icon: Icons.north_east_rounded,
          text: totalExpenseText,
          color: AppColors.expense,
          isSelected: activeFilter == 'expense',
          isDimmed: activeFilter == 'income',
          onTap: () {
            if (activeFilter == 'expense') {
              onFilterChanged(null);
            } else {
              onFilterChanged('expense');
            }
          },
        ),
        _SummaryPill(
          icon: Icons.south_west_rounded,
          text: totalIncomeText,
          color: AppColors.income,
          isSelected: activeFilter == 'income',
          isDimmed: activeFilter == 'expense',
          onTap: () {
            if (activeFilter == 'income') {
              onFilterChanged(null);
            } else {
              onFilterChanged('income');
            }
          },
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const _SummaryPill({
    required this.icon,
    required this.text,
    required this.color,
    this.isSelected = false,
    this.isDimmed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(
            maxWidth: 170,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(isDark ? 0.28 : 0.20)
                : color.withOpacity(
                    isDimmed
                        ? (isDark ? 0.07 : 0.05)
                        : (isDark ? 0.16 : 0.12),
                  ),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(
              color: isSelected
                  ? color
                  : color.withOpacity(isDimmed ? 0.08 : 0.20),
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: isDimmed ? 0.45 : 1.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDayView extends StatelessWidget {
  final String selectedDateText;
  final VoidCallback? onClose;
  final VoidCallback? onCamera;

  const _EmptyDayView({
    required this.selectedDateText,
    this.onClose,
    this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onClose != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: _HeaderBar(
              title: selectedDateText,
              onClose: onClose!,
              onCamera: onCamera,
            ),
          ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: AppColors.subtleOverlay(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.glassBorder(context),
                      ),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.textSecondary(context),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    selectedDateText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle(context).copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.dayDetailEmpty,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      fontSize: 15,
                    ),
                  ),
                  if (onCamera != null) ...[
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: onCamera,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Chụp ảnh',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentGridCard extends StatelessWidget {
  final TransactionModel transaction;
  final String amountText;
  final String timeText;

  const _MomentGridCard({
    required this.transaction,
    required this.amountText,
    required this.timeText,
  });

  String _localizedCategoryLabel(BuildContext context, String category) {
    final l10n = context.l10n;
    switch (category.trim()) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Lương':
      case 'Salary':
        return l10n.salary;
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
        if (category.trim().toLowerCase() == 'quỹ nhóm' ||
            category.trim().toLowerCase() == 'group fund' ||
            category.trim().toLowerCase() == l10n.groupFundCategory.toLowerCase()) {
          return l10n.groupFundCategory;
        }
        return BudgetNameLocalizer.display(context, category);
    }
  }

  Color _parseColorHex(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppColors.textSecondary(context);
    }

    var cleaned = value.trim().replaceAll('#', '');

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) {
      return AppColors.textSecondary(context);
    }

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return AppColors.textSecondary(context);
    }
  }

  Color _chipColor(BuildContext context) {
    final savedColor = _parseColorHex(
      context,
      transaction.categoryColorHex,
    );

    if (transaction.categoryColorHex != null &&
        transaction.categoryColorHex.toString().trim().isNotEmpty) {
      return savedColor;
    }

    switch (transaction.category) {
      case 'Ăn uống':
      case 'Food':
      case 'Lương':
      case 'Salary':
        return AppColors.income;
      case 'Mua sắm':
      case 'Shopping':
        return AppColors.primaryPink;
      case 'Đi lại':
      case 'Transport':
        return AppColors.primaryBlue;
      case 'Giải trí':
      case 'Entertainment':
        return AppColors.warning;
      case 'Học tập':
      case 'Education':
        return AppColors.primaryPurple;
      default:
        return AppColors.textSecondary(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _chipColor(context);
    final caption = transaction.caption.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          TransactionMomentImage(
            imageUrl: transaction.imageUrl,
            category: transaction.category,
            categoryIconCodePoint: transaction.categoryIconCodePoint,
            categoryColorHex: transaction.categoryColorHex,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(22),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.38),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 7,
            left: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8,
                  sigmaY: 8,
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 58,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: chipColor,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    _localizedCategoryLabel(context, transaction.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 7,
            top: 8,
            child: Text(
              timeText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (caption.isNotEmpty) ...[
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  amountText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}