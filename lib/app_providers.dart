import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/providers/app_mode_provider.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/pro_status_provider.dart';
import 'package:wislet/providers/theme_provider.dart';

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
