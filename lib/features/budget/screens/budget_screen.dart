import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/budget_controller.dart';
import '../services/budget_cycle_helper.dart';
import 'budget_history_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool loaded = false;
  bool isOverviewExpanded = false;
  static const List<Color> _colorOptions = [
    AppColors.primaryBlue,
    AppColors.income,
    AppColors.expense,
    AppColors.warning,
    AppColors.primaryPurple,
    Color(0xFF5E5CE6),
    AppColors.primaryPink,
    Color(0xFF1CC5C0),
    Color(0xFFF6D32D),
    Color(0xFFA1A1AA),
  ];
  static const List<IconData> _iconOptions = [
    Icons.account_balance_wallet_rounded,
    Icons.shopping_cart_rounded,
    Icons.shopping_bag_rounded,
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.restaurant_rounded,
    Icons.theater_comedy_rounded,
    Icons.favorite_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.flight_rounded,
    Icons.card_giftcard_rounded,
    Icons.sports_esports_rounded,
    Icons.checkroom_rounded,
    Icons.medication_rounded,
  ];

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

    return AppIconRegistry.fromCodePoint(codePoint);
  }

  Future<void> _confirmDeleteBudget({
    required BuildContext context,
    required String uid,
    required String budgetId,
    required String budgetName,
  }) async {
    if (!context.mounted) return;

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final barrierLabel =
        MaterialLocalizations.of(context).modalBarrierDismissLabel;

    final ok = await showGeneralDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final closeTip =
            MaterialLocalizations.of(dialogContext).closeButtonTooltip;
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Material(
                color: AppColors.card(dialogContext),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 40),
                            child: Text(
                              l10n.deleteBudgetQuestion,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.deleteBudgetWarning(budgetName)),
                          const SizedBox(height: 24),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.expense,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          tooltip: closeTip,
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary(dialogContext),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          duration: AppDurations.snackBar,
          content: Text(l10n.budgetDeleted(budgetName)),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.cannotDeleteBudget(e.toString())),
        ),
      );
    }
  }

  double _parseMoneyInput({
    required String raw,
    required String currency,
  }) {
    final cleaned = currency == 'USD'
        ? raw.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '')
        : raw.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatAmountForInput({
    required double amountVnd,
    required String currency,
  }) {
    final normalizedCurrency = AppCurrencyFormatter.normalizeCurrency(currency);
    final displayAmount = AppCurrencyFormatter.fromVnd(
      amountVnd: amountVnd,
      currency: normalizedCurrency,
    );

    if (normalizedCurrency == 'USD') {
      final usdPattern = NumberFormat('#,##0.##', 'en_US');
      return usdPattern.format(displayAmount);
    }

    return NumberFormat.decimalPattern('vi_VN').format(displayAmount.round());
  }

  String _periodLabel(BuildContext context, String value) {
    switch (value) {
      case 'daily':
        return context.l10n.daily;
      case 'weekly':
        return context.l10n.weekly;
      case 'biweekly':
        return context.l10n.biweekly;
      case 'monthly':
        return context.l10n.monthly;
      case 'yearly':
        return context.l10n.yearly;
      case 'custom':
        return context.l10n.custom;
      default:
        return context.l10n.monthly;
    }
  }

  String _budgetTypeLabel(BuildContext context, String value) {
    return value == 'category' ? context.l10n.category : context.l10n.total;
  }

  Future<void> _showEditBudgetDialog({
    required BuildContext context,
    required String uid,
    required String budgetId,
    required String currentName,
    required double currentLimitAmountVnd,
    required int currentIconCodePoint,
    required String currentColorHex,
    required String currentPeriod,
    required String currentBudgetType,
    DateTime? currentStartDate,
    DateTime? currentEndDate,
    String? currentCategoryKey,
  }) async {
    final l10n = context.l10n;
    final currency = context.read<ProfileController>().currency;
    final nameController = TextEditingController(text: currentName);
    final amountController = TextEditingController(
      text: _formatAmountForInput(
        amountVnd: currentLimitAmountVnd,
        currency: currency,
      ),
    );
    Color selectedColor = _parseHexColor(currentColorHex);
    IconData selectedIcon = _budgetIcon(currentIconCodePoint);
    String selectedPeriod = currentPeriod;
    String selectedBudgetType = currentBudgetType;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final initialColor = _parseHexColor(currentColorHex);
            final rawName = nameController.text.trim();
            final rawAmount = amountController.text.trim();
            final parsedInputAmount = _parseMoneyInput(
              raw: rawAmount,
              currency: currency,
            );
            final parsedAmountVnd = AppCurrencyFormatter.toVnd(
              inputAmount: parsedInputAmount,
              currency: currency,
            );
            final hasChanged = rawName != currentName.trim() ||
                (parsedAmountVnd - currentLimitAmountVnd).abs() >= 1 ||
                selectedIcon.codePoint != currentIconCodePoint ||
                selectedPeriod != currentPeriod ||
                selectedBudgetType != currentBudgetType ||
                selectedColor.toARGB32() != initialColor.toARGB32();
            final canSubmit = rawName.isNotEmpty && parsedInputAmount > 0 && hasChanged;
            final labelEmphasisColor =
                AppColors.isDark(dialogContext) ? Colors.white : Colors.black;
            final baseBorder = OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.innerBorder(dialogContext)),
            );
            final focusedBorder = OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: selectedColor,
                width: 1.4,
              ),
            );

            InputDecoration editDecoration({
              required String label,
              String? hint,
              String? suffix,
              bool emphasizedLabel = false,
            }) {
              final labelEmphasisStyle = AppTextStyles.body(dialogContext).copyWith(
                color: labelEmphasisColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              );
              return InputDecoration(
                labelText: label,
                hintText: hint,
                suffixText: suffix,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: emphasizedLabel
                    ? labelEmphasisStyle
                    : AppTextStyles.body(dialogContext).copyWith(
                        color: AppColors.textPrimary(dialogContext),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                floatingLabelStyle: emphasizedLabel
                    ? labelEmphasisStyle
                    : AppTextStyles.body(dialogContext).copyWith(
                        color: selectedColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                filled: true,
                fillColor: AppColors.surface(dialogContext),
                enabledBorder: baseBorder,
                border: baseBorder,
                focusedBorder: focusedBorder,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              );
            }

            return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
          title: Text(
            l10n.editBudget,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.pageTitle(dialogContext).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: labelEmphasisColor,
              height: 1.2,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: editDecoration(
                    label: l10n.budgetNameLabel,
                    hint: l10n.budgetNameHint,
                    emphasizedLabel: true,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: amountController,
                  onChanged: (_) => setDialogState(() {}),
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: currency == 'USD',
                  ),
                  inputFormatters: [
                    MoneyInputFormatter(
                      allowDecimal: currency == 'USD',
                      maxDigits: currency == 'USD' ? 7 : 12,
                    ),
                  ],
                  decoration: editDecoration(
                    label: l10n.budgetAmountLabel,
                    hint: AppCurrencyFormatter.formatInputHint(currency),
                    suffix: AppCurrencyFormatter.symbol(currency),
                    emphasizedLabel: true,
                  ),
                ),
                const SizedBox(height: 22),
                DropdownButtonFormField<String>(
                  initialValue: selectedPeriod,
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: AppColors.card(dialogContext),
                  decoration: editDecoration(
                    label: l10n.period,
                    emphasizedLabel: true,
                  ),
                  items: const [
                    'daily',
                    'weekly',
                    'biweekly',
                    'monthly',
                    'yearly',
                    'custom',
                  ].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(_periodLabel(dialogContext, value)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedPeriod = value);
                  },
                ),
                const SizedBox(height: 22),
                DropdownButtonFormField<String>(
                  initialValue: selectedBudgetType,
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: AppColors.card(dialogContext),
                  decoration: editDecoration(
                    label: l10n.budgetType,
                    emphasizedLabel: true,
                  ),
                  items: const ['total', 'category'].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(_budgetTypeLabel(dialogContext, value)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedBudgetType = value);
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.color,
                    style: AppTextStyles.caption(dialogContext).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((color) {
                    final selected =
                        selectedColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.icon,
                    style: AppTextStyles.caption(dialogContext).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((icon) {
                    final selected = selectedIcon.codePoint == icon.codePoint;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selected
                              ? selectedColor.withValues(alpha: 0.16)
                              : AppColors.surface(dialogContext),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? selectedColor
                                : AppColors.innerBorder(dialogContext),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: selected
                              ? selectedColor
                              : AppColors.textSecondary(dialogContext),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: canSubmit
                            ? () => Navigator.pop(dialogContext, true)
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: selectedColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.update),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          );
          },
        );
      },
    );

    if (updated != true) return;

    final rawName = nameController.text.trim();
    final rawAmount = amountController.text.trim();
    if (rawName.isEmpty) {
      _showSnack(context, l10n.pleaseEnterBudgetName);
      return;
    }
    if (rawAmount.isEmpty) {
      _showSnack(context, l10n.pleaseEnterBudgetAmount);
      return;
    }

    final inputAmount = _parseMoneyInput(raw: rawAmount, currency: currency);
    if (inputAmount <= 0) {
      _showSnack(context, l10n.budgetAmountPositive);
      return;
    }

    final amountVnd = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currency,
    );

    final hasChanged = rawName != currentName.trim() ||
        (amountVnd - currentLimitAmountVnd).abs() >= 1 ||
        selectedIcon.codePoint != currentIconCodePoint ||
        selectedPeriod != currentPeriod ||
        selectedBudgetType != currentBudgetType ||
        selectedColor.toARGB32() != _parseHexColor(currentColorHex).toARGB32();
    if (!hasChanged) {
      _showSnack(context, l10n.budgetUnchanged);
      return;
    }

    try {
      await context.read<BudgetController>().updateBudget(
        uid: uid,
        budgetId: budgetId,
        name: rawName,
        limitAmount: amountVnd,
        iconCodePoint: selectedIcon.codePoint,
        colorHex:
            '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        period: selectedPeriod,
        budgetType: selectedBudgetType,
        startDate: currentStartDate,
        endDate: currentEndDate,
        categoryKey: currentCategoryKey,
        inputLocaleIsEnglish:
            Localizations.localeOf(context).languageCode == 'en',
      );
      if (!mounted) return;
      _showSnack(context, l10n.budgetUpdated);
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, l10n.cannotUpdateBudget(e.toString()));
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: AppDurations.snackBar,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                userName: context.watch<ProfileController>().user?.name,
                dateOfBirth: context.watch<ProfileController>().user?.dateOfBirth,
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
                  final displayName = BudgetNameLocalizer.display(
                    context,
                    item.name,
                    budgetNameEn: item.nameEn,
                  );

                  final itemPercent = item.limitAmount <= 0
                      ? 0.0
                      : (item.spentAmount / item.limitAmount).clamp(0.0, 1.0).toDouble();

                  return _BudgetOverviewItemData(
                    title: displayName,
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
                    periodText: _periodLabel(context, item.period),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            const _BudgetNoteCard(),

            const SizedBox(height: 14),

            if (budget.errorMessage != null)
              _ErrorCard(
                message: context.l10n.loadBudgetError(budget.errorMessage!),
              )
            else if (budget.budgets.isEmpty)
              const _EmptyBudgetCard()
            else ...[
                _SectionTitle(
                  title: l10n.personalThemes,
                  subtitle: l10n.trackSpentVsGoal,
                ),
                const SizedBox(height: 10),

                ...budget.budgets.map((item) {
                  final budgetColor = _parseHexColor(item.colorHex);
                  final budgetIcon = _budgetIcon(item.iconCodePoint);
                  final displayName = BudgetNameLocalizer.display(
                    context,
                    item.name,
                    budgetNameEn: item.nameEn,
                  );

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
                    title: displayName,
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
                    cycleSubtitle: BudgetCycleHelper.formatCycleSubtitle(
                      item,
                      isEnglish:
                          Localizations.localeOf(context).languageCode == 'en',
                    ),
                    onAnalyze: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BudgetHistoryScreen(
                            budget: item,
                            budgetName: item.name,
                            budgetNameEn: item.nameEn,
                            limitAmount: item.limitAmount,
                            iconCodePoint: item.iconCodePoint,
                            colorHex: item.colorHex,
                          ),
                        ),
                      );
                    },
                    onEdit: uid == null
                        ? null
                        : () => _showEditBudgetDialog(
                              context: context,
                              uid: uid,
                              budgetId: item.id,
                              currentName: displayName,
                              currentLimitAmountVnd: item.limitAmount,
                              currentIconCodePoint: item.iconCodePoint,
                              currentColorHex: item.colorHex,
                              currentPeriod: item.period,
                              currentBudgetType: item.budgetType,
                              currentStartDate: item.startDate,
                              currentEndDate: item.endDate,
                              currentCategoryKey: item.categoryKey,
                            ),
                    onDelete: uid == null
                        ? null
                        : () => _confirmDeleteBudget(
                              context: context,
                              uid: uid,
                              budgetId: item.id,
                              budgetName: displayName,
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
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.budgetTitle,
                style: AppTextStyles.pageTitle(context).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.budgetSubtitle,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.createBudget);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue,
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: AppColors.isDark(context) ? 0.14 : 0.90,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.32),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.budgetNote,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
  final String? userName;
  final DateTime? dateOfBirth;
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
    this.userName,
    this.dateOfBirth,
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
    final l10n = context.l10n;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final percentText = '${(percent * 100).round()}%';
    final now = DateTime.now();
    final validThru =
        '${now.month.toString().padLeft(2, '0')}/${(now.year % 100).toString().padLeft(2, '0')}';
    final lastFourDigits = dateOfBirth != null
        ? '${dateOfBirth!.day.toString().padLeft(2, '0')}${dateOfBirth!.month.toString().padLeft(2, '0')}'
        : '3923';

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withValues(
                      alpha: AppColors.isDark(context) ? 0.28 : 0.22,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CustomPaint(
                foregroundPainter: const _DebitCardBorderPainter(
                  borderColor: Color(0xFF7EACDB),
                  borderWidth: 1.2,
                  cornerRadius: 28,
                  cutoutSize: 72,
                ),
                child: ClipPath(
                  clipper: const _DebitCardClipper(
                    cornerRadius: 28,
                    cutoutSize: 72,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE2F0FD),
                          Color(0xFFC0E2FF),
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: const _CardSquigglePainter(
                        color: Color(0xFFA6D3FF),
                      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const _MastercardLogo(),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 56),
                              child: Text(
                                l10n.budgetOverview,
                                style: const TextStyle(
                                  color: Color(0xFF13345A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '••••  ••••  ••••  $lastFourDigits',
                          style: const TextStyle(
                            color: Color(0xFF385A7F),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    totalSpentText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0C2440),
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userName?.isNotEmpty == true
                                        ? userName!
                                        : l10n.you,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF385A7F),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isEnglish ? 'Valid Thru' : 'Hiệu lực',
                                  style: const TextStyle(
                                    color: Color(0xFF4B6E94),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  validThru,
                                  style: const TextStyle(
                                    color: Color(0xFF0C2440),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.isDark(context)
                          ? const Color(0xFF131D2E)
                          : const Color(0xFF162B44),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.125 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.north_east_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (isExpanded) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.innerBorder(context),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppColors.isDark(context) ? 0.20 : 0.06,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.budgetOverview,
                      style: AppTextStyles.cardTitle(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      percentText,
                      style: TextStyle(
                        color: percent >= 1.0
                            ? AppColors.expense
                            : AppColors.primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: AppColors.surface(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent >= 1 ? AppColors.expense : AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OverviewMiniInfo(
                        icon: Icons.north_east_rounded,
                        text: totalLimitText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OverviewMiniInfo(
                        icon: Icons.spa_rounded,
                        text: totalRemainingText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (overBudgetCount > 0
                                ? AppColors.expense
                                : AppColors.income)
                            .withValues(alpha: 0.12),
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
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            overBudgetCount > 0
                                ? '$overBudgetCount'
                                : '$safeBudgetCount',
                            style: TextStyle(
                              color: overBudgetCount > 0
                                  ? AppColors.expense
                                  : AppColors.income,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(
                    color: AppColors.innerBorder(context),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BudgetOverviewMiniItem(item: item),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MastercardLogo extends StatelessWidget {
  const _MastercardLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 25,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEB001B),
              ),
            ),
          ),
          Positioned(
            left: 15,
            top: 0,
            bottom: 0,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF79E1B).withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSquigglePainter extends CustomPainter {
  final Color color;

  const _CardSquigglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.12, h * 0.35);
    path.cubicTo(
      w * 0.25,
      h * 0.28,
      w * 0.20,
      h * 0.65,
      w * 0.42,
      h * 0.62,
    );
    path.cubicTo(
      w * 0.55,
      h * 0.60,
      w * 0.50,
      h * 0.30,
      w * 0.64,
      h * 0.55,
    );
    path.cubicTo(
      w * 0.72,
      h * 0.72,
      w * 0.85,
      h * 0.65,
      w * 0.96,
      h * 0.50,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CardSquigglePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DebitCardClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double cutoutSize;

  const _DebitCardClipper({
    this.cornerRadius = 28,
    this.cutoutSize = 72,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final cut = cutoutSize;
    const fillet = 14.0;

    final path = Path();
    path.moveTo(r, 0);

    path.lineTo(w - cut - fillet, 0);

    path.quadraticBezierTo(
      w - cut,
      0,
      w - cut,
      fillet,
    );

    path.arcToPoint(
      Offset(w - fillet, cut),
      radius: Radius.circular(cut - fillet),
      clockwise: false,
    );

    path.quadraticBezierTo(
      w,
      cut,
      w,
      cut + fillet,
    );

    path.lineTo(w, h - r);

    path.arcToPoint(
      Offset(w - r, h),
      radius: Radius.circular(r),
      clockwise: true,
    );

    path.lineTo(r, h);

    path.arcToPoint(
      Offset(0, h - r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    path.lineTo(0, r);

    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _DebitCardClipper oldClipper) => false;
}

class _DebitCardBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
  final double cutoutSize;

  const _DebitCardBorderPainter({
    required this.borderColor,
    this.borderWidth = 1.2,
    this.cornerRadius = 28,
    this.cutoutSize = 72,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = _DebitCardClipper(
      cornerRadius: cornerRadius,
      cutoutSize: cutoutSize,
    );
    final path = clipper.getClip(size);
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DebitCardBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.cutoutSize != cutoutSize;
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
          color: AppColors.textSecondary(context),
          size: 13,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
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
    final progressColor =
        item.isOverLimit ? AppColors.expense : AppColors.primaryBlue;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.color.withValues(alpha: 0.15),
          ),
          child: Icon(
            item.icon,
            color: item.color,
            size: 16,
          ),
        ),

        const SizedBox(width: 8),

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
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.periodText,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: item.percent,
                  minHeight: 4,
                  backgroundColor: AppColors.surface(context),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        SizedBox(
          width: 95,
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
                      ? AppColors.expense
                      : AppColors.textPrimary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.limitText} • ${(item.percent * 100).round()}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
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
  final VoidCallback? onEdit;

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
    this.cycleSubtitle,
    required this.onDelete,
    required this.onAnalyze,
    required this.onEdit,
  });

  final String? cycleSubtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverLimit
              ? AppColors.expense.withValues(alpha: 0.45)
              : AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: AppColors.isDark(context) ? 0.08 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOverLimit
                          ? context.l10n.overLimit
                          : (cycleSubtitle != null && cycleSubtitle!.isNotEmpty
                              ? '$remainingText • $cycleSubtitle'
                              : context.l10n.remainingAmount(remainingText)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: isOverLimit
                            ? AppColors.expense
                            : AppColors.textSecondary(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(
                  '${(percent * 100).round()}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              Builder(
                builder: (iconContext) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () async {
                      final RenderBox button =
                          iconContext.findRenderObject()! as RenderBox;
                      final overlayState = Overlay.maybeOf(iconContext);
                      final overlayObject = overlayState != null
                          ? overlayState.context.findRenderObject()
                          : Navigator.of(iconContext)
                              .overlay
                              ?.context
                              .findRenderObject();
                      if (overlayObject is! RenderBox) return;

                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(
                            Offset.zero,
                            ancestor: overlayObject,
                          ),
                          button.localToGlobal(
                            button.size.bottomRight(Offset.zero),
                            ancestor: overlayObject,
                          ),
                        ),
                        Offset.zero & overlayObject.size,
                      );

                      final value = await showMenu<String>(
                        context: iconContext,
                        position: position,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppColors.innerBorder(context),
                          ),
                        ),
                        color: AppColors.card(context),
                        elevation: 8,
                        items: [
                          PopupMenuItem<String>(
                            value: 'analyze',
                            enabled: onAnalyze != null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 18,
                                  color: onAnalyze == null
                                      ? AppColors.textSecondary(context)
                                      : color,
                                ),
                                const SizedBox(width: 8),
                                Text(context.l10n.budgetAnalysis),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'edit',
                            enabled: onEdit != null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: onEdit == null
                                      ? AppColors.textSecondary(context)
                                      : AppColors.textPrimary(context),
                                ),
                                const SizedBox(width: 8),
                                Text(context.l10n.editBudget),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            enabled: onDelete != null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: onDelete == null
                                      ? AppColors.textSecondary(context)
                                      : AppColors.expense,
                                ),
                                const SizedBox(width: 8),
                                Text(context.l10n.deleteBudget),
                              ],
                            ),
                          ),
                        ],
                      );

                      if (!iconContext.mounted) return;
                      switch (value) {
                        case 'analyze':
                          onAnalyze?.call();
                          break;
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                        default:
                          break;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary(context),
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AppColors.surface(context),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${context.l10n.budgetGoal}: $limitText',
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
              Text(
                '${context.l10n.usedAmount}: $spentText',
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isOverLimit
                      ? AppColors.expense
                      : AppColors.textPrimary(context),
                ),
              ),
            ],
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
        horizontal: 20,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.wallet_giftcard_outlined,
            size: 60,
            color: AppColors.textSecondary(context).withValues(alpha: 0.72),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noBudgetThemes,
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(context).copyWith(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.noBudgetThemesSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 13,
              height: 1.4,
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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