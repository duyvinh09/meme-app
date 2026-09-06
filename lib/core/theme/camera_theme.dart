import 'package:flutter/material.dart';
import '../extensions/localization_extension.dart';

class CameraThemeData {
  final String id;
  final String fallbackName;
  final String fallbackDescription;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color shutterAccent;
  final Color frameBorderColor;
  final Color glassButtonBg;
  final Color glassButtonBorder;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Gradient? backgroundGradient;
  final Gradient? frameGradient;
  final IconData previewIcon;
  final List<Color> themePreviewDots;

  const CameraThemeData({
    required this.id,
    required this.fallbackName,
    required this.fallbackDescription,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.shutterAccent,
    required this.frameBorderColor,
    required this.glassButtonBg,
    required this.glassButtonBorder,
    this.primaryTextColor = Colors.white,
    this.secondaryTextColor = Colors.white70,
    this.backgroundGradient,
    this.frameGradient,
    this.previewIcon = Icons.camera_rounded,
    required this.themePreviewDots,
  });

  String getName(BuildContext context) {
    switch (id) {
      case 'cyber_neon':
        return context.l10n.cameraThemeCyber;
      case 'sunset_gold':
        return context.l10n.cameraThemeSunset;
      case 'ocean_breeze':
        return context.l10n.cameraThemeOcean;
      case 'matcha_zen':
        return context.l10n.cameraThemeMatcha;
      case 'aurora_borealis':
        return context.l10n.cameraThemeAurora;
      case 'cherry_blossom':
        return context.l10n.cameraThemeSakura;
      case 'galaxy_nebula':
        return context.l10n.cameraThemeGalaxy;
      case 'lava_fire':
        return context.l10n.cameraThemeLava;
      case 'retro_vaporwave':
        return context.l10n.cameraThemeVaporwave;
      case 'classic_dark':
      default:
        return context.l10n.cameraThemeClassic;
    }
  }

  String getDescription(BuildContext context) {
    switch (id) {
      case 'cyber_neon':
        return context.l10n.cameraThemeCyberDesc;
      case 'sunset_gold':
        return context.l10n.cameraThemeSunsetDesc;
      case 'ocean_breeze':
        return context.l10n.cameraThemeOceanDesc;
      case 'matcha_zen':
        return context.l10n.cameraThemeMatchaDesc;
      case 'aurora_borealis':
        return context.l10n.cameraThemeAuroraDesc;
      case 'cherry_blossom':
        return context.l10n.cameraThemeSakuraDesc;
      case 'galaxy_nebula':
        return context.l10n.cameraThemeGalaxyDesc;
      case 'lava_fire':
        return context.l10n.cameraThemeLavaDesc;
      case 'retro_vaporwave':
        return context.l10n.cameraThemeVaporwaveDesc;
      case 'classic_dark':
      default:
        return context.l10n.cameraThemeClassicDesc;
    }
  }
}

class CameraThemes {
  static const CameraThemeData classicDark = CameraThemeData(
    id: 'classic_dark',
    fallbackName: 'Meme Cổ Điển',
    fallbackDescription: 'Giao diện tối huyền ảo kết hợp viền xanh lục neon kinh điển',
    backgroundColor: Color(0xFF15171C),
    surfaceColor: Color(0xFF232833),
    shutterAccent: Color(0xFF6DFF8A),
    frameBorderColor: Color(0xFF2B3240),
    glassButtonBg: Color(0x38000000),
    glassButtonBorder: Color(0x22FFFFFF),
    themePreviewDots: [Color(0xFF15171C), Color(0xFF232833), Color(0xFF6DFF8A)],
  );

  static const CameraThemeData cyberNeon = CameraThemeData(
    id: 'cyber_neon',
    fallbackName: 'Cyber Neon',
    fallbackDescription: 'Phong cách Cyberpunk với tone tím neon và xanh dạ quang',
    backgroundColor: Color(0xFF0D0A18),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF231042), Color(0xFF0D0A18), Color(0xFF140828)],
    ),
    surfaceColor: Color(0xFF281446),
    shutterAccent: Color(0xFF06B6D4),
    frameBorderColor: Color(0xFF9333EA),
    frameGradient: LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    ),
    glassButtonBg: Color(0x40231042),
    glassButtonBorder: Color(0x40A855F7),
    themePreviewDots: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF06B6D4)],
  );

  static const CameraThemeData sunsetGold = CameraThemeData(
    id: 'sunset_gold',
    fallbackName: 'Hoàng Hôn Vàng',
    fallbackDescription: 'Tone màu hoàng hôn ấm áp cùng ánh vàng hổ phách sang trọng',
    backgroundColor: Color(0xFF17120C),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF301C10), Color(0xFF140E08), Color(0xFF23140A)],
    ),
    surfaceColor: Color(0xFF382314),
    shutterAccent: Color(0xFFF59E0B),
    frameBorderColor: Color(0xFFD97706),
    frameGradient: LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFFFB923C)],
    ),
    glassButtonBg: Color(0x40301C10),
    glassButtonBorder: Color(0x40F59E0B),
    themePreviewDots: [Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFF382314)],
  );

  static const CameraThemeData oceanBreeze = CameraThemeData(
    id: 'ocean_breeze',
    fallbackName: 'Biển Xanh',
    fallbackDescription: 'Tone xanh biển sâu mát mẻ, hiện đại và năng động',
    backgroundColor: Color(0xFF08121E),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0E233E), Color(0xFF060D17), Color(0xFF0B1B2F)],
    ),
    surfaceColor: Color(0xFF162D4A),
    shutterAccent: Color(0xFF38BDF8),
    frameBorderColor: Color(0xFF0284C7),
    frameGradient: LinearGradient(
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF3B82F6)],
    ),
    glassButtonBg: Color(0x400E233E),
    glassButtonBorder: Color(0x4038BDF8),
    themePreviewDots: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF08121E)],
  );

  static const CameraThemeData matchaZen = CameraThemeData(
    id: 'matcha_zen',
    fallbackName: 'Matcha Zen',
    fallbackDescription: 'Màu xanh trà matcha thanh bình và thư giãn',
    backgroundColor: Color(0xFF0B140F),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF162E20), Color(0xFF08100B), Color(0xFF112217)],
    ),
    surfaceColor: Color(0xFF1C3627),
    shutterAccent: Color(0xFF34D399),
    frameBorderColor: Color(0xFF059669),
    frameGradient: LinearGradient(
      colors: [Color(0xFF34D399), Color(0xFF059669), Color(0xFF10B981)],
    ),
    glassButtonBg: Color(0x40162E20),
    glassButtonBorder: Color(0x4034D399),
    themePreviewDots: [Color(0xFF34D399), Color(0xFF059669), Color(0xFF0B140F)],
  );

  static const CameraThemeData auroraBorealis = CameraThemeData(
    id: 'aurora_borealis',
    fallbackName: 'Cực Quang Aurora',
    fallbackDescription: 'Dải lụa cực quang huyền ảo với sự hòa quyện xanh ngọc và tím ma mị',
    backgroundColor: Color(0xFF071217),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0C2B2A), Color(0xFF0A1224), Color(0xFF211036)],
    ),
    surfaceColor: Color(0xFF143336),
    shutterAccent: Color(0xFF2DD4BF),
    frameBorderColor: Color(0xFF2DD4BF),
    frameGradient: LinearGradient(
      colors: [Color(0xFF2DD4BF), Color(0xFF38BDF8), Color(0xFFA855F7), Color(0xFFEC4899)],
    ),
    glassButtonBg: Color(0x400C2B2A),
    glassButtonBorder: Color(0x402DD4BF),
    themePreviewDots: [Color(0xFF2DD4BF), Color(0xFF38BDF8), Color(0xFFA855F7)],
  );

  static const CameraThemeData cherryBlossom = CameraThemeData(
    id: 'cherry_blossom',
    fallbackName: 'Hoa Anh Đào',
    fallbackDescription: 'Sắc hồng ngọt ngào, tươi trẻ kết hợp ánh đào quyến rũ',
    backgroundColor: Color(0xFF160910),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF331024), Color(0xFF14060E), Color(0xFF290C1B)],
    ),
    surfaceColor: Color(0xFF3F162E),
    shutterAccent: Color(0xFFFB7185),
    frameBorderColor: Color(0xFFF43F5E),
    frameGradient: LinearGradient(
      colors: [Color(0xFFFDA4AF), Color(0xFFFB7185), Color(0xFFF43F5E), Color(0xFFE11D48)],
    ),
    glassButtonBg: Color(0x40331024),
    glassButtonBorder: Color(0x40FB7185),
    themePreviewDots: [Color(0xFFFDA4AF), Color(0xFFFB7185), Color(0xFFE11D48)],
  );

  static const CameraThemeData galaxyNebula = CameraThemeData(
    id: 'galaxy_nebula',
    fallbackName: 'Tinh Vân Vũ Trụ',
    fallbackDescription: 'Chiều sâu vũ trụ huyền bí với ánh sáng tinh vân tím và lam điện',
    backgroundColor: Color(0xFF090818),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF241048), Color(0xFF09071A), Color(0xFF290B38)],
    ),
    surfaceColor: Color(0xFF2C1554),
    shutterAccent: Color(0xFFC084FC),
    frameBorderColor: Color(0xFF9333EA),
    frameGradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFFF43F5E)],
    ),
    glassButtonBg: Color(0x40241048),
    glassButtonBorder: Color(0x40C084FC),
    themePreviewDots: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
  );

  static const CameraThemeData lavaFire = CameraThemeData(
    id: 'lava_fire',
    fallbackName: 'Nham Thạch Núi Lửa',
    fallbackDescription: 'Ngọn lửa magma rực cháy với sắc đỏ rực và cam hoàng kim bùng nổ',
    backgroundColor: Color(0xFF140806),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF33100A), Color(0xFF110503), Color(0xFF2A0B06)],
    ),
    surfaceColor: Color(0xFF40160F),
    shutterAccent: Color(0xFFFF5722),
    frameBorderColor: Color(0xFFEA580C),
    frameGradient: LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFFBBF24)],
    ),
    glassButtonBg: Color(0x4033100A),
    glassButtonBorder: Color(0x40FF5722),
    themePreviewDots: [Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFFBBF24)],
  );

  static const CameraThemeData retroVaporwave = CameraThemeData(
    id: 'retro_vaporwave',
    fallbackName: 'Retro Vaporwave',
    fallbackDescription: 'Năng lượng thập niên 80 với sự pha trộn rực rỡ của hồng neon, lam ngọc và vàng',
    backgroundColor: Color(0xFF0C0E1A),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1F123D), Color(0xFF0A1429), Color(0xFF300E31)],
    ),
    surfaceColor: Color(0xFF251A48),
    shutterAccent: Color(0xFF22D3EE),
    frameBorderColor: Color(0xFFEC4899),
    frameGradient: LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFFFACC15)],
    ),
    glassButtonBg: Color(0x401F123D),
    glassButtonBorder: Color(0x4022D3EE),
    themePreviewDots: [Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFFFACC15)],
  );

  static const List<CameraThemeData> all = [
    classicDark,
    cyberNeon,
    sunsetGold,
    oceanBreeze,
    matchaZen,
    auroraBorealis,
    cherryBlossom,
    galaxyNebula,
    lavaFire,
    retroVaporwave,
  ];

  static CameraThemeData fromId(String? id) {
    if (id == null) return classicDark;
    for (final theme in all) {
      if (theme.id == id) return theme;
    }
    return classicDark;
  }
}
