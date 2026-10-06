import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../utils/app_haptics.dart';

class LocalSettingsService extends ChangeNotifier {
  late final SharedPreferences _prefs;
  String? _currentUserId;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppHaptics.isEnabled = hapticFeedbackEnabled;
  }

  void setActiveUser(String? uid) {
    if (_currentUserId == uid) return;
    _currentUserId = uid;
    AppHaptics.isEnabled = hapticFeedbackEnabled;
    notifyListeners();
  }

  String get _languageKey =>
      _currentUserId != null ? '${_currentUserId}_languageCode' : 'languageCode';
  String get _currencyKey =>
      _currentUserId != null ? '${_currentUserId}_currency' : 'currency';
  String get _themeModeKey =>
      _currentUserId != null ? '${_currentUserId}_themeMode' : 'themeMode';
  String get _cameraThemeKey =>
      _currentUserId != null ? '${_currentUserId}_cameraTheme' : 'cameraTheme';
  String get _chatBubbleThemeKey =>
      _currentUserId != null ? '${_currentUserId}_chatBubbleTheme' : 'chatBubbleTheme';
  String get _recentEmojisKey =>
      _currentUserId != null ? '${_currentUserId}_recentEmojis' : 'recentEmojis';
  String get _showActiveStatusKey =>
      _currentUserId != null ? '${_currentUserId}_showActiveStatus' : 'showActiveStatus';
  String get _activeStatusModeKey =>
      _currentUserId != null ? '${_currentUserId}_activeStatusMode' : 'activeStatusMode';
  String get _hapticFeedbackKey =>
      _currentUserId != null ? '${_currentUserId}_hapticFeedback' : 'hapticFeedback';
  String get _widgetFrameKey =>
      _currentUserId != null ? '${_currentUserId}_widgetFrame' : 'widgetFrame';

  bool get hapticFeedbackEnabled => _prefs.getBool(_hapticFeedbackKey) ?? true;
  String get widgetFrame => _prefs.getString(_widgetFrameKey) ?? 'none';
  bool get showActiveStatus => _prefs.getBool(_showActiveStatusKey) ?? true;
  String get activeStatusMode {
    if (!showActiveStatus) return 'none';
    return _prefs.getString(_activeStatusModeKey) ?? 'friends';
  }

  String get rawLanguageCode {
    final value =
        _prefs.getString(_languageKey) ?? _prefs.getString('languageCode');

    if (value == 'vi' || value == 'en' || value == 'system') {
      return value!;
    }

    return 'system';
  }

  String get languageCode {
    final raw = rawLanguageCode;
    if (raw == 'system') {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (systemLocale.languageCode.toLowerCase() == 'vi') {
        return 'vi';
      }
      return 'en';
    }
    return raw;
  }

  String get currency {
    final value = _prefs.getString(_currencyKey) ?? _prefs.getString('currency');

    if (value == 'VND' || value == 'USD') {
      return value!;
    }

    return 'VND';
  }

  String get themeModeString {
    final value = _prefs.getString(_themeModeKey) ?? _prefs.getString('themeMode');

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

  static const List<String> defaultAllEmojis = [
    '🤣', '🥺', '😱', '🔥', '❤️', '👏', '😍', '🎉',
    '😎', '💯', '👀', '💀', '😭', '🤯', '🥳', '✨',
    '👍', '🙏', '🥰', '🤩', '💩', '🤑', '🤫', '🥱',
  ];

  String get cameraTheme {
    final value = _prefs.getString(_cameraThemeKey);
    return value ?? 'classic_dark';
  }

  String get chatBubbleTheme {
    return _prefs.getString(_chatBubbleThemeKey) ?? 'default';
  }

  Future<bool> setHapticFeedbackEnabled(bool value) async {
    final res = await _prefs.setBool(_hapticFeedbackKey, value);
    AppHaptics.isEnabled = value;
    notifyListeners();
    return res;
  }

  Future<void> syncFromUserProfile(UserModel user) async {
    _currentUserId = user.uid;
    if (user.language.isNotEmpty) {
      await _prefs.setString(_languageKey, user.language);
    }
    if (user.currency.isNotEmpty) {
      await _prefs.setString(_currencyKey, user.currency);
    }
    if (user.themeMode.isNotEmpty) {
      await _prefs.setString(_themeModeKey, user.themeMode);
    }
    if (user.cameraTheme.isNotEmpty) {
      await _prefs.setString(_cameraThemeKey, user.cameraTheme);
    }
    if (user.chatBubbleTheme.isNotEmpty) {
      await _prefs.setString(_chatBubbleThemeKey, user.chatBubbleTheme);
    }
    if (user.widgetFrame.isNotEmpty) {
      await _prefs.setString(_widgetFrameKey, user.widgetFrame);
    }
    await _prefs.setBool(_showActiveStatusKey, user.showActiveStatus);
    await _prefs.setBool(_hapticFeedbackKey, user.hapticFeedback);
    AppHaptics.isEnabled = user.hapticFeedback;
    notifyListeners();
  }

  Future<bool> setWidgetFrame(String value) async {
    final res = await _prefs.setString(_widgetFrameKey, value);
    notifyListeners();
    return res;
  }

  Future<bool> setShowActiveStatus(bool value) async {
    final res = await _prefs.setBool(_showActiveStatusKey, value);
    if (!value) {
      await _prefs.setString(_activeStatusModeKey, 'none');
    } else {
      final currentMode = _prefs.getString(_activeStatusModeKey);
      if (currentMode == null || currentMode == 'none') {
        await _prefs.setString(_activeStatusModeKey, 'friends');
      }
    }
    notifyListeners();
    return res;
  }

  Future<bool> setActiveStatusMode(String mode) async {
    await _prefs.setString(_activeStatusModeKey, mode);
    final isOnline = mode != 'none';
    final res = await _prefs.setBool(_showActiveStatusKey, isOnline);
    notifyListeners();
    return res;
  }

  Future<bool> setLanguageCode(String value) async {
    if (value != 'vi' && value != 'en' && value != 'system') return false;
    final res = await _prefs.setString(_languageKey, value);
    notifyListeners();
    return res;
  }

  Future<bool> setCurrency(String value) async {
    if (value != 'VND' && value != 'USD') return false;
    final res = await _prefs.setString(_currencyKey, value);
    notifyListeners();
    return res;
  }

  Future<bool> setThemeMode(String value) async {
    if (value != 'light' && value != 'dark' && value != 'system') {
      return false;
    }
    final res = await _prefs.setString(_themeModeKey, value);
    notifyListeners();
    return res;
  }

  Future<bool> setCameraTheme(String value) async {
    final res = await _prefs.setString(_cameraThemeKey, value);
    notifyListeners();
    return res;
  }

  Future<bool> setChatBubbleTheme(String value) async {
    final res = await _prefs.setString(_chatBubbleThemeKey, value);
    notifyListeners();
    return res;
  }

  List<String> get recentEmojis {
    final list = _prefs.getStringList(_recentEmojisKey);
    if (list != null && list.isNotEmpty) {
      final combined = <String>[];
      for (final e in list) {
        if (!combined.contains(e)) {
          combined.add(e);
        }
      }
      for (final e in defaultAllEmojis) {
        if (!combined.contains(e)) {
          combined.add(e);
        }
      }
      return combined;
    }
    return List<String>.from(defaultAllEmojis);
  }

  Future<void> recordEmojiUsage(String emoji) async {
    final current = recentEmojis;
    current.remove(emoji);
    current.insert(0, emoji);
    await _prefs.setStringList(_recentEmojisKey, current);
    notifyListeners();
  }

  // Chat Drafts (1-on-1 & Group)
  String _getDraftKey(String chatId) =>
      _currentUserId != null ? '${_currentUserId}_draft_$chatId' : 'draft_$chatId';

  String? getDraft(String chatId) {
    final draft = _prefs.getString(_getDraftKey(chatId));
    if (draft == null || draft.trim().isEmpty) return null;
    return draft.trim();
  }

  Future<void> setDraft(String chatId, String? text) async {
    final key = _getDraftKey(chatId);
    if (text == null || text.trim().isEmpty) {
      if (_prefs.containsKey(key)) {
        await _prefs.remove(key);
        notifyListeners();
      }
    } else {
      final trimmed = text.trim();
      if (_prefs.getString(key) != trimmed) {
        await _prefs.setString(key, trimmed);
        notifyListeners();
      }
    }
  }

  Future<void> clearDraft(String chatId) async {
    final key = _getDraftKey(chatId);
    if (_prefs.containsKey(key)) {
      await _prefs.remove(key);
      notifyListeners();
    }
  }

  Future<bool> resetSettings() async {
    await _prefs.remove(_languageKey);
    await _prefs.remove(_currencyKey);
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_cameraThemeKey);
    await _prefs.remove(_recentEmojisKey);
    await _prefs.remove(_chatBubbleThemeKey);
    await _prefs.remove(_showActiveStatusKey);
    await _prefs.remove(_activeStatusModeKey);
    await _prefs.remove(_hapticFeedbackKey);
    await _prefs.remove(_widgetFrameKey);
    AppHaptics.isEnabled = true;
    notifyListeners();
    return true;
  }
}