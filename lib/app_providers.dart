import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/providers/app_mode_provider.dart';
import 'package:sage_wallet_reborn/providers/currency_provider.dart';
import 'package:sage_wallet_reborn/providers/pro_status_provider.dart';
import 'package:sage_wallet_reborn/providers/theme_provider.dart';

/// Усі ChangeNotifier-и з твого DI (GetIt)
List<SingleChildWidget> buildAppProviders() => [
      ChangeNotifierProvider<AppModeProvider>(
        create: (_) => getIt<AppModeProvider>(),
      ),
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => getIt<ThemeProvider>(),
      ),
      ChangeNotifierProvider<CurrencyProvider>(
        create: (_) => getIt<CurrencyProvider>(),
      ),
      ChangeNotifierProvider<ProStatusProvider>(
        create: (_) => getIt<ProStatusProvider>(),
      ),
    ];
