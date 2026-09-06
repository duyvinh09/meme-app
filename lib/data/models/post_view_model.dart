import 'package:cloud_firestore/cloud_firestore.dart';

class PostViewModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String userFrame;
  final DateTime viewedAt;

  const PostViewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.userFrame = 'default',
    required this.viewedAt,
  });

  factory PostViewModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PostViewModel.fromMap(data, doc.id);
  }

  factory PostViewModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return PostViewModel(
      id: id,
      userId: data['userId'] ?? id,
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      userFrame: data['userFrame'] ?? 'default',
      viewedAt: parseDate(data['viewedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'userFrame': userFrame,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }
}
