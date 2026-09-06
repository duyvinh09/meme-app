import 'package:flutter/widgets.dart';

extension ResponsiveExtension on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  double get paddingTop => mediaQuery.padding.top;
  double get paddingBottom => mediaQuery.padding.bottom;

  bool get isSmallPhone => screenWidth < 370;
  bool get isMediumPhone => screenWidth >= 370 && screenWidth < 414;
  bool get isLargePhone => screenWidth >= 414 && screenWidth < 600;
  bool get isTablet => screenWidth >= 600;

  bool get isShortScreen => screenHeight < 720;
  bool get isVeryShortScreen => screenHeight < 640;

  /// Returns a responsive value based on current device screen width.
  T responsiveValue<T>({
    required T normal,
    T? small,
    T? large,
    T? tablet,
  }) {
    if (isTablet && tablet != null) return tablet;
    if (isSmallPhone && small != null) return small;
    if (isLargePhone && large != null) return large;
    return normal;
  }

  /// Proportional scaling helper relative to standard 390px design width.
  double scaleWidth(double value, {double min = 0.8, double max = 1.25}) {
    final scale = (screenWidth / 390.0).clamp(min, max);
    return value * scale;
  }

  /// Proportional scaling helper relative to standard 844px design height.
  double scaleHeight(double value, {double min = 0.8, double max = 1.25}) {
    final scale = (screenHeight / 844.0).clamp(min, max);
    return value * scale;
  }
}
