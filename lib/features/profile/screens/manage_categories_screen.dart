import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
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

/// Normalize stored hex (e.g. #aBc / ABC) for equality checks.
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

  String _categoryTypeForTab(int index) =>
      index == 0 ? 'expense' : 'income';

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
                style: TextStyle(color: AppColors.expense),
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
      builder: (sheetBodyContext) {
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
      builder: (sheetBodyContext) {
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.card(context),
            foregroundColor: AppColors.textPrimary(context),
            side: BorderSide(color: AppColors.border(context)),
            shape: const CircleBorder(),
            fixedSize: const Size(44, 44),
          ),
        ),
        title: Text(
          context.l10n.manageCategories,
          style: AppTextStyles.sectionTitle(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.categoriesExpenseTab),
            Tab(text: context.l10n.categoriesIncomeTab),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _showAddSheet,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue,
            border: Border.all(
              color: Colors.white.withValues(
                alpha: AppColors.isDark(context) ? 0.14 : 0.90,
              ),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      body: TabBarView(
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

  void _onFormFieldChanged() => setState(() {});

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
      return true;
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
      _pickedIcon = IconData(
        edit.iconCodePoint,
        fontFamily: 'MaterialIcons',
      );
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

  void _setDraftType(String next) =>
      setState(() => _draftType = next == 'income' ? 'income' : 'expense');

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
            top: Radius.circular(24),
          ),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.editingCategory != null
                    ? context.l10n.editCustomCategory
                    : context.l10n.addCustomCategory,
                style: AppTextStyles.sectionTitle(context).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                hintText: context.l10n.categoryNameHint,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.categoryTypeLabel,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(context.l10n.expense),
                      selected: _draftType == 'expense',
                      onSelected: (_) => _setDraftType('expense'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(context.l10n.income),
                      selected: _draftType == 'income',
                      onSelected: (_) => _setDraftType('income'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.categoryIconLabel,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: widget.iconOptions.length,
                  itemBuilder: (context, i) {
                    final icon = widget.iconOptions[i];
                    final selected = icon.codePoint == _pickedIcon.codePoint;
                    return Material(
                      color: selected
                          ? _pickedColor.withValues(alpha: 0.2)
                          : AppColors.isDark(context)
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => setState(() {
                          _pickedIcon = icon;
                        }),
                        borderRadius: BorderRadius.circular(12),
                        child: Icon(
                          icon,
                          color: selected
                              ? _pickedColor
                              : AppColors.textSecondary(context),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.categoryColorLabel,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.colorOptions.map((c) {
                  final selected = c == _pickedColor;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _pickedColor = c;
                    }),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: c.withOpacity(0.45),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
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
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [
        Text(
          context.l10n.builtinCategoriesHeading,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w800,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: color.withOpacity(0.16),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
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
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 40),
            child: Text(
              emptyHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context),
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
            final icon = IconData(
              item.iconCodePoint,
              fontFamily: 'MaterialIcons',
            );

            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: color.withOpacity(0.14),
                  ),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  BudgetNameLocalizer.display(context, item.name),
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: context.l10n.editCustomCategory,
                      child: IconButton(
                        onPressed: () => onEdit(item),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onDelete(item),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.expense,
                      ),
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
