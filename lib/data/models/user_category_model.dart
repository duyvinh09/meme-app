import 'package:cloud_firestore/cloud_firestore.dart';

class UserCategoryModel {
  final String id;
  final String userId;
  final String name;
  final String? nameEn;
  final String type;
  final int iconCodePoint;
  final String colorHex;
  final DateTime createdAt;

  const UserCategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.nameEn,
    required this.type,
    required this.iconCodePoint,
    required this.colorHex,
    required this.createdAt,
  });

  bool get isExpense => type == 'expense';

  factory UserCategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return UserCategoryModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      nameEn: map['nameEn']?.toString(),
      type: (map['type'] ?? 'expense').toString(),
      iconCodePoint: map['iconCodePoint'] is num
          ? (map['iconCodePoint'] as num).toInt()
          : 0xe57f,
      colorHex: (map['colorHex'] ?? '#79AFFF').toString(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'nameEn': nameEn,
      'type': type,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
