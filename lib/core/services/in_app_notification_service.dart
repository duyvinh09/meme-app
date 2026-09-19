import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

class InAppNotificationItem {
  final String id;
  final UserModel sender;
  final String messageText;
  final String type; // 'text', 'post_reply', 'reaction', 'rewind', etc.
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

  static const String _prefsKeyShownIds = 'in_app_shown_notification_ids';
  InAppNotificationItem? _currentNotification;
  InAppNotificationItem? get currentNotification => _currentNotification;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _shownNotificationIds = {};
  bool _isLoadedFromPrefs = false;

  String? _activeChatFriendId;
  String? get activeChatFriendId => _activeChatFriendId;

  String? _activeChatGroupId;
  String? get activeChatGroupId => _activeChatGroupId;

  Future<void> ensureLoaded() async {
    if (_isLoadedFromPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKeyShownIds) ?? [];
      _shownNotificationIds.addAll(list);
      _isLoadedFromPrefs = true;
    } catch (_) {}
  }

  void setActiveChatFriend(String? friendUid) {
    _activeChatFriendId = friendUid;
  }

  void setActiveChatGroup(String? groupId) {
    _activeChatGroupId = groupId;
  }

  bool isCurrentlyInChat({String? friendId, String? groupId}) {
    if (groupId != null &&
        groupId.isNotEmpty &&
        _activeChatGroupId != null &&
        _activeChatGroupId == groupId) {
      return true;
    }
    if (friendId != null &&
        friendId.isNotEmpty &&
        _activeChatFriendId != null &&
        _activeChatFriendId == friendId) {
      return true;
    }
    return false;
  }

  bool isNotificationShown(String id) => _shownNotificationIds.contains(id);

  Future<void> markAsShown(String id, {bool persist = true}) async {
    if (_shownNotificationIds.length > 500) {
      _shownNotificationIds.clear();
    }
    _shownNotificationIds.add(id);

    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _prefsKeyShownIds,
          _shownNotificationIds.take(200).toList(),
        );
      } catch (_) {}
    }
  }

  Future<void> showNotification(InAppNotificationItem item, {bool persistShown = true}) async {
    await ensureLoaded();

    // 1. Suppress notification if user is currently inside the same group or direct chat
    if (item.isGroup || (item.groupId != null && item.groupId!.isNotEmpty)) {
      if (isCurrentlyInChat(groupId: item.groupId)) {
        return;
      }
    } else if (item.type == 'text' ||
        item.type == 'chat' ||
        item.type == 'post_reply' ||
        item.type == 'reaction' ||
        item.type == 'message_reaction') {
      if (isCurrentlyInChat(friendId: item.sender.uid)) {
        return;
      }
    }

    if (_shownNotificationIds.contains(item.id)) {
      return;
    }
    if (_currentNotification?.id == item.id) {
      return;
    }
    await markAsShown(item.id, persist: persistShown);
    _currentNotification = item;
    notifyListeners();

    // Play notification sound for in-app banner
    playNotificationSound();
  }

  Future<void> playNotificationSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/meme_sound.mp3'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('InAppNotificationService play sound error: $e');
    }
  }

  void dismiss() {
    if (_currentNotification != null) {
      _currentNotification = null;
      notifyListeners();
    }
  }

  void clearHistory() {
    _currentNotification = null;
    _activeChatFriendId = null;
    _activeChatGroupId = null;
    notifyListeners();
  }
}


