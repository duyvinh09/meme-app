import 'package:flutter/material.dart';

enum DailyTimeSlot {
  lateNight,     // 00:00 - 02:59
  dawn,          // 03:00 - 04:59
  earlyMorning,  // 05:00 - 06:59
  morningRush,   // 07:00 - 08:59
  focusWork,     // 09:00 - 10:59
  lunchTime,     // 11:00 - 12:59
  napRecharge,   // 13:00 - 14:29
  afternoon,     // 14:30 - 16:29
  afterWork,     // 16:30 - 18:29
  dinner,        // 18:30 - 19:59
  freeTime,      // 20:00 - 21:59
  windDown,      // 22:00 - 23:59
}

enum DailyMomentCategory {
  specialEvent,
  spendingEvent,
  streakEvent,
  dayOfWeekEvent,
  timeOfDayEvent,
}

class DailyMood {
  final String icon;
  final String label;
  final Color accentColor;

  const DailyMood({
    required this.icon,
    required this.label,
    required this.accentColor,
  });
}

class DailyMomentData {
  final String greetingIcon;
  final String greetingText;
  final String? subGreeting;
  final DailyMood mood;
  final DailyMomentCategory category;
  final DailyTimeSlot timeSlot;

  const DailyMomentData({
    required this.greetingIcon,
    required this.greetingText,
    this.subGreeting,
    required this.mood,
    required this.category,
    required this.timeSlot,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMomentData &&
          runtimeType == other.runtimeType &&
          greetingIcon == other.greetingIcon &&
          greetingText == other.greetingText &&
          subGreeting == other.subGreeting &&
          mood.label == other.mood.label;

  @override
  int get hashCode => Object.hash(greetingIcon, greetingText, subGreeting, mood.label);
}
