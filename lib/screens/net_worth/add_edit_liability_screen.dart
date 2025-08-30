import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/liability_repository.dart';
import 'package:sage_wallet_reborn/models/currency_model.dart';
import 'package:sage_wallet_reborn/models/liability.dart';
import 'package:sage_wallet_reborn/providers/currency_provider.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/services/auth_service.dart';
import 'package:sage_wallet_reborn/widgets/scaffold/patterned_scaffold.dart';

class AddEditLiabilityScreen extends StatefulWidget {
  const AddEditLiabilityScreen({this.liabilityToEdit, super.key});
  final Liability? liabilityToEdit;

  @override
  State<AddEditLiabilityScreen> createState() => _AddEditLiabilityScreenState();
}

class _AddEditLiabilityScreenState extends State<AddEditLiabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final LiabilityRepository _repository = getIt<LiabilityRepository>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  String _selectedType = 'РљСЂРµРґРёС‚';
  Currency? _selectedCurrency;
  bool _isSaving = false;

  bool get _isEditing => widget.liabilityToEdit != null;

  final List<String> _liabilityTypes = [
    'Р†РїРѕС‚РµРєР°',
    'РђРІС‚РѕРєСЂРµРґРёС‚',
    'РЎРїРѕР¶РёРІС‡РёР№ РєСЂРµРґРёС‚',
    'Р‘РѕСЂРі',
    'Р†РЅС€Рµ',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.liabilityToEdit!;
      _nameController = TextEditingController(text: item.name);
      _amountController = TextEditingController(
        text: item.amount.toStringAsFixed(2).replaceAll('.', ','),
      );
      _selectedType = item.type;
      _selectedCurrency =
          appCurrencies.firstWhereOrNull((c) => c.code == item.currencyCode);
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _selectedCurrency = context.read<CurrencyProvider>().selectedCurrency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveLiability() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final walletProvider = context.read<WalletProvider>();
    final authService = context.read<AuthService>();
    final walletId = walletProvider.currentWallet?.id;
    final userId = authService.currentUser?.id;

    if (walletId == null || userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'РџРѕРјРёР»РєР°: РЅРµРјРѕР¶Р»РёРІРѕ Р·Р±РµСЂРµРіС‚Рё. РђРєС‚РёРІРЅРёР№ РіР°РјР°РЅРµС†СЊ Р°Р±Рѕ РєРѕСЂРёСЃС‚СѓРІР°С‡ РЅРµ Р·РЅР°Р№РґРµРЅРѕ.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final item = Liability(
      id: widget.liabilityToEdit?.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      amount: amount,
      currencyCode: _selectedCurrency!.code,
      updatedAt: DateTime.now(),
    );
    try {
      if (_isEditing) {
        await _repository.updateLiability(item);
      } else {
        await _repository.createLiability(item, walletId, userId);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('РџРѕРјРёР»РєР° Р·Р±РµСЂРµР¶РµРЅРЅСЏ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PatternedScaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Р РµРґР°РіСѓРІР°С‚Рё РџР°СЃРёРІ'
              : 'РќРѕРІРёР№ РџР°СЃРёРІ',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText:
                    'РќР°Р·РІР° РїР°СЃРёРІСѓ (РЅР°РїСЂ., Р†РїРѕС‚РµРєР° РІ РџСЂРёРІР°С‚Р‘Р°РЅРєСѓ)',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Р’РІРµРґС–С‚СЊ РЅР°Р·РІСѓ'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration:
                  const InputDecoration(labelText: 'РўРёРї РїР°СЃРёРІСѓ'),
              items: _liabilityTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'РЎСѓРјР°'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Р’РІРµРґС–С‚СЊ СЃСѓРјСѓ';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'РќРµРІС–СЂРЅРµ С‡РёСЃР»Рѕ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Currency>(
                    value: _selectedCurrency,
                    decoration:
                        const InputDecoration(labelText: 'Р’Р°Р»СЋС‚Р°'),
                    items: appCurrencies
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.code)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCurrency = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveLiability,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isEditing
                          ? 'Р—Р±РµСЂРµРіС‚Рё Р·РјС–РЅРё'
                          : 'РЎС‚РІРѕСЂРёС‚Рё РїР°СЃРёРІ',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
