import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsService {
  static const String _languageKey = 'languageCode';
  static const String _currencyKey = 'currency';
  static const String _themeModeKey = 'themeMode';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get languageCode {
    final value = _prefs.getString(_languageKey);

    if (value == 'vi' || value == 'en') {
      return value!;
    }

    return 'vi';
  }

  String get currency {
    final value = _prefs.getString(_currencyKey);

    if (value == 'VND' || value == 'USD') {
      return value!;
    }

    return 'VND';
  }

  String get themeModeString {
    final value = _prefs.getString(_themeModeKey);

    if (value == 'light' || value == 'dark' || value == 'system') {
      return value!;
    }

    return 'system';
  }

  ThemeMode get themeMode {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> setLanguageCode(String value) async {
    if (value != 'vi' && value != 'en') return false;

    return _prefs.setString(_languageKey, value);
  }

  Future<bool> setCurrency(String value) async {
    if (value != 'VND' && value != 'USD') return false;

    return _prefs.setString(_currencyKey, value);
  }

  Future<bool> setThemeMode(String value) async {
    if (value != 'light' && value != 'dark' && value != 'system') {
      return false;
    }

    return _prefs.setString(_themeModeKey, value);
  }

  Future<bool> resetSettings() async {
    await _prefs.remove(_languageKey);
    await _prefs.remove(_currencyKey);
    await _prefs.remove(_themeModeKey);

    return true;
  }
}