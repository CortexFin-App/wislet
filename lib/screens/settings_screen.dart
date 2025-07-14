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
import 'auth/login_register_screen.dart';
import 'settings/notification_history_screen.dart';
import 'settings/wallets_screen.dart';
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
    await _authService.logout();
  }

  Future<void> _toggleBiometricAuth(bool value) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (value) {
      final canUse = await _authService.canUseBiometrics();
      if (!canUse) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Біометрію не налаштовано на вашому пристрої.')),
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
          const SnackBar(
              content: Text('Автентифікацію скасовано або не пройдено.')),
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
      final String fileName = 'sage_wallet_backup_$timestamp.json';
      final file = XFile.fromData(jsonBytes,
          mimeType: 'application/json', name: fileName);
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
              content:
                  Text('Дані успішно відновлено! Перезапустіть додаток.')),
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
    final appModeProvider = context.watch<AppModeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: <Widget>[
          _buildAccountSection(context, appModeProvider, proStatusProvider),
          _SettingsSection(
            title: 'Персоналізація',
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Колірна палітра',
                subtitle: themeProvider.currentProfile.name,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSelectionScreen()));
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 16.0, right: 0),
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Теми'),
                trailing: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text("Світла")),
                    ButtonSegment(value: ThemeMode.dark, label: Text("Темна")),
                    ButtonSegment(value: ThemeMode.system, label: Text("Системна")),
                  ],
                  selected: {themeProvider.themeMode},
                  onSelectionChanged: (newSelection) => themeProvider.setThemeMode(newSelection.first),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 16.0, right: 16.0),
                leading: const Icon(Icons.currency_exchange_outlined),
                title: const Text('Валюта'),
                trailing: DropdownButton<Currency>(
                  value: currencyProvider.selectedCurrency,
                  underline: const SizedBox.shrink(),
                  items: appCurrencies.map((Currency currency) {
                    return DropdownMenuItem<Currency>(
                      value: currency,
                      child: Text(currency.code),
                    );
                  }).toList(),
                  onChanged: (Currency? newValue) {
                    if (newValue != null) {
                      context.read<CurrencyProvider>().setCurrency(newValue);
                    }
                  },
                ),
              ),
            ],
          ),

          _SettingsSection(
            title: 'Управління',
            children: [
               _SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Гаманці',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletsScreen())),
              ),
               _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Категорії',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
              ),
               _SettingsTile(
                icon: Icons.subscriptions_outlined,
                title: 'Підписки',
                onTap: () => Navigator.push(context, SlidePageRoute(builder: (_) => const SubscriptionsListScreen())),
              ),
                _SettingsTile(
                icon: Icons.swap_calls_outlined,
                title: 'Конвертер валют',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CurrencyConverterScreen())),
              ),
            ],
           ),

           _SettingsSection(
            title: 'Автоматизація',
            children: [
              SwitchListTile(
                title: const Text('AI-визначення категорії'),
                subtitle: const Text('Пропонувати категорію на основі опису'),
                value: proStatusProvider.isPro && _aiCategorizationEnabled,
                onChanged: proStatusProvider.isPro ? _setAiCategorizationEnabled : null,
                secondary: const Icon(Icons.auto_awesome_outlined),
              ),
            ]
          ),

          _SettingsSection(
            title: 'Безпека та Дані',
            children: [
              _SettingsTile(
                icon: Icons.password_outlined,
                title: _isPinSet ? 'Змінити PIN-код' : 'Встановити PIN-код',
                onTap: _navigateToPinSetup,
              ),
              if (_deviceSupportsBiometrics)
                SwitchListTile(
                  title: const Text('Вхід за допомогою біометрії'),
                  subtitle: !_isPinSet ? const Text('Спочатку встановіть PIN-код') : null,
                  value: _isPinSet && _isBiometricEnabled,
                  onChanged: _isPinSet ? _toggleBiometricAuth : null,
                  secondary: const Icon(Icons.fingerprint),
                ),
              _SettingsTile(
                icon: Icons.history_outlined,
                title: 'Історія сповіщень',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationHistoryScreen())),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isProcessingBackup ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.backup_outlined),
                    label: const Text('Бекап'),
                    onPressed: _createBackup,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isProcessingRestore ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.restore_page_outlined),
                    label: const Text('Відновити'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _restoreFromBackup,
                  ),
                ),
              ],
            ),
          ),
          
          if (appModeProvider.isOnline)
            Center(
              child: TextButton(
                onPressed: _logout,
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Вийти з акаунту'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AppModeProvider appModeProvider, ProStatusProvider proStatusProvider) {
    if (appModeProvider.isOnline) return const SizedBox.shrink();

    return Column(
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: _SettingsTile(
            icon: Icons.cloud_sync_outlined,
            title: 'Увійти або створити акаунт',
            subtitle: 'Для синхронізації та спільного доступу',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginRegisterScreen())),
          ),
        ),
        if (!proStatusProvider.isPro) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Отримати Pro-статус',
              subtitle: 'Розблокувати всі можливості',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
            ),
          )
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0),
          child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}