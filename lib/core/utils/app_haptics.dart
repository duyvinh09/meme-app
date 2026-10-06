import 'package:flutter/services.dart';

/// Centralized Haptic Feedback utility for Meme application.
/// Respects the user's toggle setting from LocalSettingsService / Profile.
class AppHaptics {
  AppHaptics._();

  static bool isEnabled = true;

  /// Trigger a light impact (for button taps, card presses, subtle feedback).
  static void lightImpact() {
    if (!isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Trigger a medium impact (for confirmations, deletions, major milestones).
  static void mediumImpact() {
    if (!isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Trigger a heavy impact (for alerts, milestone celebrations).
  static void heavyImpact() {
    if (!isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Trigger a selection click (for scrolling pickers, tabs, toggles).
  static void selectionClick() {
    if (!isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Trigger a standard vibrate.
  static void vibrate() {
    if (!isEnabled) return;
    HapticFeedback.vibrate();
  }
}
