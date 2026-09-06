import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';

class InAppNotificationItem {
  final String id;
  final UserModel sender;
  final String messageText;
  final String type; // 'text', 'post_reply', 'reaction'
  final String? postImageUrl;
  final String? reactionEmoji;
  final String? postId;
  final DateTime timestamp;
  final bool isGroup;
  final String? groupId;
  final String? groupName;

  InAppNotificationItem({
    required this.id,
    required this.sender,
    required this.messageText,
    this.type = 'text',
    this.postImageUrl,
    this.reactionEmoji,
    this.postId,
    DateTime? timestamp,
    this.isGroup = false,
    this.groupId,
    this.groupName,
  }) : timestamp = timestamp ?? DateTime.now();
}

class InAppNotificationService extends ChangeNotifier {
  static final InAppNotificationService instance = InAppNotificationService._();
  InAppNotificationService._();

  InAppNotificationItem? _currentNotification;
  InAppNotificationItem? get currentNotification => _currentNotification;

  void showNotification(InAppNotificationItem item) {
    _currentNotification = item;
    notifyListeners();
  }

  void dismiss() {
    if (_currentNotification != null) {
      _currentNotification = null;
      notifyListeners();
    }
  }
}
