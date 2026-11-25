import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/core/theme/app_theme.dart';
import 'package:meme_app/features/profile/widgets/development_team_section.dart';
import 'package:meme_app/l10n/generated/app_localizations.dart';

void main() {
  for (final english in [false, true]) {
    testWidgets('Team credits fit narrow screen with large text ($english)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: english ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: Locale(english ? 'en' : 'vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: const SingleChildScrollView(
                      child: DevelopmentTeamSection())))));
      final l10n = AppLocalizations.of(
          tester.element(find.byType(DevelopmentTeamSection)))!;
      expect(find.text(l10n.developmentTeam), findsOneWidget);
      for (final username in [
        'duyvinh09',
        'NamLe1808',
        'Ngocvu2604',
        'QHuy1202'
      ]) {
        expect(find.text('github.com/$username'), findsOneWidget);
      }
      expect(find.byType(CachedNetworkImage), findsNWidgets(4));
      final avatars = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(avatars.map((image) => image.imageUrl),
          contains('https://github.com/duyvinh09.png?size=128'));
      expect(find.text(l10n.developerLeadRole), findsOneWidget);
      expect(find.text(l10n.developerLanguageAiRole), findsOneWidget);
      expect(find.text(l10n.developerDesignAiTestingRole), findsOneWidget);
      expect(find.text(l10n.developerBillLogicRole), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final successful in [true, false]) {
    testWidgets('GitHub profile launch handles success=$successful',
        (tester) async {
      String? launchedUrl;
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launch') {
          launchedUrl = (call.arguments as Map)['url'] as String;
          return successful;
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
              body: SingleChildScrollView(child: DevelopmentTeamSection()))));
      await tester.tap(find.text('github.com/duyvinh09'));
      await tester.pumpAndSettle();
      expect(launchedUrl, 'https://github.com/duyvinh09');
      final l10n = AppLocalizations.of(
          tester.element(find.byType(DevelopmentTeamSection)))!;
      expect(find.text(l10n.developerLinkError),
          successful ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
