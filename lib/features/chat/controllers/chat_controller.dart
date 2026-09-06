import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../../core/services/in_app_notification_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/post_reaction_model.dart';
import '../../../data/models/post_view_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/user_repository.dart';

class ChatController extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;

  ChatController({
    required ChatRepository chatRepository,
    required UserRepository userRepository,
  })  : _chatRepository = chatRepository,
        _userRepository = userRepository;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _activeChatFriendId;
  String? get activeChatFriendId => _activeChatFriendId;

  String? _activeChatGroupId;
  String? get activeChatGroupId => _activeChatGroupId;

  void setActiveChatFriend(String? friendUid) {
    _activeChatFriendId = friendUid;
  }

  void setActiveChatGroup(String? groupId) {
    _activeChatGroupId = groupId;
  }

  StreamSubscription? _incomingChatsSub;
  StreamSubscription? _incomingFriendRequestsSub;
  StreamSubscription? _friendsSub;
  StreamSubscription? _mentionsSub;
  final DateTime _sessionStart = DateTime.now();
  final Set<String> _processedMessageKeys = {};
  final Set<String> _processedFriendRequestKeys = {};
  final Set<String> _processedAcceptedFriendKeys = {};

  void disposeListeners() {
    _incomingChatsSub?.cancel();
    _incomingChatsSub = null;
    _incomingFriendRequestsSub?.cancel();
    _incomingFriendRequestsSub = null;
    _friendsSub?.cancel();
    _friendsSub = null;
    _mentionsSub?.cancel();
    _mentionsSub = null;
    _activeChatFriendId = null;
    _activeChatGroupId = null;
    _processedMessageKeys.clear();
    _processedFriendRequestKeys.clear();
    _processedAcceptedFriendKeys.clear();
  }

  void initIncomingMessageListener(String myUid) {
    disposeListeners();
    _incomingChatsSub = _chatRepository.streamUserChats(myUid).listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final lastSenderId = data['lastSenderId'] as String?;
        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        final lastMessage = data['lastMessage'] as String? ?? '';
        final lastType = data['lastType'] as String? ?? 'text';
        final lastPostImageUrl = data['lastPostImageUrl'] as String?;
        final lastReactionEmoji = data['lastReactionEmoji'] as String?;

        final isGroup = data['isGroup'] == true ||
            data['groupId'] != null ||
            data['groupName'] != null ||
            data['ownerUid'] != null;
        final groupId = isGroup
            ? ((data['groupId'] as String?)?.isNotEmpty == true
                ? data['groupId'] as String
                : change.doc.id)
            : null;
        final groupName = data['groupName'] as String?;

        final currentAuthUid = FirebaseAuth.instance.currentUser?.uid;

        // Never notify if sender is myself or matches current Firebase user
        if (lastSenderId == null ||
            lastSenderId == myUid ||
            lastSenderId == currentAuthUid ||
            updatedAt == null) {
          continue;
        }

        // Only process messages updated during current app session
        if (updatedAt.isBefore(_sessionStart.subtract(const Duration(seconds: 2)))) {
          continue;
        }

        final messageKey = '${change.doc.id}_${updatedAt.millisecondsSinceEpoch}';
        if (_processedMessageKeys.contains(messageKey)) {
          continue;
        }
        _processedMessageKeys.add(messageKey);

        final bool isAppResumed =
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        final bool isActivelyInThisChat = isAppResumed &&
            ((isGroup && _activeChatGroupId == groupId) ||
                (!isGroup && _activeChatFriendId == lastSenderId));

        // If user is actively looking at this conversation on screen, don't show popups
        if (isActivelyInThisChat) {
          continue;
        }

        // Fetch sender user profile to display in-app banner & system notification
        final senderUser = await _userRepository.getUserProfile(lastSenderId) ??
            UserModel.fromMap({
              'uid': lastSenderId,
              'name': data['senderName'] ?? (isGroup ? 'Thành viên nhóm' : 'Bạn bè'),
              'username': data['senderName'] ?? '',
              'avatarUrl': '',
            });

        final senderTitle = senderUser.name.isNotEmpty
            ? senderUser.name
            : (senderUser.username.isNotEmpty ? senderUser.username : 'Bạn bè');

        final displayTitle =
            isGroup && groupName != null && groupName.isNotEmpty
                ? '$senderTitle • $groupName'
                : senderTitle;

        if (isAppResumed) {
          InAppNotificationService.instance.showNotification(
            InAppNotificationItem(
              id: messageKey,
              sender: senderUser,
              messageText: lastMessage,
              type: lastType,
              postImageUrl: lastPostImageUrl,
              reactionEmoji: lastReactionEmoji,
              timestamp: updatedAt,
              isGroup: isGroup,
              groupId: groupId,
              groupName: groupName,
            ),
          );
        } else {
          final notifBody = lastType == 'reaction'
              ? 'Đã bày tỏ cảm xúc $lastReactionEmoji vào tin nhắn'
              : (lastPostImageUrl != null && lastPostImageUrl.isNotEmpty
                  ? 'Đã phản hồi bài viết: $lastMessage'
                  : lastMessage);

          NotificationService.instance.showLocalNotification(
            id: messageKey.hashCode,
            title: displayTitle,
            body: notifBody,
            channelId: NotificationService.chatChannelId,
            payload: jsonEncode({
              'type': isGroup ? 'group_chat' : 'chat',
              'groupId': groupId,
              'groupName': groupName,
              'senderUid': senderUser.uid,
              'senderName': displayTitle,
              'senderAvatar': senderUser.avatarUrl,
            }),
          );
        }
      }
    });

    _listenToFriendRequests(myUid);
    _listenToFriendAccepted(myUid);
  }

  void _listenToFriendRequests(String myUid) {
    _incomingFriendRequestsSub?.cancel();
    _incomingFriendRequestsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .snapshots()
        .listen((snapshot) async {
      final bool isAppResumed =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final fromUid = (data['fromUid'] as String?) ?? change.doc.id;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        if (fromUid.isEmpty || fromUid == myUid) continue;

        if (createdAt != null &&
            createdAt.isBefore(_sessionStart.subtract(const Duration(seconds: 4)))) {
          continue;
        }

        final requestKey = 'freq_${fromUid}_${createdAt?.millisecondsSinceEpoch ?? 0}';
        if (_processedFriendRequestKeys.contains(requestKey)) continue;
        _processedFriendRequestKeys.add(requestKey);

        final senderUser = await _userRepository.getUserProfile(fromUid);
        if (senderUser != null) {
          final senderTitle = senderUser.name.isNotEmpty
              ? senderUser.name
              : senderUser.username;

          if (isAppResumed) {
            InAppNotificationService.instance.showNotification(
              InAppNotificationItem(
                id: requestKey,
                sender: senderUser,
                messageText: 'Đã gửi cho bạn một lời mời kết bạn! 👋',
                type: 'friend_request',
                timestamp: createdAt ?? DateTime.now(),
              ),
            );
          } else {
            NotificationService.instance.showLocalNotification(
              id: fromUid.hashCode,
              title: senderTitle,
              body: 'Đã gửi cho bạn một lời mời kết bạn! 👋',
              channelId: NotificationService.friendChannelId,
              payload: jsonEncode({'type': 'friend_request'}),
            );
          }
        }
      }
    });
  }

  void _listenToFriendAccepted(String myUid) {
    _friendsSub?.cancel();
    _friendsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .snapshots()
        .listen((snapshot) async {
      final bool isAppResumed =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final friendUid = (data['uid'] as String?) ?? change.doc.id;
        final addedAt = (data['addedAt'] as Timestamp?)?.toDate();

        if (friendUid.isEmpty || friendUid == myUid) continue;

        // Only process friendships added during this active session
        if (addedAt == null ||
            addedAt.isBefore(_sessionStart.subtract(const Duration(seconds: 4)))) {
          continue;
        }

        final acceptedKey = 'friend_acc_${friendUid}_${addedAt.millisecondsSinceEpoch}';
        if (_processedAcceptedFriendKeys.contains(acceptedKey)) continue;
        _processedAcceptedFriendKeys.add(acceptedKey);

        final friendUser = await _userRepository.getUserProfile(friendUid);
        if (friendUser != null) {
          final friendTitle = friendUser.name.isNotEmpty
              ? friendUser.name
              : friendUser.username;

          if (isAppResumed) {
            InAppNotificationService.instance.showNotification(
              InAppNotificationItem(
                id: acceptedKey,
                sender: friendUser,
                messageText: 'Đã chấp nhận lời mời kết bạn của bạn! 🎉',
                type: 'friend_accepted',
                timestamp: addedAt,
              ),
            );
          } else {
            NotificationService.instance.showLocalNotification(
              id: friendUid.hashCode,
              title: friendTitle,
              body: 'Đã chấp nhận lời mời kết bạn của bạn! 🎉',
              channelId: NotificationService.friendChannelId,
              payload: jsonEncode({'type': 'friend_request'}),
            );
          }
        }
      }
    });

    // 3. Listen to incoming mention notifications
    _mentionsSub?.cancel();
    _mentionsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('notifications')
        .where('type', isEqualTo: 'mention')
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final senderUid = data['senderUid'] as String? ?? '';
        final senderName = data['senderName'] as String? ?? 'Bạn bè';
        final senderAvatar = data['senderAvatar'] as String? ?? '';
        final senderAvatarFrame = data['senderAvatarFrame'] as String? ?? 'plain';
        final postId = data['postId'] as String? ?? '';
        final postImageUrl = data['postImageUrl'] as String?;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        if (senderUid.isEmpty || senderUid == myUid) continue;

        if (createdAt.isBefore(_sessionStart.subtract(const Duration(seconds: 4)))) {
          continue;
        }

        final notifKey = 'mention_${change.doc.id}';
        if (_processedMessageKeys.contains(notifKey)) continue;
        _processedMessageKeys.add(notifKey);

        final bool isAppResumed =
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

        final senderUser = await _userRepository.getUserProfile(senderUid) ??
            UserModel.fromMap({
              'uid': senderUid,
              'name': senderName,
              'username': senderName,
              'avatarUrl': senderAvatar,
              'avatarFrame': senderAvatarFrame,
            });

        final notifText = '$senderName đã nhắc đến bạn trong một bài viết';

        if (isAppResumed) {
          InAppNotificationService.instance.showNotification(
            InAppNotificationItem(
              id: notifKey,
              sender: senderUser,
              messageText: notifText,
              type: 'mention',
              postImageUrl: postImageUrl,
              postId: postId,
              timestamp: createdAt,
            ),
          );
        } else {
          NotificationService.instance.showLocalNotification(
            id: senderUid.hashCode,
            title: 'Meme',
            body: notifText,
            channelId: NotificationService.chatChannelId,
            payload: jsonEncode({
              'type': 'mention',
              'senderUid': senderUid,
              'postId': postId,
            }),
          );
        }
      }
    });
  }

  Stream<List<ChatMessageModel>> messagesStream({
    required String myUid,
    required String friendUid,
  }) {
    final chatId = ChatRepository.getChatId(myUid, friendUid);
    return _chatRepository.getMessagesStream(chatId);
  }

  Stream<List<PostReactionModel>> postReactionsStream(String postId) {
    return _chatRepository.getPostReactionsStream(postId);
  }

  Stream<List<PostViewModel>> postViewsStream(String postId) {
    return _chatRepository.getPostViewsStream(postId);
  }

  Future<void> recordPostView({
    required String postId,
    required String userId,
    required String userName,
    required String userAvatar,
    String userFrame = 'default',
  }) async {
    await _chatRepository.recordPostView(
      postId: postId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      userFrame: userFrame,
    );
  }

  Future<bool> sendTextMessage({
    required String myUid,
    required String friendUid,
    required String text,
    String? bubbleTheme,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      final success = await _chatRepository.sendMessage(
        senderId: myUid,
        receiverId: friendUid,
        text: trimmed,
        type: 'text',
        bubbleTheme: bubbleTheme,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToSenderName: replyToSenderName,
      );
      return success;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> sendPostReply({
    required String myUid,
    required String friendUid,
    required String text,
    required String postId,
    String? postImageUrl,
    String? postCaption,
    DateTime? postCreatedAt,
    String? bubbleTheme,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      final success = await _chatRepository.sendMessage(
        senderId: myUid,
        receiverId: friendUid,
        text: trimmed,
        type: 'post_reply',
        postId: postId,
        postImageUrl: postImageUrl,
        postCaption: postCaption,
        postCreatedAt: postCreatedAt,
        bubbleTheme: bubbleTheme,
      );
      return success;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> sendPostReaction({
    required String postId,
    required String postOwnerId,
    required String myUid,
    required String userName,
    required String userAvatar,
    required String emoji,
    String? postImageUrl,
    String? postCaption,
    DateTime? postCreatedAt,
  }) async {
    return await _chatRepository.sendPostReaction(
      postId: postId,
      postOwnerId: postOwnerId,
      userId: myUid,
      userName: userName,
      userAvatar: userAvatar,
      emoji: emoji,
      postImageUrl: postImageUrl,
      postCaption: postCaption,
      postCreatedAt: postCreatedAt,
    );
  }

  void markChatAsRead({
    required String myUid,
    required String friendUid,
  }) {
    final chatId = ChatRepository.getChatId(myUid, friendUid);
    _chatRepository.markMessagesAsRead(chatId, myUid);
  }

  void markGroupChatAsRead({
    required String groupId,
    required String myUid,
  }) {
    _chatRepository.markGroupChatAsRead(groupId, myUid);
  }

  Future<void> toggleMessageReaction({
    required String myUid,
    required String friendUid,
    required String messageId,
    required String emoji,
    required String messageText,
  }) async {
    final chatId = ChatRepository.getChatId(myUid, friendUid);
    await _chatRepository.toggleMessageReaction(
      chatId: chatId,
      messageId: messageId,
      userId: myUid,
      emoji: emoji,
      receiverId: friendUid,
      messageText: messageText,
    );
  }

  /// Stream whether a friend is currently typing in this chat
  Stream<bool> streamFriendTyping({
    required String myUid,
    required String friendUid,
  }) {
    final chatId = ChatRepository.getChatId(myUid, friendUid);
    return _chatRepository.streamTypingStatus(chatId).map((typingMap) {
      final val = typingMap[friendUid];
      if (val == null || val == false) return false;
      return true;
    });
  }

  /// Update typing status for current user in this chat
  void setTyping({
    required String myUid,
    required String friendUid,
    required bool isTyping,
  }) {
    final chatId = ChatRepository.getChatId(myUid, friendUid);
    _chatRepository.setTypingStatus(
      chatId: chatId,
      userId: myUid,
      isTyping: isTyping,
    );
  }

  /// Unsend / recall message for everyone
  Future<bool> unsendMessage({
    required String myUid,
    required String friendUid,
    required String messageId,
  }) async {
    final chatId = ChatRepository.getChatId(myUid, friendUid);
    final ok = await _chatRepository.unsendMessage(
      chatId: chatId,
      messageId: messageId,
    );
    if (ok) {
      final currentNotif = InAppNotificationService.instance.currentNotification;
      if (currentNotif != null && currentNotif.id.contains(messageId)) {
        InAppNotificationService.instance.dismiss();
      }
    }
    return ok;
  }

  /// Delete message for me
  Future<bool> deleteMessageForMe({
    required String myUid,
    required String friendUid,
    required String messageId,
  }) async {
    final chatId = ChatRepository.getChatId(myUid, friendUid);
    return _chatRepository.deleteMessageForMe(
      chatId: chatId,
      messageId: messageId,
      userId: myUid,
    );
  }

  /// Report inappropriate message
  Future<bool> reportMessage({
    required String reporterId,
    required String reportedUserId,
    required String messageId,
    required String messageText,
    required String reason,
  }) async {
    return _chatRepository.reportMessage(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      messageId: messageId,
      messageText: messageText,
      reason: reason,
    );
  }

  @override
  void dispose() {
    _incomingChatsSub?.cancel();
    _incomingFriendRequestsSub?.cancel();
    _friendsSub?.cancel();
    _mentionsSub?.cancel();
    super.dispose();
  }
}
