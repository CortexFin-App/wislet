import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/debt_loan_repository.dart';
import 'package:sage_wallet_reborn/models/currency_model.dart';
import 'package:sage_wallet_reborn/models/debt_loan_model.dart';
import 'package:sage_wallet_reborn/providers/currency_provider.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';

class AddEditDebtLoanScreen extends StatefulWidget {
  const AddEditDebtLoanScreen({this.debtLoanToEdit, super.key});
  final DebtLoan? debtLoanToEdit;

  @override
  State<AddEditDebtLoanScreen> createState() => _AddEditDebtLoanScreenState();
}

class _AddEditDebtLoanScreenState extends State<AddEditDebtLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final DebtLoanRepository _repository = getIt<DebtLoanRepository>();
  late TextEditingController _personNameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  DebtLoanType _selectedType = DebtLoanType.debt;
  Currency? _selectedCurrency;
  DateTime? _dueDate;
  bool _isSettled = false;
  bool _isSaving = false;

  bool get _isEditing => widget.debtLoanToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.debtLoanToEdit!;
      _personNameController = TextEditingController(text: item.personName);
      _amountController = TextEditingController(
        text: item.originalAmount.toStringAsFixed(2).replaceAll('.', ','),
      );
      _descriptionController = TextEditingController(text: item.description);
      _selectedType = item.type;
      _selectedCurrency =
          appCurrencies.firstWhereOrNull((c) => c.code == item.currencyCode);
      _dueDate = item.dueDate;
      _isSettled = item.isSettled;
    } else {
      _personNameController = TextEditingController();
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedCurrency = context.read<CurrencyProvider>().selectedCurrency;
    }
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  Future<void> _saveDebtLoan() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final walletProvider = context.read<WalletProvider>();
    final walletId = walletProvider.currentWallet?.id;

    if (walletId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'РџРѕРјРёР»РєР°: РЅРµРјРѕР¶Р»РёРІРѕ Р·Р±РµСЂРµРіС‚Рё. РђРєС‚РёРІРЅРёР№ РіР°РјР°РЅРµС†СЊ РЅРµ Р·РЅР°Р№РґРµРЅРѕ.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final item = DebtLoan(
      id: widget.debtLoanToEdit?.id,
      walletId: walletId,
      type: _selectedType,
      personName: _personNameController.text.trim(),
      description: _descriptionController.text.trim(),
      originalAmount: amount,
      currencyCode: _selectedCurrency!.code,
      amountInBaseCurrency: amount,
      creationDate:
          _isEditing ? widget.debtLoanToEdit!.creationDate : DateTime.now(),
      dueDate: _dueDate,
      isSettled: _isSettled,
    );
    try {
      if (_isEditing) {
        await _repository.updateDebtLoan(item);
      } else {
        await _repository.createDebtLoan(item, walletId);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Р РµРґР°РіСѓРІР°С‚Рё Р—Р°РїРёСЃ'
              : 'РќРѕРІРёР№ Р—Р°РїРёСЃ',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<DebtLoanType>(
              segments: const [
                ButtonSegment(
                  value: DebtLoanType.debt,
                  label: Text('РЇ РІРёРЅРµРЅ'),
                  icon: Icon(Icons.arrow_circle_up_rounded),
                ),
                ButtonSegment(
                  value: DebtLoanType.loan,
                  label: Text('РњРµРЅС– РІРёРЅРЅС–'),
                  icon: Icon(Icons.arrow_circle_down_rounded),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (newSelection) {
                setState(() => _selectedType = newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _personNameController,
              decoration: const InputDecoration(
                labelText:
                    "Р†Рј'СЏ РѕСЃРѕР±Рё Р°Р±Рѕ РЅР°Р·РІР° РѕСЂРіР°РЅС–Р·Р°С†С–С—",
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? "Р’РІРµРґС–С‚СЊ С–Рј'СЏ"
                  : null,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'РћРїРёСЃ (РѕРїС†С–РѕРЅР°Р»СЊРЅРѕ)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _dueDate == null
                    ? 'РўРµСЂРјС–РЅ РїРѕРІРµСЂРЅРµРЅРЅСЏ (РѕРїС†С–РѕРЅР°Р»СЊРЅРѕ)'
                    : 'РџРѕРІРµСЂРЅСѓС‚Рё РґРѕ: ${DateFormat('dd.MM.yyyy').format(_dueDate!)}',
              ),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : null,
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Р—Р°РїРёСЃ РїРѕРіР°С€РµРЅРѕ/Р·Р°РєСЂРёС‚Рѕ'),
              value: _isSettled,
              onChanged: (val) => setState(() => _isSettled = val),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveDebtLoan,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isEditing
                          ? 'Р—Р±РµСЂРµРіС‚Рё Р·РјС–РЅРё'
                          : 'РЎС‚РІРѕСЂРёС‚Рё Р·Р°РїРёСЃ',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
