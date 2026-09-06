import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class AppLocationResult {
  final double latitude;
  final double longitude;
  final String locationName;

  const AppLocationResult({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });
}

class LocationService {
  LocationService._();

  static AppLocationResult? _cachedLocation;
  static DateTime? _lastFetchTime;

  /// Retrieve current device location with automatic permission request and fallbacks.
  static Future<AppLocationResult?> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
  }) async {
    try {
      // 0. Use fresh cache if obtained within last 45 seconds
      if (_cachedLocation != null && _lastFetchTime != null) {
        if (DateTime.now().difference(_lastFetchTime!).inSeconds < 45) {
          return _cachedLocation;
        }
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied && requestPermissionIfNeeded) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission not granted: $permission');
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service (GPS) is disabled on device');
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          final locationName = await _getLocationName(
            latitude: lastPos.latitude,
            longitude: lastPos.longitude,
          );
          final result = AppLocationResult(
            latitude: lastPos.latitude,
            longitude: lastPos.longitude,
            locationName: locationName.isNotEmpty
                ? locationName
                : '${lastPos.latitude.toStringAsFixed(3)}, ${lastPos.longitude.toStringAsFixed(3)}',
          );
          _cachedLocation = result;
          _lastFetchTime = DateTime.now();
          return result;
        }
        return null;
      }

      Position? position;

      // 1. Try fast last known position as fallback candidate
      final lastKnown = await Geolocator.getLastKnownPosition();

      // 2. Fetch fresh position with multi-stage accuracy
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        debugPrint('Medium accuracy position error: $e, trying low accuracy...');
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
        } catch (e2) {
          debugPrint('Low accuracy position error: $e2');
          position = lastKnown;
        }
      }

      position ??= lastKnown;

      if (position == null) {
        debugPrint('Unable to determine location position');
        return null;
      }

      final locationName = await _getLocationName(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final result = AppLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName.isNotEmpty
            ? locationName
            : 'Vị trí hiện tại',
      );

      _cachedLocation = result;
      _lastFetchTime = DateTime.now();

      return result;
    } catch (e) {
      debugPrint('getCurrentLocation unexpected error: $e');
      return null;
    }
  }

  static Future<String> _getLocationName({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Try native platform geocoder
    try {
      final places = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (places.isNotEmpty) {
        final p = places.first;
        final parts = [
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ]
            .where((e) => e != null && e.trim().isNotEmpty)
            .map((e) => e!.trim())
            .toSet()
            .toList();

        final name = parts.join(', ');
        if (name.isNotEmpty) return name;
      }
    } catch (e) {
      debugPrint('Native placemarkFromCoordinates error: $e');
    }

    // 2. Fallback to OpenStreetMap Reverse Geocoding API if native geocoder fails
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=16&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MemeApp/1.0',
          'Accept-Language': 'vi,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['road'] ?? address['pedestrian'] ?? address['suburb'];
          final city = address['city'] ?? address['town'] ?? address['county'] ?? address['state'];
          final country = address['country'];

          final parts = [road, city, country]
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .map((e) => e.toString().trim())
              .toSet()
              .toList();

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
    } catch (e) {
      debugPrint('HTTP reverse geocoding fallback error: $e');
    }

    return '';
  }

  static Future<bool> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  static Future<void> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  /// Proactively requests permission on first startup if not already decided.
  static Future<void> requestLocationPermissionOnFirstOpen() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint('requestLocationPermissionOnFirstOpen error: $e');
    }
  }
}