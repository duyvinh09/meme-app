import 'transaction_model.dart';

class FailedPostModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String category;
  final String caption;
  final String note;
  final String mediaPath;
  final String? thumbnailPath;
  final String mediaType; // 'image' | 'video' | 'none'
  final int? durationMs;
  final DateTime originalCreatedAt;
  final bool sharedToFeed;
  final String privacy;
  final List<String> closeFriendUids;
  final List<String> taggedUsernames;
  final String? groupId;
  final String? groupName;
  final List<String> groupMemberIds;
  final int? categoryIconCodePoint;
  final String? categoryColorHex;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final bool isGroupContribution;
  final bool isGroupExpense;
  final bool isFrontCamera;

  const FailedPostModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.caption,
    required this.note,
    required this.mediaPath,
    this.thumbnailPath,
    this.mediaType = 'image',
    this.durationMs,
    required this.originalCreatedAt,
    required this.sharedToFeed,
    required this.privacy,
    this.closeFriendUids = const [],
    this.taggedUsernames = const [],
    this.groupId,
    this.groupName,
    this.groupMemberIds = const [],
    this.categoryIconCodePoint,
    this.categoryColorHex,
    this.locationName = '',
    this.latitude,
    this.longitude,
    this.isGroupContribution = false,
    this.isGroupExpense = false,
    this.isFrontCamera = false,
  });

  bool get isVideo => mediaType == 'video';

  TransactionModel toTransactionModel() {
    final displayPath = (thumbnailPath != null && thumbnailPath!.isNotEmpty)
        ? thumbnailPath!
        : mediaPath;

    return TransactionModel(
      id: id,
      userId: userId,
      amount: amount,
      type: type,
      category: category,
      caption: caption,
      note: note,
      imageUrl: displayPath,
      mediaUrl: mediaPath,
      thumbnailUrl: displayPath,
      videoUrl: isVideo ? mediaPath : '',
      mediaType: mediaType,
      durationMs: durationMs,
      createdAt: originalCreatedAt,
      locationName: locationName,
      sharedToFeed: sharedToFeed,
      privacy: privacy,
      closeFriendUids: closeFriendUids,
      taggedUsernames: taggedUsernames,
      categoryIconCodePoint: categoryIconCodePoint,
      categoryColorHex: categoryColorHex,
      groupId: groupId,
      groupName: groupName,
      groupMemberIds: groupMemberIds,
      latitude: latitude,
      longitude: longitude,
      isGroupContribution: isGroupContribution,
      isGroupExpense: isGroupExpense,
      isFrontCamera: isFrontCamera,
      isFailed: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'caption': caption,
      'note': note,
      'mediaPath': mediaPath,
      'thumbnailPath': thumbnailPath,
      'mediaType': mediaType,
      'durationMs': durationMs,
      'originalCreatedAt': originalCreatedAt.toIso8601String(),
      'sharedToFeed': sharedToFeed,
      'privacy': privacy,
      'closeFriendUids': closeFriendUids,
      'taggedUsernames': taggedUsernames,
      'groupId': groupId,
      'groupName': groupName,
      'groupMemberIds': groupMemberIds,
      'categoryIconCodePoint': categoryIconCodePoint,
      'categoryColorHex': categoryColorHex,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'isGroupContribution': isGroupContribution,
      'isGroupExpense': isGroupExpense,
      'isFrontCamera': isFrontCamera,
    };
  }

  factory FailedPostModel.fromMap(Map<String, dynamic> map) {
    return FailedPostModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      type: map['type']?.toString() ?? 'expense',
      category: map['category']?.toString() ?? '',
      caption: map['caption']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      mediaPath: map['mediaPath']?.toString() ?? '',
      thumbnailPath: map['thumbnailPath']?.toString(),
      mediaType: map['mediaType']?.toString() ?? 'image',
      durationMs: (map['durationMs'] is num) ? (map['durationMs'] as num).toInt() : null,
      originalCreatedAt: map['originalCreatedAt'] != null
          ? (DateTime.tryParse(map['originalCreatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      sharedToFeed: map['sharedToFeed'] == true,
      privacy: map['privacy']?.toString() ?? 'friends',
      closeFriendUids: (map['closeFriendUids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      taggedUsernames: (map['taggedUsernames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      groupId: map['groupId']?.toString(),
      groupName: map['groupName']?.toString(),
      groupMemberIds: (map['groupMemberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      categoryIconCodePoint: (map['categoryIconCodePoint'] is num)
          ? (map['categoryIconCodePoint'] as num).toInt()
          : null,
      categoryColorHex: map['categoryColorHex']?.toString(),
      locationName: map['locationName']?.toString() ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : null,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : null,
      isGroupContribution: map['isGroupContribution'] == true,
      isGroupExpense: map['isGroupExpense'] == true,
      isFrontCamera: map['isFrontCamera'] == true,
    );
  }
}
