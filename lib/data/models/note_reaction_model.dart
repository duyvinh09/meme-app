import 'package:cloud_firestore/cloud_firestore.dart';

class NoteReactionModel {
  final String id;
  final String noteId;
  final String noteOwnerId;
  final String reactorId;
  final String reactorName;
  final String reactorAvatar;
  final String reactorFrame;
  final String emoji;
  final DateTime createdAt;

  const NoteReactionModel({
    required this.id,
    required this.noteId,
    required this.noteOwnerId,
    required this.reactorId,
    required this.reactorName,
    required this.reactorAvatar,
    this.reactorFrame = 'plain',
    required this.emoji,
    required this.createdAt,
  });

  factory NoteReactionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NoteReactionModel.fromMap(data, doc.id);
  }

  factory NoteReactionModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return NoteReactionModel(
      id: id,
      noteId: data['noteId'] ?? '',
      noteOwnerId: data['noteOwnerId'] ?? '',
      reactorId: data['reactorId'] ?? id,
      reactorName: data['reactorName'] ?? '',
      reactorAvatar: data['reactorAvatar'] ?? '',
      reactorFrame: data['reactorFrame'] ?? 'plain',
      emoji: data['emoji'] ?? '❤️',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'noteOwnerId': noteOwnerId,
      'reactorId': reactorId,
      'reactorName': reactorName,
      'reactorAvatar': reactorAvatar,
      'reactorFrame': reactorFrame,
      'emoji': emoji,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
