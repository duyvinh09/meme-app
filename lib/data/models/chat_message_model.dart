import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String type; // 'text' | 'reaction' | 'post_reply'
  final String? postId;
  final String? postImageUrl;
  final String? postCaption;
  final DateTime? postCreatedAt;
  final String? reactionEmoji;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, String> reactions; // { uid: '❤️' }
  final String? bubbleTheme;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderName;
  final List<String> deletedFor;
  final bool isRecalled;
  final DateTime? recalledAt;
  final String? senderName;
  final String? senderAvatar;
  final String? groupId;
  final List<String> readBy;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = 'text',
    this.postId,
    this.postImageUrl,
    this.postCaption,
    this.postCreatedAt,
    this.reactionEmoji,
    required this.createdAt,
    this.isRead = false,
    this.reactions = const {},
    this.bubbleTheme,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
    this.deletedFor = const [],
    this.isRecalled = false,
    this.recalledAt,
    this.senderName,
    this.senderAvatar,
    this.groupId,
    this.readBy = const [],
  });

  bool get isSystem => type == 'system';
  bool get isGroup => groupId != null && groupId!.isNotEmpty;

  factory ChatMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatMessageModel.fromMap(data, doc.id);
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, String> parseReactions(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return const {};
    }

    List<String> parseDeletedFor(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return const [];
    }

    List<String> parseReadBy(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return ChatMessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'text',
      postId: data['postId'],
      postImageUrl: data['postImageUrl'],
      postCaption: data['postCaption'],
      postCreatedAt: data['postCreatedAt'] != null
          ? parseDate(data['postCreatedAt'])
          : null,
      reactionEmoji: data['reactionEmoji'],
      createdAt: parseDate(data['createdAt']),
      isRead: data['isRead'] ?? false,
      reactions: parseReactions(data['reactions']),
      bubbleTheme: data['bubbleTheme'],
      replyToMessageId: data['replyToMessageId'],
      replyToText: data['replyToText'],
      replyToSenderName: data['replyToSenderName'],
      deletedFor: parseDeletedFor(data['deletedFor']),
      isRecalled: data['isRecalled'] == true,
      recalledAt: data['recalledAt'] != null
          ? parseDate(data['recalledAt'])
          : null,
      senderName: data['senderName'],
      senderAvatar: data['senderAvatar'],
      groupId: data['groupId'],
      readBy: parseReadBy(data['readBy']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type,
      if (postId != null) 'postId': postId,
      if (postImageUrl != null) 'postImageUrl': postImageUrl,
      if (postCaption != null) 'postCaption': postCaption,
      if (postCreatedAt != null)
        'postCreatedAt': Timestamp.fromDate(postCreatedAt!),
      if (reactionEmoji != null) 'reactionEmoji': reactionEmoji,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (reactions.isNotEmpty) 'reactions': reactions,
      if (bubbleTheme != null) 'bubbleTheme': bubbleTheme,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (deletedFor.isNotEmpty) 'deletedFor': deletedFor,
      'isRecalled': isRecalled,
      if (recalledAt != null) 'recalledAt': Timestamp.fromDate(recalledAt!),
      if (senderName != null) 'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      if (groupId != null) 'groupId': groupId,
      if (readBy.isNotEmpty) 'readBy': readBy,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    String? type,
    String? postId,
    String? postImageUrl,
    String? postCaption,
    DateTime? postCreatedAt,
    String? reactionEmoji,
    DateTime? createdAt,
    bool? isRead,
    Map<String, String>? reactions,
    String? bubbleTheme,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
    List<String>? deletedFor,
    bool? isRecalled,
    DateTime? recalledAt,
    String? senderName,
    String? senderAvatar,
    String? groupId,
    List<String>? readBy,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      postCaption: postCaption ?? this.postCaption,
      postCreatedAt: postCreatedAt ?? this.postCreatedAt,
      reactionEmoji: reactionEmoji ?? this.reactionEmoji,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      bubbleTheme: bubbleTheme ?? this.bubbleTheme,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      deletedFor: deletedFor ?? this.deletedFor,
      isRecalled: isRecalled ?? this.isRecalled,
      recalledAt: recalledAt ?? this.recalledAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      groupId: groupId ?? this.groupId,
      readBy: readBy ?? this.readBy,
    );
  }
}
