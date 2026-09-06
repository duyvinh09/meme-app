import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../extensions/localization_extension.dart';

class AppIconOption {
  final String id;
  final String fallbackName;
  final String fallbackDescription;
  final String assetPath;

  const AppIconOption({
    required this.id,
    required this.fallbackName,
    required this.fallbackDescription,
    required this.assetPath,
  });

  String getName(BuildContext context) {
    switch (id) {
      case 'icon1':
        return context.l10n.appIconNeon;
      case 'icon2':
        return context.l10n.appIconOcean;
      default:
        return context.l10n.appIconClassic;
    }
  }

  String getDescription(BuildContext context) {
    switch (id) {
      case 'icon1':
        return context.l10n.appIconNeonDesc;
      case 'icon2':
        return context.l10n.appIconOceanDesc;
      default:
        return context.l10n.appIconClassicDesc;
    }
  }
}

class AppIconService {
  static const MethodChannel _channel =
      MethodChannel('com.duyvinh09.memeapp/app_icon');
  static const String _prefsKey = 'selected_app_icon_key';

  static const List<AppIconOption> availableIcons = [
    AppIconOption(
      id: 'default',
      fallbackName: 'Meme Cổ Điển',
      fallbackDescription: 'Icon gốc mang phong cách vui nhộn kinh điển',
      assetPath: 'assets/icons/memeapp_icon.png',
    ),
    AppIconOption(
      id: 'icon1',
      fallbackName: 'Meme Vàng Neon',
      fallbackDescription: 'Tone vàng ấm áp, nổi bật và cá tính',
      assetPath: 'assets/icons/memeapp_icon1.png',
    ),
    AppIconOption(
      id: 'icon2',
      fallbackName: 'Meme Xanh Dương',
      fallbackDescription: 'Tone xanh hiện đại, tươi sáng và năng động',
      assetPath: 'assets/icons/memeapp_icon2.png',
    ),
  ];

  static Future<String> getCurrentIcon() async {
    try {
      final String? platformIcon =
          await _channel.invokeMethod<String>('getCurrentIcon');
      if (platformIcon != null && platformIcon.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, platformIcon);
        return platformIcon;
      }

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
      return 'default';
    } catch (e) {
      debugPrint('Error getting current app icon: $e');
      return 'default';
    }
  }

  static Future<bool> setAppIcon(String iconId) async {
    try {
      final bool? success =
          await _channel.invokeMethod<bool>('setAppIcon', {'icon': iconId});

      if (success == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, iconId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error setting app icon: $e');
      return false;
    }
  }
}
