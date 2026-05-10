import 'package:intl/intl.dart';

import '../services/exchange_rate_service.dart';

class AppCurrencyFormatter {
  AppCurrencyFormatter._();

  static String normalizeCurrency(String? currency) {
    final value = (currency ?? 'VND').toUpperCase();

    if (value == 'USD') return 'USD';
    return 'VND';
  }

  static String symbol(String? currency) {
    switch (normalizeCurrency(currency)) {
      case 'USD':
        return '\$';
      case 'VND':
      default:
        return '₫';
    }
  }

  static double currentUsdToVndRate() {
    return ExchangeRateService.usdToVndRate;
  }

  static double fromVnd({
    required double amountVnd,
    required String? currency,
  }) {
    switch (normalizeCurrency(currency)) {
      case 'USD':
        return amountVnd / currentUsdToVndRate();
      case 'VND':
      default:
        return amountVnd;
    }
  }

  static double toVnd({
    required double inputAmount,
    required String? currency,
  }) {
    switch (normalizeCurrency(currency)) {
      case 'USD':
        return inputAmount * currentUsdToVndRate();
      case 'VND':
      default:
        return inputAmount;
    }
  }

  /// After formatting, counts only ASCII digits `0–9`. If count exceeds [maxDigits],
  /// trims before the excess digit(s), strips a dangling thousands/decimal delimiter,
  /// then appends `'...'`.
  static String truncateFormattedMoneyDigits(String formatted, int maxDigits) {
    if (maxDigits <= 0 || formatted.isEmpty) return formatted;

    var digitCount = 0;
    var cutBeforeIndex = formatted.length;

    for (var i = 0; i < formatted.length; i++) {
      final cu = formatted.codeUnitAt(i);
      final isAsciiDigit = cu >= 0x30 && cu <= 0x39;
      if (!isAsciiDigit) continue;

      digitCount++;
      if (digitCount > maxDigits) {
        cutBeforeIndex = i;
        break;
      }
    }

    if (digitCount <= maxDigits) return formatted;

    var prefix = formatted.substring(0, cutBeforeIndex);
    prefix = prefix.replaceAll(RegExp(r'[\s.,\u00a0]+$'), '');
    return '$prefix...';
  }

  static String formatFromVnd({
    required double amountVnd,
    required String? currency,
  }) {
    final currentCurrency = normalizeCurrency(currency);
    final displayAmount = fromVnd(
      amountVnd: amountVnd,
      currency: currentCurrency,
    );

    if (currentCurrency == 'USD') {
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: '\$',
        decimalDigits: displayAmount >= 100 ? 0 : 2,
      ).format(displayAmount);
    }

    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(displayAmount);
  }

  static String formatInputHint(String? currency) {
    switch (normalizeCurrency(currency)) {
      case 'USD':
        return '0.00';
      case 'VND':
      default:
        return '0';
    }
  }

  static String rateText() {
    final rate = NumberFormat.decimalPattern('vi_VN').format(
      currentUsdToVndRate().round(),
    );

    return '1 USD ≈ $rate₫';
  }
}