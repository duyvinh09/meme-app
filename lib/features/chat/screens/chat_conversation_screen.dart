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
import '../../../data/models/chat_bubble_theme.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/message_action_menu_overlay.dart';
import '../widgets/typing_indicator_widget.dart';

class ChatConversationScreen extends StatefulWidget {
  final UserModel friend;
  final TransactionModel? initialPostReply;

  const ChatConversationScreen({
    super.key,
    required this.friend,
    this.initialPostReply,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();
  TransactionModel? _currentPostReply;
  ChatMessageModel? _replyingToMessage;
  bool _showEmojiGrid = false;
  bool _hasText = false;
  bool _isCloseFriend = false;
  bool _showScrollToBottom = false;
  Timer? _typingIdleTimer;
  DateTime? _lastTypingSentTime;
  bool _isCurrentlyTypingSent = false;

  bool _showFloatingDate = false;
  String _floatingDateText = '';
  Timer? _floatingDateHideTimer;
  Timer? _presenceTimer;
  final GlobalKey _listStackKey = GlobalKey();
  final Map<String, GlobalKey> _itemKeys = {};

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

    // Load unsent draft if available
    final draft = context.read<LocalSettingsService>().getDraft(widget.friend.uid);
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
      final myUid = context.read<AuthController>().user?.uid;
      context.read<ChatController>().setActiveChatFriend(widget.friend.uid);
      if (myUid != null) {
        context.read<ChatController>().markChatAsRead(
          myUid: myUid,
          friendUid: widget.friend.uid,
        );
        _loadCloseFriendStatus(myUid);
      }
    });

    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
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
    if (!_scrollController.hasClients || messages.isEmpty) return;

    final offset = _scrollController.offset;

    final bool shouldShowScrollBottom = offset > 120;
    if (shouldShowScrollBottom != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = shouldShowScrollBottom;
      });
    }

    if (offset > 20) {
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
        if (mounted) {
          setState(() {
            _showFloatingDate = false;
          });
        }
      });
    } else if (offset <= 20 && _showFloatingDate) {
      _floatingDateHideTimer?.cancel();
      setState(() {
        _showFloatingDate = false;
      });
    }
  }

  void _startFloatingHeaderTimer() {
    _floatingDateHideTimer?.cancel();
    _floatingDateHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showFloatingDate) {
        setState(() {
          _showFloatingDate = false;
        });
      }
    });
  }

  void _sendTypingHeartbeat(String myUid, bool isTyping) {
    if (!mounted) return;
    context.read<ChatController>().setTyping(
          myUid: myUid,
          friendUid: widget.friend.uid,
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
    final hasTextNow = text.isNotEmpty;
    if (hasTextNow != _hasText) {
      setState(() {
        _hasText = hasTextNow;
      });
    }

    // Persist draft in local settings
    context.read<LocalSettingsService>().setDraft(
      widget.friend.uid,
      hasTextNow ? rawText : null,
    );

    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null || myUid.isEmpty) return;

    if (!hasTextNow) {
      _typingIdleTimer?.cancel();
      _typingIdleTimer = null;
      if (_isCurrentlyTypingSent) {
        _isCurrentlyTypingSent = false;
        _sendTypingHeartbeat(myUid, false);
      }
      return;
    }

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final myUid = context.read<AuthController>().user?.uid;
    if (state == AppLifecycleState.resumed) {
      context.read<ChatController>().setActiveChatFriend(widget.friend.uid);
      if (_hasText && myUid != null) {
        _onTextChanged();
      }
    } else {
      context.read<ChatController>().setActiveChatFriend(null);
      _stopTypingHeartbeat(myUid);
    }
  }

  void _loadCloseFriendStatus(String myUid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('friends')
          .doc(widget.friend.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _isCloseFriend = doc.data()?['isCloseFriend'] == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleStarFriend() async {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null) return;

    HapticFeedback.lightImpact();
    final newValue = !_isCloseFriend;
    setState(() {
      _isCloseFriend = newValue;
    });

    try {
      await context.read<UserRepository>().toggleCloseFriend(
            myUid: myUid,
            friendUid: widget.friend.uid,
            isCloseFriend: newValue,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue
                  ? context.l10n.addedToCloseFriends(widget.friend.name)
                  : context.l10n.removedFromCloseFriends(widget.friend.name),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    final myUid = context.read<AuthController>().user?.uid;
    _stopTypingHeartbeat(myUid);
    _floatingDateHideTimer?.cancel();

    // Persist or clean up draft when disposing
    final rawText = _textController.text;
    if (rawText.trim().isNotEmpty) {
      context.read<LocalSettingsService>().setDraft(widget.friend.uid, rawText);
    } else {
      context.read<LocalSettingsService>().clearDraft(widget.friend.uid);
    }

    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _textFocusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    context.read<ChatController>().setActiveChatFriend(null);
    final myUid = context.read<AuthController>().user?.uid;
    _stopTypingHeartbeat(myUid);
    super.deactivate();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null) return;

    _textController.clear();
    context.read<LocalSettingsService>().clearDraft(widget.friend.uid);
    HapticFeedback.lightImpact();

    _stopTypingHeartbeat(myUid);

    // Auto-scroll to newest message
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final chatCtrl = context.read<ChatController>();
    final bubbleTheme = context.read<LocalSettingsService>().chatBubbleTheme;
    final replyMsg = _replyingToMessage;

    if (_replyingToMessage != null) {
      setState(() {
        _replyingToMessage = null;
      });
    }

    if (_currentPostReply != null) {
      await chatCtrl.sendPostReply(
        myUid: myUid,
        friendUid: widget.friend.uid,
        text: text,
        postId: _currentPostReply!.id,
        postImageUrl: _currentPostReply!.displayImageUrl,
        postCaption: _currentPostReply!.caption,
        postCreatedAt: _currentPostReply!.createdAt,
        bubbleTheme: bubbleTheme,
      );
      setState(() {
        _currentPostReply = null;
      });
    } else {
      await chatCtrl.sendTextMessage(
        myUid: myUid,
        friendUid: widget.friend.uid,
        text: text,
        bubbleTheme: bubbleTheme,
        replyToMessageId: replyMsg?.id,
        replyToText: replyMsg?.text,
        replyToSenderName: replyMsg != null
            ? (replyMsg.senderId == myUid ? 'bạn' : widget.friend.name)
            : null,
      );
    }
  }

  void _sendEmojiDirect(String emoji) async {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _showEmojiGrid = false);

    _stopTypingHeartbeat(myUid);

    // Auto-scroll to newest message
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final chatCtrl = context.read<ChatController>();
    final bubbleTheme = context.read<LocalSettingsService>().chatBubbleTheme;

    if (_currentPostReply != null) {
      await chatCtrl.sendPostReply(
        myUid: myUid,
        friendUid: widget.friend.uid,
        text: emoji,
        postId: _currentPostReply!.id,
        postImageUrl: _currentPostReply!.displayImageUrl,
        postCaption: _currentPostReply!.caption,
        postCreatedAt: _currentPostReply!.createdAt,
        bubbleTheme: bubbleTheme,
      );
      setState(() => _currentPostReply = null);
    } else {
      await chatCtrl.sendTextMessage(
        myUid: myUid,
        friendUid: widget.friend.uid,
        text: emoji,
        bubbleTheme: bubbleTheme,
      );
    }
  }

  void _toggleReactionOnMessage(ChatMessageModel msg, String emoji) async {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null) return;

    HapticFeedback.mediumImpact();
    final targetFriendUid = msg.senderId == myUid ? msg.receiverId : msg.senderId;

    await context.read<ChatController>().toggleMessageReaction(
      myUid: myUid,
      friendUid: targetFriendUid,
      messageId: msg.id,
      emoji: emoji,
      messageText: msg.text,
    );
  }

  void _handleMessageAction(ChatMessageModel msg, MessageMenuAction action) async {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null) return;

    switch (action) {
      case MessageMenuAction.reply:
        setState(() {
          _replyingToMessage = msg;
          _currentPostReply = null;
        });
        _textFocusNode.requestFocus();
        break;

      case MessageMenuAction.copy:
        if (msg.text.trim().isNotEmpty) {
          Clipboard.setData(ClipboardData(text: msg.text));
          AppToast.show(
            context,
            context.l10n.copiedToClipboard,
            icon: Icons.check_circle_outline_rounded,
          );
        }
        break;

      case MessageMenuAction.unsend:
        _showConfirmUnsendDialog(msg);
        break;

      case MessageMenuAction.deleteForMe:
        _showConfirmDeleteForMeDialog(msg);
        break;

      case MessageMenuAction.report:
        _showReportMessageSheet(msg);
        break;
    }
  }

  void _showConfirmUnsendDialog(ChatMessageModel msg) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);

    final diffSeconds = DateTime.now().difference(msg.createdAt).inSeconds;
    if (diffSeconds > 15 * 60) {
      AppToast.show(context, l10n.recallTimeExpired);
      return;
    }

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
              final myUid = context.read<AuthController>().user?.uid;
              if (myUid == null) return;
              if (DateTime.now().difference(msg.createdAt).inSeconds > 15 * 60) {
                AppToast.show(context, l10n.recallTimeExpired);
                return;
              }
              await context.read<ChatController>().unsendMessage(
                myUid: myUid,
                friendUid: widget.friend.uid,
                messageId: msg.id,
              );
            },
            child: Text(l10n.unsend, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteForMeDialog(ChatMessageModel msg) {
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
              final myUid = context.read<AuthController>().user?.uid;
              if (myUid == null) return;
              await context.read<ChatController>().deleteMessageForMe(
                myUid: myUid,
                friendUid: widget.friend.uid,
                messageId: msg.id,
              );
            },
            child: Text(l10n.deleteForMe, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showReportMessageSheet(ChatMessageModel msg) {
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
                      final myUid = context.read<AuthController>().user?.uid;
                      if (myUid == null) return;
                      await context.read<ChatController>().reportMessage(
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

  String _formatPresenceStatus(UserModel user, dynamic l10n) {
    if (user.isCurrentlyOnline) {
      return l10n.activeNow;
    }

    final seen = user.lastSeen ?? user.lastActiveDate;
    final now = DateTime.now();
    final safeSeen = seen.isAfter(now) ? now : seen;
    final diff = now.difference(safeSeen);

    if (diff.inMinutes < 1) {
      return l10n.activeAgo(l10n.justNow);
    }
    if (diff.inMinutes < 60) {
      return l10n.activeAgo(l10n.minutesAgo(diff.inMinutes));
    }
    if (diff.inHours < 24) {
      return l10n.activeAgo(l10n.hoursAgo(diff.inHours));
    }
    if (diff.inDays <= 7) {
      return l10n.activeAgo(l10n.daysAgo(diff.inDays));
    }
    return l10n.activeAgo(DateFormat('d/M').format(seen));
  }

  String _formatMessageTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String _formatFloatingDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    if (msgDay == today) {
      return context.l10n.today;
    }
    if (msgDay == yesterday) {
      return context.l10n.yesterday;
    }
    if (date.year == now.year) {
      return isVi
          ? '${date.day} Tháng ${date.month}'
          : DateFormat('d MMM', 'en').format(date);
    }
    return isVi
        ? '${date.day} Tháng ${date.month}, ${date.year}'
        : DateFormat('d MMM, y', 'en').format(date);
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

  bool _isMessagePureEmoji(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final emojiRegex = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
    );
    return emojiRegex.hasMatch(trimmed) && trimmed.length <= 4;
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final myUid = context.watch<AuthController>().user?.uid ?? '';
    final chatCtrl = context.watch<ChatController>();

    final bgColor = isDark ? Colors.black : const Color(0xFFF9FAFB);
    final headerColor = isDark ? Colors.black : Colors.white;

    final userRepo = context.read<UserRepository>();
    final myShowActiveStatus = context.watch<LocalSettingsService>().showActiveStatus;

    return StreamBuilder<bool>(
      stream: userRepo.streamIsFriend(myUid, widget.friend.uid),
      initialData: true,
      builder: (context, friendCheckSnapshot) {
        final isFriend = friendCheckSnapshot.data ?? false;

        return StreamBuilder<UserModel?>(
          stream: userRepo.streamUserProfile(widget.friend.uid),
          initialData: widget.friend,
          builder: (context, friendSnapshot) {
            final liveFriend = friendSnapshot.data ?? widget.friend;
            final canShowPresence = liveFriend.isPresenceVisibleTo(isFriend: isFriend) &&
                (liveFriend.activeStatusMode == 'public' || myShowActiveStatus);
            final isOnline = canShowPresence && liveFriend.isCurrentlyOnline;
            final statusText = canShowPresence
                ? _formatPresenceStatus(liveFriend, context.l10n)
                : '';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: headerColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                // Friend Avatar with Online Indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (liveFriend.avatarUrl.isNotEmpty)
                      AvatarWithFrame(
                        avatarUrl: liveFriend.avatarUrl,
                        frameId: liveFriend.avatarFrame,
                        size: 38,
                      )
                    else
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(liveFriend.name),
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10.5,
                          height: 10.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: headerColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),

                // Friend Name & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        liveFriend.name.isNotEmpty
                            ? liveFriend.name
                            : liveFriend.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (statusText.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isOnline
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
                            fontSize: 11.5,
                            fontWeight: isOnline ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Star (Bạn thân)
              IconButton(
                icon: Icon(
                  _isCloseFriend ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _isCloseFriend ? const Color(0xFFFFB800) : (isDark ? Colors.white : Colors.black87),
                  size: 25,
                ),
                onPressed: _toggleStarFriend,
              ),

              // Chat Bubble Theme Picker (...)
              IconButton(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 24,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final updatedTheme = await Navigator.pushNamed(
                    context,
                    RouteNames.chatBubbleTheme,
                  );
                  if (updatedTheme is String && mounted) {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Message List Area
                Expanded(
                  child: StreamBuilder<bool>(
                    stream: myUid.isNotEmpty
                        ? chatCtrl.streamFriendTyping(
                            myUid: myUid,
                            friendUid: widget.friend.uid,
                          )
                        : const Stream.empty(),
                    initialData: false,
                    builder: (context, typingSnapshot) {
                      final isFriendTyping = typingSnapshot.data == true;

                      return Stack(
                        key: _listStackKey,
                        children: [
                          Positioned.fill(
                            child: StreamBuilder<List<ChatMessageModel>>(
                              stream: chatCtrl.messagesStream(
                                myUid: myUid,
                                friendUid: widget.friend.uid,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting &&
                                    !snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  );
                                }

                                final allMessages = snapshot.data ?? [];
                                final messages = allMessages
                                    .where((m) => !m.deletedFor.contains(myUid))
                                    .toList();

                                // Immediately mark incoming unread messages as read in real time
                                if (messages.isNotEmpty && myUid.isNotEmpty) {
                                  final hasUnread = messages.any(
                                    (m) => m.receiverId == myUid && !m.isRead,
                                  );
                                  if (hasUnread) {
                                    chatCtrl.markChatAsRead(
                                      myUid: myUid,
                                      friendUid: widget.friend.uid,
                                    );
                                  }
                                }

                                if (messages.isEmpty && !isFriendTyping) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (liveFriend.avatarUrl.isNotEmpty)
                                            AvatarWithFrame(
                                              avatarUrl: liveFriend.avatarUrl,
                                              frameId: liveFriend.avatarFrame,
                                              size: 84,
                                            )
                                          else
                                            Container(
                                              width: 84,
                                              height: 84,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isDark
                                                    ? const Color(0xFF26262B)
                                                    : const Color(0xFFE5E7EB),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _getInitials(liveFriend.name),
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(0xFF111827),
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          Text(
                                            liveFriend.name.isNotEmpty
                                                ? liveFriend.name
                                                : liveFriend.username,
                                            style: TextStyle(
                                              color: isDark ? Colors.white : const Color(0xFF111827),
                                              fontSize: 19,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '@${liveFriend.username}',
                                            style: TextStyle(
                                              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.05)
                                                  : Colors.black.withValues(alpha: 0.04),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              context.l10n.emptyConversationPrompt,
                                              style: TextStyle(
                                                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final lastMyMessageIndex = messages.indexWhere((m) => m.senderId == myUid);
                                final int totalItemCount = messages.length + (isFriendTyping ? 1 : 0);

                                return NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification is ScrollUpdateNotification ||
                                        notification is UserScrollNotification) {
                                      _updateFloatingHeader(messages);
                                    } else if (notification is ScrollEndNotification) {
                                      _startFloatingHeaderTimer();
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
                                      if (isFriendTyping && index == 0) {
                                        return ChatTypingBubble(
                                          friend: liveFriend,
                                          isDark: isDark,
                                        );
                                      }

                                      final msgIndex = isFriendTyping ? index - 1 : index;
                                      final msg = messages[msgIndex];
                                      final isMe = msg.senderId == myUid;
                                      final isLatestMyMessage = isMe && msgIndex == lastMyMessageIndex;
                                      // Clustering calculations
                                      final prevMsg = msgIndex > 0 ? messages[msgIndex - 1] : null; // newer
                                      final nextMsg = msgIndex < messages.length - 1 ? messages[msgIndex + 1] : null; // older

                                      final bool isThisSpecial = msg.type == 'reaction' ||
                                          (msg.postImageUrl != null && msg.postImageUrl!.isNotEmpty) ||
                                          _isMessagePureEmoji(msg.text);

                                      final bool isPrevSpecial = prevMsg != null &&
                                          (prevMsg.type == 'reaction' ||
                                              (prevMsg.postImageUrl != null && prevMsg.postImageUrl!.isNotEmpty) ||
                                              _isMessagePureEmoji(prevMsg.text));

                                      final bool isNextSpecial = nextMsg != null &&
                                          (nextMsg.type == 'reaction' ||
                                              (nextMsg.postImageUrl != null && nextMsg.postImageUrl!.isNotEmpty) ||
                                              _isMessagePureEmoji(nextMsg.text));

                                      final bool isFirstInGroup = nextMsg == null ||
                                          nextMsg.senderId != msg.senderId ||
                                          isThisSpecial ||
                                          isNextSpecial ||
                                          msg.createdAt.difference(nextMsg.createdAt).inMinutes > 4;

                                      final bool isLastInGroup = prevMsg == null ||
                                          prevMsg.senderId != msg.senderId ||
                                          isThisSpecial ||
                                          isPrevSpecial ||
                                          prevMsg.createdAt.difference(msg.createdAt).inMinutes > 4;

                                      final bool isDayBoundary = nextMsg == null ||
                                          msg.createdAt.year != nextMsg.createdAt.year ||
                                          msg.createdAt.month != nextMsg.createdAt.month ||
                                          msg.createdAt.day != nextMsg.createdAt.day;

                                      final bool showTimeHeader = isDayBoundary ||
                                          msg.createdAt.difference(nextMsg.createdAt).inMinutes >= 15;

                                      final itemKey = _itemKeys.putIfAbsent(msg.id, () => GlobalKey());

                                      return Container(
                                        key: itemKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Inline Time Header Pill when gap is >= 15 mins (e.g. "Hôm nay 7:12 CH")
                                            if (showTimeHeader)
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 13,
                                                      vertical: 4.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? const Color(0xFF1E2430).withValues(alpha: 0.70)
                                                          : const Color(0xFFE5E7EB).withValues(alpha: 0.85),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: isDark
                                                            ? Colors.white.withValues(alpha: 0.12)
                                                            : Colors.black.withValues(alpha: 0.06),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _formatSeparatorTime(msg.createdAt),
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white.withValues(alpha: 0.80)
                                                            : const Color(0xFF4B5563),
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            _ChatMessageBubble(
                                              key: ValueKey(msg.id),
                                              message: msg,
                                              isMe: isMe,
                                              myUid: myUid,
                                              friend: liveFriend,
                                              timeText: _formatMessageTime(msg.createdAt),
                                              isDark: isDark,
                                              isLatestMyMessage: isLatestMyMessage,
                                              isFirstInGroup: isFirstInGroup,
                                              isLastInGroup: isLastInGroup,
                                              onDoubleTap: () => _toggleReactionOnMessage(msg, '❤️'),
                                              onReactionTap: (emoji) => _toggleReactionOnMessage(msg, emoji),
                                              onActionSelected: (action) => _handleMessageAction(msg, action),
                                              onSwipeToReply: (targetMsg) {
                                                setState(() {
                                                  _replyingToMessage = targetMsg;
                                                  _currentPostReply = null;
                                                });
                                                _textFocusNode.requestFocus();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          // Floating Sticky Time Header Pill (appears when scrolling through history)
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  opacity: _showFloatingDate && _floatingDateText.isNotEmpty ? 1.0 : 0.0,
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

                          // Floating Scroll-to-Bottom Button (transforms into typing dots when friend is typing)
                          Positioned(
                            bottom: 12,
                            right: 14,
                            child: ChatScrollToBottomButton(
                              isVisible: _showScrollToBottom,
                              isFriendTyping: isFriendTyping,
                              friend: liveFriend,
                              isDark: isDark,
                              onTap: () {
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
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

            // Replying to Message Banner Preview (Swipe to reply)
            if (_replyingToMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    Container(
                      width: 3.5,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0084FF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.reply_rounded,
                                size: 14,
                                color: Color(0xFF0084FF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _replyingToMessage!.senderId == myUid
                                    ? context.l10n.replyingToSelf
                                    : context.l10n.replyingToUser(
                                        liveFriend.name.isNotEmpty
                                            ? liveFriend.name
                                            : liveFriend.username,
                                      ),
                                style: const TextStyle(
                                  color: Color(0xFF0084FF),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            _replyingToMessage!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
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
                      onPressed: () => setState(() => _replyingToMessage = null),
                    ),
                  ],
                ),
              ),

            // Replying to Post Banner Preview
            if (_currentPostReply != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    if (_currentPostReply!.displayImageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _currentPostReply!.displayImageUrl,
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
                                context.l10n.replyingToPost(
                                  widget.friend.name.isNotEmpty
                                      ? widget.friend.name
                                      : widget.friend.username,
                                ),
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
                            _currentPostReply!.caption.isNotEmpty
                                ? _currentPostReply!.caption
                                : 'Khoảnh khắc',
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
              ),

            // Emoji Quick Drawer (if opened)
            if (_showEmojiGrid)
              Container(
                height: 180,
                color: isDark ? const Color(0xFF181A22) : const Color(0xFFF3F4F6),
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: emojiList.length,
                  itemBuilder: (context, index) {
                    final em = emojiList[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _sendEmojiDirect(em),
                      child: Center(
                        child: Text(em, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  },
                ),
              ),

            // Modern Input Bar exact match to Screenshot 1
            // Footer Input Bar exact match to Group Chat
            Container(
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
                          hintText: context.l10n.typeMessageHint,
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
                      onPressed: _hasText ? _sendMessage : null,
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
            ),
          ],
        ),
      ),
    );
          },
        );
      },
    );
  }
}

class _ChatMessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String myUid;
  final UserModel friend;
  final String timeText;
  final bool isDark;
  final bool isLatestMyMessage;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback onDoubleTap;
  final ValueChanged<String> onReactionTap;
  final ValueChanged<MessageMenuAction>? onActionSelected;
  final ValueChanged<ChatMessageModel>? onSwipeToReply;

  const _ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.myUid,
    required this.friend,
    required this.timeText,
    required this.isDark,
    required this.isLatestMyMessage,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.onDoubleTap,
    required this.onReactionTap,
    this.onActionSelected,
    this.onSwipeToReply,
  });

  @override
  State<_ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<_ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  final GlobalKey _bubbleContentKey = GlobalKey();
  bool _showDetails = false;
  double _dragOffset = 0.0;
  AnimationController? _animController;
  Animation<double>? _anim;

  void _openActionMenu() {
    MessageActionMenuOverlay.show(
      context: context,
      message: widget.message,
      isMe: widget.isMe,
      friend: widget.friend,
      messageKey: _bubbleContentKey,
      messageChild: _buildBubbleContent(context),
      onSelectReaction: widget.onReactionTap,
      onSelectAction: (action) {
        widget.onActionSelected?.call(action);
      },
    );
  }

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

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta != null) {
      setState(() {
        if (widget.isMe) {
          // For my messages (on the right): swipe right-to-left (negative offset)
          _dragOffset = (_dragOffset + details.primaryDelta!).clamp(-56.0, 0.0);
        } else {
          // For friend messages (on the left): swipe left-to-right (positive offset)
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
        widget.onSwipeToReply?.call(widget.message);
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

  bool get _isPureEmoji {
    final trimmed = widget.message.text.trim();
    if (trimmed.isEmpty) return false;
    final emojiRegex = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
    );
    return emojiRegex.hasMatch(trimmed) && trimmed.length <= 4;
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

  String _formatFeedTime(BuildContext context, DateTime? createdAt) {
    if (createdAt == null) return '';
    final now = DateTime.now();

    final safeCreatedAt = createdAt.isAfter(now) ? now : createdAt;
    final diff = now.difference(safeCreatedAt);

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

    final locale = Localizations.localeOf(context).languageCode;
    final isVietnamese = locale == 'vi';

    if (now.year == createdAt.year) {
      if (isVietnamese) {
        return '${createdAt.day} thg ${createdAt.month}';
      }
      return DateFormat('d MMM', 'en').format(createdAt);
    }

    if (isVietnamese) {
      return '${createdAt.day} thg ${createdAt.month}, ${createdAt.year}';
    }
    return DateFormat('d MMM, y', 'en').format(createdAt);
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
      // !isFirstInGroup && isLastInGroup
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
      // !isFirstInGroup && isLastInGroup
      return const BorderRadius.only(
        topLeft: Radius.circular(rSmall),
        topRight: Radius.circular(rLarge),
        bottomLeft: Radius.circular(rLarge),
        bottomRight: Radius.circular(rLarge),
      );
    }
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
          padding: const EdgeInsets.only(bottom: 3),
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
                  final friendName = widget.friend.name.isNotEmpty
                      ? widget.friend.name
                      : widget.friend.username;
                  if (widget.message.type == 'note_reply') {
                    if (isMe) {
                      return l10n.youRepliedToTheirNote;
                    } else {
                      return l10n.userRepliedToYourNote(friendName);
                    }
                  }
                  if (isMe) {
                    final isReplyToSelf = widget.message.replyToSenderName == 'chính mình' ||
                        widget.message.replyToSenderName == 'yourself' ||
                        widget.message.replyToSenderName == null ||
                        widget.message.replyToSenderName == 'You';
                    if (isReplyToSelf) {
                      return l10n.youRepliedToYourself;
                    } else {
                      final targetName = (widget.message.replyToSenderName != null &&
                              widget.message.replyToSenderName!.isNotEmpty &&
                              widget.message.replyToSenderName != 'chính mình')
                          ? widget.message.replyToSenderName!
                          : friendName;
                      return l10n.youRepliedToUser(targetName);
                    }
                  } else {
                    final isReplyToThemself = widget.message.replyToSenderName == 'chính mình' ||
                        widget.message.replyToSenderName == 'yourself' ||
                        widget.message.replyToSenderName == friendName ||
                        widget.message.replyToSenderName == widget.friend.username;
                    if (isReplyToThemself) {
                      return l10n.userRepliedToThemself(friendName);
                    } else {
                      return l10n.userRepliedToYou(friendName);
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
          margin: const EdgeInsets.only(bottom: 4),
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

    return const SizedBox(width: 36);
  }

  Widget _buildBubbleContent(BuildContext context) {
    // 0. Recalled Message State (Displays elegant recalled bubble for everyone)
    if (widget.message.isRecalled) {
      final borderRadius = _getBubbleBorderRadius();
      return Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFriendAvatar(forceShow: true),
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

    final hasPost = widget.message.postImageUrl != null &&
        widget.message.postImageUrl!.isNotEmpty;
    final localThemeId = context.read<LocalSettingsService>().chatBubbleTheme;
    final msgThemeId = widget.message.bubbleTheme;
    final friendThemeId = widget.friend.chatBubbleTheme;

    // All my messages dynamically synchronize with my active chat bubble theme!
    final effectiveThemeId = widget.isMe
        ? localThemeId
        : (friendThemeId.isNotEmpty ? friendThemeId : (msgThemeId ?? 'classic'));
    final currentTheme = ChatBubbleTheme.getTheme(effectiveThemeId);

    Widget content;

    // 1. Post Reply / Post Reaction Layout
    if (hasPost) {
      final screenWidth = MediaQuery.of(context).size.width;
      final cardSize = (screenWidth * 0.74).clamp(220.0, 290.0);
      final postTimeAgo = _formatFeedTime(
        context,
        widget.message.postCreatedAt ?? widget.message.createdAt,
      );

      content = Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuotedReplyHeader(),

          // Full Rounded Post Preview Card (aligned to edge)
          Container(
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

                  // Post author avatar + name & time (matching reference UI)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: [
                        if (widget.friend.avatarUrl.isNotEmpty)
                          AvatarWithFrame(
                            avatarUrl: widget.friend.avatarUrl,
                            frameId: widget.friend.avatarFrame,
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
                                _getInitials(widget.friend.name),
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
                            widget.friend.name.isNotEmpty
                                ? widget.friend.name
                                : widget.friend.username,
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

          const SizedBox(height: 6),

          // Standalone Reply Bubble below the post card with avatar & reaction dock
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFriendAvatar(forceShow: true),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_isPureEmoji || widget.message.type == 'reaction') ...[
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

                  // Reaction Pill Badge docked at bottom
                  if (widget.message.reactions.isNotEmpty)
                    Positioned(
                      bottom: -10,
                      right: widget.isMe ? 6 : null,
                      left: widget.isMe ? null : 6,
                      child: GestureDetector(
                        onTap: _openActionMenu,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0xFF242526)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.black
                                  : const Color(0xFFE4E6EB),
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
                            children: widget.message.reactions.values
                                .toSet()
                                .take(3)
                                .map((em) => Text(
                                      em,
                                      style: const TextStyle(fontSize: 12),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (widget.message.reactions.isNotEmpty) const SizedBox(height: 8),

          _buildStatusLine(context),
        ],
      );
    } else if (_isPureEmoji || widget.message.type == 'reaction') {
      // 2. Pure emoji message
      content = Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildQuotedReplyHeader(),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFriendAvatar(forceShow: true),
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
                      child: GestureDetector(
                        onTap: _openActionMenu,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0xFF242526)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.black
                                  : const Color(0xFFE4E6EB),
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
                            children: widget.message.reactions.values
                                .toSet()
                                .take(3)
                                .map((em) => Text(
                                      em,
                                      style: const TextStyle(fontSize: 12),
                                    ))
                                .toList(),
                          ),
                        ),
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
    } else {
      // 3. Regular text message
      final isUrl = widget.message.text.startsWith('http://') ||
          widget.message.text.startsWith('https://');

      content = Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuotedReplyHeader(),
          Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildFriendAvatar(),
              // Bubble with Reaction Badge
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.32,
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
                                      : const Color(0xFF050505),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.32,
                                  decoration: isUrl
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Reaction Pill Badge docked at the bottom corner of the bubble (Messenger Style)
                  if (widget.message.reactions.isNotEmpty)
                    Positioned(
                      bottom: -13,
                      right: widget.isMe ? 6 : null,
                      left: widget.isMe ? null : 6,
                      child: GestureDetector(
                        onTap: _openActionMenu,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0xFF242526)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.black
                                  : const Color(0xFFE4E6EB),
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
                            children: widget.message.reactions.values
                                .toSet()
                                .take(3)
                                .map((em) => Text(
                                      em,
                                      style: const TextStyle(fontSize: 12),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (widget.message.reactions.isNotEmpty) const SizedBox(height: 8),

          // Status / Seen Receipt line
          _buildStatusLine(context),
        ],
      );
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
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
          alignment:
              widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            // Reply icon reveal animation (left for friend, right for me)
            if (absOffset > 0)
              Positioned(
                left: widget.isMe ? null : 4,
                right: widget.isMe ? 4 : null,
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
                alignment:
                    widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
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

  Widget _buildStatusLine(BuildContext context) {
    // Only show status when:
    // 1. User manually tapped bubble (_showDetails == true)
    // 2. OR it is the last message in a cluster (isLastInGroup == true)
    final shouldShow = _showDetails || widget.isLastInGroup || widget.isLatestMyMessage;
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

    // For my messages (Sender):
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Time text (only when last in group or when tapped)
          if (widget.isLastInGroup || _showDetails)
            Text(
              widget.timeText,
              style: TextStyle(
                color: widget.isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),

          // "Đã xem" / Seen receipt (Messenger style mini avatar at the bottom-right of latest message)
          if (widget.isLatestMyMessage && widget.isLastInGroup) ...[
            const SizedBox(width: 5),
            if (widget.message.isRead) ...[
              if (widget.friend.avatarUrl.isNotEmpty)
                ClipOval(
                  child: Image.network(
                    widget.friend.avatarUrl,
                    width: 15,
                    height: 15,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                )
              else
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isDark
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFD1D5DB),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(widget.friend.name),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ] else ...[
              Icon(
                Icons.check_circle_rounded,
                size: 11.5,
                color: widget.isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
