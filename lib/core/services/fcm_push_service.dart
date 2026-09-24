import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmPushService {
  static final FcmPushService instance = FcmPushService._();
  FcmPushService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Project ID in Firebase
  static const String projectId = 'finnsocial-48ed5';

  // OAuth2 Token Cache
  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Service Account JSON credentials for direct FCM HTTP v1 dispatch
  Map<String, dynamic>? _serviceAccountCredentials;

  /// Initialize and load FCM Service Account from assets
  Future<void> init() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/fcm_service_account.json');
      if (jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        setServiceAccountCredentials(data);
        debugPrint('FcmPushService: Loaded service account credentials successfully.');
      }
    } catch (e) {
      debugPrint('FcmPushService init: Could not load assets/fcm_service_account.json: $e');
    }
  }

  void setServiceAccountCredentials(Map<String, dynamic> credentials) {
    _serviceAccountCredentials = credentials;
    _cachedAccessToken = null;
    _tokenExpiry = null;
  }

  /// Get fresh or cached OAuth2 access token
  Future<String?> _getAccessToken() async {
    if (_serviceAccountCredentials == null) {
      return null;
    }

    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _cachedAccessToken;
    }

    try {
      final accountCredentials =
          ServiceAccountCredentials.fromJson(_serviceAccountCredentials!);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(accountCredentials, scopes);
      _cachedAccessToken = client.credentials.accessToken.data;
      _tokenExpiry = client.credentials.accessToken.expiry;
      client.close();
      return _cachedAccessToken;
    } catch (e) {
      debugPrint('Error getting FCM OAuth2 access token: $e');
      return null;
    }
  }

  /// Send push notification to a single user by targetUserId with localization support
  Future<void> sendLocalizedNotificationToUser({
    required String targetUserId,
    required String titleVi,
    required String titleEn,
    required String bodyVi,
    required String bodyEn,
    required Map<String, dynamic> data,
    String channelId = 'chat_messages_channel_v3',
  }) async {
    try {
      final userDoc = await _db.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      if (userData == null) return;

      final isEn = (userData['language']?.toString().toLowerCase() == 'en');
      final title = isEn ? titleEn : titleVi;
      final body = isEn ? bodyEn : bodyVi;

      final rawTokens = userData['fcmTokens'];
      final List<String> tokens = [];
      if (rawTokens is List) {
        for (final t in rawTokens) {
          if (t is String && t.isNotEmpty) {
            tokens.add(t);
          }
        }
      }

      if (tokens.isEmpty) {
        final lastToken = userData['lastFcmToken'];
        if (lastToken is String && lastToken.isNotEmpty) {
          tokens.add(lastToken);
        }
      }

      if (tokens.isEmpty) return;

      for (final token in tokens) {
        await _sendToToken(
          token: token,
          title: title,
          body: body,
          data: data,
          channelId: channelId,
        );
      }
    } catch (e) {
      debugPrint('Error sending FCM to user $targetUserId: $e');
    }
  }

  /// Send push notification to a single user with default single title/body (backwards compatible)
  Future<void> sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String channelId = 'chat_messages_channel_v3',
  }) async {
    await sendLocalizedNotificationToUser(
      targetUserId: targetUserId,
      titleVi: title,
      titleEn: title,
      bodyVi: body,
      bodyEn: body,
      data: data,
      channelId: channelId,
    );
  }

  /// Send localized push notification to multiple users
  Future<void> sendLocalizedNotificationToUsers({
    required List<String> targetUserIds,
    required String titleVi,
    required String titleEn,
    required String bodyVi,
    required String bodyEn,
    required Map<String, dynamic> data,
    String channelId = 'chat_messages_channel_v3',
  }) async {
    for (final uid in targetUserIds) {
      await sendLocalizedNotificationToUser(
        targetUserId: uid,
        titleVi: titleVi,
        titleEn: titleEn,
        bodyVi: bodyVi,
        bodyEn: bodyEn,
        data: data,
        channelId: channelId,
      );
    }
  }

  /// Send push notification to multiple users (backwards compatible)
  Future<void> sendNotificationToUsers({
    required List<String> targetUserIds,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String channelId = 'chat_messages_channel_v3',
  }) async {
    for (final uid in targetUserIds) {
      await sendNotificationToUser(
        targetUserId: uid,
        title: title,
        body: body,
        data: data,
        channelId: channelId,
      );
    }
  }

  /// Send raw message to a specific FCM device token via FCM HTTP v1
  Future<bool> _sendToToken({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String channelId,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('FCM access token not available. Skipping push notification.');
        return false;
      }

      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final stringData = data.map((key, value) => MapEntry(key, value.toString()));
      stringData['channelId'] = channelId;

      final payload = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': stringData,
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': channelId,
              'sound': 'meme_sound',
              'default_sound': false,
              'default_vibrate_timings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'meme_sound.mp3',
                'badge': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM push sent successfully to token: ${token.substring(0, 10)}...');
        return true;
      } else {
        debugPrint('FCM push failed with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error dispatching FCM HTTP v1: $e');
      return false;
    }
  }

  // --- Convenience Helper Methods with Bilingual Support ---

  /// 1. Send Chat Notification
  Future<void> sendChatMessageNotification({
    required String senderId,
    required String receiverId,
    required String senderName,
    String? senderAvatar,
    required String messageText,
    String type = 'text',
    String? reactionEmoji,
  }) async {
    final bodyVi = _formatChatBodyVi(type, reactionEmoji, messageText);
    final bodyEn = _formatChatBodyEn(type, reactionEmoji, messageText);

    await sendLocalizedNotificationToUser(
      targetUserId: receiverId,
      titleVi: senderName,
      titleEn: senderName,
      bodyVi: bodyVi,
      bodyEn: bodyEn,
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'chat',
        'senderUid': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar ?? '',
      },
    );
  }

  String _formatChatBodyVi(String type, String? reactionEmoji, String text) {
    if (type == 'reaction') {
      return 'Đã thả cảm xúc: ${reactionEmoji ?? "❤️"}';
    } else if (type == 'post_reply') {
      return 'Đã phản hồi bài viết: "$text"';
    } else if (type == 'note_reply') {
      return 'Đã phản hồi ghi chú của bạn: ${text.isNotEmpty ? text : (reactionEmoji ?? "❤️")}';
    }
    return text.isNotEmpty ? text : 'Đã gửi một tin nhắn';
  }

  String _formatChatBodyEn(String type, String? reactionEmoji, String text) {
    if (type == 'reaction') {
      return 'Reacted: ${reactionEmoji ?? "❤️"}';
    } else if (type == 'post_reply') {
      return 'Replied to post: "$text"';
    } else if (type == 'note_reply') {
      return 'Replied to your note: ${text.isNotEmpty ? text : (reactionEmoji ?? "❤️")}';
    }
    return text.isNotEmpty ? text : 'Sent a message';
  }

  /// 2. Send Group Chat Notification
  Future<void> sendGroupChatMessageNotification({
    required String groupId,
    required String groupName,
    required String senderId,
    required String senderName,
    required String messageText,
    required List<String> memberIds,
    bool isSystem = false,
  }) async {
    final targetMembers = memberIds.where((id) => id != senderId).toList();
    if (targetMembers.isEmpty) return;

    final bodyVi = isSystem
        ? messageText
        : '$senderName: ${messageText.isNotEmpty ? messageText : "Đã gửi tin nhắn"}';
    final bodyEn = isSystem
        ? messageText
        : '$senderName: ${messageText.isNotEmpty ? messageText : "Sent a message"}';

    await sendLocalizedNotificationToUsers(
      targetUserIds: targetMembers,
      titleVi: groupName,
      titleEn: groupName,
      bodyVi: bodyVi,
      bodyEn: bodyEn,
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'group_chat',
        'groupId': groupId,
        'groupName': groupName,
      },
    );
  }

  /// 2b. Send Group Mention Notification (when user is @mentioned in group chat)
  Future<void> sendGroupMentionNotification({
    required String groupId,
    required String groupName,
    required String senderId,
    required String senderName,
    required String messageText,
    required String targetUserId,
  }) async {
    if (targetUserId.isEmpty || targetUserId == senderId) return;

    final bodyVi = '$senderName đã nhắc đến bạn: "$messageText"';
    final bodyEn = '$senderName mentioned you: "$messageText"';

    await sendLocalizedNotificationToUser(
      targetUserId: targetUserId,
      titleVi: groupName,
      titleEn: groupName,
      bodyVi: bodyVi,
      bodyEn: bodyEn,
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'group_chat',
        'groupId': groupId,
        'groupName': groupName,
        'isMention': 'true',
      },
    );
  }

  /// 3. Send Friend Request Notification
  Future<void> sendFriendRequestNotification({
    required String senderId,
    required String targetUserId,
    required String senderName,
  }) async {
    await sendLocalizedNotificationToUser(
      targetUserId: targetUserId,
      titleVi: 'Lời mời kết bạn mới 👋',
      titleEn: 'New friend request 👋',
      bodyVi: '$senderName vừa gửi cho bạn một lời mời kết bạn!',
      bodyEn: '$senderName sent you a friend request!',
      channelId: 'friend_requests_channel_v3',
      data: {
        'type': 'friend_request',
        'senderUid': senderId,
      },
    );
  }

  /// 4. Send Friend Accepted Notification
  Future<void> sendFriendAcceptedNotification({
    required String myUid,
    required String friendUid,
    required String myName,
  }) async {
    await sendLocalizedNotificationToUser(
      targetUserId: friendUid,
      titleVi: 'Kết bạn thành công 🎉',
      titleEn: 'Friend request accepted 🎉',
      bodyVi: '$myName đã chấp nhận lời mời kết bạn của bạn!',
      bodyEn: '$myName accepted your friend request!',
      channelId: 'friend_requests_channel_v3',
      data: {
        'type': 'friend_accepted',
        'senderUid': myUid,
      },
    );
  }

  /// 5. Send Post Reaction Notification
  Future<void> sendPostReactionNotification({
    required String postId,
    required String postOwnerId,
    required String reactorId,
    required String reactorName,
    String? reactorAvatar,
    required String emoji,
  }) async {
    if (postOwnerId.isEmpty || postOwnerId == reactorId) return;

    await sendLocalizedNotificationToUser(
      targetUserId: postOwnerId,
      titleVi: reactorName,
      titleEn: reactorName,
      bodyVi: '$reactorName đã thả cảm xúc $emoji lên bài viết của bạn',
      bodyEn: '$reactorName reacted $emoji to your post',
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'post_reaction',
        'postId': postId,
        'senderUid': reactorId,
      },
    );
  }

  /// 6. Send Status Note Reaction Notification
  Future<void> sendNoteReactionNotification({
    required String noteOwnerId,
    required String reactorId,
    required String reactorName,
    String? reactorAvatar,
    required String emoji,
  }) async {
    if (noteOwnerId.isEmpty || noteOwnerId == reactorId) return;

    await sendLocalizedNotificationToUser(
      targetUserId: noteOwnerId,
      titleVi: reactorName,
      titleEn: reactorName,
      bodyVi: '$reactorName đã thả cảm xúc $emoji lên ghi chú của bạn',
      bodyEn: '$reactorName reacted $emoji to your note',
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'note_reaction',
        'senderUid': reactorId,
      },
    );
  }

  /// 7. Send Mention Notification (@username in post)
  Future<void> sendMentionNotification({
    required String targetUserId,
    required String senderUid,
    required String senderName,
    String? senderAvatar,
    required String postId,
    String? caption,
  }) async {
    if (targetUserId.isEmpty || targetUserId == senderUid) return;

    final desc = (caption != null && caption.trim().isNotEmpty)
        ? ': "$caption"'
        : '';

    await sendLocalizedNotificationToUser(
      targetUserId: targetUserId,
      titleVi: senderName,
      titleEn: senderName,
      bodyVi: '$senderName đã nhắc đến bạn trong một bài viết$desc',
      bodyEn: '$senderName mentioned you in a post$desc',
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'mention',
        'postId': postId,
        'senderUid': senderUid,
      },
    );
  }

  /// 8. Send Group Fund Expense / Contribution Notification
  Future<void> sendGroupTransactionNotification({
    required String groupId,
    required String groupName,
    required String creatorUid,
    required String creatorName,
    required double amount,
    required String category,
    String? caption,
    required bool isGroupContribution,
    required List<String> memberIds,
    required String transactionId,
  }) async {
    final targetMembers = memberIds.where((id) => id != creatorUid).toList();
    if (targetMembers.isEmpty) return;

    final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    final desc = (caption != null && caption.isNotEmpty) ? caption : category;

    final isFund = isGroupContribution || category == 'Quỹ nhóm' || category == 'Group Fund';

    final titleVi = isFund ? '$groupName 💰' : '$groupName 💳';
    final titleEn = isFund ? '$groupName 💰' : '$groupName 💳';

    final bodyVi = isFund
        ? '$creatorName vừa nạp quỹ nhóm: +$formattedAmountđ ($desc)'
        : '$creatorName vừa chi tiêu nhóm: -$formattedAmountđ ($desc)';

    final bodyEn = isFund
        ? '$creatorName added to group fund: +$formattedAmountđ ($desc)'
        : '$creatorName spent from group fund: -$formattedAmountđ ($desc)';

    await sendLocalizedNotificationToUsers(
      targetUserIds: targetMembers,
      titleVi: titleVi,
      titleEn: titleEn,
      bodyVi: bodyVi,
      bodyEn: bodyEn,
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'group_transaction',
        'groupId': groupId,
        'groupName': groupName,
        'transactionId': transactionId,
        'senderUid': creatorUid,
        'senderName': creatorName,
        'title': titleVi,
        'body': bodyVi,
        'amount': amount.toString(),
        'isFund': isFund.toString(),
      },
    );
  }

  /// 9. Send Direct Message Reaction Notification
  Future<void> sendMessageReactionNotification({
    required String senderId,
    required String receiverId,
    required String senderName,
    String? senderAvatar,
    required String emoji,
    required String messageText,
  }) async {
    if (receiverId.isEmpty || receiverId == senderId) return;

    final preview = messageText.trim().isNotEmpty
        ? (messageText.length > 28 ? '${messageText.substring(0, 28)}...' : messageText)
        : '';
    final bodyVi = preview.isNotEmpty
        ? 'Đã bày tỏ cảm xúc $emoji về tin nhắn: "$preview"'
        : 'Đã bày tỏ cảm xúc $emoji về tin nhắn của bạn';
    final bodyEn = preview.isNotEmpty
        ? 'Reacted $emoji to: "$preview"'
        : 'Reacted $emoji to your message';

    await sendLocalizedNotificationToUser(
      targetUserId: receiverId,
      titleVi: senderName,
      titleEn: senderName,
      bodyVi: bodyVi,
      bodyEn: bodyEn,
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'chat',
        'senderUid': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar ?? '',
        'reactionEmoji': emoji,
      },
    );
  }

  /// 10. Send Group Message Reaction Notification
  Future<void> sendGroupMessageReactionNotification({
    required String groupId,
    required String groupName,
    required String senderId,
    required String targetUserId,
    required String senderName,
    required String emoji,
    required String messageText,
  }) async {
    if (targetUserId.isEmpty || targetUserId == senderId) return;

    final preview = messageText.trim().isNotEmpty
        ? (messageText.length > 28 ? '${messageText.substring(0, 28)}...' : messageText)
        : '';
    final bodyVi = preview.isNotEmpty
        ? '$senderName đã bày tỏ cảm xúc $emoji về tin nhắn của bạn: "$preview"'
        : '$senderName đã bày tỏ cảm xúc $emoji về tin nhắn của bạn trong nhóm';
    final bodyEn = preview.isNotEmpty
        ? '$senderName reacted $emoji to your message: "$preview"'
        : '$senderName reacted $emoji to your message';

    await sendLocalizedNotificationToUser(
      targetUserId: targetUserId,
      titleVi: groupName,
      titleEn: groupName,
      bodyVi: bodyVi,
      bodyEn: bodyEn,
      channelId: 'chat_messages_channel_v3',
      data: {
        'type': 'group_chat',
        'groupId': groupId,
        'groupName': groupName,
        'senderUid': senderId,
        'reactionEmoji': emoji,
      },
    );
  }
}

