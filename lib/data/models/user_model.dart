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
  final bool isDeleted;

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
    this.isDeleted = false,
  });

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
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveDate:
      (map['lastActiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: map['isDeleted'] == true,
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
      'isDeleted': isDeleted,
    };
  }
}