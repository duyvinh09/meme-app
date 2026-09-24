import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message_model.dart';
import '../models/note_reaction_model.dart';
import '../models/post_reaction_model.dart';
import '../models/post_view_model.dart';
import '../../core/services/fcm_push_service.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  /// Cooldown cache to avoid spamming push notifications when a user taps reaction multiple times on a post
  final Map<String, DateTime> _postReactionNotifSentAt = {};

  ChatRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  static String getChatId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Listen to real-time messages in a specific chat
  Stream<List<ChatMessageModel>> getMessagesStream(String chatId, {int limit = 100}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromDoc(doc))
          .toList();
    });
  }

  /// Send a message (text, reaction, or post_reply)
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String type = 'text',
    String? postId,
    String? postImageUrl,
    String? postCaption,
    DateTime? postCreatedAt,
    String? reactionEmoji,
    String? bubbleTheme,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
    String? postAuthorName,
    String? postAuthorAvatar,
    String? postAuthorFrame,
    String? postOwnerId,
  }) async {
    try {
      final chatId = getChatId(senderId, receiverId);
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = ChatMessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        type: type,
        postId: postId,
        postImageUrl: postImageUrl,
        postCaption: postCaption,
        postCreatedAt: postCreatedAt,
        reactionEmoji: reactionEmoji,
        createdAt: now,
        isRead: false,
        bubbleTheme: bubbleTheme,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToSenderName: replyToSenderName,
        postAuthorName: postAuthorName,
        postAuthorAvatar: postAuthorAvatar,
        postAuthorFrame: postAuthorFrame,
        postOwnerId: postOwnerId,
      );

      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final chatRef = _firestore.collection('chats').doc(chatId);

      batch.set(messageRef, message.toMap());
      batch.set(
        chatRef,
        {
          'lastMessage': text,
          'lastSenderId': senderId,
          'lastType': type,
          'lastPostId': postId,
          'lastPostImageUrl': postImageUrl,
          'lastReactionEmoji': reactionEmoji,
          'updatedAt': Timestamp.fromDate(now),
          'participants': [senderId, receiverId],
          'unreadBy': [receiverId],
          'lastMessageIsRead': false,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      // Trigger FCM Push notification directly
      unawaited(() async {
        try {
          // Check if receiver muted this chat
          final chatDoc = await _firestore.collection('chats').doc(chatId).get();
          final chatData = chatDoc.data();
          if (chatData != null && isChatMuted(chatData, receiverId)) {
            return;
          }

          final senderDoc =
              await _firestore.collection('users').doc(senderId).get();
          final senderData = senderDoc.data();
          final senderName =
              senderData?['name'] ?? senderData?['username'] ?? 'Bạn bè';
          final senderAvatar = senderData?['avatarUrl']?.toString();

          await FcmPushService.instance.sendChatMessageNotification(
            senderId: senderId,
            receiverId: receiverId,
            senderName: senderName,
            senderAvatar: senderAvatar,
            messageText: text,
            type: type,
            reactionEmoji: reactionEmoji,
          );
        } catch (_) {}
      }());

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Send a direct reaction to a post (creates a post reaction for feed animations and post activity)
  Future<bool> sendPostReaction({
    required String postId,
    required String postOwnerId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String emoji,
    String? postImageUrl,
    String? postCaption,
    DateTime? postCreatedAt,
  }) async {
    try {
      final reactionId = _uuid.v4();
      final now = DateTime.now();

      // Save reaction under transaction subcollection for floating animations & activity list
      final reactionRef = _firestore
          .collection('transactions')
          .doc(postId)
          .collection('reactions')
          .doc(reactionId);

      final reaction = PostReactionModel(
        id: reactionId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        emoji: emoji,
        createdAt: now,
      );

      await reactionRef.set(reaction.toMap());

      if (postOwnerId != userId) {
        final spamKey = '${postId}_$userId';
        final lastSent = _postReactionNotifSentAt[spamKey];

        // Only send push notification for the first reaction or after a 5-minute cooldown
        final bool isWithinCooldown =
            lastSent != null && now.difference(lastSent).inMinutes < 5;

        if (!isWithinCooldown) {
          _postReactionNotifSentAt[spamKey] = now;
          unawaited(() async {
            try {
              // Double check if this is the first reaction on this post by this user
              final existingSnap = await _firestore
                  .collection('transactions')
                  .doc(postId)
                  .collection('reactions')
                  .where('userId', isEqualTo: userId)
                  .limit(2)
                  .get();

              // Only dispatch push notification if there is at most 1 reaction (this newly created one)
              if (existingSnap.docs.length <= 1) {
                await FcmPushService.instance.sendPostReactionNotification(
                  postId: postId,
                  postOwnerId: postOwnerId,
                  reactorId: userId,
                  reactorName: userName,
                  reactorAvatar: userAvatar,
                  emoji: emoji,
                );
              }
            } catch (_) {}
          }());
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Record that a user viewed a post
  Future<void> recordPostView({
    required String postId,
    required String userId,
    required String userName,
    required String userAvatar,
    String userFrame = 'default',
  }) async {
    try {
      final docRef = _firestore
          .collection('transactions')
          .doc(postId)
          .collection('views')
          .doc(userId);

      await docRef.set({
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'userFrame': userFrame,
        'viewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Listen to real-time views on a specific post
  Stream<List<PostViewModel>> getPostViewsStream(String postId) {
    return _firestore
        .collection('transactions')
        .doc(postId)
        .collection('views')
        .orderBy('viewedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostViewModel.fromDoc(doc))
          .toList();
    });
  }

  /// Listen to real-time reactions on a specific post
  Stream<List<PostReactionModel>> getPostReactionsStream(String postId) {
    return _firestore
        .collection('transactions')
        .doc(postId)
        .collection('reactions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostReactionModel.fromDoc(doc))
          .toList();
    });
  }

  /// Send reaction to a friend's Note
  /// 1. Persists the reaction in users/{noteOwnerId}/note_reactions/{reactorId}
  /// 2. Creates a private chat message in background between reactor and note owner
  Future<bool> sendNoteReaction({
    required String noteOwnerId,
    required String noteId,
    required String noteText,
    required String noteOwnerName,
    required String reactorId,
    required String reactorName,
    required String reactorAvatar,
    String reactorFrame = 'plain',
    required String emoji,
  }) async {
    try {
      final now = DateTime.now();

      // 1. Save reaction in noteOwner's note_reactions subcollection
      final reactionRef = _firestore
          .collection('users')
          .doc(noteOwnerId)
          .collection('note_reactions')
          .doc(reactorId);

      // Check existing reaction to avoid sending duplicate chat message if user taps the same emoji
      final existingDoc = await reactionRef.get();
      final bool isSameEmoji = existingDoc.exists && existingDoc.data()?['emoji'] == emoji;

      final reaction = NoteReactionModel(
        id: reactorId,
        noteId: noteId,
        noteOwnerId: noteOwnerId,
        reactorId: reactorId,
        reactorName: reactorName,
        reactorAvatar: reactorAvatar,
        reactorFrame: reactorFrame,
        emoji: emoji,
        createdAt: now,
      );

      await reactionRef.set(reaction.toMap(), SetOptions(merge: true));

      // 2. Send private chat message only if emoji is new or changed (or first time)
      if (!isSameEmoji && reactorId != noteOwnerId) {
        await sendMessage(
          senderId: reactorId,
          receiverId: noteOwnerId,
          text: emoji,
          type: 'note_reply',
          replyToText: noteText,
          replyToSenderName: noteOwnerName,
          reactionEmoji: emoji,
        );

        unawaited(() async {
          try {
            await FcmPushService.instance.sendNoteReactionNotification(
              noteOwnerId: noteOwnerId,
              reactorId: reactorId,
              reactorName: reactorName,
              reactorAvatar: reactorAvatar,
              emoji: emoji,
            );
          } catch (_) {}
        }());
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Listen to real-time reactions on a specific user's active Note
  Stream<List<NoteReactionModel>> getNoteReactionsStream(String noteOwnerId) {
    return _firestore
        .collection('users')
        .doc(noteOwnerId)
        .collection('note_reactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NoteReactionModel.fromDoc(doc))
          .toList();
    });
  }

  /// Delete all note reactions for a user
  Future<void> deleteNoteReactions(String noteOwnerId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(noteOwnerId)
          .collection('note_reactions')
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }


  /// Mark all received messages in a chat as read
  Future<void> markMessagesAsRead(String chatId, String myUid) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      await chatRef.set({
        'unreadBy': FieldValue.arrayRemove([myUid]),
        'lastMessageIsRead': true,
      }, SetOptions(merge: true));

      final unreadDocs = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final batch = _firestore.batch();
      bool hasUpdates = false;
      for (final doc in unreadDocs.docs) {
        final data = doc.data();
        if (data['senderId'] != myUid && data['isRead'] != true) {
          batch.update(doc.reference, {'isRead': true});
          hasUpdates = true;
        }
      }
      if (hasUpdates) {
        await batch.commit();
      }
    } catch (_) {}
  }

  /// Listen to real-time chat updates for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserChats(String myUid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots();
  }

  /// Stream total count of all unread individual messages across all unmuted chats & groups
  Stream<int> streamTotalUnreadCount(String myUid) {
    if (myUid.isEmpty) return Stream.value(0);

    late StreamController<int> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? userChatsSub;
    final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
        messageSubs = {};
    final Map<String, int> chatUnreadCounts = {};

    void updateAndEmitTotal() {
      if (controller.isClosed) return;
      int total = 0;
      for (final count in chatUnreadCounts.values) {
        total += count;
      }
      controller.add(total);
    }

    void cleanUpSubscriptions() {
      userChatsSub?.cancel();
      userChatsSub = null;
      for (final sub in messageSubs.values) {
        sub.cancel();
      }
      messageSubs.clear();
      chatUnreadCounts.clear();
    }

    controller = StreamController<int>(
      onListen: () {
        userChatsSub = streamUserChats(myUid).listen(
          (snapshot) {
            final activeUnreadChatIds = <String>{};

            for (final doc in snapshot.docs) {
              final data = doc.data();
              final chatId = doc.id;

              // 1. Skip if muted
              if (isChatMuted(data, myUid)) {
                chatUnreadCounts.remove(chatId);
                messageSubs.remove(chatId)?.cancel();
                continue;
              }

              final isGroup = data['isGroup'] == true;
              final unreadBy = List<String>.from(data['unreadBy'] ?? []);
              final lastSenderId = (data['lastSenderId'] ?? '').toString();

              final bool isUnread = isGroup
                  ? unreadBy.contains(myUid)
                  : (unreadBy.contains(myUid) ||
                      (lastSenderId.isNotEmpty &&
                          lastSenderId != myUid &&
                          data['lastMessageIsRead'] == false));

              if (!isUnread) {
                chatUnreadCounts.remove(chatId);
                messageSubs.remove(chatId)?.cancel();
                continue;
              }

              activeUnreadChatIds.add(chatId);

              // If already listening to this chat's messages, keep it
              if (messageSubs.containsKey(chatId)) {
                continue;
              }

              // Listen to messages in this unread chat
              if (isGroup) {
                messageSubs[chatId] = _firestore
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots()
                    .listen(
                  (msgSnapshot) {
                    final count = msgSnapshot.docs.where((mDoc) {
                      final mData = mDoc.data();
                      if (mData['senderId'] == myUid) return false;
                      final readBy =
                          List<String>.from(mData['readBy'] ?? []);
                      return !readBy.contains(myUid);
                    }).length;

                    chatUnreadCounts[chatId] = count > 0 ? count : 1;
                    updateAndEmitTotal();
                  },
                  onError: (_) {
                    chatUnreadCounts[chatId] = 1;
                    updateAndEmitTotal();
                  },
                );
              } else {
                messageSubs[chatId] = _firestore
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots()
                    .listen(
                  (msgSnapshot) {
                    final count = msgSnapshot.docs.where((mDoc) {
                      final mData = mDoc.data();
                      if (mData['senderId'] == myUid) return false;
                      return mData['isRead'] != true;
                    }).length;

                    chatUnreadCounts[chatId] = count > 0 ? count : 1;
                    updateAndEmitTotal();
                  },
                  onError: (_) {
                    chatUnreadCounts[chatId] = 1;
                    updateAndEmitTotal();
                  },
                );
              }
            }

            // Remove any message subs for chats that are no longer unread
            final removedChatIds = messageSubs.keys
                .where((id) => !activeUnreadChatIds.contains(id))
                .toList();
            for (final id in removedChatIds) {
              messageSubs.remove(id)?.cancel();
              chatUnreadCounts.remove(id);
            }

            updateAndEmitTotal();
          },
          onError: (err) {
            if (!controller.isClosed) {
              controller.addError(err);
            }
          },
        );
      },
      onCancel: () {
        cleanUpSubscriptions();
      },
    );

    return controller.stream;
  }

  /// Toggle an emoji reaction on a specific message
  Future<void> toggleMessageReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
    required String receiverId,
    required String messageText,
    bool isGroup = false,
    String? groupName,
  }) async {
    try {
      final msgRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final msgDoc = await msgRef.get();
      if (!msgDoc.exists) return;

      final data = msgDoc.data() ?? {};
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
      final isAddingReaction = reactions[userId] != emoji;

      if (reactions[userId] == emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = emoji;
      }

      await msgRef.update({'reactions': reactions});

      // Update parent chat document and dispatch push notification if adding reaction
      if (isAddingReaction && receiverId.isNotEmpty && receiverId != userId) {
        final chatDoc = await _firestore.collection('chats').doc(chatId).get();
        final chatData = chatDoc.data() ?? {};
        final resolvedGroupName = groupName ?? (chatData['groupName'] as String?) ?? 'Nhóm';

        await _firestore.collection('chats').doc(chatId).set({
          'lastMessage': 'Đã bày tỏ cảm xúc $emoji về tin nhắn của bạn',
          'lastSenderId': userId,
          'lastType': 'reaction',
          'lastReactionEmoji': emoji,
          'lastReactedMessageText': messageText,
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadBy': [receiverId],
          'lastMessageIsRead': false,
        }, SetOptions(merge: true));

        // Check if recipient muted this chat before dispatching FCM push
        final isMuted = isChatMuted(chatData, receiverId);
        if (!isMuted) {
          unawaited(() async {
            try {
              final userDoc = await _firestore.collection('users').doc(userId).get();
              final senderName = userDoc.data()?['name'] ?? userDoc.data()?['username'] ?? (isGroup ? 'Thành viên nhóm' : 'Bạn bè');
              final senderAvatar = userDoc.data()?['avatarUrl'] ?? '';

              if (isGroup) {
                await FcmPushService.instance.sendGroupMessageReactionNotification(
                  groupId: chatId,
                  groupName: resolvedGroupName,
                  senderId: userId,
                  targetUserId: receiverId,
                  senderName: senderName,
                  emoji: emoji,
                  messageText: messageText,
                );
              } else {
                await FcmPushService.instance.sendMessageReactionNotification(
                  senderId: userId,
                  receiverId: receiverId,
                  senderName: senderName,
                  senderAvatar: senderAvatar,
                  emoji: emoji,
                  messageText: messageText,
                );
              }
            } catch (_) {}
          }());
        }
      }
    } catch (_) {}
  }

  /// Stream typing status for a chat
  Stream<Map<String, dynamic>> streamTypingStatus(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return {};
      final typingMap = data['typing'] as Map<String, dynamic>?;
      return typingMap ?? {};
    });
  }

  /// Set typing status in a chat
  Future<void> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'typing': {
          userId: isTyping,
        },
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Unsend / Recall message for everyone (syncs across sender and receiver)
  Future<bool> unsendMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final msgRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final msgDoc = await msgRef.get();
      if (!msgDoc.exists) return false;

      final batch = _firestore.batch();

      batch.update(msgRef, {
        'isRecalled': true,
        'recalledAt': FieldValue.serverTimestamp(),
        'text': '',
        'type': 'text',
        'postImageUrl': FieldValue.delete(),
        'postCaption': FieldValue.delete(),
        'postId': FieldValue.delete(),
        'reactionEmoji': FieldValue.delete(),
        'reactions': {},
      });

      // Check if this message was the latest message in chat
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      if (chatDoc.exists) {
        final chatData = chatDoc.data() ?? {};
        final lastSenderId = chatData['lastSenderId'];
        final msgSenderId = msgDoc.data()?['senderId'];
        if (lastSenderId == msgSenderId) {
          batch.update(chatRef, {
            'lastMessage': 'Tin nhắn đã được thu hồi',
            'lastType': 'recalled',
            'lastPostImageUrl': FieldValue.delete(),
            'lastReactionEmoji': FieldValue.delete(),
          });
        }
      }

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete message for me (hide locally)
  Future<bool> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Report inappropriate message
  Future<bool> reportMessage({
    required String reporterId,
    required String reportedUserId,
    required String messageId,
    required String messageText,
    required String reason,
  }) async {
    try {
      final reportId = _uuid.v4();
      await _firestore.collection('reports').doc(reportId).set({
        'id': reportId,
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'messageId': messageId,
        'messageText': messageText,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'chat_message',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Create or initialize a group chat document
  Future<bool> createGroupChat({
    required String groupId,
    required String groupName,
    required String groupColor,
    required String ownerUid,
    required List<String> memberUids,
    String? initialSystemMessage,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(groupId);
      final uniqueMembers = {ownerUid, ...memberUids}.toList();
      final now = DateTime.now();

      final data = {
        'id': groupId,
        'isGroup': true,
        'groupId': groupId,
        'groupName': groupName,
        'groupColor': groupColor,
        'ownerUid': ownerUid,
        'participants': uniqueMembers,
        'unreadBy': memberUids,
        'lastMessage': initialSystemMessage ?? 'Nhóm chi tiêu đã được tạo',
        'lastSenderId': ownerUid,
        'lastType': 'system',
        'updatedAt': Timestamp.fromDate(now),
        'lastMessageIsRead': false,
      };

      await chatRef.set(data, SetOptions(merge: true));

      if (initialSystemMessage != null && initialSystemMessage.isNotEmpty) {
        await sendGroupSystemMessage(
          groupId: groupId,
          systemText: initialSystemMessage,
          actorUid: ownerUid,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Send a system log message to group chat
  Future<bool> sendGroupSystemMessage({
    required String groupId,
    required String systemText,
    String? actorUid,
    String? postId,
    String? postImageUrl,
    String? postCaption,
    DateTime? postCreatedAt,
    /// Metadata for Nearby Place Suggestions: category of the expense
    String? transactionCategory,
    /// Metadata for Nearby Place Suggestions: amount of the expense
    double? transactionAmount,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      // Fetch group chat doc to retrieve members and group name
      final groupDoc = await _firestore.collection('chats').doc(groupId).get();
      final groupData = groupDoc.data() ?? {};
      final groupName = groupData['groupName']?.toString() ?? 'Nhóm';
      final rawParticipants = (groupData['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final targetMembers = rawParticipants
          .where((id) => id != actorUid)
          .toList();

      final message = ChatMessageModel(
        id: messageId,
        senderId: actorUid ?? 'system',
        receiverId: groupId,
        text: systemText,
        type: 'system',
        postId: postId,
        postImageUrl: postImageUrl,
        postCaption: postCaption,
        postCreatedAt: postCreatedAt,
        groupId: groupId,
        createdAt: now,
        isRead: false,
        transactionCategory: transactionCategory,
        transactionAmount: transactionAmount,
      );

      final batch = _firestore.batch();
      final messageRef = _firestore
          .collection('chats')
          .doc(groupId)
          .collection('messages')
          .doc(messageId);
      final chatRef = _firestore.collection('chats').doc(groupId);

      batch.set(messageRef, message.toMap());
      batch.set(
        chatRef,
        {
          'isGroup': true,
          'groupId': groupId,
          'groupName': groupName,
          'lastMessage': systemText,
          'lastSenderId': actorUid ?? 'system',
          'lastType': 'system',
          'unreadBy': targetMembers,
          'lastMessageIsRead': false,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      // Trigger FCM Push notification to group members for system spending events
      unawaited(() async {
        try {
          final activeTargetMembers = targetMembers
              .where((id) => !isChatMuted(groupData, id))
              .toList();
          if (activeTargetMembers.isNotEmpty) {
            await FcmPushService.instance.sendGroupChatMessageNotification(
              groupId: groupId,
              groupName: groupName,
              senderId: actorUid ?? 'system',
              senderName: groupName,
              messageText: systemText,
              memberIds: activeTargetMembers,
              isSystem: true,
            );
          }
        } catch (_) {}
      }());

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Send a message to a group chat
  Future<bool> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String text,
    String type = 'text',
    String? bubbleTheme,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
    String? postId,
    String? postImageUrl,
    String? postCaption,
    DateTime? postCreatedAt,
    String? postAuthorName,
    String? postAuthorAvatar,
    String? postAuthorFrame,
    String? postOwnerId,
    List<String> taggedUserIds = const [],
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = ChatMessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: groupId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        groupId: groupId,
        text: text,
        type: type,
        createdAt: now,
        isRead: false,
        readBy: [senderId],
        bubbleTheme: bubbleTheme,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToSenderName: replyToSenderName,
        postId: postId,
        postImageUrl: postImageUrl,
        postCaption: postCaption,
        postCreatedAt: postCreatedAt,
        postAuthorName: postAuthorName,
        postAuthorAvatar: postAuthorAvatar,
        postAuthorFrame: postAuthorFrame,
        postOwnerId: postOwnerId,
        taggedUserIds: taggedUserIds,
      );

      final chatDoc = await _firestore.collection('chats').doc(groupId).get();
      final chatData = chatDoc.data() ?? {};
      var participants = (chatData['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Fallback: check group document in user's subcollection
      if (participants.isEmpty || (participants.length == 1 && participants.contains(senderId))) {
        try {
          final userGroupDoc = await _firestore
              .collection('users')
              .doc(senderId)
              .collection('groups')
              .doc(groupId)
              .get();
          if (userGroupDoc.exists) {
            final memberIds = (userGroupDoc.data()?['memberIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();
            if (memberIds != null && memberIds.isNotEmpty) {
              participants = memberIds;
            }
          }
        } catch (_) {}
      }

      // Block sending if the user is no longer a member of this group
      if (participants.isNotEmpty && !participants.contains(senderId)) {
        return false;
      }

      final otherMembers = participants.where((id) => id != senderId).toList();

      final batch = _firestore.batch();
      final messageRef = _firestore
          .collection('chats')
          .doc(groupId)
          .collection('messages')
          .doc(messageId);
      final chatRef = _firestore.collection('chats').doc(groupId);

      batch.set(messageRef, message.toMap());
      batch.set(
        chatRef,
        {
          'isGroup': true,
          'groupId': groupId,
          'lastMessage': '$senderName: $text',
          'lastSenderId': senderId,
          'lastType': type,
          if (postImageUrl != null) 'lastPostImageUrl': postImageUrl,
          if (postCaption != null) 'lastPostCaption': postCaption,
          'unreadBy': otherMembers,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      // Trigger Push notifications
      if (otherMembers.isNotEmpty) {
        unawaited(() async {
          try {
            final groupName = chatData['groupName']?.toString() ?? 'Nhóm';

            // 1. Send specific Mention Notifications to tagged users (even if muted)
            final validTaggedMembers = taggedUserIds
                .where((id) => id != senderId && otherMembers.contains(id))
                .toList();

            for (final taggedUid in validTaggedMembers) {
              await FcmPushService.instance.sendGroupMentionNotification(
                groupId: groupId,
                groupName: groupName,
                senderId: senderId,
                senderName: senderName,
                messageText: text,
                targetUserId: taggedUid,
              );
            }

            // 2. Send normal group message notifications to unmuted members who are NOT tagged
            final unmutedOtherMembers = otherMembers.where((id) {
              final isMuted = isChatMuted(chatData, id);
              final isTagged = validTaggedMembers.contains(id);
              return !isMuted && !isTagged;
            }).toList();

            if (unmutedOtherMembers.isNotEmpty) {
              await FcmPushService.instance.sendGroupChatMessageNotification(
                groupId: groupId,
                groupName: groupName,
                senderId: senderId,
                senderName: senderName,
                messageText: text,
                memberIds: unmutedOtherMembers,
              );
            }
          } catch (_) {}
        }());
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Helper to check if a chat is currently muted for a specific user (handles timed mute)
  bool isChatMuted(Map<String, dynamic>? data, String uid) {
    if (data == null || uid.isEmpty) return false;

    // 1. Check timed mute map
    final mutedUntilMap = data['mutedUntil'];
    if (mutedUntilMap is Map && mutedUntilMap.containsKey(uid)) {
      final rawUntil = mutedUntilMap[uid];
      if (rawUntil == null) return true; // muted indefinitely
      if (rawUntil is Timestamp) {
        return rawUntil.toDate().isAfter(DateTime.now());
      }
    }

    // 2. Check legacy / permanent mutedBy list
    final mutedBy = data['mutedBy'];
    if (mutedBy is List && mutedBy.contains(uid)) {
      if (mutedUntilMap is Map && mutedUntilMap.containsKey(uid)) {
        final rawUntil = mutedUntilMap[uid];
        if (rawUntil is Timestamp && rawUntil.toDate().isBefore(DateTime.now())) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  /// Mute chat notifications for a user with optional duration (null = indefinite)
  Future<void> muteChat({
    required String chatId,
    required String uid,
    Duration? duration,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final now = DateTime.now();
      final untilDate = duration != null ? now.add(duration) : null;

      final updateData = <String, dynamic>{
        'mutedBy': FieldValue.arrayUnion([uid]),
      };

      if (untilDate != null) {
        updateData['mutedUntil.$uid'] = Timestamp.fromDate(untilDate);
      } else {
        updateData['mutedUntil.$uid'] = null;
      }

      await chatRef.update(updateData);
    } catch (e) {
      try {
        final chatRef = _firestore.collection('chats').doc(chatId);
        final untilDate = duration != null ? DateTime.now().add(duration) : null;
        await chatRef.set({
          'mutedBy': FieldValue.arrayUnion([uid]),
          'mutedUntil': {
            uid: untilDate != null ? Timestamp.fromDate(untilDate) : null,
          },
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Unmute chat notifications for a user
  Future<void> unmuteChat({
    required String chatId,
    required String uid,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      await chatRef.update({
        'mutedBy': FieldValue.arrayRemove([uid]),
        'mutedUntil.$uid': FieldValue.delete(),
      });
    } catch (e) {
      try {
        final chatRef = _firestore.collection('chats').doc(chatId);
        await chatRef.set({
          'mutedBy': FieldValue.arrayRemove([uid]),
          'mutedUntil': {
            uid: FieldValue.delete(),
          },
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Toggle mute notifications for a group for a specific user (backwards compatible)
  Future<void> toggleMuteGroup({
    required String groupId,
    required String uid,
    required bool isMuted,
    Duration? duration,
  }) async {
    if (isMuted) {
      await muteChat(chatId: groupId, uid: uid, duration: duration);
    } else {
      await unmuteChat(chatId: groupId, uid: uid);
    }
  }

  /// Mark all group messages as read by current user
  Future<void> markGroupChatAsRead(String groupId, String myUid) async {
    try {
      final chatRef = _firestore.collection('chats').doc(groupId);
      await chatRef.set({
        'unreadBy': FieldValue.arrayRemove([myUid]),
        'lastReadTimestamp': {
          myUid: FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // Update readBy on recent messages
      final recentMessages = await chatRef
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final batch = _firestore.batch();
      bool hasUpdates = false;

      for (final doc in recentMessages.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(myUid)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([myUid]),
          });
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (_) {}
  }

  /// Stream unread message count for a group chat
  Stream<int> streamGroupUnreadCount(String groupId, String myUid) {
    return _firestore
        .collection('chats')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final unreadCount = snapshot.docs.where((doc) {
        final data = doc.data();
        if (data['senderId'] == myUid) return false;
        final readBy = List<String>.from(data['readBy'] ?? []);
        return !readBy.contains(myUid);
      }).length;
      return unreadCount;
    });
  }

  /// Update participants and group metadata in chat
  Future<void> updateGroupChatMetadata({
    required String groupId,
    String? groupName,
    String? groupColor,
    List<String>? participants,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (groupName != null) updates['groupName'] = groupName;
      if (groupColor != null) updates['groupColor'] = groupColor;
      if (participants != null) updates['participants'] = participants;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('chats')
            .doc(groupId)
            .set(updates, SetOptions(merge: true));
      }
    } catch (_) {}
  }
}
