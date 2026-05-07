import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/budget_controller.dart';
import 'budget_history_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool loaded = false;
  bool isOverviewExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null) {
        context.read<BudgetController>().load(uid);
      }

      loaded = true;
    }
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) {
      return AppColors.primaryBlue;
    }

    var cleaned = hex.trim().replaceAll('#', '');

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) {
      return AppColors.primaryBlue;
    }

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return AppColors.primaryBlue;
    }
  }

  IconData _budgetIcon(int codePoint) {
    if (codePoint <= 0) {
      return Icons.account_balance_wallet_outlined;
    }

    return IconData(
      codePoint,
      fontFamily: 'MaterialIcons',
    );
  }

  Future<void> _confirmDeleteBudget({
    required BuildContext context,
    required String uid,
    required String budgetId,
    required String budgetName,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xoá ngân sách?'),
          content: Text(
            'Bạn có chắc muốn xoá chủ đề "$budgetName" không? Các giao dịch đã tạo trước đó vẫn giữ nguyên, chỉ xoá mục tiêu ngân sách này.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await context.read<BudgetController>().deleteBudget(
        uid: uid,
        budgetId: budgetId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xoá "$budgetName"'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xoá ngân sách: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetController>();
    final currency = context.watch<ProfileController>().currency;
    final uid = context.read<AuthController>().user?.uid;

    final totalLimit = budget.budgets.fold<double>(
      0,
          (sum, item) => sum + item.limitAmount,
    );

    final totalSpent = budget.budgets.fold<double>(
      0,
          (sum, item) => sum + item.spentAmount,
    );

    final totalRemaining = totalLimit - totalSpent;

    final overviewPercent = totalLimit <= 0
        ? 0.0
        : (totalSpent / totalLimit).clamp(0.0, 1.0).toDouble();

    final overBudgetCount = budget.budgets.where((item) {
      return item.limitAmount > 0 && item.spentAmount > item.limitAmount;
    }).length;

    final safeBudgetCount = budget.budgets.where((item) {
      return item.limitAmount > 0 && item.spentAmount <= item.limitAmount;
    }).length;

    final topBudgetItems = [...budget.budgets]
      ..sort((a, b) => b.spentAmount.compareTo(a.spentAmount));

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: budget.isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : ListView(
          cacheExtent: 800,
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            AppSizes.bottomNavSafePadding,
          ),
          children: [
            const _BudgetHeader(),
            const SizedBox(height: 16),

            if (budget.budgets.length >= 2) ...[
              _BudgetOverviewCard(
                totalSpentText: AppCurrencyFormatter.formatFromVnd(
                  amountVnd: totalSpent,
                  currency: currency,
                ),
                totalLimitText: AppCurrencyFormatter.formatFromVnd(
                  amountVnd: totalLimit,
                  currency: currency,
                ),
                totalRemainingText: AppCurrencyFormatter.formatFromVnd(
                  amountVnd: totalRemaining < 0 ? 0 : totalRemaining,
                  currency: currency,
                ),
                percent: overviewPercent,
                budgetCount: budget.budgets.length,
                safeBudgetCount: safeBudgetCount,
                overBudgetCount: overBudgetCount,
                isExpanded: isOverviewExpanded,
                onToggleExpanded: () {
                  setState(() {
                    isOverviewExpanded = !isOverviewExpanded;
                  });
                },
                items: topBudgetItems.take(2).map((item) {
                  final itemColor = _parseHexColor(item.colorHex);
                  final itemIcon = _budgetIcon(item.iconCodePoint);

                  final itemPercent = item.limitAmount <= 0
                      ? 0.0
                      : (item.spentAmount / item.limitAmount).clamp(0.0, 1.0).toDouble();

                  return _BudgetOverviewItemData(
                    title: item.name,
                    icon: itemIcon,
                    color: itemColor,
                    spentText: AppCurrencyFormatter.formatFromVnd(
                      amountVnd: item.spentAmount,
                      currency: currency,
                    ),
                    limitText: AppCurrencyFormatter.formatFromVnd(
                      amountVnd: item.limitAmount,
                      currency: currency,
                    ),
                    percent: itemPercent,
                    isOverLimit: item.limitAmount > 0 && item.spentAmount > item.limitAmount,
                    periodText: 'Hằng tháng',
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            const _BudgetNoteCard(),

            const SizedBox(height: 24),

            if (budget.errorMessage != null)
              _ErrorCard(
                message: 'Lỗi tải ngân sách:\n${budget.errorMessage}',
              )
            else if (budget.budgets.isEmpty)
              const _EmptyBudgetCard()
            else ...[
                const _SectionTitle(
                  title: 'Chủ đề cá nhân',
                  subtitle: 'Theo dõi số tiền đã dùng so với mục tiêu',
                ),
                const SizedBox(height: 14),

                ...budget.budgets.map((item) {
                  final budgetColor = _parseHexColor(item.colorHex);
                  final budgetIcon = _budgetIcon(item.iconCodePoint);

                  final double percent = item.limitAmount <= 0
                      ? 0.0
                      : (item.spentAmount / item.limitAmount)
                      .clamp(0.0, 1.0)
                      .toDouble();

                  final bool isOverLimit = item.limitAmount > 0 &&
                      item.spentAmount > item.limitAmount;

                  final progressColor = isOverLimit
                      ? AppColors.expense
                      : percent >= 0.75
                      ? AppColors.warning
                      : budgetColor;

                  final remaining = item.limitAmount - item.spentAmount;

                  return _BudgetItemCard(
                    title: item.name,
                    icon: budgetIcon,
                    color: budgetColor,
                    percent: percent,
                    progressColor: progressColor,
                    isOverLimit: isOverLimit,
                    remainingText: AppCurrencyFormatter.formatFromVnd(
                      amountVnd: remaining < 0 ? 0 : remaining,
                      currency: currency,
                    ),
                    limitText: AppCurrencyFormatter.formatFromVnd(
                      amountVnd: item.limitAmount,
                      currency: currency,
                    ),
                    spentText: AppCurrencyFormatter.formatFromVnd(
                      amountVnd: item.spentAmount,
                      currency: currency,
                    ),
                    onAnalyze: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BudgetHistoryScreen(
                            budgetName: item.name,
                            limitAmount: item.limitAmount,
                            iconCodePoint: item.iconCodePoint,
                            colorHex: item.colorHex,
                          ),
                        ),
                      );
                    },
                    onDelete: uid == null
                        ? null
                        : () => _confirmDeleteBudget(
                      context: context,
                      uid: uid,
                      budgetId: item.id,
                      budgetName: item.name,
                    ),
                  );
                }),
              ],
          ],
        ),
      ),
    );
  }
}

class _BudgetHeader extends StatelessWidget {
  const _BudgetHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ngân sách cá nhân',
                style: AppTextStyles.pageTitle(context).copyWith(
                  fontSize: 25,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo chủ đề và đặt mục tiêu tiền',
                style: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.createBudget);
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue,
              border: Border.all(
                color: Colors.white.withOpacity(
                  AppColors.isDark(context) ? 0.14 : 0.90,
                ),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetNoteCard extends StatelessWidget {
  const _BudgetNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withOpacity(0.16),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Các danh mục mặc định như Ăn uống, Mua sắm, Đi lại sẽ không có giới hạn. Ngân sách ở đây là chủ đề cá nhân do bạn tự tạo.',
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetOverviewItemData {
  final String title;
  final IconData icon;
  final Color color;
  final String spentText;
  final String limitText;
  final double percent;
  final bool isOverLimit;
  final String periodText;

  const _BudgetOverviewItemData({
    required this.title,
    required this.icon,
    required this.color,
    required this.spentText,
    required this.limitText,
    required this.percent,
    required this.isOverLimit,
    required this.periodText,
  });
}

class _BudgetOverviewCard extends StatelessWidget {
  final String totalSpentText;
  final String totalLimitText;
  final String totalRemainingText;
  final double percent;
  final int budgetCount;
  final int safeBudgetCount;
  final int overBudgetCount;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final List<_BudgetOverviewItemData> items;

  const _BudgetOverviewCard({
    required this.totalSpentText,
    required this.totalLimitText,
    required this.totalRemainingText,
    required this.percent,
    required this.budgetCount,
    required this.safeBudgetCount,
    required this.overBudgetCount,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = '${(percent * 100).round()}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4D73FF),
            Color(0xFF8956F0),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CFF).withOpacity(
              AppColors.isDark(context) ? 0.22 : 0.14,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.16),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng quan ngân sách',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tháng ${DateTime.now().month} ${DateTime.now().year}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.layers_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$budgetCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: onToggleExpanded,
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  totalSpentText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                percentText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.20),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent >= 1 ? AppColors.expense : Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _OverviewMiniInfo(
                  icon: Icons.north_east_rounded,
                  text: totalLimitText,
                ),
              ),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.42),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _OverviewMiniInfo(
                  icon: Icons.spa_rounded,
                  text: totalRemainingText,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Row(
                  children: [
                    Icon(
                      overBudgetCount > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_rounded,
                      color: overBudgetCount > 0
                          ? AppColors.expense
                          : AppColors.income,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      overBudgetCount > 0 ? '$overBudgetCount' : '$safeBudgetCount',
                      style: TextStyle(
                        color: overBudgetCount > 0
                            ? AppColors.expense
                            : AppColors.income,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isExpanded && items.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(
              color: Colors.white.withOpacity(0.20),
              height: 1,
            ),
            const SizedBox(height: 12),

            Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BudgetOverviewMiniItem(item: item),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewMiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OverviewMiniInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 15,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetOverviewMiniItem extends StatelessWidget {
  final _BudgetOverviewItemData item;

  const _BudgetOverviewMiniItem({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = item.isOverLimit ? AppColors.expense : Colors.white;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.14),
          ),
          child: Icon(
            item.icon,
            color: Colors.white,
            size: 20,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.periodText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: item.percent,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.20),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 104,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.spentText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: item.isOverLimit
                      ? const Color(0xFFFFB0B0)
                      : Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${item.limitText} • ${(item.percent * 100).round()}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetItemCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double percent;
  final Color progressColor;
  final bool isOverLimit;
  final String remainingText;
  final String limitText;
  final String spentText;
  final VoidCallback? onDelete;
  final VoidCallback? onAnalyze;

  const _BudgetItemCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.percent,
    required this.progressColor,
    required this.isOverLimit,
    required this.remainingText,
    required this.limitText,
    required this.spentText,
    required this.onDelete,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isOverLimit
              ? AppColors.expense.withOpacity(0.45)
              : AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(
              AppColors.isDark(context) ? 0.10 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.16),
                  border: Border.all(
                    color: color.withOpacity(0.22),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isOverLimit
                          ? 'Đã vượt mục tiêu'
                          : 'Còn lại $remainingText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: isOverLimit
                            ? AppColors.expense
                            : AppColors.textSecondary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(
                  '${(percent * 100).round()}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              IconButton(
                tooltip: 'Phân tích ngân sách',
                onPressed: onAnalyze,
                icon: Icon(
                  Icons.analytics_outlined,
                  color: color,
                ),
              ),

              IconButton(
                tooltip: 'Xoá ngân sách',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: AppColors.surface(context),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _BudgetInfoTile(
                  label: 'Mục tiêu',
                  value: limitText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BudgetInfoTile(
                  label: 'Đã dùng',
                  value: spentText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _BudgetInfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgetCard extends StatelessWidget {
  const _EmptyBudgetCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.wallet_giftcard_outlined,
            size: 78,
            color: AppColors.textSecondary(context).withOpacity(0.72),
          ),
          const SizedBox(height: 22),
          Text(
            'Chưa có chủ đề ngân sách',
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(context).copyWith(
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tạo một chủ đề như Picnic, Mua iPad hoặc Đi du lịch để đặt mục tiêu tiền riêng.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Text(
        message,
        style: AppTextStyles.body(context),
      ),
    );
  }
}