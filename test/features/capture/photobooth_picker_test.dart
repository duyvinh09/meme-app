import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/core/theme/app_theme.dart';
import 'package:meme_app/core/constants/app_colors.dart';
import 'package:meme_app/features/capture/controllers/photobooth_controller.dart';
import 'package:meme_app/features/capture/models/photobooth_frame.dart';
import 'package:meme_app/features/capture/widgets/photobooth_button.dart';
import 'package:meme_app/features/capture/widgets/photobooth_frame_picker.dart';
import 'package:meme_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('ProximaSoft')
          ..addFont(rootBundle.load('assets/fonts/ProximaSoft-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  test('Catalog_AllTemplates_HasMatchingSlotsAndBundledAssets', () async {
    final frames = await PhotoboothFrame.loadCatalog();
    expect(frames.length, 157);
    final ids = frames.map((frame) => frame.id).toSet();
    expect(
        ids.intersection({
          'pb_khung1_meme_meo',
          'pb_khung3_fruit',
          'pb_khung1_faker',
          'pb_khung1_hong_ty',
          'pb_khung1_matmoc',
          'pb_khung1_messi',
          'pb_khung1_mona_lisa',
          'pb_khung1_ronaldo_cup',
          'pb_khung1_the_hinh',
          'pb_khung2_cuoi_vespa',
          'pb_khung2_monkey',
        }),
        isEmpty);
    expect(ids, containsAll(['pb_khung1_meow', 'pb_khung1_cute_fruit']));
    expect(frames.map((frame) => frame.id).toSet().length, frames.length);
    for (final frame in frames) {
      final group = RegExp(r'^pb_khung([1-4])_').firstMatch(frame.id);
      expect(frame.shotCount, group == null ? 1 : int.parse(group[1]!));
      expect(frame.masks.length, isIn([0, frame.shotCount]));
      for (final path in [frame.asset, frame.thumbnail, ...frame.masks]) {
        expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0),
            reason: path);
      }
    }
  });

  testWidgets('Picker_SelectFourPhotoGroup_ReturnsChosenTemplate',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final frames = (await tester.runAsync(PhotoboothFrame.loadCatalog))!;
    Object? chosen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => RepaintBoundary(
        key: const ValueKey('photobooth_preview'),
        child: child!,
      ),
      theme: AppTheme.darkTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () async {
                      chosen = await showModalBottomSheet<Object>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        constraints: const BoxConstraints(
                            maxHeight:
                                800 * PhotoboothFramePicker.heightFraction,
                            minHeight:
                                800 * PhotoboothFramePicker.heightFraction),
                        builder: (_) => const PhotoboothFramePicker(),
                      );
                    },
                    child: const Text('Open'),
                  ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Film & Vintage'), findsOneWidget);
    expect(
        tester.getSize(find.byType(BottomSheet)).height,
        moreOrLessEquals(800 * PhotoboothFramePicker.heightFraction,
            epsilon: 0.01));
    await tester.tap(find.widgetWithText(ChoiceChip, '4 ảnh'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final expected = frames.firstWhere((frame) => frame.shotCount == 4);
    expect(find.text(expected.name), findsOneWidget);
    final tile = find.byKey(ValueKey(expected.id));
    final image = find.descendant(of: tile, matching: find.byType(Image)).first;
    final imageRect = tester.getRect(image);
    expect(imageRect.width, moreOrLessEquals(imageRect.height, epsilon: 0.01));
    expect(tester.getRect(find.text(expected.name)).top,
        greaterThanOrEqualTo(imageRect.bottom));
    await _savePreview(tester, 'picker');
    await tester.tap(find.text(expected.name));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(chosen, isA<PhotoboothFrame>());
    expect((chosen as PhotoboothFrame).id, expected.id);
    expect(tester.takeException(), isNull);
  });

  for (final isDark in [false, true]) {
    testWidgets('Picker_ThemeAndCompactHeight_${isDark ? 'Dark' : 'Light'}',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(PhotoboothFrame.loadCatalog);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('photobooth_preview'),
          child: child!,
        ),
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        locale: Locale(isDark ? 'en' : 'vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
            body: Align(
          alignment: Alignment.bottomCenter,
          child: PhotoboothFramePicker(),
        )),
      ));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await _savePreview(tester, isDark ? 'picker_dark' : 'picker_light');
      final background = tester.widget<ColoredBox>(find
          .descendant(
            of: find.byType(PhotoboothFramePicker),
            matching: find.byType(ColoredBox),
          )
          .first);
      expect(
          background.color, isDark ? AppColors.darkCard : AppColors.lightCard);
      expect(
          tester.getSize(find.byType(PhotoboothFramePicker)).height,
          moreOrLessEquals(800 * PhotoboothFramePicker.heightFraction,
              epsilon: 0.01));
      expect(find.text(isDark ? 'All' : 'Tất cả'), findsOneWidget);
      if (isDark) {
        expect(find.widgetWithText(ChoiceChip, '1 photo'), findsOneWidget);
        expect(find.text('29 frames'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mini_ClearButton_RestoresFrameIconWithoutSpinner',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final frames = (await tester.runAsync(PhotoboothFrame.loadCatalog))!;
    final controller = PhotoboothController()..select(frames.first);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: Center(
              child: PhotoboothButton(
        controller: controller,
        onPressed: () {},
        onClear: controller.clear,
      ))),
    ));
    expect(tester.getSize(find.byType(PhotoboothButton)), const Size(72, 72));
    final miniBounds = tester.getRect(find.byType(PhotoboothButton));
    final closeButton = find.widgetWithIcon(IconButton, Icons.close_rounded);
    final closeBounds = tester.getRect(closeButton);
    expect(find.byType(Tooltip), findsNothing);
    expect(closeBounds.top, greaterThan(miniBounds.top));
    expect(closeBounds.right, lessThan(miniBounds.right));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(closeButton);
    await tester.pump();
    expect(controller.frame, isNull);
    expect(find.byIcon(CupertinoIcons.film), findsOneWidget);
    expect(tester.getSize(find.byType(IconButton)), const Size(38, 38));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _savePreview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('PHOTOBOOTH_PREVIEW')) return;
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('photobooth_preview')),
  );
  await tester.runAsync(() async {
    final snapshot = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/photobooth_previews').create(recursive: true);
      await File('build/photobooth_previews/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      snapshot.dispose();
    }
  });
}
