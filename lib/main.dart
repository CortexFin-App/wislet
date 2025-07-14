import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/providers/reports_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/di/injector.dart';
import 'providers/app_mode_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/pro_status_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/error_monitoring_service.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  await ErrorMonitoringService.init(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    tz.initializeTimeZones();

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    await configureDependencies();

    if (!kIsWeb) {
      await getIt<NotificationService>().init();
    }
    runApp(const SageWalletApp());
  });
}

class SageWalletApp extends StatelessWidget {
  const SageWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<AuthService>()),
        ChangeNotifierProvider.value(value: getIt<AppModeProvider>()),
        ChangeNotifierProvider.value(value: getIt<ThemeProvider>()),
        ChangeNotifierProvider.value(value: getIt<CurrencyProvider>()),
        ChangeNotifierProvider.value(value: getIt<ProStatusProvider>()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProxyProvider<AuthService, WalletProvider>(
          create: (context) => WalletProvider(
            authService: context.read<AuthService>(),
            appModeProvider: context.read<AppModeProvider>(),
          ),
          update: (context, auth, previousWalletProvider) {
            previousWalletProvider?.updateAuthService(auth);
            return previousWalletProvider!;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final currentProfile = themeProvider.currentProfile;

          ThemeData buildTheme(Brightness brightness) {
            final colorScheme = ColorScheme.fromSeed(
              seedColor: currentProfile.seedColor,
              brightness: brightness,
            );

            return ThemeData(
              useMaterial3: true,
              brightness: brightness,
              fontFamily: currentProfile.fontFamily,
              colorScheme: colorScheme,
              appBarTheme: AppBarTheme(
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontFamily: currentProfile.fontFamily),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: colorScheme.surface,
                selectedItemColor: colorScheme.primary,
                unselectedItemColor: colorScheme.onSurfaceVariant,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                showSelectedLabels: true,
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(currentProfile.borderRadius)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: currentProfile.fontFamily),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(currentProfile.borderRadius),
                  borderSide: BorderSide.none,
                ),
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(currentProfile.borderRadius)),
              ),
              segmentedButtonTheme: SegmentedButtonThemeData(
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.primary;
                    }
                    return colorScheme.surfaceContainerHighest;
                  }),
                  foregroundColor:
                      WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.onPrimary;
                    }
                    return colorScheme.onSurface;
                  }),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(currentProfile.borderRadius))),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(currentProfile.borderRadius)),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Гаманець Мудреця',
            themeMode: themeProvider.themeMode,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
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