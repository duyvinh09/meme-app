import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/cloudinary_constants.dart';

class CloudinaryService {
  Future<String> uploadTransactionImage({
    required File file,
    String? folder,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConstants.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConstants.uploadPreset;

    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary không trả về secure_url');
      }

      return secureUrl;
    } else {
      throw Exception(
        'Upload ảnh thất bại: ${response.statusCode} - ${response.body}',
      );
    }
  }
}