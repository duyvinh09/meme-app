import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/local_settings_service.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../data/models/chat_bubble_theme.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../profile/screens/group_detail_screen.dart';
import '../../profile/widgets/avatar_with_frame.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/message_action_menu_overlay.dart';
import '../widgets/typing_indicator_widget.dart';

class GroupChatConversationScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupColor;
  final List<String>? memberUids;
  final TransactionModel? initialPostReply;
  final UserModel? initialPostAuthor;

  const GroupChatConversationScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupColor,
    this.memberUids,
    this.initialPostReply,
    this.initialPostAuthor,
  });

  static String localizeGroupSystemText(BuildContext context, String rawText) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    var cleanText = rawText.trim();
    if (cleanText.isEmpty) return rawText;

    // Strip leading sender prefix like "duy vinh: " if present in lastMessage
    final colonIdx = cleanText.indexOf(': ');
    if (colonIdx != -1 && colonIdx < 30) {
      final candidatePrefix = cleanText.substring(0, colonIdx).trim();
      final afterPrefix = cleanText.substring(colonIdx + 2).trim();
      if (afterPrefix.contains('đã thêm chi tiêu') ||
          afterPrefix.contains('đã chi tiêu') ||
          afterPrefix.contains('thêm chi tiêu') ||
          afterPrefix.contains('đã nạp') ||
          afterPrefix.contains('đã đóng góp') ||
          afterPrefix.contains('added expense') ||
          afterPrefix.contains('shared spending') ||
          afterPrefix.contains('deposited') ||
          afterPrefix.contains('contributed')) {
        if (afterPrefix.startsWith(candidatePrefix)) {
          cleanText = afterPrefix;
        } else if (afterPrefix.startsWith('đã ') ||
            afterPrefix.startsWith('added ') ||
            afterPrefix.startsWith('deposited ') ||
            afterPrefix.startsWith('contributed ')) {
          cleanText = '$candidatePrefix $afterPrefix';
        } else {
          cleanText = afterPrefix;
        }
      }
    }

    if (isEn) {
      // 1. Group fund contribution
      final fundMatch1 = RegExp(
        r'''^(.+?)\s+(?:đã đóng góp|đã nạp|nạp)\s+(.+?)\s+vào quỹ nhóm(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (fundMatch1 != null) {
        return '${fundMatch1.group(1)} deposited ${fundMatch1.group(2)} to group fund';
      }

      final fundMatch2 = RegExp(
        r'''^(.+?)\s+(?:đã đóng góp|đã nạp|nạp)\s+(.+?)\s+cho\s+(.+?)\s+trong nhóm(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (fundMatch2 != null) {
        return '${fundMatch2.group(1)} contributed ${fundMatch2.group(2)} for ${fundMatch2.group(3)} in group';
      }

      final fundMatchAmountOnly = RegExp(
        r'''^(.+?)\s+(?:đã đóng góp|đã nạp|nạp)\s+([0-9.,\s\u00a0\u202f]+[₫\$kK]?|[0-9.,]+)(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (fundMatchAmountOnly != null) {
        return '${fundMatchAmountOnly.group(1)} deposited ${fundMatchAmountOnly.group(2)} to group fund';
      }

      // 2. Expense logged
      final expMatch = RegExp(
        r'''^(.+?)\s+(?:đã thêm chi tiêu|đã chi tiêu|thêm chi tiêu)\s+(.+?)\s+cho\s+["'‘“]?([^"'’”]+?)["'’”]?(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (expMatch != null) {
        final name = expMatch.group(1)!.trim();
        final amount = expMatch.group(2)!.trim();
        final rawCat = expMatch.group(3)!.trim();
        final cat = BudgetNameLocalizer.display(context, rawCat);
        return '$name added expense of $amount for "$cat"';
      }

      final expMatchAmountOnly = RegExp(
        r'''^(.+?)\s+(?:đã thêm chi tiêu|đã chi tiêu|thêm chi tiêu)\s+([0-9.,\s\u00a0\u202f]+[₫\$kK]?|[0-9.,]+)(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (expMatchAmountOnly != null) {
        final name = expMatchAmountOnly.group(1)!.trim();
        final amount = expMatchAmountOnly.group(2)!.trim();
        return '$name added an expense of $amount';
      }

      final expMatchCatOnly = RegExp(
        r'''^(.+?)\s+(?:đã thêm chi tiêu|đã chi tiêu|thêm chi tiêu)\s+cho\s+["'‘“]?([^"'’”]+?)["'’”]?(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (expMatchCatOnly != null) {
        final name = expMatchCatOnly.group(1)!.trim();
        final rawCat = expMatchCatOnly.group(2)!.trim();
        final cat = BudgetNameLocalizer.display(context, rawCat);
        return '$name added an expense for "$cat"';
      }

      final expMatchMinimal = RegExp(
        r'''^(.+?)\s+(?:đã thêm chi tiêu|đã chi tiêu|thêm chi tiêu)(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (expMatchMinimal != null) {
        final name = expMatchMinimal.group(1)!.trim();
        return '$name added an expense';
      }

      // 3. Member added
      final addMatch = RegExp(
        r'^(.+?)\s+đã thêm\s+(.+?)\s+vào nhóm$',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (addMatch != null) {
        return '${addMatch.group(1)} added ${addMatch.group(2)} to the group';
      }

      // 4. Member removed
      final removeMatch = RegExp(
        r'^(.+?)\s+đã xoá\s+(.+?)\s+khỏi nhóm$',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (removeMatch != null) {
        return '${removeMatch.group(1)} removed ${removeMatch.group(2)} from the group';
      }

      // 5. Member left
      final leftMatch = RegExp(
        r'^(.+?)\s+đã rời khỏi nhóm$',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (leftMatch != null) {
        return '${leftMatch.group(1)} left the group';
      }

      // 6. Group created
      final createMatch = RegExp(
        r'''^(.+?)\s+đã tạo nhóm\s+["'‘“]?(.*?)["'’"]?$''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (createMatch != null) {
        return '${createMatch.group(1)} created group "${createMatch.group(2)}"';
      }
      if (cleanText == 'Nhóm chi tiêu đã được tạo' || cleanText == 'Nhóm đã được tạo') {
        return 'Group was created';
      }
    } else {
      // If language is Vietnamese, translate any English logs if stored in English
      final fundEn1 = RegExp(
        r'^(.+?)\s+(?:contributed|deposited)\s+(.+?)\s+(?:to|into) group fund$',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (fundEn1 != null) {
        return '${fundEn1.group(1)} đã nạp ${fundEn1.group(2)} vào quỹ nhóm';
      }
      final fundEn2 = RegExp(
        r'^(.+?)\s+(?:contributed|deposited)\s+(.+?)\s+for\s+(.+?)\s+in group$',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (fundEn2 != null) {
        return '${fundEn2.group(1)} đã đóng góp ${fundEn2.group(2)} cho ${fundEn2.group(3)} trong nhóm';
      }

      final expEn = RegExp(
        r'''^(.+?)\s+(?:added expense of|shared spending of)\s+(.+?)\s+for\s+["'‘“]?([^"'’”]+?)["'’”]?(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (expEn != null) {
        final cat = BudgetNameLocalizer.display(context, expEn.group(3)!);
        return '${expEn.group(1)} đã thêm chi tiêu ${expEn.group(2)} cho "$cat"';
      }

      final expEnAmountOnly = RegExp(
        r'''^(.+?)\s+(?:added an expense of|added expense of)\s+([0-9.,\s\u00a0\u202f]+[₫\$kK]?|[0-9.,]+)(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (expEnAmountOnly != null) {
        return '${expEnAmountOnly.group(1)} đã thêm chi tiêu ${expEnAmountOnly.group(2)}';
      }

      final expEnMinimal = RegExp(
        r'''^(.+?)\s+(?:added an expense|added expense)(?:\s*$)''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (expEnMinimal != null) {
        return '${expEnMinimal.group(1)} đã thêm chi tiêu';
      }

      final addEn = RegExp(
        r'^(.+?)\s+added\s+(.+?)\s+to (?:the )?group$',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (addEn != null) {
        return '${addEn.group(1)} đã thêm ${addEn.group(2)} vào nhóm';
      }

      final removeEn = RegExp(
        r'^(.+?)\s+removed\s+(.+?)\s+from (?:the )?group$',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (removeEn != null) {
        return '${removeEn.group(1)} đã xoá ${removeEn.group(2)} khỏi nhóm';
      }

      final leftEn = RegExp(
        r'^(.+?)\s+left the group$',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (leftEn != null) {
        return '${leftEn.group(1)} đã rời khỏi nhóm';
      }

      final createEn = RegExp(
        r'''^(.+?)\s+created group\s+["'‘“]?(.*?)["'’"]?$''',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (createEn != null) {
        return '${createEn.group(1)} đã tạo nhóm "${createEn.group(2)}"';
      }
      if (cleanText.toLowerCase() == 'group was created' ||
          cleanText.toLowerCase() == 'group expense was created') {
        return 'Nhóm chi tiêu đã được tạo';
      }
    }

    return rawText;
  }

  @override
  State<GroupChatConversationScreen> createState() =>
      _GroupChatConversationScreenState();
}

class _GroupChatConversationScreenState
    extends State<GroupChatConversationScreen>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();
  final ChatRepository _chatRepo = ChatRepository();
  final UserRepository _userRepo = UserRepository();

  ChatMessageModel? _replyingToMessage;
  TransactionModel? _currentPostReply;
  UserModel? _currentPostAuthor;
  bool _showEmojiGrid = false;
  bool _hasText = false;
  bool _isSending = false;
  bool _showScrollToBottom = false;
  Timer? _typingIdleTimer;
  DateTime? _lastTypingSentTime;
  bool _isCurrentlyTypingSent = false;

  bool _showFloatingDate = false;
  String _floatingDateText = '';
  Timer? _floatingDateHideTimer;
  final GlobalKey _listStackKey = GlobalKey();
  final Map<String, GlobalKey> _itemKeys = {};

  final Map<String, String> _senderBubbleThemeCache = {};
  final Map<String, UserModel> _memberCache = {};
  final TransactionRepository _txRepo = TransactionRepository();
  final Map<String, TransactionModel?> _resolvedExpensePosts = {};
  final Set<String> _resolvingExpenseIds = {};

  static const List<String> emojiList = [
    '🤣', '🥺', '😱', '🔥', '❤️', '👏', '😍', '🎉',
    '😎', '💯', '👀', '💀', '😭', '🤯', '🥳', '✨',
    '👍', '🙏', '🥰', '🤩', '💩', '🤑', '🤫', '🥱',
    '🫶', '🚀', '💖', '🙈', '🤤', '😈', '💤', '🍕',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPostReply = widget.initialPostReply;
    if (widget.initialPostReply != null) {
      if (widget.initialPostAuthor != null) {
        _currentPostAuthor = widget.initialPostAuthor;
        _memberCache[widget.initialPostAuthor!.uid] = widget.initialPostAuthor!;
      } else {
        _userRepo.getUserProfile(widget.initialPostReply!.userId).then((author) {
          if (author != null && mounted) {
            setState(() {
              _currentPostAuthor = author;
              _memberCache[author.uid] = author;
            });
          }
        });
      }
    }

    // Load unsent draft if available
    final draft = context.read<LocalSettingsService>().getDraft('group_${widget.groupId}');
    if (draft != null && draft.isNotEmpty) {
      _textController.text = draft;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      _hasText = draft.trim().isNotEmpty;
    }

    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    _textFocusNode.addListener(_onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatController>().setActiveChatGroup(widget.groupId);
        _markAsRead();
        _fetchMemberProfiles();
      }
    });
  }

  Future<void> _fetchMemberProfiles() async {
    if (widget.memberUids == null) return;
    for (final uid in widget.memberUids!) {
      if (!_memberCache.containsKey(uid)) {
        final profile = await _userRepo.getUserProfile(uid);
        if (profile != null && mounted) {
          setState(() {
            _memberCache[uid] = profile;
          });
        }
      }
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0 && _showEmojiGrid) {
      setState(() {
        _showEmojiGrid = false;
      });
    }
  }

  void _markAsRead() {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid != null) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.groupId)
          .update({
        'unreadBy': FieldValue.arrayRemove([myUid]),
      }).catchError((_) {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final myUid = context.read<AuthController>().user?.uid;
    if (state != AppLifecycleState.resumed) {
      _stopTypingHeartbeat(myUid);
    }
  }

  void _sendTypingHeartbeat(String myUid, bool isTyping) {
    if (!mounted) return;
    _chatRepo.setTypingStatus(
      chatId: widget.groupId,
      userId: myUid,
      isTyping: isTyping,
    );
  }

  void _stopTypingHeartbeat(String? myUid) {
    _typingIdleTimer?.cancel();
    _typingIdleTimer = null;
    if (myUid != null && myUid.isNotEmpty) {
      _isCurrentlyTypingSent = false;
      _sendTypingHeartbeat(myUid, false);
    }
  }

  void _onFocusChanged() {
    if (!_textFocusNode.hasFocus) {
      final myUid = context.read<AuthController>().user?.uid;
      _stopTypingHeartbeat(myUid);
    }
  }

  void _onTextChanged() {
    final rawText = _textController.text;
    final text = rawText.trim();
    final hasNow = text.isNotEmpty;
    if (hasNow != _hasText) {
      setState(() {
        _hasText = hasNow;
      });
    }

    // Persist draft in local settings
    context.read<LocalSettingsService>().setDraft(
      'group_${widget.groupId}',
      hasNow ? rawText : null,
    );

    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null || myUid.isEmpty) return;

    if (!hasNow) {
      // Empty text: immediately stop typing
      _typingIdleTimer?.cancel();
      _typingIdleTimer = null;
      if (_isCurrentlyTypingSent) {
        _isCurrentlyTypingSent = false;
        _sendTypingHeartbeat(myUid, false);
      }
      return;
    }

    // User is actively typing: send true (with throttle)
    final now = DateTime.now();
    if (!_isCurrentlyTypingSent ||
        _lastTypingSentTime == null ||
        now.difference(_lastTypingSentTime!).inSeconds >= 2) {
      _isCurrentlyTypingSent = true;
      _lastTypingSentTime = now;
      _sendTypingHeartbeat(myUid, true);
    }

    // Reset idle timer: if user pauses typing for 6s, auto-stop typing
    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _isCurrentlyTypingSent) {
        _isCurrentlyTypingSent = false;
        _sendTypingHeartbeat(myUid, false);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final bool shouldShow = _scrollController.offset > 120;
    if (shouldShow != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = shouldShow;
      });
    }
  }

  void _updateFloatingHeader(List<ChatMessageModel> messages) {
    if (messages.isEmpty) return;

    final scrollOffset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (scrollOffset > 20 && scrollOffset < maxScroll - 20) {
      final stackBox = _listStackKey.currentContext?.findRenderObject() as RenderBox?;
      final double listTopGlobalY = (stackBox != null && stackBox.hasSize)
          ? stackBox.localToGlobal(Offset.zero).dy
          : 0.0;
      const double floatingHeaderTriggerY = 55.0;
      final double triggerGlobalY = listTopGlobalY + floatingHeaderTriggerY;

      DateTime activeDate = messages.first.createdAt;

      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final gKey = _itemKeys[msg.id];
        final box = gKey?.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final topY = box.localToGlobal(Offset.zero).dy;
          final bottomY = topY + box.size.height;
          if (topY <= triggerGlobalY) {
            activeDate = msg.createdAt;
            if (bottomY >= triggerGlobalY) {
              break;
            }
          }
        }
      }

      final formatted = _formatFloatingDate(activeDate);

      if (formatted != _floatingDateText || !_showFloatingDate) {
        setState(() {
          _floatingDateText = formatted;
          _showFloatingDate = true;
        });
      }

      _floatingDateHideTimer?.cancel();
      _floatingDateHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _showFloatingDate) {
          setState(() {
            _showFloatingDate = false;
          });
        }
      });
    } else if (scrollOffset <= 20 && _showFloatingDate) {
      _floatingDateHideTimer?.cancel();
      setState(() {
        _showFloatingDate = false;
      });
    }
  }


  String _formatFloatingDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dt.year, dt.month, dt.day);

    if (msgDate == today) {
      return context.l10n.today;
    } else if (msgDate == yesterday) {
      return context.l10n.yesterday;
    } else if (now.difference(msgDate).inDays < 7) {
      return DateFormat('EEEE', Localizations.localeOf(context).languageCode).format(dt);
    } else {
      return DateFormat('dd/MM/yyyy').format(dt);
    }
  }

  String _formatSeparatorTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    if (isVi) {
      final timeStr = DateFormat('h:mm a').format(date)
          .replaceAll('AM', 'SA')
          .replaceAll('PM', 'CH');
      if (msgDay == today) {
        return '${context.l10n.today} $timeStr';
      }
      if (msgDay == yesterday) {
        return '${context.l10n.yesterday} $timeStr';
      }
      if (date.year == now.year) {
        return '${date.day} Tháng ${date.month} $timeStr';
      }
      return '${date.day} Tháng ${date.month}, ${date.year} $timeStr';
    } else {
      final timeStr = DateFormat('h:mm a', 'en').format(date);
      if (msgDay == today) {
        return '${context.l10n.today} $timeStr';
      }
      if (msgDay == yesterday) {
        return '${context.l10n.yesterday} $timeStr';
      }
      if (date.year == now.year) {
        return '${DateFormat('d MMM', 'en').format(date)} $timeStr';
      }
      return '${DateFormat('d MMM, y', 'en').format(date)} $timeStr';
    }
  }

  void _scrollToBottom() {
    HapticFeedback.lightImpact();
    if (_showScrollToBottom) {
      setState(() {
        _showScrollToBottom = false;
      });
    }
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
      );
    }
  }

  void _scrollToMessage(String messageId) {
    final key = _itemKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  void _fetchSenderThemeIfNeeded(String senderId) {
    if (senderId.isEmpty || _senderBubbleThemeCache.containsKey(senderId)) return;
    _senderBubbleThemeCache[senderId] = 'default';
    FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get()
        .then((doc) {
      if (doc.exists && mounted) {
        final theme = doc.data()?['chatBubbleTheme'] as String?;
        if (theme != null && theme.isNotEmpty && theme != 'default') {
          setState(() {
            _senderBubbleThemeCache[senderId] = theme;
          });
        }
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final myUid = context.read<AuthController>().user?.uid;
    _stopTypingHeartbeat(myUid);
    _floatingDateHideTimer?.cancel();
    context.read<ChatController>().setActiveChatGroup(null);

    // Persist or clean up draft when disposing
    final rawText = _textController.text;
    if (rawText.trim().isNotEmpty) {
      context.read<LocalSettingsService>().setDraft('group_${widget.groupId}', rawText);
    } else {
      context.read<LocalSettingsService>().clearDraft('group_${widget.groupId}');
    }

    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _textFocusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF79AFFF);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF79AFFF);
  }

  void _fetchMemberIfNeeded(String uid) {
    if (uid.isEmpty || _memberCache.containsKey(uid)) return;
    _userRepo.getUserProfile(uid).then((p) {
      if (p != null && mounted) {
        setState(() {
          _memberCache[uid] = p;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final myUser = context.read<AuthController>().user;
    if (myUser == null) return;

    final userRepo = context.read<UserRepository>();
    final localSettings = context.read<LocalSettingsService>();

    setState(() {
      _isSending = true;
    });

    final replyMsg = _replyingToMessage;
    final postReply = _currentPostReply;
    final postAuthor = _currentPostAuthor;
    _stopTypingHeartbeat(myUser.uid);
    _textController.clear();
    context.read<LocalSettingsService>().clearDraft('group_${widget.groupId}');
    _hasText = false;
    setState(() {
      _replyingToMessage = null;
      _currentPostReply = null;
      _currentPostAuthor = null;
    });

    final myUid = myUser.uid;
    final userProfile = await userRepo.getUserProfile(myUid);
    final senderName = userProfile?.name.isNotEmpty == true
        ? userProfile!.name
        : (userProfile?.username.isNotEmpty == true
            ? '@${userProfile!.username}'
            : 'Thành viên');
    final senderAvatar = userProfile?.avatarUrl ?? '';
    final bubbleThemeId = localSettings.chatBubbleTheme;

    String? postAuthorName;
    String? postAuthorAvatar;
    String? postAuthorFrame;
    String? postOwnerId;

    if (postReply != null) {
      postOwnerId = postReply.userId;
      UserModel? author = postAuthor ?? _memberCache[postReply.userId];
      if (author == null) {
        author = await userRepo.getUserProfile(postReply.userId);
        if (author != null) {
          _memberCache[postReply.userId] = author;
        }
      }
      if (author != null) {
        postAuthorName = author.name.trim().isNotEmpty
            ? author.name.trim()
            : (author.username.trim().isNotEmpty ? author.username.trim() : 'Thành viên');
        postAuthorAvatar = author.avatarUrl;
        postAuthorFrame = author.avatarFrame;
      }
    }

    final success = await _chatRepo.sendGroupMessage(
      groupId: widget.groupId,
      senderId: myUid,
      senderName: senderName,
      senderAvatar: senderAvatar,
      text: text,
      type: postReply != null ? 'post_reply' : 'text',
      bubbleTheme: bubbleThemeId,
      replyToMessageId: replyMsg?.id,
      replyToText: replyMsg?.text,
      replyToSenderName: replyMsg?.senderName ??
          (replyMsg?.senderId == myUid ? 'Bạn' : 'Thành viên'),
      postId: postReply?.id,
      postImageUrl: postReply?.displayImageUrl,
      postCaption: postReply?.caption,
      postCreatedAt: postReply?.createdAt,
      postAuthorName: postAuthorName,
      postAuthorAvatar: postAuthorAvatar,
      postAuthorFrame: postAuthorFrame,
      postOwnerId: postOwnerId,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
      });
      if (success) {
        _scrollToBottom();
      }
    }
  }

  Future<void> _openGroupDetails() async {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (doc.exists && doc.data() != null && mounted) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = widget.groupId;
        data['groupId'] = widget.groupId;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(groupData: data),
          ),
        );
      }
    } catch (_) {}
  }

  void _handleMessageAction(ChatMessageModel msg, MessageMenuAction action, bool isMe, String myUid) {
    switch (action) {
      case MessageMenuAction.reply:
        setState(() {
          _replyingToMessage = msg;
          _currentPostReply = null;
        });
        _textFocusNode.requestFocus();
        break;
      case MessageMenuAction.copy:
        Clipboard.setData(ClipboardData(text: msg.text));
        AppToast.show(context, context.l10n.copiedToClipboard);
        break;
      case MessageMenuAction.unsend:
        _showConfirmUnsendDialog(msg);
        break;
      case MessageMenuAction.deleteForMe:
        _showConfirmDeleteForMeDialog(msg, myUid);
        break;
      case MessageMenuAction.report:
        _showReportMessageSheet(msg, myUid);
        break;
    }
  }

  void _showConfirmUnsendDialog(ChatMessageModel msg) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.unsendConfirm,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          l10n.unsendConfirmDesc,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (DateTime.now().difference(msg.createdAt).inSeconds > 15 * 60) {
                AppToast.show(context, l10n.recallTimeExpired);
                return;
              }
              await _chatRepo.unsendMessage(
                chatId: widget.groupId,
                messageId: msg.id,
              );
            },
            child: Text(l10n.unsend, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteForMeDialog(ChatMessageModel msg, String myUid) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.deleteForMeConfirm,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          l10n.deleteForMeConfirmDesc,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _chatRepo.deleteMessageForMe(
                chatId: widget.groupId,
                messageId: msg.id,
                userId: myUid,
              );
            },
            child: Text(l10n.deleteForMe, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showReportMessageSheet(ChatMessageModel msg, String myUid) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);

    final reasons = [
      l10n.reportSpam,
      l10n.reportInappropriate,
      l10n.reportViolence,
      l10n.reportOther,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E222D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.reportMessage,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.reportMessageDesc,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),
                ...reasons.map((reason) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.radio_button_unchecked_rounded, size: 20),
                    title: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      await _chatRepo.reportMessage(
                        reporterId: myUid,
                        reportedUserId: msg.senderId,
                        messageId: msg.id,
                        messageText: msg.text,
                        reason: reason,
                      );
                      if (mounted) {
                        AppToast.show(
                          context,
                          l10n.reportSuccess,
                          icon: Icons.check_circle_outline_rounded,
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleReaction(ChatMessageModel msg, String emoji, String myUid) {
    _chatRepo.toggleMessageReaction(
      chatId: widget.groupId,
      messageId: msg.id,
      userId: myUid,
      emoji: emoji,
      receiverId: widget.groupId,
      messageText: msg.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = context.read<AuthController>().user?.uid ?? '';
    final parsedGroupColor = _parseHexColor(widget.groupColor);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: _buildAppBar(context, isDark, parsedGroupColor),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                key: _listStackKey,
                children: [
                  StreamBuilder<Map<String, dynamic>>(
                    stream: _chatRepo.streamTypingStatus(widget.groupId),
                    builder: (context, typingSnapshot) {
                      final typingMap = typingSnapshot.data ?? {};
                      final typingUids = typingMap.entries.where((e) {
                        if (e.key == myUid) return false;
                        return e.value == true || e.value is Timestamp;
                      }).map((e) => e.key).toList();

                      final bool isSomeoneTyping = typingUids.isNotEmpty;
                      final String? typingUid =
                          isSomeoneTyping ? typingUids.first : null;
                      UserModel? typingUser =
                          typingUid != null ? _memberCache[typingUid] : null;
                      if (typingUid != null && typingUser == null) {
                        _userRepo.getUserProfile(typingUid).then((profile) {
                          if (profile != null && mounted) {
                            setState(() {
                              _memberCache[typingUid] = profile;
                            });
                          }
                        });
                      }

                      return StreamBuilder<List<ChatMessageModel>>(
                        stream: _chatRepo.getMessagesStream(widget.groupId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final allMessages = snapshot.data ?? [];
                          final messages = allMessages
                              .where((m) => !m.deletedFor.contains(myUid))
                              .toList();

                          if (messages.isNotEmpty && myUid.isNotEmpty) {
                            final hasUnread = messages.any((m) =>
                                !m.readBy.contains(myUid) &&
                                m.senderId != myUid);
                            if (hasUnread) {
                              _chatRepo.markGroupChatAsRead(
                                  widget.groupId, myUid);
                            }
                          }

                          if (messages.isEmpty && !isSomeoneTyping) {
                            return _buildEmptyState(context, isDark);
                          }

                          // Compute latest read message for each member (Messenger Group Seen Avatars)
                          final Map<String, List<String>> messageSeenUids = {};
                          final Set<String> accountedMembers = {myUid};
                          for (final m in messages) {
                            for (final readerUid in m.readBy) {
                              if (!accountedMembers.contains(readerUid)) {
                                messageSeenUids
                                    .putIfAbsent(m.id, () => [])
                                    .add(readerUid);
                                accountedMembers.add(readerUid);
                              }
                            }
                          }

                          final totalItemCount =
                              messages.length + (isSomeoneTyping ? 1 : 0);

                          return NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollUpdateNotification) {
                                _updateFloatingHeader(messages);
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              itemCount: totalItemCount,
                              itemBuilder: (context, index) {
                                if (isSomeoneTyping && index == 0) {
                                  final friendModel = typingUser ??
                                      UserModel(
                                        uid: typingUid ?? '',
                                        email: '',
                                        name: 'Thành viên',
                                        username: 'member',
                                        avatarUrl: '',
                                        currency: 'VND',
                                        language: 'vi',
                                        themeMode: 'dark',
                                        currentStreak: 0,
                                        bestStreak: 0,
                                        createdAt: DateTime.now(),
                                        lastActiveDate: DateTime.now(),
                                      );
                                  return ChatTypingBubble(
                                    friend: friendModel,
                                    isDark: isDark,
                                  );
                                }

                                final msgIndex =
                                    isSomeoneTyping ? index - 1 : index;
                                final msg = messages[msgIndex];
                                final key = _itemKeys.putIfAbsent(
                                  msg.id,
                                  () => GlobalKey(debugLabel: msg.id),
                                );

                                if (msg.isSystem) {
                                  return KeyedSubtree(
                                    key: key,
                                    child: _buildSystemMessagePill(msg, isDark),
                                  );
                                }

                                // Clustering calculations in reversed list
                                // prevMsg is newer (towards bottom, index - 1)
                                // nextMsg is older (towards top, index + 1)
                                final prevMsg =
                                    msgIndex > 0 ? messages[msgIndex - 1] : null;
                                final nextMsg = msgIndex < messages.length - 1
                                    ? messages[msgIndex + 1]
                                    : null;

                                bool isSpecialMsg(ChatMessageModel m) {
                                  final trimmed = m.text.trim();
                                  if (trimmed.isEmpty) return false;
                                  final emojiRegex = RegExp(
                                    r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
                                  );
                                  final isPureEmoji =
                                      emojiRegex.hasMatch(trimmed) &&
                                          trimmed.length <= 4;
                                  return m.type == 'reaction' ||
                                      (m.postImageUrl != null &&
                                          m.postImageUrl!.isNotEmpty) ||
                                      isPureEmoji;
                                }

                                final bool isThisSpecial = isSpecialMsg(msg);
                                final bool isPrevSpecial = prevMsg != null &&
                                    !prevMsg.isSystem &&
                                    isSpecialMsg(prevMsg);
                                final bool isNextSpecial = nextMsg != null &&
                                    !nextMsg.isSystem &&
                                    isSpecialMsg(nextMsg);

                                final bool isFirstInGroup = nextMsg == null ||
                                    nextMsg.isSystem ||
                                    nextMsg.senderId != msg.senderId ||
                                    nextMsg.senderId != msg.senderId ||
                                    isThisSpecial ||
                                    isNextSpecial ||
                                    msg.createdAt
                                            .difference(nextMsg.createdAt)
                                            .inMinutes >=
                                        5;

                                final bool isLastInGroup = prevMsg == null ||
                                    prevMsg.isSystem ||
                                    prevMsg.senderId != msg.senderId ||
                                    isThisSpecial ||
                                    isPrevSpecial ||
                                    prevMsg.createdAt
                                            .difference(msg.createdAt)
                                            .inMinutes >=
                                        5;

                                final bool isDayBoundary = nextMsg == null ||
                                    msg.createdAt.year != nextMsg.createdAt.year ||
                                    msg.createdAt.month !=
                                        nextMsg.createdAt.month ||
                                    msg.createdAt.day != nextMsg.createdAt.day;

                                final bool showTimeHeader = isDayBoundary ||
                                    msg.createdAt
                                            .difference(nextMsg.createdAt)
                                            .inMinutes >=
                                        15;

                                final isMe = msg.senderId == myUid;
                                final senderName =
                                    msg.senderName ?? 'Thành viên';
                                final senderAvatar = msg.senderAvatar ?? '';

                                final friendModel = _memberCache.putIfAbsent(
                                  msg.senderId,
                                  () => UserModel(
                                    uid: msg.senderId,
                                    email: '',
                                    name: senderName,
                                    username: senderName,
                                    avatarUrl: senderAvatar,
                                    currency: 'VND',
                                    language: 'vi',
                                    themeMode: 'dark',
                                    currentStreak: 0,
                                    bestStreak: 0,
                                    createdAt: DateTime.now(),
                                    lastActiveDate: DateTime.now(),
                                  ),
                                );

                                final seenUids = messageSeenUids[msg.id];

                                return KeyedSubtree(
                                  key: key,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showTimeHeader)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          child: Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 13,
                                                vertical: 4.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF1E2430)
                                                        .withValues(alpha: 0.70)
                                                    : const Color(0xFFE5E7EB)
                                                        .withValues(
                                                            alpha: 0.85),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.12)
                                                      : Colors.black.withValues(
                                                          alpha: 0.06),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                _formatSeparatorTime(
                                                    msg.createdAt),
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.80)
                                                      : const Color(0xFF4B5563),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      _GroupChatMessageBubble(
                                        key: ValueKey(msg.id),
                                        message: msg,
                                        isMe: isMe,
                                        myUid: myUid,
                                        friend: friendModel,
                                        isDark: isDark,
                                        isFirstInGroup: isFirstInGroup,
                                        isLastInGroup: isLastInGroup,
                                        timeText: DateFormat('HH:mm')
                                            .format(msg.createdAt),
                                        onDoubleTap: () =>
                                            _toggleReaction(msg, '❤️', myUid),
                                        onReactionTap: (emoji) =>
                                            _toggleReaction(msg, emoji, myUid),
                                        onActionSelected: (action) =>
                                            _handleMessageAction(
                                                msg, action, isMe, myUid),
                                        onSwipeToReply: (message) {
                                          setState(() {
                                            _replyingToMessage = message;
                                            _currentPostReply = null;
                                          });
                                          _textFocusNode.requestFocus();
                                        },
                                        onTapReplySnippet: (replyMsgId) =>
                                            _scrollToMessage(replyMsgId),
                                        fetchSenderThemeIfNeeded:
                                            _fetchSenderThemeIfNeeded,
                                        senderBubbleThemeCache:
                                            _senderBubbleThemeCache,
                                        onTapPost: (postId) => _navigateToPost(postId),
                                        memberCache: _memberCache,
                                        fetchMemberIfNeeded: _fetchMemberIfNeeded,
                                      ),
                                      // Seen member avatars row (Messenger Group Seen Receipts)
                                      if (seenUids != null && seenUids.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                            right: 6,
                                            bottom: 3,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: seenUids.map((uid) {
                                                final member = _memberCache[uid];
                                                if (member == null) {
                                                  _userRepo
                                                      .getUserProfile(uid)
                                                      .then((p) {
                                                    if (p != null && mounted) {
                                                      setState(() =>
                                                          _memberCache[uid] = p);
                                                    }
                                                  });
                                                }
                                                final avatarUrl =
                                                    member?.avatarUrl ?? '';
                                                final frameId =
                                                    member?.avatarFrame ??
                                                        'plain';
                                                final name = member?.name ?? '';
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 3),
                                                  child: avatarUrl.isNotEmpty
                                                      ? AvatarWithFrame(
                                                          avatarUrl: avatarUrl,
                                                          frameId: frameId,
                                                          size: 14,
                                                        )
                                                      : Container(
                                                          width: 14,
                                                          height: 14,
                                                          decoration:
                                                              const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xFF0084FF),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              name.isNotEmpty
                                                                  ? name[0]
                                                                      .toUpperCase()
                                                                  : 'U',
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 7.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),


                  // Floating Sticky Date Header
                  if (_showFloatingDate && _floatingDateText.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _showFloatingDate ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF181C26).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.08),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder: (currentChild, previousChildren) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: <Widget>[
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  );
                                },
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0, 0.10),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );

                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: slide,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  _floatingDateText,
                                  key: ValueKey<String>(_floatingDateText),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Floating Scroll-to-Bottom Button (transforms into typing dots when someone is typing)
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: StreamBuilder<Map<String, dynamic>>(
                      stream: _chatRepo.streamTypingStatus(widget.groupId),
                      builder: (context, snapshot) {
                        final typingMap = snapshot.data ?? {};
                        final typingUsers = typingMap.entries.where((e) {
                          if (e.key == myUid) return false;
                          return e.value == true || e.value is Timestamp;
                        }).toList();

                        final isFriendTyping = typingUsers.isNotEmpty;
                        final firstTypingUid =
                            typingUsers.isNotEmpty ? typingUsers.first.key : null;
                        final typingFriend = firstTypingUid != null
                            ? _memberCache[firstTypingUid]
                            : null;
                        if (firstTypingUid != null && typingFriend == null) {
                          _userRepo.getUserProfile(firstTypingUid).then((profile) {
                            if (profile != null && mounted) {
                              setState(() {
                                _memberCache[firstTypingUid] = profile;
                              });
                            }
                          });
                        }

                        return ChatScrollToBottomButton(
                          isVisible: _showScrollToBottom,
                          isFriendTyping: isFriendTyping,
                          friend: typingFriend,
                          isDark: isDark,
                          onTap: _scrollToBottom,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Replying banner
            if (_replyingToMessage != null) _buildReplyBanner(context, isDark),
            if (_currentPostReply != null) _buildPostReplyBanner(context, isDark),

            // Input Bar
            _buildInputBar(context, isDark),

            // Quick Emoji Grid
            if (_showEmojiGrid) _buildEmojiGrid(context, isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color groupColor,
  ) {
    return AppBar(
      backgroundColor: AppColors.card(context),
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary(context),
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.groupId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final currentName =
              (data?['groupName'] as String?)?.trim() ?? widget.groupName;
          final participants = (data?['participants'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              widget.memberUids ??
              [];
          final memberCount = participants.length;

          return InkWell(
            onTap: _openGroupDetails,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: groupColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: groupColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                currentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: groupColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                context.l10n.groupBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: groupColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Builder(
                          builder: (context) {
                            final myUid =
                                context.read<AuthController>().user?.uid ?? '';
                            final typingData =
                                data?['typing'] as Map<String, dynamic>?;
                            final typingUids = (typingData?.entries ?? [])
                                .where((e) {
                                  if (e.key == myUid) return false;
                                  return e.value == true || e.value is Timestamp;
                                })
                                .map((e) => e.key)
                                .toList();

                            if (typingUids.isNotEmpty) {
                              final firstTypingUid = typingUids.first;
                              final typingUser = _memberCache[firstTypingUid];
                              final displayName =
                                  typingUser?.name.trim().isNotEmpty == true
                                      ? typingUser!.name.trim()
                                      : (typingUser?.username.trim().isNotEmpty ==
                                              true
                                          ? typingUser!.username.trim()
                                          : 'Thành viên');

                              String typingText;
                              if (typingUids.length > 1) {
                                typingText =
                                    '${typingUids.length} người đang soạn tin...';
                              } else {
                                typingText =
                                    '$displayName ${context.l10n.isTyping.toLowerCase()}';
                              }

                              return Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      typingText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const TypingDotsIndicator(
                                    dotSize: 3.5,
                                    spacing: 2,
                                    color: AppColors.primaryBlue,
                                  ),
                                ],
                              );
                            }

                            return Text(
                              context.l10n.groupMembersCount(memberCount),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            );
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
      actions: [
        IconButton(
          icon: Icon(
            Icons.info_outline_rounded,
            color: AppColors.textPrimary(context),
            size: 22,
          ),
          onPressed: _openGroupDetails,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 34,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.groupName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Welcome to the group! Start the conversation now.'
                  : 'Chào mừng mọi người đến với nhóm! Hãy bắt đầu cuộc trò chuyện ngay bây giờ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resolveHistoricalExpensePost(ChatMessageModel msg) {
    if (msg.postId != null && msg.postId!.isNotEmpty) return;
    if (_resolvingExpenseIds.contains(msg.id)) return;
    _resolvingExpenseIds.add(msg.id);

    _txRepo
        .findGroupExpenseTransaction(
      groupId: widget.groupId,
      messageTime: msg.createdAt,
      actorUid: msg.senderId != 'system' ? msg.senderId : null,
    )
        .then((tx) {
      if (mounted && tx != null) {
        setState(() {
          _resolvedExpensePosts[msg.id] = tx;
        });
      }
    });
  }

  void _navigateToPost(String postId) {
    HapticFeedback.lightImpact();
    context.read<FeedController>().setTargetPostId(postId);
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.mainShell,
      (route) => false,
      arguments: {
        'initialIndex': 2,
        'targetPostId': postId,
      },
    );
  }

  Future<void> _handleSystemPostTap(String postId, ChatMessageModel msg) async {
    HapticFeedback.lightImpact();
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null) return;

    TransactionModel? tx = _resolvedExpensePosts[msg.id];
    if (tx == null) {
      tx = await _txRepo.fetchTransactionById(postId, groupId: widget.groupId);
      if (tx != null && mounted) {
        setState(() {
          _resolvedExpensePosts[msg.id] = tx;
        });
      }
    }

    String? authorUid = (msg.senderId != 'system' && msg.senderId.isNotEmpty)
        ? msg.senderId
        : tx?.userId;

    if (authorUid == null || authorUid.isEmpty) {
      if (tx != null && tx.userId.isNotEmpty) {
        authorUid = tx.userId;
      }
    }

    final isMe = (authorUid == myUid);
    bool isFriend = isMe;
    if (!isFriend && authorUid != null && authorUid.isNotEmpty) {
      isFriend = await _userRepo.areFriends(myUid, authorUid);
    }

    if (!mounted) return;

    if (isFriend) {
      _navigateToPost(postId);
    } else {
      _showMomentDetailModal(
        postId: postId,
        msg: msg,
        tx: tx,
        authorUid: authorUid,
      );
    }
  }

  void _showMomentDetailModal({
    required String postId,
    required ChatMessageModel msg,
    TransactionModel? tx,
    String? authorUid,
  }) async {
    UserModel? author;
    if (authorUid != null && authorUid.isNotEmpty) {
      author = _memberCache[authorUid];
      if (author == null) {
        author = await _userRepo.getUserProfile(authorUid);
        if (author != null && mounted) {
          _memberCache[authorUid] = author;
        }
      }
    }

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final l10n = context.l10n;

    final authorName = author?.name.isNotEmpty == true
        ? author!.name
        : (author?.username.isNotEmpty == true
            ? '@${author!.username}'
            : (msg.postAuthorName ?? l10n.member));
    final authorUsername = author?.username.isNotEmpty == true
        ? '@${author!.username}'
        : '';
    final authorAvatar = author?.avatarUrl ?? msg.postAuthorAvatar ?? '';
    final authorFrame = author?.avatarFrame ?? msg.postAuthorFrame;

    final imageUrl = (tx?.imageUrl.isNotEmpty == true ? tx!.imageUrl : null) ??
        (msg.postImageUrl?.isNotEmpty == true ? msg.postImageUrl : null) ??
        (tx?.thumbnailUrl.isNotEmpty == true ? tx!.thumbnailUrl : null) ??
        (tx?.mediaUrl.isNotEmpty == true ? tx!.mediaUrl : null);

    final caption = tx?.caption.isNotEmpty == true
        ? tx!.caption
        : (msg.postCaption?.isNotEmpty == true ? msg.postCaption : tx?.note);

    final postTime = tx?.createdAt ?? msg.postCreatedAt ?? msg.createdAt;
    final timeStr = _formatFeedTime(context, postTime);

    final rawTextLower = msg.text.toLowerCase();
    final isFund = rawTextLower.contains('đóng góp') ||
        rawTextLower.contains('nạp') ||
        rawTextLower.contains('quỹ nhóm') ||
        rawTextLower.contains('contributed') ||
        rawTextLower.contains('deposited') ||
        rawTextLower.contains('group fund') ||
        (tx?.isGroupContribution == true);

    final double amount = tx?.amount ?? 0;
    final amountFormatted = amount > 0
        ? AppCurrencyFormatter.formatFromVnd(amountVnd: amount, currency: 'VND')
        : '';

    final typeColor = isFund ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final typeLabel = isFund
        ? (isEn ? 'Group Fund Deposit' : 'Nạp quỹ nhóm')
        : (isEn ? 'Group Expense' : 'Chi tiêu nhóm');
    final typeIcon = isFund ? Icons.savings_rounded : Icons.receipt_long_rounded;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181D26) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              typeIcon,
                              size: 18,
                              color: typeColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.momentDetails,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            icon: const Icon(Icons.close_rounded),
                            color: isDark ? Colors.white60 : Colors.black54,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notice Banner: You are not friends with the author
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.28 : 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.notFriendsGroupPostNotice,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Author Info Row
                      Row(
                        children: [
                          if (authorAvatar.isNotEmpty)
                            AvatarWithFrame(
                              avatarUrl: authorAvatar,
                              frameId: authorFrame,
                              size: 38,
                            )
                          else
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF374151),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(authorName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (authorUsername.isNotEmpty)
                                  Text(
                                    authorUsername,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Image Card
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 1.12,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: isDark ? const Color(0xFF252D3D) : const Color(0xFFF3F4F6),
                                    child: const Center(
                                      child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(typeIcon, color: typeColor, size: 13),
                                        const SizedBox(width: 5),
                                        Text(
                                          typeLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Transaction Info Strip: Amount & Category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: typeColor.withValues(alpha: isDark ? 0.28 : 0.18),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: typeColor,
                                  ),
                                ),
                                if (tx != null && tx.category.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    BudgetNameLocalizer.display(context, tx.category),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (amountFormatted.isNotEmpty)
                              Text(
                                '${isFund ? '+' : '-'}$amountFormatted',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: typeColor,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Caption
                      if (caption != null && caption.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF222834) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            caption.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Action Button (Send friend request or Close)
                      if (authorUid != null && authorUid.isNotEmpty)
                        _buildMomentAddFriendButton(
                          authorUid: authorUid,
                          author: author,
                          isDark: isDark,
                          l10n: l10n,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatFeedTime(BuildContext context, DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return context.l10n.justNow;
    }

    if (diff.inMinutes < 60) {
      return context.l10n.minutesAgo(diff.inMinutes);
    }

    if (diff.inHours < 24) {
      return context.l10n.hoursAgo(diff.inHours);
    }

    if (diff.inDays <= 7) {
      return context.l10n.daysAgo(diff.inDays);
    }

    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    if (now.year == createdAt.year) {
      return isVi
          ? '${createdAt.day} thg ${createdAt.month}'
          : DateFormat('d MMM', 'en').format(createdAt);
    }
    return isVi
        ? '${createdAt.day} thg ${createdAt.month}, ${createdAt.year}'
        : DateFormat('d MMM, y', 'en').format(createdAt);
  }

  Widget _buildMomentAddFriendButton({
    required String authorUid,
    UserModel? author,
    required bool isDark,
    required dynamic l10n,
  }) {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null || myUid == authorUid) return const SizedBox.shrink();

    return FutureBuilder<AddFriendConnectionState>(
      future: _userRepo.checkConnectionState(myUid, authorUid),
      builder: (context, snapshot) {
        final state = snapshot.data ?? AddFriendConnectionState.canSend;

        if (state == AddFriendConnectionState.alreadyFriends) {
          return const SizedBox.shrink();
        }

        if (state == AddFriendConnectionState.pendingSent) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.done_rounded, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                const SizedBox(width: 6),
                Text(
                  l10n.friendRequestSent,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }

        return ElevatedButton.icon(
          onPressed: () async {
            HapticFeedback.lightImpact();
            try {
              final target = author ?? await _userRepo.getUserProfile(authorUid);
              if (target != null) {
                await _userRepo.sendFriendRequest(
                  myUid: myUid,
                  targetUser: target,
                );
                if (context.mounted) {
                  AppToast.show(context, l10n.friendRequestSent);
                }
              }
            } catch (_) {}
          },
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: Text(
            l10n.addFriend,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        );
      },
    );
  }

  Widget _buildSystemMessagePill(ChatMessageModel msg, bool isDark) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);
    final text = GroupChatConversationScreen.localizeGroupSystemText(context, msg.text);
    final rawTextLower = msg.text.toLowerCase();

    Color badgeColor;
    Color iconColor;
    IconData iconData;
    String categoryLabel;

    final isFund = rawTextLower.contains('đóng góp') ||
        rawTextLower.contains('nạp') ||
        rawTextLower.contains('quỹ nhóm') ||
        rawTextLower.contains('contributed') ||
        rawTextLower.contains('deposited') ||
        rawTextLower.contains('group fund');
    final isExpense = rawTextLower.contains('chi tiêu') ||
        rawTextLower.contains('đã tiêu') ||
        rawTextLower.contains('expense') ||
        rawTextLower.contains('spending');
    final isMemberAdd = (rawTextLower.contains('thêm') && rawTextLower.contains('nhóm')) ||
        (rawTextLower.contains('added') && rawTextLower.contains('group'));
    final isMemberRemove = rawTextLower.contains('xoá') ||
        rawTextLower.contains('rời khỏi nhóm') ||
        rawTextLower.contains('rời nhóm') ||
        rawTextLower.contains('removed') ||
        rawTextLower.contains('left the group');
    final isCreated = rawTextLower.contains('tạo nhóm') ||
        rawTextLower.contains('được tạo') ||
        rawTextLower.contains('created group');

    if (isFund) {
      badgeColor = const Color(0xFF10B981);
      iconColor = const Color(0xFF10B981);
      iconData = Icons.savings_rounded;
      categoryLabel = isEn ? 'Group Fund' : 'Quỹ nhóm';
    } else if (isExpense) {
      badgeColor = const Color(0xFFF59E0B);
      iconColor = const Color(0xFFF59E0B);
      iconData = Icons.receipt_long_rounded;
      categoryLabel = isEn ? 'Expense' : 'Chi tiêu';
    } else if (isMemberAdd) {
      badgeColor = const Color(0xFF3B82F6);
      iconColor = const Color(0xFF3B82F6);
      iconData = Icons.person_add_rounded;
      categoryLabel = isEn ? 'Member' : 'Thành viên';
    } else if (isMemberRemove) {
      badgeColor = const Color(0xFFEF4444);
      iconColor = const Color(0xFFEF4444);
      iconData = Icons.person_remove_rounded;
      categoryLabel = isEn ? 'Member' : 'Thành viên';
    } else if (isCreated) {
      badgeColor = const Color(0xFF8B5CF6);
      iconColor = const Color(0xFF8B5CF6);
      iconData = Icons.celebration_rounded;
      categoryLabel = isEn ? 'Created' : 'Khởi tạo';
    } else {
      badgeColor = isDark ? Colors.white60 : Colors.black54;
      iconColor = isDark ? Colors.white70 : Colors.black87;
      iconData = Icons.notifications_active_outlined;
      categoryLabel = isEn ? 'System' : 'Hệ thống';
    }

    String? targetPostId = msg.postId;
    String? postImageUrl = msg.postImageUrl;
    String? postCaption = msg.postCaption;

    if (isExpense || isFund) {
      if (targetPostId == null || targetPostId.isEmpty) {
        final resolved = _resolvedExpensePosts[msg.id];
        if (resolved != null) {
          targetPostId = resolved.id;
          postImageUrl = resolved.imageUrl.isNotEmpty
              ? resolved.imageUrl
              : (resolved.thumbnailUrl.isNotEmpty
                  ? resolved.thumbnailUrl
                  : resolved.mediaUrl);
          postCaption = resolved.caption.isNotEmpty ? resolved.caption : resolved.note;
        } else {
          _resolveHistoricalExpensePost(msg);
        }
      }
    }

    final hasTargetPost = targetPostId != null && targetPostId.isNotEmpty;
    final hasPostImage = postImageUrl != null && postImageUrl.isNotEmpty;

    final pillWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasTargetPost ? () => _handleSystemPostTap(targetPostId!, msg) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: badgeColor.withValues(alpha: isDark ? 0.25 : 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 14,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$categoryLabel: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                      TextSpan(
                        text: '$text • $timeStr',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasTargetPost) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: iconColor.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if ((!isExpense && !isFund) || !hasTargetPost) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: pillWidget,
        ),
      );
    }

    final cardAccentColor = isFund ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final cardBadgeIcon = isFund ? Icons.savings_rounded : Icons.receipt_long_rounded;
    final cardBadgeText = isFund
        ? (isEn ? 'Group Fund' : 'Nạp quỹ nhóm')
        : (isEn ? 'Group Expense' : 'Chi tiêu nhóm');

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            pillWidget,
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _handleSystemPostTap(targetPostId!, msg),
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2430) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cardAccentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPostImage)
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 1.15,
                              child: Image.network(
                                postImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: isDark
                                      ? const Color(0xFF252D3D)
                                      : const Color(0xFFF3F4F6),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.35),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.65),
                                    ],
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cardBadgeIcon,
                                      color: cardAccentColor,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      cardBadgeText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (postCaption != null && postCaption.trim().isNotEmpty)
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 8,
                                child: Text(
                                  postCaption.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF181D26)
                              : (isFund ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  size: 14,
                                  color: isDark
                                      ? (isFund ? const Color(0xFF34D399) : const Color(0xFFFBBF24))
                                      : (isFund ? const Color(0xFF059669) : const Color(0xFFD97706)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isEn ? 'View moment' : 'Xem khoảnh khắc',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? (isFund ? const Color(0xFF34D399) : const Color(0xFFFBBF24))
                                        : (isFund ? const Color(0xFF059669) : const Color(0xFFD97706)),
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: isDark
                                  ? (isFund ? const Color(0xFF34D399) : const Color(0xFFFBBF24))
                                  : (isFund ? const Color(0xFF059669) : const Color(0xFFD97706)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBanner(BuildContext context, bool isDark) {
    final replyMsg = _replyingToMessage!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Replying to ${replyMsg.senderName ?? 'Member'}'
                      : 'Đang trả lời ${replyMsg.senderName ?? 'Thành viên'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyMsg.text.isNotEmpty
                      ? replyMsg.text
                      : (Localizations.localeOf(context).languageCode == 'en'
                          ? 'Message'
                          : 'Tin nhắn'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary(context),
            ),
            onPressed: () {
              setState(() {
                _replyingToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostReplyBanner(BuildContext context, bool isDark) {
    final post = _currentPostReply!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E212B) : const Color(0xFFEFF6FF),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFBFDBFE),
          ),
        ),
      ),
      child: Row(
        children: [
          if (post.displayImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                post.displayImageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.reply_rounded,
                      size: 15,
                      color: Color(0xFF0084FF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? 'Replying to post'
                          : 'Đang trả lời bài viết',
                      style: const TextStyle(
                        color: Color(0xFF0084FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  post.caption.isNotEmpty ? post.caption : 'Khoảnh khắc',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            onPressed: () => setState(() => _currentPostReply = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _showEmojiGrid
                  ? Icons.keyboard_rounded
                  : Icons.sentiment_satisfied_alt_rounded,
              color: _showEmojiGrid
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary(context),
              size: 24,
            ),
            onPressed: () {
              if (_showEmojiGrid) {
                setState(() => _showEmojiGrid = false);
                _textFocusNode.requestFocus();
              } else {
                FocusScope.of(context).unfocus();
                setState(() => _showEmojiGrid = true);
              }
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _textFocusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textPrimary(context),
                ),
                decoration: InputDecoration(
                  hintText: isEn ? 'Type a group message...' : 'Nhập tin nhắn nhóm...',
                  hintStyle: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textSecondary(context).withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
                onTap: () {
                  if (_showEmojiGrid) {
                    setState(() => _showEmojiGrid = false);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedScale(
            scale: _hasText ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 150),
            child: IconButton(
              onPressed: _hasText && !_isSending ? _sendMessage : null,
              icon: Icon(
                Icons.send_rounded,
                color: _hasText
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary(context).withValues(alpha: 0.35),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid(BuildContext context, bool isDark) {
    return Container(
      height: 220,
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: emojiList.length,
        itemBuilder: (context, index) {
          final emoji = emojiList[index];
          return InkWell(
            onTap: () {
              final text = _textController.text;
              final selection = _textController.selection;
              final newText = selection.textBefore(text) + emoji + selection.textAfter(text);
              _textController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: selection.baseOffset + emoji.length,
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GroupChatMessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String myUid;
  final UserModel friend;
  final bool isDark;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final String timeText;
  final VoidCallback onDoubleTap;
  final ValueChanged<String> onReactionTap;
  final ValueChanged<MessageMenuAction> onActionSelected;
  final ValueChanged<ChatMessageModel> onSwipeToReply;
  final ValueChanged<String> onTapReplySnippet;
  final void Function(String senderId) fetchSenderThemeIfNeeded;
  final Map<String, String> senderBubbleThemeCache;
  final ValueChanged<String>? onTapPost;
  final Map<String, UserModel>? memberCache;
  final ValueChanged<String>? fetchMemberIfNeeded;

  const _GroupChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.myUid,
    required this.friend,
    required this.isDark,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.timeText,
    required this.onDoubleTap,
    required this.onReactionTap,
    required this.onActionSelected,
    required this.onSwipeToReply,
    required this.onTapReplySnippet,
    required this.fetchSenderThemeIfNeeded,
    required this.senderBubbleThemeCache,
    this.onTapPost,
    this.memberCache,
    this.fetchMemberIfNeeded,
  });

  @override
  State<_GroupChatMessageBubble> createState() => _GroupChatMessageBubbleState();
}

class _GroupChatMessageBubbleState extends State<_GroupChatMessageBubble>
    with SingleTickerProviderStateMixin {
  final GlobalKey _bubbleContentKey = GlobalKey();
  bool _showDetails = false;
  double _dragOffset = 0.0;
  AnimationController? _animController;
  Animation<double>? _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  void _openActionMenu() {
    MessageActionMenuOverlay.show(
      context: context,
      message: widget.message,
      isMe: widget.isMe,
      friend: widget.friend,
      messageKey: _bubbleContentKey,
      messageChild: _buildBubbleContent(context),
      onSelectReaction: widget.onReactionTap,
      onSelectAction: widget.onActionSelected,
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta != null) {
      setState(() {
        if (widget.isMe) {
          _dragOffset = (_dragOffset + details.primaryDelta!).clamp(-56.0, 0.0);
        } else {
          _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, 56.0);
        }
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final absOffset = _dragOffset.abs();
    if (absOffset >= 32.0) {
      if (!widget.message.isRecalled) {
        HapticFeedback.mediumImpact();
        widget.onSwipeToReply(widget.message);
      }
    }
    _anim = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animController!, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragOffset = _anim!.value;
        });
      });
    _animController!.forward(from: 0.0);
  }

  bool _isPureEmoji(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final emojiRegex = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
    );
    return emojiRegex.hasMatch(trimmed) && trimmed.length <= 4;
  }

  BorderRadius _getBubbleBorderRadius() {
    const double rLarge = 18.0;
    const double rSmall = 4.0;

    if (widget.isMe) {
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return BorderRadius.circular(rLarge);
      }
      if (widget.isFirstInGroup && !widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(rLarge),
          topRight: Radius.circular(rLarge),
          bottomLeft: Radius.circular(rLarge),
          bottomRight: Radius.circular(rSmall),
        );
      }
      if (!widget.isFirstInGroup && !widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(rLarge),
          topRight: Radius.circular(rSmall),
          bottomLeft: Radius.circular(rLarge),
          bottomRight: Radius.circular(rSmall),
        );
      }
      return const BorderRadius.only(
        topLeft: Radius.circular(rLarge),
        topRight: Radius.circular(rSmall),
        bottomLeft: Radius.circular(rLarge),
        bottomRight: Radius.circular(rLarge),
      );
    } else {
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return BorderRadius.circular(rLarge);
      }
      if (widget.isFirstInGroup && !widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(rLarge),
          topRight: Radius.circular(rLarge),
          bottomLeft: Radius.circular(rSmall),
          bottomRight: Radius.circular(rLarge),
        );
      }
      if (!widget.isFirstInGroup && !widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(rSmall),
          topRight: Radius.circular(rLarge),
          bottomLeft: Radius.circular(rSmall),
          bottomRight: Radius.circular(rLarge),
        );
      }
      return const BorderRadius.only(
        topLeft: Radius.circular(rSmall),
        topRight: Radius.circular(rLarge),
        bottomLeft: Radius.circular(rLarge),
        bottomRight: Radius.circular(rLarge),
      );
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatFeedTime(BuildContext context, DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return context.l10n.justNow;
    }

    if (diff.inMinutes < 60) {
      return context.l10n.minutesAgo(diff.inMinutes);
    }

    if (diff.inHours < 24) {
      return context.l10n.hoursAgo(diff.inHours);
    }

    if (diff.inDays <= 7) {
      return context.l10n.daysAgo(diff.inDays);
    }

    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    if (now.year == createdAt.year) {
      return isVi
          ? '${createdAt.day} thg ${createdAt.month}'
          : DateFormat('d MMM', 'en').format(createdAt);
    }
    return isVi
        ? '${createdAt.day} thg ${createdAt.month}, ${createdAt.year}'
        : DateFormat('d MMM, y', 'en').format(createdAt);
  }

  Widget _buildFriendAvatar({bool forceShow = false}) {
    if (widget.isMe) return const SizedBox.shrink();

    final shouldShow = forceShow || widget.isLastInGroup;
    if (shouldShow) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: widget.friend.avatarUrl.isNotEmpty
            ? AvatarWithFrame(
                avatarUrl: widget.friend.avatarUrl,
                frameId: widget.friend.avatarFrame,
                size: 28,
              )
            : Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                ),
                child: Center(
                  child: Text(
                    _getInitials(widget.friend.name),
                    style: TextStyle(
                      color: widget.isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      );
    }

    // Keep space aligned for consecutive messages
    return const SizedBox(width: 36);
  }

  Widget _buildQuotedReplyHeader() {
    if (widget.message.replyToText == null ||
        widget.message.replyToText!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isMe = widget.isMe;
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 3, left: isMe ? 0 : 36),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.reply_rounded,
                size: 13.5,
                color: widget.isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              Text(
                () {
                  final l10n = context.l10n;
                  final senderName = widget.message.replyToSenderName ?? 'Thành viên';
                  if (isMe) {
                    final isReplyToSelf = senderName == 'chính mình' ||
                        senderName == 'yourself' ||
                        senderName == 'You';
                    if (isReplyToSelf) {
                      return l10n.youRepliedToYourself;
                    } else {
                      return l10n.youRepliedToUser(senderName);
                    }
                  } else {
                    final isReplyToThemself = senderName == 'chính mình' ||
                        senderName == 'yourself' ||
                        senderName == widget.friend.name ||
                        senderName == widget.friend.username;
                    if (isReplyToThemself) {
                      return l10n.userRepliedToThemself(widget.friend.name.isNotEmpty ? widget.friend.name : widget.friend.username);
                    } else {
                      return l10n.userRepliedToYou(widget.friend.name.isNotEmpty ? widget.friend.name : widget.friend.username);
                    }
                  }
                }(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(bottom: 4, left: isMe ? 0 : 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xFF22242A)
                : const Color(0xFFE2E4E8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.message.replyToText!.trim().isNotEmpty
                ? widget.message.replyToText!
                : context.l10n.messageRecalled,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontStyle: widget.message.replyToText!.trim().isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: widget.isDark ? Colors.white70 : const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildBubbleContent(BuildContext context) {
    // 0. Recalled Message State (Displays elegant recalled bubble for everyone)
    if (widget.message.isRecalled) {
      final borderRadius = _getBubbleBorderRadius();
      return Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.isFirstInGroup)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 3),
              child: Text(
                widget.friend.name.isNotEmpty
                    ? widget.friend.name
                    : widget.friend.username,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFriendAvatar(),
              GestureDetector(
                onTap: () => setState(() => _showDetails = !_showDetails),
                onLongPress: _openActionMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 15,
                        color: widget.isDark
                            ? Colors.white54
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.messageRecalled,
                        style: TextStyle(
                          color: widget.isDark
                              ? Colors.white54
                              : const Color(0xFF6B7280),
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildStatusLine(context),
        ],
      );
    }

    Widget content;
    final currentThemeId = widget.isMe
        ? context.read<LocalSettingsService>().chatBubbleTheme
        : (widget.message.bubbleTheme?.isNotEmpty == true
            ? widget.message.bubbleTheme!
            : (widget.senderBubbleThemeCache[widget.message.senderId] ?? 'default'));
    final currentTheme = ChatBubbleTheme.getTheme(currentThemeId);

    if (currentThemeId == 'default' &&
        !widget.isMe &&
        !widget.senderBubbleThemeCache.containsKey(widget.message.senderId)) {
      widget.fetchSenderThemeIfNeeded(widget.message.senderId);
    }

    final hasPost = widget.message.postImageUrl != null &&
        widget.message.postImageUrl!.isNotEmpty;
    final isPureEmojiMessage = _isPureEmoji(widget.message.text);

    if (hasPost) {
      final screenWidth = MediaQuery.of(context).size.width;
      final cardSize = (screenWidth * 0.74).clamp(220.0, 290.0);
      final postTimeAgo = _formatFeedTime(
        context,
        widget.message.postCreatedAt ?? widget.message.createdAt,
      );

      UserModel? cachedOwner;
      if (widget.message.postOwnerId != null &&
          widget.message.postOwnerId!.isNotEmpty &&
          widget.memberCache != null) {
        cachedOwner = widget.memberCache![widget.message.postOwnerId!];
      }

      final authorName = widget.message.postAuthorName?.trim().isNotEmpty == true
          ? widget.message.postAuthorName!.trim()
          : (cachedOwner?.name.trim().isNotEmpty == true
              ? cachedOwner!.name.trim()
              : (cachedOwner?.username.trim().isNotEmpty == true
                  ? cachedOwner!.username.trim()
                  : (widget.friend.name.trim().isNotEmpty
                      ? widget.friend.name.trim()
                      : widget.friend.username.trim())));

      final authorAvatar = widget.message.postAuthorAvatar ??
          cachedOwner?.avatarUrl ??
          widget.friend.avatarUrl;

      final authorFrame = widget.message.postAuthorFrame ??
          cachedOwner?.avatarFrame ??
          widget.friend.avatarFrame;

      if (widget.message.postOwnerId != null &&
          widget.message.postOwnerId!.isNotEmpty &&
          cachedOwner == null &&
          widget.fetchMemberIfNeeded != null) {
        widget.fetchMemberIfNeeded!(widget.message.postOwnerId!);
      }

      content = Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isMe && widget.isFirstInGroup)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 3),
              child: Text(
                widget.friend.name.isNotEmpty
                    ? widget.friend.name
                    : widget.friend.username,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          _buildQuotedReplyHeader(),

          // Full Rounded Post Preview Card (tap to view post)
          GestureDetector(
            onTap: () {
              if (widget.message.postId != null &&
                  widget.message.postId!.isNotEmpty &&
                  widget.onTapPost != null) {
                widget.onTapPost!(widget.message.postId!);
              }
            },
            child: Container(
              margin: EdgeInsets.only(
                left: widget.isMe ? 0 : 36,
              ),
              width: cardSize,
              height: cardSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.message.postImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: const Color(0xFF1E2430)),
                    ),

                    // Subtle dark gradient from top and bottom for readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.70),
                            ],
                            stops: const [0.0, 0.28, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Post author info & time
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: [
                          if (authorAvatar.isNotEmpty)
                            AvatarWithFrame(
                              avatarUrl: authorAvatar,
                              frameId: authorFrame,
                              size: 24,
                            )
                          else
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF374151),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(authorName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                          if (postTimeAgo.isNotEmpty)
                            Text(
                              postTimeAgo,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Post caption badge pinned at bottom
                    if (widget.message.postCaption != null &&
                        widget.message.postCaption!.isNotEmpty)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              widget.message.postCaption!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Standalone message bubble below the post card
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFriendAvatar(forceShow: true),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_isPureEmoji(widget.message.text) || widget.message.type == 'reaction') ...[
                    GestureDetector(
                      onDoubleTap: widget.onDoubleTap,
                      onLongPress: _openActionMenu,
                      child: Text(
                        widget.message.text,
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () => setState(() => _showDetails = !_showDetails),
                      onDoubleTap: widget.onDoubleTap,
                      onLongPress: _openActionMenu,
                      child: (widget.isMe || !currentTheme.isDefault)
                          ? ChatBubbleDecoratedBox(
                              theme: currentTheme,
                              isMe: widget.isMe,
                              customBorderRadius: BorderRadius.circular(20),
                              child: Text(
                                widget.message.text,
                                style: TextStyle(
                                  color: currentTheme.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isDark
                                    ? const Color(0xFF242526)
                                    : const Color(0xFFE4E6EB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.message.text,
                                style: TextStyle(
                                  color: widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF050505),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                    ),
                  ],
                  if (widget.message.reactions.isNotEmpty)
                    Positioned(
                      bottom: -10,
                      right: widget.isMe ? 6 : null,
                      left: widget.isMe ? null : 6,
                      child: GestureDetector(
                        onTap: _openActionMenu,
                        child: _buildReactionsBadge(),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (widget.message.reactions.isNotEmpty) const SizedBox(height: 6),
          _buildStatusLine(context),
        ],
      );
    } else if (isPureEmojiMessage || widget.message.type == 'reaction') {
      content = Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.isFirstInGroup)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 3),
              child: Text(
                widget.friend.name.isNotEmpty
                    ? widget.friend.name
                    : widget.friend.username,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          _buildQuotedReplyHeader(),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFriendAvatar(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showDetails = !_showDetails),
                    onDoubleTap: widget.onDoubleTap,
                    onLongPress: _openActionMenu,
                    child: Text(
                      widget.message.text,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                  if (widget.message.reactions.isNotEmpty)
                    Positioned(
                      bottom: -10,
                      right: widget.isMe ? 2 : null,
                      left: widget.isMe ? null : 2,
                      child: _buildReactionsBadge(),
                    ),
                ],
              ),
            ],
          ),
          if (widget.message.reactions.isNotEmpty) const SizedBox(height: 6),
          _buildStatusLine(context),
        ],
      );
    } else {
      final isUrl = widget.message.text.startsWith('http://') ||
          widget.message.text.startsWith('https://');

      content = Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isMe && widget.isFirstInGroup)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 3),
              child: Text(
                widget.friend.name.isNotEmpty
                    ? widget.friend.name
                    : widget.friend.username,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          _buildQuotedReplyHeader(),
          Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFriendAvatar(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showDetails = !_showDetails),
                    onDoubleTap: widget.onDoubleTap,
                    onLongPress: _openActionMenu,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      child: (widget.isMe || !currentTheme.isDefault)
                          ? ChatBubbleDecoratedBox(
                              theme: currentTheme,
                              isMe: widget.isMe,
                              customBorderRadius: _getBubbleBorderRadius(),
                              child: Text(
                                widget.message.text,
                                style: TextStyle(
                                  color: currentTheme.textColor,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                  decoration: isUrl
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isDark
                                    ? const Color(0xFF242526)
                                    : const Color(0xFFE4E6EB),
                                borderRadius: _getBubbleBorderRadius(),
                              ),
                              child: Text(
                                widget.message.text,
                                style: TextStyle(
                                  color: widget.isDark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                  decoration: isUrl
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (widget.message.reactions.isNotEmpty)
                    Positioned(
                      bottom: -13,
                      right: widget.isMe ? 6 : null,
                      left: widget.isMe ? null : 6,
                      child: _buildReactionsBadge(),
                    ),
                ],
              ),
            ],
          ),
          if (widget.message.reactions.isNotEmpty) const SizedBox(height: 8),
          _buildStatusLine(context),
        ],
      );
    }
    return content;
  }

  Widget _buildReactionsBadge() {
    final reactions = widget.message.reactions;
    if (reactions.isEmpty) return const SizedBox.shrink();

    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openActionMenu,
      onLongPress: _openActionMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF242526) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDark ? Colors.black : const Color(0xFFE4E6EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...counts.entries.map((e) => Text(
                  e.key,
                  style: const TextStyle(fontSize: 12),
                )),
            if (reactions.length > 1) ...[
              const SizedBox(width: 3),
              Text(
                '${reactions.length}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLine(BuildContext context) {
    final shouldShow = _showDetails || widget.isLastInGroup;
    if (!shouldShow) return const SizedBox.shrink();

    if (!widget.isMe) {
      if (!_showDetails && !widget.isLastInGroup) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 36, top: 4),
        child: Text(
          widget.timeText,
          style: TextStyle(
            color: widget.isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.isLastInGroup || _showDetails)
            Text(
              widget.timeText,
              style: TextStyle(
                color: widget.isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final hasReactions = widget.message.reactions.isNotEmpty;
    final verticalPadding = widget.isLastInGroup ? 5.0 : 3.0;
    final absOffset = _dragOffset.abs();

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onLongPress: _openActionMenu,
      onDoubleTap: widget.onDoubleTap,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: EdgeInsets.only(
          top: verticalPadding,
          bottom: hasReactions ? verticalPadding + 8.0 : verticalPadding,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            // Reply icon reveal animation
            if (absOffset > 0)
              Positioned(
                left: isMe ? null : 4,
                right: isMe ? 4 : null,
                child: Opacity(
                  opacity: (absOffset / 32.0).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: (absOffset / 32.0).clamp(0.5, 1.0),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isDark
                            ? const Color(0xFF26262B)
                            : const Color(0xFFE5E7EB),
                      ),
                      child: const Icon(
                        Icons.reply_rounded,
                        color: Color(0xFF0084FF),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),

            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: KeyedSubtree(
                  key: _bubbleContentKey,
                  child: _buildBubbleContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
