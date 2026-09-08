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
  final bool isDeleted;
  final bool isOnline;
  final DateTime? lastSeen;
  final String chatBubbleTheme;
  final String cameraTheme;
  final bool showActiveStatus;
  final String activeStatusMode;
  final String? userNote;
  final DateTime? userNoteCreatedAt;

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
    this.isDeleted = false,
    this.isOnline = false,
    this.lastSeen,
    this.chatBubbleTheme = 'default',
    this.cameraTheme = 'classic_dark',
    this.showActiveStatus = true,
    this.activeStatusMode = 'friends',
    this.userNote,
    this.userNoteCreatedAt,
  });

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
      isDeleted: map['isDeleted'] == true,
      isOnline: map['isOnline'] == true,
      lastSeen: _parseDateTime(map['lastSeen']),
      chatBubbleTheme: map['chatBubbleTheme'] ?? 'default',
      cameraTheme: map['cameraTheme'] ?? 'classic_dark',
      showActiveStatus: map['showActiveStatus'] != false,
      activeStatusMode: (map['activeStatusMode'] as String?) ??
          (map['showActiveStatus'] == false ? 'none' : 'friends'),
      userNote: map['userNote'] as String?,
      userNoteCreatedAt: _parseDateTime(map['userNoteCreatedAt']),
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
      'isDeleted': isDeleted,
      'isOnline': isOnline,
      'showActiveStatus': showActiveStatus,
      'activeStatusMode': activeStatusMode,
      if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
      if (chatBubbleTheme.isNotEmpty) 'chatBubbleTheme': chatBubbleTheme,
      if (cameraTheme.isNotEmpty) 'cameraTheme': cameraTheme,
      if (userNote != null) 'userNote': userNote,
      if (userNoteCreatedAt != null)
        'userNoteCreatedAt': Timestamp.fromDate(userNoteCreatedAt!),
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
    bool? isDeleted,
    bool? isOnline,
    DateTime? lastSeen,
    String? chatBubbleTheme,
    String? cameraTheme,
    bool? showActiveStatus,
    String? activeStatusMode,
    String? userNote,
    DateTime? userNoteCreatedAt,
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
      isDeleted: isDeleted ?? this.isDeleted,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      chatBubbleTheme: chatBubbleTheme ?? this.chatBubbleTheme,
      cameraTheme: cameraTheme ?? this.cameraTheme,
      showActiveStatus: showActiveStatus ?? this.showActiveStatus,
      activeStatusMode: activeStatusMode ?? this.activeStatusMode,
      userNote: userNote ?? this.userNote,
      userNoteCreatedAt: userNoteCreatedAt ?? this.userNoteCreatedAt,
    );
  }
}