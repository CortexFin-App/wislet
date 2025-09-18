import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wislet/utils/l10n_helpers.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/l10n/app_localizations.dart' as sw;
import 'package:wislet/screens/app_navigation_shell.dart';
import 'package:wislet/screens/onboarding/onboarding_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider()..load(),
      child: const MyApp(),
    ),
  );
}

class LanguageProvider extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString('app_locale');
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final p = await SharedPreferences.getInstance();
    await p.setString('app_locale', locale.languageCode);
    notifyListeners();
  }
}

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppNavigationShell(shell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const _HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wallet',
              builder: (context, state) => const _WalletScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const _SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const _AddScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return OnboardingGate(
      child: MaterialApp.router(
        locale: lp.locale,
        supportedLocales: const [Locale('en'), Locale('uk')],
        localizationsDelegates: const [
          sw.AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        onGenerateTitle: (context) => sw.AppLocalizations.of(context)!.t('app_title'),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  @override
  Widget build(BuildContext context) {
    final t = sw.AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.t('app_title'))),
      body: Center(child: Text(t.t('home'))),
    );
  }
}

class _WalletScreen extends StatelessWidget {
  const _WalletScreen();
  @override
  Widget build(BuildContext context) {
    final t = sw.AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.t('wallets'))),
      body: Center(child: Text(t.t('wallets'))),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();
  @override
  Widget build(BuildContext context) {
    final t = sw.AppLocalizations.of(context)!;
    final lp = context.read<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings'))),
      body: ListView(
        children: [
          ListTile(
            title: const Text('English'),
            onTap: () => lp.setLocale(const Locale('en')),
          ),
          ListTile(
            title: const Text('Українська'),
            onTap: () => lp.setLocale(const Locale('uk')),
          ),
        ],
      ),
    );
  }
}

class _AddScreen extends StatelessWidget {
  const _AddScreen();
  @override
  Widget build(BuildContext context) {
    final t = sw.AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.t('add'))),
      body: Center(child: Text(t.t('add'))),
    );
  }
}
