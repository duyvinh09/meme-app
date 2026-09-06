import 'dart:io';

import 'package:moment_money/core/services/locket/locket_upload_service.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Cách dùng: dart run bin/test_locket_upload.dart <duong_dan_file>');
    exit(1);
  }

  final service = LocketUploadService();

  try {
    print('Đang upload file...');
    final result = await service.uploadPath(args.first);

    print('Upload thành công!');
    print('Download URL:');
    print(result.downloadUrl);
  } catch (e) {
    print('Lỗi: $e');
  } finally {
    service.close();
  }
}