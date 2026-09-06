import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../routes/app_routes.dart';
import '../routes/route_names.dart';
import '../../data/models/user_model.dart';
import '../../features/feed/controllers/feed_controller.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Top-level background handler for FCM messages
  debugPrint('FCM Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isInitialized = false;

  // Android Notification Channels
  static const String chatChannelId = 'chat_messages_channel';
  static const String friendChannelId = 'friend_requests_channel';
  static const String reminderChannelId = 'expense_reminders_channel';

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Initialize timezone for scheduled reminders
      tz.initializeTimeZones();

      // 2. Request Notification Permission
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // 3. Setup Android Channels
      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        chatChannelId,
        'Tin nhắn & Cảm xúc',
        description: 'Thông báo khi có tin nhắn mới hoặc phản hồi cảm xúc',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel friendChannel = AndroidNotificationChannel(
        friendChannelId,
        'Lời mời & Bạn bè',
        description: 'Thông báo lời mời kết bạn và tương tác bạn bè',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        reminderChannelId,
        'Nhắc nhở chi tiêu & Chuỗi',
        description: 'Nhắc nhở ghi chép chi tiêu và duy trì chuỗi hàng ngày',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(chatChannel);
        await androidPlugin.createNotificationChannel(friendChannel);
        await androidPlugin.createNotificationChannel(reminderChannel);
      }

      // 4. Initialize Local Notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 5. Setup Foreground FCM Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // 6. Handle notification click when app opens from background / terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationPayload(message.data);
      });

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationPayload(initialMessage.data);
      }

      // 7. Schedule Default Daily Expense Reminder
      await scheduleDailyExpenseReminder();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Sync FCM Token for logged-in user
  Future<void> syncTokenForUser(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(uid, token);
      }

      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(uid, newToken);
      });
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmToken': token,
      });
    } catch (e) {
      debugPrint('Error saving FCM token to firestore: $e');
    }
  }

  /// Remove FCM Token on Logout
  Future<void> removeTokenForUser(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Display a local push notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String channelId = chatChannelId,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelId == chatChannelId
          ? 'Tin nhắn & Cảm xúc'
          : (channelId == friendChannelId
              ? 'Lời mời & Bạn bè'
              : 'Nhắc nhở chi tiêu & Chuỗi'),
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Handle incoming foreground FCM message by showing a local heads-up notification ONLY if app is in background
  void _handleForegroundMessage(RemoteMessage message) {
    final bool isAppResumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (isAppResumed) {
      // In-app notifications are handled by InAppNotificationService inside the app
      return;
    }

    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Meme';
    final body = notification?.body ?? data['body'] ?? '';
    final channel = data['channelId'] ?? chatChannelId;

    showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      channelId: channel,
      payload: jsonEncode(data),
    );
  }

  /// Schedule Daily Expense & Streak Reminder (e.g. 20:00 every day)
  Future<void> scheduleDailyExpenseReminder({
    int hour = 20,
    int minute = 0,
  }) async {
    try {
      const int reminderId = 9991;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _localNotifications.zonedSchedule(
        id: reminderId,
        title: 'Duy trì chuỗi chi tiêu 🔥',
        body: 'Đừng quên ghi chép chi tiêu hôm nay để không bị đứt chuỗi bạn nhé!',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannelId,
            'Nhắc nhở chi tiêu & Chuỗi',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode({'type': 'daily_reminder'}),
      );
      debugPrint('Daily reminder scheduled for $hour:$minute every day.');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  /// Handle notification tap action
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _handleNotificationPayload(data);
      } catch (e) {
        debugPrint('Error decoding notification payload: $e');
      }
    }
  }

  void _handleNotificationPayload(Map<String, dynamic> data) async {
    final nav = AppRoutes.navigatorKey.currentState;
    if (nav == null) return;

    final type = data['type']?.toString();

    if (type == 'group_chat') {
      final groupId = data['groupId']?.toString();
      final groupName = data['groupName']?.toString() ?? 'Nhóm';
      if (groupId != null && groupId.isNotEmpty) {
        nav.pushNamed(
          RouteNames.groupChatConversation,
          arguments: {
            'groupId': groupId,
            'groupName': groupName,
          },
        );
      }
    } else if (type == 'chat' || type == 'chat_message') {
      final friendUid = data['senderUid']?.toString();
      final friendName = data['senderName']?.toString() ?? 'Bạn bè';
      final friendAvatar = data['senderAvatar']?.toString() ?? '';

      if (friendUid != null && friendUid.isNotEmpty) {
        final friend = UserModel(
          uid: friendUid,
          name: friendName,
          username: friendName,
          email: '',
          avatarUrl: friendAvatar,
          currency: 'VND',
          language: 'vi',
          themeMode: 'system',
          currentStreak: 0,
          bestStreak: 0,
          createdAt: DateTime.now(),
          lastActiveDate: DateTime.now(),
        );

        nav.pushNamed(
          RouteNames.chatConversation,
          arguments: {'friend': friend},
        );
      }
    } else if (type == 'friend_request') {
      nav.pushNamed(RouteNames.friendRequests);
    } else if (type == 'daily_reminder') {
      nav.pushNamed(RouteNames.addTransaction);
    } else if (type == 'mention') {
      final postId = data['postId']?.toString();
      if (postId != null && postId.isNotEmpty) {
        final navContext = AppRoutes.navigatorKey.currentContext;
        if (navContext != null) {
          navContext.read<FeedController>().setTargetPostId(postId);
        }
      }
      nav.pushNamedAndRemoveUntil(
        RouteNames.mainShell,
        (route) => false,
        arguments: {
          'initialIndex': 2,
          'targetPostId': postId,
        },
      );
    }
  }
}
