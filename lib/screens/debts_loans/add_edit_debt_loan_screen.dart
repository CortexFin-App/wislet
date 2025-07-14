import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../core/di/injector.dart';
import '../../models/debt_loan_model.dart';
import '../../models/currency_model.dart';
import '../../providers/wallet_provider.dart';
import '../../data/repositories/debt_loan_repository.dart';
import '../../providers/currency_provider.dart';

class AddEditDebtLoanScreen extends StatefulWidget {
  final DebtLoan? debtLoanToEdit;
  const AddEditDebtLoanScreen({super.key, this.debtLoanToEdit});

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
      _amountController = TextEditingController(text: item.originalAmount.toStringAsFixed(2).replaceAll('.',','));
      _descriptionController = TextEditingController(text: item.description);
      _selectedType = item.type;
      _selectedCurrency = appCurrencies.firstWhereOrNull((c) => c.code == item.currencyCode);
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
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка: неможливо зберегти. Активний гаманець не знайдено.'))
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
      creationDate: _isEditing ? widget.debtLoanToEdit!.creationDate : DateTime.now(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка збереження: $e')));
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
        title: Text(_isEditing ? 'Редагувати Запис' : 'Новий Запис'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SegmentedButton<DebtLoanType>(
              segments: const [
                ButtonSegment(value: DebtLoanType.debt, label: Text('Я винен'), icon: Icon(Icons.arrow_circle_up_rounded)),
                ButtonSegment(value: DebtLoanType.loan, label: Text('Мені винні'), icon: Icon(Icons.arrow_circle_down_rounded)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (newSelection) {
                setState(() => _selectedType = newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _personNameController,
              decoration: const InputDecoration(labelText: 'Ім\'я особи або назва організації'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Введіть ім\'я' : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Сума'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введіть суму';
                      if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Невірне число';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Currency>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(labelText: 'Валюта'),
                    items: appCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c.code))).toList(),
                    onChanged: (val) => setState(() => _selectedCurrency = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Опис (опціонально)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_dueDate == null ? 'Термін повернення (опціонально)' : 'Повернути до: ${DateFormat('dd.MM.yyyy').format(_dueDate!)}'),
              trailing: _dueDate != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null)) : null,
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Запис погашено/закрито'),
              value: _isSettled,
              onChanged: (val) => setState(() => _isSettled = val),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveDebtLoan,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'Зберегти зміни' : 'Створити запис'),
            ),
          ],
        ),
      ),
    );
  }
}