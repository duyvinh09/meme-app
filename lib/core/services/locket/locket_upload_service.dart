import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'locket_config.dart';

class LocketAuthSession {
  final String email;
  final String idToken;
  final String refreshToken;
  final String localId;
  final int expiresAt; // Epoch timestamp (seconds)

  const LocketAuthSession({
    required this.email,
    required this.idToken,
    required this.refreshToken,
    required this.localId,
    required this.expiresAt,
  });

  bool get isValid {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (expiresAt - now) > 300; // Còn hạn trên 5 phút
  }
}

class LocketUploadResult {
  final String fileType;
  final String fileName;
  final String storagePath;
  final String bucket;
  final String downloadUrl;
  final String? md5Hex;
  final String? downloadToken;

  const LocketUploadResult({
    required this.fileType,
    required this.fileName,
    required this.storagePath,
    required this.bucket,
    required this.downloadUrl,
    this.md5Hex,
    this.downloadToken,
  });

  Map<String, dynamic> toMap() => {
    'fileType': fileType,
    'fileName': fileName,
    'storagePath': storagePath,
    'bucket': bucket,
    'downloadUrl': downloadUrl,
    'md5Hex': md5Hex,
    'downloadToken': downloadToken,
  };

  @override
  String toString() => const JsonEncoder.withIndent('  ').convert(toMap());
}

class LocketUploadService {
  // Singleton pattern để dùng chung cache session trong suốt vòng đời app
  static final LocketUploadService _instance = LocketUploadService._internal();
  factory LocketUploadService({http.Client? client}) {
    if (client != null) _instance._client = client;
    return _instance;
  }
  LocketUploadService._internal() : _client = http.Client();

  http.Client _client;

  // Cache token theo email (Tương đương tokens_cache.json)
  final Map<String, LocketAuthSession> _tokenCache = {};
  LocketAuthSession? _currentSession;

  static const Set<String> _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const Set<String> _videoExtensions = {'.mp4', '.mov', '.avi'};

  /// Đăng nhập trực tiếp lấy idToken và refreshToken
  Future<LocketAuthSession?> _loginDirectly(Map<String, String> account) async {
    final email = account['email'];
    final password = account['password'];
    if (email == null || password == null) return null;

    final uri = Uri.parse(
      'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=${LocketConfig.firebaseApiKey}',
    );

    final response = await _client.post(
      uri,
      headers: {
        'Accept': '*/*',
        'Accept-Language': 'vi-VN,vi;q=0.9',
        'Content-Type': 'application/json',
        'User-Agent': LocketConfig.userAgentAuth,
        'X-Client-Version': 'iOS/FirebaseSDK/10.23.1/FirebaseCore-iOS',
        'X-Firebase-AppCheck': LocketConfig.firebaseAppCheck,
        'X-Firebase-GMPID': LocketConfig.firebaseGmpId,
        'sentry-trace': LocketConfig.sentryTrace,
        'X-Ios-Bundle-Identifier': 'com.locket.Locket',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'clientType': 'CLIENT_TYPE_IOS',
        'returnSecureToken': true,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return LocketAuthSession(
        email: email,
        idToken: data['idToken'],
        refreshToken: data['refreshToken'] ?? '',
        localId: data['localId'],
        expiresAt: now + 3300, // Cache 55 phút (3300s)
      );
    }
    return null;
  }

  /// Làm mới token bằng refreshToken khi token cũ hết hạn (không cần verifyPassword)
  Future<LocketAuthSession?> _refreshSession(LocketAuthSession oldSession) async {
    if (oldSession.refreshToken.isEmpty) return null;

    final uri = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=${LocketConfig.firebaseApiKey}',
    );

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': oldSession.refreshToken,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiresIn = int.tryParse(data['expires_in']?.toString() ?? '3600') ?? 3600;

      return LocketAuthSession(
        email: oldSession.email,
        idToken: data['id_token'],
        refreshToken: data['refresh_token'] ?? oldSession.refreshToken,
        localId: data['user_id'] ?? oldSession.localId,
        expiresAt: now + (expiresIn - 300),
      );
    }
    return null;
  }

  /// Lấy session từ cache hoặc xoay vòng account trong Pool (tương tự logic PHP)
  Future<LocketAuthSession> _getOrRotateSession({List<String> excludeEmails = const []}) async {
    final accounts = List<Map<String, String>>.from(LocketConfig.accounts);
    if (accounts.isEmpty) {
      throw Exception('Không có tài khoản nào được cấu hình trong LocketConfig.accounts');
    }

    // 1. Kiểm tra cache xem có account nào còn session hợp lệ không
    final validCachedSessions = _tokenCache.values
        .where((s) => !excludeEmails.contains(s.email) && s.isValid)
        .toList();

    if (validCachedSessions.isNotEmpty) {
      _currentSession = validCachedSessions[Random().nextInt(validCachedSessions.length)];
      return _currentSession!;
    }

    // 2. Thử dùng refreshToken cho các session đã hết hạn trong cache
    for (final email in _tokenCache.keys.toList()) {
      if (excludeEmails.contains(email)) continue;
      final cached = _tokenCache[email]!;
      final refreshed = await _refreshSession(cached);
      if (refreshed != null) {
        _tokenCache[email] = refreshed;
        _currentSession = refreshed;
        return _currentSession!;
      } else {
        _tokenCache.remove(email); // Refresh fail -> Xoá cache
      }
    }

    // 3. Nếu chưa có -> Xáo trộn danh sách account để login trực tiếp
    accounts.shuffle();
    for (final acc in accounts) {
      final email = acc['email'] ?? '';
      if (excludeEmails.contains(email)) continue;

      final session = await _loginDirectly(acc);
      if (session != null) {
        _tokenCache[email] = session;
        _currentSession = session;
        return _currentSession!;
      }
    }

    throw Exception('Tất cả tài khoản trong Pool đều đăng nhập thất bại hoặc bị Rate Limit');
  }

  void _invalidateCurrentToken() {
    if (_currentSession != null) {
      _tokenCache.remove(_currentSession!.email);
      _currentSession = null;
    }
  }

  /// Upload file ảnh/video với cơ chế tự động Retry & Xoay vòng Account nếu gặp lỗi 401/403
  Future<LocketUploadResult> uploadFile(
      File file, {
        String? forcedFileName,
        int maxRetries = 3,
      }) async {
    if (!await file.exists()) {
      throw FileSystemException('File không tồn tại', file.path);
    }

    final triedEmails = <String>[];

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final session = await _getOrRotateSession(excludeEmails: triedEmails);
        triedEmails.add(session.email);

        return await _executeUpload(file, session, forcedFileName);
      } catch (e) {
        final errorMsg = e.toString();

        // Nếu lỗi do Token hết hạn / 401 / 403 -> Hủy session hiện tại và thử lại
        if (errorMsg.contains('401') || errorMsg.contains('403')) {
          _invalidateCurrentToken();
          if (attempt == maxRetries) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        rethrow;
      }
    }

    throw Exception('Upload thất bại sau $maxRetries lần thử');
  }

  Future<LocketUploadResult> uploadPath(String filePath) {
    return uploadFile(File(filePath));
  }

  /// Luồng xử lý upload Firebase Storage Resumable
  Future<LocketUploadResult> _executeUpload(
      File file,
      LocketAuthSession session,
      String? forcedFileName,
      ) async {
    final ext = p.extension(file.path).toLowerCase();
    final mediaType = _detectMediaType(ext);
    final targetExt = mediaType == 'image' ? '.webp' : '.mp4';
    final fileName = forcedFileName ?? _generateRandomFileName(targetExt);

    final fileBytes = await file.readAsBytes();
    final fileSize = fileBytes.length;
    final md5Hex = md5.convert(fileBytes).toString();

    final contentType = mediaType == 'image' ? 'image/webp' : 'video/mp4';
    final bucket = mediaType == 'image' ? 'locket-img' : 'locket-video';
    final folder = mediaType == 'image' ? 'thumbnails' : 'videos';

    final storagePath = 'users/${session.localId}/moments/$folder/$fileName';
    final encodedStoragePath = Uri.encodeComponent(storagePath);

    // 1. POST Resumable Start
    final startUploadUri = Uri.parse(
      'https://firebasestorage.googleapis.com:443/v0/b/$bucket/o/'
          '$encodedStoragePath?uploadType=resumable&name=$encodedStoragePath',
    );

    final startResponse = await _client.post(
      startUploadUri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Firebase ${session.idToken}',
        'X-Goog-Upload-Protocol': 'resumable',
        'Accept': '*/*',
        'X-Firebase-Appcheck': LocketConfig.firebaseAppCheck,
        'X-Goog-Upload-Command': 'start',
        'Priority': 'u=3, i',
        'X-Goog-Upload-Content-Length': '$fileSize',
        'Sentry-Trace': LocketConfig.sentryTrace,
        'X-Firebase-Storage-Version': 'ios/12.12.0',
        'Accept-Language': 'vi-VN,vi;q=0.9',
        'User-Agent': LocketConfig.userAgentStorage,
        'X-Goog-Upload-Content-Type': contentType,
        'X-Firebase-Gmpid': LocketConfig.firebaseGmpId,
      },
      body: jsonEncode({
        'metadata': {'creator': session.localId, 'visibility': 'private'},
        'cacheControl': 'public, max-age=604800',
        'name': storagePath,
        'contentType': contentType,
        'bucket': '',
      }),
    ).timeout(const Duration(seconds: 30));

    if (startResponse.statusCode < 200 || startResponse.statusCode >= 300) {
      throw Exception('Khởi tạo upload thất bại (${startResponse.statusCode}): ${startResponse.body}');
    }

    final resumableUploadUrl = startResponse.headers['x-goog-upload-url'];
    if (resumableUploadUrl == null || resumableUploadUrl.isEmpty) {
      throw Exception('Không tìm thấy X-Goog-Upload-URL');
    }

    // 2. PUT Data
    final uploadResponse = await _client.put(
      Uri.parse(resumableUploadUrl),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Accept': '*/*',
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Offset': '0',
        'X-Goog-Upload-Command': 'upload, finalize',
        'Priority': 'u=3, i',
        'X-Goog-Upload-Content-Length': '$fileSize',
        'Accept-Language': 'vi-VN,vi;q=0.9',
        'Upload-Draft-Interop-Version': '6',
        'Content-Length': '$fileSize',
        'User-Agent': LocketConfig.userAgentStorage,
        'Upload-Complete': '?1',
      },
      body: fileBytes,
    ).timeout(const Duration(minutes: 3));

    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw Exception('Upload file thất bại (${uploadResponse.statusCode}): ${uploadResponse.body}');
    }

    // 3. GET Metadata & downloadToken
    final fileMetadataUri = Uri.parse(
      'https://firebasestorage.googleapis.com:443/v0/b/$bucket/o/$encodedStoragePath',
    );

    final metadataResponse = await _client.get(
      fileMetadataUri,
      headers: {
        'Accept': '*/*',
        'Authorization': 'Firebase ${session.idToken}',
        'X-Firebase-Appcheck': LocketConfig.firebaseAppCheck,
        'Priority': 'u=3, i',
        'Accept-Language': 'vi-VN,vi;q=0.9',
        'X-Firebase-Storage-Version': 'ios/12.12.0',
        'Sentry-Trace': LocketConfig.sentryTrace,
        'User-Agent': LocketConfig.userAgentClient,
        'X-Firebase-Gmpid': LocketConfig.firebaseGmpId,
      },
    ).timeout(const Duration(seconds: 30));

    if (metadataResponse.statusCode < 200 || metadataResponse.statusCode >= 300) {
      throw Exception('Lấy metadata thất bại (${metadataResponse.statusCode}): ${metadataResponse.body}');
    }

    final metadata = jsonDecode(metadataResponse.body) as Map<String, dynamic>;
    final downloadToken = metadata['downloadTokens']?.toString();

    if (downloadToken == null || downloadToken.isEmpty) {
      throw Exception('Không lấy được download token.');
    }

    final downloadUrl =
        'https://firebasestorage.googleapis.com:443/v0/b/$bucket/o/'
        '$encodedStoragePath?alt=media&token=$downloadToken';

    return LocketUploadResult(
      fileType: mediaType,
      fileName: fileName,
      storagePath: storagePath,
      bucket: bucket,
      downloadUrl: downloadUrl,
      md5Hex: md5Hex,
      downloadToken: downloadToken,
    );
  }

  String _detectMediaType(String ext) {
    if (_imageExtensions.contains(ext)) return 'image';
    if (_videoExtensions.contains(ext)) return 'video';
    throw UnsupportedError('Định dạng không hỗ trợ: $ext');
  }

  String _generateRandomFileName(String extension) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final randomId = List.generate(20, (_) => chars[random.nextInt(chars.length)]).join();
    return '$randomId$extension';
  }

  void close() {
    _client.close();
  }
}