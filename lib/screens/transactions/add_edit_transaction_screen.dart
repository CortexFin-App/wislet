import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wislet/core/constants/app_constants.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/budget_repository.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/data/repositories/goal_repository.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/models/category.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/financial_goal.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/providers/app_mode_provider.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/pro_status_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/transactions/create_transfer_screen.dart';
import 'package:wislet/screens/transactions/qr_scanner_screen.dart';
import 'package:wislet/services/ai_categorization_service.dart';
import 'package:wislet/services/analytics_service.dart';
import 'package:wislet/services/auth_service.dart';
import 'package:wislet/services/exchange_rate_service.dart';
import 'package:wislet/services/ocr_service.dart';
import 'package:wislet/services/receipt_parser.dart';
import 'package:wislet/widgets/scaffold/patterned_scaffold.dart';

enum _TransactionScreenMode { expense, income, transfer }

class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    this.transactionToEdit,
    this.isFirstTransaction = false,
    this.isTransferAllowed = true,
  });
  final fin_transaction.Transaction? transactionToEdit;
  final bool isFirstTransaction;
  final bool isTransferAllowed;

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransactionRepository _transactionRepo = getIt<TransactionRepository>();
  final CategoryRepository _categoryRepo = getIt<CategoryRepository>();
  final GoalRepository _goalRepo = getIt<GoalRepository>();
  final BudgetRepository _budgetRepo = getIt<BudgetRepository>();
  final AICategorizationService _aiCategorizationService =
      getIt<AICategorizationService>();
  final OcrService _ocrService = getIt<OcrService>();
  final ReceiptParser _receiptParser = getIt<ReceiptParser>();
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();

  Timer? _debounce;
  bool _showDetails = false;
  bool _userHasManuallySelectedCategory = false;

  _TransactionScreenMode _selectedMode = _TransactionScreenMode.expense;
  final TextEditingController _amountController = TextEditingController();
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _descriptionController = TextEditingController();
  Currency? _selectedInputCurrency;

  bool _isSaving = false;
  bool _isScanning = false;
  List<Category> _availableCategories = [];
  bool _isLoadingCategories = true;
  bool get _isEditing => widget.transactionToEdit != null;
  int? _originalLinkedGoalIdBeforeEdit;

  final String _baseCurrencyCode = 'UAH';
  ConversionRateInfo? _currentRateInfo;
  bool _isLoadingRate = false;
  List<FinancialGoal> _availableGoals = [];
  FinancialGoal? _selectedLinkedGoal;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _descriptionController.addListener(_onDescriptionChanged);
    _setupInitialState();
  }

  void _setupInitialState() {
    if (_isEditing) {
      final transaction = widget.transactionToEdit!;
      _originalLinkedGoalIdBeforeEdit = transaction.linkedGoalId;
      _selectedMode =
          transaction.type == fin_transaction.TransactionType.expense
              ? _TransactionScreenMode.expense
              : _TransactionScreenMode.income;
      _amountController.text =
          transaction.originalAmount.toStringAsFixed(2).replaceAll('.', ',');
      _selectedDate = transaction.date;
      _descriptionController.text = transaction.description ?? '';
      _selectedInputCurrency = appCurrencies.firstWhereOrNull(
            (c) => c.code == transaction.originalCurrencyCode,
          ) ??
          appCurrencies.firstWhere((curr) => curr.code == _baseCurrencyCode);
      if (transaction.exchangeRateUsed != null &&
          transaction.originalCurrencyCode != _baseCurrencyCode) {
        _currentRateInfo = ConversionRateInfo(
          rate: transaction.exchangeRateUsed!,
          effectiveRateDate: transaction.date,
          isRateStale: true,
        );
      } else {
        _fetchAndSetExchangeRate(
          date: _selectedDate,
          currency: _selectedInputCurrency,
        );
      }
    } else {
      _selectedInputCurrency =
          context.read<CurrencyProvider>().selectedCurrency;
      _fetchAndSetExchangeRate(
        date: _selectedDate,
        currency: _selectedInputCurrency,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesForType(
        _selectedMode == _TransactionScreenMode.income
            ? fin_transaction.TransactionType.income
            : fin_transaction.TransactionType.expense,
        initialCategoryId: widget.transactionToEdit?.categoryId,
      );
      _loadAvailableGoals();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amountController.removeListener(() => setState(() {}));
    _descriptionController.removeListener(_onDescriptionChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onDescriptionChanged() async {
    if (_userHasManuallySelectedCategory) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isAiEnabled =
        prefs.getBool(AppConstants.prefsKeyAiCategorization) ?? true;
    if (!mounted || !isAiEnabled) return;
    final proStatus = context.read<ProStatusProvider>();
    if (!proStatus.isPro) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final walletId = context.read<WalletProvider>().currentWallet?.id;
      if (walletId == null || _descriptionController.text.trim().length < 3) {
        return;
      }
      final suggestedCategory = await _aiCategorizationService.suggestCategory(
        description: _descriptionController.text,
        walletId: walletId,
      );

      if (mounted &&
          suggestedCategory != null &&
          _selectedCategory?.id != suggestedCategory.id &&
          !_userHasManuallySelectedCategory) {
        setState(() => _selectedCategory = suggestedCategory);
      }
    });
  }

  Future<void> _saveTransaction() async {
    final walletProvider = context.read<WalletProvider>();
    final authService = context.read<AuthService>();
    final appModeProvider = context.read<AppModeProvider>();

    if (!_formKey.currentState!.validate() || _isSaving) return;

    final currentWalletId = walletProvider.currentWallet?.id;
    final currentUserId =
        appModeProvider.isOnline ? authService.currentUser?.id : '1';

    if (currentWalletId == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Помилка: не вдалося визначити гаманець або користувача. Спробуйте перезайти.',
          ),
        ),
      );
      return;
    }

    final amountString = _amountController.text.replaceAll(',', '.');
    final originalAmount = double.tryParse(amountString);
    if (originalAmount == null ||
        _selectedCategory == null ||
        _selectedInputCurrency == null) {
      return;
    }

    if (_selectedCategory!.id != null &&
        _descriptionController.text.trim().isNotEmpty) {
      await _aiCategorizationService.rememberUserChoice(
        _descriptionController.text.trim(),
        _selectedCategory!,
      );
    }

    final finalExchangeRate = _currentRateInfo?.rate ?? 1.0;

    setState(() => _isSaving = true);
    final amountInBase = originalAmount * finalExchangeRate;
    final newLinkedGoalId = _selectedLinkedGoal?.id;

    final transactionToSave = fin_transaction.Transaction(
      id: widget.transactionToEdit?.id,
      type: _selectedMode == _TransactionScreenMode.income
          ? fin_transaction.TransactionType.income
          : fin_transaction.TransactionType.expense,
      originalAmount: originalAmount,
      originalCurrencyCode: _selectedInputCurrency!.code,
      amountInBaseCurrency: amountInBase,
      exchangeRateUsed: finalExchangeRate,
      categoryId: _selectedCategory!.id!,
      date: _selectedDate,
      description: _descriptionController.text.trim(),
      linkedGoalId: newLinkedGoalId,
    );

    final result = _isEditing
        ? await _transactionRepo.updateTransaction(
            transactionToSave,
            currentWalletId,
            currentUserId,
          )
        : await _transactionRepo.createTransaction(
            transactionToSave,
            currentWalletId,
            currentUserId,
          );

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await result.fold((failure) {
      messenger.showSnackBar(
        SnackBar(content: Text('Помилка: ${failure.userMessage}')),
      );
      if (mounted) setState(() => _isSaving = false);
    }, (savedId) async {
      final finalTransaction = fin_transaction.Transaction.fromMap(
        transactionToSave.toMap()..['id'] = savedId,
      );

      try {
        if (_isEditing &&
            _originalLinkedGoalIdBeforeEdit != null &&
            _originalLinkedGoalIdBeforeEdit != newLinkedGoalId) {
          await _goalRepo
              .updateFinancialGoalProgress(_originalLinkedGoalIdBeforeEdit!);
        }
        await _runPostSaveChecks(finalTransaction, currentWalletId);
        if (mounted) {
          final returnData = {
            'transaction': finalTransaction,
            'isIncome': _selectedMode == _TransactionScreenMode.income,
          };
          navigator.pop(widget.isFirstTransaction ? returnData : true);
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Транзакцію збережено, але сталася помилка: $e',
              ),
            ),
          );
          if (navigator.canPop()) {
            navigator.pop(true);
          }
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    });
  }

  Future<void> _scanReceipt() async {
    final proStatusProvider = context.read<ProStatusProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!mounted) return;

    if (!proStatusProvider.isPro) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Сканування чеків доступне лише у Pro-версії.',
          ),
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.camera);
    if (imageFile == null || !mounted) return;
    setState(() => _isScanning = true);
    try {
      final recognizedText = await _ocrService.processImage(imageFile.path);
      if (recognizedText != null && mounted) {
        final result = _receiptParser.parseFromText(recognizedText);
        setState(() {
          if (result.totalAmount != null) {
            _amountController.text =
                result.totalAmount!.toStringAsFixed(2).replaceAll('.', ',');
          }
          if (result.date != null) {
            _selectedDate = result.date!;
          }
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Дані з чека заповнено!'),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Не вдалося розпізнати текст на зображенні.',
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Помилка сканування: $e')),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _scanQrCode() async {
    final proStatusProvider = context.read<ProStatusProvider>();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!proStatusProvider.isPro) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Сканування QR доступне лише у Pro-версії.',
          ),
        ),
      );
      return;
    }

    final result = await navigator.push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      final parsedData = _receiptParser.parseQrCode(result);
      setState(() {
        if (parsedData.totalAmount != null) {
          _amountController.text = parsedData.totalAmount!
              .toStringAsFixed(2)
              .replaceAll('.', ',');
        }
        if (parsedData.date != null) {
          _selectedDate = parsedData.date!;
        }
        if (parsedData.merchantName != null) {
          _descriptionController.text = parsedData.merchantName!;
        }
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Дані з QR-коду заповнено!'),
        ),
      );
    }
  }

  Future<void> _loadAvailableGoals() async {
    if (!mounted) return;
    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId == null) return;

    final allGoalsEither = await _goalRepo.getAllFinancialGoals(walletId);
    if (!mounted) return;

    allGoalsEither.fold((failure) => _availableGoals = [], (allGoals) {
      _availableGoals = allGoals.where((goal) => !goal.isAchieved).toList();
      if (_isEditing && widget.transactionToEdit?.linkedGoalId != null) {
        _selectedLinkedGoal = _availableGoals.firstWhereOrNull(
          (goal) => goal.id == widget.transactionToEdit!.linkedGoalId,
        );
      }
    });
    if (mounted) setState(() {});
  }

  Future<void> _fetchAndSetExchangeRate({
    DateTime? date,
    Currency? currency,
  }) async {
    final targetDate = date ?? _selectedDate;
    final targetCurrency = currency ?? _selectedInputCurrency;

    if (targetCurrency == null || targetCurrency.code == _baseCurrencyCode) {
      if (mounted) {
        setState(
          () => _currentRateInfo = ConversionRateInfo(
            rate: 1,
            effectiveRateDate: targetDate,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoadingRate = true;
      _currentRateInfo = null;
    });

    try {
      final rateInfo = await _exchangeRateService.getConversionRate(
        targetCurrency.code,
        _baseCurrencyCode,
        date: targetDate,
      );
      if (mounted) {
        setState(() {
          _currentRateInfo = rateInfo;
          _isLoadingRate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentRateInfo = null;
          _isLoadingRate = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не вдалося отримати курс для ${targetCurrency.code}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadCategoriesForType(
    fin_transaction.TransactionType type, {
    int? initialCategoryId,
  }) async {
    if (!mounted) return;
    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId == null) return;

    setState(() {
      _isLoadingCategories = true;
      _selectedCategory = null;
      _availableCategories = [];
    });

    final categoryTypeToLoad = (type == fin_transaction.TransactionType.income)
        ? CategoryType.income
        : CategoryType.expense;
    var categoriesEither =
        await _categoryRepo.getCategoriesByType(walletId, categoryTypeToLoad);

    var categories = categoriesEither.getOrElse((_) => []);

    if (categories.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final flagKey = 'default_categories_created_for_wallet_$walletId';
      final alreadyCreated = prefs.getBool(flagKey) ?? false;

      if (!alreadyCreated) {
        await _categoryRepo.addDefaultCategories(walletId);
        await prefs.setBool(flagKey, true);

        categoriesEither = await _categoryRepo.getCategoriesByType(
          walletId,
          categoryTypeToLoad,
        );
        categories = categoriesEither.getOrElse((_) => []);
      }
    }

    if (mounted) {
      setState(() {
        _availableCategories = categories;
        if (initialCategoryId != null) {
          _selectedCategory =
              categories.firstWhereOrNull((cat) => cat.id == initialCategoryId);
        }
        _isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletProvider = context.watch<WalletProvider>();
    final authService = context.watch<AuthService>();
    final appModeProvider = context.watch<AppModeProvider>();

    final isUserAvailable =
        !appModeProvider.isOnline || authService.currentUser != null;
    final isRateReady = _selectedInputCurrency?.code == _baseCurrencyCode ||
        (_currentRateInfo != null && !_isLoadingRate);
    final canSave = !_isSaving &&
        _amountController.text.isNotEmpty &&
        _selectedCategory != null &&
        walletProvider.currentWallet != null &&
        isUserAvailable &&
        isRateReady;

    var titleText = _isEditing
        ? 'Редагувати транзакцію'
        : 'Нова транзакція';
    if (widget.isFirstTransaction) {
      titleText = _selectedMode == _TransactionScreenMode.income
          ? 'Ваш перший дохід'
          : 'Ваша перша витрата';
    }

    return PatternedScaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          if (!widget.isFirstTransaction) ...[
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_outlined),
              tooltip: 'Сканувати QR-код',
              onPressed: _scanQrCode,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Сканувати чек',
              onPressed: _scanReceipt,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                SegmentedButton<_TransactionScreenMode>(
                  style: theme.segmentedButtonTheme.style,
                  segments: <ButtonSegment<_TransactionScreenMode>>[
                    const ButtonSegment(
                      value: _TransactionScreenMode.expense,
                      label: Text('Витрата'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    const ButtonSegment(
                      value: _TransactionScreenMode.income,
                      label: Text('Дохід'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                    if (widget.isTransferAllowed)
                      const ButtonSegment(
                        value: _TransactionScreenMode.transfer,
                        label: Text('Переказ'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                  ],
                  selected: <_TransactionScreenMode>{_selectedMode},
                  onSelectionChanged:
                      (Set<_TransactionScreenMode> newSelection) async {
                    if (mounted) {
                      if (newSelection.first ==
                          _TransactionScreenMode.transfer) {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateTransferScreen(),
                          ),
                        );
                        if (result ?? false) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.of(context).pop(true);
                            }
                          });
                        }
                      } else {
                        setState(() {
                          _selectedMode = newSelection.first;
                          _loadCategoriesForType(
                            _selectedMode ==
                                    _TransactionScreenMode.income
                                ? fin_transaction.TransactionType.income
                                : fin_transaction.TransactionType.expense,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Сума',
                    prefixIcon: _selectedInputCurrency != null
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              _selectedInputCurrency!.symbol,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : null,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введіть суму';
                    }
                    final cleanValue = value.replaceAll(',', '.');
                    if (double.tryParse(cleanValue) == null) {
                      return 'Коректне число';
                    }
                    if (double.parse(cleanValue) <= 0) {
                      return 'Більше нуля';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_isLoadingCategories)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_availableCategories.isEmpty)
                  Card(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Спочатку створіть категорії для "${_selectedMode == _TransactionScreenMode.expense ? 'витрат' : 'доходів'}" в налаштуваннях.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Категорія',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    hint: const Text('Оберіть категорію'),
                    isExpanded: true,
                    items: _availableCategories
                        .map(
                          (Category category) => DropdownMenuItem<Category>(
                            value: category,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        _userHasManuallySelectedCategory = true;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Оберіть категорію' : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Опис (опціонально)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showDetails
                      ? _buildDetailsSection()
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _showDetails = !_showDetails),
                      child: Text(
                        _showDetails
                            ? 'Сховати деталі'
                            : 'Показати деталі',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: canSave ? _saveTransaction : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Зберегти' : 'Додати',
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isScanning)
            ColoredBox(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Обробка зображення...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(
          'Додаткові параметри',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Currency>(
          decoration: const InputDecoration(
            labelText: 'Валюта',
            prefixIcon: Icon(Icons.currency_exchange_outlined),
          ),
          initialValue: _selectedInputCurrency,
          items: appCurrencies
              .map(
                (Currency currency) => DropdownMenuItem<Currency>(
                  value: currency,
                  child: Text('${currency.code} - ${currency.name}'),
                ),
              )
              .toList(),
          onChanged: (Currency? newValue) {
            if (mounted && newValue != null) {
              setState(() => _selectedInputCurrency = newValue);
              _fetchAndSetExchangeRate(currency: newValue);
            }
          },
          validator: (value) =>
              value == null ? 'Оберіть валюту' : null,
        ),
        if (_isLoadingRate)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_currentRateInfo != null &&
            _selectedInputCurrency?.code != _baseCurrencyCode)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Курс: 1 ${_selectedInputCurrency?.code} ≈ ${_currentRateInfo!.rate.toStringAsFixed(4)} $_baseCurrencyCode',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(
            'Дата: ${DateFormat('dd.MM.yyyy, HH:mm').format(_selectedDate)}',
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null && mounted) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_selectedDate),
              );
              if (mounted) {
                setState(() {
                  _selectedDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime?.hour ?? _selectedDate.hour,
                    pickedTime?.minute ?? _selectedDate.minute,
                  );
                });
                await _fetchAndSetExchangeRate(
                  date: _selectedDate,
                  currency: _selectedInputCurrency,
                );
              }
            }
          },
        ),
        const SizedBox(height: 16),
        if (_availableGoals.isNotEmpty)
          DropdownButtonFormField<FinancialGoal?>(
            initialValue: _selectedLinkedGoal,
            decoration: InputDecoration(
              labelText: "Прив'язати до цілі",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.flag_outlined),
              suffixIcon: _selectedLinkedGoal != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () =>
                          setState(() => _selectedLinkedGoal = null),
                    )
                  : null,
            ),
            isExpanded: true,
            hint: const Text("Не прив'язувати"),
            items: [
              const DropdownMenuItem<FinancialGoal?>(
                child: Text("Не прив'язувати до цілі"),
              ),
              ..._availableGoals.map((FinancialGoal goal) {
                return DropdownMenuItem<FinancialGoal?>(
                  value: goal,
                  child: Text(goal.name, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: (FinancialGoal? newValue) =>
                setState(() => _selectedLinkedGoal = newValue),
          ),
      ],
    );
  }

  Future<void> _runPostSaveChecks(
    fin_transaction.Transaction transaction,
    int walletId,
  ) async {
    await _budgetRepo.checkAndNotifyEnvelopeLimits(transaction, walletId);
    if (transaction.linkedGoalId != null) {
      await _goalRepo.updateFinancialGoalProgress(transaction.linkedGoalId!);
    }
    if (mounted) {
      final proStatus = context.read<ProStatusProvider>();
      if (proStatus.isPro) {
        await _analyticsService.analyzeAndNotifyOnNewTransaction(
          transaction,
          walletId,
        );
      }
    }
  }
}
