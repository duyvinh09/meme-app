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
  final double? latitude;
  final double? longitude;

  final int? categoryIconCodePoint;
  final String? categoryColorHex;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
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
    this.categoryIconCodePoint,
    this.categoryColorHex,
    this.latitude,
    this.longitude,
  })  : mediaUrl = mediaUrl ?? imageUrl,
        thumbnailUrl = thumbnailUrl ?? imageUrl;

  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';

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

    return TransactionModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      amount: _parseDouble(map['amount']),
      type: map['type']?.toString() ?? 'expense',
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
      categoryIconCodePoint: _parseIntOrNull(map['categoryIconCodePoint']),
      categoryColorHex: map['categoryColorHex']?.toString(),
      latitude: map['latitude'] is num
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] is num
          ? (map['longitude'] as num).toDouble()
          : null,
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
      'categoryIconCodePoint': categoryIconCodePoint,
      'categoryColorHex': categoryColorHex,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}