import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/core/theme/app_theme.dart';
import 'package:meme_app/features/profile/screens/about_app_screen.dart';
import 'package:meme_app/l10n/generated/app_localizations.dart';

Widget app({bool english = false, double scale = 1, bool reduced = true}) =>
    MaterialApp(
        theme: english ? AppTheme.darkTheme : AppTheme.lightTheme,
        locale: Locale(english ? 'en' : 'vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: reduced,
                textScaler: TextScaler.linear(scale)),
            child: child!),
        home: const AboutAppScreen());

void main() {
  for (final english in [false, true]) {
    testWidgets(
        'About page thanks, credits and project links fit with large text ($english)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(english: english, scale: 2));
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AboutAppScreen)))!;
      expect(find.text(l10n.memeThankYouTitle), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNWidgets(4));
      await tester.ensureVisible(find.text(l10n.memeStarRepo));
      await tester.pumpAndSettle();
      expect(find.text(l10n.memeReleases), findsOneWidget);
      expect(find.text(l10n.memeStarRepo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Project actions open releases and repository URLs',
      (tester) async {
    final urls = <String>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') {
        urls.add((call.arguments as Map)['url'] as String);
        return true;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app(english: true));
    for (final title in ['View releases', 'Give Meme a star']) {
      await tester.ensureVisible(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }
    expect(urls, [
      'https://github.com/duyvinh09/meme-app/releases',
      'https://github.com/duyvinh09/meme-app'
    ]);
  });
  testWidgets(
      'Calendar style back button has no tooltip and returns to previous page',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      await Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AboutAppScreen()));
                    },
                    child: const Text('Open about'))))));
    await tester.tap(find.text('Open about'));
    await tester.pumpAndSettle();
    final icon = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(icon, findsOneWidget);
    expect(find.byType(Tooltip), findsNothing);
    final button =
        find.ancestor(of: icon, matching: find.byType(InkWell)).first;
    expect(tester.getSize(button), const Size(44, 44));
    expect(tester.widget<Icon>(icon).size, 19);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(AboutAppScreen), findsNothing);
    expect(find.text('Open about'), findsOneWidget);
  });
  testWidgets('Heart animation disposes safely and reacts to reduced motion',
      (tester) async {
    await tester.pumpWidget(app(reduced: false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(reduced: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
