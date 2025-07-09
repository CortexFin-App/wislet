import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/di/injector.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/goal_repository.dart';
import 'data/repositories/invitation_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'providers/app_mode_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/pro_status_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wallet_provider.dart';
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
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AuthService>()),
        ChangeNotifierProvider(create: (_) => getIt<ThemeProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<CurrencyProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<ProStatusProvider>()),
        ChangeNotifierProvider(
            create: (ctx) => AppModeProvider(ctx.read<AuthService>())),
        ChangeNotifierProvider(
          create: (context) => WalletProvider(
            appModeProvider: context.read<AppModeProvider>(),
            authService: context.read<AuthService>(),
            localWalletRepo: getIt<WalletRepository>(instanceName: 'local'),
            localTransactionRepo: getIt<TransactionRepository>(instanceName: 'local'),
            localBudgetRepo: getIt<BudgetRepository>(instanceName: 'local'),
            localGoalRepo: getIt<GoalRepository>(instanceName: 'local'),
            supabaseWalletRepo: getIt<WalletRepository>(instanceName: 'supabase'),
            supabaseTransactionRepo: getIt<TransactionRepository>(instanceName: 'supabase'),
            supabaseBudgetRepo: getIt<BudgetRepository>(instanceName: 'supabase'),
            supabaseGoalRepo: getIt<GoalRepository>(instanceName: 'supabase'),
            supabaseInvitationRepo: getIt<InvitationRepository>(instanceName: 'supabase'),
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
            ),
            darkTheme: ThemeData(
              fontFamily: profile.fontFamily,
              colorScheme: ColorScheme.fromSeed(
                seedColor: profile.seedColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
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