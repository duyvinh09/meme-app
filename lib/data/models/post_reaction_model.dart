import 'package:cloud_firestore/cloud_firestore.dart';

class PostReactionModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String emoji;
  final DateTime createdAt;

  const PostReactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.emoji,
    required this.createdAt,
  });

  factory PostReactionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PostReactionModel.fromMap(data, doc.id);
  }

  factory PostReactionModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return PostReactionModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      emoji: data['emoji'] ?? '❤️',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'emoji': emoji,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
