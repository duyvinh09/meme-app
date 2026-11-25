import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meme_app/features/capture/controllers/photobooth_controller.dart';
import 'package:meme_app/features/capture/models/photobooth_frame.dart';
import 'package:meme_app/features/capture/models/photobooth_preview_capture.dart';
import 'package:meme_app/features/capture/services/photobooth_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const assets = 'test/transparent.png';
  const frame = PhotoboothFrame(
    id: 'two',
    name: 'Two',
    asset: assets,
    thumbnail: assets,
    slots: [Rect.fromLTWH(0, 0, 540, 1080), Rect.fromLTWH(540, 0, 540, 1080)],
  );
  late Directory temporary;
  late File photo;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('meme_photobooth_test_');
    final overlay = img.Image(width: 16, height: 16, numChannels: 4);
    final image = img.Image(width: 32, height: 32);
    img.fill(image, color: img.ColorRgb8(200, 50, 50));
    photo = await File('${temporary.path}/input.jpg')
        .writeAsBytes(img.encodeJpg(image));
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final path = const StringCodec().decodeMessage(message);
      if (path == assets) return ByteData.sublistView(img.encodePng(overlay));
      return null;
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => temporary.path);
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), null);
    await temporary.delete(recursive: true);
  });

  test('Session_PartialThenComplete_OnlyExportsWhenAllSlotsAreFilled',
      () async {
    final controller = PhotoboothController()..select(frame);
    addTearDown(controller.dispose);
    expect(await controller.addPhoto(photo), isNull);
    expect(controller.capturedCount, 1);
    expect(controller.complete, isFalse);
    expect(controller.shots, hasLength(1));
    final firstImage = controller.shots.first.image;
    var shownBeforeExport = false;
    controller.addListener(() {
      if (controller.capturedCount == 2 && controller.busy) {
        shownBeforeExport = true;
      }
    });
    final output = await controller.addPhoto(photo);
    expect(output, isNotNull);
    expect(await output!.exists(), isTrue);
    final outputBytes = await output.readAsBytes();
    expect(output.path, endsWith('.jpg'));
    expect(outputBytes.take(3), [0xff, 0xd8, 0xff]);
    expect(outputBytes.length, lessThan(6000000));
    expect(img.decodeJpg(outputBytes)!.width, 1080);
    expect(controller.capturedCount, 2);
    expect(controller.complete, isTrue);
    expect(identical(firstImage, controller.shots.first.image), isTrue);
    expect(shownBeforeExport, isTrue);
    expect(await controller.addPhoto(photo), isNull);
    expect(controller.capturedCount, 2);
    controller.select(frame);
    expect(controller.capturedCount, 0);
    expect(controller.shots, isEmpty);
  });

  test('Session_FailedShot_DoesNotConsumeSlotAndCanRetry', () async {
    final controller = PhotoboothController()..select(frame);
    addTearDown(controller.dispose);
    final invalid =
        await File('${temporary.path}/bad.jpg').writeAsBytes([1, 2, 3]);
    await expectLater(controller.addPhoto(invalid), throwsFormatException);
    expect(controller.capturedCount, 0);
    expect(controller.busy, isFalse);
    expect(await controller.addPhoto(photo), isNull);
    expect(controller.capturedCount, 1);
  });

  test('Session_DoubleShutterAndFrameChange_DoesNotRaceActiveShot', () async {
    final controller = PhotoboothController()..select(frame);
    addTearDown(controller.dispose);
    final pending = controller.addPhoto(photo);
    expect(controller.busy, isTrue);
    controller.select(null);
    expect(controller.frame, frame);
    expect(await controller.addPhoto(photo), isNull);
    await pending;
    expect(controller.capturedCount, 1);
  });
  test('Session_ClearWhileShotArrives_CancelsWithoutRestoringFrame', () async {
    final controller = PhotoboothController()..select(frame);
    addTearDown(controller.dispose);
    final pending = controller.addPhoto(photo);
    controller.clear();
    expect(controller.frame, isNull);
    expect(await pending, isNull);
    expect(controller.capturedCount, 0);
    expect(controller.busy, isFalse);
  });
  test('Session_FinalPhoto_ProvidesIndependentPreviewBeforeExportCompletes',
      () async {
    final controller = PhotoboothController()..select(frame);
    addTearDown(controller.dispose);
    await controller.addPhoto(photo);
    PhotoboothPreviewCapture? preview;
    addTearDown(() => preview?.dispose());
    var exported = false;
    late final Future<File?> pending;
    pending = controller.addPhoto(photo, onReady: (scene) {
      expect(exported, isFalse);
      expect(scene.shots, hasLength(2));
      preview = PhotoboothPreviewCapture(scene: scene, file: pending);
    });
    final file = await pending;
    exported = true;
    expect(preview, isNotNull);
    expect(await preview!.file, file);
    controller.clear();
    // The preview must keep its image handles after camera state is cleared.
    final bytes = await exportPhotobooth(preview!.scene);
    final image = img.decodePng(bytes)!;
    expect(image.width, 1080);
    expect(image.getPixel(270, 540).r, greaterThan(180));
    expect(image.getPixel(810, 540).r, greaterThan(180));
  });
}
