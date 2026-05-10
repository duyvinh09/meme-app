import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF79AFFF);
  static const Color primaryBlueDark = Color(0xFF4A90E2);
  static const Color primaryPurple = Color(0xFF8B7CFF);
  static const Color primaryPink = Color(0xFFFF7AD9);

  static const Color income = Color(0xFF36B66C);
  static const Color incomeSoft = Color(0xFFE9FBEF);

  static const Color expense = Color(0xFFFF7A7A);
  static const Color expenseDark = Color(0xFFD84B4B);
  static const Color expenseSoft = Color(0xFFFFEEEE);

  static const Color warning = Color(0xFFFFC857);
  static const Color gift = Color(0xFFFF4D4D);

  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightCard = Colors.white;
  static const Color lightSurface = Color(0xFFF7F9FC);
  static const Color lightBorder = Color(0xFFE3E7F0);
  static const Color lightInnerBorder = Color(0xFFE8ECF3);
  static const Color lightTextPrimary = Color(0xFF14151B);
  static const Color lightTextSecondary = Color(0xFF74788A);

  static const Color darkBackground = Color(0xFF090A0F);
  static const Color darkCard = Color(0xFF141722);
  static const Color darkSurface = Color(0xFF171A26);
  static const Color darkBorder = Color(0xFF2A2D3B);
  static const Color darkInnerBorder = Color(0xFF222636);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA3A6B2);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context) ? darkBackground : lightBackground;
  }

  static Color card(BuildContext context) {
    return isDark(context) ? darkCard : lightCard;
  }

  static Color surface(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static Color innerBorder(BuildContext context) {
    return isDark(context) ? darkInnerBorder : lightInnerBorder;
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : lightTextPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }

  static Color subtleOverlay(BuildContext context) {
    return isDark(context)
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.035);
  }

  static Color glassBackground(BuildContext context) {
    return isDark(context)
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.18);
  }

  static Color glassBorder(BuildContext context) {
    return isDark(context)
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.08);
  }

  /// Readable foreground on an arbitrary accent color (buttons, icon grids).
  static Color foregroundOnAccent(Color accent) {
    return accent.computeLuminance() > 0.56
        ? const Color(0xFF18181B)
        : Colors.white;
  }
}