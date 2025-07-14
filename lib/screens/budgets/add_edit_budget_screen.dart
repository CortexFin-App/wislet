import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../models/budget_models.dart';
import '../../providers/wallet_provider.dart';

class AddEditBudgetScreen extends StatefulWidget {
  final Budget? budgetToEdit;
  final int? isFirstBudgetForCategory;
  const AddEditBudgetScreen({super.key, this.budgetToEdit, this.isFirstBudgetForCategory});

  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late DateTime _startDate;
  late DateTime _endDate;
  BudgetStrategyType _selectedStrategy = BudgetStrategyType.envelope;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.budgetToEdit != null;
  bool get _isFirstBudgetFlow => widget.isFirstBudgetForCategory != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();

    if (_isEditing) {
      final budget = widget.budgetToEdit!;
      _nameController = TextEditingController(text: budget.name);
      _startDate = budget.startDate;
      _endDate = budget.endDate;
      _selectedStrategy = budget.strategyType;
      _isActive = budget.isActive;
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
      _nameController = TextEditingController(text: 'Бюджет на ${DateFormat.yMMMM('uk_UA').format(now)}');
    }

    if (_isFirstBudgetFlow) {
      _selectedStrategy = BudgetStrategyType.categoryBased;
      _fetchCategoryNameAndSetName();
    }
  }

  Future<void> _fetchCategoryNameAndSetName() async {
    final categoryId = widget.isFirstBudgetForCategory;
    if (categoryId == null) return;
    
    final categoryNameResult = await _categoryRepository.getCategoryNameById(categoryId);
    categoryNameResult.fold(
      (l) => null,
      (name) {
        if (mounted) {
          setState(() {
            _nameController.text = 'Бюджет на "$name"';
          });
        }
      }
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка: активний гаманець не знайдено.'))
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final budget = Budget(
      id: widget.budgetToEdit?.id,
      name: _nameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      strategyType: _selectedStrategy,
      isActive: _isActive,
    );
    
    try {
      if (_isFirstBudgetFlow) {
        // Simplified flow for onboarding
        final amount = double.parse(_amountController.text.replaceAll(',', '.'));
        final newBudgetResult = await _budgetRepository.createBudget(budget, walletId);
        await newBudgetResult.fold((l) => throw l, (newBudgetId) async {
          final envelope = BudgetEnvelope(
            budgetId: newBudgetId,
            name: 'Ліміт на категорію',
            categoryId: widget.isFirstBudgetForCategory!,
            originalPlannedAmount: amount,
            originalCurrencyCode: 'UAH',
            plannedAmountInBaseCurrency: amount,
          );
          await _budgetRepository.createBudgetEnvelope(envelope);
        });
      } else {
         if (_isEditing) {
          await _budgetRepository.updateBudget(budget);
        } else {
          await _budgetRepository.createBudget(budget, walletId);
        }
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
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstBudgetFlow) {
      return _buildFirstBudgetDialog();
    }
    return _buildFullEditor();
  }

  Widget _buildFirstBudgetDialog() {
    return AlertDialog(
      title: const Text('Створимо перший бюджет'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Чудово! Тепер встановіть місячний ліміт для категорії, яку ви щойно використали. Це допоможе вам контролювати витрати.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Назва бюджету'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Введіть назву' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Встановіть ліміт, грн'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Введіть суму';
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) return 'Сума має бути більшою за нуль';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _isSaving ? null : _saveBudget,
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text('Готово'),
        ),
      ],
    );
  }

  Widget _buildFullEditor() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати Бюджет' : 'Створити Бюджет'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Назва бюджету', prefixIcon: Icon(Icons.drive_file_rename_outline)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Введіть назву' : null,
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline)
                ),
                tileColor: Theme.of(context).colorScheme.surface,
                leading: const Icon(Icons.date_range_outlined),
                title: const Text('Період бюджету'),
                subtitle: Text('${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}'),
                onTap: _pickDateRange,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<BudgetStrategyType>(
                value: _selectedStrategy,
                decoration: const InputDecoration(labelText: 'Стратегія бюджетування', prefixIcon: Icon(Icons.rule_rounded)),
                items: BudgetStrategyType.values.map((strategy) {
                  return DropdownMenuItem(
                    value: strategy,
                    child: Text(budgetStrategyTypeToString(strategy)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStrategy = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Бюджет активний'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveBudget,
                child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Зберегти Бюджет' : 'Створити Бюджет'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}