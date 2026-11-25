import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/core/theme/app_theme.dart';
import 'package:meme_app/features/capture/models/camera_capture_mode.dart';
import 'package:meme_app/features/capture/models/receipt_scan_result.dart';
import 'package:meme_app/features/capture/controllers/receipt_scan_controller.dart';
import 'package:meme_app/features/capture/widgets/camera_mode_selector.dart';
import 'package:meme_app/features/capture/widgets/receipt_scan_feedback.dart';
import 'package:meme_app/l10n/generated/app_localizations.dart';

Widget app(Widget child, {bool english = false}) => MaterialApp(
    theme: english ? AppTheme.darkTheme : AppTheme.lightTheme,
    locale: Locale(english ? 'en' : 'vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)));

void main() {
  test('Bill is between photo/video and cannot use gallery or photobooth', () {
    expect(CameraCaptureMode.values, [
      CameraCaptureMode.photo,
      CameraCaptureMode.bill,
      CameraCaptureMode.video
    ]);
    expect(CameraCaptureMode.bill.allowsGallery, isFalse);
    expect(CameraCaptureMode.bill.allowsPhotobooth, isFalse);
    expect(CameraCaptureMode.photo.allowsPhotobooth, isTrue);
    expect(CameraCaptureMode.video.allowsPhotobooth, isFalse);
  });
  testWidgets('Bill tab selects Bill without adding hover tooltips',
      (tester) async {
    CameraCaptureMode? selected;
    await tester.pumpWidget(app(CameraModeSelector(
        mode: CameraCaptureMode.photo,
        accent: Colors.blue,
        border: Colors.white24,
        onChanged: (mode) => selected = mode)));
    final bill = find.byIcon(CupertinoIcons.doc_text_viewfinder);
    expect(tester.getCenter(find.byIcon(CupertinoIcons.camera_fill)).dx,
        lessThan(tester.getCenter(bill).dx));
    expect(
        tester.getCenter(bill).dx,
        lessThan(
            tester.getCenter(find.byIcon(CupertinoIcons.videocam_fill)).dx));
    await tester.tap(bill);
    expect(selected, CameraCaptureMode.bill);
    expect(find.byType(Tooltip), findsNothing);
  });
  testWidgets('Busy or unsupported Bill mode cannot be selected',
      (tester) async {
    CameraCaptureMode? selected;
    await tester.pumpWidget(app(CameraModeSelector(
        mode: CameraCaptureMode.photo,
        accent: Colors.blue,
        border: Colors.white24,
        enabled: false,
        onChanged: (mode) => selected = mode)));
    await tester.tap(find.byIcon(CupertinoIcons.doc_text_viewfinder));
    expect(selected, isNull);
    await tester.pumpWidget(app(CameraModeSelector(
        mode: CameraCaptureMode.photo,
        accent: Colors.blue,
        border: Colors.white24,
        allowBill: false,
        onChanged: (mode) => selected = mode)));
    expect(find.byIcon(CupertinoIcons.doc_text_viewfinder), findsNothing);
  });
  for (final english in [false, true]) {
    testWidgets(
        'Receipt feedback states fit large text and support retry ($english)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      for (final phase in [
        ReceiptScanPhase.loading,
        ReceiptScanPhase.ready,
        ReceiptScanPhase.failed
      ]) {
        await tester.pumpWidget(app(
            MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.7)),
                child: SingleChildScrollView(
                    child: ReceiptScanFeedback(
                        phase: phase,
                        result: phase == ReceiptScanPhase.ready
                            ? const ReceiptScanResult(amountVnd: 100000)
                            : null,
                        currency: 'VND',
                        onRetry: () => retries++))),
            english: english));
        final l10n = AppLocalizations.of(
            tester.element(find.byType(ReceiptScanFeedback)))!;
        if (phase == ReceiptScanPhase.failed) {
          expect(find.text(l10n.receiptFailed), findsOneWidget);
          expect(find.text(l10n.receiptAmountUnknown), findsNothing);
          expect(find.text(l10n.receiptCategoryUnknown), findsNothing);
        }
        if (phase == ReceiptScanPhase.loading) {
          expect(find.text(l10n.receiptReading), findsOneWidget);
        } else {
          final before = retries;
          await tester.ensureVisible(find.text(l10n.receiptRetry));
          await tester.pump();
          await tester.tap(find.text(l10n.receiptRetry));
          expect(retries, before + 1);
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
