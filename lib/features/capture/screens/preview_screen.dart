import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../profile/controllers/user_category_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/capture_controller.dart';
import 'camera_screen.dart';

class PreviewScreen extends StatefulWidget {
  final File? imageFile;
  final File? videoFile;
  final String mediaType;
  final int? durationMs;

  const PreviewScreen({
    super.key,
    required this.imageFile,
    this.videoFile,
    this.mediaType = 'image',
    this.durationMs,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final amountController = TextEditingController();
  final captionController = TextEditingController();

  static const int kMaxAmountDigits = 10;
  static const double kMaxAmountValue = 9999999999;
  static const int kMaxCaptionLength = 70;

  static const Color _captureBackground = Color(0xFF15171C);
  static const Color _darkSwitch = Color(0xFF1A1B24);

  String type = 'expense';
  String category = 'Ăn uống';
  String privacy = 'friends';

  bool categoryOpen = false;
  bool privacyOpen = false;
  bool _loadedBudgets = false;
  bool _loadedUserCategories = false;
  bool _submitTapBusy = false;

  double amountValue = 0;

  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _isVideoMuted = true;

  bool get isVideo => widget.mediaType == 'video' && widget.videoFile != null;
  bool get isImage => widget.mediaType == 'image' && widget.imageFile != null;

  bool get hasMedia => isImage || isVideo;

  final Map<String, Map<String, dynamic>> categoryMeta = {
    'Ăn uống': {
      'icon': Icons.shopping_cart_outlined,
      'color': AppColors.income,
    },
    'Mua sắm': {
      'icon': Icons.shopping_bag_outlined,
      'color': AppColors.primaryPink,
    },
    'Đi lại': {
      'icon': Icons.directions_bus_outlined,
      'color': AppColors.primaryBlue,
    },
    'Giải trí': {
      'icon': Icons.movie_outlined,
      'color': AppColors.warning,
    },
    'Học tập': {
      'icon': Icons.menu_book_outlined,
      'color': AppColors.primaryPurple,
    },
    'Lương': {
      'icon': Icons.payments_outlined,
      'color': AppColors.income,
    },
    'Quà tặng': {
      'icon': Icons.card_giftcard_rounded,
      'color': AppColors.expense,
    },
    'Khác': {
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFAAAAAA),
    },
  };

  Color get accentColor {
    return type == 'expense' ? AppColors.expense : AppColors.income;
  }

  Color get submitColor {
    return type == 'expense' ? AppColors.expense : AppColors.income;
  }

  bool get hasAmountInput {
    return amountController.text.trim().isNotEmpty;
  }

  String get privacyLabel {
    return privacy == 'private' ? context.l10n.private : context.l10n.everyone;
  }

  IconData get privacyIcon {
    return privacy == 'private'
        ? Icons.lock_outline_rounded
        : Icons.groups_2_outlined;
  }

  IconData get currentCategoryIcon {
    return _iconForCategory(category);
  }

  Color get currentCategoryColor {
    return _colorForCategory(category);
  }

  String _toCanonicalCategory(String label) {
    final l10n = context.l10n;
    switch (label.trim()) {
      case 'Ăn uống':
      case 'Food':
        return 'Ăn uống';
      case 'Mua sắm':
      case 'Shopping':
        return 'Mua sắm';
      case 'Đi lại':
      case 'Transport':
        return 'Đi lại';
      case 'Học tập':
      case 'Education':
        return 'Học tập';
      case 'Giải trí':
      case 'Entertainment':
        return 'Giải trí';
      case 'Lương':
      case 'Salary':
        return 'Lương';
      case 'Quà tặng':
      case 'Gift':
        return 'Quà tặng';
      case 'Khác':
      case 'Other':
        return 'Khác';
      default:
        if (label == l10n.food) return 'Ăn uống';
        if (label == l10n.shopping) return 'Mua sắm';
        if (label == l10n.transport) return 'Đi lại';
        if (label == l10n.education) return 'Học tập';
        if (label == l10n.entertainment) return 'Giải trí';
        if (label == l10n.salary) return 'Lương';
        if (label == l10n.gift) return 'Quà tặng';
        if (label == l10n.other) return 'Khác';
        return label;
    }
  }

  String _localizedCategoryLabel(String categoryValue) {
    final l10n = context.l10n;
    switch (_toCanonicalCategory(categoryValue)) {
      case 'Ăn uống':
        return l10n.food;
      case 'Mua sắm':
        return l10n.shopping;
      case 'Đi lại':
        return l10n.transport;
      case 'Học tập':
        return l10n.education;
      case 'Giải trí':
        return l10n.entertainment;
      case 'Lương':
        return l10n.salary;
      case 'Quà tặng':
        return l10n.gift;
      case 'Khác':
        return l10n.other;
      default:
        return BudgetNameLocalizer.display(context, categoryValue);
    }
  }

  @override
  void initState() {
    super.initState();
    _prepareVideoIfNeeded();
  }

  Future<void> _prepareVideoIfNeeded() async {
    if (!isVideo) return;

    final file = widget.videoFile;
    if (file == null || !await file.exists()) return;

    final controller = VideoPlayerController.file(file);
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (!mounted) return;

      setState(() {
        _isVideoReady = true;
        _isVideoMuted = true;
      });
    } catch (e) {
      debugPrint('Preview video init error: $e');
    }
  }

  Future<void> _toggleVideoMute() async {
    final controller = _videoController;
    if (controller == null) return;

    final nextMuted = !_isVideoMuted;

    await controller.setVolume(nextMuted ? 0 : 1);

    if (!mounted) return;

    setState(() {
      _isVideoMuted = nextMuted;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loadedBudgets) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null) {
        context.read<BudgetController>().load(uid);
      }

      _loadedBudgets = true;
    }

    if (!_loadedUserCategories) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null) {
        context.read<UserCategoryController>().load(uid);
      }

      _loadedUserCategories = true;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  List<String> _mergedExpenseCategoryLabels(
    BuildContext context, {
    required bool listen,
  }) {
    final l10n = context.l10n;

    BudgetController budgetController(BuildContext ctx) =>
        listen ? ctx.watch<BudgetController>() : ctx.read<BudgetController>();

    UserCategoryController userCategoryController(BuildContext ctx) =>
        listen ? ctx.watch<UserCategoryController>() : ctx.read<UserCategoryController>();

    final seen = <String>{};
    final out = <String>[];

    void addRaw(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;

      final key = _toCanonicalCategory(trimmed);
      if (seen.contains(key)) return;

      seen.add(key);
      out.add(trimmed);
    }

    for (final label in [
      l10n.food,
      l10n.shopping,
      l10n.transport,
      l10n.entertainment,
      l10n.education,
      l10n.other,
    ]) {
      addRaw(label);
    }

    for (final uc in userCategoryController(context).categoriesForExpense()) {
      addRaw(uc.name);
    }

    for (final budget in budgetController(context).budgets) {
      addRaw(budget.name);
    }

    return out;
  }

  List<String> _mergedIncomeCategoryLabels(
    BuildContext context, {
    required bool listen,
  }) {
    final l10n = context.l10n;

    UserCategoryController userCategoryController(BuildContext ctx) =>
        listen ? ctx.watch<UserCategoryController>() : ctx.read<UserCategoryController>();

    final seen = <String>{};
    final out = <String>[];

    void addRaw(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;

      final key = _toCanonicalCategory(trimmed);
      if (seen.contains(key)) return;

      seen.add(key);
      out.add(trimmed);
    }

    for (final label in [
      l10n.salary,
      l10n.gift,
      l10n.other,
    ]) {
      addRaw(label);
    }

    for (final uc in userCategoryController(context).categoriesForIncome()) {
      addRaw(uc.name);
    }

    return out;
  }

  List<String> currentCategories(BuildContext context) {
    if (type == 'income') {
      return _mergedIncomeCategoryLabels(context, listen: true);
    }

    return _mergedExpenseCategoryLabels(context, listen: true);
  }

  List<String> expenseCategoriesForAction() {
    return _mergedExpenseCategoryLabels(context, listen: false);
  }

  List<String> incomeCategoriesForAction() {
    return _mergedIncomeCategoryLabels(context, listen: false);
  }

  IconData _iconForCategory(String label) {
    final lookupLabel = _toCanonicalCategory(label);

    final defaultIcon = categoryMeta[lookupLabel]?['icon'] as IconData?;

    if (defaultIcon != null) {
      return defaultIcon;
    }

    final budget = context.read<BudgetController>().findBudgetByName(label);

    if (budget != null) {
      return IconData(
        budget.iconCodePoint,
        fontFamily: 'MaterialIcons',
      );
    }

    final userCat = context.read<UserCategoryController>().findByName(label);

    if (userCat != null) {
      return IconData(
        userCat.iconCodePoint,
        fontFamily: 'MaterialIcons',
      );
    }

    return Icons.account_balance_wallet_outlined;
  }

  Color _colorForCategory(String label) {
    final lookupLabel = _toCanonicalCategory(label);

    final defaultColor = categoryMeta[lookupLabel]?['color'] as Color?;

    if (defaultColor != null) {
      return defaultColor;
    }

    final budget = context.read<BudgetController>().findBudgetByName(label);

    if (budget != null) {
      final cleaned = budget.colorHex.replaceAll('#', '');

      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
    }

    final userCat = context.read<UserCategoryController>().findByName(label);

    if (userCat != null) {
      final cleaned = userCat.colorHex.replaceAll('#', '');

      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
    }

    return AppColors.primaryBlue;
  }

  void _closeCaptureFlow() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.mainShell,
          (route) => false,
    );
  }

  void _showMaxDigitsWarning() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.maxAmountDigits),
        ),
      );
    });
  }

  void _onAmountChanged(String value) {
    final currency = context.read<ProfileController>().currency;

    final raw = currency == 'USD'
        ? value.replaceAll(RegExp(r'[^0-9.]'), '')
        : value.replaceAll(RegExp(r'[^0-9]'), '');

    final inputAmount = double.tryParse(raw) ?? 0;

    setState(() {
      amountValue = AppCurrencyFormatter.toVnd(
        inputAmount: inputAmount,
        currency: currency,
      );
    });
  }

  String _formatMoney(double value) {
    final currency = context.read<ProfileController>().currency;

    return AppCurrencyFormatter.formatFromVnd(
      amountVnd: value,
      currency: currency,
    );
  }

  String _formatDurationLabel() {
    final duration = widget.durationMs;

    if (duration == null || duration <= 0) {
      return 'Video';
    }

    final seconds = (duration / 1000).clamp(0, 5).toStringAsFixed(1);
    return '${seconds}s';
  }

  Future<bool> _confirmIfBudgetWillExceed() async {
    if (type != 'expense') return true;

    final budget = context.read<BudgetController>().findBudgetByName(category);

    if (budget == null) return true;
    if (budget.limitAmount <= 0) return true;

    final nextSpent = budget.spentAmount + amountValue;

    if (nextSpent <= budget.limitAmount) return true;

    final overAmount = nextSpent - budget.limitAmount;
    final overText = _formatMoney(overAmount);
    final limitText = _formatMoney(budget.limitAmount);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(context.l10n.overBudgetLimitTitle),
          content: Text(
            context.l10n.overBudgetLimitWarning(category, limitText, overText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.saveAnyway),
            ),
          ],
        );
      },
    );

    return ok == true;
  }

  Future<void> _shareMoment() async {
    if (!hasMedia) {
      return;
    }

    try {
      final currency = context.read<ProfileController>().currency;

      final rawAmount = currency == 'USD'
          ? amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')
          : amountController.text.replaceAll(RegExp(r'[^0-9]'), '');

      final inputAmount = double.tryParse(rawAmount) ?? 0;

      final amountVnd = AppCurrencyFormatter.toVnd(
        inputAmount: inputAmount,
        currency: currency,
      );

      final amountText = AppCurrencyFormatter.formatFromVnd(
        amountVnd: amountVnd,
        currency: currency,
      );

      final captionText = captionController.text.trim();
      final sign = type == 'expense' ? '-' : '+';
      final privacyText = privacy == 'private' ? context.l10n.private : context.l10n.everyone;

      final shareText = StringBuffer()
        ..writeln('Meme')
        ..writeln()
        ..writeln(context.l10n.shareType(type == 'expense' ? context.l10n.expense : context.l10n.income))
        ..writeln(context.l10n.shareCategory(_localizedCategoryLabel(category)));

      if (amountController.text.trim().isNotEmpty) {
        shareText.writeln(context.l10n.shareAmount('$sign$amountText'));
      }

      if (captionText.isNotEmpty) {
        shareText.writeln(context.l10n.shareDetails(captionText));
      }

      shareText.writeln(context.l10n.sharePrivacy(privacyText));

      final mediaFile = isVideo ? widget.videoFile : widget.imageFile;

      if (mediaFile != null && await mediaFile.exists()) {
        final tempDir = await getTemporaryDirectory();
        final ext = mediaFile.path.split('.').last.toLowerCase();
        final safeExt = ext.isEmpty ? (isVideo ? 'mp4' : 'jpg') : ext;

        final shareFile = File(
          '${tempDir.path}/meme_share_${DateTime.now().millisecondsSinceEpoch}.$safeExt',
        );

        await mediaFile.copy(shareFile.path);

        await Share.shareXFiles(
          [XFile(shareFile.path)],
          text: shareText.toString(),
        );

        return;
      }

      await Share.share(shareText.toString());
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.cannotShareNow),
        ),
      );
    }
  }

  Future<void> _saveTransaction() async {
    final currentCurrency = context.read<ProfileController>().currency;

    final rawAmount = currentCurrency == 'USD'
        ? amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')
        : amountController.text.replaceAll(RegExp(r'[^0-9]'), '');

    final inputAmount = double.tryParse(rawAmount) ?? 0;

    amountValue = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currentCurrency,
    );

    if (amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.enterValidAmount),
        ),
      );
      return;
    }

    if (amountValue > kMaxAmountValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.amountLimitExceeded),
        ),
      );
      return;
    }

    final shouldContinue = await _confirmIfBudgetWillExceed();
    if (!shouldContinue) return;

    final capture = context.read<CaptureController>();
    final uid = context.read<AuthController>().user?.uid;

    if (uid == null) return;

    if (isVideo && widget.videoFile != null) {
      capture.setVideo(
        widget.videoFile!,
        durationMs: widget.durationMs,
      );
    } else if (widget.imageFile != null) {
      capture.setImage(widget.imageFile!);
    } else {
      capture.clearMedia();
    }

    final selectedIcon = _iconForCategory(category);
    final selectedColor = _colorForCategory(category);

    final selectedColorHex =
        '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

    final location = capture.selectedLocation;

    final ok = await capture.saveTransaction(
      userId: uid,
      amount: amountValue,
      type: type,
      category: _toCanonicalCategory(category),
      caption: captionController.text.trim(),
      note: '',
      sharedToFeed: privacy == 'friends',
      privacy: privacy,
      categoryIconCodePoint: selectedIcon.codePoint,
      categoryColorHex: selectedColorHex,
      locationName: location?.locationName ?? '',
      latitude: location?.latitude,
      longitude: location?.longitude,
    );

    if (!mounted) return;

    if (ok) {
      final budget = context.read<BudgetController>().findBudgetByName(category);

      if (budget != null && type == 'expense') {
        final nextSpent = budget.spentAmount + amountValue;

        if (budget.limitAmount > 0 && nextSpent > budget.limitAmount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: AppDurations.snackBar,
              content: Text(
                context.l10n.savedWithOverLimit(category),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: AppDurations.snackBar,
              content: Text(context.l10n.transactionSavedSuccessfully),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: AppDurations.snackBar,
            content: Text(context.l10n.transactionSavedSuccessfully),
          ),
        );
      }

      await context.read<FeedController>().refresh();

      if (!mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.transactionSaveFailed),
        ),
      );
    }
  }

  Widget _buildCategoryDropdownPanel() {
    final budgetController = context.watch<BudgetController>();
    final categories = currentCategories(context);

    final items = categories.map((label) {
      final budget = budgetController.findBudgetByName(label);
      final isCustomBudget = budget != null;

      return {
        'label': label,
        'displayLabel': _localizedCategoryLabel(label),
        'icon': _iconForCategory(label),
        'color': _colorForCategory(label),
        'isCustomBudget': isCustomBudget,
        'badgeText': isCustomBudget ? context.l10n.limitLabel : null,
      };
    }).toList();

    return _DropdownPanel(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final label = item['label'] as String;
        final displayLabel = item['displayLabel'] as String;
        final color = item['color'] as Color;
        final icon = item['icon'] as IconData;
        final badgeText = item['badgeText'] as String?;
        final isSelected = _toCanonicalCategory(category) == _toCanonicalCategory(label);

        return Column(
          children: [
            _DropdownItem(
              icon: icon,
              label: displayLabel,
              color: color,
              isSelected: isSelected,
              badgeText: badgeText,
              onTap: () {
                setState(() {
                  category = _toCanonicalCategory(label);
                  categoryOpen = false;
                });
              },
            ),
            if (index != items.length - 1) const _DropdownDivider(),
          ],
        );
      }),
    );
  }

  Widget _buildPrivacyDropdownPanel() {
    final items = [
      {
        'value': 'friends',
        'label': context.l10n.everyone,
        'icon': Icons.groups_2_outlined,
        'color': AppColors.income,
      },
      {
        'value': 'private',
        'label': context.l10n.private,
        'icon': Icons.lock_outline_rounded,
        'color': AppColors.expense,
      },
    ];

    return _DropdownPanel(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final value = item['value'] as String;
        final label = item['label'] as String;
        final icon = item['icon'] as IconData;
        final color = item['color'] as Color;
        final isSelected = privacy == value;

        return Column(
          children: [
            _DropdownItem(
              icon: icon,
              label: label,
              color: color,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  privacy = value;
                  privacyOpen = false;
                });
              },
            ),
            if (index != items.length - 1) const _DropdownDivider(),
          ],
        );
      }),
    );
  }

  Widget _dropdownPill({
    required IconData icon,
    required String label,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.10),
              Colors.white.withOpacity(0.045),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(
            color: Colors.white.withOpacity(isOpen ? 0.22 : 0.09),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 3),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeSwitch() {
    final isExpense = type == 'expense';
    final activeColor = isExpense ? AppColors.expense : AppColors.income;

    void switchToExpense() {
      if (type == 'expense') return;

      final categories = expenseCategoriesForAction();

      setState(() {
        type = 'expense';
        final currentCanonical = _toCanonicalCategory(category);
        category = categories.any(
          (item) => _toCanonicalCategory(item) == currentCanonical,
        )
            ? currentCanonical
            : _toCanonicalCategory(categories.first);
        categoryOpen = false;
        privacyOpen = false;
      });

      _onAmountChanged(amountController.text);
    }

    void switchToIncome() {
      if (type == 'income') return;

      final categories = incomeCategoriesForAction();

      setState(() {
        type = 'income';
        final currentCanonical = _toCanonicalCategory(category);
        category = categories.any(
          (item) => _toCanonicalCategory(item) == currentCanonical,
        )
            ? currentCanonical
            : _toCanonicalCategory(categories.first);
        categoryOpen = false;
        privacyOpen = false;
      });

      _onAmountChanged(amountController.text);
    }

    return Container(
      width: 148,
      height: 62,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _darkSwitch,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
              ),
              child: Center(
                child: Icon(
                  isExpense
                      ? Icons.arrow_outward_rounded
                      : Icons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: switchToExpense,
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: isExpense ? Colors.transparent : Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: switchToIncome,
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: isExpense ? Colors.white38 : Colors.transparent,
                      size: 24,
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

  Widget _bottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewMedia(double previewSize) {
    final currency = context.watch<ProfileController>().currency;

    return Center(
      child: SizedBox(
        width: previewSize,
        height: previewSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isVideo)
                _VideoPreviewLayer(
                  controller: _videoController,
                  isReady: _isVideoReady,
                  durationLabel: _formatDurationLabel(),
                  isMuted: _isVideoMuted,
                  onToggleMute: _toggleVideoMute,
                )
              else if (widget.imageFile != null)
                Image.file(
                  widget.imageFile!,
                  fit: BoxFit.cover,
                )
              else
                _CategoryFallbackPreview(
                  color: currentCategoryColor,
                  icon: currentCategoryIcon,
                  label: category,
                ),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.18),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: _InputOverlayCard(
                  accentColor: accentColor,
                  amountController: amountController,
                  captionController: captionController,
                  amountPrefix: type == 'expense' ? '-' : '+',
                  currency: currency,
                  onAmountChanged: _onAmountChanged,
                  onMaxDigitsExceeded: _showMaxDigitsWarning,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmitTap() async {
    if (_submitTapBusy || !hasAmountInput) return;
    setState(() => _submitTapBusy = true);
    try {
      await _saveTransaction();
    } finally {
      if (mounted) setState(() => _submitTapBusy = false);
    }
  }

  Widget _buildSubmitButton({
    required bool controllerSaving,
  }) {
    final busy = controllerSaving || _submitTapBusy;
    return GestureDetector(
      onTap: hasAmountInput && !busy ? () => _handleSubmitTap() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: hasAmountInput
                ? submitColor.withOpacity(0.45)
                : Colors.white.withOpacity(0.12),
            width: 4,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasAmountInput ? submitColor : const Color(0xFF1D2028),
              border: Border.all(
                color: hasAmountInput
                    ? submitColor.withOpacity(0.65)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
                  : const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<CaptureController>().isSaving;

    return Scaffold(
      backgroundColor: _captureBackground,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();

            if (categoryOpen || privacyOpen) {
              setState(() {
                categoryOpen = false;
                privacyOpen = false;
              });
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;

              final previewSize = (screenWidth - 12).clamp(300.0, 390.0);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: _CancelButton(
                      onTap: _closeCaptureFlow,
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: screenHeight - 68,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPreviewMedia(previewSize),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: _dropdownPill(
                                      icon: currentCategoryIcon,
                                      label: _localizedCategoryLabel(category),
                                      isOpen: categoryOpen,
                                      onTap: () {
                                        setState(() {
                                          categoryOpen = !categoryOpen;

                                          if (categoryOpen) {
                                            privacyOpen = false;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _dropdownPill(
                                      icon: privacyIcon,
                                      label: privacyLabel,
                                      isOpen: privacyOpen,
                                      onTap: () {
                                        setState(() {
                                          privacyOpen = !privacyOpen;

                                          if (privacyOpen) {
                                            categoryOpen = false;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              if (categoryOpen) _buildCategoryDropdownPanel(),
                              if (privacyOpen) _buildPrivacyDropdownPanel(),

                              const SizedBox(height: 14),

                              Center(
                                child: _typeSwitch(),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _bottomAction(
                                    icon: Icons.photo_camera_back_outlined,
                                    label: context.l10n.retake,
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CameraScreen(),
                                        ),
                                      );
                                    },
                                  ),

                                  _buildSubmitButton(
                                    controllerSaving: isSaving,
                                  ),

                                  if (hasMedia)
                                    _bottomAction(
                                      icon: Icons.ios_share_rounded,
                                      label: context.l10n.share,
                                      onTap: _shareMoment,
                                    )
                                  else
                                    const SizedBox(
                                      width: 58,
                                      height: 78,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CancelButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              color: _PreviewColors.captureSurface.withOpacity(0.55),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoPreviewLayer extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool isReady;
  final String durationLabel;
  final bool isMuted;
  final VoidCallback onToggleMute;

  const _VideoPreviewLayer({
    required this.controller,
    required this.isReady,
    required this.durationLabel,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final videoController = controller;

    return Container(
      color: Colors.black,
      child: isReady && videoController != null
          ? FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoController.value.size.width,
          height: videoController.value.size.height,
          child: VideoPlayer(videoController),
        ),
      )
          : const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}

class _InputOverlayCard extends StatelessWidget {
  final Color accentColor;
  final TextEditingController amountController;
  final TextEditingController captionController;
  final String amountPrefix;
  final String currency;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onMaxDigitsExceeded;

  const _InputOverlayCard({
    required this.accentColor,
    required this.amountController,
    required this.captionController,
    required this.amountPrefix,
    required this.currency,
    required this.onAmountChanged,
    required this.onMaxDigitsExceeded,
  });

  @override
  Widget build(BuildContext context) {
    final allowDecimal = currency == 'USD';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.34),
            accentColor.withOpacity(0.20),
            Colors.black.withOpacity(0.34),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: accentColor.withOpacity(0.55),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(
              decimal: allowDecimal,
            ),
            inputFormatters: [
              MoneyInputFormatter(
                maxDigits: _PreviewScreenState.kMaxAmountDigits,
                allowDecimal: allowDecimal,
                onMaxDigitsExceeded: onMaxDigitsExceeded,
              ),
            ],
            onChanged: onAmountChanged,
            textAlign: TextAlign.center,
            cursorColor: Colors.white,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: AppCurrencyFormatter.formatInputHint(currency),
              hintStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  top: 6,
                ),
                child: Text(
                  amountPrefix,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixText: AppCurrencyFormatter.symbol(currency),
              suffixStyle: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              filled: false,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            constraints: const BoxConstraints(
              maxWidth: 330,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 14,
                  child: Icon(
                    Icons.edit_outlined,
                    color: Colors.white.withOpacity(0.65),
                    size: 18,
                  ),
                ),

                TextField(
                  controller: captionController,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: Colors.white,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  minLines: 1,
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      _PreviewScreenState.kMaxCaptionLength,
                    ),
                    FilteringTextInputFormatter.deny(
                      RegExp(r'[\n\r]'),
                    ),
                  ],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.l10n.addDetails,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 42,
                      vertical: 8,
                    ),
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

class _CategoryFallbackPreview extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _CategoryFallbackPreview({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.90),
            const Color(0xFF0F2A20),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.18),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 72,
          ),
        ),
      ),
    );
  }
}

class _DropdownPanel extends StatelessWidget {
  final List<Widget> children;

  const _DropdownPanel({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        color: _PreviewColors.darkPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 235,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scrollbar(
            thumbVisibility: true,
            radius: const Radius.circular(999),
            thickness: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final String? badgeText;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.18),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (badgeText != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusPill,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.income,
                size: 21,
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownDivider extends StatelessWidget {
  const _DropdownDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.05),
    );
  }
}

class _PreviewColors {
  static const Color captureSurface = Color(0xFF232833);
  static const Color darkPanel = Color(0xFF1C1F28);
}