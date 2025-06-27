import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/budget_repository.dart';
import '../../models/budget_models.dart';
import '../../providers/wallet_provider.dart';

class AddEditBudgetScreen extends StatefulWidget {
  final Budget? budgetToEdit;
  const AddEditBudgetScreen({super.key, this.budgetToEdit});

  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  late TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  BudgetStrategyType _selectedStrategy = BudgetStrategyType.envelope;
  bool _isActive = true;

  bool get _isEditing => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final budget = widget.budgetToEdit!;
      _nameController = TextEditingController(text: budget.name);
      _startDate = budget.startDate;
      _endDate = budget.endDate;
      _selectedStrategy = budget.strategyType;
      _isActive = budget.isActive;
    } else {
      _nameController = TextEditingController();
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final walletId = context.read<WalletProvider>().currentWallet!.id!;
    final budget = Budget(
      id: widget.budgetToEdit?.id,
      name: _nameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      strategyType: _selectedStrategy,
      isActive: _isActive,
    );
    try {
      if (_isEditing) {
        await _budgetRepository.updateBudget(budget);
      } else {
        await _budgetRepository.createBudget(budget, walletId);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка збереження: $e')));
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Назва бюджету'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Введіть назву' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range_outlined),
                title: const Text('Період бюджету'),
                subtitle: Text('${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}'),
                onTap: _pickDateRange,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetStrategyType>(
                value: _selectedStrategy,
                decoration: const InputDecoration(labelText: 'Стратегія бюджетування'),
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
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveBudget,
                child: Text(_isEditing ? 'Зберегти Бюджет' : 'Створити Бюджет'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}