import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_constants.dart';
import '../core/di/injector.dart';
import '../providers/app_mode_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/pro_status_provider.dart';
import '../models/currency_model.dart';
import '../utils/database_helper.dart';
import '../services/auth_service.dart';
import '../utils/slide_page_route.dart';
import 'settings/notification_history_screen.dart';
import 'settings/wallets_screen.dart';
import 'settings/accept_invitation_screen.dart';
import 'premium_screen.dart';
import 'categories_screen.dart';
import 'subscriptions/subscriptions_list_screen.dart';
import 'settings/pin_setup_screen.dart';
import 'settings/theme_selection_screen.dart';
import 'tools/currency_converter_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = getIt<DatabaseHelper>();
  final AuthService _authService = getIt<AuthService>();
  bool _isProcessingBackup = false;
  bool _isProcessingRestore = false;
  bool _aiCategorizationEnabled = true;
  bool _deviceSupportsBiometrics = false;
  bool _isBiometricEnabled = false;
  bool _isPinSet = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final supportsBiometrics = await _authService.canUseBiometrics();
    final biometricsEnabled = await _authService.isBiometricsEnabled();
    final pinSet = await _authService.hasPin();

    if (mounted) {
      context.read<ProStatusProvider>().loadProStatus();
      setState(() {
        _deviceSupportsBiometrics = supportsBiometrics;
        _isBiometricEnabled = biometricsEnabled;
        _isPinSet = pinSet;
        _aiCategorizationEnabled =
            prefs.getBool(AppConstants.prefsKeyAiCategorization) ?? true;
      });
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    final appModeProvider = context.read<AppModeProvider>();
    await _authService.logout();
    appModeProvider.switchToLocalMode();
  }

  Future<void> _toggleBiometricAuth(bool value) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    
    if (value) {
      final canUse = await _authService.canUseBiometrics();
      if (!canUse) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Біометрію не налаштовано на вашому пристрої.')),
        );
        return;
      }
      
      final authenticated = await _authService.authenticateWithBiometrics();
      if (authenticated) {
        await _authService.setBiometricsEnabled(true);
        if (mounted) {
          setState(() => _isBiometricEnabled = true);
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('Біометричний вхід увімкнено.')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Автентифікацію скасовано або не пройдено.')),
        );
      }
    } else {
      await _authService.setBiometricsEnabled(false);
      if (mounted) {
        setState(() => _isBiometricEnabled = false);
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Біометричний вхід вимкнено.')),
      );
    }
  }

  Future<void> _navigateToPinSetup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PinSetupScreen()),
    );
    if (result == true && mounted) {
      await _loadSettings();
    }
  }

  Future<void> _setAiCategorizationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyAiCategorization, value);
    if (mounted) {
      setState(() {
        _aiCategorizationEnabled = value;
      });
    }
  }

  Future<void> _createBackup() async {
    if (_isProcessingBackup) return;
    if (!mounted) return;
    setState(() => _isProcessingBackup = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final jsonData = await _dbHelper.exportDatabaseToJson();
      final String jsonString = jsonEncode(jsonData);
      final Uint8List jsonBytes = utf8.encode(jsonString);
      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String fileName = 'finance_app_backup_$timestamp.json';
      final file =
          XFile.fromData(jsonBytes, mimeType: 'application/json', name: fileName);
      await Share.shareXFiles([file],
          subject: 'Резервна копія Гаманця Мудреця');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Помилка при створенні резервної копії: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingBackup = false);
      }
    }
  }

  Future<void> _restoreFromBackup() async {
    if (_isProcessingRestore) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    final bool? confirmRestore = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Відновити дані?'),
          content: const Text(
              'УВАГА! Поточні дані в додатку будуть повністю замінені даними з резервної копії. Цю дію неможливо буде скасувати. Продовжити?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Скасувати'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Відновити'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmRestore != true) {
      return;
    }
    if (!mounted) return;
    setState(() => _isProcessingRestore = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        final String jsonString = await file.readAsString();
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        await _dbHelper.importDatabaseFromJson(jsonData);

        messenger.showSnackBar(
          const SnackBar(
              content: Text(
                  'Дані успішно відновлено! Перезапустіть додаток.')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Вибір файлу для відновлення скасовано.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Помилка при відновленні: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingRestore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final proStatusProvider = context.watch<ProStatusProvider>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final appModeProvider = context.watch<AppModeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: <Widget>[
          Card(
            elevation: 2,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.workspace_premium_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              title: Text('Гаманець Мудреця Pro',
                  style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer)),
              subtitle: Text(
                  proStatusProvider.isPro
                      ? 'Статус активовано'
                      : 'Розблокувати всі можливості',
                  style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withAlpha(204))),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final proProvider = context.read<ProStatusProvider>();
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PremiumScreen()));
                proProvider.loadProStatus();
              },
            ),
          ),
          const Divider(height: 32, thickness: 0.5),
          Text(
            'Вигляд та Персоналізація',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.light, label: Text('Світла'), icon: Icon(Icons.wb_sunny_outlined)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark, label: Text('Темна'), icon: Icon(Icons.nightlight_outlined)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.system, label: Text('Системна'), icon: Icon(Icons.settings_suggest_outlined)),
            ],
            selected: <ThemeMode>{themeProvider.themeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              themeProvider.setThemeMode(newSelection.first);
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16.0, right: 4.0),
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Колірна палітра'),
            subtitle: Text(themeProvider.currentProfile.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ThemeSelectionScreen()));
            },
          ),
          const Divider(height: 32, thickness: 0.5),
          Text(
            'Загальні',
            style: textTheme.titleLarge,
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Управління гаманцями'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const WalletsScreen()));
            },
          ),
          if (appModeProvider.isOnline)
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('Прийняти запрошення'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AcceptInvitationScreen()));
              },
            ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Управління категоріями'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const CategoriesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_calls_outlined),
            title: const Text('Конвертер валют'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CurrencyConverterScreen()));
            },
          ),
          DropdownButtonFormField<Currency>(
            decoration: const InputDecoration(
                labelText: 'Основна валюта відображення',
                prefixIcon: Icon(Icons.currency_exchange_outlined)),
            value: currencyProvider.selectedCurrency,
            items: appCurrencies.map((Currency currency) {
              return DropdownMenuItem<Currency>(
                value: currency,
                child: Text('${currency.name} (${currency.symbol})'),
              );
            }).toList(),
            onChanged: (Currency? newValue) {
              if (newValue != null) {
                context.read<CurrencyProvider>().setCurrency(newValue);
              }
            },
          ),
          const Divider(height: 32, thickness: 0.5),
          Text(
            'Автоматизація',
            style: textTheme.titleLarge,
          ),
          SwitchListTile(
            title: const Text('Авто-визначення категорії'),
            subtitle: const Text('AI-асистент пропонуватиме категорію'),
            value: proStatusProvider.isPro && _aiCategorizationEnabled,
            onChanged:
                proStatusProvider.isPro ? _setAiCategorizationEnabled : null,
            secondary: const Icon(Icons.auto_awesome_outlined),
          ),
          ListTile(
            title: const Text('Підписки'),
            leading: const Icon(Icons.subscriptions_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                SlidePageRoute(
                    builder: (context) => const SubscriptionsListScreen()),
              );
            },
          ),
          const Divider(height: 32, thickness: 0.5),
          Text(
            'Безпека та Дані',
            style: textTheme.titleLarge,
          ),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: Text(_isPinSet ? 'Змінити PIN-код' : 'Встановити PIN-код'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToPinSetup,
          ),
          if (_deviceSupportsBiometrics)
            SwitchListTile(
              title: const Text('Вхід за допомогою біометрії'),
              subtitle:
                  !_isPinSet ? const Text('Спочатку встановіть PIN-код') : null,
              value: _isPinSet && _isBiometricEnabled,
              onChanged: _isPinSet ? _toggleBiometricAuth : null,
              secondary: const Icon(Icons.fingerprint),
            ),
          ListTile(
            title: const Text('Історія сповіщень'),
            leading: const Icon(Icons.history_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: _isProcessingBackup
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.backup_outlined),
            label: const Text('Створити резервну копію'),
            onPressed: _createBackup,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: _isProcessingRestore
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.restore_page_outlined),
            label: const Text('Відновити з резервної копії'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            onPressed: _restoreFromBackup,
          ),
          if (appModeProvider.isOnline) ...[
            const Divider(),
            ListTile(
              leading:
                  Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text('Вийти з акаунту',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: _logout,
            ),
          ]
        ],
      ),
    );
  }
}