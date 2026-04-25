import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wislet/app_providers.dart';
import 'package:wislet/core/bootstrap/supabase_env.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/l10n/app_localizations.dart' as sw;
import 'package:wislet/providers/locale_provider.dart';
import 'package:wislet/providers/theme_provider.dart';
import 'package:wislet/screens/app_navigation_shell.dart';
import 'package:wislet/screens/home_screen.dart';
import 'package:wislet/screens/onboarding/onboarding_gate.dart';
import 'package:wislet/screens/settings_screen.dart';
import 'package:wislet/screens/transactions/add_edit_transaction_screen.dart';
import 'package:wislet/screens/transactions_list_screen.dart';
import 'package:wislet/theme/app_theme.dart';
import 'package:wislet/utils/l10n_helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseEnv.url,
      anonKey: SupabaseEnv.anon,
    );
  } catch (_) {}

  await configureDependencies();

  runApp(
    MultiProvider(
      providers: buildAppProviders(),
      child: const MyApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppNavigationShell(shell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wallet',
              builder: (context, state) => const TransactionsListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/add',
      builder: (context, state) => const AddEditTransactionScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocaleProvider>();
    final tp = context.watch<ThemeProvider>();
    return OnboardingGate(
      child: MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: tp.themeMode,
        locale: lp.locale,
        supportedLocales: const [Locale('en'), Locale('uk')],
        localizationsDelegates: const [
          sw.AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        onGenerateTitle: (context) =>
            sw.AppLocalizations.of(context)!.t('app_title'),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
