import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/asset_repository.dart';
import 'package:wislet/models/asset.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/services/auth_service.dart';
import 'package:wislet/widgets/scaffold/patterned_scaffold.dart';

class AddEditAssetScreen extends StatefulWidget {
  const AddEditAssetScreen({super.key, this.assetToEdit});
  final Asset? assetToEdit;

  @override
  State<AddEditAssetScreen> createState() => _AddEditAssetScreenState();
}

class _AddEditAssetScreenState extends State<AddEditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final AssetRepository _repository = getIt<AssetRepository>();
  late TextEditingController _nameController;
  late TextEditingController _valueController;

  String _selectedType = 'РќРµСЂСѓС…РѕРјС–СЃС‚СЊ';
  Currency? _selectedCurrency;
  bool _isSaving = false;

  bool get _isEditing => widget.assetToEdit != null;

  final List<String> _assetTypes = [
    'РќРµСЂСѓС…РѕРјС–СЃС‚СЊ',
    'РђРІС‚РѕРјРѕР±С–Р»СЊ',
    'Р†РЅРІРµСЃС‚РёС†С–С—',
    'РљСЂРёРїС‚РѕРІР°Р»СЋС‚Р°',
    'Р†РЅС€Рµ',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.assetToEdit!;
      _nameController = TextEditingController(text: item.name);
      _valueController = TextEditingController(
        text: item.value.toStringAsFixed(2).replaceAll('.', ','),
      );
      _selectedType = item.type;
      _selectedCurrency =
          appCurrencies.firstWhereOrNull((c) => c.code == item.currencyCode);
    } else {
      _nameController = TextEditingController();
      _valueController = TextEditingController();
      _selectedCurrency = context.read<CurrencyProvider>().selectedCurrency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _saveAsset() async {
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
    final value = double.parse(_valueController.text.replaceAll(',', '.'));

    final item = Asset(
      id: widget.assetToEdit?.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      value: value,
      currencyCode: _selectedCurrency!.code,
      updatedAt: DateTime.now(),
    );
    try {
      if (_isEditing) {
        await _repository.updateAsset(item);
      } else {
        await _repository.createAsset(item, walletId, userId);
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
              ? 'Р РµРґР°РіСѓРІР°С‚Рё РђРєС‚РёРІ'
              : 'РќРѕРІРёР№ РђРєС‚РёРІ',
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
                    'РќР°Р·РІР° Р°РєС‚РёРІСѓ (РЅР°РїСЂ., РљРІР°СЂС‚РёСЂР° РЅР° РҐСЂРµС‰Р°С‚РёРєСѓ)',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Р’РІРµРґС–С‚СЊ РЅР°Р·РІСѓ'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration:
                  const InputDecoration(labelText: 'РўРёРї Р°РєС‚РёРІСѓ'),
              items: _assetTypes
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
                    controller: _valueController,
                    decoration:
                        const InputDecoration(labelText: 'Р’Р°СЂС‚С–СЃС‚СЊ'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Р’РІРµРґС–С‚СЊ РІР°СЂС‚С–СЃС‚СЊ';
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
              onPressed: _isSaving ? null : _saveAsset,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isEditing
                          ? 'Р—Р±РµСЂРµРіС‚Рё Р·РјС–РЅРё'
                          : 'РЎС‚РІРѕСЂРёС‚Рё Р°РєС‚РёРІ',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
