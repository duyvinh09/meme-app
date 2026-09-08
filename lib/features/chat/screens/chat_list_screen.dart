import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/local_settings_service.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/user_repository.dart';
import 'group_chat_conversation_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'all'; // 'all' | 'unread' | 'groups'
  Timer? _activeStoriesTicker;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _activeStoriesTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _activeStoriesTicker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime? dateTime, String locale) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final isVi = locale.startsWith('vi');

    if (difference.inSeconds < 45) {
      return isVi ? 'Vừa xong' : 'Just now';
    } else if (difference.inMinutes < 60) {
      return isVi ? '${difference.inMinutes}ph' : '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return isVi ? '${difference.inHours}g' : '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return isVi ? '${difference.inDays}ngày' : '${difference.inDays}d';
    } else if (dateTime.year == now.year) {
      return isVi
          ? '${dateTime.day} thg ${dateTime.month}'
          : '${dateTime.day} ${_shortMonth(dateTime.month)}';
    } else {
      return isVi
          ? '${dateTime.day}/${dateTime.month}/${dateTime.year}'
          : '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  String _shortMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '$month';
  }

  void _openActiveStatusSheet(BuildContext context, String myUid) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActiveStatusPrivacySheet(myUid: myUid),
    );
  }


  void _openNewChatSheet(BuildContext context, String myUid) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewChatFriendsSheet(myUid: myUid),
    );
  }

  Future<void> _markAllConversationsAsRead(
    String myUid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chatDocs,
  ) async {
    HapticFeedback.mediumImpact();
    final chatRepo = context.read<ChatRepository>();
    final toastMsg = context.l10n.markAllAsRead;

    for (final doc in chatDocs) {
      final chatId = doc.id;
      final isGroup = doc.data()['isGroup'] == true;
      if (isGroup) {
        await chatRepo.markGroupChatAsRead(chatId, myUid);
      } else {
        await chatRepo.markMessagesAsRead(chatId, myUid);
      }
    }

    if (!mounted) return;

    AppToast.show(
      context,
      toastMsg,
      icon: Icons.done_all_rounded,
    );
  }

  void _openMyNoteViewerModal(
    BuildContext context,
    String myUid,
    String note,
    DateTime? createdAt,
  ) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => _MyNoteViewerModal(
        myUid: myUid,
        note: note,
        createdAt: createdAt,
        onShareNewNote: () {
          Navigator.pop(ctx);
          _openNewNoteModal(context, myUid, null);
        },
      ),
    );
  }

  void _openNewNoteModal(BuildContext context, String myUid, String? currentNote) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => _NewNoteModal(
        myUid: myUid,
        initialNote: currentNote,
      ),
    );
  }

  void _openNoteViewerModal(
    BuildContext context,
    Map<String, dynamic> friendData,
    String myUid,
  ) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => _NoteViewerModal(
        friend: friendData,
        myUid: myUid,
      ),
    );
  }

  Widget _buildActiveStoriesBar(
    BuildContext context,
    String myUid,
    bool isDark,
    UserRepository userRepo,
  ) {
    final myShowActiveStatus =
        context.watch<LocalSettingsService>().showActiveStatus;

    return Container(
      height: 112,
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userRepo.streamActiveFriendsRealtime(myUid),
        builder: (context, snapshot) {
          final friends = snapshot.data ?? [];
          final activeOrOnlineFriends = friends.where((f) {
            final hasNote = f['hasActiveNote'] == true;
            final canShowOnline = (f['isOnline'] == true) &&
                (f['showActiveStatus'] != false) &&
                (f['activeStatusMode'] == 'public' || myShowActiveStatus);
            return hasNote || canShowOnline;
          }).toList();

          activeOrOnlineFriends.sort((a, b) {
            final aHasNote = a['hasActiveNote'] == true ? 1 : 0;
            final bHasNote = b['hasActiveNote'] == true ? 1 : 0;
            return bHasNote.compareTo(aHasNote);
          });

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: 1 + activeOrOnlineFriends.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                final myProfile = context.watch<ProfileController>().user;
                final myAvatar = myProfile?.avatarUrl ?? '';
                final myFrame = myProfile?.avatarFrame ?? 'plain';
                final hasNote = myProfile?.hasActiveNote == true;
                final noteText = hasNote ? myProfile!.userNote! : context.l10n.shareNote;

                return InkWell(
                  onTap: () {
                    if (hasNote) {
                      _openMyNoteViewerModal(
                        context,
                        myUid,
                        myProfile!.userNote!,
                        myProfile.userNoteCreatedAt,
                      );
                    } else {
                      _openNewNoteModal(
                        context,
                        myUid,
                        null,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 82,
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 82,
                          height: 76,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                bottom: 0,
                                child: AvatarWithFrame(
                                  avatarUrl: myAvatar,
                                  frameId: myFrame,
                                  size: 54,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                child: _NoteThoughtBubble(
                                  text: noteText,
                                  isPlaceholder: !hasNote,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.l10n.yourNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final friend = activeOrOnlineFriends[index - 1];
              final friendName = friend['name'] as String? ?? 'Bạn bè';
              final avatarUrl = friend['avatarUrl'] as String? ?? '';
              final avatarFrame = friend['avatarFrame'] as String? ?? 'plain';
              final displayName = friendName.trim().split(' ').last;
              final hasNote = friend['hasActiveNote'] == true;
              final noteText = friend['userNote'] as String? ?? '';
              final isOnline = friend['isOnline'] == true &&
                  friend['showActiveStatus'] != false &&
                  (friend['activeStatusMode'] == 'public' || myShowActiveStatus);

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (hasNote) {
                    _openNoteViewerModal(context, friend, myUid);
                  } else {
                    final targetFriend = UserModel.fromMap(friend);
                    Navigator.pushNamed(
                      context,
                      RouteNames.chatConversation,
                      arguments: {
                        'friend': targetFriend,
                      },
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 82,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 82,
                        height: 76,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              bottom: 0,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AvatarWithFrame(
                                    avatarUrl: avatarUrl,
                                    frameId: avatarFrame,
                                    size: 54,
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      bottom: 1,
                                      right: 1,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.background(context),
                                            width: 2.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (hasNote)
                              Positioned(
                                top: 0,
                                child: _NoteThoughtBubble(
                                  text: noteText,
                                  isPlaceholder: false,
                                  isDark: isDark,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayName.isNotEmpty ? displayName : friendName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF374151),
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
    );
  }

  Widget _buildFilterTabs(
    BuildContext context,
    bool isDark,
  ) {
    final tabs = [
      {'key': 'all', 'label': context.l10n.tabAll},
      {'key': 'unread', 'label': context.l10n.tabUnread},
      {'key': 'groups', 'label': context.l10n.tabGroups},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ...tabs.map((tab) {
            final isSelected = _selectedTab == tab['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedTab = tab['key']!;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0084FF)
                        : (isDark
                            ? const Color(0xFF1E2430)
                            : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0084FF)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFCBD5E1)),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    tab['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.watch<AuthController>().user?.uid;
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final chatRepo = context.read<ChatRepository>();
    final userRepo = context.read<UserRepository>();
    final currentLocale = Localizations.localeOf(context).languageCode;

    if (myUid == null || myUid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          title: Text(context.l10n.conversationsTitle),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      floatingActionButton: FloatingActionButton(
        elevation: 6,
        backgroundColor: const Color(0xFF00E5FF),
        shape: const CircleBorder(),
        onPressed: () => _openNewChatSheet(context, myUid),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.edit_rounded,
            color: Colors.black87,
            size: 26,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TOP APP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                12,
                AppSizes.pagePadding,
                8,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
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
                        color: textPrimary,
                        size: 20,
                      ),
                    ),
                  ),

                  // Center Title WITH ACTIVE STATUS BUTTON
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _openActiveStatusSheet(context, myUid),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                context.l10n.conversationsTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _ActiveStatusHeaderPill(
                              isActive: context.watch<ProfileController>().showActiveStatus,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Right Checkmark Action
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: chatRepo.streamUserChats(myUid),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      return InkWell(
                        onTap: () => _markAllConversationsAsRead(myUid, docs),
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
                            Icons.done_all_rounded,
                            color: textSecondary,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchConversations,
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: textSecondary,
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.cancel_rounded,
                              color: textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // STORIES / ACTIVE FRIENDS BAR
            if (_searchQuery.isEmpty)
              _buildActiveStoriesBar(context, myUid, isDark, userRepo),

            // CONVERSATIONS STREAM
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: userRepo.streamFriends(myUid),
                builder: (context, friendsSnapshot) {
                  final friendsList = friendsSnapshot.data ?? [];
                  final friendUids = friendsList
                      .map((f) => (f['uid'] ?? '').toString())
                      .where((uid) => uid.isNotEmpty)
                      .toSet();

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: chatRepo.streamUserChats(myUid),
                    builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Sort conversations by latest message timestamp descending
                  final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs)
                    ..sort((a, b) {
                      final aTime = (a.data()['updatedAt'] as Timestamp?)?.toDate() ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final bTime = (b.data()['updatedAt'] as Timestamp?)?.toDate() ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return bTime.compareTo(aTime);
                    });

                  // Filter by tab
                  final filteredDocs = sortedDocs.where((doc) {
                    final data = doc.data();
                    final isGroup = data['isGroup'] == true;
                    final unreadBy = List<String>.from(data['unreadBy'] ?? []);
                    final lastSenderId = (data['lastSenderId'] ?? '').toString();
                    final bool isUnread = isGroup
                        ? unreadBy.contains(myUid)
                        : (unreadBy.contains(myUid) ||
                            (lastSenderId.isNotEmpty &&
                                lastSenderId != myUid &&
                                data['lastMessageIsRead'] == false));

                    if (_selectedTab == 'unread') {
                      return isUnread;
                    } else if (_selectedTab == 'groups') {
                      return isGroup;
                    }
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      // Filter Tabs Row
                      _buildFilterTabs(context, isDark),

                      Expanded(
                        child: filteredDocs.isEmpty
                            ? _buildEmptyState(context, myUid)
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                                itemCount: filteredDocs.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  indent: 74,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                                itemBuilder: (context, index) {
                                  final doc = filteredDocs[index];
                                  final data = doc.data();
                                  final participants =
                                      List<String>.from(data['participants'] ?? []);

                                  final isGroup = data['isGroup'] == true;
                                  if (isGroup) {
                                    final groupName =
                                        (data['groupName'] as String?)?.trim() ??
                                            'Nhóm chi tiêu';
                                    final groupColorHex =
                                        (data['groupColor'] as String?) ?? '#79AFFF';
                                    final lastMessage =
                                        (data['lastMessage'] ?? '').toString();
                                    final lastSenderId =
                                        (data['lastSenderId'] ?? '').toString();
                                    final updatedAt =
                                        (data['updatedAt'] as Timestamp?)?.toDate();
                                    final unreadBy =
                                        List<String>.from(data['unreadBy'] ?? []);
                                    final bool isUnread = unreadBy.contains(myUid);

                                    // Group Typing detection
                                    bool isGroupTyping = false;
                                    String typingUid = '';
                                    final typingData =
                                        data['typing'] as Map<String, dynamic>?;
                                    if (typingData != null) {
                                      for (final entry in typingData.entries) {
                                        if (entry.key != myUid) {
                                          final val = entry.value;
                                          if (val == true || val is Timestamp) {
                                            isGroupTyping = true;
                                            typingUid = entry.key;
                                            break;
                                          }
                                        }
                                      }
                                    }

                                    return _GroupConversationItemTile(
                                      key: ValueKey('group_${doc.id}'),
                                      groupId: doc.id,
                                      myUid: myUid,
                                      groupName: groupName,
                                      groupColorHex: groupColorHex,
                                      participants: participants,
                                      lastMessage: lastMessage,
                                      lastSenderId: lastSenderId,
                                      updatedAt: updatedAt,
                                      relativeTime: _formatRelativeTime(
                                          updatedAt, currentLocale),
                                      isUnread: isUnread,
                                      isGroupTyping: isGroupTyping,
                                      typingUid: typingUid,
                                      userRepo: userRepo,
                                      chatRepo: chatRepo,
                                      searchQuery: _searchQuery,
                                    );
                                  }

                                  final otherUid = participants.firstWhere(
                                    (id) => id != myUid,
                                    orElse: () => '',
                                  );

                                  if (otherUid.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final lastMessage =
                                      (data['lastMessage'] ?? '').toString();
                                  final lastSenderId =
                                      (data['lastSenderId'] ?? '').toString();
                                  final lastType =
                                      (data['lastType'] ?? 'text').toString();
                                  final lastReactionEmoji =
                                      (data['lastReactionEmoji'] ?? '').toString();
                                  final updatedAt =
                                      (data['updatedAt'] as Timestamp?)?.toDate();

                                  // Typing detection
                                  bool isOtherTyping = false;
                                  final typingData =
                                      data['typing'] as Map<String, dynamic>?;
                                  if (typingData != null &&
                                      typingData.containsKey(otherUid)) {
                                    final val = typingData[otherUid];
                                    isOtherTyping =
                                        val == true || val is Timestamp;
                                  }

                                  // Unread detection
                                  final unreadBy =
                                      List<String>.from(data['unreadBy'] ?? []);
                                  final bool isUnread = unreadBy.contains(myUid) ||
                                      (lastSenderId.isNotEmpty &&
                                          lastSenderId != myUid &&
                                          data['lastMessageIsRead'] == false);

                                  final isFriend = friendUids.contains(otherUid);

                                  return _ConversationItemTile(
                                    key: ValueKey(doc.id),
                                    chatId: doc.id,
                                    myUid: myUid,
                                    otherUid: otherUid,
                                    isFriend: isFriend,
                                    lastMessage: lastMessage,
                                    lastSenderId: lastSenderId,
                                    lastType: lastType,
                                    lastReactionEmoji: lastReactionEmoji,
                                    updatedAt: updatedAt,
                                    relativeTime: _formatRelativeTime(
                                        updatedAt, currentLocale),
                                    isOtherTyping: isOtherTyping,
                                    isUnread: isUnread,
                                    userRepo: userRepo,
                                    searchQuery: _searchQuery,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String myUid) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.noConversationsYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.startChattingWithFriends,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                context.l10n.newMessage,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
              onPressed: () => _openNewChatSheet(context, myUid),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationItemTile extends StatelessWidget {
  final String chatId;
  final String myUid;
  final String otherUid;
  final String lastMessage;
  final String lastSenderId;
  final String lastType;
  final String lastReactionEmoji;
  final DateTime? updatedAt;
  final String relativeTime;
  final bool isOtherTyping;
  final bool isUnread;
  final UserRepository userRepo;
  final String searchQuery;
  final bool isFriend;

  const _ConversationItemTile({
    super.key,
    required this.chatId,
    required this.myUid,
    required this.otherUid,
    required this.isFriend,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastType,
    required this.lastReactionEmoji,
    required this.updatedAt,
    required this.relativeTime,
    required this.isOtherTyping,
    required this.isUnread,
    required this.userRepo,
    required this.searchQuery,
  });

  String _formatSnippet(UserModel? otherUser, BuildContext context) {
    if (isOtherTyping) {
      return context.l10n.isTyping;
    }

    final otherName = otherUser?.name.isNotEmpty == true
        ? otherUser!.name
        : (otherUser?.username.isNotEmpty == true
            ? '@${otherUser!.username}'
            : context.l10n.user);

    if (lastType == 'message_reaction' || lastType == 'reaction') {
      final emoji = lastReactionEmoji.isNotEmpty ? lastReactionEmoji : '❤️';
      if (lastSenderId == myUid) {
        return context.l10n.youReactedToMessage(emoji);
      } else {
        return context.l10n.friendReactedToMessage(otherName, emoji);
      }
    }

    if (lastType == 'recalled' || lastMessage == 'Tin nhắn đã được thu hồi') {
      return context.l10n.messageRecalled;
    }

    if (lastType == 'post_reply') {
      return context.l10n.repliedToPostSnippet(lastMessage);
    }

    if (lastMessage.isEmpty) {
      return context.l10n.startConversation;
    }

    if (lastType == 'system' ||
        lastMessage.contains('đã thêm chi tiêu') ||
        lastMessage.contains('đã nạp') ||
        lastMessage.contains('added expense') ||
        lastMessage.contains('deposited')) {
      final localized = GroupChatConversationScreen.localizeGroupSystemText(context, lastMessage);
      if (localized != lastMessage) {
        return localized;
      }
    }

    if (lastSenderId == myUid) {
      return context.l10n.youPrefix(lastMessage);
    }

    return lastMessage;
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return StreamBuilder<UserModel?>(
      stream: userRepo.streamUserProfile(otherUid),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;
        final name = otherUser?.name.isNotEmpty == true
            ? otherUser!.name
            : (otherUser?.username.isNotEmpty == true
                ? '@${otherUser!.username}'
                : context.l10n.user);
        final username = otherUser?.username ?? '';
        final avatarUrl = otherUser?.avatarUrl ?? '';
        final avatarFrame = otherUser?.avatarFrame ?? 'plain';
        final myShowActiveStatus =
            context.watch<LocalSettingsService>().showActiveStatus;
        final isOnline = otherUser != null &&
            otherUser.isOnlineVisibleTo(isFriend: isFriend) &&
            (otherUser.activeStatusMode == 'public' || myShowActiveStatus);

        final draft = context.watch<LocalSettingsService>().getDraft(otherUid);
        final hasDraft = !isOtherTyping && draft != null && draft.trim().isNotEmpty;

        // Filter search query if present
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final matchName = name.toLowerCase().contains(query);
          final matchUsername = username.toLowerCase().contains(query);
          final matchMsg = lastMessage.toLowerCase().contains(query);
          final matchDraft = hasDraft && draft.toLowerCase().contains(query);
          if (!matchName && !matchUsername && !matchMsg && !matchDraft) {
            return const SizedBox.shrink();
          }
        }

        final snippet = _formatSnippet(otherUser, context);

        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            final targetFriend = otherUser ??
                UserModel.fromMap({
                  'uid': otherUid,
                  'name': name,
                  'username': username,
                  'avatarUrl': avatarUrl,
                  'avatarFrame': avatarFrame,
                });

            Navigator.pushNamed(
              context,
              RouteNames.chatConversation,
              arguments: {
                'friend': targetFriend,
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Row(
              children: [
                // Unread Blue Dot on the far left
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0084FF),
                    ),
                  )
                else
                  const SizedBox(width: 2),

                // Avatar with Frame & Online Indicator Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AvatarWithFrame(
                      avatarUrl: avatarUrl,
                      frameId: avatarFrame,
                      size: 54,
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background(context),
                              width: 2.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // Name, Relative Time & Message Snippet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Name + Relative Time
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (relativeTime.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              relativeTime,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isUnread ? FontWeight.w800 : FontWeight.w500,
                                color: isUnread
                                    ? AppColors.primaryBlue
                                    : textSecondary.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 3.5),

                      // Bottom Row: Message snippet or Draft
                      if (hasDraft)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: context.l10n.draftPrefix,
                                style: const TextStyle(
                                  color: Color(0xFF0084FF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: draft.trim(),
                                style: TextStyle(
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: isOtherTyping ? FontStyle.italic : FontStyle.normal,
                            fontWeight: isOtherTyping
                                ? FontWeight.w700
                                : (isUnread ? FontWeight.w800 : FontWeight.w500),
                            color: isOtherTyping
                                ? AppColors.primaryBlue
                                : (isUnread ? textPrimary : textSecondary),
                            height: 1.25,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trailing Chevron Indicator
                Icon(
                  Icons.chevron_right_rounded,
                  color: isUnread
                      ? AppColors.primaryBlue
                      : textSecondary.withValues(alpha: 0.45),
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GroupConversationItemTile extends StatelessWidget {
  final String groupId;
  final String myUid;
  final String groupName;
  final String groupColorHex;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;
  final String relativeTime;
  final bool isUnread;
  final bool isGroupTyping;
  final String typingUid;
  final UserRepository userRepo;
  final ChatRepository chatRepo;
  final String searchQuery;

  const _GroupConversationItemTile({
    super.key,
    required this.groupId,
    required this.myUid,
    required this.groupName,
    required this.groupColorHex,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderId,
    required this.updatedAt,
    required this.relativeTime,
    required this.isUnread,
    required this.isGroupTyping,
    required this.typingUid,
    required this.userRepo,
    required this.chatRepo,
    required this.searchQuery,
  });

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF79AFFF);
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<LocalSettingsService>().getDraft('group_$groupId');
    final hasDraft = !isGroupTyping && draft != null && draft.trim().isNotEmpty;

    final localizedLastMessage =
        GroupChatConversationScreen.localizeGroupSystemText(context, lastMessage);

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final matchName = groupName.toLowerCase().contains(query);
      final matchMsg = lastMessage.toLowerCase().contains(query) ||
          localizedLastMessage.toLowerCase().contains(query);
      final matchDraft = hasDraft && draft.toLowerCase().contains(query);
      if (!matchName && !matchMsg && !matchDraft) {
        return const SizedBox.shrink();
      }
    }

    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final groupColor = _parseHexColor(groupColorHex);

    Widget buildTileContent(int unreadCount, UserModel? typingUser) {
      String displaySnippet;
      if (isGroupTyping) {
        if (typingUser != null && typingUser.name.trim().isNotEmpty) {
          displaySnippet = '${typingUser.name.trim()}: ${context.l10n.isTyping}';
        } else {
          displaySnippet = context.l10n.isTyping;
        }
      } else if (isUnread) {
        displaySnippet = unreadCount > 1
            ? context.l10n.newMessagesCount(unreadCount)
            : (localizedLastMessage.isNotEmpty
                ? localizedLastMessage
                : context.l10n.newMessagesCount(1));
      } else {
        displaySnippet = localizedLastMessage.isNotEmpty
            ? localizedLastMessage
            : context.l10n.groupChat;
      }

      return InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pushNamed(
            context,
            RouteNames.groupChatConversation,
            arguments: {
              'groupId': groupId,
              'groupName': groupName,
              'groupColor': groupColorHex,
              'memberUids': participants,
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          child: Row(
            children: [
              // Unread Blue Dot on the far left
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0084FF),
                  ),
                )
              else
                const SizedBox(width: 2),

              // Group Circle Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: groupColor.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.groups_2_rounded,
                    color: groupColor,
                    size: 26,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Group Name, Badge, Time & Snippet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            groupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight:
                                  isUnread ? FontWeight.w900 : FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 6),
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
                        if (relativeTime.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            relativeTime,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isUnread ? FontWeight.w800 : FontWeight.w500,
                              color: isUnread
                                  ? AppColors.primaryBlue
                                  : textSecondary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 3.5),

                    if (hasDraft)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: context.l10n.draftPrefix,
                              style: const TextStyle(
                                color: Color(0xFF0084FF),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: draft.trim(),
                              style: TextStyle(
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        displaySnippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: isGroupTyping
                              ? FontStyle.italic
                              : FontStyle.normal,
                          fontWeight: isUnread || isGroupTyping
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isGroupTyping
                              ? AppColors.primaryBlue
                              : (isUnread ? textPrimary : textSecondary),
                          height: 1.25,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: isUnread
                    ? AppColors.primaryBlue
                    : textSecondary.withValues(alpha: 0.45),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }

    if (typingUid.isNotEmpty) {
      return StreamBuilder<UserModel?>(
        stream: userRepo.streamUserProfile(typingUid),
        builder: (context, userSnapshot) {
          if (isUnread) {
            return StreamBuilder<int>(
              stream: chatRepo.streamGroupUnreadCount(groupId, myUid),
              builder: (context, unreadSnapshot) {
                final count = unreadSnapshot.data ?? 1;
                return buildTileContent(count > 0 ? count : 1, userSnapshot.data);
              },
            );
          }
          return buildTileContent(0, userSnapshot.data);
        },
      );
    }

    if (isUnread) {
      return StreamBuilder<int>(
        stream: chatRepo.streamGroupUnreadCount(groupId, myUid),
        builder: (context, unreadSnapshot) {
          final count = unreadSnapshot.data ?? 1;
          return buildTileContent(count > 0 ? count : 1, null);
        },
      );
    }

    return buildTileContent(0, null);
  }
}

class _NewChatFriendsSheet extends StatefulWidget {
  final String myUid;

  const _NewChatFriendsSheet({required this.myUid});

  @override
  State<_NewChatFriendsSheet> createState() => _NewChatFriendsSheetState();
}

class _NewChatFriendsSheetState extends State<_NewChatFriendsSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final repo = context.read<UserRepository>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E28) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_square,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.newMessage,
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: textSecondary,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262938) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchInFriends,
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),

            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),

            // Friends List Stream
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: repo.streamFriends(widget.myUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final allFriends = snapshot.data ?? [];

                  final filtered = allFriends.where((f) {
                    final name = (f['name'] ?? '').toString().toLowerCase();
                    final username = (f['username'] ?? '').toString().toLowerCase();
                    if (_query.isNotEmpty) {
                      return name.contains(_query) || username.contains(_query);
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _query.isNotEmpty
                              ? 'Không tìm thấy bạn bè phù hợp'
                              : 'Chưa có bạn bè nào',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final friendUid = (item['uid'] ?? '').toString();
                      final friendName = (item['name'] ?? '').toString().trim();
                      final friendUsername = (item['username'] ?? '').toString().trim();
                      final avatarUrl = (item['avatarUrl'] ?? '').toString();
                      final avatarFrame = (item['avatarFrame'] ?? 'plain').toString();

                      final displayName =
                          friendName.isNotEmpty ? friendName : (friendUsername.isNotEmpty ? friendUsername : context.l10n.user);

                      return ListTile(
                        onTap: () {
                          Navigator.pop(context); // Close sheet
                          Navigator.pushNamed(
                            context,
                            RouteNames.chatConversation,
                            arguments: {
                              'friend': UserModel.fromMap({
                                'uid': friendUid,
                                'name': displayName,
                                'username': friendUsername,
                                'avatarUrl': avatarUrl,
                                'avatarFrame': avatarFrame,
                              }),
                            },
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: AvatarWithFrame(
                          avatarUrl: avatarUrl,
                          frameId: avatarFrame,
                          size: 46,
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: friendUsername.isNotEmpty
                            ? Text(
                                '@$friendUsername',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                              )
                            : null,
                        trailing: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.primaryBlue,
                            size: 18,
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
      ),
    );
  }
}

class _ActiveStatusHeaderPill extends StatelessWidget {
  final bool isActive;

  const _ActiveStatusHeaderPill({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dotColor = isActive ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.10)),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.5,
            height: 7.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 3.5),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: dotColor,
          ),
        ],
      ),
    );
  }
}

class _ActiveStatusPrivacySheet extends StatefulWidget {
  final String myUid;

  const _ActiveStatusPrivacySheet({required this.myUid});

  @override
  State<_ActiveStatusPrivacySheet> createState() => _ActiveStatusPrivacySheetState();
}

class _ActiveStatusPrivacySheetState extends State<_ActiveStatusPrivacySheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final l10n = context.l10n;
    final profileCtrl = context.watch<ProfileController>();
    final currentMode = profileCtrl.activeStatusMode;
    final isCurrentlyActive = profileCtrl.showActiveStatus;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E212B) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header row: Handle bar in center, Close button on right
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: textSecondary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: textPrimary,
                      size: 24,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Large user avatar with active dot badge (matching screenshot)
              FutureBuilder<UserModel?>(
                future: context.read<UserRepository>().getUserProfile(widget.myUid),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final avatarUrl = user?.avatarUrl ?? '';
                  final avatarFrame = user?.avatarFrame ?? 'plain';
                  final name = user?.name.isNotEmpty == true ? user!.name : 'User';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (avatarUrl.isNotEmpty)
                        AvatarWithFrame(
                          avatarUrl: avatarUrl,
                          frameId: avatarFrame,
                          size: 82,
                        )
                      else
                        Container(
                          width: 82,
                          height: 82,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF80DEEA),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF006064),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrentlyActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFF9CA3AF),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E212B) : Colors.white,
                              width: 3.5,
                            ),
                            boxShadow: isCurrentlyActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              // Title: Choose who can see when you're active
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.chooseWhoCanSeeActive,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Option list container (matching screenshot)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161922) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      title: l10n.activeStatusPublic,
                      subtitle: l10n.activeStatusPublicDesc,
                      modeKey: 'public',
                      selected: currentMode == 'public',
                      onSelect: () => _handleSelectMode('public'),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    _buildOptionTile(
                      context: context,
                      title: l10n.activeStatusFriends,
                      subtitle: l10n.activeStatusFriendsDesc,
                      modeKey: 'friends',
                      selected: currentMode == 'friends',
                      onSelect: () => _handleSelectMode('friends'),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    _buildOptionTile(
                      context: context,
                      title: l10n.activeStatusNoOne,
                      subtitle: l10n.activeStatusNoOneDesc,
                      modeKey: 'none',
                      selected: currentMode == 'none',
                      onSelect: () => _handleSelectMode('none'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String modeKey,
    required bool selected,
    required VoidCallback onSelect,
  }) {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: textSecondary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFEF4444)
                      : (isDark ? Colors.white38 : Colors.black26),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSelectMode(String mode) async {
    HapticFeedback.selectionClick();
    final profile = context.read<ProfileController>();
    await profile.setActiveStatusMode(mode, widget.myUid);
    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _NoteThoughtBubble extends StatelessWidget {
  final String text;
  final bool isPlaceholder;
  final bool isDark;

  const _NoteThoughtBubble({
    required this.text,
    this.isPlaceholder = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isDark ? const Color(0xFF262626) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.10);
    final textColor = isPlaceholder
        ? (isDark ? Colors.white54 : const Color(0xFF6B7280))
        : (isDark ? Colors.white : const Color(0xFF111827));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(
            maxWidth: 78,
            minWidth: 44,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isPlaceholder ? FontWeight.w500 : FontWeight.w700,
              color: textColor,
              height: 1.15,
            ),
          ),
        ),
        // Lobe and dot attached to bottom left, floating over top of avatar
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 5,
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 1.2),
              Container(
                width: 4.2,
                height: 4.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bubbleColor,
                  border: Border.all(
                    color: borderColor,
                    width: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyNoteViewerModal extends StatelessWidget {
  final String myUid;
  final String note;
  final DateTime? createdAt;
  final VoidCallback onShareNewNote;

  const _MyNoteViewerModal({
    required this.myUid,
    required this.note,
    this.createdAt,
    required this.onShareNewNote,
  });

  String _formatRemainingTime(BuildContext context, DateTime? dt) {
    if (dt == null) return context.l10n.expiresIn24Hours;
    final diff = DateTime.now().difference(dt);
    final remainingSeconds = 86400 - diff.inSeconds;
    if (remainingSeconds <= 0) return context.l10n.expiresInHours(0);
    final remainingHours = (remainingSeconds / 3600).ceil();
    if (remainingHours >= 24) return context.l10n.expiresIn24Hours;
    return context.l10n.expiresInHours(remainingHours);
  }

  Future<void> _deleteNote(BuildContext context) async {
    final userRepo = context.read<UserRepository>();
    await userRepo.deleteUserNote(myUid);
    if (!context.mounted) return;
    context.read<ProfileController>().refreshUser(myUid);
    Navigator.pop(context);
    AppToast.show(
      context,
      context.l10n.noteDeletedSuccess,
      icon: Icons.delete_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final myProfile = context.watch<ProfileController>().user;
    final myAvatar = myProfile?.avatarUrl ?? '';
    final myFrame = myProfile?.avatarFrame ?? 'plain';
    final myName = myProfile?.name ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.75)
                    : Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top close button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Avatar with Thought Bubble Floating Over It
                            Center(
                              child: SizedBox(
                                width: 260,
                                height: 175,
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      bottom: 0,
                                      child: AvatarWithFrame(
                                        avatarUrl: myAvatar,
                                        frameId: myFrame,
                                        size: 84,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxWidth: 240,
                                              minWidth: 120,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF262626) : Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.12)
                                                    : Colors.black.withValues(alpha: 0.08),
                                                width: 0.8,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              note,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isDark ? Colors.white : const Color(0xFF111827),
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 11,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF262626) : Colors.white,
                                                    borderRadius: const BorderRadius.only(
                                                      bottomLeft: Radius.circular(5),
                                                      bottomRight: Radius.circular(5),
                                                    ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.12)
                                                          : Colors.black.withValues(alpha: 0.08),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Container(
                                                  width: 5.5,
                                                  height: 5.5,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isDark ? const Color(0xFF262626) : Colors.white,
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.12)
                                                          : Colors.black.withValues(alpha: 0.08),
                                                      width: 0.8,
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
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // User Name
                            Text(
                              myName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Shared with Public / Friends
                            Text(
                              context.l10n.sharedWithAudience(context.l10n.audiencePublic),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // Expires in 24 hours
                            Text(
                              _formatRemainingTime(context, createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const Spacer(),

                            // Bottom Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: ElevatedButton.icon(
                                      onPressed: onShareNewNote,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0084FF),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(23),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                                      label: Text(
                                        context.l10n.shareNewNote,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: TextButton.icon(
                                      onPressed: () => _deleteNote(context),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFFF453A),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                      ),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 19),
                                      label: Text(
                                        context.l10n.deleteNote,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewNoteModal extends StatefulWidget {
  final String myUid;
  final String? initialNote;

  const _NewNoteModal({
    required this.myUid,
    this.initialNote,
  });

  @override
  State<_NewNoteModal> createState() => _NewNoteModalState();
}

class _NewNoteModalState extends State<_NewNoteModal> {
  late final TextEditingController _controller;
  static const int _maxChars = 60;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _shareNote() async {
    final text = _controller.text.trim();
    final userRepo = context.read<UserRepository>();
    await userRepo.updateUserNote(widget.myUid, text);
    if (!mounted) return;
    context.read<ProfileController>().refreshUser(widget.myUid);
    Navigator.pop(context);
    AppToast.show(
      context,
      context.l10n.noteSharedSuccess,
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final myProfile = context.watch<ProfileController>().user;
    final myAvatar = myProfile?.avatarUrl ?? '';
    final myFrame = myProfile?.avatarFrame ?? 'plain';
    final myName = myProfile?.name ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.75)
                    : Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top Bar (Matches Screenshot)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Expanded(
                                    child: Text(
                                      context.l10n.newNote,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _controller,
                                    builder: (context, value, _) {
                                      final canShare = value.text.trim().isNotEmpty;
                                      return TextButton(
                                        onPressed: canShare ? _shareNote : null,
                                        child: Text(
                                          context.l10n.shareVerb,
                                          style: TextStyle(
                                            color: canShare ? const Color(0xFF38BDF8) : Colors.white38,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),

                            // Center Avatar + Thought Bubble Floating Over It
                            Center(
                              child: SizedBox(
                                width: 260,
                                height: 175,
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      bottom: 0,
                                      child: AvatarWithFrame(
                                        avatarUrl: myAvatar,
                                        frameId: myFrame,
                                        size: 84,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 240,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF262626) : Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.12)
                                                    : Colors.black.withValues(alpha: 0.08),
                                                width: 0.8,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: TextField(
                                              controller: _controller,
                                              autofocus: true,
                                              maxLength: _maxChars,
                                              maxLines: 3,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isDark ? Colors.white : const Color(0xFF111827),
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: context.l10n.shareNote,
                                                hintStyle: TextStyle(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.45)
                                                      : const Color(0xFF6B7280).withValues(alpha: 0.75),
                                                  fontSize: 14.5,
                                                ),
                                                border: InputBorder.none,
                                                isDense: true,
                                                counterStyle: TextStyle(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.40)
                                                      : const Color(0xFF6B7280),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 11,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF262626) : Colors.white,
                                                    borderRadius: const BorderRadius.only(
                                                      bottomLeft: Radius.circular(5),
                                                      bottomRight: Radius.circular(5),
                                                    ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.12)
                                                          : Colors.black.withValues(alpha: 0.08),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Container(
                                                  width: 5.5,
                                                  height: 5.5,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isDark ? const Color(0xFF262626) : Colors.white,
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.12)
                                                          : Colors.black.withValues(alpha: 0.08),
                                                      width: 0.8,
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
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // User name
                            Text(
                              myName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Audience info
                            Text(
                              context.l10n.sharedWithAudience(context.l10n.audiencePublic),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // Expires in 24 hours
                            Text(
                              context.l10n.expiresIn24Hours,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteViewerModal extends StatefulWidget {
  final Map<String, dynamic> friend;
  final String myUid;

  const _NoteViewerModal({
    required this.friend,
    required this.myUid,
  });

  @override
  State<_NoteViewerModal> createState() => _NoteViewerModalState();
}

class _NoteViewerModalState extends State<_NoteViewerModal> {
  final TextEditingController _msgController = TextEditingController();

  static const List<String> _quickReactions = ['😍', '🙏', '😭', '😂', '😮'];

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _sendReply(String text, {String? emoji}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && emoji == null) return;

    final friendUid = widget.friend['uid'] as String;
    final friendName = widget.friend['name'] as String? ?? 'Bạn bè';
    final noteText = widget.friend['userNote'] as String? ?? '';

    final chatRepo = context.read<ChatRepository>();
    await chatRepo.sendMessage(
      senderId: widget.myUid,
      receiverId: friendUid,
      text: emoji ?? trimmed,
      type: 'note_reply',
      replyToText: noteText,
      replyToSenderName: friendName,
      reactionEmoji: emoji,
    );

    if (!mounted) return;
    Navigator.pop(context);

    // Open chat
    final targetFriend = UserModel.fromMap(widget.friend);
    Navigator.pushNamed(
      context,
      RouteNames.chatConversation,
      arguments: {'friend': targetFriend},
    );
  }

  String _formatRemainingTime(BuildContext context, DateTime? dt) {
    if (dt == null) return context.l10n.expiresIn24Hours;
    final diff = DateTime.now().difference(dt);
    final remainingSeconds = 86400 - diff.inSeconds;
    if (remainingSeconds <= 0) return context.l10n.expiresInHours(0);
    final remainingHours = (remainingSeconds / 3600).ceil();
    if (remainingHours >= 24) return context.l10n.expiresIn24Hours;
    return context.l10n.expiresInHours(remainingHours);
  }

  String _formatNoteTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    return '${diff.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final friendName = widget.friend['name'] as String? ?? 'Bạn bè';
    final avatarUrl = widget.friend['avatarUrl'] as String? ?? '';
    final avatarFrame = widget.friend['avatarFrame'] as String? ?? 'plain';
    final noteText = widget.friend['userNote'] as String? ?? '';
    final noteCreatedAt = widget.friend['userNoteCreatedAt'] as DateTime?;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.75)
                    : Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top Bar (Matches Screenshot 3)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  AvatarWithFrame(
                                    avatarUrl: avatarUrl,
                                    frameId: avatarFrame,
                                    size: 34,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          friendName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (noteCreatedAt != null)
                                          Text(
                                            _formatNoteTime(noteCreatedAt),
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.75),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Large Avatar & Thought Bubble Floating Over It
                            Center(
                              child: SizedBox(
                                width: 260,
                                height: 175,
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      bottom: 0,
                                      child: AvatarWithFrame(
                                        avatarUrl: avatarUrl,
                                        frameId: avatarFrame,
                                        size: 84,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxWidth: 240,
                                              minWidth: 120,
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF262626) : Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.12)
                                                    : Colors.black.withValues(alpha: 0.08),
                                                width: 0.8,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              noteText,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isDark ? Colors.white : const Color(0xFF111827),
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 11,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF262626) : Colors.white,
                                                    borderRadius: const BorderRadius.only(
                                                      bottomLeft: Radius.circular(5),
                                                      bottomRight: Radius.circular(5),
                                                    ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.12)
                                                          : Colors.black.withValues(alpha: 0.08),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Container(
                                                  width: 5.5,
                                                  height: 5.5,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isDark ? const Color(0xFF262626) : Colors.white,
                                                    border: Border.all(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.12)
                                                          : Colors.black.withValues(alpha: 0.08),
                                                      width: 0.8,
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
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Friend Name
                            Text(
                              friendName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Shared with Friends
                            Text(
                              context.l10n.sharedWithAudience(context.l10n.audienceFriends),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // Expires in
                            Text(
                              _formatRemainingTime(context, noteCreatedAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const Spacer(),

                            // Bottom Reactions & Message Input Bar (Matches Screenshot 3)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: _quickReactions.map((emoji) {
                                  return InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _sendReply('', emoji: emoji);
                                    },
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E222B)
                                      : Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.08),
                                    width: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _msgController,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF111827),
                                          fontSize: 14.5,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: context.l10n.sendDirectMessage,
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.5)
                                                : const Color(0xFF6B7280),
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (val) => _sendReply(val),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite_rounded,
                                        color: Color(0xFFFF2D55),
                                      ),
                                      onPressed: () => _sendReply('', emoji: '❤️'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send_rounded, color: Color(0xFF0084FF)),
                                      onPressed: () => _sendReply(_msgController.text),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


