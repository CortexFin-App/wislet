import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/di/injector.dart';
import 'providers/app_mode_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/pro_status_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/billing_service.dart'; // <--- ІНТЕГРОВАНО
import 'services/navigation_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await configureDependencies();

  await getIt<AuthService>().tryToRestoreSession();
  
  // Ініціалізуємо сервіс покупок
  if (!kIsWeb) {
    await getIt<BillingService>().init();
    await getIt<NotificationService>().init();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<ThemeProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<CurrencyProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<ProStatusProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<AppModeProvider>()),
        ChangeNotifierProvider(
          create: (context) => WalletProvider(
            getIt(),
            getIt(),
            context.read<AppModeProvider>(),
            getIt<AuthService>(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final profile = themeProvider.currentProfile;
          return MaterialApp(
            title: 'Гаманець Мудреця',
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              fontFamily: profile.fontFamily,
              colorScheme: ColorScheme.fromSeed(
                seedColor: profile.seedColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(profile.borderRadius),
                ),
              ),
            ),
            darkTheme: ThemeData(
              fontFamily: profile.fontFamily,
              colorScheme: ColorScheme.fromSeed(
                seedColor: profile.seedColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(profile.borderRadius),
                ),
              ),
            ),
            navigatorKey: NavigationService.navigatorKey,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('uk', 'UA'),
            ],
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}