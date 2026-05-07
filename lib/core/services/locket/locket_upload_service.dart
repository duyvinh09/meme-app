import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'locket_config.dart';

class LocketAuthSession {
  final String idToken;
  final String localId;
  final String? displayName;

  const LocketAuthSession({
    required this.idToken,
    required this.localId,
    this.displayName,
  });
}

class LocketUploadResult {
  final String fileType;
  final String fileName;
  final String storagePath;
  final String bucket;
  final String downloadUrl;
  final String? md5Hash;
  final String? downloadToken;

  const LocketUploadResult({
    required this.fileType,
    required this.fileName,
    required this.storagePath,
    required this.bucket,
    required this.downloadUrl,
    this.md5Hash,
    this.downloadToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileType': fileType,
      'fileName': fileName,
      'storagePath': storagePath,
      'bucket': bucket,
      'downloadUrl': downloadUrl,
      'md5Hash': md5Hash,
      'downloadToken': downloadToken,
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }
}

class LocketUploadService {
  LocketUploadService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  LocketAuthSession? _session;

  static const Set<String> _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  static const Set<String> _videoExtensions = {
    '.mp4',
    '.mov',
    '.avi',
  };

  Future<LocketAuthSession> login({
    String email = LocketConfig.email,
    String password = LocketConfig.password,
  }) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword'
          '?key=${LocketConfig.firebaseApiKey}',
    );

    final body = {
      'email': email,
      'password': password,
      'clientType': 'CLIENT_TYPE_IOS',
      'returnSecureToken': true,
    };

    final response = await _client
        .post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Đăng nhập Locket thất bại: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final idToken = data['idToken']?.toString();
    final localId = data['localId']?.toString();

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Không lấy được idToken từ Locket.');
    }

    if (localId == null || localId.isEmpty) {
      throw Exception('Không lấy được localId từ Locket.');
    }

    _session = LocketAuthSession(
      idToken: idToken,
      localId: localId,
      displayName: data['displayName']?.toString(),
    );

    return _session!;
  }

  Future<LocketAuthSession> _getSession() async {
    if (_session != null) return _session!;

    return login();
  }

  Future<LocketUploadResult> uploadFile(
      File file, {
        String? forcedFileName,
      }) async {
    if (!await file.exists()) {
      throw FileSystemException('File không tồn tại', file.path);
    }

    final session = await _getSession();

    final ext = p.extension(file.path).toLowerCase();
    final fileName = forcedFileName ?? _generateFileName(ext);
    final fileBytes = await file.readAsBytes();
    final fileSize = fileBytes.length;

    final mediaType = _detectMediaType(ext);
    final contentType = _contentTypeFor(mediaType, ext);
    final bucket = mediaType == 'image' ? 'locket-img' : 'locket-video';
    final folder = mediaType == 'image' ? 'thumbnails' : 'videos';

    final storagePath = 'users/${session.localId}/moments/$folder/$fileName';
    final encodedStoragePath = Uri.encodeComponent(storagePath);

    final startUploadUri = Uri.parse(
      'https://firebasestorage.googleapis.com:443/v0/b/$bucket/o/'
          '$encodedStoragePath?uploadType=resumable&name=$encodedStoragePath',
    );

    final uploadMetadata = {
      'cacheControl': 'public, max-age=604800',
      'bucket': '',
      'contentType': contentType,
      'name': storagePath,
      'metadata': {
        'creator': session.localId,
        'visibility': 'private',
      },
    };

    final startResponse = await _client
        .post(
      startUploadUri,
      headers: _startUploadHeaders(
        idToken: session.idToken,
        fileSize: fileSize,
        contentType: contentType,
        metadataLength: utf8.encode(jsonEncode(uploadMetadata)).length,
      ),
      body: jsonEncode(uploadMetadata),
    )
        .timeout(const Duration(seconds: 30));

    if (startResponse.statusCode < 200 || startResponse.statusCode >= 300) {
      throw Exception('Khởi tạo upload thất bại: ${startResponse.body}');
    }

    final resumableUploadUrl = startResponse.headers['x-goog-upload-url'];

    if (resumableUploadUrl == null || resumableUploadUrl.isEmpty) {
      throw Exception('Không tìm thấy X-Goog-Upload-URL.');
    }

    final uploadResponse = await _client
        .put(
      Uri.parse(resumableUploadUrl),
      headers: _uploadBytesHeaders(fileSize: fileSize),
      body: fileBytes,
    )
        .timeout(const Duration(minutes: 3));

    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw Exception('Upload file thất bại: ${uploadResponse.body}');
    }

    final fileMetadataUri = Uri.parse(
      'https://firebasestorage.googleapis.com:443/v0/b/$bucket/o/$encodedStoragePath',
    );

    final metadataResponse = await _client
        .get(
      fileMetadataUri,
      headers: _metadataHeaders(session.idToken),
    )
        .timeout(const Duration(seconds: 30));

    if (metadataResponse.statusCode < 200 ||
        metadataResponse.statusCode >= 300) {
      throw Exception('Lấy metadata thất bại: ${metadataResponse.body}');
    }

    final metadata = jsonDecode(metadataResponse.body) as Map<String, dynamic>;
    final downloadToken = metadata['downloadTokens']?.toString();
    final md5Hash = metadata['md5Hash']?.toString();

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
      md5Hash: md5Hash,
      downloadToken: downloadToken,
    );
  }

  Future<LocketUploadResult> uploadPath(String filePath) {
    return uploadFile(File(filePath));
  }

  String _detectMediaType(String ext) {
    if (_imageExtensions.contains(ext)) return 'image';
    if (_videoExtensions.contains(ext)) return 'video';

    throw UnsupportedError(
      'Định dạng không hỗ trợ: $ext. Chỉ hỗ trợ ảnh jpg/jpeg/png/webp và video mp4/mov/avi.',
    );
  }

  String _contentTypeFor(String mediaType, String ext) {
    if (mediaType == 'video') return 'video/mp4';

    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/webp';
    }
  }

  String _generateFileName(String extension) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final randomText = _randomString(5);
    final safeExt = extension.isEmpty ? '.jpg' : extension;
    return '${now}_$randomText$safeExt';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    return List.generate(
      length,
          (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String md5WithTimestamp(List<int> bytes) {
    final md5Hex = md5.convert(bytes).toString();
    final seconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
    return '${md5Hex}_$seconds';
  }

  Map<String, String> _authHeaders() {
    return {
      'Accept': '*/*',
      'Accept-Language': 'en',
      'Content-Type': 'application/json',
      'User-Agent': LocketConfig.userAgentAuth,
      'X-Client-Version': 'iOS/FirebaseSDK/10.23.1/FirebaseCore-iOS',
      'X-Firebase-AppCheck': LocketConfig.firebaseAppCheck,
      'X-Firebase-GMPID': LocketConfig.firebaseGmpId,
      'sentry-trace': LocketConfig.sentryTrace,
      'X-Ios-Bundle-Identifier': 'com.locket.Locket',
    };
  }

  Map<String, String> _startUploadHeaders({
    required String idToken,
    required int fileSize,
    required String contentType,
    required int metadataLength,
  }) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Firebase $idToken',
      'X-Goog-Upload-Protocol': 'resumable',
      'Accept': '*/*',
      'X-Firebase-Appcheck': LocketConfig.firebaseAppCheck,
      'X-Goog-Upload-Command': 'start',
      'X-Goog-Upload-Content-Length': '$fileSize',
      'Sentry-Trace': LocketConfig.sentryTrace,
      'Accept-Language': 'vi-VN,vi;q=0.9',
      'X-Firebase-Storage-Version': 'ios/10.13.0',
      'Content-Length': '$metadataLength',
      'User-Agent': LocketConfig.userAgentStorage,
      'X-Goog-Upload-Content-Type': contentType,
      'X-Firebase-Gmpid': LocketConfig.firebaseGmpId,
    };
  }

  Map<String, String> _uploadBytesHeaders({
    required int fileSize,
  }) {
    return {
      'Content-Type': 'application/octet-stream',
      'Accept': '*/*',
      'X-Goog-Upload-Protocol': 'resumable',
      'X-Goog-Upload-Offset': '0',
      'X-Goog-Upload-Command': 'upload, finalize',
      'X-Goog-Upload-Content-Length': '$fileSize',
      'User-Agent': 'com.locket.Locket/1.43.1 iPhone/17.3 hw/iPhone15_3',
      'Upload-Incomplete': '?0',
      'Upload-Draft-Interop-Version': '3',
    };
  }

  Map<String, String> _metadataHeaders(String idToken) {
    return {
      'Accept': '*/*',
      'Authorization': 'Firebase $idToken',
      'X-Firebase-Appcheck': LocketConfig.firebaseAppCheck,
      'Accept-Language': 'vi-VN,vi;q=0.9',
      'X-Firebase-Storage-Version': 'ios/10.13.1',
      'User-Agent': 'com.locket.Locket/1.43.1 iPhone/17.3 hw/iPhone15_3',
      'X-Firebase-Gmpid': LocketConfig.firebaseGmpId,
    };
  }

  void close() {
    _client.close();
  }
}