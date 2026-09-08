import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';
import 'moment_viewer_screen.dart';

enum TimeFilterOption {
  all,
  today,
  last7days,
  thisMonth,
  lastMonth,
  thisYear,
}

enum TypeFilterOption {
  all,
  expense,
  income,
}

class TransactionBrowseScreen extends StatefulWidget {
  final List<TransactionModel>? initialTransactions;

  const TransactionBrowseScreen({
    super.key,
    this.initialTransactions,
  });

  @override
  State<TransactionBrowseScreen> createState() => _TransactionBrowseScreenState();
}

class _TransactionBrowseScreenState extends State<TransactionBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _timeFilterKey = GlobalKey();

  String _searchQuery = '';
  TimeFilterOption _timeFilter = TimeFilterOption.all;
  TypeFilterOption _typeFilter = TypeFilterOption.all;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
        });
      }
    });
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _matchesTimeFilter(DateTime date, DateTime now) {
    switch (_timeFilter) {
      case TimeFilterOption.all:
        return true;
      case TimeFilterOption.today:
        return _isSameDay(date, now);
      case TimeFilterOption.last7days:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return date.isAfter(start) || _isSameDay(date, start);
      case TimeFilterOption.thisMonth:
        return date.year == now.year && date.month == now.month;
      case TimeFilterOption.lastMonth:
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        return date.year == prevYear && date.month == prevMonth;
      case TimeFilterOption.thisYear:
        return date.year == now.year;
    }
  }

  String _getTimeFilterLabel(BuildContext context, TimeFilterOption option) {
    final l10n = context.l10n;
    switch (option) {
      case TimeFilterOption.all:
        return l10n.timeFilterAll;
      case TimeFilterOption.today:
        return l10n.timeFilterToday;
      case TimeFilterOption.last7days:
        return l10n.timeFilterLast7Days;
      case TimeFilterOption.thisMonth:
        return l10n.timeFilterThisMonth;
      case TimeFilterOption.lastMonth:
        return l10n.timeFilterLastMonth;
      case TimeFilterOption.thisYear:
        return l10n.timeFilterThisYear;
    }
  }

  String _formatDateShort(BuildContext context, DateTime date) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    if (isVi) {
      return '${date.day} thg ${date.month}';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }

  Color _parseHexColor(String? value, {Color fallback = const Color(0xFF4CAF50)}) {
    if (value == null || value.trim().isEmpty) return fallback;
    var cleaned = value.trim().replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length != 8) return fallback;
    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Color _getCategoryColor(String category, List<TransactionModel> transactions) {
    final lower = category.toLowerCase().trim();
    for (final tx in transactions) {
      if (tx.category.toLowerCase().trim() == lower &&
          tx.categoryColorHex != null &&
          tx.categoryColorHex!.trim().isNotEmpty) {
        final parsed = _parseHexColor(tx.categoryColorHex);
        if (parsed != const Color(0xFF4CAF50)) {
          return parsed;
        }
      }
    }

    if (lower.contains('lương') || lower.contains('salary') || lower.contains('thu nhập')) {
      return AppColors.income;
    }
    if (lower.contains('ăn') || lower.contains('food') || lower.contains('uống') || lower.contains('cafe')) {
      return const Color(0xFFFF8A00);
    }
    if (lower.contains('mua') || lower.contains('shop')) {
      return const Color(0xFFEC4899);
    }
    if (lower.contains('đi') || lower.contains('transport') || lower.contains('xe')) {
      return const Color(0xFF3B82F6);
    }
    if (lower.contains('học') || lower.contains('education') || lower.contains('sách')) {
      return const Color(0xFF8B5CF6);
    }
    if (lower.contains('giải trí') || lower.contains('entertainment') || lower.contains('game')) {
      return const Color(0xFFF43F5E);
    }
    if (lower.contains('quà') || lower.contains('gift')) {
      return const Color(0xFFF59E0B);
    }
    if (lower.contains('nhà') || lower.contains('bills') || lower.contains('điện') || lower.contains('nước')) {
      return const Color(0xFF06B6D4);
    }
    return AppColors.primaryBlue;
  }

  IconData _getCategoryIcon(String category, [List<TransactionModel>? transactions]) {
    final lower = category.toLowerCase().trim();
    if (transactions != null) {
      for (final tx in transactions) {
        if (tx.category.toLowerCase().trim() == lower &&
            tx.categoryIconCodePoint != null &&
            tx.categoryIconCodePoint! > 0) {
          return AppIconRegistry.fromCodePoint(tx.categoryIconCodePoint!);
        }
      }
    }
    if (lower.contains('lương') || lower.contains('salary')) {
      return Icons.payments_outlined;
    }
    if (lower.contains('ăn') || lower.contains('food') || lower.contains('uống')) {
      return Icons.shopping_cart_outlined;
    }
    if (lower.contains('mua') || lower.contains('shop')) {
      return Icons.shopping_bag_outlined;
    }
    if (lower.contains('đi') || lower.contains('transport') || lower.contains('xe')) {
      return Icons.directions_car_outlined;
    }
    if (lower.contains('học') || lower.contains('education')) {
      return Icons.school_outlined;
    }
    if (lower.contains('giải trí') || lower.contains('entertainment')) {
      return Icons.sports_esports_outlined;
    }
    if (lower.contains('quà') || lower.contains('gift')) {
      return Icons.card_giftcard_outlined;
    }
    return Icons.category_outlined;
  }

  void _showTimeFilterMenu() async {
    final renderBox = _timeFilterKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + size.height + 6,
      offset.dx + size.width,
      0,
    );

    final l10n = context.l10n;

    final options = [
      {'option': TimeFilterOption.all, 'label': l10n.timeFilterAll, 'symbol': '∞'},
      {'option': TimeFilterOption.today, 'label': l10n.timeFilterToday, 'icon': Icons.wb_sunny_outlined},
      {'option': TimeFilterOption.last7days, 'label': l10n.timeFilterLast7Days, 'icon': Icons.view_week_outlined},
      {'option': TimeFilterOption.thisMonth, 'label': l10n.timeFilterThisMonth, 'icon': Icons.calendar_month_outlined},
      {'option': TimeFilterOption.lastMonth, 'label': l10n.timeFilterLastMonth, 'icon': Icons.calendar_today_outlined},
      {'option': TimeFilterOption.thisYear, 'label': l10n.timeFilterThisYear, 'icon': Icons.event_available_outlined},
    ];

    final selected = await showMenu<TimeFilterOption>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.border(context),
          width: 0.8,
        ),
      ),
      color: AppColors.card(context),
      elevation: 8,
      items: options.map((item) {
        final opt = item['option'] as TimeFilterOption;
        final label = item['label'] as String;
        final icon = item['icon'] as IconData?;
        final symbol = item['symbol'] as String?;
        final isCurrent = _timeFilter == opt;

        return PopupMenuItem<TimeFilterOption>(
          value: opt,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                child: isCurrent
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 6),
              if (symbol != null)
                Text(
                  symbol,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  color: AppColors.textSecondary(context),
                  size: 18,
                ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isCurrent
                      ? AppColors.primaryBlue
                      : AppColors.textPrimary(context),
                  fontSize: 14.5,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null && selected != _timeFilter) {
      HapticFeedback.lightImpact();
      setState(() {
        _timeFilter = selected;
      });
    }
  }

  void _showAllCategoriesSheet(List<String> categories, List<TransactionModel> rawTransactions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.allCategories,
                      style: TextStyle(
                        color: AppColors.textPrimary(ctx),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedCategory != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedCategory = null);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          l10n.timeFilterAll,
                          style: const TextStyle(color: AppColors.primaryBlue),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final displayName = BudgetNameLocalizer.display(context, cat);
                    final catColor = _getCategoryColor(cat, rawTransactions);
                    return ChoiceChip(
                      label: Text(displayName),
                      selected: isSelected,
                      selectedColor: catColor,
                      backgroundColor: catColor.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: isSelected
                            ? catColor
                            : catColor.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : catColor,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = isSelected ? null : cat;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final homeController = context.watch<HomeController>();
    final rawTransactions = (widget.initialTransactions != null && widget.initialTransactions!.isNotEmpty)
        ? widget.initialTransactions!
        : homeController.transactions;

    final profileController = context.watch<ProfileController>();
    final currency = profileController.currency;
    final now = DateTime.now();

    // Lọc giao dịch
    final filteredTransactions = rawTransactions.where((tx) {
      // 1. Lọc thời gian
      if (!_matchesTimeFilter(tx.createdAt, now)) return false;

      // 2. Lọc loại thu/chi
      if (_typeFilter == TypeFilterOption.expense && tx.type != 'expense') return false;
      if (_typeFilter == TypeFilterOption.income && tx.type != 'income') return false;

      // 3. Lọc danh mục
      if (_selectedCategory != null &&
          tx.category.toLowerCase() != _selectedCategory!.toLowerCase()) {
        return false;
      }

      // 4. Lọc từ khoá tìm kiếm
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final caption = tx.caption.toLowerCase();
        final note = tx.note.toLowerCase();
        final category = tx.category.toLowerCase();
        final localizedCat = BudgetNameLocalizer.display(context, tx.category).toLowerCase();
        final location = tx.locationName.toLowerCase();
        final group = (tx.groupName ?? '').toLowerCase();
        final amountStr = tx.amount.toStringAsFixed(0);

        final matches = caption.contains(q) ||
            note.contains(q) ||
            category.contains(q) ||
            localizedCat.contains(q) ||
            location.contains(q) ||
            group.contains(q) ||
            amountStr.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();

    // Sắp xếp theo ngày giảm dần
    filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Thống kê tổng
    double totalExpense = 0;
    double totalIncome = 0;
    for (final tx in filteredTransactions) {
      if (tx.type == 'expense') {
        totalExpense += tx.amount;
      } else if (tx.type == 'income') {
        totalIncome += tx.amount;
      }
    }
    final netAmount = totalIncome - totalExpense;

    // Danh sách danh mục độc nhất
    final uniqueCategories = rawTransactions
        .map((e) => e.category.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueCategories.isEmpty) {
      uniqueCategories.addAll(['Lương', 'Ăn uống', 'Mua sắm', 'Giải trí']);
    }

    // Nhãn nút thời gian
    final timeLabel = _timeFilter == TimeFilterOption.all
        ? '∞ ${l10n.timeFilterLabel}'
        : _getTimeFilterLabel(context, _timeFilter);

    // Tiêu đề thời gian trên thẻ xanh dương
    final periodCardTitle = _timeFilter == TimeFilterOption.all
        ? l10n.timeFilterAll
        : _getTimeFilterLabel(context, _timeFilter);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: [X] Button + "Duyệt giao dịch" Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(24),
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
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.browseTransactionsTitle,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: () => _searchFocusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus
                          ? AppColors.primaryBlue.withValues(alpha: 0.6)
                          : AppColors.border(context),
                      width: _searchFocusNode.hasFocus ? 1.2 : 0.8,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: _searchFocusNode.hasFocus
                            ? AppColors.primaryBlue
                            : AppColors.textSecondary(context),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                          ),
                          cursorColor: AppColors.primaryBlue,
                          decoration: InputDecoration(
                            hintText: l10n.browseTransactionsSearchHint,
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary(context).withValues(alpha: 0.65),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _searchController.clear();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Icon(
                              Icons.cancel_rounded,
                              color: AppColors.textSecondary(context),
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Phần nội dung cuộn (Filters + Thẻ tổng quan + Categories + Grid ảnh)
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),

                        // Filter Row 1: [∞ Thời gian ⌵] + Segment [Tất cả | Chi tiêu | Thu nhập]
                        // Bọc LayoutBuilder + FittedBox chống tràn ngang trên máy nhỏ
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Nút Dropdown Thời gian
                                      GestureDetector(
                                        key: _timeFilterKey,
                                        onTap: _showTimeFilterMenu,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface(context),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: AppColors.border(context),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                timeLabel,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary(context),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                color: AppColors.textSecondary(context),
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      // Segmented Filter: Tất cả | Chi tiêu | Thu nhập
                                      Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface(context),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: AppColors.border(context),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildTypeSegmentItem(
                                              label: l10n.typeFilterAll,
                                              isSelected: _typeFilter == TypeFilterOption.all,
                                              onTap: () {
                                                if (_typeFilter != TypeFilterOption.all) {
                                                  HapticFeedback.lightImpact();
                                                  setState(() => _typeFilter = TypeFilterOption.all);
                                                }
                                              },
                                            ),
                                            _buildTypeSegmentItem(
                                              label: l10n.typeFilterExpense,
                                              isSelected: _typeFilter == TypeFilterOption.expense,
                                              onTap: () {
                                                if (_typeFilter != TypeFilterOption.expense) {
                                                  HapticFeedback.lightImpact();
                                                  setState(() => _typeFilter = TypeFilterOption.expense);
                                                }
                                              },
                                            ),
                                            _buildTypeSegmentItem(
                                              label: l10n.typeFilterIncome,
                                              isSelected: _typeFilter == TypeFilterOption.income,
                                              onTap: () {
                                                if (_typeFilter != TypeFilterOption.income) {
                                                  HapticFeedback.lightImpact();
                                                  setState(() => _typeFilter = TypeFilterOption.income);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Summary Blue Gradient Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5394ED),
                                  Color(0xFF4384DE),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A8AE2).withValues(alpha: 0.28),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hàng trên: Icon Lịch + Thời gian & Pill Chi Tiêu
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_month_outlined,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              periodCardTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Pill chi tiêu (↓ 777,665đ)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '↓ ${AppCurrencyFormatter.formatFromVnd(amountVnd: totalExpense, currency: currency)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Số tiền lớn nổi bật ở giữa (+777,665đ hoặc -...đ)
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatBigAmount(netAmount, currency),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Pill thu nhập ở góc dưới phải (↑ 0đ)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '↑ ${AppCurrencyFormatter.formatFromVnd(amountVnd: totalIncome, currency: currency)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Horizontal Category Filter Pills (với màu thật của từng Category)
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              ...uniqueCategories.take(4).map((cat) {
                                final isSelected = _selectedCategory?.toLowerCase() == cat.toLowerCase();
                                final catName = BudgetNameLocalizer.display(context, cat);
                                final catColor = _getCategoryColor(cat, rawTransactions);
                                final icon = _getCategoryIcon(cat, rawTransactions);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _selectedCategory = isSelected ? null : cat;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? catColor.withValues(alpha: 0.26)
                                            : catColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? catColor.withValues(alpha: 0.8)
                                              : catColor.withValues(alpha: 0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: catColor.withValues(alpha: 0.22),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                icon,
                                                color: catColor,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            catName,
                                            style: TextStyle(
                                              color: catColor,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // Nút "Danh mục" để xem tất cả hoặc chọn thêm
                              GestureDetector(
                                onTap: () {
                                  _showAllCategoriesSheet(uniqueCategories, rawTransactions);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selectedCategory != null &&
                                              !uniqueCategories.take(4).contains(_selectedCategory)
                                          ? AppColors.primaryBlue
                                          : AppColors.border(context),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        color: AppColors.textSecondary(context),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.allCategories,
                                        style: TextStyle(
                                          color: AppColors.textPrimary(context),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // 2-Column Grid of Moments / Transactions hoặc Trạng thái rỗng
                  if (filteredTransactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.noTransactionsFound,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        2,
                        16,
                        MediaQuery.of(context).padding.bottom + 24,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.74,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) {
                            final tx = filteredTransactions[index];
                            return _buildMomentGridItem(
                              context: ctx,
                              transaction: tx,
                              currency: currency,
                              index: index,
                              allFiltered: filteredTransactions,
                            );
                          },
                          childCount: filteredTransactions.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBigAmount(double net, String currency) {
    final absFormatted = AppCurrencyFormatter.formatFromVnd(
      amountVnd: net.abs(),
      currency: currency,
    );
    if (net > 0) {
      return '+$absFormatted';
    } else if (net < 0) {
      return '-$absFormatted';
    }
    return absFormatted;
  }

  Widget _buildTypeSegmentItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary(context),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMomentGridItem({
    required BuildContext context,
    required TransactionModel transaction,
    required String currency,
    required int index,
    required List<TransactionModel> allFiltered,
  }) {
    final formattedMoney = AppCurrencyFormatter.formatFromVnd(
      amountVnd: transaction.amount,
      currency: currency,
    );
    final amountDisplay = transaction.type == 'expense'
        ? '-$formattedMoney'
        : '+$formattedMoney';

    final dateDisplay = _formatDateShort(context, transaction.createdAt);
    final categoryDisplay = BudgetNameLocalizer.display(context, transaction.category);
    final categoryColor = _parseHexColor(
      transaction.categoryColorHex,
      fallback: transaction.type == 'expense'
          ? const Color(0xFF4CAF50)
          : const Color(0xFF4CAF50),
    );

    final caption = transaction.caption.trim();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MomentViewerScreen(
              transactions: allFiltered,
              initialIndex: index,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Card with Overlay
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  TransactionMomentImage(
                    imageUrl: transaction.displayImageUrl,
                    category: transaction.category,
                    categoryIconCodePoint: transaction.categoryIconCodePoint,
                    categoryColorHex: transaction.categoryColorHex,
                    caption: transaction.caption,
                    width: double.infinity,
                    height: double.infinity,
                  ),

                  // Bottom Gradient Shadow for readability
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 70,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.88),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Overlay Content
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Amount on Bottom-Left
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              amountDisplay,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Date & Category on Bottom-Right
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dateDisplay,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 65),
                                  child: Text(
                                    categoryDisplay,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Caption underneath card
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
