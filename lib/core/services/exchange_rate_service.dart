import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  ExchangeRateService._();

  static const String _rateKey = 'usd_to_vnd_rate';
  static const String _updatedAtKey = 'usd_to_vnd_updated_at';

  static const double fallbackUsdToVndRate = 25000;

  static double _cachedUsdToVndRate = fallbackUsdToVndRate;
  static DateTime? _cachedUpdatedAt;

  static double get usdToVndRate => _cachedUsdToVndRate;

  static DateTime? get updatedAt => _cachedUpdatedAt;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _cachedUsdToVndRate =
        prefs.getDouble(_rateKey) ?? fallbackUsdToVndRate;

    final updatedAtMillis = prefs.getInt(_updatedAtKey);
    if (updatedAtMillis != null) {
      _cachedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);
    }

    await refreshIfNeeded();
  }

  static Future<double> refreshIfNeeded() async {
    final now = DateTime.now();

    if (_cachedUpdatedAt != null) {
      final diff = now.difference(_cachedUpdatedAt!);

      if (diff.inHours < 6) {
        return _cachedUsdToVndRate;
      }
    }

    return refresh();
  }

  static Future<double> refresh() async {
    try {
      final uri = Uri.parse(
        'https://open.er-api.com/v6/latest/USD',
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return _cachedUsdToVndRate;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      final result = json['result']?.toString();
      final rates = json['rates'];

      if (result != 'success' || rates is! Map<String, dynamic>) {
        return _cachedUsdToVndRate;
      }

      final vndValue = rates['VND'];

      if (vndValue is! num || vndValue <= 0) {
        return _cachedUsdToVndRate;
      }

      _cachedUsdToVndRate = vndValue.toDouble();
      _cachedUpdatedAt = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_rateKey, _cachedUsdToVndRate);
      await prefs.setInt(
        _updatedAtKey,
        _cachedUpdatedAt!.millisecondsSinceEpoch,
      );

      return _cachedUsdToVndRate;
    } catch (_) {
      return _cachedUsdToVndRate;
    }
  }
}