import 'dart:async';
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
import '../../home/widgets/streak_milestone_dialog.dart';
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
  final bool isFrontCamera;

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
    this.isFrontCamera = false,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final amountController = TextEditingController();
  final captionController = TextEditingController();
  final ValueNotifier<bool> _hasAmountNotifier = ValueNotifier<bool>(false);

  static const int kMaxAmountDigits = 12;
  static const double kMaxAmountValue = 999999999999;
  static const int kMaxCaptionLength = 70;
  bool _hasShownMaxDigitsWarning = false;

  static const Color _captureBackground = Color(0xFF15171C);
  static const Color _darkSwitch = Color(0xFF1A1B24);

  String type = 'expense';
  String category = 'Ăn uống';
  String privacy = 'friends';
  final Set<String> _selectedFriendUids = {};
  String? _selectedGroupId;
  String? _selectedGroupName;
  List<String> _selectedGroupMemberIds = [];
  List<Map<String, dynamic>> _userGroups = [];
  List<Map<String, dynamic>> _friends = [];

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
  bool _loadedBudgets = false;
  bool _loadedUserCategories = false;
  bool _submitTapBusy = false;

  double amountValue = 0;

  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _isVideoMuted = true;

  List<String> _closeFriendUids = [];
  StreamSubscription<List<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<List<String>>? _closeFriendsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _groupsSub;

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

  bool get isContribution {
    return widget.isGroupContribution ||
        (privacy == 'group' &&
            (category == 'Quỹ nhóm' ||
                category == 'Group Fund' ||
                category == context.l10n.groupFundCategory ||
                type == 'income'));
  }

  Color get accentColor {
    if (isContribution) return AppColors.income;
    return type == 'expense' ? AppColors.expense : AppColors.income;
  }

  Color get submitColor {
    if (isContribution) return AppColors.income;
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
    final trimmed = label.trim().toLowerCase();
    switch (trimmed) {
      case 'ăn uống':
      case 'food':
        return 'Ăn uống';
      case 'mua sắm':
      case 'shopping':
        return 'Mua sắm';
      case 'đi lại':
      case 'transport':
        return 'Đi lại';
      case 'học tập':
      case 'education':
        return 'Học tập';
      case 'giải trí':
      case 'entertainment':
        return 'Giải trí';
      case 'lương':
      case 'salary':
        return 'Lương';
      case 'quà tặng':
      case 'gift':
        return 'Quà tặng';
      case 'khác':
      case 'other':
        return 'Khác';
      case 'quỹ nhóm':
      case 'group fund':
        return 'Quỹ nhóm';
      default:
        if (trimmed == l10n.food.toLowerCase()) return 'Ăn uống';
        if (trimmed == l10n.shopping.toLowerCase()) return 'Mua sắm';
        if (trimmed == l10n.transport.toLowerCase()) return 'Đi lại';
        if (trimmed == l10n.education.toLowerCase()) return 'Học tập';
        if (trimmed == l10n.entertainment.toLowerCase()) return 'Giải trí';
        if (trimmed == l10n.salary.toLowerCase()) return 'Lương';
        if (trimmed == l10n.gift.toLowerCase()) return 'Quà tặng';
        if (trimmed == l10n.other.toLowerCase()) return 'Khác';
        if (trimmed == l10n.groupFundCategory.toLowerCase()) return 'Quỹ nhóm';
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
      if (uid != null && uid.isNotEmpty) {
        final userRepo = context.read<UserRepository>();

        _friendsSub = userRepo.streamFriends(uid).listen((friendsList) {
          if (mounted) {
            setState(() {
              _friends = friendsList;
            });
          }
        });

        _closeFriendsSub = userRepo.streamCloseFriendIds(uid).listen((ids) {
          if (mounted) {
            setState(() {
              _closeFriendUids = ids;
              if (_closeFriendUids.isEmpty && privacy == 'close_friends') {
                privacy = 'friends';
              }
            });
          }
        });

        _groupsSub = userRepo.streamGroups(uid).listen((groupsList) {
          if (mounted) {
            setState(() {
              _userGroups = groupsList;
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
  }

  @override
  void dispose() {
    _hasAmountNotifier.dispose();
    _friendsSub?.cancel();
    _closeFriendsSub?.cancel();
    _groupsSub?.cancel();
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
      addRaw(l10n.groupFundCategory);
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
    if (Navigator.canPop(context)) {
      Navigator.pop(context, 'close');
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.mainShell,
        (route) => false,
      );
    }
  }

  void _showMaxDigitsWarning() {
    if (_hasShownMaxDigitsWarning) return;
    _hasShownMaxDigitsWarning = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.maxAmountDigits),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _onAmountChanged(String value) {
    final currency = context.read<ProfileController>().currency;

    final raw = currency == 'USD'
        ? value.replaceAll(RegExp(r'[^0-9.]'), '')
        : value.replaceAll(RegExp(r'[^0-9]'), '');

    final digitCount = (currency == 'USD'
        ? raw.split('.').first
        : raw).length;

    if (digitCount < kMaxAmountDigits) {
      _hasShownMaxDigitsWarning = false;
    }

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
        ..writeln(context.l10n.shareType(isContribution ? context.l10n.groupFundDeposit : (type == 'expense' ? context.l10n.expense : context.l10n.income)))
        ..writeln(context.l10n.shareCategory(_localizedCategoryLabel(category)));

      if (amountController.text.trim().isNotEmpty) {
        shareText.writeln(context.l10n.shareAmount('${(isContribution ? '+' : (type == 'expense' ? '-' : '+'))}$amountText'));
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
        !isContribution &&
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
        isFrontCamera: widget.isFrontCamera,
      );
    } else if (widget.imageFile != null) {
      capture.setImage(
        widget.imageFile!,
        isFrontCamera: widget.isFrontCamera,
      );
    } else {
      capture.clearMedia();
    }

    final selectedIcon = _iconForCategory(category);
    final selectedColor = _colorForCategory(category);

    final selectedColorHex =
        '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    final location = capture.selectedLocation;

    final effectiveType = isContribution ? 'expense' : type;

    // Resolve effective privacy, close friends, and group
    String effectivePrivacy = 'friends';
    List<String> effectiveCloseFriends = const [];
    bool effectiveSharedToFeed = true;
    String? effectiveGroupId;
    String? effectiveGroupName;
    List<String> effectiveGroupMemberIds = const [];

    if (privacy == 'private') {
      effectivePrivacy = 'private';
      effectiveSharedToFeed = false;
    } else if (privacy == 'friends') {
      effectivePrivacy = 'friends';
      effectiveSharedToFeed = true;
    } else if (privacy == 'close_friends') {
      effectivePrivacy = 'close_friends';
      effectiveSharedToFeed = true;
      effectiveCloseFriends = _closeFriendUids;
    } else if (privacy == 'group' && _selectedGroupId != null) {
      effectivePrivacy = 'group';
      effectiveSharedToFeed = true;
      effectiveGroupId = _selectedGroupId;
      effectiveGroupName = _selectedGroupName;
      effectiveGroupMemberIds = _selectedGroupMemberIds;
    } else if (_selectedFriendUids.isNotEmpty) {
      effectivePrivacy = 'close_friends';
      effectiveSharedToFeed = true;
      effectiveCloseFriends = _selectedFriendUids.toList();
    }

    final ok = await capture.saveTransaction(
      userId: uid,
      amount: amountValue,
      type: effectiveType,
      category: isContribution ? 'Quỹ nhóm' : _toCanonicalCategory(category),
      caption: captionController.text.trim(),
      note: '',
      sharedToFeed: effectiveSharedToFeed,
      privacy: effectivePrivacy,
      closeFriendUids: effectiveCloseFriends,
      groupId: effectiveGroupId,
      groupName: effectiveGroupName,
      groupMemberIds: effectiveGroupMemberIds,
      categoryIconCodePoint: selectedIcon.codePoint,
      categoryColorHex: selectedColorHex,
      locationName: location?.locationName ?? '',
      latitude: location?.latitude,
      longitude: location?.longitude,
      isGroupContribution: isContribution,
      isFrontCamera: widget.isFrontCamera,
    );

    if (!mounted) return;

    if (ok) {
      final unlockedMilestone = capture.consumeLastUnlockedMilestone();
      if (unlockedMilestone != null && mounted) {
        await StreakMilestoneDialog.show(
          context,
          milestone: unlockedMilestone,
        );
      }
      if (!mounted) return;

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

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.mainShell,
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        AppToast.show(
          context,
          context.l10n.transactionSaveFailed,
        );
      }
    }
  }

  Widget _buildFloatingCategoryMenu(double previewSize) {
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: (previewSize * 0.84).clamp(240.0, 340.0),
          constraints: BoxConstraints(
            maxHeight: (previewSize * 0.68).clamp(160.0, 260.0),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF14161F).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          final isBudget = item['isCustomBudget'] == true;
                          category = isBudget ? label : _toCanonicalCategory(label);
                          categoryOpen = false;
                        });
                      },
                      child: Container(
                        height: 46,
                        color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.22),
                              ),
                              child: Center(
                                child: Icon(
                                  icon,
                                  color: color,
                                  size: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (badgeText != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.5),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: const TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (index != items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
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

  Widget _typeSwitch() {
    final isExpense = !isContribution && type == 'expense';
    final activeColor = isContribution
        ? AppColors.income
        : (isExpense ? AppColors.expense : AppColors.income);

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
                isContribution
                    ? Icons.arrow_downward_rounded
                    : (isExpense
                        ? Icons.arrow_outward_rounded
                        : Icons.arrow_downward_rounded),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isContribution
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
      });

      _onAmountChanged(amountController.text);
    }

    return Container(
      width: 148,
      height: 56,
      padding: const EdgeInsets.all(5),
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
              width: 46,
              height: 46,
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
                  size: 21,
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
                      size: 19,
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
                      size: 22,
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
                        isFrontCamera: widget.isFrontCamera,
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
                            label: _localizedCategoryLabel(category),
                          ),
              ),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.22),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                ),
              ),

              // 1. Input Card overlay at bottom
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: RepaintBoundary(
                  child: _InputOverlayCard(
                    accentColor: accentColor,
                    amountController: amountController,
                    captionController: captionController,
                    amountPrefix: isContribution ? '+' : (type == 'expense' ? '-' : '+'),
                    currency: currency,
                    onAmountChanged: _onAmountChanged,
                    onMaxDigitsExceeded: _showMaxDigitsWarning,
                    myUid: context.read<AuthController>().user?.uid ?? '',
                    privacy: privacy,
                    closeFriendUids: _selectedFriendUids.isNotEmpty ? _selectedFriendUids.toList() : _closeFriendUids,
                    groupMemberIds: _selectedGroupMemberIds,
                    groupRemainingBalance: (privacy == 'group' && type == 'expense' && !isContribution)
                        ? _currentGroupRemainingBalance
                        : null,
                  ),
                ),
              ),

              // 2. Floating Category Dropdown Pill & Floating Menu in Top-Center (Rendered on top)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            categoryOpen = !categoryOpen;
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14161F).withValues(alpha: 0.80),
                                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: categoryOpen ? 0.40 : 0.20),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    currentCategoryIcon,
                                    color: currentCategoryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: previewSize * 0.52,
                                    ),
                                    child: Text(
                                      _localizedCategoryLabel(category),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AnimatedRotation(
                                    turns: categoryOpen ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (categoryOpen) ...[
                        const SizedBox(height: 8),
                        _buildFloatingCategoryMenu(previewSize),
                      ],
                    ],
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isShort = screenHeight < 720;
    final isSmall = screenWidth < 370;

    // Like camera screen, square frame that fits full width or maxPreviewHeight
    final maxPreviewHeight = screenHeight - (isShort ? 250 : 285);
    final previewSize = screenWidth.clamp(220.0, maxPreviewHeight);
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: _captureBackground,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();

            if (categoryOpen) {
              setState(() {
                categoryOpen = false;
              });
            }
          },
          child: Stack(
            children: [
              // 1. Scrollable body tràn lên toàn màn hình
              Positioned.fill(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    0,
                    isShort ? 46 : 52,
                    0,
                    24,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPreviewMedia(previewSize),

                        SizedBox(height: isShort ? 10 : 14),

                        // 1. Dòng chuyển chi tiêu và thu nhập
                        Center(
                          child: _typeSwitch(),
                        ),

                        SizedBox(height: isShort ? 10 : 14),

                        // 2. Dòng chọn đối tượng (Riêng tư, Tất cả, Bạn thân, Nhóm, Bạn bè...)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _CaptureAudienceSelectorRow(
                            selectedAudience: privacy,
                            selectedFriendUids: _selectedFriendUids,
                            selectedGroupId: _selectedGroupId,
                            friends: _friends,
                            closeFriendUids: _closeFriendUids,
                            userGroups: _userGroups,
                            onPrivateSelected: () {
                              setState(() {
                                privacy = 'private';
                                _selectedFriendUids.clear();
                                _selectedGroupId = null;
                                _selectedGroupName = null;
                                _selectedGroupMemberIds = [];
                                if (category == 'Quỹ nhóm' || category == 'Group Fund') {
                                  category = 'Ăn uống';
                                }
                              });
                              _notifyPrivacyTagAdjustmentIfNeeded('private');
                            },
                            onAllFriendsSelected: () {
                              setState(() {
                                privacy = 'friends';
                                _selectedFriendUids.clear();
                                _selectedGroupId = null;
                                _selectedGroupName = null;
                                _selectedGroupMemberIds = [];
                                if (category == 'Quỹ nhóm' || category == 'Group Fund') {
                                  category = 'Ăn uống';
                                }
                              });
                              _notifyPrivacyTagAdjustmentIfNeeded('friends');
                            },
                            onCloseFriendsSelected: () {
                              setState(() {
                                privacy = 'close_friends';
                                _selectedGroupId = null;
                                _selectedGroupName = null;
                                _selectedGroupMemberIds = [];
                                _selectedFriendUids.clear();
                                _selectedFriendUids.addAll(_closeFriendUids);
                                if (category == 'Quỹ nhóm' || category == 'Group Fund') {
                                  category = 'Ăn uống';
                                }
                              });
                              _notifyPrivacyTagAdjustmentIfNeeded('close_friends');
                            },
                            onGroupSelected: (group) {
                              final gId = (group['id'] ?? group['groupId'] ?? '').toString();
                              final gName = (group['name'] ?? 'Nhóm').toString();
                              final gMembers = (group['memberIds'] as List<dynamic>?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                  <String>[];
                              setState(() {
                                privacy = 'group';
                                _selectedGroupId = gId;
                                _selectedGroupName = gName;
                                _selectedGroupMemberIds = gMembers;
                                _selectedFriendUids.clear();
                              });
                              _notifyPrivacyTagAdjustmentIfNeeded('group');
                            },
                            onFriendToggled: (friend) {
                              final fUid = (friend['uid'] ?? '').toString();
                              setState(() {
                                _selectedGroupId = null;
                                _selectedGroupName = null;
                                _selectedGroupMemberIds = [];

                                if (_selectedFriendUids.contains(fUid)) {
                                  _selectedFriendUids.remove(fUid);
                                  if (_selectedFriendUids.isEmpty) {
                                    privacy = 'friends';
                                  }
                                } else {
                                  _selectedFriendUids.add(fUid);
                                  privacy = 'friends_custom';
                                }

                                if (category == 'Quỹ nhóm' || category == 'Group Fund') {
                                  category = 'Ăn uống';
                                }
                              });
                              _notifyPrivacyTagAdjustmentIfNeeded(privacy);
                            },
                            isDark: true,
                            isEnUI: isEn,
                          ),
                        ),

                        SizedBox(height: isShort ? 14 : 20),

                        // 3. Hàng nút hành động dưới cùng
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Floating Transparent Header
              Positioned(
                top: 8,
                left: isSmall ? 12 : 16,
                child: _CancelButton(
                  onTap: _closeCaptureFlow,
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  context.l10n.cancel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
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
  final bool isFrontCamera;

  const _VideoPreviewLayer({
    required this.controller,
    required this.isReady,
    required this.durationLabel,
    required this.isMuted,
    required this.onToggleMute,
    this.isFrontCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    final videoController = controller;

    Widget? playerWidget;
    if (isReady && videoController != null) {
      playerWidget = FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoController.value.size.width,
          height: videoController.value.size.height,
          child: VideoPlayer(videoController),
        ),
      );

      if (isFrontCamera) {
        playerWidget = Transform.flip(
          flipX: true,
          child: playerWidget,
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (playerWidget != null)
          playerWidget
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
    if (mounted) {
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

    final rawDigits = widget.currency == 'USD'
        ? widget.amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')
        : widget.amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final integerDigits = widget.currency == 'USD'
        ? rawDigits.split('.').first
        : rawDigits;
    final isAtMaxDigits = integerDigits.length >= _PreviewScreenState.kMaxAmountDigits;

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
              colors: isAtMaxDigits
                  ? [
                      const Color(0xFFFF3B30).withValues(alpha: 0.38),
                      const Color(0xFFFF3B30).withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.34),
                    ]
                  : [
                      widget.accentColor.withValues(alpha: 0.34),
                      widget.accentColor.withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.34),
                    ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isAtMaxDigits
                  ? const Color(0xFFFF3B30)
                  : widget.accentColor.withValues(alpha: 0.55),
              width: isAtMaxDigits ? 1.5 : 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: isAtMaxDigits
                    ? const Color(0x66FF3B30)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: isAtMaxDigits ? 16 : 14,
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
                        color: isAtMaxDigits ? const Color(0xFFFF5252) : widget.accentColor,
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

/// Horizontal Audience & Privacy Selector Row for Capture & Preview Screens
class _CaptureAudienceSelectorRow extends StatelessWidget {
  final String selectedAudience;
  final Set<String> selectedFriendUids;
  final String? selectedGroupId;
  final List<Map<String, dynamic>> friends;
  final List<String> closeFriendUids;
  final List<Map<String, dynamic>> userGroups;
  final VoidCallback onPrivateSelected;
  final VoidCallback onAllFriendsSelected;
  final VoidCallback onCloseFriendsSelected;
  final ValueChanged<Map<String, dynamic>> onGroupSelected;
  final ValueChanged<Map<String, dynamic>> onFriendToggled;
  final bool isDark;
  final bool isEnUI;

  const _CaptureAudienceSelectorRow({
    required this.selectedAudience,
    required this.selectedFriendUids,
    required this.selectedGroupId,
    required this.friends,
    required this.closeFriendUids,
    required this.userGroups,
    required this.onPrivateSelected,
    required this.onAllFriendsSelected,
    required this.onCloseFriendsSelected,
    required this.onGroupSelected,
    required this.onFriendToggled,
    this.isDark = true,
    this.isEnUI = false,
  });

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF10B981);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryBlue;

    final isPrivateSelected = selectedAudience == 'private';
    final isAllSelected = selectedAudience == 'friends' && selectedFriendUids.isEmpty && selectedGroupId == null;
    final isCloseFriendsSelected = selectedAudience == 'close_friends';

    // Always display full friends list
    final displayedFriends = friends;

    return SizedBox(
      height: 66,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          // 1. Riêng tư (Private)
          _buildItem(
            label: isEnUI ? 'Private' : 'Riêng tư',
            isSelected: isPrivateSelected,
            onTap: onPrivateSelected,
            child: Icon(
              Icons.lock_rounded,
              size: 19,
              color: isPrivateSelected ? Colors.white : const Color(0xFF8E95A5),
            ),
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 10),

          // 2. Tất cả (All Friends)
          _buildItem(
            label: isEnUI ? 'All' : 'Tất cả',
            isSelected: isAllSelected,
            onTap: onAllFriendsSelected,
            child: Icon(
              Icons.groups_rounded,
              size: 20,
              color: isAllSelected ? Colors.white : const Color(0xFF8E95A5),
            ),
            primaryColor: primaryColor,
          ),

          // 3. Bạn thân (Close Friends) - Only show if user has close friends!
          if (closeFriendUids.isNotEmpty) ...[
            const SizedBox(width: 10),
            _buildItem(
              label: isEnUI ? 'Close friends' : 'Bạn thân',
              isSelected: isCloseFriendsSelected,
              onTap: onCloseFriendsSelected,
              child: const Icon(
                Icons.star_rounded,
                size: 21,
                color: Color(0xFFFBBF24),
              ),
              primaryColor: primaryColor,
            ),
          ],

          // 4. Nhóm (Groups)
          for (final group in userGroups) ...[
            const SizedBox(width: 10),
            _buildGroupItem(
              group: group,
              isSelected: selectedAudience == 'group' &&
                  (group['id'] ?? group['groupId'] ?? '').toString() == selectedGroupId,
              onTap: () => onGroupSelected(group),
              primaryColor: primaryColor,
            ),
          ],

          // 5. Friends list (Multi-selectable)
          for (final friend in displayedFriends) ...[
            const SizedBox(width: 10),
            _buildFriendItem(
              friend: friend,
              isCloseFriend: closeFriendUids.contains((friend['uid'] ?? '').toString()),
              isSelected: selectedFriendUids.contains((friend['uid'] ?? '').toString()),
              onTap: () => onFriendToggled(friend),
              primaryColor: primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
    required Color primaryColor,
  }) {
    const textSecondary = Colors.white60;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.28)
                  : const Color(0xFF242732),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.40),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: child,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 52,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupItem({
    required Map<String, dynamic> group,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    final groupName = (group['name'] ?? 'Nhóm').toString();
    final groupColor = _parseHexColor(group['color'] as String? ?? group['colorHex'] as String?);
    const textSecondary = Colors.white60;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? groupColor.withValues(alpha: 0.35)
                  : groupColor.withValues(alpha: 0.16),
              border: Border.all(
                color: isSelected ? groupColor : Colors.transparent,
                width: 2.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: groupColor.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.groups_2_rounded,
              size: 20,
              color: groupColor,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 52,
            child: Text(
              groupName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem({
    required Map<String, dynamic> friend,
    required bool isCloseFriend,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    final name = (friend['name'] ?? '').toString().trim();
    final username = (friend['username'] ?? '').toString().trim();
    final avatarUrl = (friend['avatarUrl'] ?? '').toString().trim();
    final displayName = name.isNotEmpty ? name : (username.isNotEmpty ? username : 'User');
    const textSecondary = Colors.white60;

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 2.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackInitial(initial),
                        )
                      : _buildFallbackInitial(initial),
                ),
              ),

              // Close Friend Star Badge indicator
              if (isCloseFriend)
                Positioned(
                  left: -2,
                  top: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF59E0B),
                      border: Border.all(
                        color: const Color(0xFF15171C),
                        width: 1.4,
                      ),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Multi-select Check Badge indicator
              if (isSelected)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      border: Border.all(
                        color: const Color(0xFF15171C),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 52,
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitial(String initial) {
    final colors = [
      const Color(0xFF00796B),
      const Color(0xFF1E88E5),
      const Color(0xFF5E35B1),
      const Color(0xFFD81B60),
      const Color(0xFF3949AB),
      const Color(0xFF00897B),
      const Color(0xFF43A047),
      const Color(0xFFFB8C00),
    ];
    final color = colors[initial.codeUnitAt(0) % colors.length];

    return Container(
      width: 36,
      height: 36,
      color: color,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}