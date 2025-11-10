import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/app_currencies.dart' as data;
import 'package:wislet/l10n/app_localizations.dart' as sw;
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/locale_provider.dart';
import 'package:wislet/screens/categories_screen.dart';
import 'package:wislet/screens/settings/invitations_screen.dart';
import 'package:wislet/screens/settings/language_screen.dart';
import 'package:wislet/screens/settings/pin_setup_screen.dart';
import 'package:wislet/screens/settings/wallets_screen.dart';
import 'package:wislet/screens/tools/currency_converter_screen.dart';
import 'package:wislet/services/auth_service.dart';
import 'package:wislet/services/sync_service.dart';
import 'package:wislet/utils/database_helper.dart';
import 'package:wislet/utils/l10n_helpers.dart';
import 'package:wislet/widgets/scaffold/patterned_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AuthService _auth;
  late final DatabaseHelper _dbHelper;
  late final SyncService _syncService;

  bool _deviceSupportsBiometrics = false;
  bool _isBiometricEnabled = false;
  bool _isPinSet = false;
  bool _isProcessingBackup = false;
  bool _isProcessingRestore = false;

  @override
  void initState() {
    super.initState();
    _auth = getIt<AuthService>();
    _dbHelper = getIt<DatabaseHelper>();
    _syncService = getIt<SyncService>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final supportsBiometrics = await _auth.canUseBiometrics();
    final biometricsEnabled = await _auth.isBiometricsEnabled();
    final pinSet = await _auth.hasPin();
    if (mounted) {
      setState(() {
        _deviceSupportsBiometrics = supportsBiometrics;
        _isBiometricEnabled = biometricsEnabled;
        _isPinSet = pinSet;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
  }

  Future<void> _exportBackup() async {
    if (!mounted) return;
    setState(() => _isProcessingBackup = true);
    try {
      final jsonData = await _dbHelper.exportDatabaseToJson();
      final jsonString = jsonEncode(jsonData);
      final jsonBytes = utf8.encode(jsonString);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'sage_wallet_backup_$timestamp.json';

      final xfile = XFile.fromData(
        jsonBytes,
        mimeType: 'application/json',
        name: fileName,
      );
       await SharePlus.instance.share(
        ShareParams(
        files: [xfile],
         text: 'Export completed',
        subject: 'Backup',
         ),
        );

    } finally {
      if (mounted) setState(() => _isProcessingBackup = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (!mounted) return;
    setState(() => _isProcessingRestore = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonMap =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await _dbHelper.importDatabaseFromJson(jsonMap);

      if (!mounted) return;
      final l = sw.AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.t('restore_done')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessingRestore = false);
    }
  }

  Future<void> _runSync() async {
    await _syncService.synchronize();
    if (!mounted) return;
    final l = sw.AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('sync_done')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = sw.AppLocalizations.of(context)!;
    final currencyProvider = context.watch<CurrencyProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return PatternedScaffold(
      appBar: AppBar(title: Text(l.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SizedBox(height: 8),
          Text(
            l.t('interface'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.language,
            title: l.t('language'),
            subtitle: localeProvider.currentLanguageName(),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const LanguageScreen(),
              ),
            ),
          ),
          const Divider(height: 24),
          Text(
            l.t('money_and_currencies'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.payments_outlined,
            title: l.t('default_currency'),
            subtitle:
                '${currencyProvider.selectedCurrency.name} (${currencyProvider.selectedCurrency.symbol})',
            onTap: () async {
              final selected = await showModalBottomSheet<Currency>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return ListView(
                   children: [
                      RadioGroup<Currency>(
                         groupValue: currencyProvider.selectedCurrency,
                        onChanged: (Currency? v) => Navigator.pop(context, v),
                         child: Column(
                            children: data.appCurrencies.map((c) {
                             return RadioMenuButton<Currency>(
                            value: c,
                                groupValue: currencyProvider.selectedCurrency,
                             onChanged: (Currency? v) => Navigator.pop(context, v),
                                child: ListTile(
                                  title: Text('${c.name} (${c.code})'),
                                     subtitle: Text(c.symbol),
                                ),
                             );
                             }).toList(),
                         ),
                        ),

                    ],

                  );
                },
              );
              if (selected != null) {
                await currencyProvider.setCurrency(selected);
              }
            },
          ),
          _SettingsTile(
            icon: Icons.swap_calls_outlined,
            title: l.t('currency_converter'),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CurrencyConverterScreen(),
              ),
            ),
          ),
          const Divider(height: 24),
          Text(
            l.t('data_and_sync'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.sync_outlined,
            title: l.t('sync_now'),
            onTap: _runSync,
          ),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: l.t('backup'),
            onTap: _exportBackup,
          ),
          _SettingsTile(
            icon: Icons.restore_outlined,
            title: l.t('restore'),
            onTap: _restoreBackup,
          ),
          if (_isProcessingBackup || _isProcessingRestore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          const Divider(height: 24),
          Text(
            l.t('management'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: l.t('wallets'),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const WalletsScreen(),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.category_outlined,
            title: l.t('categories'),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CategoriesScreen(),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.group_add_outlined,
            title: l.t('invitations'),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const InvitationsScreen(),
              ),
            ),
          ),
          const Divider(height: 24),
          Text(
            l.t('security'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.pin_outlined,
            title: _isPinSet ? l.t('change_pin') : l.t('enable_pin'),
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => const PinSetupScreen(),
                ),
              );
              if (updated ?? false) {
                await _loadSettings();
              }
            },
          ),
          SwitchListTile.adaptive(
            value: _isBiometricEnabled,
            onChanged: null,
            secondary: const Icon(Icons.fingerprint),
            title: Text(l.t('biometrics')),
            subtitle: Text(
              _deviceSupportsBiometrics
                  ? l.t('biometrics_configured')
                  : l.t('biometrics_not_supported'),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.logout_outlined,
            title: l.t('logout'),
            onTap: _logout,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
