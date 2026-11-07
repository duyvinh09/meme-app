import 'dart:math' as math;

class NearbyPlace {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? address;
  final double? rating;
  final int? reviewCount;
  final String? priceRange;
  final String? phone;
  final String? placeType;
  final String? imageUrl;
  final double distanceMeters;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.rating,
    this.reviewCount,
    this.priceRange,
    this.phone,
    this.placeType,
    this.imageUrl,
    required this.distanceMeters,
  });

  /// Formatted review count: "350", "1.2k", "2.6k"
  String? get formattedReviewCount {
    if (reviewCount == null || reviewCount! <= 0) return null;
    if (reviewCount! < 1000) {
      return '$reviewCount';
    }
    final k = reviewCount! / 1000.0;
    return '${k.toStringAsFixed(1)}k';
  }

  /// Distance formatted for display: "350 m", "1.2 km", "2.7 km"
  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    final km = distanceMeters / 1000.0;
    if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${km.toStringAsFixed(0)} km';
  }

  /// Estimated walking or driving time formatted in Vietnamese or English
  String travelTimeEstimate({required bool isEn}) {
    if (distanceMeters < 800) {
      final mins = (distanceMeters / 75).clamp(1, 15).round();
      return isEn ? '🚶 ~$mins min walk' : '🚶 ~$mins phút đi bộ';
    } else {
      final mins = (distanceMeters / 380).clamp(2, 25).round();
      return isEn ? '🛵 ~$mins min drive' : '🛵 ~$mins phút đi xe';
    }
  }

  /// Direct Google Maps navigation URL
  String get googleMapsUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';

  /// Text to share to group chat or external apps
  String getShareText({required bool isEn}) {
    final cat = category;
    if (isEn) {
      return '📍 Let\'s check out "$name" ($cat) - $distanceLabel away!\n$googleMapsUrl';
    }
    return '📍 Nhóm mình cùng ghé "$name" ($cat) nhé - cách đây $distanceLabel!\n$googleMapsUrl';
  }

  /// Compute haversine distance in meters between two coordinates
  static double haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadius = 6371000.0; // meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * math.pi / 180.0;

  NearbyPlace copyWith({
    String? id,
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    String? address,
    double? rating,
    int? reviewCount,
    String? priceRange,
    String? phone,
    String? placeType,
    String? imageUrl,
    double? distanceMeters,
  }) {
    return NearbyPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceRange: priceRange ?? this.priceRange,
      phone: phone ?? this.phone,
      placeType: placeType ?? this.placeType,
      imageUrl: imageUrl ?? this.imageUrl,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
