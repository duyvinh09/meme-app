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
      case 'icon3':
        return context.l10n.appIconSketch;
      case 'icon4':
        return context.l10n.appIconLuxury;
      case 'icon5':
        return context.l10n.appIconMinimal;
      case 'icon6':
        return context.l10n.appIconModern3D;
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
      case 'icon3':
        return context.l10n.appIconSketchDesc;
      case 'icon4':
        return context.l10n.appIconLuxuryDesc;
      case 'icon5':
        return context.l10n.appIconMinimalDesc;
      case 'icon6':
        return context.l10n.appIconModern3DDesc;
      default:
        return context.l10n.appIconClassicDesc;
    }
  }
}

class AppIconService {
  static const MethodChannel _channel =
      MethodChannel('com.duyvinh09.memeapp/app_icon');
  static const String _prefsKey = 'selected_app_icon_key';

  static String _cachedIconId = 'default';
  static String get cachedIconId => _cachedIconId;

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
    AppIconOption(
      id: 'icon3',
      fallbackName: 'Meme Phác Thảo',
      fallbackDescription: 'Phong cách tranh vẽ chì màu trên sổ tay dễ thương',
      assetPath: 'assets/icons/memeapp_icon3.png',
    ),
    AppIconOption(
      id: 'icon4',
      fallbackName: 'Meme Hoàng Kim',
      fallbackDescription: 'Chất liệu da đen và kim loại vàng sang trọng',
      assetPath: 'assets/icons/memeapp_icon4.png',
    ),
    AppIconOption(
      id: 'icon5',
      fallbackName: 'Meme Tối Giản',
      fallbackDescription: 'Đường nét phác hoạ thanh lịch, tinh gọn',
      assetPath: 'assets/icons/memeapp_icon5.png',
    ),
    AppIconOption(
      id: 'icon6',
      fallbackName: 'Meme 3D Hiện Đại',
      fallbackDescription: 'Thiết kế không gian 3D nổi bật với biểu tượng chữ meme',
      assetPath: 'assets/icons/memeapp_icon6.png',
    ),
  ];

  static String getAssetForIconId(String iconId) {
    final option = availableIcons.firstWhere(
      (opt) => opt.id == iconId,
      orElse: () => availableIcons.first,
    );
    return option.assetPath;
  }

  static String get currentIconAsset => getAssetForIconId(_cachedIconId);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty) {
        _cachedIconId = saved;
      }
    } catch (_) {}
  }

  static Future<String> getCurrentIcon() async {
    try {
      final String? platformIcon =
          await _channel.invokeMethod<String>('getCurrentIcon');
      if (platformIcon != null && platformIcon.isNotEmpty) {
        _cachedIconId = platformIcon;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, platformIcon);
        return platformIcon;
      }

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty) {
        _cachedIconId = saved;
        return saved;
      }
      _cachedIconId = 'default';
      return 'default';
    } catch (e) {
      debugPrint('Error getting current app icon: $e');
      return _cachedIconId;
    }
  }

  static Future<bool> setAppIcon(String iconId) async {
    try {
      final bool? success =
          await _channel.invokeMethod<bool>('setAppIcon', {'icon': iconId});

      if (success == true) {
        _cachedIconId = iconId;
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
