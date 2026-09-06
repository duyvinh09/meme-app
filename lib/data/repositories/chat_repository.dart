import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message_model.dart';
import '../models/post_reaction_model.dart';
import '../models/post_view_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

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

  /// Mark all received messages in a chat as read
  Future<void> markMessagesAsRead(String chatId, String myUid) async {
    try {
      final unreadDocs = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: myUid)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadDocs.docs.isEmpty) {
        await _firestore.collection('chats').doc(chatId).set({
          'unreadBy': FieldValue.arrayRemove([myUid]),
          'lastMessageIsRead': true,
        }, SetOptions(merge: true));
        return;
      }

      final batch = _firestore.batch();
      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      batch.set(_firestore.collection('chats').doc(chatId), {
        'unreadBy': FieldValue.arrayRemove([myUid]),
        'lastMessageIsRead': true,
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (_) {}
  }

  /// Listen to real-time chat updates for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserChats(String myUid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots();
  }

  /// Toggle an emoji reaction on a specific message
  Future<void> toggleMessageReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
    required String receiverId,
    required String messageText,
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

      if (reactions[userId] == emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = emoji;
      }

      await msgRef.update({'reactions': reactions});

      // Update parent chat document so in-app notification triggers
      if (reactions.containsKey(userId) && receiverId.isNotEmpty && receiverId != userId) {
        await _firestore.collection('chats').doc(chatId).set({
          'lastMessage': 'Đã bày tỏ cảm xúc $emoji về tin nhắn của bạn',
          'lastSenderId': userId,
          'lastType': 'message_reaction',
          'lastReactionEmoji': emoji,
          'lastReactedMessageText': messageText,
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadBy': [receiverId],
          'lastMessageIsRead': false,
        }, SetOptions(merge: true));
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
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = ChatMessageModel(
        id: messageId,
        senderId: actorUid ?? 'system',
        receiverId: groupId,
        text: systemText,
        type: 'system',
        groupId: groupId,
        createdAt: now,
        isRead: false,
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
          'lastMessage': systemText,
          'lastSenderId': actorUid ?? 'system',
          'lastType': 'system',
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
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
      );

      final chatDoc = await _firestore.collection('chats').doc(groupId).get();
      final participants = (chatDoc.data()?['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [senderId];

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
          'unreadBy': otherMembers,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark all group messages as read by current user
  Future<void> markGroupChatAsRead(String groupId, String myUid) async {
    try {
      final chatRef = _firestore.collection('chats').doc(groupId);
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) return;

      final unreadBy = List<String>.from(chatDoc.data()?['unreadBy'] ?? []);
      if (unreadBy.contains(myUid)) {
        await chatRef.set({
          'unreadBy': FieldValue.arrayRemove([myUid]),
          'lastReadTimestamp': {
            myUid: FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      }

      // Update readBy on recent messages
      final recentMessages = await chatRef
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(30)
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
