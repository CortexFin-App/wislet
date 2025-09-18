import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/wallet.dart';
import 'package:wislet/providers/wallet_provider.dart';

class CreateTransferScreen extends StatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  State<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class _CreateTransferScreenState extends State<CreateTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransactionRepository _transactionRepo = getIt<TransactionRepository>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Wallet? _fromWallet;
  Wallet? _toWallet;
  Currency? _selectedCurrency;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final walletProvider = context.read<WalletProvider>();
    if (walletProvider.wallets.isNotEmpty) {
      _fromWallet = walletProvider.currentWallet;
      _toWallet = walletProvider.wallets
          .firstWhereOrNull((w) => w.id != _fromWallet?.id);
    }
    _selectedCurrency = appCurrencies.firstWhere((c) => c.code == 'UAH');
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransfer() async {
    if (!_isFormValid() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _transactionRepo.createTransfer(
        fromWallet: _fromWallet!,
        toWallet: _toWallet!,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        currencyCode: _selectedCurrency!.code,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('РџРѕРјРёР»РєР° РїРµСЂРµРєР°Р·Сѓ: $e')),
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
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.wallets;

    if (wallets.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('РќРѕРІРёР№ РїРµСЂРµРєР°Р·')),
        body: const Center(
          child: Text(
            'Р”Р»СЏ Р·РґС–Р№СЃРЅРµРЅРЅСЏ РїРµСЂРµРєР°Р·С–РІ РїРѕС‚СЂС–Р±РЅРѕ РјР°С‚Рё С…РѕС‡Р° Р± РґРІР° РіР°РјР°РЅС†С–.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('РќРѕРІРёР№ РїРµСЂРµРєР°Р·'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: (_isFormValid() && !_isSaving) ? _saveTransfer : null,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Wallet>(
              value: _fromWallet,
              decoration: const InputDecoration(
                labelText: 'Р— РіР°РјР°РЅС†СЏ',
                border: OutlineInputBorder(),
              ),
              items: wallets
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
                  .toList(),
              onChanged: (wallet) {
                if (wallet == _toWallet) {
                  setState(() {
                    _toWallet = null;
                  });
                }
                setState(() => _fromWallet = wallet);
              },
              validator: (v) =>
                  v == null ? 'РћР±РµСЂС–С‚СЊ РіР°РјР°РЅРµС†СЊ' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Wallet>(
              value: _toWallet,
              decoration: const InputDecoration(
                labelText: 'РќР° РіР°РјР°РЅРµС†СЊ',
                border: OutlineInputBorder(),
              ),
              items: wallets
                  .where((w) => w.id != _fromWallet?.id)
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
                  .toList(),
              onChanged: (wallet) => setState(() => _toWallet = wallet),
              validator: (v) =>
                  v == null ? 'РћР±РµСЂС–С‚СЊ РіР°РјР°РЅРµС†СЊ' : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'РЎСѓРјР°',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Р’РІРµРґС–С‚СЊ СЃСѓРјСѓ';
                      }
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'РќРµРІС–СЂРЅРµ С‡РёСЃР»Рѕ';
                      }
                      if (double.parse(v.replaceAll(',', '.')) <= 0) {
                        return 'РЎСѓРјР° > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<Currency>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Р’Р°Р»СЋС‚Р°',
                      border: OutlineInputBorder(),
                    ),
                    items: appCurrencies
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.code)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCurrency = val),
                    validator: (v) => v == null ? 'РћР±РµСЂС–С‚СЊ' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Р”Р°С‚Р°: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}",
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'РћРїРёСЃ (РѕРїС†С–РѕРЅР°Р»СЊРЅРѕ)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_isFormValid() && !_isSaving) ? _saveTransfer : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Р—РґС–Р№СЃРЅРёС‚Рё РїРµСЂРµРєР°Р·'),
            ),
          ],
        ),
      ),
    );
  }
}
