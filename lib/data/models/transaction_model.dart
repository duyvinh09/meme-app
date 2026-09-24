import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String category;
  final String caption;
  final String note;

  /// Field cũ, giữ nguyên để toàn bộ UI cũ không bị vỡ.
  /// Ảnh: imageUrl = link ảnh.
  /// Video: imageUrl sẽ dùng thumbnail về sau.
  final String imageUrl;

  /// Field mới, thêm nhẹ để hỗ trợ video sau này.
  /// Hiện tại nếu dữ liệu cũ không có thì mặc định là image/none.
  final String mediaType; // image | video | none
  final String mediaUrl; // ảnh: link ảnh, video: link video
  final String thumbnailUrl; // ảnh đại diện, nhất là cho video
  final String videoUrl; // link video nếu là video
  final int? durationMs;

  final DateTime createdAt;
  final String locationName;
  final bool sharedToFeed;
  final String privacy;
  final List<String> closeFriendUids;
  final List<String> taggedUsernames;
  final double? latitude;
  final double? longitude;

  final int? categoryIconCodePoint;
  final String? categoryColorHex;
  final String? groupId;
  final String? groupName;
  final List<String> groupMemberIds;
  final bool isGroupExpense;
  final bool isGroupContribution;
  final bool isFrontCamera;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required String type,
    required this.category,
    required this.caption,
    required this.note,
    required this.imageUrl,
    this.mediaType = 'image',
    String? mediaUrl,
    String? thumbnailUrl,
    this.videoUrl = '',
    this.durationMs,
    required this.createdAt,
    required this.locationName,
    required this.sharedToFeed,
    required this.privacy,
    this.closeFriendUids = const [],
    this.taggedUsernames = const [],
    this.categoryIconCodePoint,
    this.categoryColorHex,
    this.groupId,
    this.groupName,
    this.groupMemberIds = const [],
    this.latitude,
    this.longitude,
    bool? isGroupExpense,
    bool? isGroupContribution,
    this.isFrontCamera = false,
  })  : mediaUrl = mediaUrl ?? imageUrl,
        thumbnailUrl = thumbnailUrl ?? imageUrl,
        isGroupContribution = isGroupContribution ??
            ((privacy == 'group' && (type == 'income' || category == 'Quỹ nhóm' || category == 'Group Fund')) ||
                category == 'Quỹ nhóm' ||
                category == 'Group Fund'),
        isGroupExpense = isGroupExpense ??
            (privacy == 'group' &&
                type == 'expense' &&
                !(isGroupContribution ??
                    ((privacy == 'group' && (type == 'income' || category == 'Quỹ nhóm' || category == 'Group Fund')) ||
                        category == 'Quỹ nhóm' ||
                        category == 'Group Fund')) &&
                category != 'Quỹ nhóm' &&
                category != 'Group Fund'),
        type = ((isGroupContribution ??
                    ((privacy == 'group' && (type == 'income' || category == 'Quỹ nhóm' || category == 'Group Fund')) ||
                        category == 'Quỹ nhóm' ||
                        category == 'Group Fund')) ||
                category == 'Quỹ nhóm' ||
                category == 'Group Fund')
            ? 'expense'
            : type;

  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';

  /// Kiểm tra xem giao dịch có được tạo bằng giọng nói không
  bool get isVoiceExpense {
    final n = note.toLowerCase().trim();
    return n == 'voice' || n.startsWith('voice:') || n.contains('[voice]') || n.startsWith('voice_expense');
  }

  /// Chi tiêu cá nhân: bao gồm chi tiêu bình thường và nạp quỹ nhóm,
  /// nhưng LOẠI TRỪ các khoản chi tiêu từ quỹ nhóm (vì đó là tiền của quỹ, không phải tiền cá nhân).
  bool get isPersonalExpense =>
      (type == 'expense' && !isGroupExpense) || isGroupContribution;

  /// Thu nhập cá nhân: loại trừ các giao dịch quỹ nhóm.
  bool get isPersonalIncome => type == 'income' && !isGroupContribution;

  /// Dùng cho các UI thumbnail như Home, Calendar, Recent.
  /// Ảnh thì lấy ảnh thật.
  /// Video thì lấy thumbnail.
  String get displayImageUrl {
    if (isVideo) {
      if (thumbnailUrl.trim().isNotEmpty) return thumbnailUrl;
      if (imageUrl.trim().isNotEmpty) return imageUrl;
    }

    if (mediaUrl.trim().isNotEmpty) return mediaUrl;
    return imageUrl;
  }

  /// Dùng cho Feed / Detail khi cần phát video.
  String get playableVideoUrl {
    if (videoUrl.trim().isNotEmpty) return videoUrl;
    if (isVideo && mediaUrl.trim().isNotEmpty) return mediaUrl;
    return '';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final imageUrl = map['imageUrl']?.toString() ?? '';

    final rawMediaType = map['mediaType']?.toString().trim();

    final mediaType = rawMediaType == null || rawMediaType.isEmpty
        ? (imageUrl.trim().isEmpty ? 'none' : 'image')
        : rawMediaType;

    final mediaUrl = map['mediaUrl']?.toString() ??
        (mediaType == 'video'
            ? map['videoUrl']?.toString() ?? ''
            : imageUrl);

    final thumbnailUrl = map['thumbnailUrl']?.toString() ??
        (mediaType == 'video' ? imageUrl : mediaUrl);

    final videoUrl = map['videoUrl']?.toString() ??
        (mediaType == 'video' ? mediaUrl : '');

    final rawIsContribution = map['isGroupContribution'] == true ||
        (map['privacy'] == 'group' &&
            (map['type'] == 'income' ||
                map['category'] == 'Quỹ nhóm' ||
                map['category'] == 'Group Fund')) ||
        (map['category']?.toString() == 'Quỹ nhóm' ||
            map['category']?.toString() == 'Group Fund');

    final rawIsExpense = (map['isGroupExpense'] == true ||
            (map['privacy'] == 'group' &&
                map['type'] == 'expense' &&
                !rawIsContribution)) &&
        !rawIsContribution &&
        map['category']?.toString() != 'Quỹ nhóm' &&
        map['category']?.toString() != 'Group Fund';

    final rawType = map['type']?.toString() ?? 'expense';
    final effectiveType = rawIsContribution ? 'expense' : rawType;

    return TransactionModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      amount: _parseDouble(map['amount']),
      type: effectiveType,
      category: map['category']?.toString() ?? '',
      caption: map['caption']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      imageUrl: imageUrl,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      durationMs: _parseIntOrNull(map['durationMs']),
      createdAt: _parseDateTime(map['createdAt']),
      locationName: map['locationName']?.toString() ?? '',
      sharedToFeed: map['sharedToFeed'] == true,
      privacy: map['privacy']?.toString() ?? 'private',
      closeFriendUids: (map['closeFriendUids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      taggedUsernames: (map['taggedUsernames'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const [],
      categoryIconCodePoint: _parseIntOrNull(map['categoryIconCodePoint']),
      categoryColorHex: map['categoryColorHex']?.toString(),
      groupId: map['groupId']?.toString(),
      groupName: map['groupName']?.toString(),
      groupMemberIds: (map['groupMemberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      latitude: map['latitude'] is num
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] is num
          ? (map['longitude'] as num).toDouble()
          : null,
      isGroupExpense: rawIsExpense,
      isGroupContribution: rawIsContribution,
      isFrontCamera: map['isFrontCamera'] == true,
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

      // Field cũ.
      'imageUrl': imageUrl,

      // Field mới.
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'durationMs': durationMs,

      'createdAt': createdAt,
      'locationName': locationName,
      'sharedToFeed': sharedToFeed,
      'privacy': privacy,
      'closeFriendUids': closeFriendUids,
      'taggedUsernames': taggedUsernames,
      'categoryIconCodePoint': categoryIconCodePoint,
      'categoryColorHex': categoryColorHex,
      'groupId': groupId,
      'groupName': groupName,
      'groupMemberIds': groupMemberIds,
      'latitude': latitude,
      'longitude': longitude,
      'isGroupExpense': isGroupExpense,
      'isGroupContribution': isGroupContribution,
      'isFrontCamera': isFrontCamera,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    String? category,
    String? caption,
    String? note,
    String? imageUrl,
    String? mediaType,
    String? mediaUrl,
    String? thumbnailUrl,
    String? videoUrl,
    int? durationMs,
    DateTime? createdAt,
    String? locationName,
    bool? sharedToFeed,
    String? privacy,
    List<String>? closeFriendUids,
    List<String>? taggedUsernames,
    int? categoryIconCodePoint,
    String? categoryColorHex,
    String? groupId,
    String? groupName,
    List<String>? groupMemberIds,
    double? latitude,
    double? longitude,
    bool? isGroupExpense,
    bool? isGroupContribution,
    bool? isFrontCamera,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      caption: caption ?? this.caption,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      locationName: locationName ?? this.locationName,
      sharedToFeed: sharedToFeed ?? this.sharedToFeed,
      privacy: privacy ?? this.privacy,
      closeFriendUids: closeFriendUids ?? this.closeFriendUids,
      taggedUsernames: taggedUsernames ?? this.taggedUsernames,
      categoryIconCodePoint: categoryIconCodePoint ?? this.categoryIconCodePoint,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupMemberIds: groupMemberIds ?? this.groupMemberIds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isGroupExpense: isGroupExpense ?? this.isGroupExpense,
      isGroupContribution: isGroupContribution ?? this.isGroupContribution,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    );
  }
}