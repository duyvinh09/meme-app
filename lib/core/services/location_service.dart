import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<AppLocationResult?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 8),
              ),
            );
      }

      final locationName = await _getLocationName(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return AppLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> _getLocationName({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final places = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (places.isEmpty) return '';

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

      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }

  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
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

  static const String _askedLocationOnFirstOpenKey =
      'asked_location_permission_on_first_open';

  static Future<void> requestLocationPermissionOnFirstOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final hasAsked = prefs.getBool(_askedLocationOnFirstOpenKey) ?? false;

      if (hasAsked) {
        return;
      }

      await prefs.setBool(_askedLocationOnFirstOpenKey, true);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {
      return;
    }
  }
}