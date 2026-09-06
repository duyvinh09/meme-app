import 'dart:convert';

class LocketConfig {
  LocketConfig._();

  // Danh sách Pool tài khoản để xoay vòng (Email | Password) lấy từ biến môi trường LOCKET_ACCOUNTS
  static List<Map<String, String>> get accounts {
    const raw = String.fromEnvironment('LOCKET_ACCOUNTS', defaultValue: '');
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((item) => Map<String, String>.from(item as Map))
              .toList();
        }
      } catch (_) {
        // Hỗ trợ định dạng email:password,email:password
        final list = <Map<String, String>>[];
        for (final pair in raw.split(',')) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            list.add({'email': parts[0].trim(), 'password': parts[1].trim()});
          }
        }
        if (list.isNotEmpty) return list;
      }
    }
    return const [];
  }

  static const String firebaseApiKey = String.fromEnvironment(
    'LOCKET_FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseGmpId = String.fromEnvironment(
    'LOCKET_FIREBASE_GMP_ID',
    defaultValue: '',
  );

  static const String firebaseAppCheck = String.fromEnvironment(
    'LOCKET_FIREBASE_APP_CHECK',
    defaultValue: '',
  );

  static const String sentryTrace = String.fromEnvironment(
    'LOCKET_SENTRY_TRACE',
    defaultValue: '',
  );

  static const String userAgentAuth = String.fromEnvironment(
    'LOCKET_USER_AGENT_AUTH',
    defaultValue:
        'FirebaseAuth.iOS/10.23.1 com.locket.Locket/2.61.1 iPhone/26.6.1 hw/iPhone14_5 (GTMSUF/1)',
  );

  static const String userAgentStorage = String.fromEnvironment(
    'LOCKET_USER_AGENT_STORAGE',
    defaultValue:
        'com.locket.Locket/2.61.1 iPhone/26.6.1 hw/iPhone14_5 (GTMSUF/1)',
  );

  static const String userAgentClient = String.fromEnvironment(
    'LOCKET_USER_AGENT_CLIENT',
    defaultValue: 'com.locket.Locket/2.61.1 iPhone/26.6.1 hw/iPhone14_5',
  );
}