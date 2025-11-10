import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/data/repositories/plan_repository.dart';
import 'package:wislet/models/category.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/plan.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/services/exchange_rate_service.dart';

class AddEditPlanScreen extends StatefulWidget {
  const AddEditPlanScreen({super.key, this.planToEdit, this.initialDate});
  final Plan? planToEdit;
  final DateTime? initialDate;

  @override
  State<AddEditPlanScreen> createState() => _AddEditPlanScreenState();
}

class _AddEditPlanScreenState extends State<AddEditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final PlanRepository _planRepository = getIt<PlanRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _manualRateController = TextEditingController();

  Category? _selectedCategory;
  late DateTime _startDate;
  late DateTime _endDate;

  Currency? _selectedPlanCurrency;
  final List<Currency> _availableCurrencies = appCurrencies;

  List<Category> _availableCategories = [];
  bool _isLoadingCategories = false;
  bool _isSaving = false;
  bool get _isEditing => widget.planToEdit != null;

  final String _baseCurrencyCode = 'UAH';

  bool _isFetchingRate = false;
  String? _rateFetchingError;
  ConversionRateInfo? _currentRateInfo;

  bool _isManuallyEnteringRate = false;
  bool _manualRateSetByButton = false;

  @override
  void initState() {
    super.initState();

    _selectedPlanCurrency = _availableCurrencies.firstWhere(
      (c) => c.code == _baseCurrencyCode,
      orElse: () => _availableCurrencies.first,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });

    if (_isEditing) {
      final plan = widget.planToEdit!;
      _amountController.text =
          plan.originalPlannedAmount.toStringAsFixed(2).replaceAll('.', ',');
      _startDate = plan.startDate;
      _endDate = plan.endDate;

      _selectedPlanCurrency = _availableCurrencies.firstWhere(
        (c) => c.code == plan.originalCurrencyCode,
        orElse: () => _availableCurrencies
            .firstWhere((curr) => curr.code == _baseCurrencyCode),
      );

      if (plan.exchangeRateUsed != null &&
          plan.originalCurrencyCode != _baseCurrencyCode) {
        _currentRateInfo = ConversionRateInfo(
          rate: plan.exchangeRateUsed!,
          effectiveRateDate: plan.startDate,
          isRateStale: true,
        );
      } else if (_selectedPlanCurrency!.code != _baseCurrencyCode) {
        _fetchAndSetExchangeRate(currency: _selectedPlanCurrency);
      } else {
        _currentRateInfo = ConversionRateInfo(
          rate: 1,
          effectiveRateDate: _startDate,
        );
      }
    } else {
      final now = DateTime.now();
      if (widget.initialDate != null) {
        _startDate =
            DateTime(widget.initialDate!.year, widget.initialDate!.month);
        _endDate = DateTime(
          widget.initialDate!.year,
          widget.initialDate!.month + 1,
          0,
        );
      } else {
        _startDate = DateTime(now.year, now.month);
        _endDate = DateTime(now.year, now.month + 1, 0);
      }

      if (_selectedPlanCurrency!.code != _baseCurrencyCode) {
        _fetchAndSetExchangeRate(currency: _selectedPlanCurrency);
      } else {
        _currentRateInfo = ConversionRateInfo(
          rate: 1,
          effectiveRateDate: _startDate,
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _manualRateController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSetExchangeRate({
    Currency? currency,
    bool calledFromManualCancel = false,
  }) async {
    final targetCurrency = currency ?? _selectedPlanCurrency;
    final rateDateForPlan = DateTime.now();

    if (targetCurrency == null || targetCurrency.code == _baseCurrencyCode) {
      if (mounted) {
        setState(() {
          _currentRateInfo = ConversionRateInfo(
            rate: 1,
            effectiveRateDate: rateDateForPlan,
          );
          _rateFetchingError = null;
          _isFetchingRate = false;
          _isManuallyEnteringRate = false;
          _manualRateSetByButton = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isFetchingRate = true;
        _rateFetchingError = null;
        _currentRateInfo = null;
        if (!calledFromManualCancel) {
          _isManuallyEnteringRate = false;
          _manualRateSetByButton = false;
        }
      });
    }

    try {
      final rateInfo = await _exchangeRateService.getConversionRate(
        targetCurrency.code,
        _baseCurrencyCode,
        date: rateDateForPlan,
      );
      if (mounted) {
        setState(() {
          _currentRateInfo = rateInfo;
          _manualRateSetByButton = false;
          _manualRateController.clear();
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _rateFetchingError =
              'Курс для ${targetCurrency.code}: помилка отримання.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRate = false;
        });
      }
    }
  }

  void _applyManualRate() {
    final manualRate =
        double.tryParse(_manualRateController.text.replaceAll(',', '.'));
    if (manualRate != null && manualRate > 0) {
      if (mounted) {
        setState(() {
          _currentRateInfo = ConversionRateInfo(
            rate: manualRate,
            effectiveRateDate: DateTime.now(),
            isRateStale: true,
          );
          _manualRateSetByButton = true;
          _isManuallyEnteringRate = false;
          _rateFetchingError = null;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) return;

    setState(() => _isLoadingCategories = true);
    final categoriesEither = await _categoryRepository.getCategoriesByType(
      currentWalletId,
      CategoryType.expense,
    );
    if (!mounted) return;

    categoriesEither.fold(
      (failure) {
        setState(() {
          _availableCategories = [];
          _isLoadingCategories = false;
        });
      },
      (categories) {
        if (mounted) {
          setState(() {
            _availableCategories = categories;
            if (_isEditing &&
                categories
                    .any((cat) => cat.id == widget.planToEdit!.categoryId)) {
              _selectedCategory = categories
                  .firstWhere((cat) => cat.id == widget.planToEdit!.categoryId);
            }
            _isLoadingCategories = false;
          });
        }
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final initial = isStartDate ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null && !_isEditing) return;

    final originalAmount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (originalAmount == null ||
        originalAmount <= 0 ||
        _selectedCategory == null ||
        _selectedPlanCurrency == null) {
      return;
    }

    double? finalExchangeRate;
    if (_selectedPlanCurrency!.code == _baseCurrencyCode) {
      finalExchangeRate = 1.0;
    } else if (_manualRateSetByButton && _currentRateInfo != null) {
      finalExchangeRate = _currentRateInfo!.rate;
    } else if (_currentRateInfo != null &&
        !_currentRateInfo!.isRateStale &&
        _rateFetchingError == null &&
        !_isFetchingRate &&
        _currentRateInfo!.rate > 0) {
      finalExchangeRate = _currentRateInfo!.rate;
    }

    if (finalExchangeRate == null || finalExchangeRate <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не вдалося визначити курс для ${_selectedPlanCurrency!.code}.',
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final amountInBase = originalAmount * finalExchangeRate;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final plan = Plan(
      id: widget.planToEdit?.id,
      categoryId: _selectedCategory!.id!,
      originalPlannedAmount: originalAmount,
      originalCurrencyCode: _selectedPlanCurrency!.code,
      plannedAmountInBaseCurrency: amountInBase,
      exchangeRateUsed: finalExchangeRate,
      startDate: _startDate,
      endDate: _endDate,
    );

    final result = _isEditing
        ? await _planRepository.updatePlan(plan)
     : await _planRepository.createPlan(plan, currentWalletId!);

    if (!mounted) return;

    result.fold(
        (failure) {
         messenger.showSnackBar(
        SnackBar(
         content: Text(
           'Помилка збереження плану: ${failure.userMessage}',
             ),
            ),
           );
        },
    (_) {
        messenger.showSnackBar(
        SnackBar(
          content: Text(
           _isEditing ? 'План оновлено!' : 'План створено!',
          ),
         ),
        );
        navigator.pop(true);
     },
    );



    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_isSaving &&
        (_selectedPlanCurrency?.code == _baseCurrencyCode ||
            (_manualRateSetByButton &&
                _currentRateInfo != null &&
                _currentRateInfo!.rate > 0) ||
            (_currentRateInfo != null &&
                !_currentRateInfo!.isRateStale &&
                _rateFetchingError == null &&
                !_isFetchingRate &&
                _currentRateInfo!.rate > 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редагувати План' : 'Створити План',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              if (_isLoadingCategories)
                const Center(child: CircularProgressIndicator())
              else if (_availableCategories.isEmpty)
                Text(
                  'Немає доступних категорій витрат. Спочатку додайте їх на екрані категорій.',
                  style: TextStyle(color: Colors.orange[700]),
                )
              else
                DropdownButtonFormField<Category>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Категорія витрат',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  hint: const Text('Оберіть категорію'),
                  isExpanded: true,
                  items: _availableCategories
                      .map(
                        (category) => DropdownMenuItem<Category>(
                          value: category,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (newValue) {
                    if (mounted) {
                      setState(() => _selectedCategory = newValue);
                    }
                  },
                  validator: (value) => value == null
                      ? 'Будь ласка, оберіть категорію'
                      : null,
                ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Запланована сума',
                        border: const OutlineInputBorder(),
                        prefixIcon: _selectedPlanCurrency != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                                child: Text(
                                  _selectedPlanCurrency!.symbol,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть суму';
                        }
                        final cleanValue = value.replaceAll(',', '.');
                        if (double.tryParse(cleanValue) == null) {
                          return 'Введіть коректне число';
                        }
                        if (double.parse(cleanValue) <= 0) {
                          return 'Сума > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<Currency>(
                      initialValue: _selectedPlanCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Валюта',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableCurrencies
                          .map(
                            (currency) => DropdownMenuItem<Currency>(
                              value: currency,
                              child: Text(currency.code),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        if (mounted && newValue != null) {
                          setState(() {
                            _selectedPlanCurrency = newValue;
                            _isManuallyEnteringRate = false;
                            _manualRateSetByButton = false;
                            _manualRateController.clear();
                          });
                          _fetchAndSetExchangeRate(currency: newValue);
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Оберіть' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isFetchingRate)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (!_isFetchingRate &&
                  _rateFetchingError != null &&
                  !_isManuallyEnteringRate &&
                  _selectedPlanCurrency?.code != _baseCurrencyCode)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        _rateFetchingError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        child: const Text('Ввести курс вручну?'),
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              _isManuallyEnteringRate = true;
                              _rateFetchingError = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              if (_isManuallyEnteringRate &&
                  _selectedPlanCurrency?.code != _baseCurrencyCode)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _manualRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '1 ${_selectedPlanCurrency?.code} = X UAH',
                            hintText: 'Введіть курс',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_isManuallyEnteringRate) {
                              if (value == null || value.isEmpty) {
                                return 'Вкажіть курс';
                              }
                              final val = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
                              if (val == null || val <= 0) {
                                return 'Невірне значення';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        tooltip: 'Застосувати курс',
                        onPressed: _applyManualRate,
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        tooltip: 'Скасувати ручне введення',
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              _isManuallyEnteringRate = false;
                              _manualRateSetByButton = false;
                              _manualRateController.clear();
                            });
                          }
                          _fetchAndSetExchangeRate(
                            calledFromManualCancel: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              if (!_isFetchingRate &&
                  _rateFetchingError == null &&
                  _currentRateInfo != null &&
                  _selectedPlanCurrency?.code != _baseCurrencyCode)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    _manualRateSetByButton
                        ? 'Встановлено вручну: 1 ${_selectedPlanCurrency!.code} = ${_currentRateInfo!.rate.toStringAsFixed(4)} $_baseCurrencyCode'
                        : '1 ${_selectedPlanCurrency!.code} ≈ ${_currentRateInfo!.rate.toStringAsFixed(4)} $_baseCurrencyCode на ${DateFormat('dd.MM.yy').format(_currentRateInfo!.effectiveRateDate)}${_currentRateInfo!.isRateStale ? ' (застарілий)' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _manualRateSetByButton
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Період планування:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        'З: ${DateFormat('dd.MM.yyyy').format(_startDate)}',
                      ),
                      onPressed: () => _pickDate(context, isStartDate: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'По: ${DateFormat('dd.MM.yyyy').format(_endDate)}',
                      ),
                      onPressed: () => _pickDate(context, isStartDate: false),
                    ),
                  ),
                ],
              ),
              if (_endDate.isBefore(_startDate))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Дата закінчення не може бути раніше дати початку.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _isEditing ? 'Зберегти зміни' : 'Створити план',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: (canSave && !_endDate.isBefore(_startDate))
                      ? _savePlan
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
