import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../routes/app_routes.dart';
import '../routes/route_names.dart';
import '../constants/genz_reminder_quotes.dart';
import 'in_app_notification_service.dart';
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
  static const String chatChannelId = 'chat_messages_channel_v3';
  static const String friendChannelId = 'friend_requests_channel_v3';
  static const String reminderChannelId = 'expense_reminders_channel_v3';
  static const String customSoundName = 'meme_sound';

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

      // 3. Setup Android Channels with custom sound
      const customSound = RawResourceAndroidNotificationSound(customSoundName);

      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        chatChannelId,
        'Tin nhắn & Cảm xúc',
        description: 'Thông báo khi có tin nhắn mới hoặc phản hồi cảm xúc',
        importance: Importance.max,
        playSound: true,
        sound: customSound,
        enableVibration: true,
      );

      const AndroidNotificationChannel friendChannel = AndroidNotificationChannel(
        friendChannelId,
        'Lời mời & Bạn bè',
        description: 'Thông báo lời mời kết bạn và tương tác bạn bè',
        importance: Importance.high,
        playSound: true,
        sound: customSound,
        enableVibration: true,
      );

      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        reminderChannelId,
        'Nhắc nhở chi tiêu & Chuỗi',
        description: 'Nhắc nhở ghi chép chi tiêu và duy trì chuỗi hàng ngày',
        importance: Importance.high,
        playSound: true,
        sound: customSound,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Clean up legacy channel IDs to ensure custom sound triggers immediately
        await androidPlugin.deleteNotificationChannel(channelId: 'chat_messages_channel');
        await androidPlugin.deleteNotificationChannel(channelId: 'chat_messages_channel_v2');
        await androidPlugin.deleteNotificationChannel(channelId: 'friend_requests_channel');
        await androidPlugin.deleteNotificationChannel(channelId: 'friend_requests_channel_v2');
        await androidPlugin.deleteNotificationChannel(channelId: 'expense_reminders_channel');
        await androidPlugin.deleteNotificationChannel(channelId: 'expense_reminders_channel_v2');

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

      // 7. Schedule Default Daily Expense Reminder & Rewind Reminders
      await scheduleDailyExpenseReminder();
      await scheduleRewindReminders();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Sync FCM Token for logged-in user and schedule personalized reminders
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

      // Schedule reminders for this user
      await scheduleGenZDailyReminders(checkSpentTodayForUid: uid);
      await scheduleRewindReminders(checkUid: uid);
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
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(customSoundName),
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'meme_sound.mp3',
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

  /// Handle incoming foreground FCM message:
  /// - If user is actively inside the app (resumed): display in-app banner ONLY and suppress external notification.
  /// - If app is in background / paused: show local heads-up notification.
  void _handleForegroundMessage(RemoteMessage message) {
    final bool isAppResumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    final notification = message.notification;
    final data = message.data;

    final type = data['type']?.toString() ?? 'text';
    final senderUid = data['senderUid']?.toString() ?? 'system';
    final senderName = data['senderName']?.toString() ?? notification?.title ?? 'Meme';
    final senderAvatar = data['senderAvatar']?.toString() ?? '';
    final msgText = notification?.body ?? data['body']?.toString() ?? '';
    final isGroup = type == 'group_chat' || type == 'group_transaction';
    final groupId = data['groupId']?.toString();

    final bool isChatOrSocialType = type == 'text' ||
        type == 'chat' ||
        type == 'group_chat' ||
        type == 'reaction' ||
        type == 'message_reaction' ||
        type == 'friend_request' ||
        type == 'friend_accepted' ||
        type == 'mention';

    // Suppress notification completely if user is actively in this chat screen
    if (InAppNotificationService.instance.isCurrentlyInChat(
      friendId: senderUid,
      groupId: groupId,
    )) {
      return;
    }

    if (isAppResumed) {
      // Chat, mention, and friend notifications are already delivered in real-time
      // by ChatController (which fetches the full user profile including avatarFrame and verifies mute settings).
      if (isChatOrSocialType && type != 'group_transaction') {
        return;
      }

      // Show in-app banner for general system announcements or other custom types
      InAppNotificationService.instance.showNotification(
        InAppNotificationItem(
          id: 'fcm_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}',
          sender: UserModel(
            uid: senderUid,
            name: senderName,
            username: senderName,
            email: '',
            avatarUrl: senderAvatar,
            currency: 'VND',
            language: 'vi',
            themeMode: 'system',
            currentStreak: 0,
            bestStreak: 0,
            createdAt: DateTime.now(),
            lastActiveDate: DateTime.now(),
          ),
          messageText: msgText,
          type: type,
          isGroup: isGroup,
          groupId: groupId,
          groupName: data['groupName']?.toString(),
          postId: data['postId']?.toString() ?? data['period']?.toString(),
        ),
      );
      return;
    }

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

  /// Check if a user has already recorded at least one transaction/expense today
  Future<bool> hasSpentToday(String uid) async {
    if (uid.isEmpty) return false;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user spent today: $e');
      return false;
    }
  }

  /// Triggered whenever user records a new expense today
  /// Cancels today's 20:00 reminder immediately and re-schedules upcoming days
  Future<void> onExpenseRecordedToday({String? uid}) async {
    try {
      // Cancel today's slot (ID 9000)
      await _localNotifications.cancel(id: 9000);
      debugPrint('NotificationService: Expense recorded today! Cancelled today\'s 20:00 reminder.');
      // Re-schedule for next days
      await scheduleGenZDailyReminders(hour: 20, minute: 0, checkSpentTodayForUid: uid);
    } catch (e) {
      debugPrint('Error in onExpenseRecordedToday: $e');
    }
  }

  /// Schedule Gen Z Daily Expense & Streak Reminders (e.g. 20:00 every day)
  Future<void> scheduleDailyExpenseReminder({
    int hour = 20,
    int minute = 0,
    String? checkSpentTodayForUid,
  }) async {
    await scheduleGenZDailyReminders(
      hour: hour,
      minute: minute,
      checkSpentTodayForUid: checkSpentTodayForUid,
    );
  }

  /// Schedule rotating Gen Z quotes for the upcoming 14 days
  /// Only schedules today if user has NOT yet spent today and 20:00 has not passed
  Future<void> scheduleGenZDailyReminders({
    int hour = 20,
    int minute = 0,
    String? checkSpentTodayForUid,
    String? language,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);

      // Cancel legacy/previous reminder slots (IDs 9000 to 9020 and 9991)
      await _localNotifications.cancel(id: 9991);
      for (int i = 0; i < 20; i++) {
        await _localNotifications.cancel(id: 9000 + i);
      }

      bool alreadySpentToday = false;
      String userLanguage = language ?? 'vi';

      if (checkSpentTodayForUid != null && checkSpentTodayForUid.isNotEmpty) {
        alreadySpentToday = await hasSpentToday(checkSpentTodayForUid);
        if (language == null) {
          try {
            final userDoc = await _db.collection('users').doc(checkSpentTodayForUid).get();
            final lang = userDoc.data()?['language']?.toString();
            if (lang != null && lang.isNotEmpty) {
              userLanguage = lang;
            }
          } catch (_) {}
        }
      }

      final isEn = userLanguage.toLowerCase() == 'en';
      final channelName = isEn ? 'Expense & Streak Reminders' : 'Nhắc nhở chi tiêu & Chuỗi';

      // Schedule distinct rotating Gen Z quotes for the next 14 days
      for (int i = 0; i < 14; i++) {
        final targetDate = now.add(Duration(days: i));
        var scheduledDate = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );

        // For today (i == 0): skip if already spent today or if 20:00 has passed
        if (i == 0) {
          if (alreadySpentToday || scheduledDate.isBefore(now)) {
            continue;
          }
        }

        final quote = GenZReminderQuotes.getQuoteForDay(
          DateTime(targetDate.year, targetDate.month, targetDate.day),
          language: userLanguage,
        );

        await _localNotifications.zonedSchedule(
          id: 9000 + i,
          title: quote.title,
          body: quote.body,
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              reminderChannelId,
              channelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound(customSoundName),
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'meme_sound.mp3',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: jsonEncode({'type': 'daily_reminder'}),
        );
      }
      debugPrint('Gen Z Daily reminders scheduled at $hour:$minute in $userLanguage (alreadySpentToday: $alreadySpentToday).');
    } catch (e) {
      debugPrint('Error scheduling Gen Z daily reminders: $e');
    }
  }

  /// Schedule Weekend (Sunday 20:30) and Month-End (Last day of month 20:30) Rewind Reminders
  Future<void> scheduleRewindReminders({
    String? checkUid,
    String? language,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);

      // Cancel previous Rewind slots (IDs 9100 to 9110 for weekly, 9200 to 9210 for monthly)
      for (int i = 0; i < 10; i++) {
        await _localNotifications.cancel(id: 9100 + i);
        await _localNotifications.cancel(id: 9200 + i);
      }

      String userLanguage = language ?? 'vi';
      if (checkUid != null && checkUid.isNotEmpty && language == null) {
        try {
          final userDoc = await _db.collection('users').doc(checkUid).get();
          final lang = userDoc.data()?['language']?.toString();
          if (lang != null && lang.isNotEmpty) {
            userLanguage = lang;
          }
        } catch (_) {}
      }

      final isEn = userLanguage.toLowerCase() == 'en';
      final channelName = isEn ? 'Rewind & Highlights' : 'Xem lại & Tổng kết';

      // 1. Schedule next 4 weekends (Sundays at 20:30)
      for (int w = 0; w < 4; w++) {
        int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
        if (daysUntilSunday == 0) {
          final todaySlot = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            20,
            30,
          );
          if (todaySlot.isBefore(now)) {
            daysUntilSunday = 7;
          }
        }
        final targetDate = now.add(Duration(days: daysUntilSunday + (w * 7)));
        final scheduledDate = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          20,
          30,
        );

        final title = isEn
            ? 'Your Weekly Rewind is ready! 🎬✨'
            : 'Xem lại một tuần vừa qua! 🎬✨';
        final body = isEn
            ? 'Let\'s rewind all your expense moments & streaks this week in Rewind mode 👀🍿'
            : 'Cùng tua lại toàn bộ khoảnh khắc chi tiêu & streak tuần này của bạn trong Rewind nè 👀🍿';

        await _localNotifications.zonedSchedule(
          id: 9100 + w,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              reminderChannelId,
              channelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound(customSoundName),
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'meme_sound.mp3',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: jsonEncode({'type': 'rewind', 'period': 'thisWeek'}),
        );
      }

      // 2. Schedule next 3 month-ends (Last day of month at 20:30)
      for (int m = 0; m < 3; m++) {
        final targetMonth = now.month + m;
        final targetYear = now.year + (targetMonth - 1) ~/ 12;
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;

        var scheduledDate = tz.TZDateTime(
          tz.local,
          targetYear,
          normalizedMonth,
          lastDay,
          20,
          30,
        );

        if (scheduledDate.isBefore(now)) {
          continue;
        }

        final title = isEn
            ? 'Your Monthly Rewind is ready! 🏆📊'
            : 'Tổng kết tháng này cùng Meme! 🏆📊';
        final body = isEn
            ? 'How was your spending and saving this month? Open Rewind to watch your highlight reel 🎉💸'
            : 'Tháng này bạn đã chi tiêu và tiết kiệm thế nào? Mở Rewind xem lại toàn bộ thước phim nhé 🎉💸';

        await _localNotifications.zonedSchedule(
          id: 9200 + m,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              reminderChannelId,
              channelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound(customSoundName),
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'meme_sound.mp3',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: jsonEncode({'type': 'rewind', 'period': 'thisMonth'}),
        );
      }

      debugPrint('Rewind reminders scheduled for upcoming weekends & month-ends in $userLanguage.');
    } catch (e) {
      debugPrint('Error scheduling Rewind reminders: $e');
    }
  }

  /// If user is actively inside the app on weekend or month-end, display the in-app rewind alert
  Future<void> checkAndShowInAppRewindNotification({String? language}) async {
    final bool isAppResumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!isAppResumed) return;

    final now = DateTime.now();
    final isEn = (language ?? 'vi').toLowerCase() == 'en';

    // Month-end check: Last 2 days of month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final isMonthEnd = (lastDayOfMonth - now.day) <= 1;

    // Weekend check: Sunday or Saturday after 18:00
    final isWeekend = now.weekday == DateTime.sunday ||
        (now.weekday == DateTime.saturday && now.hour >= 18);

    await InAppNotificationService.instance.ensureLoaded();

    if (isMonthEnd) {
      final notifKey = 'in_app_rewind_month_${now.year}_${now.month}';
      if (!InAppNotificationService.instance.isNotificationShown(notifKey)) {
        await InAppNotificationService.instance.showNotification(
          InAppNotificationItem(
            id: notifKey,
            sender: UserModel(
              uid: 'system',
              name: 'Meme Rewind',
              username: 'Rewind',
              email: '',
              avatarUrl: '',
              currency: 'VND',
              language: language ?? 'vi',
              themeMode: 'system',
              currentStreak: 0,
              bestStreak: 0,
              createdAt: DateTime.now(),
              lastActiveDate: DateTime.now(),
            ),
            messageText: isEn
                ? 'Your Monthly Rewind is ready! Tap to watch your highlights 🎉💸'
                : 'Tổng kết tháng này đã sẵn sàng! Chạm để xem lại thước phim nhé 🎉💸',
            type: 'rewind',
            postId: 'thisMonth',
          ),
          persistShown: true,
        );
      }
    } else if (isWeekend) {
      final saturday = now.weekday == DateTime.sunday
          ? now.subtract(const Duration(days: 1))
          : now;
      final notifKey =
          'in_app_rewind_weekend_${saturday.year}_${saturday.month}_${saturday.day}';

      if (!InAppNotificationService.instance.isNotificationShown(notifKey)) {
        await InAppNotificationService.instance.showNotification(
          InAppNotificationItem(
            id: notifKey,
            sender: UserModel(
              uid: 'system',
              name: 'Meme Rewind',
              username: 'Rewind',
              email: '',
              avatarUrl: '',
              currency: 'VND',
              language: language ?? 'vi',
              themeMode: 'system',
              currentStreak: 0,
              bestStreak: 0,
              createdAt: DateTime.now(),
              lastActiveDate: DateTime.now(),
            ),
            messageText: isEn
                ? 'Let\'s rewind your weekly spending & streak highlights! 🎬🍿'
                : 'Cùng tua lại toàn bộ chi tiêu & chuỗi streak tuần này nhé! 🎬🍿',
            type: 'rewind',
            postId: 'thisWeek',
          ),
          persistShown: true,
        );
      }
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
    if (data.isEmpty) return;

    // Await briefly in case app was just launched and navigator state is mounting
    if (AppRoutes.navigatorKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final nav = AppRoutes.navigatorKey.currentState;
    if (nav == null) {
      debugPrint('Notification payload handling failed: Navigator not ready');
      return;
    }

    final type = data['type']?.toString();

    if (type == 'group_chat' || type == 'group_transaction') {
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
    } else if (type == 'chat' || type == 'chat_message' || type == 'note_reaction') {
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
    } else if (type == 'friend_accepted') {
      nav.pushNamed(RouteNames.friends);
    } else if (type == 'daily_reminder') {
      nav.pushNamed(RouteNames.addTransaction);
    } else if (type == 'rewind') {
      final period = data['period']?.toString() ?? 'thisWeek';
      nav.pushNamed(
        RouteNames.rewind,
        arguments: {'period': period},
      );
    } else if (type == 'mention' ||
        type == 'post_reaction' ||
        type == 'new_expense' ||
        type == 'feed_moment' ||
        type == 'expense_post') {
      final postId = data['postId']?.toString();
      if (postId != null && postId.isNotEmpty) {
        final navContext = AppRoutes.navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
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
