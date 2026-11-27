import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meme_app/core/services/cloudinary_service.dart';

void main() {
  late Directory directory;
  late File file;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('meme_upload_test_');
    file = await File('${directory.path}/capture.jpg').writeAsBytes([1, 2, 3]);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('Primary succeeds without uploading to backup', () async {
    final client = MockClient((_) async {
      fail('Backup must not be called');
    });
    final service = CloudinaryService(client: client);
    expect(
        await service.uploadMedia(
            file: file,
            primaryUpload: () async => 'https://primary.example/image.jpg'),
        'https://primary.example/image.jpg');
    client.close();
  });

  for (final video in [false, true]) {
    test('Primary auth/upload failure falls back once (video=$video)',
        () async {
      var backupCalls = 0;
      var primaryCalls = 0;
      final client = MockClient((request) async {
        backupCalls++;
        expect(
            request.url.path
                .endsWith(video ? '/video/upload' : '/image/upload'),
            isTrue);
        expect(request.body, contains('memeapp/test/transactions'));
        return http.Response(
            '{"secure_url":"https://res.cloudinary.com/test/media"}', 200);
      });
      final service = CloudinaryService(client: client);
      expect(
          await service.uploadMedia(
              file: file,
              isVideo: video,
              folder: 'memeapp/test/transactions',
              primaryUpload: () async {
                primaryCalls++;
                throw const HttpException('Primary failed: 403');
              }),
          'https://res.cloudinary.com/test/media');
      expect(primaryCalls, 1);
      expect(backupCalls, 1);
      client.close();
    });
  }

  test('Avatar image upload remains supported without a primary', () async {
    final client = MockClient((request) async {
      expect(request.url.path.endsWith('/image/upload'), isTrue);
      return http.Response(
          '{"secure_url":"https://res.cloudinary.com/avatar"}', 200);
    });
    expect(
        await CloudinaryService(client: client)
            .uploadTransactionImage(file: file),
        'https://res.cloudinary.com/avatar');
    client.close();
  });

  for (final response in [
    http.Response('private error details', 500),
    http.Response('{}', 200),
    http.Response('{"secure_url":"http://insecure.example/file"}', 200),
    http.Response('invalid JSON', 200),
  ]) {
    test('Both providers fail: backup error is propagated (${response.body})',
        () async {
      final client = MockClient((_) async => response);
      await expectLater(
          CloudinaryService(client: client).uploadMedia(
              file: file,
              primaryUpload: () async =>
                  throw const HttpException('primary error')),
          throwsA(isA<Exception>()));
      client.close();
    });
  }

  test('Missing file is rejected before either provider is called', () async {
    final client =
        MockClient((_) async => throw StateError('Unexpected backup'));
    await expectLater(
        CloudinaryService(client: client).uploadMedia(
            file: File('${directory.path}/missing.jpg'),
            primaryUpload: () async => throw StateError('Unexpected primary')),
        throwsA(isA<FileSystemException>()));
    client.close();
  });
}
