import 'package:flutter/material.dart';

class AppIconRegistry {
  const AppIconRegistry._();

  /// Rebuild an icon from persisted Material icon code point.
  /// Falls back to wallet icon when stored value is invalid.
  static IconData fromCodePoint(int codePoint) {
    if (codePoint <= 0) {
      return Icons.account_balance_wallet_outlined;
    }

    return IconData(
      codePoint,
      fontFamily: 'MaterialIcons',
    );
  }
}
