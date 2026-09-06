import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/user_category_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/user_category_controller.dart';

/// Matches default expense/income visuals used in transaction preview.
const List<IconData> _kBuiltinExpenseIcons = [
  Icons.shopping_cart_outlined,
  Icons.shopping_bag_outlined,
  Icons.directions_bus_outlined,
  Icons.movie_outlined,
  Icons.menu_book_outlined,
  Icons.more_horiz_rounded,
];

const List<Color> _kBuiltinExpenseColors = [
  AppColors.income,
  AppColors.primaryPink,
  AppColors.primaryBlue,
  AppColors.warning,
  AppColors.primaryPurple,
  Color(0xFFAAAAAA),
];

const List<IconData> _kBuiltinIncomeIcons = [
  Icons.payments_outlined,
  Icons.card_giftcard_rounded,
  Icons.more_horiz_rounded,
];

const List<Color> _kBuiltinIncomeColors = [
  AppColors.income,
  AppColors.expense,
  Color(0xFFAAAAAA),
];

Color _colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');

  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  return AppColors.primaryBlue;
}

/// Normalize stored hex for equality checks.
String _normalizeCategoryHex(String raw) {
  final s = raw.trim().replaceAll('#', '').toUpperCase();

  if (s.length == 6) {
    return '#$s';
  }

  return raw.trim().toUpperCase();
}

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _requestedLoad = false;

  final List<Color> _colorOptions = const [
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

  final List<IconData> _iconOptions = const [
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
    Icons.pending_actions_rounded,
    Icons.volunteer_activism_rounded,
    Icons.celebration_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_requestedLoad) return;

    _requestedLoad = true;

    final uid = context.read<AuthController>().user?.uid;

    if (uid != null) {
      context.read<UserCategoryController>().load(uid);
    }
  }

  String _categoryTypeForTab(int index) {
    return index == 0 ? 'expense' : 'income';
  }

  Future<void> _confirmDelete(UserCategoryModel model) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ctx.l10n.deleteCategoryTitle),
          content: Text(
            ctx.l10n.deleteCategoryMessage(
              BudgetNameLocalizer.display(ctx, model.name),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                ctx.l10n.deleteCategoryConfirmAction,
                style: const TextStyle(
                  color: AppColors.expense,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    final uid = context.read<AuthController>().user?.uid;

    if (uid == null) return;

    try {
      await context.read<UserCategoryController>().deleteCategory(
        uid: uid,
        categoryId: model.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.categoryDeleted),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.categoryDeleteFailed),
        ),
      );
    }
  }

  void _showAddSheet() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final sheetInitialType = _categoryTypeForTab(_tabController.index);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddCategorySheet(
          initialDraftType: sheetInitialType,
          colorOptions: _colorOptions,
          iconOptions: _iconOptions,
          mapCreateError: _mapCreateError,
          onSaved: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  duration: AppDurations.snackBar,
                  content: Text(context.l10n.categorySaved),
                ),
              );
            });
          },
        );
      },
    );
  }

  String _mapCreateError(BuildContext context, Object? code) {
    switch (code) {
      case 'duplicate_category':
        return context.l10n.categoryDuplicate;
      case 'reserved_category_name':
        return context.l10n.categoryReserved;
      case 'category_name_too_long':
        return context.l10n.categoryNameTooLong;
      case 'empty_category_name':
        return context.l10n.categoryNameRequired;
      case 'category_not_found':
        return context.l10n.categoryNotFound;
      default:
        return context.l10n.categorySaveFailed;
    }
  }

  void _showEditSheet(UserCategoryModel model) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddCategorySheet(
          initialDraftType: model.isExpense ? 'expense' : 'income',
          colorOptions: _colorOptions,
          iconOptions: _iconOptions,
          mapCreateError: _mapCreateError,
          editingCategory: model,
          onSaved: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  duration: AppDurations.snackBar,
                  content: Text(context.l10n.categoryUpdated),
                ),
              );
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserCategoryController>();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      floatingActionButton: GestureDetector(
        onTap: _showAddSheet,
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue,
            border: Border.all(
              color: Colors.white.withOpacity(
                AppColors.isDark(context) ? 0.14 : 0.90,
              ),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _CategoriesHeader(
                title: context.l10n.manageCategories,
                onBack: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _CategoryTypeSegment(
                controller: _tabController,
                expenseLabel: context.l10n.categoriesExpenseTab,
                incomeLabel: context.l10n.categoriesIncomeTab,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CategoryListPane(
                    builtinLabels: [
                      context.l10n.food,
                      context.l10n.shopping,
                      context.l10n.transport,
                      context.l10n.entertainment,
                      context.l10n.education,
                      context.l10n.other,
                    ],
                    builtinIcons: _kBuiltinExpenseIcons,
                    builtinColors: _kBuiltinExpenseColors,
                    items: controller.categoriesForExpense(),
                    onEdit: _showEditSheet,
                    onDelete: _confirmDelete,
                    emptyHint: context.l10n.categoriesExpenseEmpty,
                  ),
                  _CategoryListPane(
                    builtinLabels: [
                      context.l10n.salary,
                      context.l10n.gift,
                      context.l10n.other,
                    ],
                    builtinIcons: _kBuiltinIncomeIcons,
                    builtinColors: _kBuiltinIncomeColors,
                    items: controller.categoriesForIncome(),
                    onEdit: _showEditSheet,
                    onDelete: _confirmDelete,
                    emptyHint: context.l10n.categoriesIncomeEmpty,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _CategoriesHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
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
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.pageTitle(context).copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTypeSegment extends StatefulWidget {
  final TabController controller;
  final String expenseLabel;
  final String incomeLabel;

  const _CategoryTypeSegment({
    required this.controller,
    required this.expenseLabel,
    required this.incomeLabel,
  });

  @override
  State<_CategoryTypeSegment> createState() => _CategoryTypeSegmentState();
}

class _CategoryTypeSegmentState extends State<_CategoryTypeSegment> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_handleTabChanged);
  }

  @override
  void didUpdateWidget(covariant _CategoryTypeSegment oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTabChanged);
      widget.controller.addListener(_handleTabChanged);
    }
  }

  void _handleTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTabChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.controller.index;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          _SegmentItem(
            selected: selectedIndex == 0,
            label: widget.expenseLabel,
            icon: Icons.north_east_rounded,
            color: AppColors.expense,
            onTap: () => widget.controller.animateTo(0),
          ),
          _SegmentItem(
            selected: selectedIndex == 1,
            label: widget.incomeLabel,
            icon: Icons.south_west_rounded,
            color: AppColors.income,
            onTap: () => widget.controller.animateTo(1),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : AppColors.textSecondary(context),
                size: 17,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  final String initialDraftType;
  final List<Color> colorOptions;
  final List<IconData> iconOptions;
  final String Function(BuildContext context, Object? code) mapCreateError;
  final UserCategoryModel? editingCategory;
  final VoidCallback onSaved;

  const _AddCategorySheet({
    required this.initialDraftType,
    required this.colorOptions,
    required this.iconOptions,
    required this.mapCreateError,
    this.editingCategory,
    required this.onSaved,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  late final TextEditingController _nameController;

  late String _draftType;
  late IconData _pickedIcon;
  late Color _pickedColor;

  String? _snapshotName;
  String? _snapshotType;
  int? _snapshotIconCp;
  String? _snapshotHex;

  bool _seededEditLocaleFields = false;

  void _onFormFieldChanged() {
    setState(() {});
  }

  bool get _hasChangesFromSnapshot {
    final e = widget.editingCategory;

    if (e == null || _snapshotName == null) {
      return true;
    }

    final hex = _normalizeCategoryHex(
      '#${_pickedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
    );

    return _nameController.text.trim() != _snapshotName ||
        _draftType != _snapshotType ||
        _pickedIcon.codePoint != _snapshotIconCp ||
        hex != _snapshotHex;
  }

  bool get _saveEnabled {
    if (widget.editingCategory == null) {
      return _nameController.text.trim().isNotEmpty;
    }

    return _nameController.text.trim().isNotEmpty && _hasChangesFromSnapshot;
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();

    final edit = widget.editingCategory;

    if (edit != null) {
      _draftType = edit.isExpense ? 'expense' : 'income';
      _pickedIcon = AppIconRegistry.fromCodePoint(edit.iconCodePoint);
      _pickedColor = _colorFromHex(edit.colorHex);

      _snapshotType = edit.isExpense ? 'expense' : 'income';
      _snapshotIconCp = edit.iconCodePoint;
      _snapshotHex = _normalizeCategoryHex(edit.colorHex);
    } else {
      final t = widget.initialDraftType;

      _draftType = t == 'income' ? 'income' : 'expense';
      _pickedIcon = widget.iconOptions.first;
      _pickedColor = widget.colorOptions.first;
    }

    _nameController.addListener(_onFormFieldChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final edit = widget.editingCategory;

    if (edit != null && !_seededEditLocaleFields) {
      _seededEditLocaleFields = true;

      final lang = Localizations.localeOf(context).languageCode;
      final seed = lang == 'en' && (edit.nameEn ?? '').trim().isNotEmpty
          ? edit.nameEn!.trim()
          : edit.name.trim();

      _nameController.text = seed;
      _snapshotName = seed;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormFieldChanged);
    _nameController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final uid = context.read<AuthController>().user?.uid;

    if (uid == null) return;

    final raw = _nameController.text.trim();

    if (raw.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.categoryNameRequired),
        ),
      );
      return;
    }

    if (widget.editingCategory != null && !_hasChangesFromSnapshot) {
      return;
    }

    final hex =
        '#${_pickedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    final inputLocaleIsEnglish =
        Localizations.localeOf(context).languageCode == 'en';

    try {
      final edit = widget.editingCategory;

      if (edit != null) {
        await context.read<UserCategoryController>().updateCategory(
          uid: uid,
          categoryId: edit.id,
          name: raw,
          type: _draftType,
          iconCodePoint: _pickedIcon.codePoint,
          colorHex: hex,
          inputLocaleIsEnglish: inputLocaleIsEnglish,
        );
      } else {
        await context.read<UserCategoryController>().addCategory(
          uid: uid,
          name: raw,
          type: _draftType,
          iconCodePoint: _pickedIcon.codePoint,
          colorHex: hex,
          inputLocaleIsEnglish: inputLocaleIsEnglish,
        );
      }

      if (!mounted) return;

      nav.pop();

      widget.onSaved();
    } catch (e) {
      if (!mounted) return;

      final code =
      e is ArgumentError ? (e.message is String ? e.message as String : '') : '';

      messenger.showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(widget.mapCreateError(context, code)),
        ),
      );
    }
  }

  void _setDraftType(String next) {
    setState(() {
      _draftType = next == 'income' ? 'income' : 'expense';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          border: Border.all(
            color: AppColors.border(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                AppColors.isDark(context) ? 0.28 : 0.12,
              ),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                widget.editingCategory != null
                    ? context.l10n.editCustomCategory
                    : context.l10n.addCustomCategory,
                textAlign: TextAlign.center,
                style: AppTextStyles.pageTitle(context).copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 18),

              CustomTextField(
                controller: _nameController,
                hintText: context.l10n.categoryNameHint,
              ),

              const SizedBox(height: 16),

              Text(
                context.l10n.categoryTypeLabel,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: AppColors.innerBorder(context),
                  ),
                ),
                child: Row(
                  children: [
                    _SheetTypeOption(
                      selected: _draftType == 'expense',
                      label: context.l10n.expense,
                      icon: Icons.north_east_rounded,
                      color: AppColors.expense,
                      onTap: () => _setDraftType('expense'),
                    ),
                    _SheetTypeOption(
                      selected: _draftType == 'income',
                      label: context.l10n.income,
                      icon: Icons.south_west_rounded,
                      color: AppColors.income,
                      onTap: () => _setDraftType('income'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                context.l10n.categoryIconLabel,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.innerBorder(context),
                  ),
                ),
                child: GridView.builder(
                  itemCount: widget.iconOptions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, i) {
                    final icon = widget.iconOptions[i];
                    final selected = icon.codePoint == _pickedIcon.codePoint;

                    return Material(
                      color: selected
                          ? _pickedColor.withOpacity(0.18)
                          : AppColors.card(context),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _pickedIcon = icon;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Icon(
                          icon,
                          color: selected
                              ? _pickedColor
                              : AppColors.textSecondary(context),
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              Text(
                context.l10n.categoryColorLabel,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.innerBorder(context),
                  ),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.colorOptions.map((c) {
                    final selected = c.value == _pickedColor.value;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _pickedColor = c;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selected
                              ? [
                            BoxShadow(
                              color: c.withOpacity(0.35),
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
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: context.l10n.saveCategory,
                backgroundColor: _pickedColor,
                foregroundColor: AppColors.foregroundOnAccent(_pickedColor),
                onPressedAsync: _saveEnabled ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTypeOption extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SheetTypeOption({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : AppColors.textSecondary(context),
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryListPane extends StatelessWidget {
  final List<String> builtinLabels;
  final List<IconData> builtinIcons;
  final List<Color> builtinColors;
  final List<UserCategoryModel> items;
  final void Function(UserCategoryModel) onEdit;
  final void Function(UserCategoryModel) onDelete;
  final String emptyHint;

  const _CategoryListPane({
    required this.builtinLabels,
    required this.builtinIcons,
    required this.builtinColors,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.emptyHint,
  }) : assert(
  builtinLabels.length == builtinIcons.length &&
      builtinLabels.length == builtinColors.length,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
      children: [
        Text(
          context.l10n.builtinCategoriesHeading,
          style: AppTextStyles.sectionTitle(context).copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(builtinLabels.length, (i) {
            final label = builtinLabels[i];
            final icon = builtinIcons[i];
            final color = builtinColors[i];

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(
                  color: AppColors.border(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      AppColors.isDark(context) ? 0.12 : 0.035,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.16),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 22),

        Text(
          context.l10n.yourCategoriesHeading,
          style: AppTextStyles.sectionTitle(context).copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 32,
            ),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.border(context),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 50,
                  color: AppColors.textSecondary(context).withOpacity(0.65),
                ),
                const SizedBox(height: 14),
                Text(
                  emptyHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(items.length * 2 - 1, (i) {
            if (i.isOdd) {
              return const SizedBox(height: 10);
            }

            final index = i ~/ 2;
            final item = items[index];
            final color = _colorFromHex(item.colorHex);
            final icon = AppIconRegistry.fromCodePoint(item.iconCodePoint);

            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.border(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(
                      AppColors.isDark(context) ? 0.10 : 0.055,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
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
                    size: 24,
                  ),
                ),
                title: Text(
                  BudgetNameLocalizer.display(context, item.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CategoryActionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.primaryBlue,
                      onTap: () => onEdit(item),
                    ),
                    const SizedBox(width: 6),
                    _CategoryActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.expense,
                      onTap: () => onDelete(item),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _CategoryActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(
            color: color.withOpacity(0.18),
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 19,
        ),
      ),
    );
  }
}