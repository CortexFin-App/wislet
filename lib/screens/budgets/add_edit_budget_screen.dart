import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/budget_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/models/budget_models.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';

class AddEditBudgetScreen extends StatefulWidget {
  const AddEditBudgetScreen({
    super.key,
    this.budgetToEdit,
    this.isFirstBudgetForCategory,
  });
  final Budget? budgetToEdit;
  final int? isFirstBudgetForCategory;

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
      _startDate = DateTime(now.year, now.month);
      _endDate = DateTime(now.year, now.month + 1, 0);
      _nameController = TextEditingController(
        text: 'Р‘СЋРґР¶РµС‚ РЅР° ${DateFormat.yMMMM('uk_UA').format(now)}',
      );
    }

    if (_isFirstBudgetFlow) {
      _selectedStrategy = BudgetStrategyType.categoryBased;
      _fetchCategoryNameAndSetName();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoryNameAndSetName() async {
    final categoryId = widget.isFirstBudgetForCategory;
    if (categoryId == null) return;

    final categoryNameResult =
        await _categoryRepository.getCategoryNameById(categoryId);
    categoryNameResult.fold(
      (l) => null,
      (name) {
        if (mounted) {
          setState(() {
            _nameController.text = 'Р‘СЋРґР¶РµС‚ РЅР° "$name"';
          });
        }
      },
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
          const SnackBar(
            content: Text(
              'РџРѕРјРёР»РєР°: Р°РєС‚РёРІРЅРёР№ РіР°РјР°РЅРµС†СЊ РЅРµ Р·РЅР°Р№РґРµРЅРѕ.',
            ),
          ),
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
        final amount =
            double.parse(_amountController.text.replaceAll(',', '.'));
        final newBudgetResult =
            await _budgetRepository.createBudget(budget, walletId);
        await newBudgetResult.fold((l) => throw l, (newBudgetId) async {
          final envelope = BudgetEnvelope(
            budgetId: newBudgetId,
            name: 'Р›С–РјС–С‚ РЅР° РєР°С‚РµРіРѕСЂС–СЋ',
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
    if (_isFirstBudgetFlow) {
      return _buildFirstBudgetDialog();
    }
    return _buildFullEditor();
  }

  Widget _buildFirstBudgetDialog() {
    return AlertDialog(
      title: const Text('РЎС‚РІРѕСЂРёРјРѕ РїРµСЂС€РёР№ Р±СЋРґР¶РµС‚'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Р§СѓРґРѕРІРѕ! РўРµРїРµСЂ РІСЃС‚Р°РЅРѕРІС–С‚СЊ РјС–СЃСЏС‡РЅРёР№ Р»С–РјС–С‚ РґР»СЏ РєР°С‚РµРіРѕСЂС–С—, СЏРєСѓ РІРё С‰РѕР№РЅРѕ РІРёРєРѕСЂРёСЃС‚Р°Р»Рё. Р¦Рµ РґРѕРїРѕРјРѕР¶Рµ РІР°Рј РєРѕРЅС‚СЂРѕР»СЋРІР°С‚Рё РІРёС‚СЂР°С‚Рё.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'РќР°Р·РІР° Р±СЋРґР¶РµС‚Сѓ'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Р’РІРµРґС–С‚СЊ РЅР°Р·РІСѓ'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Р’СЃС‚Р°РЅРѕРІС–С‚СЊ Р»С–РјС–С‚, РіСЂРЅ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Р’РІРµРґС–С‚СЊ СЃСѓРјСѓ';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'РЎСѓРјР° РјР°С” Р±СѓС‚Рё Р±С–Р»СЊС€РѕСЋ Р·Р° РЅСѓР»СЊ';
                }
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
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Р“РѕС‚РѕРІРѕ'),
        ),
      ],
    );
  }

  Widget _buildFullEditor() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Р РµРґР°РіСѓРІР°С‚Рё Р‘СЋРґР¶РµС‚'
              : 'РЎС‚РІРѕСЂРёС‚Рё Р‘СЋРґР¶РµС‚',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'РќР°Р·РІР° Р±СЋРґР¶РµС‚Сѓ',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Р’РІРµРґС–С‚СЊ РЅР°Р·РІСѓ'
                    : null,
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                tileColor: Theme.of(context).colorScheme.surface,
                leading: const Icon(Icons.date_range_outlined),
                title: const Text('РџРµСЂС–РѕРґ Р±СЋРґР¶РµС‚Сѓ'),
                subtitle: Text(
                  '${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}',
                ),
                onTap: _pickDateRange,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<BudgetStrategyType>(
                value: _selectedStrategy,
                decoration: const InputDecoration(
                  labelText: 'РЎС‚СЂР°С‚РµРіС–СЏ Р±СЋРґР¶РµС‚СѓРІР°РЅРЅСЏ',
                  prefixIcon: Icon(Icons.rule_rounded),
                ),
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
                title: const Text('Р‘СЋРґР¶РµС‚ Р°РєС‚РёРІРЅРёР№'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                tileColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveBudget,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Р—Р±РµСЂРµРіС‚Рё Р‘СЋРґР¶РµС‚'
                            : 'РЎС‚РІРѕСЂРёС‚Рё Р‘СЋРґР¶РµС‚',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
