import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/repeating_transaction_repository.dart';
import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/models/currency_model.dart';
import 'package:sage_wallet_reborn/models/repeating_transaction_model.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as fin_transaction;
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';

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
    'РџРЅ',
    'Р’С‚',
    'РЎСЂ',
    'Р§С‚',
    'РџС‚',
    'РЎР±',
    'РќРґ',
  ];

  MonthlyRepeatType _monthlyType = MonthlyRepeatType.specificDay;
  int _selectedMonthNumericDay = 1;
  int? _selectedYearMonth;
  int? _selectedYearNumericDay;

  final List<String> _monthLabels = [
    'РЎС–С‡РµРЅСЊ',
    'Р›СЋС‚РёР№',
    'Р‘РµСЂРµР·РµРЅСЊ',
    'РљРІС–С‚РµРЅСЊ',
    'РўСЂР°РІРµРЅСЊ',
    'Р§РµСЂРІРµРЅСЊ',
    'Р›РёРїРµРЅСЊ',
    'РЎРµСЂРїРµРЅСЊ',
    'Р’РµСЂРµСЃРµРЅСЊ',
    'Р–РѕРІС‚РµРЅСЊ',
    'Р›РёСЃС‚РѕРїР°Рґ',
    'Р“СЂСѓРґРµРЅСЊ',
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
            'Р”Р»СЏ С‰РѕС‚РёР¶РЅРµРІРѕРіРѕ РїРѕРІС‚РѕСЂРµРЅРЅСЏ РїРѕС‚СЂС–Р±РЅРѕ РѕР±СЂР°С‚Рё С…РѕС‡Р° Р± РѕРґРёРЅ РґРµРЅСЊ.',
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
              ? 'Р РµРґР°РіСѓРІР°С‚Рё С€Р°Р±Р»РѕРЅ'
              : 'РќРѕРІРёР№ С€Р°Р±Р»РѕРЅ',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveTemplate,
            tooltip: 'Р—Р±РµСЂРµРіС‚Рё С€Р°Р±Р»РѕРЅ',
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
                              ? 'Р—Р±РµСЂРµРіС‚Рё Р·РјС–РЅРё'
                              : 'РЎС‚РІРѕСЂРёС‚Рё С€Р°Р±Р»РѕРЅ',
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
          decoration: const InputDecoration(labelText: 'РћРїРёСЃ'),
          validator: (value) =>
              value == null || value.isEmpty ? 'Р’РІРµРґС–С‚СЊ РѕРїРёСЃ' : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'РЎСѓРјР°'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Р’РІРµРґС–С‚СЊ СЃСѓРјСѓ';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'РќРµРІС–СЂРЅРµ С‡РёСЃР»Рѕ';
                  }
                  if (double.parse(value.replaceAll(',', '.')) <= 0) {
                    return 'РЎСѓРјР° > 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<Currency>(
                value: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'Р’Р°Р»СЋС‚Р°'),
                items: appCurrencies
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.code)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCurrency = val),
                validator: (val) => val == null ? 'РћР±РµСЂС–С‚СЊ' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<fin_transaction.TransactionType>(
          value: _selectedType,
          decoration:
              const InputDecoration(labelText: 'РўРёРї С‚СЂР°РЅР·Р°РєС†С–С—'),
          items: fin_transaction.TransactionType.values
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t == fin_transaction.TransactionType.income
                        ? 'Р”РѕС…С–Рґ'
                        : 'Р’РёС‚СЂР°С‚Р°',
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
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'РљР°С‚РµРіРѕСЂС–СЏ'),
            items: _availableCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
            validator: (val) => val == null ? 'РћР±РµСЂС–С‚СЊ' : null,
          )
        else
          Text(
            _isLoadingCategories
                ? 'Р—Р°РІР°РЅС‚Р°Р¶РµРЅРЅСЏ РєР°С‚РµРіРѕСЂС–Р№...'
                : 'РќРµРјР°С” РґРѕСЃС‚СѓРїРЅРёС… РєР°С‚РµРіРѕСЂС–Р№ РґР»СЏ РѕР±СЂР°РЅРѕРіРѕ С‚РёРїСѓ. РЎРїРѕС‡Р°С‚РєСѓ СЃС‚РІРѕСЂС–С‚СЊ С—С….',
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
          'РќР°Р»Р°С€С‚СѓРІР°РЅРЅСЏ РїРѕРІС‚РѕСЂРµРЅРЅСЏ:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Frequency>(
          value: _selectedFrequency,
          decoration: const InputDecoration(labelText: 'Р§Р°СЃС‚РѕС‚Р°'),
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
                'Р†РЅС‚РµСЂРІР°Р» (РЅР°РїСЂ., РєРѕР¶РЅС– X РґРЅС–РІ/С‚РёР¶РЅС–РІ/РјС–СЃСЏС†С–РІ)',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Р’РєР°Р¶С–С‚СЊ С–РЅС‚РµСЂРІР°Р»';
            }
            if (int.tryParse(value) == null || int.parse(value) < 1) {
              return 'РњС–РЅ. 1';
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
            'РћР±РµСЂС–С‚СЊ РґРЅС– С‚РёР¶РЅСЏ:',
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
            'Р”РµРЅСЊ РјС–СЃСЏС†СЏ РґР»СЏ РїРѕРІС‚РѕСЂРµРЅРЅСЏ:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          RadioListTile<MonthlyRepeatType>(
            title: const Text('РљРѕРЅРєСЂРµС‚РЅРёР№ РґРµРЅСЊ'),
            value: MonthlyRepeatType.specificDay,
            groupValue: _monthlyType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _monthlyType = value;
                });
              }
            },
          ),
          if (_monthlyType == MonthlyRepeatType.specificDay)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<int>(
                value: _selectedMonthNumericDay.clamp(
                  1,
                  _getDaysInMonth(_startDate.year, _startDate.month),
                ),
                decoration: const InputDecoration(
                  labelText: 'РћР±РµСЂС–С‚СЊ С‡РёСЃР»Рѕ',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: List.generate(31, (i) => i + 1)
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
                      _selectedMonthNumericDay = val;
                    });
                  }
                },
              ),
            ),
          RadioListTile<MonthlyRepeatType>(
            title: const Text('РћСЃС‚Р°РЅРЅС–Р№ РґРµРЅСЊ РјС–СЃСЏС†СЏ'),
            value: MonthlyRepeatType.lastDay,
            groupValue: _monthlyType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _monthlyType = value;
                });
              }
            },
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
            'Р”Р°С‚Р° РґР»СЏ С‰РѕСЂС–С‡РЅРѕРіРѕ РїРѕРІС‚РѕСЂРµРЅРЅСЏ:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedYearMonth,
            decoration: const InputDecoration(labelText: 'РњС–СЃСЏС†СЊ'),
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
            validator: (val) =>
                val == null ? 'РћР±РµСЂС–С‚СЊ РјС–СЃСЏС†СЊ' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value:
                (_selectedYearNumericDay != null && _selectedYearMonth != null)
                    ? _selectedYearNumericDay!.clamp(
                        1,
                        _getDaysInMonth(_startDate.year, _selectedYearMonth!),
                      )
                    : null,
            decoration: const InputDecoration(labelText: 'Р”РµРЅСЊ'),
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
            validator: (val) => val == null ? 'РћР±РµСЂС–С‚СЊ РґРµРЅСЊ' : null,
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
            'РџРѕС‡Р°С‚РѕРє: ${DateFormat('dd.MM.yyyy HH:mm').format(_startDate)}',
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
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startDate),
              );
              if (mounted) {
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
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _endDate == null
                ? 'Р‘РµР· РґР°С‚Рё Р·Р°РєС–РЅС‡РµРЅРЅСЏ'
                : 'РљС–РЅРµС†СЊ: ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
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
          title: const Text('РЁР°Р±Р»РѕРЅ Р°РєС‚РёРІРЅРёР№'),
          value: _isActive,
          onChanged: (val) => setState(() => _isActive = val),
        ),
      ],
    );
  }
}
