import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle appTitle(BuildContext context) {
    return TextStyle(
      color: AppColors.textPrimary(context),
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.6,
      height: 1.05,
    );
  }

  static TextStyle pageTitle(BuildContext context) {
    return TextStyle(
      color: AppColors.textPrimary(context),
      fontSize: 28,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.4,
      height: 1.1,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return TextStyle(
      color: AppColors.textPrimary(context),
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      height: 1.15,
    );
  }

  static TextStyle cardTitle(BuildContext context) {
    return TextStyle(
      color: AppColors.textPrimary(context),
      fontSize: 17,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );
  }

  static TextStyle body(BuildContext context) {
    return TextStyle(
      color: AppColors.textPrimary(context),
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );
  }

  static TextStyle bodySecondary(BuildContext context) {
    return TextStyle(
      color: AppColors.textSecondary(context),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );
  }

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      color: AppColors.textSecondary(context),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
  }

  static TextStyle button() {
    return const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1,
    );
  }

  static TextStyle navLabel({
    required bool selected,
    required Color color,
  }) {
    return TextStyle(
      color: color,
      fontSize: selected ? 11.0 : 10.2,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      height: 1,
      letterSpacing: -0.2,
    );
  }
}