// lib/screens/onboarding/interactive_onboarding_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/l10n/app_localizations.dart' as sw;
import 'package:sage_wallet_reborn/models/currency_model.dart' show Currency;
import 'package:sage_wallet_reborn/screens/categories_screen.dart';
import 'package:sage_wallet_reborn/screens/settings/wallets_screen.dart';
import 'package:sage_wallet_reborn/services/sync_service.dart';
import 'package:sage_wallet_reborn/utils/l10n_helpers.dart';

// уникаємо конфлікту назв: appCurrencies беремо з data/* під alias `data`
import 'package:sage_wallet_reborn/data/app_currencies.dart' as data;

class InteractiveOnboardingScreen extends StatefulWidget {
  const InteractiveOnboardingScreen({
    required this.onFinished,
    super.key,
  });

  final VoidCallback onFinished;

  @override
  State<InteractiveOnboardingScreen> createState() =>
      _InteractiveOnboardingScreenState();
}

class _InteractiveOnboardingScreenState
    extends State<InteractiveOnboardingScreen> {
  int _step = 0;

  Currency? _selectedCurrency;
  final TextEditingController _walletNameCtrl = TextEditingController();
  final TextEditingController _walletBalanceCtrl = TextEditingController();

  final Map<String, bool> _categories = <String, bool>{
    'Housing': true,
    'Food & Groceries': true,
    'Transport': true,
    'Health': false,
    'Entertainment': false,
    'Utilities': false,
    'Subscriptions': true,
    'Other': false,
  };

  bool _wantsPin = false;
  bool _syncing = false;

  @override
  void dispose() {
    _walletNameCtrl
      ..removeListener(() {})
      ..dispose();
    _walletBalanceCtrl
      ..removeListener(() {})
      ..dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _selectedCurrency != null;
      case 2:
        return _walletNameCtrl.text.trim().isNotEmpty;
      case 3:
        return true; // категорії опціональні
      case 4:
        return true; // PIN опціонально
      case 5:
        return !_syncing; // можна далі, якщо не синкаться
      default:
        return true;
    }
  }

  Future<void> _persistSelections() async {
    final SharedPreferences p = await SharedPreferences.getInstance();

    if (_selectedCurrency != null) {
      await p.setString('selected_currency_code', _selectedCurrency!.code);
    }

    await p.setString('onboard_wallet_name', _walletNameCtrl.text.trim());

    final double balRaw = double.tryParse(
          _walletBalanceCtrl.text.replaceAll(',', '.'),
        ) ??
        0.0;
    await p.setDouble('onboard_wallet_balance', balRaw);
    await p.setBool('onboard_wants_pin', _wantsPin);

    final List<String> chosenCats = _categories.entries
        .where((MapEntry<String, bool> e) => e.value)
        .map((MapEntry<String, bool> e) => e.key)
        .toList();
    await p.setString('onboard_categories', jsonEncode(chosenCats));
  }

  Future<void> _runInitialSync() async {
    setState(() => _syncing = true);
    try {
      final SyncService sync = getIt<SyncService>();
      await sync.synchronize();
    } catch (_) {
      // не падаємо майстер через помилку синку
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  List<Step> _buildSteps(BuildContext context) {
    final sw.AppLocalizations? l = sw.AppLocalizations.of(context);

    return <Step>[
      Step(
        title: Text(l?.t('onb_int_goal_title') ?? 'Welcome!'),
        isActive: _step >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l?.t('onb_int_goal_body') ??
                  'Let’s tailor Sage Wallet for you: choose currency, add your first wallet, pick categories, security, and sync.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: const <Widget>[
                Chip(label: Text('Track expenses')),
                Chip(label: Text('Budgeting')),
                Chip(label: Text('Subscriptions')),
                Chip(label: Text('Multi-wallet')),
              ],
            ),
          ],
        ),
      ),
      Step(
        title: Text(l?.t('onb_int_currency_title') ?? 'Default currency'),
        isActive: _step >= 1,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DropdownButtonFormField<Currency>(
              value: _selectedCurrency,
              items: data.appCurrencies
                  .map<DropdownMenuItem<Currency>>(
                    (Currency c) => DropdownMenuItem<Currency>(
                      value: c,
                      child: Text('${c.name} (${c.code}) — ${c.symbol}'),
                    ),
                  )
                  .toList(),
              onChanged: (Currency? v) => setState(() => _selectedCurrency = v),
              decoration: InputDecoration(
                labelText: l?.t('default_currency') ?? 'Default currency',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l?.t('onb_int_currency_hint') ??
                  'You can change this later in Settings → Money & Currencies.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      Step(
        title:
            Text(l?.t('onb_int_wallet_title') ?? 'Create your first wallet'),
        isActive: _step >= 2,
        content: Column(
          children: <Widget>[
            TextField(
              controller: _walletNameCtrl,
              decoration: InputDecoration(
                labelText: l?.t('wallet_name') ?? 'Wallet name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _walletBalanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l?.t('starting_balance') ??
                    'Starting balance (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const WalletsScreen(),
                    ),
                  );
                },
                label: Text(
                  l?.t('configure_in_wallets') ?? 'Open wallets manager',
                ),
              ),
            ),
          ],
        ),
      ),
      Step(
        title:
            Text(l?.t('onb_int_categories_title') ?? 'Pick categories'),
        isActive: _step >= 3,
        content: Column(
          children: <Widget>[
            ..._categories.entries.map(
              (MapEntry<String, bool> e) => CheckboxListTile(
                value: e.value,
                onChanged: (bool? v) =>
                    setState(() => _categories[e.key] = v ?? false),
                title: Text(e.key),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const CategoriesScreen(),
                    ),
                  );
                },
                label: Text(
                  l?.t('configure_in_categories') ??
                      'Open categories manager',
                ),
              ),
            ),
          ],
        ),
      ),
      Step(
        title: Text(l?.t('onb_int_security_title') ?? 'Security'),
        isActive: _step >= 4,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile.adaptive(
              value: _wantsPin,
              onChanged: (bool v) => setState(() => _wantsPin = v),
              title: Text(l?.t('enable_pin') ?? 'Enable PIN'),
              subtitle: Text(
                l?.t('onb_int_security_hint') ??
                    'You can set/change PIN later in Settings.',
              ),
            ),
          ],
        ),
      ),
      Step(
        title: Text(l?.t('onb_int_sync_title') ?? 'Sync'),
        isActive: _step >= 5,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l?.t('onb_int_sync_body') ??
                  'Run an initial sync to fetch remote data (if any). You can also do this later in Settings.',
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _syncing ? null : _runInitialSync,
                  icon: _syncing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(l?.t('sync_now') ?? 'Sync now'),
                ),
                const SizedBox(width: 12),
                if (_syncing)
                  Text(l?.t('sync_running') ?? 'Syncing…'),
              ],
            ),
          ],
        ),
      ),
      Step(
        title: Text(l?.t('onb_int_done_title') ?? 'All set!'),
        isActive: _step >= 6,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l?.t('onb_int_done_body') ??
                  'You’re ready to use Sage Wallet. You can change anything later in Settings.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await _persistSelections();
                if (mounted) widget.onFinished();
              },
              icon: const Icon(Icons.check),
              label: Text(l?.t('finish') ?? 'Finish'),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Step> steps = _buildSteps(context);
    final bool isLast = _step == steps.length - 1;
    final sw.AppLocalizations? l = sw.AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.t('onboarding') ?? 'Onboarding'),
      ),
      body: Stepper(
        currentStep: _step,
        steps: steps,
        onStepTapped: (int i) => setState(() => _step = i),
        onStepCancel: _step == 0 ? null : () => setState(() => _step -= 1),
        onStepContinue: !_canContinue
            ? null
            : () async {
                if (_step == 5) {
                  await _persistSelections();
                }
                if (isLast) {
                  await _persistSelections();
                  if (mounted) widget.onFinished();
                } else {
                  setState(() => _step += 1);
                }
              },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          final bool canBack = _step > 0;
          final bool canNext = _canContinue;
          final bool isLastLocal =
              _step == _buildSteps(context).length - 1;

          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: <Widget>[
                FilledButton(
                  onPressed: canNext ? details.onStepContinue : null,
                  child: Text(
                    isLastLocal
                        ? (l?.t('finish') ?? 'Finish')
                        : (l?.t('continue') ?? 'Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: canBack ? details.onStepCancel : null,
                  child: Text(l?.t('back') ?? 'Back'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
