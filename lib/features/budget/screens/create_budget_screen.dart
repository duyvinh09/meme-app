import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/controllers/user_category_controller.dart';
import '../controllers/budget_controller.dart';
import '../services/budget_cycle_helper.dart';

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  String period = 'monthly';
  String budgetType = 'category';
  Color selectedColor = AppColors.primaryBlue;
  IconData selectedIcon = Icons.account_balance_wallet_rounded;
  String? selectedCategoryKey;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  bool _loadedCategories = false;

  List<_PeriodOption> get periodOptions => [
    _PeriodOption('daily', context.l10n.daily, Icons.wb_sunny_outlined),
    _PeriodOption('weekly', context.l10n.weekly, Icons.calendar_view_week_outlined),
    _PeriodOption('biweekly', context.l10n.biweekly, Icons.date_range_outlined),
    _PeriodOption('monthly', context.l10n.monthly, Icons.calendar_month_outlined),
    _PeriodOption('yearly', context.l10n.yearly, Icons.event_note_outlined),
    _PeriodOption('custom', context.l10n.custom, Icons.edit_calendar_outlined),
  ];

  final List<Color> colorOptions = const [
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

  final List<IconData> iconOptions = const [
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
    if (!_loadedCategories) {
      final uid = context.read<AuthController>().user?.uid;
      if (uid != null) {
        context.read<UserCategoryController>().load(uid);
      }
      _loadedCategories = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String get displayName {
    final text = nameController.text.trim();
    return text.isEmpty ? context.l10n.budgetNamePreview : text;
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

  String displayAmount(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;
    final raw = amountController.text.trim();

    if (raw.isEmpty) {
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: 0,
        currency: currency,
      );
    }

    final inputAmount = _parseMoneyInput(
      raw: raw,
      currency: currency,
    );

    final amountVnd = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currency,
    );

    return AppCurrencyFormatter.formatFromVnd(
      amountVnd: amountVnd,
      currency: currency,
    );
  }

  String get displayPeriodText {
    if (period == 'custom') {
      final s =
          '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}';
      final e =
          '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}';
      return '$s - $e';
    }

    switch (period) {
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
      default:
        return context.l10n.monthly;
    }
  }

  String get displayTypeText {
    if (budgetType == 'total') {
      return context.l10n.total;
    }
    if (selectedCategoryKey != null && selectedCategoryKey!.isNotEmpty) {
      return '${context.l10n.category}: ${BudgetNameLocalizer.display(context, selectedCategoryKey!)}';
    }
    return context.l10n.category;
  }

  String _periodDescription(String p) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    switch (p) {
      case 'daily':
        return isEn ? 'Resets at 00:00 every day' : 'Làm mới vào 00:00 mỗi ngày';
      case 'weekly':
        return isEn ? 'Monday to Sunday every week' : 'Thứ Hai đến Chủ Nhật hàng tuần';
      case 'biweekly':
        return isEn ? 'Repeats every 14 days' : 'Chu kỳ lặp lại mỗi 14 ngày';
      case 'yearly':
        return isEn ? 'From Jan 1st to Dec 31st each year' : 'Từ 01/01 đến 31/12 hàng năm';
      case 'custom':
        return isEn ? 'Fixed period between chosen dates' : 'Khoảng ngày cố định được chọn';
      case 'monthly':
      default:
        return isEn
            ? 'From 1st to the last day of each month'
            : 'Từ ngày 1 đến ngày cuối cùng của tháng';
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate.isBefore(startDate)) {
          endDate = startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate.isBefore(startDate) ? startDate : endDate,
      firstDate: startDate,
      lastDate: DateTime(2100),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    final isDark = AppColors.isDark(ctx);
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: isDark
            ? ColorScheme.dark(
                primary: selectedColor,
                surface: AppColors.card(ctx),
              )
            : ColorScheme.light(
                primary: selectedColor,
                surface: AppColors.card(ctx),
              ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  List<_CategoryOption> _buildCategoryOptions(BuildContext context) {
    final l10n = context.l10n;
    final List<_CategoryOption> list = [
      _CategoryOption(
        key: 'Ăn uống',
        displayName: l10n.food,
        icon: Icons.restaurant_rounded,
        color: AppColors.income,
        nameEn: 'Food',
      ),
      _CategoryOption(
        key: 'Mua sắm',
        displayName: l10n.shopping,
        icon: Icons.shopping_bag_rounded,
        color: AppColors.primaryPink,
        nameEn: 'Shopping',
      ),
      _CategoryOption(
        key: 'Đi lại',
        displayName: l10n.transport,
        icon: Icons.directions_car_rounded,
        color: AppColors.primaryBlue,
        nameEn: 'Transport',
      ),
      _CategoryOption(
        key: 'Giải trí',
        displayName: l10n.entertainment,
        icon: Icons.theater_comedy_rounded,
        color: AppColors.warning,
        nameEn: 'Entertainment',
      ),
      _CategoryOption(
        key: 'Học tập',
        displayName: l10n.education,
        icon: Icons.school_rounded,
        color: AppColors.primaryPurple,
        nameEn: 'Education',
      ),
      _CategoryOption(
        key: 'Khác',
        displayName: l10n.other,
        icon: Icons.more_horiz_rounded,
        color: const Color(0xFFAAAAAA),
        nameEn: 'Other',
      ),
    ];

    try {
      final userCatController = context.watch<UserCategoryController>();
      for (final uc in userCatController.categoriesForExpense()) {
        Color c;
        final hex = uc.colorHex.replaceAll('#', '');
        if (hex.length == 6) {
          c = Color(int.parse('FF$hex', radix: 16));
        } else {
          c = AppColors.primaryBlue;
        }

        final isEn = Localizations.localeOf(context).languageCode == 'en';
        final dName = (isEn && uc.nameEn != null && uc.nameEn!.trim().isNotEmpty)
            ? uc.nameEn!
            : uc.name;

        list.add(_CategoryOption(
          key: uc.name,
          displayName: dName,
          icon: AppIconRegistry.fromCodePoint(uc.iconCodePoint),
          color: c,
          nameEn: uc.nameEn,
        ));
      }
    } catch (_) {}

    return list;
  }

  void _onCategorySelected(_CategoryOption cat) {
    setState(() {
      selectedCategoryKey = cat.key;
      nameController.text = cat.displayName;
      selectedIcon = cat.icon;
      selectedColor = cat.color;
    });
  }

  Future<void> _createBudget() async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;

    final rawName = nameController.text.trim();
    final rawAmount = amountController.text.trim();

    if (rawName.isEmpty) {
      _showSnack(context.l10n.pleaseEnterBudgetName);
      return;
    }

    if (rawAmount.isEmpty) {
      _showSnack(context.l10n.pleaseEnterBudgetAmount);
      return;
    }

    if (period == 'custom' && endDate.isBefore(startDate)) {
      _showSnack('Ngày kết thúc phải sau hoặc bằng ngày bắt đầu');
      return;
    }

    final budget = context.read<BudgetController>();
    final currency = context.read<ProfileController>().currency;

    final inputAmount = _parseMoneyInput(
      raw: rawAmount,
      currency: currency,
    );

    if (inputAmount <= 0) {
      _showSnack(context.l10n.budgetAmountPositive);
      return;
    }

    final amount = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currency,
    );

    // If budgetType is marked 'total', but user typed a custom budget name that isn't a total budget name,
    // ensure it is saved as 'category' so it acts as an individual wallet rather than capturing all expenses!
    final effectiveBudgetType =
        (budgetType == 'total' && BudgetCycleHelper.isTotalBudgetName(rawName))
            ? 'total'
            : 'category';

    try {
      await budget.createBudget(
        uid: uid,
        name: rawName,
        iconCodePoint: selectedIcon.codePoint,
        colorHex:
            '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        limitAmount: amount,
        period: period,
        budgetType: effectiveBudgetType,
        startDate: period == 'custom'
            ? startDate
            : (period == 'biweekly' ? startDate : null),
        endDate: period == 'custom' ? endDate : null,
        categoryKey:
            effectiveBudgetType == 'category' ? selectedCategoryKey : null,
        inputLocaleIsEnglish:
            Localizations.localeOf(context).languageCode == 'en',
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _showSnack(context.l10n.cannotCreateBudget(msg));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: AppDurations.snackBar,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = amountController.text.trim().isNotEmpty &&
        nameController.text.trim().isNotEmpty;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final categories = _buildCategoryOptions(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            AppSizes.bottomNavSafePadding,
          ),
          children: [
            _TopBar(
              onCancel: () => Navigator.pop(context),
            ),

            const SizedBox(height: 18),

            _PreviewBudgetCard(
              color: selectedColor,
              icon: selectedIcon,
              title: displayName,
              amount: displayAmount(context),
              periodText: displayPeriodText,
              typeText: displayTypeText,
            ),

            const SizedBox(height: 22),

            _SectionTitle(title: context.l10n.budgetType),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BudgetTypeCard(
                    title: context.l10n.total,
                    subtitle: context.l10n.allSpending,
                    icon: Icons.language_rounded,
                    selected: budgetType == 'total',
                    selectedColor: selectedColor,
                    onTap: () {
                      setState(() {
                        budgetType = 'total';
                        selectedCategoryKey = null;
                        if (nameController.text.isEmpty) {
                          nameController.text = isEn ? 'Total Expenses' : 'Tổng chi tiêu';
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BudgetTypeCard(
                    title: context.l10n.category,
                    subtitle: context.l10n.syncFromCategory,
                    icon: Icons.folder_rounded,
                    selected: budgetType == 'category',
                    selectedColor: selectedColor,
                    onTap: () {
                      setState(() {
                        budgetType = 'category';
                        if (categories.isNotEmpty && selectedCategoryKey == null) {
                          _onCategorySelected(categories.first);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),

            if (budgetType == 'category') ...[
              const SizedBox(height: 18),
              _SectionTitle(title: isEn ? 'Select Category' : 'Chọn danh mục chi tiêu'),
              const SizedBox(height: 10),
              _CategoryChipSelector(
                categories: categories,
                selectedKey: selectedCategoryKey,
                onSelected: _onCategorySelected,
              ),
            ],

            const SizedBox(height: 20),

            _SectionTitle(title: context.l10n.budgetNameLabel),
            const SizedBox(height: 8),
            CustomTextField(
              controller: nameController,
              hintText: context.l10n.budgetNameHint,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.drive_file_rename_outline_rounded,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 18),

            _SectionTitle(title: context.l10n.budgetAmountLabel),
            const SizedBox(height: 8),
            _AmountField(
              controller: amountController,
              selectedColor: selectedColor,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            _SectionTitle(title: context.l10n.period),
            const SizedBox(height: 10),
            _PeriodGrid(
              periodOptions: periodOptions,
              selectedPeriod: period,
              selectedColor: selectedColor,
              onSelected: (value) {
                setState(() {
                  period = value;
                });
              },
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _periodDescription(period),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (period == 'custom') ...[
              const SizedBox(height: 16),
              _CustomDateRangeCard(
                startDate: startDate,
                endDate: endDate,
                selectedColor: selectedColor,
                onTapStart: _pickStartDate,
                onTapEnd: _pickEndDate,
              ),
            ],

            const SizedBox(height: 20),

            _SectionTitle(title: context.l10n.color),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colorOptions.map((color) {
                final selected = selectedColor.toARGB32() == color.toARGB32();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: selected ? Colors.white : AppColors.border(context),
                        width: selected ? 3 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            _SectionTitle(title: context.l10n.icon),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: iconOptions.map((icon) {
                final selected = selectedIcon == icon;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIcon = icon;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? selectedColor : AppColors.surface(context),
                      border: Border.all(
                        color: selected
                            ? selectedColor
                            : AppColors.innerBorder(context),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : AppColors.textSecondary(context),
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 26),

            CustomButton(
              text: context.l10n.createBudget,
              onPressedAsync: canSubmit ? _createBudget : null,
              backgroundColor: selectedColor,
              foregroundColor: AppColors.foregroundOnAccent(selectedColor),
              height: 54,
              borderRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String key;
  final String displayName;
  final IconData icon;
  final Color color;
  final String? nameEn;

  const _CategoryOption({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.color,
    this.nameEn,
  });
}

class _CategoryChipSelector extends StatelessWidget {
  final List<_CategoryOption> categories;
  final String? selectedKey;
  final ValueChanged<_CategoryOption> onSelected;

  const _CategoryChipSelector({
    required this.categories,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selectedKey != null &&
            (selectedKey == cat.key ||
                selectedKey!.toLowerCase() == cat.key.toLowerCase());

        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.color.withValues(alpha: 0.18)
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? cat.color : AppColors.border(context),
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat.icon,
                  size: 17,
                  color: isSelected ? cat.color : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 7),
                Text(
                  cat.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (AppColors.isDark(context) ? Colors.white : cat.color)
                        : AppColors.textPrimary(context),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 5),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: cat.color,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CustomDateRangeCard extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Color selectedColor;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;

  const _CustomDateRangeCard({
    required this.startDate,
    required this.endDate,
    required this.selectedColor,
    required this.onTapStart,
    required this.onTapEnd,
  });

  String _format(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final totalDays = endDate.difference(startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selectedColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 18,
                color: selectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                isEn ? 'Custom Date Range' : 'Khoảng thời gian áp dụng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEn ? '$totalDays days' : '$totalDays ngày',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selectedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTapStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Start date' : 'Từ ngày',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _format(startDate),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Color(0xFFAAAAAA),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onTapEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'End date' : 'Đến ngày',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _format(endDate),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onCancel;

  const _TopBar({
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              border: Border.all(
                color: AppColors.innerBorder(context),
              ),
            ),
            child: Text(
              context.l10n.cancelLabel,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          context.l10n.addBudget,
          style: AppTextStyles.pageTitle(context).copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 64),
      ],
    );
  }
}

class _PreviewBudgetCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String amount;
  final String periodText;
  final String typeText;

  const _PreviewBudgetCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.amount,
    required this.periodText,
    required this.typeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: AppColors.isDark(context) ? 0.10 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle(context).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$periodText  •  $typeText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySecondary(context).copyWith(
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
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color selectedColor;
  final ValueChanged<String>? onChanged;

  const _AmountField({
    required this.controller,
    required this.selectedColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(
        decimal: currency == 'USD',
      ),
      textAlign: TextAlign.center,
      cursorColor: selectedColor,
      inputFormatters: [
        MoneyInputFormatter(
          allowDecimal: currency == 'USD',
          maxDigits: currency == 'USD' ? 7 : 12,
        ),
      ],
      style: TextStyle(
        color: AppColors.textPrimary(context),
        fontSize: 38,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        hintText: AppCurrencyFormatter.formatInputHint(currency),
        hintStyle: TextStyle(
          color: AppColors.textSecondary(context).withValues(alpha: 0.50),
          fontSize: 38,
          fontWeight: FontWeight.w900,
        ),
        suffixText: AppCurrencyFormatter.symbol(currency),
        suffixStyle: TextStyle(
          color: AppColors.textPrimary(context),
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: AppColors.card(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.border(context),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.border(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: selectedColor,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

class _PeriodGrid extends StatelessWidget {
  final List<_PeriodOption> periodOptions;
  final String selectedPeriod;
  final Color selectedColor;
  final ValueChanged<String> onSelected;

  const _PeriodGrid({
    required this.periodOptions,
    required this.selectedPeriod,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: periodOptions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3.25,
      ),
      itemBuilder: (context, index) {
        final item = periodOptions[index];
        final selected = selectedPeriod == item.value;

        return GestureDetector(
          onTap: () => onSelected(item.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? selectedColor : AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? selectedColor : AppColors.border(context),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: selected ? Colors.white : AppColors.textSecondary(context),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BudgetTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _BudgetTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? selectedColor : AppColors.border(context),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? Colors.white : AppColors.textSecondary(context),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.88)
                    : AppColors.textSecondary(context),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.sectionTitle(context).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PeriodOption {
  final String value;
  final String label;
  final IconData icon;

  const _PeriodOption(this.value, this.label, this.icon);
}