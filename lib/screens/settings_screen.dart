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
import 'package:wislet/screens/auth/login_register_screen.dart';
import 'package:wislet/screens/categories_screen.dart';
import 'package:wislet/screens/settings/language_screen.dart';
import 'package:wislet/screens/settings/wallets_screen.dart';
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

  bool _isProcessingBackup = false;
  bool _isProcessingRestore = false;

  @override
  void initState() {
    super.initState();
    _auth = getIt<AuthService>();
    _dbHelper = getIt<DatabaseHelper>();
  }

  Future<void> _logout() async {
    try {
      // Зупинити періодичну синхронізацію перед очищенням сесії
      getIt<SyncService>().stopAutoSync();
      await _auth.logout();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {}
  }

  Future<void> _exportBackup() async {
    if (!mounted) return;
    setState(() => _isProcessingBackup = true);
    try {
      final jsonData = await _dbHelper.exportDatabaseToJson();
      final jsonString = jsonEncode(jsonData);
      final jsonBytes = utf8.encode(jsonString);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'wislet_backup_$timestamp.json';
      final xfile = XFile.fromData(
        jsonBytes,
        mimeType: 'application/json',
        name: fileName,
      );
      await SharePlus.instance.share(
        ShareParams(files: [xfile], text: 'Export completed', subject: 'Backup'),
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
        SnackBar(content: Text(l.t('restore_done'))),
      );
    } finally {
      if (mounted) setState(() => _isProcessingRestore = false);
    }
  }

  void _showProBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ProTeaser(),
    );
  }

  Widget _buildAccountSection(BuildContext context, sw.AppLocalizations l) {
    final user = context.watch<AuthService>().currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.t('account'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (user != null) ...[
          ListTile(
            leading: Icon(
              Icons.account_circle_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(user.email ?? user.name),
            subtitle: Text(l.t('logged_in')),
          ),
          _SettingsTile(
            icon: Icons.logout_outlined,
            title: l.t('logout'),
            onTap: _logout,
          ),
        ] else
          _SettingsTile(
            icon: Icons.login_outlined,
            title: l.t('sign_in_to_sync'),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const LoginRegisterScreen()),
            ),
          ),
      ],
    );
  }

  Widget _buildSyncSection(BuildContext context, sw.AppLocalizations l) {
    final user = context.watch<AuthService>().currentUser;
    // Показувати розділ синхронізації лише авторизованим користувачам
    if (user == null) return const SizedBox.shrink();

    final sync = context.watch<SyncService>();
    final lastSynced = sync.lastSyncedAt;
    final lastSyncLabel = lastSynced != null
        ? DateFormat('d MMM, HH:mm').format(lastSynced)
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text('Синхронізація',
            style: Theme.of(context).textTheme.titleMedium,),
        const SizedBox(height: 8),
        ListTile(
          leading: sync.isSyncing
              ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
              : Icon(
            sync.lastError != null
                ? Icons.sync_problem_outlined
                : Icons.sync_outlined,
            color: sync.lastError != null
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: const Text('Синхронізувати зараз'),
          subtitle: Text(
            sync.lastError != null
                ? 'Помилка: ${sync.lastError}'
                : 'Останній раз: $lastSyncLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: sync.isSyncing
              ? null
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: sync.isSyncing ? null : () => getIt<SyncService>().synchronize(),
        ),
      ],
    );
  }

  Widget _buildProSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text('Wislet Pro', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          leading: Icon(Icons.workspace_premium_outlined,
              color: theme.colorScheme.primary,),
          title: const Text('Wislet Pro'),
          subtitle: const Text('Розблокуйте розширені можливості'),
          trailing: Icon(Icons.lock_outline,
              size: 18, color: theme.colorScheme.onSurfaceVariant,),
          onTap: _showProBottomSheet,
        ),
      ],
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

          _buildAccountSection(context, l),
          _buildSyncSection(context, l),
          _buildProSection(context),

          const Divider(height: 24),
          Text(l.t('interface'),
              style: Theme.of(context).textTheme.titleMedium,),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.language,
            title: l.t('language'),
            subtitle: localeProvider.currentLanguageName(),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
            ),
          ),
          const Divider(height: 24),

          Text(l.t('money_and_currencies'),
              style: Theme.of(context).textTheme.titleMedium,),
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
                builder: (context) => ListView(
                  children: data.appCurrencies.map((c) {
                    return ListTile(
                      title: Text('${c.name} (${c.code})'),
                      subtitle: Text(c.symbol),
                      trailing:
                      currencyProvider.selectedCurrency.code == c.code
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(context, c),
                    );
                  }).toList(),
                ),
              );
              if (selected != null) {
                await currencyProvider.setCurrency(selected);
              }
            },
          ),
          const Divider(height: 24),

          Text(l.t('data_and_sync'),
              style: Theme.of(context).textTheme.titleMedium,),
          const SizedBox(height: 8),
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

          Text(l.t('management'),
              style: Theme.of(context).textTheme.titleMedium,),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: l.t('wallets'),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const WalletsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.category_outlined,
            title: l.t('categories'),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Промо-панель Pro-версії

class _ProTeaser extends StatelessWidget {
  const _ProTeaser();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const features = [
      (Icons.sync_outlined, 'Синхронізація між пристроями'),
      (Icons.bar_chart_outlined, 'Розширені звіти та аналітика'),
      (Icons.repeat_outlined, 'Регулярні транзакції'),
      (Icons.document_scanner_outlined, 'Сканування чеків'),
      (Icons.group_outlined, 'Спільні гаманці'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 48, color: theme.colorScheme.primary,),
          const SizedBox(height: 12),
          Text(
            'Wislet Pro',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Скоро буде доступно',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ...features.map(
                (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(f.$1, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Text(f.$2, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Зрозуміло'),
          ),
        ],
      ),
    );
  }
}

// Блок налаштувань

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
