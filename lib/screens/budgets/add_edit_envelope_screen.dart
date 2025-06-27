import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../models/budget_models.dart';
import '../../models/category.dart';
import '../../models/currency_model.dart';
import '../../providers/currency_provider.dart';
import '../../providers/wallet_provider.dart';

class AddEditEnvelopeScreen extends StatefulWidget {
  final int budgetId;
  final BudgetEnvelope? envelopeToEdit;
  const AddEditEnvelopeScreen({super.key, required this.budgetId, this.envelopeToEdit});

  @override
  State<AddEditEnvelopeScreen> createState() => _AddEditEnvelopeScreenState();
}

class _AddEditEnvelopeScreenState extends State<AddEditEnvelopeScreen> {
  final _formKey = GlobalKey<FormState>();
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  Category? _selectedCategory;
  Currency? _selectedCurrency;
  List<Category> _availableCategories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  bool get _isEditing => widget.envelopeToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditing) {
      final envelope = widget.envelopeToEdit!;
      _nameController = TextEditingController(text: envelope.name);
      _amountController = TextEditingController(text: envelope.originalPlannedAmount.toStringAsFixed(2).replaceAll('.', ','));
      _selectedCurrency = appCurrencies.firstWhereOrNull((c) => c.code == envelope.originalCurrencyCode);
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _selectedCurrency = context.read<CurrencyProvider>().selectedCurrency;
    }
  }

  Future<void> _loadCategories() async {
    final walletId = context.read<WalletProvider>().currentWallet!.id!;
    final categories = await _categoryRepository.getCategoriesByType(walletId, CategoryType.expense);
    final assignedCategories = (await _budgetRepository.getEnvelopesForBudget(widget.budgetId)).map((e) => e.categoryId).toSet();
    
    if (mounted) {
      setState(() {
        _availableCategories = categories.where((cat) {
          if (_isEditing && cat.id == widget.envelopeToEdit!.categoryId) {
            return true;
          }
          return !assignedCategories.contains(cat.id);
        }).toList();
        if (_isEditing) {
          _selectedCategory = _availableCategories.firstWhereOrNull((cat) => cat.id == widget.envelopeToEdit!.categoryId);
        }
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _saveEnvelope() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Будь ласка, оберіть категорію.')));
      return;
    }

    setState(() => _isSaving = true);
    
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    
    final envelope = BudgetEnvelope(
      id: widget.envelopeToEdit?.id,
      budgetId: widget.budgetId,
      name: _nameController.text.trim(),
      categoryId: _selectedCategory!.id!,
      originalPlannedAmount: amount,
      originalCurrencyCode: _selectedCurrency!.code,
      plannedAmountInBaseCurrency: amount,
      exchangeRateUsed: 1.0,
    );
    
    try {
      if (_isEditing) {
        await _budgetRepository.updateBudgetEnvelope(envelope);
      } else {
        await _budgetRepository.createBudgetEnvelope(envelope);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка збереження: $e')));
      }
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати Конверт' : 'Новий Конверт'),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Назва конверта'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Введіть назву' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Категорія витрат'),
                      items: _availableCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name))).toList(),
                      onChanged: (cat) => setState(() => _selectedCategory = cat),
                      validator: (value) => value == null ? 'Оберіть категорію' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(labelText: 'Запланована сума'),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEnvelope,
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'Зберегти Конверт' : 'Створити Конверт'),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}