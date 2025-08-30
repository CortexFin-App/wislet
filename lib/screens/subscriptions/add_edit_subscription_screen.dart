import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/subscription_repository.dart';
import 'package:sage_wallet_reborn/models/category.dart' as fin_category;
import 'package:sage_wallet_reborn/models/currency_model.dart';
import 'package:sage_wallet_reborn/models/subscription_model.dart';
import 'package:sage_wallet_reborn/providers/currency_provider.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/services/notification_service.dart';
import 'package:sage_wallet_reborn/utils/l10n_helpers.dart';

class AddEditSubscriptionScreen extends StatefulWidget {
  const AddEditSubscriptionScreen({super.key, this.subscriptionToEdit});
  final Subscription? subscriptionToEdit;

  @override
  State<AddEditSubscriptionScreen> createState() => _AddEditSubscriptionScreenState();
}

class _AddEditSubscriptionScreenState extends State<AddEditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubscriptionRepository _subscriptionRepository = getIt<SubscriptionRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  final NotificationService _notificationService = getIt<NotificationService>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _notesController;
  late TextEditingController _websiteController;

  Currency? _selectedCurrency;
  BillingCycle _selectedBillingCycle = BillingCycle.monthly;
  late DateTime _nextPaymentDate;
  late DateTime _startDate;
  fin_category.Category? _selectedCategory;
  bool _isActive = true;
  int _selectedReminderDays = 1;
  List<fin_category.Category> _availableCategories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  bool get _isEditing => widget.subscriptionToEdit != null;

  final Map<int, String> _reminderOptions = {
    0: 'В день оплати',
    1: 'За 1 день',
    2: 'За 2 дні',
    3: 'За 3 дні',
    7: 'За тиждень',
  };

  @override
  void initState() {
    super.initState();
    _loadExpenseCategories();

    if (_isEditing) {
      final sub = widget.subscriptionToEdit!;
      _nameController = TextEditingController(text: sub.name);
      _amountController = TextEditingController(
        text: sub.amount.toStringAsFixed(2).replaceAll('.', ','),
      );
      _paymentMethodController = TextEditingController(text: sub.paymentMethod);
      _notesController = TextEditingController(text: sub.notes);
      _websiteController = TextEditingController(text: sub.website);
      _selectedCurrency = appCurrencies.firstWhereOrNull((c) => c.code == sub.currencyCode);
      _selectedBillingCycle = sub.billingCycle;
      _nextPaymentDate = sub.nextPaymentDate;
      _startDate = sub.startDate;
      _isActive = sub.isActive;
      _selectedReminderDays = sub.reminderDaysBefore ?? 1;
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _paymentMethodController = TextEditingController();
      _notesController = TextEditingController();
      _websiteController = TextEditingController();
      _selectedCurrency = context.read<CurrencyProvider>().selectedCurrency;
      _startDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      _nextPaymentDate = _calculateNextPaymentDate(_startDate, _selectedBillingCycle);
    }
  }

  Future<void> _loadExpenseCategories() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
      return;
    }
    final categoriesEither = await _categoryRepository.getCategoriesByType(
      currentWalletId,
      fin_category.CategoryType.expense,
    );
    if (!mounted) return;

    categoriesEither.fold((failure) => setState(() => _isLoadingCategories = false), (categories) {
      if (mounted) {
        setState(() {
          _availableCategories = categories;
          if (_isEditing && widget.subscriptionToEdit?.categoryId != null) {
            _selectedCategory = _availableCategories.firstWhereOrNull(
              (cat) => cat.id == widget.subscriptionToEdit!.categoryId,
            );
          }
          _isLoadingCategories = false;
        });
      }
    });
  }

  DateTime _calculateNextPaymentDate(DateTime fromDate, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.daily:
        return fromDate.add(const Duration(days: 1));
      case BillingCycle.weekly:
        return fromDate.add(const Duration(days: 7));
      case BillingCycle.monthly:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      case BillingCycle.quarterly:
        return DateTime(fromDate.year, fromDate.month + 3, fromDate.day);
      case BillingCycle.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
      case BillingCycle.custom:
        return fromDate.add(const Duration(days: 30));
    }
  }

  Future<void> _pickDate(bool isNextPayment) async {
    final initial = isNextPayment ? _nextPaymentDate : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isNextPayment) {
          _nextPaymentDate = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId == null) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || _selectedCurrency == null) return;

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final subToSave = Subscription(
      id: widget.subscriptionToEdit?.id,
      name: _nameController.text.trim(),
      amount: amount,
      currencyCode: _selectedCurrency!.code,
      billingCycle: _selectedBillingCycle,
      nextPaymentDate: _nextPaymentDate,
      startDate: _startDate,
      categoryId: _selectedCategory?.id,
      paymentMethod: _paymentMethodController.text.trim(),
      notes: _notesController.text.trim(),
      isActive: _isActive,
      website: _websiteController.text.trim(),
      reminderDaysBefore: _selectedReminderDays,
    );

    final result = _isEditing
        ? await _subscriptionRepository.updateSubscription(subToSave, walletId)
        : await _subscriptionRepository.createSubscription(subToSave, walletId);

    result.fold((failure) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Помилка збереження підписки: ${failure.userMessage}',
            ),
          ),
        );
      }
    }, (savedSubscriptionId) async {
      final reminderId = savedSubscriptionId * 20000 + 1;

      if (_isEditing && widget.subscriptionToEdit?.id != null) {
        await _notificationService.cancelNotification(reminderId);
      }

      if (subToSave.isActive && subToSave.nextPaymentDate.isAfter(DateTime.now())) {
        final reminderDateTime = subToSave.nextPaymentDate.subtract(Duration(days: subToSave.reminderDaysBefore!));

        await _notificationService.scheduleNotificationForDueDate(
          id: reminderId,
          title: 'Нагадування про підписку: ${subToSave.name}',
          body: 'Завтра платіж на суму ${subToSave.amount.toStringAsFixed(2)} ${subToSave.currencyCode}',
          dueDate: reminderDateTime,
          payload: 'subscription/$savedSubscriptionId',
          channelId: NotificationService.goalNotificationChannelId,
        );
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Підписку оновлено!' : 'Підписку створено!',
            ),
          ),
        );
        navigator.pop(true);
      }
    });

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _paymentMethodController.dispose();
    _notesController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редагувати Підписку' : 'Нова Підписка',
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Назва підписки',
                      prefixIcon: Icon(Icons.star_border_purple500_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Назва не може бути порожньою' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Сума',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              child: Text(
                                _selectedCurrency?.symbol ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Введіть суму';
                            }
                            if (double.tryParse(v.replaceAll(',', '.')) == null) {
                              return 'Невірне число';
                            }
                            if (double.parse(v.replaceAll(',', '.')) <= 0) {
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
                          value: _selectedCurrency,
                          decoration: const InputDecoration(labelText: 'Валюта'),
                          items: appCurrencies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.code),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCurrency = val),
                          validator: (v) => v == null ? 'Оберіть' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<BillingCycle>(
                    value: _selectedBillingCycle,
                    decoration: const InputDecoration(
                      labelText: 'Цикл оплати',
                      prefixIcon: Icon(Icons.repeat_outlined),
                    ),
                    items: BillingCycle.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(billingCycleToString(c, context)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedBillingCycle = val;
                          if (!_isEditing) {
                            _nextPaymentDate = _calculateNextPaymentDate(_startDate, val);
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Дата першого платежу'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                    onTap: () => _pickDate(false),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_repeat_outlined),
                    title: const Text(
                      'Дата наступного платежу',
                    ),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_nextPaymentDate)),
                    onTap: () => _pickDate(true),
                  ),
                  const SizedBox(height: 16),
                  if (_availableCategories.isNotEmpty)
                    DropdownButtonFormField<fin_category.Category?>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Категорія витрат (опціонально)',
                        prefixIcon: const Icon(Icons.category_outlined),
                        suffixIcon: _selectedCategory != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => setState(() => _selectedCategory = null),
                              )
                            : null,
                      ),
                      items: [
                        const DropdownMenuItem<fin_category.Category?>(
                          child: Text('Без категорії'),
                        ),
                        ..._availableCategories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedReminderDays,
                    decoration: const InputDecoration(
                      labelText: 'Нагадувати',
                      prefixIcon: Icon(Icons.notifications_active_outlined),
                    ),
                    items: _reminderOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedReminderDays = val ?? 1),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _paymentMethodController,
                    decoration: const InputDecoration(
                      labelText: 'Метод оплати (опціонально)',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Веб-сайт (опціонально)',
                      prefixIcon: Icon(Icons.public_outlined),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Нотатки (опціонально)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Підписка активна'),
                    subtitle: const Text(
                      'Для тимчасового відключення сповіщень та обліку',
                    ),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSubscription,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Зберегти Зміни' : 'Створити Підписку',
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
