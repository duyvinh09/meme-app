import 'package:flutter/material.dart';

enum MilestoneTier {
  /// 3, 10 days - Early milestone (warm glow, gentle bounce, few sparkles)
  tier1,

  /// 30, 60 days - Growing streak (expanding glow ring, smooth floating particles, richer aura)
  tier2,

  /// 100, 200 days - Major milestone (radial light burst, rotating aura, ambient floating particles)
  tier3,

  /// 300, 400, 500, 600+ days - Legendary milestone (cosmic/gold radial rays, shockwaves, multi-tier particles)
  tier4,
}

class StreakMilestone {
  final int days;
  final MilestoneTier tier;
  final String titleVi;
  final String titleEn;
  final String messageVi;
  final String messageEn;
  final Color primaryColor;
  final Color secondaryColor;
  final Color glowColor;
  final String? avatarFrameId;

  const StreakMilestone({
    required this.days,
    required this.tier,
    required this.titleVi,
    required this.titleEn,
    required this.messageVi,
    required this.messageEn,
    this.primaryColor = const Color(0xFFFF5722),
    this.secondaryColor = const Color(0xFFFF9800),
    this.glowColor = const Color(0xFFFF5722),
    this.avatarFrameId,
  });

  String getTitle(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return isVi ? titleVi : titleEn;
  }

  String getMessage(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return isVi ? messageVi : messageEn;
  }
}

class StreakMilestones {
  StreakMilestones._();

  static const List<StreakMilestone> all = [
    // 3 Days - Tier 1
    StreakMilestone(
      days: 3,
      tier: MilestoneTier.tier1,
      titleVi: 'Khởi đầu rực rỡ',
      titleEn: 'Bright Beginning',
      messageVi: 'Bạn đã cùng mình đi qua 3 ngày rồi.',
      messageEn: 'You’ve walked through 3 days with me already.',
      primaryColor: Color(0xFFFF6B4A),
      secondaryColor: Color(0xFFFF9E43),
      glowColor: Color(0xFFFF6B4A),
      avatarFrameId: 'gradient',
    ),

    // 10 Days - Tier 1
    StreakMilestone(
      days: 10,
      tier: MilestoneTier.tier1,
      titleVi: 'Thói quen gắn kết',
      titleEn: 'Bonding Habit',
      messageVi: '10 ngày rồi đó, chúng ta vẫn còn ở đây cùng nhau.',
      messageEn: '10 days already, and we’re still here side by side.',
      primaryColor: Color(0xFFFF416C),
      secondaryColor: Color(0xFFFF8B3D),
      glowColor: Color(0xFFFF416C),
      avatarFrameId: 'flame',
    ),

    // 30 Days - Tier 2
    StreakMilestone(
      days: 30,
      tier: MilestoneTier.tier2,
      titleVi: 'Một tháng trọn vẹn',
      titleEn: 'One Whole Month',
      messageVi: '30 ngày bên nhau. Một tháng rồi đấy.',
      messageEn: '30 days together. A whole beautiful month already.',
      primaryColor: Color(0xFF00E676),
      secondaryColor: Color(0xFF00B0FF),
      glowColor: Color(0xFF00E676),
      avatarFrameId: 'sparkle',
    ),

    // 60 Days - Tier 2
    StreakMilestone(
      days: 60,
      tier: MilestoneTier.tier2,
      titleVi: 'Hai tháng đồng hành',
      titleEn: 'Two Months Strong',
      messageVi: '60 ngày rồi. Cảm ơn vì vẫn cùng mình lưu lại những khoảnh khắc này.',
      messageEn: '60 days already. Thank you for capturing these moments with me.',
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF7C4DFF),
      glowColor: Color(0xFF00E5FF),
      avatarFrameId: 'aurora',
    ),

    // 100 Days - Tier 3
    StreakMilestone(
      days: 100,
      tier: MilestoneTier.tier3,
      titleVi: 'Hành trình thế kỷ',
      titleEn: 'Centennial Journey',
      messageVi: '100 ngày. Không còn là một chuỗi nữa, đây đã là một hành trình.',
      messageEn: '100 days. No longer just a streak, this is now a journey.',
      primaryColor: Color(0xFFFF0080),
      secondaryColor: Color(0xFF7928CA),
      glowColor: Color(0xFFFF0080),
      avatarFrameId: 'cosmic',
    ),

    // 200 Days - Tier 3
    StreakMilestone(
      days: 200,
      tier: MilestoneTier.tier3,
      titleVi: 'Câu chuyện rực rỡ',
      titleEn: 'Radiant Story',
      messageVi: '200 ngày bên nhau. Từng khoảnh khắc nhỏ đã thành một câu chuyện lớn.',
      messageEn: '200 days together. Every little moment has become a grand story.',
      primaryColor: Color(0xFFFF6B00),
      secondaryColor: Color(0xFFFFE600),
      glowColor: Color(0xFFFF6B00),
      avatarFrameId: 'solar',
    ),

    // 300 Days - Tier 4
    StreakMilestone(
      days: 300,
      tier: MilestoneTier.tier4,
      titleVi: 'Thần thoại kim cương',
      titleEn: 'Diamond Mythic',
      messageVi: '300 ngày. Chúng ta đã đi cùng nhau lâu hơn rất nhiều điều khác.',
      messageEn: '300 days. We’ve stayed together longer than so many other things.',
      primaryColor: Color(0xFF30CFD0),
      secondaryColor: Color(0xFFFA709A),
      glowColor: Color(0xFF30CFD0),
      avatarFrameId: 'mythic',
    ),

    // 400 Days - Tier 4
    StreakMilestone(
      days: 400,
      tier: MilestoneTier.tier4,
      titleVi: 'Ngọn lửa bất diệt',
      titleEn: 'Immortal Flame',
      messageVi: '400 ngày rồi. Cảm ơn vì vẫn chưa để chuỗi này kết thúc.',
      messageEn: '400 days already. Thank you for never letting this streak end.',
      primaryColor: Color(0xFFFF0055),
      secondaryColor: Color(0xFFFFD700),
      glowColor: Color(0xFFFF0055),
      avatarFrameId: 'phoenix',
    ),

    // 500 Days - Tier 4
    StreakMilestone(
      days: 500,
      tier: MilestoneTier.tier4,
      titleVi: 'Kỷ nguyên vàng son',
      titleEn: 'Golden Era',
      messageVi: '500 ngày bên nhau. Đây không còn chỉ là một con số nữa.',
      messageEn: '500 days together. This is no longer just a number.',
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFF00F260),
      glowColor: Color(0xFFFFD700),
      avatarFrameId: 'dragon',
    ),

    // 600 Days - Tier 4
    StreakMilestone(
      days: 600,
      tier: MilestoneTier.tier4,
      titleVi: 'Bất tử tối thượng',
      titleEn: 'Eternal Transcendence',
      messageVi: '600 ngày đồng hành. Một chặng đường vô giá mà chúng ta cùng tạo nên.',
      messageEn: '600 days together. An invaluable journey we have created side by side.',
      primaryColor: Color(0xFF00FFFF),
      secondaryColor: Color(0xFFFF00FF),
      glowColor: Color(0xFF00FFFF),
      avatarFrameId: 'eternal',
    ),
  ];

  static StreakMilestone? getMilestone(int streak) {
    for (final m in all) {
      if (m.days == streak) {
        return m;
      }
    }
    return null;
  }

  /// Checks if reaching [newStreak] from [oldStreak] unlocks a new milestone that has not yet been unlocked in [unlockedMilestones].
  static StreakMilestone? checkNewMilestone({
    required int oldStreak,
    required int newStreak,
    required List<int> unlockedMilestones,
  }) {
    if (newStreak <= oldStreak) return null;

    for (final m in all) {
      if (newStreak >= m.days && oldStreak < m.days && !unlockedMilestones.contains(m.days)) {
        return m;
      }
      // Exact hit check
      if (newStreak == m.days && !unlockedMilestones.contains(m.days)) {
        return m;
      }
    }
    return null;
  }
}
