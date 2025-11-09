import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/theme_repository.dart';
import 'package:wislet/main.dart' show LanguageProvider;
import 'package:wislet/providers/app_mode_provider.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/dashboard_provider.dart';
import 'package:wislet/providers/locale_provider.dart';
import 'package:wislet/providers/pro_status_provider.dart';
import 'package:wislet/providers/reports_provider.dart';
import 'package:wislet/providers/theme_provider.dart';
import 'package:wislet/providers/transaction_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/services/auth_service.dart';

/// Усі ChangeNotifier-и з твого DI (GetIt)
List<SingleChildWidget> buildAppProviders() => [
      Provider(
        create: (_) => getIt<AuthService>(),
      ),
      ChangeNotifierProvider(
        create: (context) => AppModeProvider(context.read<AuthService>()),
      ),
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(getIt<ThemeRepository>()),
      ),
      ChangeNotifierProvider(
        create: (_) => CurrencyProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => ProStatusProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => LanguageProvider()..load(),
      ),
      ChangeNotifierProvider(
        create: (_) => DashboardProvider(),
      ),
      ChangeNotifierProvider(
         create: (_) => LocaleProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => ReportsProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => TransactionProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => WalletProvider(
        authService: context.read<AuthService>(), 
         appModeProvider: context.read<AppModeProvider>(),
      ),
     ),
    ];
