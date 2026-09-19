import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/chat_message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';

class MessageReactionsDetailSheet extends StatefulWidget {
  final ChatMessageModel message;
  final String myUid;
  final String chatId;
  final bool isGroup;
  final String? groupName;
  final Map<String, UserModel>? userCache;
  final Future<void> Function(String emoji)? onRemoveReaction;

  const MessageReactionsDetailSheet({
    super.key,
    required this.message,
    required this.myUid,
    required this.chatId,
    this.isGroup = false,
    this.groupName,
    this.userCache,
    this.onRemoveReaction,
  });

  static Future<void> show({
    required BuildContext context,
    required ChatMessageModel message,
    required String myUid,
    required String chatId,
    bool isGroup = false,
    String? groupName,
    Map<String, UserModel>? userCache,
    Future<void> Function(String emoji)? onRemoveReaction,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MessageReactionsDetailSheet(
        message: message,
        myUid: myUid,
        chatId: chatId,
        isGroup: isGroup,
        groupName: groupName,
        userCache: userCache,
        onRemoveReaction: onRemoveReaction,
      ),
    );
  }

  @override
  State<MessageReactionsDetailSheet> createState() =>
      _MessageReactionsDetailSheetState();
}

class _MessageReactionsDetailSheetState
    extends State<MessageReactionsDetailSheet> {
  final UserRepository _userRepo = UserRepository();
  final ChatRepository _chatRepo = ChatRepository();
  final Map<String, UserModel> _resolvedUsers = {};
  String _selectedFilter = 'ALL'; // 'ALL' or specific emoji
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _messageSub;
  Map<String, String> _currentReactions = {};

  @override
  void initState() {
    super.initState();
    if (widget.userCache != null) {
      _resolvedUsers.addAll(widget.userCache!);
    }

    _currentReactions = Map<String, String>.from(widget.message.reactions);
    _loadUserProfiles(_currentReactions.keys);

    // Stream real-time updates for reactions on this message
    _messageSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(widget.message.id)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null && mounted) {
        final rawReactions = doc.data()!['reactions'] as Map<String, dynamic>?;
        final updated = rawReactions != null
            ? rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()))
            : <String, String>{};

        if (updated.isEmpty) {
          Navigator.of(context).maybePop();
          return;
        }

        setState(() {
          _currentReactions = updated;
        });
        _loadUserProfiles(updated.keys);
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserProfiles(Iterable<String> uids) async {
    for (final uid in uids) {
      if (!_resolvedUsers.containsKey(uid)) {
        final profile = await _userRepo.getUserProfile(uid);
        if (profile != null && mounted) {
          setState(() {
            _resolvedUsers[uid] = profile;
          });
        }
      }
    }
  }

  Future<void> _removeMyReaction(String emoji) async {
    HapticFeedback.mediumImpact();
    if (widget.onRemoveReaction != null) {
      await widget.onRemoveReaction!(emoji);
    } else {
      await _chatRepo.toggleMessageReaction(
        chatId: widget.chatId,
        messageId: widget.message.id,
        userId: widget.myUid,
        emoji: emoji,
        receiverId: widget.message.senderId,
        messageText: widget.message.text,
        isGroup: widget.isGroup,
        groupName: widget.groupName,
      );
    }

    if (mounted) {
      final updated = Map<String, String>.from(_currentReactions);
      updated.remove(widget.myUid);
      if (updated.isEmpty) {
        Navigator.of(context).maybePop();
      } else {
        setState(() {
          _currentReactions = updated;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.maybeLocaleOf(context);
    final isEn = locale?.languageCode.toLowerCase() == 'en';
    final myUid = widget.myUid.isNotEmpty
        ? widget.myUid
        : (context.read<AuthController>().user?.uid ?? '');

    // 1. Sort reactors so current user is always placed FIRST if they reacted
    final allEntries = _currentReactions.entries.toList();
    allEntries.sort((a, b) {
      if (a.key == myUid) return -1;
      if (b.key == myUid) return 1;
      return 0;
    });

    // 2. Filter reactors according to selected emoji tab
    final filteredEntries = _selectedFilter == 'ALL'
        ? allEntries
        : allEntries.where((e) => e.value == _selectedFilter).toList();

    // 3. Count occurrences per emoji for the bottom filter bar
    final emojiCounts = <String, int>{};
    for (final e in allEntries) {
      emojiCounts[e.value] = (emojiCounts[e.value] ?? 0) + 1;
    }

    final totalCount = allEntries.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.58,
        minHeight: 280,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242526) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header: Title & Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      isEn ? 'Reactions' : 'Cảm xúc',
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF3A3B3C)
                              : const Color(0xFFE4E6EB),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Reactor List
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Text(
                        isEn
                            ? 'No reactions found'
                            : 'Chưa có cảm xúc nào',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        final uid = entry.key;
                        final emoji = entry.value;
                        final isMe = uid == myUid;
                        final user = _resolvedUsers[uid];
                        final displayName = user?.name.isNotEmpty == true
                            ? user!.name
                            : (user?.username.isNotEmpty == true
                                ? user!.username
                                : (isMe
                                    ? (isEn ? 'You' : 'Bạn')
                                    : (isEn ? 'Member' : 'Thành viên')));

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isMe ? () => _removeMyReaction(emoji) : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              child: Row(
                                children: [
                                  // User Avatar
                                  if (user != null && user.avatarUrl.isNotEmpty)
                                    AvatarWithFrame(
                                      avatarUrl: user.avatarUrl,
                                      frameId: user.avatarFrame,
                                      size: 46,
                                    )
                                  else
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? const Color(0xFF374151)
                                            : const Color(0xFFE5E7EB),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getInitials(displayName),
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(width: 14),

                                  // User Display Name & Tap to remove hint
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            isEn
                                                ? 'Tap to remove'
                                                : 'Nhấn để gỡ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF65676B),
                                            ),
                                          ),
                                        ] else if (user?.username.isNotEmpty ==
                                            true) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '@${user!.username}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Reaction Emoji
                                  Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1, thickness: 0.7),

            // Bottom Filter Tab Bar (Messenger Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // "ALL" Tab
                    _buildFilterPill(
                      label: isEn
                          ? 'ALL ${totalCount > 0 ? totalCount : ""}'
                          : 'TẤT CẢ ${totalCount > 0 ? totalCount : ""}',
                      isSelected: _selectedFilter == 'ALL',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = 'ALL');
                      },
                      isDark: isDark,
                    ),

                    // Specific Emoji Tabs
                    ...emojiCounts.entries.map((entry) {
                      final emoji = entry.key;
                      final count = entry.value;
                      final isSelected = _selectedFilter == emoji;

                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildFilterPill(
                          emoji: emoji,
                          label: '$emoji $count',
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedFilter = emoji);
                          },
                          isDark: isDark,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    String? emoji,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white24 : Colors.black12)
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF111827))
                : (isDark ? Colors.white60 : const Color(0xFF65676B)),
          ),
        ),
      ),
    );
  }
}
