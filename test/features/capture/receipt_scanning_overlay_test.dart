import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meme_app/features/capture/widgets/receipt_scanning_overlay.dart';
import 'package:meme_app/l10n/generated/app_localizations.dart';

void main() {
  final image = MemoryImage(img.encodePng(img.Image(width: 20, height: 20)));
  for (final reduced in [false, true]) {
    testWidgets(
        'Scan stays inside the photo and respects reduced motion ($reduced)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!),
          home: Scaffold(
              body: Center(
                  child: SizedBox.square(
                      dimension: 240,
                      child: ReceiptScanningOverlay(
                          image: image, accent: Colors.blue))))));
      final l10n = AppLocalizations.of(
          tester.element(find.byType(ReceiptScanningOverlay)))!;
      expect(find.text(l10n.receiptReading), findsOneWidget);
      expect(tester.getSize(find.byType(ReceiptScanningOverlay)),
          const Size(240, 240));
      final beam = find.descendant(
          of: find.byType(ReceiptScanningOverlay),
          matching: find.byType(Transform));
      if (reduced) {
        expect(beam, findsNothing);
      } else {
        final before =
            tester.widget<Transform>(beam).transform.getTranslation().y;
        await tester.pump(const Duration(milliseconds: 300));
        final after =
            tester.widget<Transform>(beam).transform.getTranslation().y;
        expect(after, greaterThan(before));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
