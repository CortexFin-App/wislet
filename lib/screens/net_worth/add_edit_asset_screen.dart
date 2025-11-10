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

  String _selectedType = 'Нерухомість';
  Currency? _selectedCurrency;
  bool _isSaving = false;

  bool get _isEditing => widget.assetToEdit != null;

  final List<String> _assetTypes = [
    'Нерухомість',
    'Автомобіль',
    'Інвестиції',
    'Криптовалюта',
    'Інше',
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
              'Помилка: неможливо зберегти. Активний гаманець або користувач не знайдено.',
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
          SnackBar(content: Text('Помилка збереження: $e')),
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
          _isEditing ? 'Редагувати Актив' : 'Новий Актив',
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
                    'Назва активу (напр., Квартира на Хрещатику)',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Введіть назву'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration:
                  const InputDecoration(labelText: 'Тип активу'),
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
                        const InputDecoration(labelText: 'Вартість'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введіть вартість';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Невірне число';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Currency>(
                    initialValue: _selectedCurrency,
                    decoration:
                        const InputDecoration(labelText: 'Валюта'),
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
                          ? 'Зберегти зміни'
                          : 'Створити актив',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
