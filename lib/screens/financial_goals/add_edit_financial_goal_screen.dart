import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../models/financial_goal.dart';
import '../../models/currency_model.dart';
import '../../providers/currency_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../data/repositories/goal_repository.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/notification_service.dart';

class AddEditFinancialGoalScreen extends StatefulWidget {
  final FinancialGoal? goalToEdit;
  const AddEditFinancialGoalScreen({super.key, this.goalToEdit});

  @override
  State<AddEditFinancialGoalScreen> createState() =>
      _AddEditFinancialGoalScreenState();
}

class _AddEditFinancialGoalScreenState
    extends State<AddEditFinancialGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final GoalRepository _goalRepository = getIt<GoalRepository>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();
  final NotificationService _notificationService = getIt<NotificationService>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentAmountController;
  late TextEditingController _notesController;

  DateTime? _targetDate;
  DateTime _creationDate = DateTime.now();
  Currency? _selectedGoalCurrency;
  final List<Currency> _availableCurrencies = appCurrencies;
  final String _baseCurrencyCode = 'UAH';

  bool _isSaving = false;
  bool _isFetchingRate = false;
  String? _rateFetchingError;
  ConversionRateInfo? _currentRateInfo;

  bool _isManuallyEnteringRate = false;
  final TextEditingController _manualRateController = TextEditingController();
  bool _manualRateSetByButton = false;

  bool get _isEditing => widget.goalToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goalToEdit?.name);
    _notesController = TextEditingController(text: widget.goalToEdit?.notes);
    _creationDate = widget.goalToEdit?.creationDate ?? DateTime.now();
    _targetDate = widget.goalToEdit?.targetDate;

    if (_isEditing) {
      final goal = widget.goalToEdit!;
      _targetAmountController = TextEditingController(
          text: goal.originalTargetAmount
              .toStringAsFixed(goal.currencyCode == 'UAH' ? 2 : 2)
              .replaceAll('.', ','));
      _currentAmountController = TextEditingController(
          text: goal.originalCurrentAmount
              .toStringAsFixed(goal.currencyCode == 'UAH' ? 2 : 2)
              .replaceAll('.', ','));
      _selectedGoalCurrency = _availableCurrencies.firstWhere(
        (c) => c.code == goal.currencyCode,
        orElse: () => _availableCurrencies
            .firstWhere((curr) => curr.code == _baseCurrencyCode),
      );

      if (goal.exchangeRateUsed != null &&
          goal.currencyCode != _baseCurrencyCode) {
        _currentRateInfo = ConversionRateInfo(
            rate: goal.exchangeRateUsed!,
            effectiveRateDate: goal.creationDate,
            isRateStale: true);
      } else if (_selectedGoalCurrency!.code != _baseCurrencyCode) {
        _fetchAndSetExchangeRate(currency: _selectedGoalCurrency);
      } else {
        _currentRateInfo = ConversionRateInfo(
            rate: 1.0, effectiveRateDate: DateTime.now(), isRateStale: false);
      }
    } else {
      _targetAmountController = TextEditingController();
      _currentAmountController = TextEditingController(text: '0');
      final globalDisplayCurrency =
          Provider.of<CurrencyProvider>(context, listen: false).selectedCurrency;
      _selectedGoalCurrency = _availableCurrencies.firstWhere(
        (c) => c.code == globalDisplayCurrency.code,
        orElse: () => _availableCurrencies
            .firstWhere((curr) => curr.code == _baseCurrencyCode),
      );

      if (_selectedGoalCurrency!.code != _baseCurrencyCode) {
        _fetchAndSetExchangeRate(currency: _selectedGoalCurrency);
      } else {
        _currentRateInfo = ConversionRateInfo(
            rate: 1.0, effectiveRateDate: DateTime.now(), isRateStale: false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _notesController.dispose();
    _manualRateController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSetExchangeRate(
      {Currency? currency, bool calledFromManualCancel = false}) async {
    final targetCurrency = currency ?? _selectedGoalCurrency;
    final DateTime rateDateForGoal = DateTime.now();
    if (targetCurrency == null || targetCurrency.code == _baseCurrencyCode) {
      if (mounted) {
        setState(() {
          _currentRateInfo = ConversionRateInfo(
              rate: 1.0, effectiveRateDate: rateDateForGoal, isRateStale: false);
          _rateFetchingError = null;
          _isFetchingRate = false;
          if (!calledFromManualCancel) {
            _isManuallyEnteringRate = false;
            _manualRateSetByButton = false;
          }
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isFetchingRate = true;
      _rateFetchingError = null;
      _currentRateInfo = null;
      if (!calledFromManualCancel) {
        _isManuallyEnteringRate = false;
        _manualRateSetByButton = false;
      }
    });

    try {
      final ConversionRateInfo rateInfo =
          await _exchangeRateService.getConversionRate(
        targetCurrency.code,
        _baseCurrencyCode,
        date: rateDateForGoal,
      );
      if (mounted) {
        setState(() {
          _currentRateInfo = rateInfo;
          _manualRateSetByButton = false;
          _manualRateController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rateFetchingError = "Курс для ${targetCurrency.code}: помилка.";
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
    final double? manualRate =
        double.tryParse(_manualRateController.text.replaceAll(',', '.'));
    if (manualRate != null && manualRate > 0) {
      if (mounted) {
        setState(() {
          _currentRateInfo = ConversionRateInfo(
              rate: manualRate,
              effectiveRateDate: DateTime.now(),
              isRateStale: true);
          _manualRateSetByButton = true;
          _isManuallyEnteringRate = false;
          _rateFetchingError = null;
        });
      }
    }
  }

  Future<void> _pickTargetDate() async {
    DateTime initialDatePickerDate =
        _targetDate ?? DateTime.now().add(const Duration(days: 30));
    if (initialDatePickerDate.isBefore(DateTime.now()) && _targetDate == null) {
      initialDatePickerDate = DateTime.now().add(const Duration(days: 30));
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDatePickerDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка: неможливо визначити активний гаманець.')));
      return;
    }

    final name = _nameController.text.trim();
    final originalTargetAmount =
        double.tryParse(_targetAmountController.text.replaceAll(',', '.')) ?? 0.0;
    final originalCurrentAmount =
        double.tryParse(_currentAmountController.text.replaceAll(',', '.')) ?? 0.0;
    final notes = _notesController.text.trim();
    if (_selectedGoalCurrency == null ||
        originalTargetAmount <= 0 ||
        originalCurrentAmount < 0) return;

    double? finalExchangeRate;
    if (_selectedGoalCurrency!.code == _baseCurrencyCode) {
      finalExchangeRate = 1.0;
    } else if (_manualRateSetByButton && _currentRateInfo != null) {
      finalExchangeRate = _currentRateInfo!.rate;
    } else if (_currentRateInfo != null &&
        !_currentRateInfo!.isRateStale &&
        _rateFetchingError == null) {
      finalExchangeRate = _currentRateInfo!.rate;
    }

    if (finalExchangeRate == null || finalExchangeRate <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Не вдалося визначити курс для ${_selectedGoalCurrency!.code}.')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    double targetAmountInBase = originalTargetAmount * finalExchangeRate;
    double currentAmountInBase = originalCurrentAmount * finalExchangeRate;
    bool calculatedIsAchieved = originalCurrentAmount >= originalTargetAmount;

    FinancialGoal goalToSave = FinancialGoal(
      id: widget.goalToEdit?.id,
      name: name,
      originalTargetAmount: originalTargetAmount,
      originalCurrentAmount: originalCurrentAmount,
      currencyCode: _selectedGoalCurrency!.code,
      exchangeRateUsed: finalExchangeRate,
      targetAmountInBaseCurrency: targetAmountInBase,
      currentAmountInBaseCurrency: currentAmountInBase,
      targetDate: _targetDate,
      creationDate: _creationDate,
      notes: notes.isNotEmpty ? notes : null,
      isAchieved: calculatedIsAchieved,
    );
    int savedGoalId;
    try {
      if (_isEditing) {
        await _goalRepository.updateFinancialGoal(goalToSave);
        savedGoalId = goalToSave.id!;
      } else {
        savedGoalId =
            await _goalRepository.createFinancialGoal(goalToSave, walletId);
      }

      final int targetDateReminderId = savedGoalId * 10000 + 1;
      if (_isEditing && widget.goalToEdit?.id != null) {
        await _notificationService
            .cancelNotification(widget.goalToEdit!.id! * 10000 + 1);
      }

      if (goalToSave.targetDate != null && !goalToSave.isAchieved) {
        String reminderTitle = "Нагадування: Ціль \"${goalToSave.name}\"";
        String reminderBody =
            "Наближається цільова дата (${DateFormat('dd.MM.yyyy').format(goalToSave.targetDate!)}) для вашої фінансової цілі.";

        await _notificationService.scheduleNotificationForDueDate(
          id: targetDateReminderId,
          title: reminderTitle,
          body: reminderBody,
          dueDateTime: goalToSave.targetDate!,
          payload: 'goal/$savedGoalId',
          channelId: NotificationService.goalNotificationChannelId,
        );
      } else {
        await _notificationService.cancelNotification(targetDateReminderId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Ціль оновлено!' : 'Ціль створено!')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Помилка збереження цілі: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentCurrencySymbol = _selectedGoalCurrency?.symbol ??
        (_availableCurrencies.firstWhere((c) => c.code == _baseCurrencyCode))
            .symbol;

    bool canSave = !_isSaving &&
        (_selectedGoalCurrency?.code == _baseCurrencyCode ||
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
        title: Text(_isEditing ? 'Редагувати ціль' : 'Нова фінансова ціль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Зберегти ціль',
            onPressed: canSave ? _saveGoal : null,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Назва цілі',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Будь ласка, введіть назву цілі';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Currency>(
              value: _selectedGoalCurrency,
              decoration: const InputDecoration(
                  labelText: 'Валюта цілі',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_exchange_outlined)),
              items: _availableCurrencies.map((Currency currency) {
                return DropdownMenuItem<Currency>(
                  value: currency,
                  child: Text('${currency.name} (${currency.code})'),
                );
              }).toList(),
              onChanged: (Currency? newValue) {
                if (mounted && newValue != null) {
                  setState(() {
                    _selectedGoalCurrency = newValue;
                    _isManuallyEnteringRate = false;
                    _manualRateSetByButton = false;
                    _manualRateController.clear();
                  });
                  _fetchAndSetExchangeRate(currency: newValue);
                }
              },
              validator: (value) => value == null ? 'Оберіть валюту' : null,
            ),
            const SizedBox(height: 8),
            if (_isFetchingRate)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))),
            if (!_isFetchingRate &&
                _rateFetchingError != null &&
                !_isManuallyEnteringRate &&
                _selectedGoalCurrency?.code != _baseCurrencyCode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  children: [
                    Text(_rateFetchingError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12),
                        textAlign: TextAlign.center),
                    TextButton(
                        child: const Text('Ввести курс вручну?'),
                        onPressed: () {
                          if (mounted)
                            setState(() {
                              _isManuallyEnteringRate = true;
                              _rateFetchingError = null;
                            });
                        })
                  ],
                ),
              ),
            if (_isManuallyEnteringRate &&
                _selectedGoalCurrency?.code != _baseCurrencyCode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                      controller: _manualRateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: '1 ${_selectedGoalCurrency?.code} = X UAH',
                          hintText: 'Введіть курс',
                          border: const OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Вкажіть курс';
                        final val = double.tryParse(value.replaceAll(',', '.'));
                        if (val == null || val <= 0) return 'Невірне значення';
                        return null;
                      },
                    )),
                    IconButton(
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        tooltip: 'Застосувати курс',
                        onPressed: _applyManualRate),
                    IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        tooltip: 'Скасувати ручне введення',
                        onPressed: () {
                          if (mounted)
                            setState(() {
                              _isManuallyEnteringRate = false;
                              _manualRateSetByButton = false;
                              _manualRateController.clear();
                            });
                          _fetchAndSetExchangeRate(calledFromManualCancel: true);
                        })
                  ],
                ),
              ),
            if (!_isFetchingRate &&
                _rateFetchingError == null &&
                _currentRateInfo != null &&
                _selectedGoalCurrency?.code != _baseCurrencyCode)
              Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: Text(
                      _manualRateSetByButton
                          ? "Встановлено вручну: 1 ${_selectedGoalCurrency!.code} = ${(_currentRateInfo!.rate).toStringAsFixed(4)} $_baseCurrencyCode"
                          : "1 ${_selectedGoalCurrency!.code} ≈ ${(_currentRateInfo!.rate).toStringAsFixed(4)} $_baseCurrencyCode на ${DateFormat('dd.MM.yy').format(_currentRateInfo!.effectiveRateDate)}${_currentRateInfo!.isRateStale ? ' (застарілий)' : ''}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _manualRateSetByButton
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetAmountController,
              decoration: InputDecoration(
                labelText: 'Цільова сума',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.monetization_on_outlined),
                suffixText: currentCurrencySymbol,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Будь ласка, введіть цільову суму';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Сума має бути більшою за нуль';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentAmountController,
              decoration: InputDecoration(
                labelText: 'Вже накопичено',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                suffixText: currentCurrencySymbol,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Будь ласка, введіть поточну суму (може бути 0)';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount < 0) {
                  return 'Сума не може бути від\'ємною';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_targetDate == null
                  ? 'Бажана дата досягнення (необов\'язково)'
                  : 'Ціль до: ${DateFormat('dd.MM.yyyy').format(_targetDate!)}'),
              trailing: Icon(Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary),
              onTap: _pickTargetDate,
            ),
            if (_targetDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: const Text('Очистити дату'),
                  onPressed: () {
                    if (mounted) setState(() => _targetDate = null);
                  },
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Нотатки (необов\'язково)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isEditing ? 'Зберегти зміни' : 'Створити ціль'),
                    onPressed: canSave ? _saveGoal : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}