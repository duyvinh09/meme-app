import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/cloudinary_constants.dart';

class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<String> uploadTransactionImage({
    required File file,
    String? folder,
  }) =>
      uploadMedia(file: file, folder: folder);

  /// Prefer the primary storage; use Cloudinary only when it fails.
  /// Local validation runs first so missing/empty files do not trigger uploads.
  Future<String> uploadMedia({
    required File file,
    String? folder,
    bool isVideo = false,
    Future<String> Function()? primaryUpload,
  }) async {
    if (!await file.exists()) {
      throw FileSystemException('Upload file does not exist', file.path);
    }
    if (await file.length() == 0) {
      throw const FileSystemException('Upload file is empty');
    }
    if (primaryUpload != null) {
      try {
        return _secureUrl(await primaryUpload());
      } on Exception {
        // Includes authentication, network and primary storage failures.
        // Never log tokens or response bodies when switching providers.
      }
    }
    return _upload(file, folder, isVideo).timeout(const Duration(minutes: 3));
  }

  Future<String> _upload(File file, String? folder, bool isVideo) async {
    final resource = isVideo ? 'video' : 'image';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConstants.cloudName}/$resource/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConstants.uploadPreset;

    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse =
        _client == null ? await request.send() : await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary không trả về secure_url');
      }

      return _secureUrl(secureUrl);
    } else {
      throw Exception(
        'Media upload failed (${response.statusCode})',
      );
    }
  }

  String _secureUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Storage returned an invalid HTTPS URL');
    }
    return value;
  }
}
