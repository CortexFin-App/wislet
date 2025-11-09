import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/data/repositories/repeating_transaction_repository.dart';
import 'package:wislet/models/category.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/repeating_transaction_model.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/providers/wallet_provider.dart';

class AddEditRepeatingTransactionScreen extends StatefulWidget {
  const AddEditRepeatingTransactionScreen({this.template, super.key});
  final RepeatingTransaction? template;
  @override
  State<AddEditRepeatingTransactionScreen> createState() =>
      _AddEditRepeatingTransactionScreenState();
}

enum MonthlyRepeatType { specificDay, lastDay }

class _AddEditRepeatingTransactionScreenState
    extends State<AddEditRepeatingTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final RepeatingTransactionRepository _repeatingTransactionRepository =
      getIt<RepeatingTransactionRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _intervalController;
  late TextEditingController _occurrencesController;
  fin_transaction.TransactionType _selectedType =
      fin_transaction.TransactionType.expense;
  Currency? _selectedCurrency;
  Category? _selectedCategory;
  Frequency _selectedFrequency = Frequency.monthly;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  List<Category> _availableCategories = [];
  bool _isLoadingCategories = false;
  List<int> _selectedWeekDays = [];
  List<bool> _selectedToggleButtons = List<bool>.filled(7, false);
  final List<String> _weekDayLabels = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Нд',
  ];

  MonthlyRepeatType _monthlyType = MonthlyRepeatType.specificDay;
  int _selectedMonthNumericDay = 1;
  int? _selectedYearMonth;
  int? _selectedYearNumericDay;

  final List<String> _monthLabels = [
    'Січень',
    'Лютий',
    'Березень',
    'Квітень',
    'Травень',
    'Червень',
    'Липень',
    'Серпень',
    'Вересень',
    'Жовтень',
    'Листопад',
    'Грудень',
  ];

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.template?.description);
    _amountController = TextEditingController(
      text: widget.template?.originalAmount
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );
    _intervalController = TextEditingController(
      text: widget.template?.interval.toString() ?? '1',
    );
    _occurrencesController =
        TextEditingController(text: widget.template?.occurrences?.toString());
    _startDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      9,
    );

    if (_isEditing) {
      final t = widget.template!;
      _selectedType = t.type;
      _selectedCurrency = appCurrencies
          .firstWhereOrNull((c) => c.code == t.originalCurrencyCode);
      _selectedFrequency = t.frequency;
      _startDate = t.startDate;
      _endDate = t.endDate;
      _isActive = t.isActive;
      if (t.frequency == Frequency.weekly && t.weekDays != null) {
        _selectedWeekDays = t.weekDays!;
        for (var i = 0; i < _selectedToggleButtons.length; i++) {
          _selectedToggleButtons[i] = _selectedWeekDays.contains(i + 1);
        }
      }

      if (t.frequency == Frequency.monthly && t.monthDay != null) {
        if (t.monthDay == 'last') {
          _monthlyType = MonthlyRepeatType.lastDay;
        } else {
          _monthlyType = MonthlyRepeatType.specificDay;
          _selectedMonthNumericDay = int.tryParse(t.monthDay!) ?? 1;
        }
      } else {
        _selectedMonthNumericDay = _startDate.day;
      }

      if (t.frequency == Frequency.yearly) {
        _selectedYearMonth = t.yearMonth ?? _startDate.month;
        _selectedYearNumericDay = t.yearDay ?? _startDate.day;
      } else {
        _selectedYearMonth = _startDate.month;
        _selectedYearNumericDay = _startDate.day;
      }
    } else {
      _selectedCurrency = appCurrencies.firstWhere(
        (c) => c.code == 'UAH',
        orElse: () => appCurrencies.first,
      );
      _selectedMonthNumericDay = _startDate.day;
      _selectedYearMonth = _startDate.month;
      _selectedYearNumericDay = _startDate.day;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _intervalController.dispose();
    _occurrencesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      if (mounted) setState(() => _isLoadingCategories = false);
      return;
    }

    setState(() => _isLoadingCategories = true);
    final categoriesEither = await _categoryRepository.getCategoriesByType(
      currentWalletId,
      _selectedType == fin_transaction.TransactionType.income
          ? CategoryType.income
          : CategoryType.expense,
    );
    if (!mounted) return;

    categoriesEither.fold(
      (failure) => setState(() => _isLoadingCategories = false),
      (categories) {
        if (mounted) {
          setState(() {
            _availableCategories = categories;
            if (_isEditing && widget.template != null) {
              final foundCategory = categories.firstWhereOrNull(
                (cat) => cat.id == widget.template!.categoryId,
              );
              if (foundCategory != null) {
                _selectedCategory = foundCategory;
              }
            }
            _isLoadingCategories = false;
          });
        }
      },
    );
  }

  int _getDaysInMonth(int year, int month) {
    if (month < 1 || month > 12) return 30;
    if (month == DateTime.february) {
      final isLeapYear =
          (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const daysInMonthList = <int>[
      0,
      31,
      28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    return daysInMonthList[month];
  }

  DateTime _calculateInitialNextDueDate(
    DateTime startDate,
    Frequency frequency,
    int interval,
    String? weekDays,
    String? monthDay,
    int? yearMonth,
    int? yearDay,
  ) {
    var nextDate = startDate;
    final startDateAtMidnight =
        DateTime(startDate.year, startDate.month, startDate.day);

    if (frequency == Frequency.daily) {
      nextDate = startDateAtMidnight;
    } else if (frequency == Frequency.weekly &&
        weekDays != null &&
        weekDays.isNotEmpty) {
      final allowedWeekDays =
          weekDays.split(',').map((e) => int.parse(e.trim())).toList()..sort();

      if (allowedWeekDays.isNotEmpty) {
        var searchDate = startDateAtMidnight;
        if (!allowedWeekDays.contains(searchDate.weekday)) {
          var found = false;
          for (var i = 0; i < 7; i++) {
            final potentialNextDay = searchDate.add(Duration(days: i));
            if (allowedWeekDays.contains(potentialNextDay.weekday)) {
              searchDate = potentialNextDay;
              found = true;
              break;
            }
          }
          if (!found) {
            searchDate = searchDate.add(
              Duration(days: 7 - searchDate.weekday + allowedWeekDays.first),
            );
          }
        }
        nextDate = searchDate;
      } else {
        nextDate = startDateAtMidnight;
      }
    } else if (frequency == Frequency.monthly &&
        monthDay != null &&
        monthDay.isNotEmpty) {
      var currentYear = startDate.year;
      var currentMonth = startDate.month;
      int actualTargetDay;
      if (monthDay == 'last') {
        actualTargetDay = _getDaysInMonth(currentYear, currentMonth);
      } else {
        final desiredDay = int.tryParse(monthDay) ?? startDate.day;
        actualTargetDay =
            desiredDay.clamp(1, _getDaysInMonth(currentYear, currentMonth));
      }
      final potentialDateInCurrentMonth =
          DateTime(currentYear, currentMonth, actualTargetDay);
      if (potentialDateInCurrentMonth.isBefore(startDateAtMidnight)) {
        currentMonth += interval;
        while (currentMonth > 12) {
          currentMonth -= 12;
          currentYear++;
        }
        if (monthDay == 'last') {
          actualTargetDay = _getDaysInMonth(currentYear, currentMonth);
        } else {
          final desiredDay = int.tryParse(monthDay) ?? startDate.day;
          actualTargetDay =
              desiredDay.clamp(1, _getDaysInMonth(currentYear, currentMonth));
        }
        nextDate = DateTime(currentYear, currentMonth, actualTargetDay);
      } else {
        nextDate = potentialDateInCurrentMonth;
      }
    } else if (frequency == Frequency.yearly &&
        yearMonth != null &&
        yearDay != null) {
      var currentYear = startDate.year;
      final targetMonth = yearMonth;
      final targetDay = yearDay;
      final potentialDateThisYear = DateTime(
        currentYear,
        targetMonth,
        targetDay.clamp(1, _getDaysInMonth(currentYear, targetMonth)),
      );

      if (potentialDateThisYear.isBefore(startDateAtMidnight)) {
        currentYear += interval;
        nextDate = DateTime(
          currentYear,
          targetMonth,
          targetDay.clamp(1, _getDaysInMonth(currentYear, targetMonth)),
        );
      } else {
        nextDate = potentialDateThisYear;
      }
    }
    return DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      startDate.hour,
      startDate.minute,
      startDate.second,
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null && !_isEditing) return;
    if (_selectedCategory == null || _selectedCurrency == null) return;
    if (_selectedFrequency == Frequency.weekly && _selectedWeekDays.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Для щотижневого повторення потрібно обрати хоча б один день.',
          ),
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final originalAmount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));
    final interval = int.tryParse(_intervalController.text.trim()) ?? 1;
    final occurrences = _occurrencesController.text.trim().isEmpty
        ? null
        : int.tryParse(_occurrencesController.text.trim());

    String? weekDaysString;
    if (_selectedFrequency == Frequency.weekly &&
        _selectedWeekDays.isNotEmpty) {
      _selectedWeekDays.sort();
      weekDaysString = _selectedWeekDays.join(',');
    }

    String? monthDayValue;
    if (_selectedFrequency == Frequency.monthly) {
      monthDayValue = _monthlyType == MonthlyRepeatType.lastDay
          ? 'last'
          : _selectedMonthNumericDay.toString();
    }
    final finalYearMonth =
        _selectedFrequency == Frequency.yearly ? _selectedYearMonth : null;
    final finalYearDay =
        _selectedFrequency == Frequency.yearly ? _selectedYearNumericDay : null;

    if (originalAmount == null || originalAmount <= 0) return;

    final initialNextDueDate = _calculateInitialNextDueDate(
      _startDate,
      _selectedFrequency,
      interval,
      weekDaysString,
      monthDayValue,
      finalYearMonth,
      finalYearDay,
    );

    final templateToSave = RepeatingTransaction(
      id: widget.template?.id,
      description: description,
      originalAmount: originalAmount,
      originalCurrencyCode: _selectedCurrency!.code,
      categoryId: _selectedCategory!.id!,
      type: _selectedType,
      frequency: _selectedFrequency,
      interval: interval > 0 ? interval : 1,
      startDate: _startDate,
      endDate: _endDate,
      occurrences: occurrences,
      generatedOccurrencesCount:
          _isEditing ? widget.template!.generatedOccurrencesCount : 0,
      nextDueDate: _isEditing
          ? (widget.template!.nextDueDate.isBefore(DateTime.now())
              ? initialNextDueDate
              : widget.template!.nextDueDate)
          : initialNextDueDate,
      isActive: _isActive,
      weekDays: _selectedWeekDays.isNotEmpty ? _selectedWeekDays : null,
      monthDay: monthDayValue,
      yearMonth: finalYearMonth,
      yearDay: finalYearDay,
    );

    if (_isEditing) {
      await _repeatingTransactionRepository
          .updateRepeatingTransaction(templateToSave);
    } else {
      await _repeatingTransactionRepository.createRepeatingTransaction(
        templateToSave,
        currentWalletId!,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Редагувати шаблон'
              : 'Новий шаблон',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveTemplate,
            tooltip: 'Зберегти шаблон',
          ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCommonFieldsSection(),
                    const SizedBox(height: 16),
                    _buildFrequencyAndIntervalSection(),
                    const SizedBox(height: 16),
                    if (_selectedFrequency == Frequency.weekly)
                      _buildWeeklyRepeatOptions(),
                    if (_selectedFrequency == Frequency.monthly)
                      _buildMonthlyRepeatOptions(),
                    if (_selectedFrequency == Frequency.yearly)
                      _buildYearlyRepeatOptions(),
                    _buildDateAndStatusSection(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTemplate,
                        child: Text(
                          _isEditing
                              ? 'Зберегти зміни'
                              : 'Створити шаблон',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCommonFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Опис'),
          validator: (value) =>
              value == null || value.isEmpty ? 'Введіть опис' : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Сума'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введіть суму';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Невірне число';
                  }
                  if (double.parse(value.replaceAll(',', '.')) <= 0) {
                    return 'Сума > 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<Currency>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'Валюта'),
                items: appCurrencies
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.code)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCurrency = val),
                validator: (val) => val == null ? 'Оберіть' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<fin_transaction.TransactionType>(
          initialValue: _selectedType,
          decoration:
              const InputDecoration(labelText: 'Тип транзакції'),
          items: fin_transaction.TransactionType.values
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t == fin_transaction.TransactionType.income
                        ? 'Дохід'
                        : 'Витрата',
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedType = val;
                _selectedCategory = null;
              });
              _loadCategories();
            }
          },
        ),
        const SizedBox(height: 16),
        if (_availableCategories.isNotEmpty)
          DropdownButtonFormField<Category>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Категорія'),
            items: _availableCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
            validator: (val) => val == null ? 'Оберіть' : null,
          )
        else
          Text(
            _isLoadingCategories
                ? 'Завантаження категорій...'
                : 'Немає доступних категорій для обраного типу. Спочатку створіть їх.',
            style: TextStyle(color: Colors.orange.shade700),
          ),
      ],
    );
  }

  Widget _buildFrequencyAndIntervalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Налаштування повторення:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Frequency>(
          initialValue: _selectedFrequency,
          decoration: const InputDecoration(labelText: 'Частота'),
          items: Frequency.values
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(frequencyToString(f)),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedFrequency = val;
                if (_selectedFrequency != Frequency.weekly) {
                  _selectedWeekDays.clear();
                  _selectedToggleButtons = List<bool>.filled(7, false);
                }
                if (_selectedFrequency != Frequency.monthly) {
                  _monthlyType = MonthlyRepeatType.specificDay;
                  _selectedMonthNumericDay = _startDate.day;
                }
                if (_selectedFrequency != Frequency.yearly) {
                  _selectedYearMonth = _startDate.month;
                  _selectedYearNumericDay = _startDate.day;
                }
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _intervalController,
          decoration: const InputDecoration(
            labelText:
                'Інтервал (напр., кожні X днів/тижнів/місяців)',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Вкажіть інтервал';
            }
            if (int.tryParse(value) == null || int.parse(value) < 1) {
              return 'Мін. 1';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWeeklyRepeatOptions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Оберіть дні тижня:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Center(
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              constraints: BoxConstraints(
                minWidth:
                    (MediaQuery.of(context).size.width - 32 - 6 * 4) / 7 - 1,
                minHeight: 40,
              ),
              isSelected: _selectedToggleButtons,
              onPressed: (index) {
                setState(() {
                  _selectedToggleButtons[index] =
                      !_selectedToggleButtons[index];
                  _selectedWeekDays.clear();
                  for (var i = 0; i < _selectedToggleButtons.length; i++) {
                    if (_selectedToggleButtons[i]) {
                      _selectedWeekDays.add(i + 1);
                    }
                  }
                });
              },
              children: _weekDayLabels
                  .map(
                    (label) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(label),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRepeatOptions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'День місяця для повторення:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
            RadioGroup<MonthlyRepeatType>(
            groupValue: _monthlyType,
             onChanged: (value) {
             if (value != null) {
               setState(() => _monthlyType = value);
              }
            },
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const RadioListTile<MonthlyRepeatType>(
                    title: Text('Конкретний день'),
                    value: MonthlyRepeatType.specificDay,
                ),
                if (_monthlyType == MonthlyRepeatType.specificDay)
                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: DropdownButtonFormField<int>(
                        items: const [],
                        onChanged: (_) {},
                     ),
                    ),
                const RadioListTile<MonthlyRepeatType>(
                 title: Text('Останній день місяця'),
                    value: MonthlyRepeatType.lastDay,
                ),
                ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyRepeatOptions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дата для щорічного повторення:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _selectedYearMonth,
            decoration: const InputDecoration(labelText: 'Місяць'),
            items: List.generate(12, (i) => i + 1)
                .map(
                  (month) => DropdownMenuItem(
                    value: month,
                    child: Text(_monthLabels[month - 1]),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedYearMonth = val;
                  final daysInNewMonth =
                      _getDaysInMonth(_startDate.year, _selectedYearMonth!);
                  if (_selectedYearNumericDay != null &&
                      _selectedYearNumericDay! > daysInNewMonth) {
                    _selectedYearNumericDay = daysInNewMonth;
                  }
                });
              }
            },
            validator: (val) => val == null ? 'Оберіть місяць' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue:
                (_selectedYearNumericDay != null && _selectedYearMonth != null)
                    ? _selectedYearNumericDay!.clamp(
                        1,
                        _getDaysInMonth(_startDate.year, _selectedYearMonth!),
                      )
                    : null,
            decoration: const InputDecoration(labelText: 'День'),
            items: List.generate(
              _getDaysInMonth(
                _startDate.year,
                _selectedYearMonth ?? _startDate.month,
              ),
              (i) => i + 1,
            )
                .map(
                  (day) => DropdownMenuItem(
                    value: day,
                    child: Text(day.toString()),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedYearNumericDay = val;
                });
              }
            },
            validator: (val) => val == null ? 'Оберіть день' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Початок: ${DateFormat('dd.MM.yyyy HH:mm').format(_startDate)}',
          ),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              if (!mounted) return;
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startDate),
              );
              if (!mounted) return; 
                setState(() {
                  _startDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime?.hour ?? _startDate.hour,
                    pickedTime?.minute ?? _startDate.minute,
                  );
                });
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _endDate == null
                ? 'Без дати закінчення'
                : 'Кінець: ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
              firstDate: _startDate,
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _endDate = picked);
          },
          leading: _endDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _endDate = null),
                )
              : const SizedBox(width: 40),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          title: const Text('Шаблон активний'),
          value: _isActive,
          onChanged: (val) => setState(() => _isActive = val),
        ),
      ],
    );
  }
}
