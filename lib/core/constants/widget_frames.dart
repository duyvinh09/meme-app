import 'package:flutter/material.dart';

class WidgetFrameItem {
  final String id;
  final String nameVi;
  final String nameEn;
  final Gradient? gradient;
  final double borderWidth;

  const WidgetFrameItem({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    this.gradient,
    this.borderWidth = 3.5,
  });

  bool get isNone => id == 'none' || gradient == null;

  String getName(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return isVi ? nameVi : nameEn;
  }
}

class WidgetFrames {
  WidgetFrames._();

  static const List<WidgetFrameItem> all = [
    // 0. None (Không có)
    WidgetFrameItem(
      id: 'none',
      nameVi: 'Không có',
      nameEn: 'None',
      gradient: null,
      borderWidth: 1.0,
    ),

    // 1. Sunset Coral (Hoàng hôn)
    WidgetFrameItem(
      id: 'sunset_coral',
      nameVi: 'Hoàng hôn',
      nameEn: 'Sunset Coral',
      gradient: LinearGradient(
        colors: [Color(0xFFFF3366), Color(0xFFFF6B4A), Color(0xFFFF9F43)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 2. Amber Citrus (Cam hổ phách)
    WidgetFrameItem(
      id: 'amber_citrus',
      nameVi: 'Cam hổ phách',
      nameEn: 'Amber Citrus',
      gradient: LinearGradient(
        colors: [Color(0xFFFF7A00), Color(0xFFFFB800), Color(0xFFFFD600)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 3. Lemon Lime (Vàng chanh)
    WidgetFrameItem(
      id: 'lemon_lime',
      nameVi: 'Vàng chanh',
      nameEn: 'Lemon Lime',
      gradient: LinearGradient(
        colors: [Color(0xFFFFE600), Color(0xFFD4FF00), Color(0xFFA6FF00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 4. Fresh Mint (Bạc hà tươi)
    WidgetFrameItem(
      id: 'fresh_mint',
      nameVi: 'Bạc hà tươi',
      nameEn: 'Fresh Mint',
      gradient: LinearGradient(
        colors: [Color(0xFF00FF87), Color(0xFF60EFA0), Color(0xFF00E676)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 5. Cyan Aqua (Ngọc lam)
    WidgetFrameItem(
      id: 'cyan_aqua',
      nameVi: 'Ngọc lam',
      nameEn: 'Cyan Aqua',
      gradient: LinearGradient(
        colors: [Color(0xFF00F2FE), Color(0xFF4FACFE), Color(0xFF00D2FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 6. Electric Blue (Xanh điện)
    WidgetFrameItem(
      id: 'electric_blue',
      nameVi: 'Xanh điện',
      nameEn: 'Electric Blue',
      gradient: LinearGradient(
        colors: [Color(0xFF2979FF), Color(0xFF3D5AFE), Color(0xFF651FFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 7. Neon Purple (Tím Neon)
    WidgetFrameItem(
      id: 'neon_purple',
      nameVi: 'Tím Neon',
      nameEn: 'Neon Purple',
      gradient: LinearGradient(
        colors: [Color(0xFFB000FF), Color(0xFFD500F9), Color(0xFFF50057)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 8. Pastel Lavender (Kẹo bông)
    WidgetFrameItem(
      id: 'pastel_lavender',
      nameVi: 'Kẹo bông',
      nameEn: 'Pastel Lavender',
      gradient: LinearGradient(
        colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFF99AC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 9. Moonlight Ice (Băng tuyết)
    WidgetFrameItem(
      id: 'moonlight_ice',
      nameVi: 'Băng tuyết',
      nameEn: 'Moonlight Ice',
      gradient: LinearGradient(
        colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3), Color(0xFFB9D7EA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 10. Aurora Glow (Cực quang)
    WidgetFrameItem(
      id: 'aurora_glow',
      nameVi: 'Cực quang',
      nameEn: 'Aurora Glow',
      gradient: LinearGradient(
        colors: [Color(0xFF00FF87), Color(0xFF60EFA0), Color(0xFF6C5CE7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 11. Cyber Hologram (Hologram)
    WidgetFrameItem(
      id: 'cyber_hologram',
      nameVi: 'Hologram',
      nameEn: 'Cyber Hologram',
      gradient: LinearGradient(
        colors: [Color(0xFFFF007F), Color(0xFF7928CA), Color(0xFF00DFD8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 12. Golden Glow (Hoàng kim)
    WidgetFrameItem(
      id: 'golden_glow',
      nameVi: 'Hoàng kim',
      nameEn: 'Golden Glow',
      gradient: LinearGradient(
        colors: [Color(0xFFFFDF00), Color(0xFFFFB800), Color(0xFFFF8C00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 13. Deep Space (Vũ trụ)
    WidgetFrameItem(
      id: 'deep_space',
      nameVi: 'Vũ trụ',
      nameEn: 'Deep Space',
      gradient: LinearGradient(
        colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 14. Sweet Peach (Đào ngọt)
    WidgetFrameItem(
      id: 'sweet_peach',
      nameVi: 'Đào ngọt',
      nameEn: 'Sweet Peach',
      gradient: LinearGradient(
        colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4), Color(0xFFFED6E3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 15. Crimson Ruby (Hồng ngọc)
    WidgetFrameItem(
      id: 'crimson_ruby',
      nameVi: 'Hồng ngọc',
      nameEn: 'Crimson Ruby',
      gradient: LinearGradient(
        colors: [Color(0xFFFF0844), Color(0xFFFF4E50), Color(0xFFF9D423)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 16. Midnight Ocean (Biển đêm)
    WidgetFrameItem(
      id: 'midnight_ocean',
      nameVi: 'Biển đêm',
      nameEn: 'Midnight Ocean',
      gradient: LinearGradient(
        colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 17. Tropical Paradise (Nhiệt đới)
    WidgetFrameItem(
      id: 'tropical_paradise',
      nameVi: 'Nhiệt đới',
      nameEn: 'Tropical Paradise',
      gradient: LinearGradient(
        colors: [Color(0xFF00F5D4), Color(0xFF7B2CBF), Color(0xFFF72585)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 18. Berry Smoothie (Quả mọng)
    WidgetFrameItem(
      id: 'berry_smoothie',
      nameVi: 'Quả mọng',
      nameEn: 'Berry Smoothie',
      gradient: LinearGradient(
        colors: [Color(0xFFDA22FF), Color(0xFF9733EE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 19. Matcha Latte (Matcha)
    WidgetFrameItem(
      id: 'matcha_latte',
      nameVi: 'Matcha',
      nameEn: 'Matcha Latte',
      gradient: LinearGradient(
        colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 20. Cherry Blossom (Hoa anh đào)
    WidgetFrameItem(
      id: 'cherry_blossom',
      nameVi: 'Hoa anh đào',
      nameEn: 'Cherry Blossom',
      gradient: LinearGradient(
        colors: [Color(0xFFFBC2EB), Color(0xFFA6C1EE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 21. Volcano Flame (Lửa nham thạch)
    WidgetFrameItem(
      id: 'volcano_flame',
      nameVi: 'Nham thạch',
      nameEn: 'Volcano Flame',
      gradient: LinearGradient(
        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 22. Galaxy Dream (Ngân hà)
    WidgetFrameItem(
      id: 'galaxy_dream',
      nameVi: 'Ngân hà',
      nameEn: 'Galaxy Dream',
      gradient: LinearGradient(
        colors: [Color(0xFF654EA3), Color(0xFFEAAFC8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 23. Silver Chrome (Bạch kim)
    WidgetFrameItem(
      id: 'silver_chrome',
      nameVi: 'Bạch kim',
      nameEn: 'Silver Chrome',
      gradient: LinearGradient(
        colors: [Color(0xFFECE9E6), Color(0xFFFFFFFF), Color(0xFFB0B7C3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 24. Rose Gold (Vàng hồng)
    WidgetFrameItem(
      id: 'rose_gold',
      nameVi: 'Vàng hồng',
      nameEn: 'Rose Gold',
      gradient: LinearGradient(
        colors: [Color(0xFFF4C4F3), Color(0xFFFC67FA), Color(0xFFF9D29D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 25. Candy Pop (Kẹo ngọt)
    WidgetFrameItem(
      id: 'candy_pop',
      nameVi: 'Kẹo ngọt',
      nameEn: 'Candy Pop',
      gradient: LinearGradient(
        colors: [Color(0xFFFF007F), Color(0xFFFFD700), Color(0xFF00E5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 26. Emerald Forest (Rừng ngọc)
    WidgetFrameItem(
      id: 'emerald_forest',
      nameVi: 'Rừng ngọc',
      nameEn: 'Emerald Forest',
      gradient: LinearGradient(
        colors: [Color(0xFF134E5E), Color(0xFF71B280)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    // 27. Twilight Sunset (Hoàng hôn tím)
    WidgetFrameItem(
      id: 'twilight_sunset',
      nameVi: 'Hoàng hôn tím',
      nameEn: 'Twilight Sunset',
      gradient: LinearGradient(
        colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  static WidgetFrameItem getById(String? id) {
    if (id == null || id.isEmpty || id == 'none') {
      return all.first;
    }
    return all.firstWhere(
      (f) => f.id == id,
      orElse: () => all.first,
    );
  }
}
