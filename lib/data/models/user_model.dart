import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String avatarUrl;
  final String currency;
  final String language;
  final String themeMode;
  final int currentStreak;
  final int bestStreak;
  final DateTime createdAt;
  final DateTime lastActiveDate;
  final String avatarFrame;
  final String widgetFrame;
  final bool isDeleted;
  final bool isOnline;
  final DateTime? lastSeen;
  final String chatBubbleTheme;
  final String cameraTheme;
  final bool showActiveStatus;
  final String activeStatusMode;
  final bool hapticFeedback;
  final String? userNote;
  final DateTime? userNoteCreatedAt;
  final List<int> unlockedMilestones;
  final DateTime? dateOfBirth;

  const UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.currency,
    required this.language,
    required this.themeMode,
    required this.currentStreak,
    required this.bestStreak,
    required this.createdAt,
    required this.lastActiveDate,
    this.avatarFrame = 'plain',
    this.widgetFrame = 'none',
    this.isDeleted = false,
    this.isOnline = false,
    this.lastSeen,
    this.chatBubbleTheme = 'default',
    this.cameraTheme = 'classic_dark',
    this.showActiveStatus = true,
    this.activeStatusMode = 'friends',
    this.hapticFeedback = true,
    this.userNote,
    this.userNoteCreatedAt,
    this.unlockedMilestones = const [],
    this.dateOfBirth,
  });

  bool get isBirthdayToday {
    if (dateOfBirth == null) return false;
    final now = DateTime.now();
    return now.month == dateOfBirth!.month && now.day == dateOfBirth!.day;
  }

  bool get hasActiveNote {
    if (userNote == null || userNote!.trim().isEmpty) return false;
    if (userNoteCreatedAt == null) return true;
    final diff = DateTime.now().difference(userNoteCreatedAt!);
    return diff.inSeconds >= 0 && diff.inSeconds < 86400;
  }

  bool get isCurrentlyOnline {
    if (isDeleted) return false;
    if (!showActiveStatus) return false;
    if (activeStatusMode == 'none') return false;
    if (!isOnline) return false;
    final now = DateTime.now();
    final seen = lastSeen ?? lastActiveDate;
    return now.difference(seen).inMinutes < 3;
  }

  /// Kiểm tra xem người xem có được phép thấy trạng thái hoạt động (online / lần hoạt động gần nhất) của user này không:
  /// - Nếu user bị xoá -> false
  /// - Nếu user tắt trạng thái hoạt động -> false
  /// - Nếu user để chế độ 'none' -> false
  /// - Nếu user để 'public' -> true (ai cũng thấy)
  /// - Nếu user để 'friends' -> chỉ thấy nếu hai người là bạn bè (isFriend == true)
  bool isPresenceVisibleTo({required bool isFriend}) {
    if (isDeleted) return false;
    if (!showActiveStatus) return false;
    if (activeStatusMode == 'none') return false;
    if (activeStatusMode == 'public') return true;
    if (activeStatusMode == 'friends') return isFriend;
    return false;
  }

  /// Kiểm tra xem người xem có được phép thấy trạng thái online (đang hoạt động / chấm xanh) của user này không:
  /// Phải đang online thực tế (isCurrentlyOnline) VÀ có quyền xem trạng thái (isPresenceVisibleTo).
  bool isOnlineVisibleTo({required bool isFriend}) {
    return isCurrentlyOnline && isPresenceVisibleTo(isFriend: isFriend);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
      if (seconds is num) {
        final nanoInt = nanoseconds is num ? nanoseconds.toInt() : 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds.toInt() * 1000 + (nanoInt ~/ 1000000),
        );
      }
    }
    return null;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      currency: map['currency'] ?? 'VND',
      language: map['language'] ?? 'vi',
      themeMode: map['themeMode'] ?? 'system',
      currentStreak: map['currentStreak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastActiveDate: _parseDateTime(map['lastActiveDate']) ?? DateTime.now(),
      avatarFrame: map['avatarFrame'] ?? 'plain',
      widgetFrame: map['widgetFrame'] ?? 'none',
      isDeleted: map['isDeleted'] == true,
      isOnline: map['isOnline'] == true,
      lastSeen: _parseDateTime(map['lastSeen']),
      chatBubbleTheme: map['chatBubbleTheme'] ?? 'default',
      cameraTheme: map['cameraTheme'] ?? 'classic_dark',
      showActiveStatus: map['showActiveStatus'] != false,
      activeStatusMode: (map['activeStatusMode'] as String?) ??
          (map['showActiveStatus'] == false ? 'none' : 'friends'),
      hapticFeedback: map['hapticFeedback'] != false,
      userNote: map['userNote'] as String?,
      userNoteCreatedAt: _parseDateTime(map['userNoteCreatedAt']),
      unlockedMilestones: (map['unlockedMilestones'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      dateOfBirth: _parseDateTime(map['dateOfBirth'] ?? map['birthday']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'currency': currency,
      'language': language,
      'themeMode': themeMode,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveDate': Timestamp.fromDate(lastActiveDate),
      'avatarFrame': avatarFrame,
      'widgetFrame': widgetFrame,
      'isDeleted': isDeleted,
      'isOnline': isOnline,
      'showActiveStatus': showActiveStatus,
      'activeStatusMode': activeStatusMode,
      'hapticFeedback': hapticFeedback,
      if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
      if (chatBubbleTheme.isNotEmpty) 'chatBubbleTheme': chatBubbleTheme,
      if (cameraTheme.isNotEmpty) 'cameraTheme': cameraTheme,
      if (userNote != null) 'userNote': userNote,
      if (userNoteCreatedAt != null)
        'userNoteCreatedAt': Timestamp.fromDate(userNoteCreatedAt!),
      if (unlockedMilestones.isNotEmpty) 'unlockedMilestones': unlockedMilestones,
      if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    String? currency,
    String? language,
    String? themeMode,
    int? currentStreak,
    int? bestStreak,
    DateTime? createdAt,
    DateTime? lastActiveDate,
    String? avatarFrame,
    String? widgetFrame,
    bool? isDeleted,
    bool? isOnline,
    DateTime? lastSeen,
    String? chatBubbleTheme,
    String? cameraTheme,
    bool? showActiveStatus,
    String? activeStatusMode,
    bool? hapticFeedback,
    String? userNote,
    DateTime? userNoteCreatedAt,
    List<int>? unlockedMilestones,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      avatarFrame: avatarFrame ?? this.avatarFrame,
      widgetFrame: widgetFrame ?? this.widgetFrame,
      isDeleted: isDeleted ?? this.isDeleted,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      chatBubbleTheme: chatBubbleTheme ?? this.chatBubbleTheme,
      cameraTheme: cameraTheme ?? this.cameraTheme,
      showActiveStatus: showActiveStatus ?? this.showActiveStatus,
      activeStatusMode: activeStatusMode ?? this.activeStatusMode,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      userNote: userNote ?? this.userNote,
      userNoteCreatedAt: userNoteCreatedAt ?? this.userNoteCreatedAt,
      unlockedMilestones: unlockedMilestones ?? this.unlockedMilestones,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
    );
  }
}