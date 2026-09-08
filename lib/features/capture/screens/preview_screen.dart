import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../budget/services/budget_cycle_helper.dart';
import '../../profile/controllers/user_category_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';
import '../controllers/capture_controller.dart';
import 'camera_screen.dart';

class PreviewScreen extends StatefulWidget {
  final File? imageFile;
  final File? videoFile;
  final String mediaType;
  final int? durationMs;
  final String? initialType;
  final String? initialPrivacy;
  final String? initialGroupId;
  final String? initialGroupName;
  final List<String>? initialGroupMemberIds;
  final bool lockType;
  final bool lockPrivacy;
  final bool isGroupContribution;

  const PreviewScreen({
    super.key,
    required this.imageFile,
    this.videoFile,
    this.mediaType = 'image',
    this.durationMs,
    this.initialType,
    this.initialPrivacy,
    this.initialGroupId,
    this.initialGroupName,
    this.initialGroupMemberIds,
    this.lockType = false,
    this.lockPrivacy = false,
    this.isGroupContribution = false,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final amountController = TextEditingController();
  final captionController = TextEditingController();
  final ValueNotifier<bool> _hasAmountNotifier = ValueNotifier<bool>(false);

  static const int kMaxAmountDigits = 10;
  static const double kMaxAmountValue = 9999999999;
  static const int kMaxCaptionLength = 70;

  static const Color _captureBackground = Color(0xFF15171C);
  static const Color _darkSwitch = Color(0xFF1A1B24);

  String type = 'expense';
  String category = 'Ăn uống';
  String privacy = 'friends';
  String? _selectedGroupId;
  String? _selectedGroupName;
  List<String> _selectedGroupMemberIds = [];
  List<Map<String, dynamic>> _userGroups = [];
  bool _loadedGroups = false;

  Map<String, dynamic>? get _currentSelectedGroupData {
    if (_selectedGroupId == null || _selectedGroupId!.isEmpty) return null;
    try {
      return _userGroups.firstWhere(
        (g) => (g['id'] ?? g['groupId']) == _selectedGroupId,
      );
    } catch (_) {
      return null;
    }
  }

  double get _currentGroupRemainingBalance {
    final data = _currentSelectedGroupData;
    if (data == null) return 0.0;
    final current = (data['currentAmount'] as num?)?.toDouble() ?? 0.0;
    final spent = (data['spentAmount'] as num?)?.toDouble() ?? 0.0;
    return current - spent;
  }

  bool categoryOpen = false;
  bool privacyOpen = false;
  bool _loadedBudgets = false;
  bool _loadedUserCategories = false;
  bool _submitTapBusy = false;

  double amountValue = 0;

  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _isVideoMuted = true;

  List<String> _closeFriendUids = [];
  StreamSubscription<List<String>>? _closeFriendsSub;

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
    'Quỹ nhóm': {
      'icon': Icons.savings_rounded,
      'color': Color(0xFF10B981),
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
    if (privacy == 'group') return _selectedGroupName ?? context.l10n.groupBadge;
    if (privacy == 'private') return context.l10n.private;
    if (privacy == 'close_friends') return context.l10n.closeFriends;
    return context.l10n.everyone;
  }

  IconData get privacyIcon {
    if (privacy == 'group') {
      return Icons.groups_2_rounded;
    }
    if (privacy == 'private') {
      return Icons.lock_outline_rounded;
    }
    if (privacy == 'close_friends') {
      return Icons.star_rounded;
    }
    return Icons.groups_2_outlined;
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
      case 'Quỹ nhóm':
      case 'Group Fund':
        return 'Quỹ nhóm';
      default:
        if (label == l10n.food) return 'Ăn uống';
        if (label == l10n.shopping) return 'Mua sắm';
        if (label == l10n.transport) return 'Đi lại';
        if (label == l10n.education) return 'Học tập';
        if (label == l10n.entertainment) return 'Giải trí';
        if (label == l10n.salary) return 'Lương';
        if (label == l10n.gift) return 'Quà tặng';
        if (label == l10n.other) return 'Khác';
        if (label == l10n.groupFundCategory) return 'Quỹ nhóm';
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
      case 'Quỹ nhóm':
      case 'Group Fund':
        return l10n.groupFundCategory;
      default:
        return BudgetNameLocalizer.display(context, categoryValue);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      type = widget.initialType!;
    }
    if (widget.initialPrivacy != null) {
      privacy = widget.initialPrivacy!;
    }
    if (widget.initialGroupId != null) {
      _selectedGroupId = widget.initialGroupId;
    }
    if (widget.initialGroupName != null) {
      _selectedGroupName = widget.initialGroupName;
    }
    if (widget.initialGroupMemberIds != null) {
      _selectedGroupMemberIds = widget.initialGroupMemberIds!;
    }
    if (widget.isGroupContribution) {
      category = 'Quỹ nhóm';
    }
    _prepareVideoIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().user?.uid;
      if (uid != null) {
        _closeFriendsSub = context
            .read<UserRepository>()
            .streamCloseFriendIds(uid)
            .listen((ids) {
          if (mounted) {
            setState(() {
              _closeFriendUids = ids;
              if (_closeFriendUids.isEmpty && privacy == 'close_friends') {
                privacy = 'friends';
              }
            });
          }
        });
      }
    });
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

    if (!_loadedGroups) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null) {
        context.read<UserRepository>().fetchUserGroups(uid).then((groups) {
          if (mounted) {
            setState(() {
              _userGroups = groups;
            });
          }
        });
      }

      _loadedGroups = true;
    }
  }

  @override
  void dispose() {
    _hasAmountNotifier.dispose();
    _closeFriendsSub?.cancel();
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

      final key = _toCanonicalCategory(trimmed).toLowerCase();
      if (seen.contains(key)) return;

      seen.add(key);
      out.add(trimmed);
    }

    final isGroupMode = privacy == 'group';

    // When in group mode, hide personal budgets and custom categories
    if (!isGroupMode) {
      // 1. Prioritize user created budgets at top (excluding pure overall total budgets)
      for (final budget in budgetController(context).budgets) {
        if (!BudgetCycleHelper.isTotalBudgetName(budget.name)) {
          addRaw(budget.name);
        }
      }

      // 2. User custom categories
      for (final uc in userCategoryController(context).categoriesForExpense()) {
        addRaw(uc.name);
      }
    }

    // 3. Default expense categories
    if (isGroupMode || widget.isGroupContribution) {
      addRaw(l10n.groupFundCategory);
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

    final isGroupMode = privacy == 'group';

    if (isGroupMode || widget.isGroupContribution) {
      addRaw('Quỹ nhóm');
    }

    for (final label in [
      l10n.salary,
      l10n.gift,
      l10n.other,
    ]) {
      addRaw(label);
    }

    if (!isGroupMode) {
      for (final uc in userCategoryController(context).categoriesForIncome()) {
        addRaw(uc.name);
      }
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
    final budget = context.read<BudgetController>().findBudgetByName(label);

    if (budget != null) {
      return AppIconRegistry.fromCodePoint(budget.iconCodePoint);
    }

    final userCat = context.read<UserCategoryController>().findByName(label);

    if (userCat != null) {
      return AppIconRegistry.fromCodePoint(userCat.iconCodePoint);
    }

    final lookupLabel = _toCanonicalCategory(label);

    final defaultIcon = categoryMeta[lookupLabel]?['icon'] as IconData?;

    if (defaultIcon != null) {
      return defaultIcon;
    }

    return Icons.account_balance_wallet_outlined;
  }

  Color _colorForCategory(String label) {
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

    final lookupLabel = _toCanonicalCategory(label);

    final defaultColor = categoryMeta[lookupLabel]?['color'] as Color?;

    if (defaultColor != null) {
      return defaultColor;
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

    amountValue = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currency,
    );

    final hasInput = amountValue > 0;
    if (_hasAmountNotifier.value != hasInput) {
      _hasAmountNotifier.value = hasInput;
    }
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
    if (type != 'expense' || privacy == 'group') return true;

    final budgetCtrl = context.read<BudgetController>();
    final budget = budgetCtrl.findApplicableBudgetForExpense(category: category) ??
        budgetCtrl.findBudgetByName(category);

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

      final privacyText = privacy == 'private'
          ? context.l10n.private
          : (privacy == 'close_friends'
              ? context.l10n.closeFriends
              : (privacy == 'group'
                  ? (_selectedGroupName ?? context.l10n.groupBadge)
                  : context.l10n.everyone));

      final shareText = StringBuffer()
        ..writeln('Meme')
        ..writeln()
        ..writeln(context.l10n.shareType(type == 'expense' ? context.l10n.expense : context.l10n.income))
        ..writeln(context.l10n.shareCategory(_localizedCategoryLabel(category)));

      if (amountController.text.trim().isNotEmpty) {
        shareText.writeln(context.l10n.shareAmount('${type == 'expense' ? '-' : '+'}$amountText'));
      }

      final captionText = captionController.text.trim();
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
      AppToast.show(context, context.l10n.cannotShareNow);
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
      AppToast.show(
        context,
        context.l10n.enterValidAmount,
      );
      return;
    }

    if (amountValue > kMaxAmountValue) {
      AppToast.show(
        context,
        context.l10n.amountLimitExceeded,
      );
      return;
    }

    // Kiểm tra số dư quỹ nhóm nếu đang ở tab Chi tiêu cho nhóm (không phải nạp quỹ)
    if (privacy == 'group' &&
        type == 'expense' &&
        !widget.isGroupContribution &&
        _selectedGroupId != null &&
        _selectedGroupId!.isNotEmpty) {
      final remainingBalance = _currentGroupRemainingBalance;
      if (amountValue > remainingBalance) {
        final balText = _formatMoney(remainingBalance);
        AppToast.show(
          context,
          context.l10n.groupExpenseExceedsBalance(balText),
        );
        return;
      }
    }

    final shouldContinue = await _confirmIfBudgetWillExceed();
    if (!shouldContinue || !mounted) return;

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
        '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    final location = capture.selectedLocation;

    final isContribution = widget.isGroupContribution ||
        (privacy == 'group' &&
            (type == 'income' ||
                category == 'Quỹ nhóm' ||
                category == context.l10n.groupFundCategory));

    final effectiveType = isContribution ? 'expense' : type;

    final ok = await capture.saveTransaction(
      userId: uid,
      amount: amountValue,
      type: effectiveType,
      category: isContribution ? 'Quỹ nhóm' : _toCanonicalCategory(category),
      caption: captionController.text.trim(),
      note: '',
      sharedToFeed: privacy != 'private',
      privacy: privacy,
      closeFriendUids: privacy == 'close_friends' ? _closeFriendUids : const [],
      groupId: _selectedGroupId,
      groupName: _selectedGroupName,
      groupMemberIds: _selectedGroupMemberIds,
      categoryIconCodePoint: selectedIcon.codePoint,
      categoryColorHex: selectedColorHex,
      locationName: location?.locationName ?? '',
      latitude: location?.latitude,
      longitude: location?.longitude,
      isGroupContribution: isContribution,
    );

    if (!mounted) return;

    if (ok) {
      final budgetCtrl = context.read<BudgetController>();
      final budget = budgetCtrl.findApplicableBudgetForExpense(category: category) ??
          budgetCtrl.findBudgetByName(category);

      if (budget != null && type == 'expense' && privacy != 'group') {
        final nextSpent = budget.spentAmount + amountValue;

        if (budget.limitAmount > 0 && nextSpent > budget.limitAmount) {
          AppToast.show(
            context,
            context.l10n.savedWithOverLimit(
              _localizedCategoryLabel(category),
            ),
          );
        } else {
          AppToast.show(
            context,
            context.l10n.transactionSavedSuccessfully,
          );
        }
      } else {
        AppToast.show(
          context,
          context.l10n.transactionSavedSuccessfully,
        );
      }

      await context.read<FeedController>().refresh();

      if (!mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      if (mounted) {
        AppToast.show(
          context,
          context.l10n.transactionSaveFailed,
        );
      }
    }
  }

  Widget _buildCategoryDropdownPanel() {
    final budgetController = context.watch<BudgetController>();
    final categories = currentCategories(context);
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    final items = categories.map((label) {
      final budget = budgetController.findBudgetByName(label);
      final isCustomBudget = budget != null;

      return {
        'label': label,
        'displayLabel': _localizedCategoryLabel(label),
        'icon': _iconForCategory(label),
        'color': _colorForCategory(label),
        'isCustomBudget': isCustomBudget,
        'badgeText': isCustomBudget ? (isEn ? 'Budget' : 'Ngân sách') : null,
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
        final isSelected = category.trim().toLowerCase() == label.trim().toLowerCase() ||
            _toCanonicalCategory(category).toLowerCase() == _toCanonicalCategory(label).toLowerCase();

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
                  final isBudget = item['isCustomBudget'] == true;
                  category = isBudget ? label : _toCanonicalCategory(label);
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

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF79AFFF);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF79AFFF);
  }

  Widget _buildPrivacyDropdownPanel() {
    final items = [
      {
        'value': 'friends',
        'label': context.l10n.everyone,
        'icon': Icons.groups_2_outlined,
        'color': AppColors.income,
      },
      if (_closeFriendUids.isNotEmpty)
        {
          'value': 'close_friends',
          'label': context.l10n.closeFriends,
          'icon': Icons.star_rounded,
          'color': const Color(0xFFF59E0B),
        },
      {
        'value': 'private',
        'label': context.l10n.private,
        'icon': Icons.lock_outline_rounded,
        'color': AppColors.expense,
      },
      for (final g in _userGroups)
        {
          'value': 'group_${g['id']}',
          'groupId': (g['id'] ?? '').toString(),
          'groupName': (g['name'] ?? 'Nhóm').toString(),
          'memberIds': (g['memberIds'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[],
          'label': (g['name'] ?? 'Nhóm').toString(),
          'icon': Icons.groups_2_rounded,
          'color': _parseHexColor(g['color'] as String?),
        },
    ];

    return _DropdownPanel(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final value = item['value'] as String;
        final label = item['label'] as String;
        final icon = item['icon'] as IconData;
        final color = item['color'] as Color;
        final isSelected = privacy == 'group'
            ? (_selectedGroupId != null && _selectedGroupId == item['groupId'])
            : privacy == value;

        return Column(
          children: [
            _DropdownItem(
              icon: icon,
              label: label,
              color: color,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (value.startsWith('group_')) {
                    privacy = 'group';
                    _selectedGroupId = item['groupId'] as String?;
                    _selectedGroupName = item['groupName'] as String?;
                    _selectedGroupMemberIds =
                        (item['memberIds'] as List<String>?) ?? [];
                  } else {
                    privacy = value;
                    _selectedGroupId = null;
                    _selectedGroupName = null;
                    _selectedGroupMemberIds = [];
                  }
                  privacyOpen = false;
                });
                _notifyPrivacyTagAdjustmentIfNeeded(value);
              },
            ),
            if (index != items.length - 1) const _DropdownDivider(),
          ],
        );
      }),
    );
  }

  void _notifyPrivacyTagAdjustmentIfNeeded(String newPrivacy) {
    final text = captionController.text.trim();
    if (text.isEmpty) return;

    final mentionRegex = RegExp(r'@([a-zA-Z0-9_.]+)');
    final matches = mentionRegex.allMatches(text);
    if (matches.isEmpty) return;

    final isEn = Localizations.localeOf(context).languageCode == 'en';

    if (newPrivacy == 'private') {
      AppToast.show(
        context,
        isEn
            ? 'Private mode: tagged friends will appear as plain text.'
            : 'Khoảnh khắc riêng tư: thẻ bạn bè sẽ hiển thị dạng chữ thường.',
      );
    } else if (newPrivacy == 'close_friends') {
      AppToast.show(
        context,
        isEn
            ? 'Close friends mode: non-close friends will appear as plain text.'
            : 'Chế độ bạn thân: bạn bè không thuộc Bạn thân sẽ hiển thị chữ thường.',
      );
    }
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

    if (widget.lockType) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _darkSwitch,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
              ),
              child: Icon(
                isExpense
                    ? Icons.arrow_outward_rounded
                    : Icons.arrow_downward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.isGroupContribution
                  ? context.l10n.groupFundDeposit
                  : (isExpense ? context.l10n.expense : context.l10n.income),
              style: TextStyle(
                color: activeColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.lock_rounded,
              color: activeColor.withValues(alpha: 0.7),
              size: 14,
            ),
          ],
        ),
      );
    }

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
          borderRadius: BorderRadius.circular(56),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: isVideo
                    ? _VideoPreviewLayer(
                        controller: _videoController,
                        isReady: _isVideoReady,
                        durationLabel: _formatDurationLabel(),
                        isMuted: _isVideoMuted,
                        onToggleMute: _toggleVideoMute,
                      )
                    : widget.imageFile != null
                        ? Image.file(
                            widget.imageFile!,
                            fit: BoxFit.cover,
                            cacheWidth: 800,
                          )
                        : _CategoryFallbackPreview(
                            color: currentCategoryColor,
                            icon: currentCategoryIcon,
                            label: category,
                          ),
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
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: RepaintBoundary(
                  child: _InputOverlayCard(
                    accentColor: accentColor,
                    amountController: amountController,
                    captionController: captionController,
                    amountPrefix: type == 'expense' ? '-' : '+',
                    currency: currency,
                    onAmountChanged: _onAmountChanged,
                    onMaxDigitsExceeded: _showMaxDigitsWarning,
                    myUid: context.read<AuthController>().user?.uid ?? '',
                    privacy: privacy,
                    closeFriendUids: _closeFriendUids,
                    groupMemberIds: _selectedGroupMemberIds,
                    groupRemainingBalance: (privacy == 'group' && type == 'expense' && !widget.isGroupContribution)
                        ? _currentGroupRemainingBalance
                        : null,
                  ),
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
    return ValueListenableBuilder<bool>(
      valueListenable: _hasAmountNotifier,
      builder: (context, hasAmount, _) {
        return GestureDetector(
          onTap: hasAmount && !busy ? () => _handleSubmitTap() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: hasAmount
                    ? submitColor.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.12),
                width: 2.2,
              ),
              boxShadow: hasAmount
                  ? [
                      BoxShadow(
                        color: submitColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasAmount
                      ? submitColor
                      : Colors.white.withValues(alpha: 0.16),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<CaptureController>().isSaving;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final previewSize = (screenWidth - 28).clamp(240.0, 400.0);

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: _CancelButton(
                  onTap: _closeCaptureFlow,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
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
                                  if (widget.lockPrivacy) return;
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
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CameraScreen(),
                                    ),
                                  );
                                }
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
            ],
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
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.cancel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      color: color.withValues(alpha: 0.22),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 58,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isReady && videoController != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoController.value.size.width,
              height: videoController.value.size.height,
              child: VideoPlayer(videoController),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  durationLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: GestureDetector(
            onTap: onToggleMute,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputOverlayCard extends StatefulWidget {
  final Color accentColor;
  final TextEditingController amountController;
  final TextEditingController captionController;
  final String amountPrefix;
  final String currency;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onMaxDigitsExceeded;
  final String myUid;
  final String privacy;
  final List<String> closeFriendUids;
  final List<String> groupMemberIds;
  final double? groupRemainingBalance;

  const _InputOverlayCard({
    required this.accentColor,
    required this.amountController,
    required this.captionController,
    required this.amountPrefix,
    required this.currency,
    required this.onAmountChanged,
    required this.onMaxDigitsExceeded,
    required this.myUid,
    this.privacy = 'friends',
    this.closeFriendUids = const [],
    this.groupMemberIds = const [],
    this.groupRemainingBalance,
  });

  @override
  State<_InputOverlayCard> createState() => _InputOverlayCardState();
}

class _InputOverlayCardState extends State<_InputOverlayCard> {
  String? _activeMentionQuery;

  @override
  void initState() {
    super.initState();
    widget.captionController.addListener(_checkMentionQuery);
    widget.amountController.addListener(_onAmountChangedInternal);
  }

  @override
  void dispose() {
    widget.captionController.removeListener(_checkMentionQuery);
    widget.amountController.removeListener(_onAmountChangedInternal);
    super.dispose();
  }

  void _onAmountChangedInternal() {
    if (mounted && widget.groupRemainingBalance != null) {
      setState(() {});
    }
  }

  void _checkMentionQuery() {
    final text = widget.captionController.text;
    final selection = widget.captionController.selection;
    final cursor = selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    if (cursor > text.length) {
      if (_activeMentionQuery != null) setState(() => _activeMentionQuery = null);
      return;
    }

    final prefix = text.substring(0, cursor);
    final lastAt = prefix.lastIndexOf('@');
    if (lastAt == -1) {
      if (_activeMentionQuery != null) setState(() => _activeMentionQuery = null);
      return;
    }

    final query = prefix.substring(lastAt + 1);
    if (query.contains(' ') || query.contains('\n')) {
      if (_activeMentionQuery != null) setState(() => _activeMentionQuery = null);
      return;
    }

    final normalized = query.toLowerCase();
    if (_activeMentionQuery != normalized) {
      setState(() {
        _activeMentionQuery = normalized;
      });
    }
  }

  void _selectMentionFriend(String username) {
    HapticFeedback.selectionClick();
    final text = widget.captionController.text;
    final selection = widget.captionController.selection;
    final cursor = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    final prefix = text.substring(0, cursor);
    final lastAt = prefix.lastIndexOf('@');
    if (lastAt == -1) return;

    final beforeAt = text.substring(0, lastAt);
    final afterCursor = text.substring(cursor);
    final cleanUsername = username.replaceAll('@', '').trim();
    final insertText = '@$cleanUsername ';
    final newText = '$beforeAt$insertText$afterCursor';

    widget.captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: beforeAt.length + insertText.length),
    );

    setState(() {
      _activeMentionQuery = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allowDecimal = widget.currency == 'USD';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // FLOATING FRIEND MENTION SUGGESTIONS
        if (_activeMentionQuery != null && widget.myUid.isNotEmpty)
          _FriendMentionSuggestionsCard(
            myUid: widget.myUid,
            query: _activeMentionQuery!,
            onSelect: _selectMentionFriend,
            privacy: widget.privacy,
            closeFriendUids: widget.closeFriendUids,
            groupMemberIds: widget.groupMemberIds,
          ),

        if (_activeMentionQuery != null && widget.myUid.isNotEmpty)
          const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0x73000000),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accentColor.withValues(alpha: 0.34),
                widget.accentColor.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.34),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.55),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: widget.amountController,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: allowDecimal,
                ),
                inputFormatters: [
                  MoneyInputFormatter(
                    maxDigits: _PreviewScreenState.kMaxAmountDigits,
                    allowDecimal: allowDecimal,
                    onMaxDigitsExceeded: widget.onMaxDigitsExceeded,
                  ),
                ],
                onChanged: widget.onAmountChanged,
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
                  hintText: AppCurrencyFormatter.formatInputHint(widget.currency),
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      top: 4,
                    ),
                    child: Text(
                      widget.amountPrefix,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  suffixText: AppCurrencyFormatter.symbol(widget.currency),
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

              if (widget.groupRemainingBalance != null) ...[
                const SizedBox(height: 6),
                Builder(
                  builder: (context) {
                    final rawAmount = widget.currency == 'USD'
                        ? widget.amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')
                        : widget.amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    final inputAmount = double.tryParse(rawAmount) ?? 0;
                    final enteredVnd = AppCurrencyFormatter.toVnd(
                      inputAmount: inputAmount,
                      currency: widget.currency,
                    );
                    final balance = widget.groupRemainingBalance!;
                    final isExceeded = enteredVnd > balance;
                    final formattedBalance = AppCurrencyFormatter.formatFromVnd(
                      amountVnd: balance,
                      currency: widget.currency,
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExceeded
                            ? const Color(0x40FF4B4B)
                            : Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isExceeded
                              ? const Color(0xFFFF5252).withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExceeded ? Icons.warning_amber_rounded : Icons.account_balance_wallet_outlined,
                            size: 13,
                            color: isExceeded ? const Color(0xFFFF6B6B) : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isExceeded
                                  ? context.l10n.groupExpenseExceedsBalance(formattedBalance)
                                  : '${context.l10n.groupFundRemaining}: $formattedBalance',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isExceeded ? const Color(0xFFFF6B6B) : Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
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
                        color: Colors.white.withValues(alpha: 0.65),
                        size: 18,
                      ),
                    ),

                    TextField(
                      controller: widget.captionController,
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
                          color: Colors.white.withValues(alpha: 0.50),
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
        ),
      ],
    );
  }
}

class _FriendMentionSuggestionsCard extends StatelessWidget {
  final String myUid;
  final String query;
  final ValueChanged<String> onSelect;
  final String privacy;
  final List<String> closeFriendUids;
  final List<String> groupMemberIds;

  const _FriendMentionSuggestionsCard({
    required this.myUid,
    required this.query,
    required this.onSelect,
    this.privacy = 'friends',
    this.closeFriendUids = const [],
    this.groupMemberIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<UserRepository>();

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 165,
        maxWidth: 330,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xEB161922),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.alternate_email_rounded,
                  color: Color(0xFF00E5FF),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  context.l10n.tagFriends,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          Flexible(
            child: privacy == 'private'
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    child: Center(
                      child: Text(
                        context.l10n.privateCannotTagFriends,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: userRepo.streamFriends(myUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                        );
                      }

                      final friends = snapshot.data ?? [];
                      final filtered = friends.where((f) {
                        // 1. Chế độ Riêng tư: Không gắn thẻ bạn bè
                        if (privacy == 'private') {
                          return false;
                        }

                        final friendUid = (f['uid'] ?? '').toString();

                        // 2. Chế độ Bạn thân: Chỉ cho phép gắn thẻ bạn bè trong danh sách CloseFriends
                        if (privacy == 'close_friends' &&
                            !closeFriendUids.contains(friendUid)) {
                          return false;
                        }

                        // 3. Chế độ Nhóm quỹ: Chỉ cho phép gắn thẻ giao thoa Members(Group) ∩ Friends(A)
                        if (privacy == 'group' &&
                            !groupMemberIds.contains(friendUid)) {
                          return false;
                        }

                        final name = (f['name'] ?? '').toString().toLowerCase();
                        final username =
                            (f['username'] ?? '').toString().toLowerCase();
                        if (query.isEmpty) return true;
                        return name.contains(query) || username.contains(query);
                      }).toList();

                      if (filtered.isEmpty) {
                        final isEn = Localizations.localeOf(context).languageCode == 'en';
                        final String emptyMessage;
                        if (privacy == 'private') {
                          emptyMessage = isEn
                              ? 'Private mode does not tag friends'
                              : 'Chế độ riêng tư không gắn thẻ bạn bè';
                        } else if (privacy == 'close_friends' && query.isEmpty) {
                          emptyMessage = context.l10n.closeFriendsTagOnly;
                        } else if (privacy == 'group' && query.isEmpty) {
                          emptyMessage = isEn
                              ? 'Only group members who are your friends can be tagged'
                              : 'Chỉ gắn thẻ thành viên nhóm là bạn bè';
                        } else {
                          emptyMessage = context.l10n.noMatchingFriends;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Center(
                            child: Text(
                              emptyMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.60),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final friend = filtered[index];
                    final name = (friend['name'] ?? '').toString().trim();
                    final username = (friend['username'] ?? '').toString().trim();
                    final avatarUrl = (friend['avatarUrl'] ?? '').toString();
                    final avatarFrame = (friend['avatarFrame'] ?? 'plain').toString();
                    final displayName = name.isNotEmpty ? name : (username.isNotEmpty ? username : 'User');
                    final mentionHandle = username.isNotEmpty ? username : displayName.replaceAll(' ', '_');

                    return InkWell(
                      onTap: () => onSelect(mentionHandle),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            AvatarWithFrame(
                              avatarUrl: avatarUrl,
                              frameId: avatarFrame,
                              size: 30,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (username.isNotEmpty)
                                    Text(
                                      '@$username',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.north_west_rounded,
                              color: Color(0xFF00E5FF),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
          maxHeight: 280,
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
  static const Color darkPanel = Color(0xFF1C1F28);
}