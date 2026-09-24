import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/local_settings_service.dart';
import '../../../core/services/sound_effect_service.dart';
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
import '../widgets/message_reactions_detail_sheet.dart';
import '../widgets/nearby_place_bottom_sheet.dart';
import '../widgets/mute_chat_sheet.dart';
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

class _MentionPopupState {
  final bool show;
  final String query;
  final int startIndex;
  const _MentionPopupState({
    this.show = false,
    this.query = '',
    this.startIndex = -1,
  });
}

class MentionTextEditingController extends TextEditingController {
  final Color mentionColor;

  MentionTextEditingController({
    super.text,
    this.mentionColor = const Color(0xFF3B82F6),
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!value.isComposingRangeValid || !withComposing) {
      return _buildMentionSpans(text, style);
    }

    final TextStyle composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            const TextStyle(decoration: TextDecoration.underline);

    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(text: value.composing.textBefore(value.text)),
        TextSpan(
          style: composingStyle,
          text: value.composing.textInside(value.text),
        ),
        TextSpan(text: value.composing.textAfter(value.text)),
      ],
    );
  }

  TextSpan _buildMentionSpans(String textVal, TextStyle? style) {
    if (!textVal.contains('@')) {
      return TextSpan(text: textVal, style: style);
    }

    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(@[a-zA-Z0-9_\.\u00C0-\u1EF9]+)');
    int lastIndex = 0;

    for (final match in regex.allMatches(textVal)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: textVal.substring(lastIndex, match.start),
          style: style,
        ));
      }
      final mention = match.group(0)!;
      spans.add(TextSpan(
        text: mention,
        style: (style ?? const TextStyle()).copyWith(
          color: mentionColor,
          fontWeight: FontWeight.w700,
        ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < textVal.length) {
      spans.add(TextSpan(
        text: textVal.substring(lastIndex),
        style: style,
      ));
    }

    return TextSpan(children: spans);
  }
}

class _GroupChatConversationScreenState
    extends State<GroupChatConversationScreen>
    with WidgetsBindingObserver, RouteAware {
  final MentionTextEditingController _textController = MentionTextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();
  final ChatRepository _chatRepo = ChatRepository();
  final UserRepository _userRepo = UserRepository();

  ChatMessageModel? _replyingToMessage;
  TransactionModel? _currentPostReply;
  UserModel? _currentPostAuthor;
  bool _showEmojiGrid = false;
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier<bool>(false);
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
  final List<UserModel> _allGroupMemberList = [];
  final Set<String> _selectedTaggedUids = {};
  final ValueNotifier<_MentionPopupState> _mentionNotifier =
      ValueNotifier<_MentionPopupState>(const _MentionPopupState());

  final TransactionRepository _txRepo = TransactionRepository();
  final Map<String, TransactionModel?> _resolvedExpensePosts = {};
  final Set<String> _resolvingExpenseIds = {};

  Stream<List<Map<String, dynamic>>>? _activeFriendsStream;
  List<Map<String, dynamic>> _lastActiveFriends = [];

  // Tracks whether the current user has been kicked from this group
  bool _isKickedFromGroup = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _membershipSub;

  static const List<String> emojiList = [
    '🤣', '🥺', '😱', '🔥', '❤️', '👏', '😍', '🎉',
    '😎', '💯', '👀', '💀', '😭', '🤯', '🥳', '✨',
    '👍', '🙏', '🥰', '🤩', '💩', '🤑', '🤫', '🥱',
    '🫶', '🚀', '💖', '🙈', '🤤', '😈', '💤', '🍕',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      AppRoutes.routeObserver.subscribe(this, modalRoute);
    }
    final myUid = context.read<AuthController>().user?.uid ?? '';
    if (myUid.isNotEmpty && _activeFriendsStream == null) {
      _activeFriendsStream = _userRepo.streamActiveFriendsRealtime(myUid);
      _lastActiveFriends = _userRepo.getLatestActiveFriends(myUid);
    }
  }

  @override
  void didPopNext() {
    if (mounted) {
      context.read<ChatController>().setActiveChatGroup(widget.groupId);
    }
  }

  @override
  void didPushNext() {
    if (mounted) {
      context.read<ChatController>().setActiveChatGroup(null);
    }
  }

  @override
  void didPop() {
    if (mounted) {
      context.read<ChatController>().setActiveChatGroup(null);
    }
  }

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
      _hasTextNotifier.value = draft.trim().isNotEmpty;
    }

    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    _textFocusNode.addListener(_onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatController>().setActiveChatGroup(widget.groupId);
        _markAsRead();
        _fetchMemberProfiles();
        _listenToMembership();
        _textFocusNode.requestFocus();
      }
    });
  }

  Future<void> _fetchMemberProfiles() async {
    List<String> participants = widget.memberUids ?? [];
    if (participants.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('chats').doc(widget.groupId).get();
        if (doc.exists && doc.data() != null) {
          final list = doc.data()!['participants'] as List<dynamic>?;
          if (list != null) {
            participants = list.map((e) => e.toString()).toList();
          }
        }
      } catch (_) {}
    }

    for (final uid in participants) {
      if (!_memberCache.containsKey(uid)) {
        final profile = await _userRepo.getUserProfile(uid);
        if (profile != null && mounted) {
          setState(() {
            _memberCache[uid] = profile;
            if (!_allGroupMemberList.any((m) => m.uid == uid)) {
              _allGroupMemberList.add(profile);
            }
          });
        }
      } else {
        final profile = _memberCache[uid]!;
        if (!_allGroupMemberList.any((m) => m.uid == uid)) {
          _allGroupMemberList.add(profile);
        }
      }
    }
  }

  void _checkMentionTrigger() {
    final text = _textController.text;
    final selection = _textController.selection;
    if (selection.baseOffset <= 0) {
      if (_mentionNotifier.value.show) {
        _mentionNotifier.value = const _MentionPopupState();
      }
      return;
    }

    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final bool isValidPrefix = lastAtIndex == 0 ||
          RegExp(r'\s').hasMatch(textBeforeCursor[lastAtIndex - 1]);
      final query = textBeforeCursor.substring(lastAtIndex + 1);
      final bool hasNoSpace = !query.contains(' ') && !query.contains('\n');

      if (isValidPrefix && hasNoSpace) {
        final q = query.toLowerCase();
        final current = _mentionNotifier.value;
        if (!current.show || current.query != q || current.startIndex != lastAtIndex) {
          _mentionNotifier.value = _MentionPopupState(
            show: true,
            query: q,
            startIndex: lastAtIndex,
          );
        }
        return;
      }
    }

    if (_mentionNotifier.value.show) {
      _mentionNotifier.value = const _MentionPopupState();
    }
  }

  void _selectMentionUser(UserModel member) {
    final mentionState = _mentionNotifier.value;
    final text = _textController.text;
    final selection = _textController.selection;
    final cursorPosition = selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    if (mentionState.startIndex != -1 && mentionState.startIndex <= text.length) {
      final before = text.substring(0, mentionState.startIndex);
      final after = (cursorPosition <= text.length && cursorPosition >= mentionState.startIndex)
          ? text.substring(cursorPosition)
          : '';
      final mentionTag = member.username.isNotEmpty ? member.username : member.name.replaceAll(' ', '_');
      final newText = '$before@$mentionTag $after';
      final newCursorPos = (before.length + mentionTag.length + 2).clamp(0, newText.length);

      _selectedTaggedUids.add(member.uid);
      _mentionNotifier.value = const _MentionPopupState();

      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPos),
        composing: TextRange.empty,
      );

      _textFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  void _selectMentionAll() {
    final mentionState = _mentionNotifier.value;
    final text = _textController.text;
    final selection = _textController.selection;
    final cursorPosition = selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    if (mentionState.startIndex != -1 && mentionState.startIndex <= text.length) {
      final before = text.substring(0, mentionState.startIndex);
      final after = (cursorPosition <= text.length && cursorPosition >= mentionState.startIndex)
          ? text.substring(cursorPosition)
          : '';
      const mentionTag = 'all';
      final newText = '$before@$mentionTag $after';
      final newCursorPos = (before.length + mentionTag.length + 2).clamp(0, newText.length);

      _selectedTaggedUids.add('all');
      final myUid = context.read<AuthController>().user?.uid ?? '';
      for (final m in _allGroupMemberList) {
        if (m.uid != myUid) _selectedTaggedUids.add(m.uid);
      }
      for (final uid in widget.memberUids ?? <String>[]) {
        if (uid != myUid) _selectedTaggedUids.add(uid);
      }

      _mentionNotifier.value = const _MentionPopupState();

      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPos),
        composing: TextRange.empty,
      );

      _textFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  Future<void> _showUserMentionBottomSheet(String mentionTag) async {
    final cleanTag = mentionTag.replaceAll('@', '').trim().toLowerCase();
    if (cleanTag.isEmpty) return;

    // Tapping @all / @mọi_người opens group details and member list
    if (cleanTag == 'all' ||
        cleanTag == 'mọi_người' ||
        cleanTag == 'moinguoi' ||
        cleanTag == 'mọi' ||
        cleanTag == 'moi' ||
        cleanTag == 'everyone') {
      _openGroupDetails();
      return;
    }

    final myUid = context.read<AuthController>().user?.uid ?? '';

    UserModel? targetUser = _allGroupMemberList.firstWhere(
      (m) =>
          m.username.toLowerCase() == cleanTag ||
          m.name.toLowerCase().replaceAll(' ', '_') == cleanTag ||
          m.name.toLowerCase() == cleanTag,
      orElse: () => _memberCache.values.firstWhere(
        (m) =>
            m.username.toLowerCase() == cleanTag ||
            m.name.toLowerCase().replaceAll(' ', '_') == cleanTag ||
            m.name.toLowerCase() == cleanTag,
        orElse: () => UserModel(
          uid: '',
          email: '',
          name: '',
          username: '',
          avatarUrl: '',
          currency: 'VND',
          language: 'vi',
          themeMode: 'dark',
          currentStreak: 0,
          bestStreak: 0,
          createdAt: DateTime.now(),
          lastActiveDate: DateTime.now(),
        ),
      ),
    );

    if (targetUser.uid.isEmpty) {
      try {
        final querySnap = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: cleanTag)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          targetUser = UserModel.fromMap(querySnap.docs.first.data());
          _memberCache[targetUser.uid] = targetUser;
        }
      } catch (_) {}
    }

    if (targetUser == null || targetUser.uid.isEmpty) return;
    final user = targetUser;

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = user.uid == myUid;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetInnerCtx, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E222D) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    AvatarWithFrame(
                      avatarUrl: user.avatarUrl,
                      frameId: user.avatarFrame,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name.isNotEmpty
                          ? user.name
                          : user.username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (user.username.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (isMe) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Đây là chính bạn',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      FutureBuilder<AddFriendConnectionState>(
                        future: _userRepo.checkConnectionState(
                            myUid, user.uid),
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }

                          final state =
                              snap.data ?? AddFriendConnectionState.canSend;

                          if (state == AddFriendConnectionState.alreadyFriends) {
                            return SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 18),
                                label: Text(
                                  l10n.sendMessageAction,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(sheetCtx);
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.chatConversation,
                                    arguments: {
                                      'friend': user,
                                    },
                                  );
                                },
                              ),
                            );
                          }

                          if (state == AddFriendConnectionState.pendingSent) {
                            return Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 16,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Đã gửi lời mời (Chờ chấp nhận)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.person_add_rounded,
                                  size: 18),
                              label: Text(
                                l10n.sendFriendRequest,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                try {
                                  final result =
                                      await _userRepo.sendFriendRequest(
                                    myUid: myUid,
                                    targetUser: user,
                                  );
                                  setSheetState(() {});
                                  if (!mounted) return;
                                  AppToast.show(
                                    context,
                                    result == 'auto_accepted'
                                        ? 'Đã trở thành bạn bè!'
                                        : l10n.friendRequestSent,
                                    icon: Icons.check_circle_outline_rounded,
                                  );
                                } catch (_) {}
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      context.read<ChatController>().setActiveChatGroup(widget.groupId);
    } else {
      context.read<ChatController>().setActiveChatGroup(null);
      final myUid = context.read<AuthController>().user?.uid;
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
    if (mounted) setState(() {});
    if (!_textFocusNode.hasFocus) {
      final myUid = context.read<AuthController>().user?.uid;
      _stopTypingHeartbeat(myUid);
    }
  }

  void _onTextChanged() {
    _checkMentionTrigger();
    final rawText = _textController.text;
    final text = rawText.trim();
    final hasNow = text.isNotEmpty;
    if (_hasTextNotifier.value != hasNow) {
      _hasTextNotifier.value = hasNow;
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

    if (scrollOffset > 20) {
      final stackBox = _listStackKey.currentContext?.findRenderObject() as RenderBox?;
      final double listTopGlobalY = (stackBox != null && stackBox.hasSize && stackBox.attached)
          ? stackBox.localToGlobal(Offset.zero).dy
          : 0.0;
      const double floatingHeaderTriggerY = 10.0;
      final double triggerGlobalY = listTopGlobalY + floatingHeaderTriggerY;

      DateTime? matchedDate;

      // When scrolled near or to the very top (oldest messages / start of conversation)
      if (scrollOffset >= maxScroll - 30) {
        matchedDate = messages.last.createdAt;
      } else {
        double? minDistance;

        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          final gKey = _itemKeys[msg.id];
          final box = gKey?.currentContext?.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize && box.attached) {
            final topY = box.localToGlobal(Offset.zero).dy;
            final bottomY = topY + box.size.height;
            if (topY <= triggerGlobalY && bottomY >= triggerGlobalY) {
              matchedDate = msg.createdAt;
              break;
            }

            final distance = (topY - triggerGlobalY).abs();
            if (minDistance == null || distance < minDistance) {
              minDistance = distance;
              matchedDate = msg.createdAt;
            }
          }
        }
      }

      final activeDate = matchedDate ??
          (scrollOffset > (maxScroll > 0 ? maxScroll * 0.5 : 50)
              ? messages.last.createdAt
              : messages.first.createdAt);

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
    AppRoutes.routeObserver.unsubscribe(this);
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

    _membershipSub?.cancel();
    _membershipSub = null;
    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _textFocusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    _mentionNotifier.dispose();
    _hasTextNotifier.dispose();
    super.dispose();
  }

  /// Stream the group chat doc to detect if current user has been removed from participants.
  void _listenToMembership() {
    final myUid = context.read<AuthController>().user?.uid ?? '';
    if (myUid.isEmpty) return;

    _membershipSub?.cancel();
    _membershipSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.groupId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (!snapshot.exists) return; // Group deleted – handled elsewhere

      final data = snapshot.data();
      if (data == null) return;

      final participants = (data['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Only mark as kicked when participants list is non-empty and does not include us
      final wasKicked = participants.isNotEmpty &&
          !participants.contains(myUid);

      if (wasKicked && !_isKickedFromGroup) {
        setState(() => _isKickedFromGroup = true);
        // Auto-pop after a short delay so user can see the banner
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
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
    _hasTextNotifier.value = false;
    SoundEffectService.instance.playMessageSent();
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

    final taggedUids = Set<String>.from(_selectedTaggedUids);
    final lowerText = text.toLowerCase();
    final isTagAll = taggedUids.contains('all') ||
        lowerText.contains('@all') ||
        lowerText.contains('@mọi_người') ||
        lowerText.contains('@mọi người') ||
        lowerText.contains('@moinguoi') ||
        lowerText.contains('@everyone');

    if (isTagAll) {
      for (final member in _allGroupMemberList) {
        if (member.uid != myUid) taggedUids.add(member.uid);
      }
      for (final uid in widget.memberUids ?? <String>[]) {
        if (uid != myUid) taggedUids.add(uid);
      }
    } else {
      for (final member in _allGroupMemberList) {
        if (member.username.isNotEmpty && text.contains('@${member.username}')) {
          taggedUids.add(member.uid);
        } else if (member.name.isNotEmpty && text.contains('@${member.name}')) {
          taggedUids.add(member.uid);
        }
      }
    }
    taggedUids.remove('all');
    taggedUids.remove(myUid);
    _selectedTaggedUids.clear();

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
      taggedUserIds: taggedUids.toList(),
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

  Future<void> _sendEmojiDirect(String emoji) async {
    final myUser = context.read<AuthController>().user;
    if (myUser == null || _isSending) return;

    HapticFeedback.mediumImpact();
    setState(() => _showEmojiGrid = false);

    _stopTypingHeartbeat(myUser.uid);

    // Auto-scroll to newest message
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final userRepo = context.read<UserRepository>();
    final localSettings = context.read<LocalSettingsService>();

    final replyMsg = _replyingToMessage;
    final postReply = _currentPostReply;
    final postAuthor = _currentPostAuthor;

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
      text: emoji,
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
      taggedUserIds: [],
    );

    if (mounted && success) {
      _scrollToBottom();
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
      receiverId: msg.senderId,
      messageText: msg.text,
      isGroup: true,
      groupName: widget.groupName,
    );
  }

  void _unfocusKeyboard() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    if (_textFocusNode.hasFocus) {
      _textFocusNode.unfocus();
    }
    if (_showEmojiGrid) {
      setState(() => _showEmojiGrid = false);
    }
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _unfocusKeyboard,
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
                      final List<UserModel> typingMembers = [];
                      if (isSomeoneTyping) {
                        for (final uid in typingUids) {
                          final cached = _memberCache[uid];
                          if (cached != null) {
                            typingMembers.add(cached);
                          } else {
                            typingMembers.add(UserModel(
                              uid: uid,
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
                            ));
                            _userRepo.getUserProfile(uid).then((profile) {
                              if (profile != null && mounted) {
                                setState(() {
                                  _memberCache[uid] = profile;
                                });
                              }
                            });
                          }
                        }
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
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              itemCount: totalItemCount,
                              itemBuilder: (context, index) {
                                if (isSomeoneTyping && index == 0) {
                                  return ChatTypingBubble(
                                    friends: typingMembers,
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
                                        onTapMention: (tag) => _showUserMentionBottomSheet(tag),
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
                        final List<UserModel> typingFriends = [];
                        for (final entry in typingUsers) {
                          final uid = entry.key;
                          final cached = _memberCache[uid];
                          if (cached != null) {
                            typingFriends.add(cached);
                          } else {
                            typingFriends.add(UserModel(
                              uid: uid,
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
                            ));
                            _userRepo.getUserProfile(uid).then((profile) {
                              if (profile != null && mounted) {
                                setState(() {
                                  _memberCache[uid] = profile;
                                });
                              }
                            });
                          }
                        }

                        final bool shouldBeVisible = _showScrollToBottom ||
                            (isFriendTyping &&
                                _scrollController.hasClients &&
                                _scrollController.offset > 40);

                        return ChatScrollToBottomButton(
                          isVisible: shouldBeVisible,
                          isFriendTyping: isFriendTyping,
                          friends: typingFriends,
                          isDark: isDark,
                          onTap: _scrollToBottom,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

            // Replying banner
            if (_replyingToMessage != null) _buildReplyBanner(context, isDark),
            if (_currentPostReply != null) _buildPostReplyBanner(context, isDark),

            // Mention popup
            ValueListenableBuilder<_MentionPopupState>(
              valueListenable: _mentionNotifier,
              builder: (context, mentionState, _) {
                if (!mentionState.show) return const SizedBox.shrink();
                return _buildMentionPopup(context, isDark, mentionState);
              },
            ),

            // Input Bar (replaced with kicked banner when user is no longer a member)
            if (_isKickedFromGroup)
              _buildKickedBanner(context, isDark)
            else
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
    final myUid = context.read<AuthController>().user?.uid ?? '';
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

          final myUid = context.read<AuthController>().user?.uid ?? '';
          final myShowActiveStatus =
              context.watch<LocalSettingsService>().showActiveStatus;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _activeFriendsStream ??
                _userRepo.streamActiveFriendsRealtime(myUid),
            initialData: _lastActiveFriends,
            builder: (context, friendsSnap) {
              if (friendsSnap.hasData && friendsSnap.data != null) {
                _lastActiveFriends = friendsSnap.data!;
              }
              final friends = friendsSnap.data ?? _lastActiveFriends;
              final activeFriends = friends.where((f) {
                final uid = (f['uid'] ?? '').toString();
                if (uid == myUid || !participants.contains(uid)) return false;
                final isOnline = f['isOnline'] == true;
                final showActive = f['showActiveStatus'] != false;
                final mode = (f['activeStatusMode'] ?? 'friends').toString();
                return isOnline &&
                    showActive &&
                    (mode == 'public' || myShowActiveStatus);
              }).toList();

              final onlineCount = activeFriends.length;
              final otherMembersCount =
                  participants.where((u) => u != myUid).length;
              final hasActiveMember = onlineCount > 0;

              return InkWell(
                onTap: _openGroupDetails,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
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
                          if (hasActiveMember)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.card(context),
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                                final typingData =
                                    data?['typing'] as Map<String, dynamic>?;
                                final typingUids = (typingData?.entries ?? [])
                                    .where((e) {
                                      if (e.key == myUid) return false;
                                      return e.value == true ||
                                          e.value is Timestamp;
                                    })
                                    .map((e) => e.key)
                                    .toList();

                                if (typingUids.isNotEmpty) {
                                  String typingText;
                                  if (typingUids.length == 1) {
                                    final firstTypingUid = typingUids.first;
                                    final typingUser =
                                        _memberCache[firstTypingUid];
                                    final displayName =
                                        typingUser?.name.trim().isNotEmpty ==
                                                true
                                            ? typingUser!.name.trim()
                                            : (typingUser?.username
                                                        .trim()
                                                        .isNotEmpty ==
                                                    true
                                                ? typingUser!.username.trim()
                                                : 'Thành viên');
                                    typingText =
                                        '$displayName ${context.l10n.isTyping.toLowerCase()}';
                                  } else if (typingUids.length == 2) {
                                    final user1 = _memberCache[typingUids[0]];
                                    final user2 = _memberCache[typingUids[1]];
                                    final name1 =
                                        user1?.name.trim().isNotEmpty == true
                                            ? user1!.name.trim()
                                            : (user1?.username
                                                        .trim()
                                                        .isNotEmpty ==
                                                    true
                                                ? user1!.username.trim()
                                                : 'Thành viên');
                                    final name2 =
                                        user2?.name.trim().isNotEmpty == true
                                            ? user2!.name.trim()
                                            : (user2?.username
                                                        .trim()
                                                        .isNotEmpty ==
                                                    true
                                                ? user2!.username.trim()
                                                : 'Thành viên');
                                    typingText = '$name1 và $name2 đang soạn...';
                                  } else {
                                    typingText =
                                        '${typingUids.length} người đang soạn tin...';
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

                                if (onlineCount == 0) {
                                  return Text(
                                    context.l10n.groupMembersCount(memberCount),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  );
                                }

                                final String activeText;
                                if (otherMembersCount >= 2 &&
                                    onlineCount == otherMembersCount) {
                                  activeText = context.l10n.everyoneActive;
                                } else if (onlineCount >= 2) {
                                  activeText =
                                      context.l10n.groupActiveCount(onlineCount);
                                } else {
                                  activeText = context.l10n.onePersonActive;
                                }

                                return Text(
                                  activeText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        AppColors.textSecondary(context),
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
          );
        },
      ),
      actions: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.groupId)
              .snapshots(),
          builder: (btnCtx, snapshot) {
            final chatData = snapshot.data?.data();
            final isMuted = _chatRepo.isChatMuted(chatData, myUid);
            return IconButton(
              tooltip: isMuted ? 'Bật thông báo nhóm' : 'Tắt thông báo nhóm',
              icon: Icon(
                isMuted
                    ? Icons.notifications_off_rounded
                    : Icons.notifications_outlined,
                color: isMuted
                    ? const Color(0xFFFF5252)
                    : AppColors.textPrimary(btnCtx),
                size: 22,
              ),
              onPressed: () {
                MuteChatSheet.show(
                  context,
                  chatId: widget.groupId,
                  myUid: myUid,
                  isCurrentlyMuted: isMuted,
                  isGroup: true,
                );
              },
            );
          },
        ),
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
          if (isExpense && hasTargetPost) ...[                     
            const SizedBox(height: 8),
            _buildExploreButton(msg, isDark, isEn),
          ],
          ],
        ),
      ),
    );
  }

  /// "✨ Khám phá" action button shown below expense system message card.
  /// Opens [NearbyPlaceBottomSheet] with the viewer's own location.
  Widget _buildExploreButton(ChatMessageModel msg, bool isDark, bool isEn) {
    final category = msg.transactionCategory;
    if (category == null || category.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showNearbyPlaceBottomSheet(
          context,
          spendingCategory: category,
        );
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.32),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              isEn ? 'Explore nearby' : 'Khám phá gần bạn',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.explore_rounded,
              size: 14,
              color: Colors.white,
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

  Widget _buildMentionPopup(
    BuildContext context,
    bool isDark,
    _MentionPopupState mentionState,
  ) {
    final myUid = context.read<AuthController>().user?.uid ?? '';
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final q = mentionState.query.toLowerCase();

    // Check if query matches "all", "tat ca", "mọi người", "everyone", etc.
    final bool matchesTagAll = q.isEmpty ||
        'all'.contains(q) ||
        'tatca'.contains(q) ||
        'tất cả'.contains(q) ||
        'mọi người'.contains(q) ||
        'moinguoi'.contains(q) ||
        'mọi'.contains(q) ||
        'moi'.contains(q) ||
        'everyone'.contains(q);

    final filteredMembers = _allGroupMemberList.where((member) {
      if (member.uid == myUid) return false;
      if (q.isEmpty) return true;
      final nameMatches = member.name.toLowerCase().contains(q);
      final usernameMatches = member.username.toLowerCase().contains(q);
      return nameMatches || usernameMatches;
    }).toList();

    final int totalCount = (matchesTagAll ? 1 : 0) + filteredMembers.length;
    if (totalCount == 0) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: totalCount,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.5,
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        itemBuilder: (context, index) {
          if (matchesTagAll && index == 0) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _textFocusNode.requestFocus(),
              onTap: _selectMentionAll,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF7A00), Color(0xFFFF006E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
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
                              Text(
                                isEn ? 'Mention all members' : 'Nhắc tất cả mọi người',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ALL',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFF5252),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isEn
                                ? '@all • Notify all group members'
                                : '@all • Thông báo đến tất cả thành viên',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
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

          final memberIndex = matchesTagAll ? index - 1 : index;
          final member = filteredMembers[memberIndex];
          final displayName =
              member.name.isNotEmpty ? member.name : member.username;
          final displayHandle =
              member.username.isNotEmpty ? '@${member.username}' : '';

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _textFocusNode.requestFocus(),
            onTap: () => _selectMentionUser(member),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  AvatarWithFrame(
                    avatarUrl: member.avatarUrl,
                    frameId: member.avatarFrame,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (displayHandle.isNotEmpty)
                          Text(
                            displayHandle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildKickedBanner(BuildContext context, bool isDark) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_rounded,
            size: 18,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(width: 8),
          Text(
            isEn
                ? 'You have been removed from this group'
                : 'Bạn đã bị xoá khỏi nhóm',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white38 : Colors.black45,
              fontStyle: FontStyle.italic,
            ),
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
            child: AnimatedBuilder(
              animation: _textFocusNode,
              builder: (context, child) {
                final isFocused = _textFocusNode.hasFocus;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isFocused
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.08))
                        : (isFocused
                            ? Colors.black.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isFocused
                          ? AppColors.primaryBlue
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.08)),
                      width: 1.2,
                    ),
                  ),
                  child: child,
                );
              },
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _textFocusNode,
                  autofocus: true,
                  maxLines: 4,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
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
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
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
          ),
          const SizedBox(width: 6),
          ValueListenableBuilder<bool>(
            valueListenable: _hasTextNotifier,
            builder: (context, hasText, _) {
              return AnimatedScale(
                scale: hasText ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  onPressed: hasText && !_isSending ? _sendMessage : null,
                  icon: Icon(
                    Icons.send_rounded,
                    color: hasText
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary(context).withValues(alpha: 0.35),
                    size: 24,
                  ),
                ),
              );
            },
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
            onTap: () => _sendEmojiDirect(emoji),
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
  final ValueChanged<String>? onTapMention;

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
    this.onTapMention,
  });

  @override
  State<_GroupChatMessageBubble> createState() => _GroupChatMessageBubbleState();
}

class _GroupChatMessageBubbleState extends State<_GroupChatMessageBubble>
    with TickerProviderStateMixin {
  final GlobalKey _bubbleContentKey = GlobalKey();
  bool _showDetails = false;
  double _dragOffset = 0.0;
  AnimationController? _animController;
  Animation<double>? _anim;

  // Optimistic UI state for 0ms instant reaction feedback
  Map<String, String>? _optimisticReactions;
  AnimationController? _heartAnimController;
  Animation<double>? _heartScaleAnim;
  Animation<double>? _heartOpacityAnim;

  Map<String, String> get _effectiveReactions =>
      _optimisticReactions ?? widget.message.reactions;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // Heart Burst / Pop Animation on Double-Tap
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.40)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 45,
      ),
    ]).animate(_heartAnimController!);

    _heartOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_heartAnimController!);
  }

  @override
  void didUpdateWidget(_GroupChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.reactions != widget.message.reactions) {
      _optimisticReactions = null;
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    _heartAnimController?.dispose();
    super.dispose();
  }

  void _handleOptimisticReaction(String emoji) {
    HapticFeedback.lightImpact();
    final myUid = widget.myUid;
    final current = Map<String, String>.from(_effectiveReactions);
    final isHeart = emoji == '❤️';

    if (current[myUid] == emoji) {
      // Toggle off / remove reaction
      current.remove(myUid);
    } else {
      // Add or change reaction
      current[myUid] = emoji;
      SoundEffectService.instance.playMessageReaction();
      if (isHeart) {
        _heartAnimController?.forward(from: 0.0);
      }
    }

    setState(() {
      _optimisticReactions = current;
    });

    widget.onReactionTap(emoji);
  }

  void _handleDoubleTap() {
    _handleOptimisticReaction('❤️');
  }

  Widget _buildHeartPopOverlay() {
    if (_heartAnimController == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _heartAnimController!,
            builder: (context, child) {
              if (!_heartAnimController!.isAnimating &&
                  _heartAnimController!.value == 0) {
                return const SizedBox.shrink();
              }
              return Opacity(
                opacity: (_heartOpacityAnim?.value ?? 0.0).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _heartScaleAnim?.value ?? 1.0,
                  child: child,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openActionMenu() {
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
    MessageActionMenuOverlay.show(
      context: context,
      message: widget.message,
      isMe: widget.isMe,
      friend: widget.friend,
      myReaction: _effectiveReactions[widget.myUid],
      messageKey: _bubbleContentKey,
      messageChild: _buildBubbleContent(context),
      onSelectReaction: (emoji) {
        _handleOptimisticReaction(emoji);
      },
      onSelectAction: widget.onActionSelected,
    );
  }

  void _openReactionsDetailSheet() {
    final gId = widget.message.groupId ??
        (widget.message.receiverId.isNotEmpty ? widget.message.receiverId : '');
    MessageReactionsDetailSheet.show(
      context: context,
      message: widget.message,
      myUid: widget.myUid,
      chatId: gId,
      isGroup: true,
      userCache: widget.memberCache,
      onRemoveReaction: (emoji) async {
        _handleOptimisticReaction(emoji);
      },
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

          // Full Rounded Post Preview Card (tap to view post / double tap to heart)
          GestureDetector(
            onTap: () {
              if (widget.message.postId != null &&
                  widget.message.postId!.isNotEmpty &&
                  widget.onTapPost != null) {
                widget.onTapPost!(widget.message.postId!);
              }
            },
            onDoubleTap: _handleDoubleTap,
            onLongPress: _openActionMenu,
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

                    // Heart Pop Animation Overlay
                    _buildHeartPopOverlay(),
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
                      onDoubleTap: _handleDoubleTap,
                      onLongPress: _openActionMenu,
                      child: Text(
                        widget.message.text,
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () => setState(() => _showDetails = !_showDetails),
                      onDoubleTap: _handleDoubleTap,
                      onLongPress: _openActionMenu,
                      child: (widget.isMe || !currentTheme.isDefault)
                          ? ChatBubbleDecoratedBox(
                              theme: currentTheme,
                              isMe: widget.isMe,
                              customBorderRadius: BorderRadius.circular(20),
                              child: _buildRichMessageText(
                                widget.message.text,
                                TextStyle(
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
                              child: _buildRichMessageText(
                                widget.message.text,
                                TextStyle(
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

                  // Heart Pop Animation Overlay
                  _buildHeartPopOverlay(),

                  if (_effectiveReactions.isNotEmpty)
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
          if (_effectiveReactions.isNotEmpty) const SizedBox(height: 6),
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
                    onDoubleTap: _handleDoubleTap,
                    onLongPress: _openActionMenu,
                    child: Text(
                      widget.message.text,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),

                  // Heart Pop Animation Overlay
                  _buildHeartPopOverlay(),

                  if (_effectiveReactions.isNotEmpty)
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
          if (_effectiveReactions.isNotEmpty) const SizedBox(height: 6),
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
                    onDoubleTap: _handleDoubleTap,
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
                              child: _buildRichMessageText(
                                widget.message.text,
                                TextStyle(
                                  color: currentTheme.textColor,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                                isUnderline: isUrl,
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
                              child: _buildRichMessageText(
                                widget.message.text,
                                TextStyle(
                                  color: widget.isDark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                                isUnderline: isUrl,
                              ),
                            ),
                    ),
                  ),

                  // Heart Pop Animation Overlay
                  _buildHeartPopOverlay(),

                  if (_effectiveReactions.isNotEmpty)
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
          if (_effectiveReactions.isNotEmpty) const SizedBox(height: 8),
          _buildStatusLine(context),
        ],
      );
    }
    return content;
  }

  Widget _buildRichMessageText(
    String text,
    TextStyle baseStyle, {
    bool isUnderline = false,
  }) {
    if (!text.contains('@')) {
      return Text(
        text,
        style: isUnderline
            ? baseStyle.copyWith(decoration: TextDecoration.underline)
            : baseStyle,
      );
    }

    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(@[a-zA-Z0-9_\.\u00C0-\u1EF9]+)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      final mention = match.group(0)!;
      spans.add(TextSpan(
        text: mention,
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.none,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            HapticFeedback.lightImpact();
            widget.onTapMention?.call(mention);
          },
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildReactionsBadge() {
    final reactions = _effectiveReactions;
    if (reactions.isEmpty) return const SizedBox.shrink();

    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openReactionsDetailSheet,
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
    final hasReactions = _effectiveReactions.isNotEmpty;
    final verticalPadding = widget.isLastInGroup ? 5.0 : 3.0;
    final absOffset = _dragOffset.abs();

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onLongPress: _openActionMenu,
      onDoubleTap: _handleDoubleTap,
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
