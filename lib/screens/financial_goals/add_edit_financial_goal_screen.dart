import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/goal_repository.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/financial_goal.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/services/exchange_rate_service.dart';
import 'package:wislet/services/notification_service.dart';
import 'package:wislet/utils/app_palette.dart';

class AddEditFinancialGoalScreen extends StatefulWidget {
  const AddEditFinancialGoalScreen({this.goalToEdit, super.key});
  final FinancialGoal? goalToEdit;

  @override
  State<AddEditFinancialGoalScreen> createState() => _AddEditFinancialGoalScreenState();
}

class _AddEditFinancialGoalScreenState extends State<AddEditFinancialGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final GoalRepository _goalRepository = getIt<GoalRepository>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();
  final NotificationService _notificationService = getIt<NotificationService>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentAmountController;
  late TextEditingController _notesController;

  DateTime? _targetDate;
  late DateTime _creationDate;
  Currency? _selectedGoalCurrency;
  final List<Currency> _availableCurrencies = appCurrencies;
  final String _baseCurrencyCode = 'UAH';

  bool _isSaving = false;
  bool _isFetchingRate = false;
  ConversionRateInfo? _currentRateInfo;

  bool get _isEditing => widget.goalToEdit != null;

  @override
  void initState() {
    super.initState();
    _creationDate = widget.goalToEdit?.creationDate ?? DateTime.now();
    _nameController = TextEditingController(text: widget.goalToEdit?.name);
    _notesController = TextEditingController(text: widget.goalToEdit?.notes);
    _targetDate = widget.goalToEdit?.targetDate;

    if (_isEditing) {
      final goal = widget.goalToEdit!;
      _targetAmountController = TextEditingController(
        text: goal.originalTargetAmount.toStringAsFixed(2).replaceAll('.', ','),
      );
      _currentAmountController = TextEditingController(
        text: goal.originalCurrentAmount.toStringAsFixed(2).replaceAll('.', ','),
      );
      _selectedGoalCurrency = _availableCurrencies.firstWhere(
        (c) => c.code == goal.currencyCode,
        orElse: () => _availableCurrencies.firstWhere((curr) => curr.code == _baseCurrencyCode),
      );

      if (goal.exchangeRateUsed != null && goal.currencyCode != _baseCurrencyCode) {
        _currentRateInfo = ConversionRateInfo(
          rate: goal.exchangeRateUsed!,
          effectiveRateDate: goal.creationDate,
          isRateStale: true,
        );
      } else {
        _fetchAndSetExchangeRate(currency: _selectedGoalCurrency);
      }
    } else {
      _targetAmountController = TextEditingController();
      _currentAmountController = TextEditingController(text: '0');
      final globalDisplayCurrency = context.read<CurrencyProvider>().selectedCurrency;
      _selectedGoalCurrency = _availableCurrencies.firstWhere(
        (c) => c.code == globalDisplayCurrency.code,
        orElse: () => _availableCurrencies.firstWhere((curr) => curr.code == _baseCurrencyCode),
      );
      _fetchAndSetExchangeRate(currency: _selectedGoalCurrency);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSetExchangeRate({Currency? currency}) async {
    final targetCurrency = currency ?? _selectedGoalCurrency;
    final rateDateForGoal = DateTime.now();

    if (targetCurrency == null || targetCurrency.code == _baseCurrencyCode) {
      if (mounted) {
        setState(
          () => _currentRateInfo = ConversionRateInfo(
            rate: 1,
            effectiveRateDate: rateDateForGoal,
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isFetchingRate = true);

    try {
      final rateInfo = await _exchangeRateService.getConversionRate(
        targetCurrency.code,
        _baseCurrencyCode,
        date: rateDateForGoal,
      );
      if (mounted) setState(() => _currentRateInfo = rateInfo);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка отримання курсу для ${targetCurrency.code}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingRate = false);
    }
  }

  Future<void> _pickTargetDate() async {
    var initialDatePickerDate = _targetDate ?? DateTime.now().add(const Duration(days: 30));
    if (_targetDate == null && initialDatePickerDate.isBefore(DateTime.now())) {
      initialDatePickerDate = DateTime.now().add(const Duration(days: 30));
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDatePickerDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Помилка: неможливо визначити активний гаманець.'),
        ),
      );
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
        originalCurrentAmount < 0 ||
        _currentRateInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не вдалося визначити курс валют. Спробуйте ще раз.'),
        ),
      );
      return;
    }

    if (mounted) setState(() => _isSaving = true);

    final finalExchangeRate = _currentRateInfo!.rate;
    final targetAmountInBase = originalTargetAmount * finalExchangeRate;
    final currentAmountInBase = originalCurrentAmount * finalExchangeRate;
    final calculatedIsAchieved = originalCurrentAmount >= originalTargetAmount;

    final goalToSave = FinancialGoal(
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

    final result = _isEditing
        ? await _goalRepository.updateFinancialGoal(goalToSave)
        : await _goalRepository.createFinancialGoal(goalToSave, walletId);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Помилка збереження цілі: ${failure.userMessage}'),
            ),
          );
        }
      },
      (savedGoalId) async {
        final targetDateReminderId = savedGoalId * 10000 + 1;
        if (_isEditing && widget.goalToEdit?.id != null) {
          await _notificationService.cancelNotification(widget.goalToEdit!.id! * 10000 + 1);
        }

        if (goalToSave.targetDate != null && !goalToSave.isAchieved) {
          await _notificationService.scheduleNotificationForDueDate(
            id: targetDateReminderId,
            title: 'Нагадування: Ціль "${goalToSave.name}"',
            body:
                'Наближається цільова дата (${DateFormat('dd.MM.yyyy').format(goalToSave.targetDate!)}) для вашої фінансової цілі.',
            dueDate: goalToSave.targetDate!,
            payload: 'goal/$savedGoalId',
            channelId: NotificationService.goalNotificationChannelId,
          );
        } else {
          await _notificationService.cancelNotification(targetDateReminderId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Ціль оновлено!' : 'Ціль створено!'),
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
    );

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_isSaving && !_isFetchingRate && _currentRateInfo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати ціль' : 'Нова фінансова ціль'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Назва цілі',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Будь ласка, введіть назву цілі' : null,
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetAmountController,
                    decoration: InputDecoration(
                      labelText: 'Цільова сума',
                      prefixIcon: Icon(
                        Icons.monetization_on_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введіть суму';
                      }
                      final amount = double.tryParse(value.replaceAll(',', '.'));
                      if (amount == null || amount <= 0) {
                        return 'Сума має бути більшою за нуль';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<Currency>(
                    value: _selectedGoalCurrency,
                    decoration: const InputDecoration(labelText: 'Валюта'),
                    items: _availableCurrencies.map((currency) {
                      return DropdownMenuItem<Currency>(
                        value: currency,
                        child: Text(currency.code),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (mounted && newValue != null) {
                        setState(() => _selectedGoalCurrency = newValue);
                        _fetchAndSetExchangeRate(currency: newValue);
                      }
                    },
                    validator: (value) => value == null ? 'Оберіть' : null,
                  ),
                ),
              ],
            ),
            if (_isFetchingRate)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if (!_isFetchingRate && _currentRateInfo != null && _selectedGoalCurrency?.code != _baseCurrencyCode)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Text(
                  '1 ${_selectedGoalCurrency!.code} ≈ ${_currentRateInfo!.rate.toStringAsFixed(4)} $_baseCurrencyCode',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppPalette.darkSecondaryText),
                ),
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _currentAmountController,
              decoration: const InputDecoration(
                labelText: 'Вже накопичено',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введіть поточну суму (може бути 0)';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount < 0) {
                  return 'Сума не може бути відʼємною';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              leading: const Icon(
                Icons.calendar_today_outlined,
                color: AppPalette.darkSecondaryText,
              ),
              title: Text(
                _targetDate == null
                    ? 'Бажана дата досягнення (необовʼязково)'
                    : 'Ціль до: ${DateFormat('dd.MM.yyyy').format(_targetDate!)}',
              ),
              trailing: const Icon(
                Icons.edit_outlined,
                color: AppPalette.darkSecondaryText,
                size: 20,
              ),
              onTap: _pickTargetDate,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: canSave ? _saveGoal : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Зберегти зміни' : 'Створити ціль'),
            ),
          ],
        ),
      ),
    );
  }
}
