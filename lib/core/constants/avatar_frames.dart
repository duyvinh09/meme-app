import 'package:flutter/material.dart';

class AvatarFrameItem {
  final String id;
  final String nameVi;
  final String nameEn;
  final int requiredStreak;
  final Gradient gradient;
  final Color glowColor;
  final Color? secondaryGlowColor;
  final double borderWidth;
  final IconData? badgeIcon;
  final Color? badgeColor;

  const AvatarFrameItem({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.requiredStreak,
    required this.gradient,
    required this.glowColor,
    this.secondaryGlowColor,
    this.borderWidth = 3.0,
    this.badgeIcon,
    this.badgeColor,
  });

  String getName(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return isVi ? nameVi : nameEn;
  }

  String get name => nameVi;

  bool isUnlocked(int streak, {int bestStreak = 0}) =>
      streak >= requiredStreak || bestStreak >= requiredStreak;
}

class AvatarFrames {
  AvatarFrames._();

  static const List<AvatarFrameItem> all = [
    // 0 Days: Plain / Trơn
    AvatarFrameItem(
      id: 'plain',
      nameVi: 'Trơn',
      nameEn: 'Classic',
      requiredStreak: 0,
      gradient: LinearGradient(
        colors: [Color(0xFF8E95A5), Color(0xFF6B7280)],
      ),
      glowColor: Colors.transparent,
      borderWidth: 1.8,
    ),

    // 3 Days: Gradient / Neon Pulse
    AvatarFrameItem(
      id: 'gradient',
      nameVi: 'Gradient',
      nameEn: 'Neon Pulse',
      requiredStreak: 3,
      gradient: SweepGradient(
        colors: [
          Color(0xFF00F2FE),
          Color(0xFF4FACFE),
          Color(0xFFFF7AD9),
          Color(0xFF9B51E0),
          Color(0xFF00F2FE),
        ],
      ),
      glowColor: Color(0xFF4FACFE),
      borderWidth: 3.0,
    ),

    // 10 Days: Flame / Ngọn Lửa
    AvatarFrameItem(
      id: 'flame',
      nameVi: 'Ngọn Lửa',
      nameEn: 'Fire Flame',
      requiredStreak: 10,
      gradient: SweepGradient(
        colors: [
          Color(0xFFFFD200),
          Color(0xFFF7971E),
          Color(0xFFFF416C),
          Color(0xFFFF4B2B),
          Color(0xFFFFD200),
        ],
      ),
      glowColor: Color(0xFFFF5722),
      borderWidth: 3.2,
      badgeIcon: Icons.local_fire_department_rounded,
      badgeColor: Color(0xFFFF5722),
    ),

    // 30 Days: Sparkle / Tinh Tú
    AvatarFrameItem(
      id: 'sparkle',
      nameVi: 'Tinh Tú',
      nameEn: 'Sparkle Star',
      requiredStreak: 30,
      gradient: SweepGradient(
        colors: [
          Color(0xFF00F5A0),
          Color(0xFF00D9F5),
          Color(0xFF11998E),
          Color(0xFF38EF7D),
          Color(0xFF00F5A0),
        ],
      ),
      glowColor: Color(0xFF00E676),
      borderWidth: 3.2,
      badgeIcon: Icons.auto_awesome_rounded,
      badgeColor: Color(0xFF00E676),
    ),

    // 60 Days: Aurora / Cực Quang
    AvatarFrameItem(
      id: 'aurora',
      nameVi: 'Cực Quang',
      nameEn: 'Aurora Borealis',
      requiredStreak: 60,
      gradient: SweepGradient(
        colors: [
          Color(0xFF4E65FF),
          Color(0xFF92EFFD),
          Color(0xFF38EF7D),
          Color(0xFF8A2387),
          Color(0xFF4E65FF),
        ],
      ),
      glowColor: Color(0xFF00E5FF),
      secondaryGlowColor: Color(0xFF38EF7D),
      borderWidth: 3.4,
      badgeIcon: Icons.wb_twilight_rounded,
      badgeColor: Color(0xFF00E5FF),
    ),

    // 100 Days: Cosmic Nebula / Vũ Trụ Huyền Bí (100+ Tier)
    AvatarFrameItem(
      id: 'cosmic',
      nameVi: 'Vũ Trụ',
      nameEn: 'Cosmic Nebula',
      requiredStreak: 100,
      gradient: SweepGradient(
        colors: [
          Color(0xFF8A2387),
          Color(0xFFFF0080),
          Color(0xFF00DFD8),
          Color(0xFF7928CA),
          Color(0xFFF27121),
          Color(0xFF8A2387),
        ],
      ),
      glowColor: Color(0xFFFF0080),
      secondaryGlowColor: Color(0xFF7928CA),
      borderWidth: 3.6,
      badgeIcon: Icons.auto_awesome_rounded,
      badgeColor: Color(0xFFFF0080),
    ),

    // 200 Days: Solar Flare / Bão Mặt Trời (200+ Tier)
    AvatarFrameItem(
      id: 'solar',
      nameVi: 'Thái Dương',
      nameEn: 'Solar Flare',
      requiredStreak: 200,
      gradient: SweepGradient(
        colors: [
          Color(0xFFFFE600),
          Color(0xFFFF6B00),
          Color(0xFFFF0844),
          Color(0xFFFFB199),
          Color(0xFFFFE000),
          Color(0xFFFFE600),
        ],
      ),
      glowColor: Color(0xFFFF6B00),
      secondaryGlowColor: Color(0xFFFFE600),
      borderWidth: 3.8,
      badgeIcon: Icons.wb_sunny_rounded,
      badgeColor: Color(0xFFFFE600),
    ),

    // 300 Days: Mythic Prism / Thần Thoại Kim Cương (300+ Tier)
    AvatarFrameItem(
      id: 'mythic',
      nameVi: 'Thần Thoại',
      nameEn: 'Mythic Prism',
      requiredStreak: 300,
      gradient: SweepGradient(
        colors: [
          Color(0xFFFA709A),
          Color(0xFFFEE140),
          Color(0xFF30CFD0),
          Color(0xFF667EEA),
          Color(0xFF764BA2),
          Color(0xFFFA709A),
        ],
      ),
      glowColor: Color(0xFF30CFD0),
      secondaryGlowColor: Color(0xFFFA709A),
      borderWidth: 4.0,
      badgeIcon: Icons.diamond_rounded,
      badgeColor: Color(0xFF30CFD0),
    ),

    // 400 Days: Phoenix Blaze / Phượng Hoàng Lửa (400+ Tier NEW)
    AvatarFrameItem(
      id: 'phoenix',
      nameVi: 'Phượng Hoàng',
      nameEn: 'Phoenix Blaze',
      requiredStreak: 400,
      gradient: SweepGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFF3300),
          Color(0xFFFF0055),
          Color(0xFF9900FF),
          Color(0xFFFF9900),
          Color(0xFFFFD700),
        ],
      ),
      glowColor: Color(0xFFFF0055),
      secondaryGlowColor: Color(0xFFFFD700),
      borderWidth: 4.2,
      badgeIcon: Icons.whatshot_rounded,
      badgeColor: Color(0xFFFF3300),
    ),

    // 500 Days: Dragon Sovereign / Long Vương Hoàng Kim (500+ Tier NEW)
    AvatarFrameItem(
      id: 'dragon',
      nameVi: 'Long Vương',
      nameEn: 'Dragon Sovereign',
      requiredStreak: 500,
      gradient: SweepGradient(
        colors: [
          Color(0xFFFFE259),
          Color(0xFFFFA751),
          Color(0xFF00F260),
          Color(0xFF0575E6),
          Color(0xFFFFD700),
          Color(0xFFFFE259),
        ],
      ),
      glowColor: Color(0xFFFFD700),
      secondaryGlowColor: Color(0xFF00F260),
      borderWidth: 4.4,
      badgeIcon: Icons.military_tech_rounded,
      badgeColor: Color(0xFFFFD700),
    ),

    // 600 Days: Eternal Transcendence / Bất Tử Tối Thượng (600+ Tier NEW)
    AvatarFrameItem(
      id: 'eternal',
      nameVi: 'Bất Tử',
      nameEn: 'Eternal Deity',
      requiredStreak: 600,
      gradient: SweepGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFF00FFFF),
          Color(0xFFFF00FF),
          Color(0xFFFFE600),
          Color(0xFF8A2387),
          Color(0xFF0072FF),
          Color(0xFFFFFFFF),
        ],
      ),
      glowColor: Color(0xFF00FFFF),
      secondaryGlowColor: Color(0xFFFF00FF),
      borderWidth: 4.6,
      badgeIcon: Icons.workspace_premium_rounded,
      badgeColor: Color(0xFFFFE600),
    ),
  ];

  static AvatarFrameItem getById(String? id) {
    if (id == null || id.isEmpty || id == 'default') {
      return all.first;
    }
    return all.firstWhere(
      (f) => f.id == id,
      orElse: () => all.first,
    );
  }

  static String getValidFrameId(String? id, int streak, {int bestStreak = 0}) {
    if (id == null || id.isEmpty || id == 'default' || id == 'plain') {
      return 'plain';
    }
    final frame = getById(id);
    if (!frame.isUnlocked(streak, bestStreak: bestStreak)) {
      return 'plain';
    }
    return frame.id;
  }

  static AvatarFrameItem? getNextMilestone(int currentStreak, {int bestStreak = 0}) {
    final highest = currentStreak > bestStreak ? currentStreak : bestStreak;
    for (final frame in all) {
      if (frame.requiredStreak > highest) {
        return frame;
      }
    }
    return null;
  }

  static int getUnlockedCount(int currentStreak, {int bestStreak = 0}) {
    return all.where((f) => f.isUnlocked(currentStreak, bestStreak: bestStreak)).length;
  }
}
