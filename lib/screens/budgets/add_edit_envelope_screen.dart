import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/budget_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/models/budget_models.dart';
import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/models/currency_model.dart';
import 'package:sage_wallet_reborn/providers/currency_provider.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';

class AddEditEnvelopeScreen extends StatefulWidget {
  const AddEditEnvelopeScreen({
    required this.budgetId,
    this.envelopeToEdit,
    super.key,
  });
  final int budgetId;
  final BudgetEnvelope? envelopeToEdit;

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
      _amountController = TextEditingController(
        text: envelope.originalPlannedAmount
            .toStringAsFixed(2)
            .replaceAll('.', ','),
      );
      _selectedCurrency = appCurrencies
          .firstWhereOrNull((c) => c.code == envelope.originalCurrencyCode);
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

  Future<void> _loadCategories() async {
    final walletId = context.read<WalletProvider>().currentWallet!.id!;
    final categoriesEither = await _categoryRepository.getCategoriesByType(
      walletId,
      CategoryType.expense,
    );
    final assignedEnvelopesEither =
        await _budgetRepository.getEnvelopesForBudget(widget.budgetId);

    assignedEnvelopesEither.fold(
      (failure) {
        if (mounted) setState(() => _isLoadingCategories = false);
      },
      (assignedEnvelopes) {
        categoriesEither.fold(
          (failure) {
            if (mounted) setState(() => _isLoadingCategories = false);
          },
          (categories) {
            if (mounted) {
              final assignedCategoryIds =
                  assignedEnvelopes.map((e) => e.categoryId).toSet();
              setState(() {
                _availableCategories = categories.where((cat) {
                  if (_isEditing &&
                      cat.id == widget.envelopeToEdit!.categoryId) {
                    return true;
                  }
                  return !assignedCategoryIds.contains(cat.id);
                }).toList();
                if (_isEditing) {
                  _selectedCategory = _availableCategories.firstWhereOrNull(
                    (cat) => cat.id == widget.envelopeToEdit!.categoryId,
                  );
                }
                _isLoadingCategories = false;
              });
            }
          },
        );
      },
    );
  }

  Future<void> _saveEnvelope() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Р‘СѓРґСЊ Р»Р°СЃРєР°, РѕР±РµСЂС–С‚СЊ РєР°С‚РµРіРѕСЂС–СЋ.',
          ),
        ),
      );
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
      exchangeRateUsed: 1,
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
              ? 'Р РµРґР°РіСѓРІР°С‚Рё РљРѕРЅРІРµСЂС‚'
              : 'РќРѕРІРёР№ РљРѕРЅРІРµСЂС‚',
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'РќР°Р·РІР° РєРѕРЅРІРµСЂС‚Р°',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Р’РІРµРґС–С‚СЊ РЅР°Р·РІСѓ'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'РљР°С‚РµРіРѕСЂС–СЏ РІРёС‚СЂР°С‚',
                      ),
                      items: _availableCategories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.name),
                            ),
                          )
                          .toList(),
                      onChanged: (cat) =>
                          setState(() => _selectedCategory = cat),
                      validator: (value) => value == null
                          ? 'РћР±РµСЂС–С‚СЊ РєР°С‚РµРіРѕСЂС–СЋ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Р—Р°РїР»Р°РЅРѕРІР°РЅР° СЃСѓРјР°',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Р’РІРµРґС–С‚СЊ СЃСѓРјСѓ';
                              }
                              if (double.tryParse(value.replaceAll(',', '.')) ==
                                  null) {
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
                            decoration: const InputDecoration(
                              labelText: 'Р’Р°Р»СЋС‚Р°',
                            ),
                            items: appCurrencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.code),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCurrency = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEnvelope,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isEditing
                                  ? 'Р—Р±РµСЂРµРіС‚Рё РљРѕРЅРІРµСЂС‚'
                                  : 'РЎС‚РІРѕСЂРёС‚Рё РљРѕРЅРІРµСЂС‚',
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
