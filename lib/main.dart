import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_names.dart';
import 'core/theme/app_theme.dart';
import 'core/services/local_settings_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/home/controllers/home_controller.dart';
import 'features/capture/controllers/capture_controller.dart';
import 'features/stats/controllers/stats_controller.dart';
import 'features/budget/controllers/budget_controller.dart';
import 'features/profile/controllers/profile_controller.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/user_category_repository.dart';
import 'features/profile/controllers/user_category_controller.dart';
import 'data/repositories/chat_repository.dart';
import 'features/feed/controllers/feed_controller.dart';
import 'features/chat/controllers/chat_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/in_app_notification_host.dart';
import 'core/services/exchange_rate_service.dart';
import 'core/theme/app_scroll_behavior.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final localSettings = LocalSettingsService();
  await localSettings.init();
  await ExchangeRateService.init();
  await NotificationService.instance.init();

  runApp(MyApp(localSettings: localSettings));
}

class MyApp extends StatelessWidget {
  final LocalSettingsService localSettings;
  const MyApp({super.key, required this.localSettings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localSettings),
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => TransactionRepository()),
        Provider(create: (_) => BudgetRepository()),
        Provider(create: (_) => UserCategoryRepository()),
        Provider(create: (_) => ChatRepository()),
        ChangeNotifierProvider(
          create: (context) => AuthController(
            authRepository: context.read<AuthRepository>(),
            userRepository: context.read<UserRepository>(),
            localSettingsService: context.read<LocalSettingsService>(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileController(
            localSettingsService: context.read<LocalSettingsService>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeController(
            transactionRepository: context.read<TransactionRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CaptureController(
            transactionRepository: context.read<TransactionRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => StatsController(
            transactionRepository: context.read<TransactionRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => BudgetController(
            budgetRepository: context.read<BudgetRepository>(),
            transactionRepository: context.read<TransactionRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FeedController(
            transactionRepository: context.read<TransactionRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => UserCategoryController(
            repository: context.read<UserCategoryRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatController(
            chatRepository: context.read<ChatRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),
      ],
      child: Consumer<ProfileController>(
        builder: (context, profile, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Meme',
            scrollBehavior: const AppScrollBehavior(),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: profile.themeMode,
            locale: Locale(profile.languageCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorKey: AppRoutes.navigatorKey,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            initialRoute: RouteNames.splash,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final clampedTextScaler = media.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.15,
              );
              return InAppNotificationHost(
                child: MediaQuery(
                  data: media.copyWith(textScaler: clampedTextScaler),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}