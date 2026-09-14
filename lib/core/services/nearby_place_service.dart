import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/nearby_place_model.dart';

// ─────────────────────────────────────────────────────────────
// ABSTRACT INTERFACE
// ─────────────────────────────────────────────────────────────

abstract class NearbyPlaceService {
  Future<List<NearbyPlace>> searchNearby({
    required double latitude,
    required double longitude,
    required String category, // Category key ('Food', 'Shopping', 'Transport', etc.)
    required double radiusKm,
  });
}

// ─────────────────────────────────────────────────────────────
// CATEGORY CONFIG (5 Core App Categories)
// ─────────────────────────────────────────────────────────────

class NearbyPlaceConfig {
  NearbyPlaceConfig._();

  /// 5 main categories matching MeMe app's transaction model:
  /// Food, Shopping, Transport, Entertainment, Education
  static const List<String> coreCategories = [
    'Food',
    'Shopping',
    'Transport',
    'Entertainment',
    'Education',
  ];

  static const Map<String, OverpassFilter> categoryFilters = {
    // 1. Food: Quán ăn, nhà hàng, quán cafe, trà sữa, tiệm bánh, ăn vặt, fast food, bistro
    'Food': OverpassFilter(
      icon: '🍜',
      viName: 'Ăn uống',
      enName: 'Food & Dining',
      osm: 'node[amenity~"restaurant|cafe|fast_food|food_court|bistro|ice_cream|pub|bar"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[amenity~"restaurant|cafe|fast_food|food_court|bistro|ice_cream|pub|bar"](around:\$radiusMeters,\$lat,\$lon);\n'
          'node[shop~"bakery|pastry|coffee"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[shop~"bakery|pastry|coffee"](around:\$radiusMeters,\$lat,\$lon);',
    ),

    // 2. Shopping: TTTM, siêu thị, chợ, quần áo, giày dép, mỹ phẩm, đồ điện tử, quà tặng
    'Shopping': OverpassFilter(
      icon: '🛍️',
      viName: 'Mua sắm',
      enName: 'Shopping',
      osm: 'node[shop~"mall|supermarket|clothes|shoes|electronics|department_store|convenience|fashion|boutique|gift|cosmetics|beauty|variety_store"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[shop~"mall|supermarket|clothes|shoes|electronics|department_store|convenience|fashion|boutique|gift|cosmetics|beauty|variety_store"](around:\$radiusMeters,\$lat,\$lon);\n'
          'node[amenity="marketplace"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[amenity="marketplace"](around:\$radiusMeters,\$lat,\$lon);',
    ),

    // 3. Transport: Cây xăng, trạm sạc điện, bến xe, ga tàu, bãi đỗ xe, tiệm sửa xe / vá xe
    'Transport': OverpassFilter(
      icon: '🚗',
      viName: 'Đi lại',
      enName: 'Transport',
      osm: 'node[amenity~"fuel|charging_station|bus_station|car_wash|car_repair"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[amenity~"fuel|charging_station|bus_station|car_wash|car_repair"](around:\$radiusMeters,\$lat,\$lon);\n'
          'node[shop~"car_repair|motorcycle_repair"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[shop~"car_repair|motorcycle_repair"](around:\$radiusMeters,\$lat,\$lon);',
    ),

    // 4. Entertainment: Rạp phim, karaoke, bida, công viên, khu vui chơi, bowling, gym, điểm check-in/du lịch
    'Entertainment': OverpassFilter(
      icon: '🎮',
      viName: 'Giải trí',
      enName: 'Entertainment',
      osm: 'node[amenity~"cinema|karaoke|billiards|internet_cafe|theatre|nightclub|casino"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[amenity~"cinema|karaoke|billiards|internet_cafe|theatre|nightclub|casino"](around:\$radiusMeters,\$lat,\$lon);\n'
          'node[leisure~"park|garden|amusement_arcade|bowling_alley|escape_game|sports_centre|fitness_centre|water_park|theme_park|playground"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[leisure~"park|garden|amusement_arcade|bowling_alley|escape_game|sports_centre|fitness_centre|water_park|theme_park|playground"](around:\$radiusMeters,\$lat,\$lon);\n'
          'node[tourism~"attraction|museum|viewpoint|zoo|theme_park"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[tourism~"attraction|museum|viewpoint|zoo|theme_park"](around:\$radiusMeters,\$lat,\$lon);',
    ),

    // 5. Education: Nhà sách, hiệu sách, thư viện, trường học, trường đại học, trung tâm học tập
    'Education': OverpassFilter(
      icon: '🎓',
      viName: 'Học tập',
      enName: 'Education',
      osm: 'node[amenity~"library|school|university|college|kindergarten"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[amenity~"library|school|university|college|kindergarten"](around:\$radiusMeters,\$lat,\$lon);\n'
          'node[shop~"books|stationery"](around:\$radiusMeters,\$lat,\$lon);\n'
          'way[shop~"books|stationery"](around:\$radiusMeters,\$lat,\$lon);',
    ),
  };

  /// Normalizes any raw transaction category to one of the 5 core keys:
  /// 'Food' | 'Shopping' | 'Transport' | 'Entertainment' | 'Education'
  static String normalizeCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Food';
    final trimmed = raw.trim().toLowerCase();

    if (trimmed.contains('ăn') ||
        trimmed.contains('food') ||
        trimmed.contains('cafe') ||
        trimmed.contains('uống') ||
        trimmed.contains('cà phê')) {
      return 'Food';
    }
    if (trimmed.contains('mua') ||
        trimmed.contains('shop') ||
        trimmed.contains('siêu thị') ||
        trimmed.contains('chợ') ||
        trimmed.contains('quà') ||
        trimmed.contains('gift')) {
      return 'Shopping';
    }
    if (trimmed.contains('đi') ||
        trimmed.contains('chuyển') ||
        trimmed.contains('transport') ||
        trimmed.contains('xăng') ||
        trimmed.contains('xe')) {
      return 'Transport';
    }
    if (trimmed.contains('giải trí') ||
        trimmed.contains('entertainment') ||
        trimmed.contains('phim') ||
        trimmed.contains('cinema') ||
        trimmed.contains('công viên') ||
        trimmed.contains('du lịch') ||
        trimmed.contains('thể thao')) {
      return 'Entertainment';
    }
    if (trimmed.contains('học') ||
        trimmed.contains('giáo dục') ||
        trimmed.contains('education') ||
        trimmed.contains('sách')) {
      return 'Education';
    }

    return 'Food';
  }

  /// Returns suggested categories for a given spending category.
  /// The spending category appears last (de-emphasized).
  static List<String> getSuggestedCategories(String spendingCategory) {
    final norm = normalizeCategory(spendingCategory);
    final order = List<String>.from(coreCategories);
    order.remove(norm);
    order.add(norm); // Spending category placed last
    return order;
  }

  static String getCategoryLabel(String categoryKey, {required bool isEn}) {
    final norm = normalizeCategory(categoryKey);
    final filter = categoryFilters[norm];
    if (filter == null) return categoryKey;
    return isEn ? filter.enName : filter.viName;
  }

  static String iconForCategory(String categoryKey) {
    final norm = normalizeCategory(categoryKey);
    return categoryFilters[norm]?.icon ?? '📍';
  }

  static String? osmFilterForCategory(String categoryKey) {
    final norm = normalizeCategory(categoryKey);
    return categoryFilters[norm]?.osm;
  }
}

class OverpassFilter {
  final String icon;
  final String viName;
  final String enName;
  final String osm;

  const OverpassFilter({
    required this.icon,
    required this.viName,
    required this.enName,
    required this.osm,
  });
}

// ─────────────────────────────────────────────────────────────
// OVERPASS (OSM) IMPLEMENTATION WITH RATE-LIMIT & CACHE
// ─────────────────────────────────────────────────────────────

class OverpassNearbyPlaceService implements NearbyPlaceService {
  OverpassNearbyPlaceService._();

  static final OverpassNearbyPlaceService instance =
      OverpassNearbyPlaceService._();

  /// List of Overpass API mirror endpoints ordered by speed and availability
  static const List<String> _overpassEndpoints = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  static const Duration _cacheExpiry = Duration(minutes: 20);
  static const double _approxGridDeg = 0.015; // ~1.5 km grid for cache key

  final Map<String, _CacheEntry> _cache = {};

  // Rate-limiting timestamp
  static DateTime? _lastRequestTime;
  static Completer<void>? _rateLimitCompleter;

  /// Lightweight rate-limiting to prevent spamming
  Future<void> _throttle() async {
    while (_rateLimitCompleter != null) {
      await _rateLimitCompleter!.future;
    }

    _rateLimitCompleter = Completer<void>();
    try {
      final now = DateTime.now();
      if (_lastRequestTime != null) {
        final elapsed = now.difference(_lastRequestTime!);
        const minGap = Duration(milliseconds: 200);
        if (elapsed < minGap) {
          await Future.delayed(minGap - elapsed);
        }
      }
      _lastRequestTime = DateTime.now();
    } finally {
      final completer = _rateLimitCompleter;
      _rateLimitCompleter = null;
      completer?.complete();
    }
  }

  @override
  Future<List<NearbyPlace>> searchNearby({
    required double latitude,
    required double longitude,
    required String category,
    required double radiusKm,
  }) async {
    final normCategory = NearbyPlaceConfig.normalizeCategory(category);

    // 1. Check in-memory Cache
    final cacheKey = _buildCacheKey(latitude, longitude, normCategory);
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      debugPrint('OverpassService: Cache HIT for $cacheKey (${cached.places.length} places)');
      return cached.places;
    }

    // 2. Validate OSM filter
    final osmFilter = NearbyPlaceConfig.osmFilterForCategory(normCategory);
    if (osmFilter == null) {
      debugPrint('OverpassService: No OSM filter for category "$normCategory"');
      return [];
    }

    final radiusMeters = (radiusKm * 1000).toInt();
    final query = _buildOverpassQuery(
      lat: latitude,
      lon: longitude,
      radiusMeters: radiusMeters,
      osmFilter: osmFilter,
    );

    // 3. Apply Rate Limiting
    await _throttle();

    // 4. Fast-Fallback Concurrent Mirror Request
    final responseData = await _queryOverpassWithFastFallback(query);

    if (responseData == null) {
      debugPrint('OverpassService: All Overpass mirrors failed or timed out');
      return [];
    }

    // 5. Parse OSM elements
    final elements = responseData['elements'] as List<dynamic>? ?? [];
    final places = _parseElements(
      elements: elements,
      category: normCategory,
      userLat: latitude,
      userLon: longitude,
      maxRadiusMeters: radiusKm * 1000,
    );

    // 6. Sort by nearest distance first
    places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    // 7. Store in Cache
    _cache[cacheKey] = _CacheEntry(places: places, createdAt: DateTime.now());
    debugPrint('OverpassService: Found ${places.length} places for "$normCategory"');
    return places;
  }

  /// Sends request to the fastest mirror; if it doesn't respond within 1.2s,
  /// races the backup mirrors concurrently to guarantee the fastest response.
  Future<Map<String, dynamic>?> _queryOverpassWithFastFallback(String query) async {
    final completer = Completer<Map<String, dynamic>?>();
    var pendingCount = 0;
    var hasCompleted = false;

    Future<void> executeQuery(String endpoint) async {
      if (hasCompleted) return;
      pendingCount++;
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
                'User-Agent': 'MemeApp/1.0 (nearby_place_feature; contact: support@memeapp.vn)',
                'Accept-Language': 'vi,vi-VN;q=0.9,en;q=0.8',
              },
              body: 'data=${Uri.encodeComponent(query)}',
            )
            .timeout(const Duration(seconds: 8));

        if (!hasCompleted && response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          if (data.containsKey('elements')) {
            hasCompleted = true;
            if (!completer.isCompleted) completer.complete(data);
            return;
          }
        }
      } catch (_) {
        // Fallback to next mirror
      } finally {
        pendingCount--;
        if (pendingCount == 0 && !hasCompleted && !completer.isCompleted) {
          completer.complete(null);
        }
      }
    }

    // 1. Fire primary high-speed mirror
    executeQuery(_overpassEndpoints[0]);

    // 2. If primary takes longer than 1200ms, immediately fire backup mirrors in parallel
    await Future.any([
      completer.future,
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    if (!hasCompleted) {
      for (int i = 1; i < _overpassEndpoints.length; i++) {
        if (hasCompleted) break;
        executeQuery(_overpassEndpoints[i]);
      }
    }

    return completer.future;
  }



  List<NearbyPlace> _parseElements({
    required List<dynamic> elements,
    required String category,
    required double userLat,
    required double userLon,
    required double maxRadiusMeters,
  }) {
    final seen = <String>{};
    final result = <NearbyPlace>[];

    for (final el in elements) {
      if (el is! Map<String, dynamic>) continue;

      final id = el['id']?.toString() ?? '';
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final name = _extractName(tags);

      if (name.isEmpty) continue;
      // Deduplicate by name (normalized lowercase)
      final normName = name.toLowerCase().trim();
      if (seen.contains(normName)) continue;
      seen.add(normName);

      double? lat;
      double? lon;

      if (el['type'] == 'node') {
        lat = (el['lat'] as num?)?.toDouble();
        lon = (el['lon'] as num?)?.toDouble();
      } else if (el['type'] == 'way' || el['type'] == 'relation') {
        lat = (el['center']?['lat'] as num?)?.toDouble();
        lon = (el['center']?['lon'] as num?)?.toDouble();
      }

      if (lat == null || lon == null) continue;

      final distance = NearbyPlace.haversineDistance(
        lat1: userLat,
        lon1: userLon,
        lat2: lat,
        lon2: lon,
      );

      if (distance > maxRadiusMeters) continue;

      final address = _extractAddress(tags);
      final rating = _extractRating(tags);
      final imageUrl = _extractImageUrl(tags);

      result.add(NearbyPlace(
        id: id,
        name: name,
        category: category,
        latitude: lat,
        longitude: lon,
        address: address.isNotEmpty ? address : null,
        rating: rating,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        distanceMeters: distance,
      ));
    }

    return result;
  }

  /// Extracts place name with Vietnamese priority:
  /// name:vi > name > alt_name:vi > brand:vi > brand > name:en > alt_name
  String _extractName(Map<String, dynamic> tags) {
    return (tags['name:vi'] as String?) ??
        (tags['name'] as String?) ??
        (tags['alt_name:vi'] as String?) ??
        (tags['brand:vi'] as String?) ??
        (tags['brand'] as String?) ??
        (tags['name:en'] as String?) ??
        (tags['alt_name'] as String?) ??
        '';
  }

  /// Extracts structured Vietnamese address components
  String _extractAddress(Map<String, dynamic> tags) {
    final full = tags['addr:full'] as String?;
    if (full != null && full.trim().isNotEmpty) {
      return full.trim();
    }

    final parts = <String>[];
    final housenumber = tags['addr:housenumber'] as String?;
    final street = tags['addr:street'] as String?;
    final ward = tags['addr:ward'] as String?;
    final district = tags['addr:district'] as String? ?? tags['addr:suburb'] as String?;
    final city = tags['addr:city'] as String? ?? tags['addr:province'] as String?;

    if (housenumber != null && street != null) {
      parts.add('$housenumber $street');
    } else if (street != null) {
      parts.add(street);
    }
    if (ward != null && ward.isNotEmpty && !parts.any((p) => p.contains(ward))) {
      parts.add(ward.startsWith('Phường') || ward.startsWith('Xã') ? ward : 'P. $ward');
    }
    if (district != null && district.isNotEmpty && !parts.any((p) => p.contains(district))) {
      parts.add(district.startsWith('Quận') || district.startsWith('Huyện') ? district : 'Q. $district');
    }
    if (city != null && city.isNotEmpty && !parts.any((p) => p.contains(city))) {
      parts.add(city);
    }

    return parts.join(', ');
  }

  double? _extractRating(Map<String, dynamic> tags) {
    final raw = tags['stars'] ?? tags['rating'];
    if (raw == null) return null;
    return double.tryParse(raw.toString());
  }

  String _extractImageUrl(Map<String, dynamic> tags) {
    return tags['image'] as String? ?? '';
  }

  /// Builds a clean Overpass QL query with timeout and center bounding
  String _buildOverpassQuery({
    required double lat,
    required double lon,
    required int radiusMeters,
    required String osmFilter,
  }) {
    final queryBody = osmFilter
        .replaceAll(r'$radiusMeters', radiusMeters.toString())
        .replaceAll(r'$lat', lat.toString())
        .replaceAll(r'$lon', lon.toString());

    return '''
[out:json][timeout:10];
(
$queryBody
);
out tags center qt 60;
''';
  }

  String _buildCacheKey(double lat, double lon, String category) {
    final latGrid = (lat / _approxGridDeg).round();
    final lonGrid = (lon / _approxGridDeg).round();
    return '${category}_${latGrid}_$lonGrid';
  }

  /// Invalidate cache for a location if user has moved significantly (>500m)
  void invalidateCacheIfMoved({
    required double oldLat,
    required double oldLon,
    required double newLat,
    required double newLon,
    double thresholdMeters = 500,
  }) {
    final dist = NearbyPlace.haversineDistance(
      lat1: oldLat,
      lon1: oldLon,
      lat2: newLat,
      lon2: newLon,
    );
    if (dist > thresholdMeters) {
      _cache.clear();
      debugPrint('OverpassService: User moved ${dist.toInt()}m, cleared cache.');
    }
  }
}

class _CacheEntry {
  final List<NearbyPlace> places;
  final DateTime createdAt;

  _CacheEntry({required this.places, required this.createdAt});

  bool get isExpired =>
      DateTime.now().difference(createdAt) >
      OverpassNearbyPlaceService._cacheExpiry;
}
