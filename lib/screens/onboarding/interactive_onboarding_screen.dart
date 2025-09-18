import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/app_currencies.dart' as data;
import 'package:wislet/l10n/app_localizations.dart' as sw;
import 'package:wislet/models/currency_model.dart' show Currency;
import 'package:wislet/screens/categories_screen.dart';
import 'package:wislet/screens/settings/wallets_screen.dart';
import 'package:wislet/services/sync_service.dart';
import 'package:wislet/utils/l10n_helpers.dart';

class InteractiveOnboarding extends StatefulWidget {
  const InteractiveOnboarding({
    required this.onFinished,
    super.key,
  });

  final VoidCallback onFinished;

  @override
  State<InteractiveOnboarding> createState() => _InteractiveOnboardingState();
}

class _InteractiveOnboardingState extends State<InteractiveOnboarding> {
  int _step = 0;

  // Кроки
  Currency? _selectedCurrency;
  final _walletNameCtrl = TextEditingController();
  final _walletBalanceCtrl = TextEditingController();

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
    _walletNameCtrl.dispose();
    _walletBalanceCtrl.dispose();
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
        return true; // категорії необов'язкові
      case 4:
        return true; // безпека — вибір
      case 5:
        return !_syncing; // далі можна, коли не синкиться
      default:
        return true;
    }
  }

  Future<void> _persistSelections() async {
    final p = await SharedPreferences.getInstance();
    if (_selectedCurrency != null) {
      await p.setString('selected_currency_code', _selectedCurrency!.code);
    }
    await p.setString('onboard_wallet_name', _walletNameCtrl.text.trim());

    final balRaw = double.tryParse(
          _walletBalanceCtrl.text.replaceAll(',', '.'),
        ) ??
        0.0;
    await p.setDouble('onboard_wallet_balance', balRaw);
    await p.setBool('onboard_wants_pin', _wantsPin);

    final chosenCats =
        _categories.entries.where((e) => e.value).map((e) => e.key).toList();
    await p.setString('onboard_categories', jsonEncode(chosenCats));
  }

  Future<void> _runInitialSync() async {
    setState(() => _syncing = true);
    try {
      final sync = getIt<SyncService>();
      await sync.synchronize();
    } catch (_) {
      // no-op: не валимо майстер
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  List<Step> _buildSteps(BuildContext context) {
    final l = sw.AppLocalizations.of(context);

    return <Step>[
      Step(
        title: Text(l?.t('onb_int_goal_title') ?? 'Welcome!'),
        isActive: _step >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.t('onb_int_goal_body') ??
                  'Let’s tailor Wislet for you: choose currency, add your first wallet, pick categories, security, and sync.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: const [
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
          children: [
            DropdownButtonFormField<Currency>(
              value: _selectedCurrency,
              items: data.appCurrencies
                  .map(
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
        title: Text(l?.t('onb_int_wallet_title') ?? 'Create your first wallet'),
        isActive: _step >= 2,
        content: Column(
          children: [
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
        title: Text(l?.t('onb_int_categories_title') ?? 'Pick categories'),
        isActive: _step >= 3,
        content: Column(
          children: [
            ..._categories.entries.map(
              (e) => CheckboxListTile(
                value: e.value,
                onChanged: (v) =>
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
                  l?.t('configure_in_categories') ?? 'Open categories manager',
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
          children: [
            SwitchListTile.adaptive(
              value: _wantsPin,
              onChanged: (v) => setState(() => _wantsPin = v),
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
          children: [
            Text(
              l?.t('onb_int_sync_body') ??
                  'Run an initial sync to fetch remote data (if any). You can also do this later in Settings.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
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
                if (_syncing) Text(l?.t('sync_running') ?? 'Syncing…'),
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
          children: [
            Text(
              l?.t('onb_int_done_body') ??
                  'You’re ready to use Wislet. You can change anything later in Settings.',
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
    final steps = _buildSteps(context);
    final isLast = _step == steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          sw.AppLocalizations.of(context)?.t('onboarding') ?? 'Onboarding',
        ),
      ),
      body: Stepper(
        currentStep: _step,
        steps: steps,
        onStepTapped: (i) => setState(() => _step = i),
        onStepCancel: _step == 0 ? null : () => setState(() => _step -= 1),
        onStepContinue: !_canContinue
            ? null
            : () async {
                // На переході з 5-го кроку збережемо проміжні налаштування
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
        controlsBuilder: (context, details) {
          final canBack = _step > 0;
          final canNext = _canContinue;
          final isLastLocal = _step == _buildSteps(context).length - 1;

          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: canNext ? details.onStepContinue : null,
                  child: Text(isLastLocal ? 'Finish' : 'Continue'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: canBack ? details.onStepCancel : null,
                  child: const Text('Back'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
