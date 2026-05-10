import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String name;
  final String? nameEn;
  final int iconCodePoint;
  final String colorHex;
  final double limitAmount;
  final double spentAmount;
  final bool isDefault;
  final DateTime createdAt;
  final String period;
  final String budgetType;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.name,
    this.nameEn,
    required this.iconCodePoint,
    required this.colorHex,
    required this.limitAmount,
    required this.spentAmount,
    required this.isDefault,
    required this.createdAt,
    required this.period,
    required this.budgetType,
  });

  String get category => name;

  double get progress {
    if (limitAmount <= 0) return 0;
    return (spentAmount / limitAmount).clamp(0.0, 1.0).toDouble();
  }

  bool get isOverLimit {
    if (limitAmount <= 0) return false;
    return spentAmount > limitAmount;
  }

  double get remainingAmount {
    if (limitAmount <= 0) return 0;
    return limitAmount - spentAmount;
  }

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    return BudgetModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      name: (map['name'] ?? map['category'] ?? '').toString(),
      nameEn: map['nameEn']?.toString(),
      iconCodePoint: map['iconCodePoint'] is num
          ? (map['iconCodePoint'] as num).toInt()
          : 0xe57f,
      colorHex: (map['colorHex'] ?? '#79AFFF').toString(),
      limitAmount: map['limitAmount'] is num
          ? (map['limitAmount'] as num).toDouble()
          : 0,
      spentAmount: map['spentAmount'] is num
          ? (map['spentAmount'] as num).toDouble()
          : 0,
      isDefault: map['isDefault'] == true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      period: map['period']?.toString() ?? 'monthly',
      budgetType: map['budgetType']?.toString() ?? 'total',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'nameEn': nameEn,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'period': period,
      'budgetType': budgetType,
    };
  }
}