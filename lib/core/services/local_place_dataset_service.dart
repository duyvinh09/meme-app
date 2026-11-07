import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/nearby_place_model.dart';
import 'nearby_place_service.dart';

/// Representation of a curated place record loaded from local dataset (Da Nang Google Maps scrape).
class LocalPlaceRecord {
  final String id;
  final String name;
  final String category;
  final String? placeType;
  final String? address;
  final String? phone;
  final double lat;
  final double lng;
  final double? rating;
  final int? reviews;
  final String? price;
  final String? image;

  const LocalPlaceRecord({
    required this.id,
    required this.name,
    required this.category,
    this.placeType,
    this.address,
    this.phone,
    required this.lat,
    required this.lng,
    this.rating,
    this.reviews,
    this.price,
    this.image,
  });

  factory LocalPlaceRecord.fromJson(Map<String, dynamic> json) {
    return LocalPlaceRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Food',
      placeType: json['place_type'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviews: json['reviews'] as int?,
      price: json['price'] as String?,
      image: json['image'] as String?,
    );
  }

  NearbyPlace toNearbyPlace({required double distanceMeters}) {
    return NearbyPlace(
      id: id,
      name: name,
      category: NearbyPlaceConfig.normalizeCategory(category),
      latitude: lat,
      longitude: lng,
      address: address,
      phone: phone,
      placeType: placeType,
      rating: rating,
      reviewCount: reviews,
      priceRange: price,
      imageUrl: image,
      distanceMeters: distanceMeters,
    );
  }
}

/// Service that manages local scraped Google Maps dataset (Da Nang area)
/// and provides instant, zero-latency nearby queries and metadata enrichment.
class LocalPlaceDatasetService {
  LocalPlaceDatasetService._();

  static final LocalPlaceDatasetService instance = LocalPlaceDatasetService._();

  List<LocalPlaceRecord>? _cachedPlaces;
  bool _isLoading = false;

  bool get isLoaded => _cachedPlaces != null;
  int get count => _cachedPlaces?.length ?? 0;

  /// Loads `assets/data/places.json` once into memory.
  Future<void> loadDatasetIfNeeded({String? jsonOverride}) async {
    if (_cachedPlaces != null) return;

    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
      return;
    }

    _isLoading = true;
    try {
      final jsonString = jsonOverride ??
          await rootBundle.loadString('assets/data/places.json');
      final list = jsonDecode(jsonString) as List<dynamic>;
      _cachedPlaces = list
          .map((e) => LocalPlaceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint(
        '[LocalPlaceDatasetService] Successfully loaded ${_cachedPlaces!.length} places from assets/data/places.json',
      );
    } catch (e, stack) {
      debugPrint(
        '[LocalPlaceDatasetService] Failed to load places.json: $e\n$stack',
      );
      _cachedPlaces = [];
    } finally {
      _isLoading = false;
    }
  }

  @visibleForTesting
  void setPlacesForTesting(List<LocalPlaceRecord> places) {
    _cachedPlaces = places;
  }

  /// Finds places from local dataset matching [category] within [radiusKm] of [userLat, userLon],
  /// sorted by nearest distance first.
  Future<List<NearbyPlace>> getNearbyPlaces({
    required double userLat,
    required double userLon,
    required String category,
    required double radiusKm,
  }) async {
    await loadDatasetIfNeeded();
    final all = _cachedPlaces ?? [];
    if (all.isEmpty) return [];

    final normCategory = NearbyPlaceConfig.normalizeCategory(category);
    final maxRadiusMeters = radiusKm * 1000;

    final results = <NearbyPlace>[];
    for (final p in all) {
      if (NearbyPlaceConfig.normalizeCategory(p.category) != normCategory) {
        continue;
      }

      final distance = NearbyPlace.haversineDistance(
        lat1: userLat,
        lon1: userLon,
        lat2: p.lat,
        lon2: p.lng,
      );

      if (distance <= maxRadiusMeters) {
        results.add(p.toNearbyPlace(distanceMeters: distance));
      }
    }

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }
}
