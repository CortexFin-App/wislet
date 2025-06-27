import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_scanner_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injector.dart';
import '../../providers/currency_provider.dart'; 
import '../../providers/pro_status_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/currency_model.dart'; 	
import '../../models/transaction.dart' as FinTransaction;
import '../../models/category.dart';
import '../../models/financial_goal.dart';
import '../../models/receipt_parse_result.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/ai_categorization_service.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';
import '../../services/analytics_service.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/budget_repository.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final FinTransaction.Transaction? transactionToEdit;
  const AddEditTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransactionRepository _transactionRepo = getIt<TransactionRepository>();
  final CategoryRepository _categoryRepo = getIt<CategoryRepository>();
  final GoalRepository _goalRepo = getIt<GoalRepository>();
  final BudgetRepository _budgetRepo = getIt<BudgetRepository>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();
  final AICategorizationService _aiCategorizationService = getIt<AICategorizationService>();
  final OcrService _ocrService = getIt<OcrService>();
  final ReceiptParser _receiptParser = getIt<ReceiptParser>();
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  
  Timer? _debounce;
  
  FinTransaction.TransactionType _selectedTransactionType = FinTransaction.TransactionType.expense;
  final TextEditingController _amountController = TextEditingController();
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _descriptionController = TextEditingController();
  Currency? _selectedInputCurrency; 
  
  bool _isSaving = false;
  bool _isScanning = false;
  List<Category> _availableCategories = [];
  bool _isLoadingCategories = false;
  bool get _isEditing => widget.transactionToEdit != null;
  int? _originalLinkedGoalIdBeforeEdit;
  
  final String _baseCurrencyCode = 'UAH';
  bool _isFetchingRate = false;
  String? _rateFetchingError;
  ConversionRateInfo? _currentRateInfo;
  
  bool _isManuallyEnteringRate = false;
  final TextEditingController _manualRateController = TextEditingController();
  bool _manualRateSetByButton = false;
  List<FinancialGoal> _availableGoals = [];
  FinancialGoal? _selectedLinkedGoal;
  bool _isLoadingGoals = false;
  Category? _suggestedNewCategory;
  int? _aiSuggestedCategoryId;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_onDescriptionChanged);
    _setupInitialState();
  }
  
  void _setupInitialState() {
    if (_isEditing) {
      final transaction = widget.transactionToEdit!;
      _originalLinkedGoalIdBeforeEdit = transaction.linkedGoalId;
      _selectedTransactionType = transaction.type;
      _amountController.text = transaction.originalAmount.toStringAsFixed(2).replaceAll('.', ',');
      _selectedDate = transaction.date;
      _descriptionController.text = transaction.description ?? '';
      _selectedInputCurrency = appCurrencies.firstWhereOrNull(
        (c) => c.code == transaction.originalCurrencyCode,
      ) ?? appCurrencies.firstWhere((curr) => curr.code == _baseCurrencyCode);
      
      if (transaction.exchangeRateUsed != null && transaction.originalCurrencyCode != _baseCurrencyCode) {
          _currentRateInfo = ConversionRateInfo(
            rate: transaction.exchangeRateUsed!,
            effectiveRateDate: transaction.date, 
            isRateStale: true 
        );
      } else if (_selectedInputCurrency!.code != _baseCurrencyCode) {
        _fetchAndSetExchangeRate(date: _selectedDate, currency: _selectedInputCurrency);
      } else {
        _currentRateInfo = ConversionRateInfo(rate: 1.0, effectiveRateDate: _selectedDate, isRateStale: false);
      }
    } else {
      _selectedInputCurrency = context.read<CurrencyProvider>().selectedCurrency;
      if (_selectedInputCurrency!.code != _baseCurrencyCode) {
        _fetchAndSetExchangeRate(date: _selectedDate, currency: _selectedInputCurrency);
      } else {
        _currentRateInfo = ConversionRateInfo(rate: 1.0, effectiveRateDate: _selectedDate, isRateStale: false);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesForType(_selectedTransactionType, initialCategoryId: widget.transactionToEdit?.categoryId);
      _loadAvailableGoals();
    });
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    _descriptionController.removeListener(_onDescriptionChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    _manualRateController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isAiEnabled = prefs.getBool(AppConstants.prefsKeyAiCategorization) ?? true;
    if (!isAiEnabled) return;
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted || !context.read<ProStatusProvider>().isPro) return;

      final walletId = context.read<WalletProvider>().currentWallet?.id;
      if (walletId == null || _descriptionController.text.trim().length < 3) {
        if(mounted) setState(() => _suggestedNewCategory = null);
        return;
      }

      final suggestedCategory = await _aiCategorizationService.suggestCategory(
        description: _descriptionController.text, 
        walletId: walletId
      );
      
      if (mounted) {
        if (suggestedCategory != null) {
          if (suggestedCategory.id != null) {
            if (_selectedCategory?.id != suggestedCategory.id) {
              setState(() {
                _selectedCategory = suggestedCategory;
                _suggestedNewCategory = null;
              });
            }
          } else {
             if (_suggestedNewCategory?.name != suggestedCategory.name) {
              setState(() {
                _selectedCategory = null;
                _suggestedNewCategory = suggestedCategory;
              });
            }
          }
        } else {
          setState(() => _suggestedNewCategory = null);
        }
      }
    });
  }

  Future<void> _createAndSelectSuggestedCategory() async {
    if (_suggestedNewCategory == null) return;

    final walletId = context.read<WalletProvider>().currentWallet!.id!;
    final categoryType = _selectedTransactionType == FinTransaction.TransactionType.income 
        ? CategoryType.income 
        : CategoryType.expense;

    final newCategory = Category(
      name: _suggestedNewCategory!.name,
      type: categoryType,
    );

    try {
      final newId = await _categoryRepo.createCategory(newCategory, walletId);
      final createdCategory = Category(id: newId, name: newCategory.name, type: newCategory.type);

      await _loadCategoriesForType(_selectedTransactionType);
      if(mounted) {
        setState(() {
          _selectedCategory = createdCategory;
          _suggestedNewCategory = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка створення категорії: $e')));
      }
    }
  }

  Future<void> _scanReceipt() async {
    if (!context.read<ProStatusProvider>().isPro) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сканування чеків доступне лише у Pro-версії.')));
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(source: ImageSource.camera);
    if (imageFile == null || !mounted) return;

    setState(() => _isScanning = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final recognizedText = await _ocrService.processImage(imageFile.path);
      if (recognizedText != null && mounted) {
        final result = _receiptParser.parseFromText(recognizedText);
        setState(() {
          if (result.totalAmount != null) {
            _amountController.text = result.totalAmount!.toStringAsFixed(2).replaceAll('.', ',');
          }
          if (result.date != null) {
            _selectedDate = result.date!;
          }
        });
        messenger.showSnackBar(const SnackBar(content: Text('Дані з чека заповнено!')));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Не вдалося розпізнати текст на зображенні.')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Помилка сканування: $e')));
    } finally {
      if(mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _scanQrCode() async {
    if (!context.read<ProStatusProvider>().isPro) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сканування QR доступне лише у Pro-версії.')));
      return;
    }
    
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await navigator.push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      final parsedData = _receiptParser.parseQrCode(result);
      setState(() {
        if (parsedData.totalAmount != null) {
          _amountController.text = parsedData.totalAmount!.toStringAsFixed(2).replaceAll('.', ',');
        }
        if (parsedData.date != null) {
          _selectedDate = parsedData.date!;
        }
        if(parsedData.merchantName != null){
          _descriptionController.text = parsedData.merchantName!;
        }
      });
      messenger.showSnackBar(const SnackBar(content: Text('Дані з QR-коду заповнено!')));
    }
  }

  Future<void> _loadAvailableGoals() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) return;
    setState(() => _isLoadingGoals = true);
    try {
      final allGoals = await _goalRepo.getAllFinancialGoals(currentWalletId);
      if (!mounted) return;
      
      _availableGoals = allGoals.where((goal) => !goal.isAchieved).toList();
      if (_isEditing && widget.transactionToEdit?.linkedGoalId != null) {
          _selectedLinkedGoal = _availableGoals.firstWhereOrNull(
            (goal) => goal.id == widget.transactionToEdit!.linkedGoalId,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGoals = false);
      }
    }
  }

  Future<void> _fetchAndSetExchangeRate({DateTime? date, Currency? currency, bool calledFromManualCancel = false}) async {
    final targetDate = date ?? _selectedDate;
    final targetCurrency = currency ?? _selectedInputCurrency;
    if (targetCurrency == null || targetCurrency.code == _baseCurrencyCode) {
      if (mounted) {
        setState(() {
          _currentRateInfo = ConversionRateInfo(rate: 1.0, effectiveRateDate: targetDate, isRateStale: false);
          _rateFetchingError = null;
          _isFetchingRate = false;
          _isManuallyEnteringRate = false;
          _manualRateSetByButton = false;
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
      final ConversionRateInfo rateInfo = await _exchangeRateService.getConversionRate(
        targetCurrency.code,
        _baseCurrencyCode,
        date: targetDate,
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
          _rateFetchingError = "Курс для ${targetCurrency.code} на ${DateFormat('dd.MM.yy').format(targetDate)}: помилка.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingRate = false);
      }
    }
  }
  
  void _applyManualRate() {
    final double? manualRate = double.tryParse(_manualRateController.text.replaceAll(',', '.'));
    if (manualRate != null && manualRate > 0) {
      if(mounted) {
        setState(() {
          _currentRateInfo = ConversionRateInfo(
            rate: manualRate, 
            effectiveRateDate: _selectedDate, 
            isRateStale: true 
          );
          _manualRateSetByButton = true;
          _isManuallyEnteringRate = false;
          _rateFetchingError = null; 
        });
      }
    }
  }

  Future<void> _loadCategoriesForType(FinTransaction.TransactionType type, {int? initialCategoryId}) async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if(currentWalletId == null) return;
    
    setState(() {
      _isLoadingCategories = true;
      _selectedCategory = null; 
      _availableCategories = []; 
    });
    CategoryType categoryTypeToLoad = (type == FinTransaction.TransactionType.income)
        ? CategoryType.income
        : CategoryType.expense;

    final categories = await _categoryRepo.getCategoriesByType(currentWalletId, categoryTypeToLoad);
    if (!mounted) return;

    setState(() {
      _availableCategories = categories;
      if (initialCategoryId != null && categories.any((Category cat) => cat.id == initialCategoryId)) {
        _selectedCategory = categories.firstWhere((Category cat) => cat.id == initialCategoryId);
      }
      _isLoadingCategories = false;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
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
        _fetchAndSetExchangeRate(date: _selectedDate, currency: _selectedInputCurrency);
      }
    }
  }

  Future<void> _runPostSaveChecks(FinTransaction.Transaction transaction, int walletId) async {
    await _budgetRepo.checkAndNotifyEnvelopeLimits(transaction, walletId);
    if (transaction.linkedGoalId != null) {
      await _goalRepo.updateFinancialGoalProgress(transaction.linkedGoalId!);
    }
    if(mounted && context.read<ProStatusProvider>().isPro) {
      await _analyticsService.analyzeAndNotifyOnNewTransaction(transaction, walletId);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) return;
    
    final amountString = _amountController.text.replaceAll(',', '.');
    final originalAmount = double.tryParse(amountString);
    if (originalAmount == null || _selectedCategory == null || _selectedInputCurrency == null) return;
    
    if (_selectedCategory!.id != null && _aiSuggestedCategoryId != _selectedCategory!.id) {
        await _aiCategorizationService.rememberUserChoice(_descriptionController.text.trim(), _selectedCategory!);
    }
    
    double? finalExchangeRate;
    if (_selectedInputCurrency!.code == _baseCurrencyCode) {
      finalExchangeRate = 1.0;
    } else if (_manualRateSetByButton && _currentRateInfo != null) {
        finalExchangeRate = _currentRateInfo!.rate;
    } else if (_currentRateInfo != null && !_currentRateInfo!.isRateStale && _rateFetchingError == null) {
        finalExchangeRate = _currentRateInfo!.rate;
    }

    if (finalExchangeRate == null || finalExchangeRate <= 0) return;
    if (!mounted) return;
    setState(() => _isSaving = true);
    double amountInBase = originalAmount * finalExchangeRate;
    
    FinTransaction.Transaction transactionToSave;
    int? transactionId = _isEditing ? widget.transactionToEdit!.id : null;
    final int? newLinkedGoalId = _selectedLinkedGoal?.id;

    if (_isEditing) {
      transactionToSave = FinTransaction.Transaction(
        id: transactionId,
        type: _selectedTransactionType,
        originalAmount: originalAmount,
        originalCurrencyCode: _selectedInputCurrency!.code,
        amountInBaseCurrency: amountInBase,
        exchangeRateUsed: finalExchangeRate,
        categoryId: _selectedCategory!.id!,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
        linkedGoalId: newLinkedGoalId,
      );
      await _transactionRepo.updateTransaction(transactionToSave, currentWalletId);
    } else {
      transactionToSave = FinTransaction.Transaction(
        type: _selectedTransactionType,
        originalAmount: originalAmount,
        originalCurrencyCode: _selectedInputCurrency!.code,
        amountInBaseCurrency: amountInBase,
        exchangeRateUsed: finalExchangeRate,
        categoryId: _selectedCategory!.id!,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
        linkedGoalId: newLinkedGoalId,
      );
      int newId = await _transactionRepo.createTransaction(transactionToSave, currentWalletId);
      transactionToSave = FinTransaction.Transaction(
          id: newId, type: transactionToSave.type, originalAmount: transactionToSave.originalAmount,
          originalCurrencyCode: transactionToSave.originalCurrencyCode, amountInBaseCurrency: transactionToSave.amountInBaseCurrency,
          exchangeRateUsed: transactionToSave.exchangeRateUsed, categoryId: transactionToSave.categoryId,
          date: transactionToSave.date, description: transactionToSave.description, linkedGoalId: transactionToSave.linkedGoalId,
      );
    }
        
    try {
        if (_isEditing && _originalLinkedGoalIdBeforeEdit != null && _originalLinkedGoalIdBeforeEdit != newLinkedGoalId) {
            await _goalRepo.updateFinancialGoalProgress(_originalLinkedGoalIdBeforeEdit!);
        }
        await _runPostSaveChecks(transactionToSave, currentWalletId);
        if (mounted) {
            Navigator.of(context).pop(true);
        }
    } catch (e) {
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Транзакцію збережено, але сталася помилка при оновленні: $e')),
            );
            if (Navigator.canPop(context)) Navigator.of(context).pop(true);
        }
    } finally {
        if (mounted) {
            setState(() => _isSaving = false);
        }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    bool canSave = !_isSaving && !_isScanning &&
                    (_selectedInputCurrency?.code == _baseCurrencyCode || 
                    (_manualRateSetByButton && _currentRateInfo != null && _currentRateInfo!.rate > 0) ||
                    (_currentRateInfo != null && !_currentRateInfo!.isRateStale && _rateFetchingError == null && !_isFetchingRate && _currentRateInfo!.rate > 0)
                    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати транзакцію' : 'Додати транзакцію'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                Consumer<ProStatusProvider>(
                    builder: (context, proStatus, child) {
                      if (!proStatus.isPro) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Скан Чека'),
                                onPressed: _isScanning ? null : _scanReceipt,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.qr_code_scanner_outlined),
                                label: const Text('Скан QR'),
                                onPressed: _isScanning ? null : _scanQrCode,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                ),
                SegmentedButton<FinTransaction.TransactionType>(
                  segments: const <ButtonSegment<FinTransaction.TransactionType>>[
                    ButtonSegment<FinTransaction.TransactionType>(value: FinTransaction.TransactionType.expense, label: Text('Витрата'), icon: Icon(Icons.arrow_upward)),
                    ButtonSegment<FinTransaction.TransactionType>(value: FinTransaction.TransactionType.income, label: Text('Дохід'), icon: Icon(Icons.arrow_downward)),
                  ],
                  selected: <FinTransaction.TransactionType>{_selectedTransactionType},
                  onSelectionChanged: (Set<FinTransaction.TransactionType> newSelection) {
                    if (mounted) {
                      setState(() {
                        _selectedTransactionType = newSelection.first;
                        _loadCategoriesForType(_selectedTransactionType);
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: const Key('amount_field'),
                        controller: _amountController,
                        decoration: InputDecoration(labelText: 'Сума', border: const OutlineInputBorder(), prefixIcon: _selectedInputCurrency != null ? Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0) , child: Text(_selectedInputCurrency!.symbol, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant))) : const Icon(Icons.money),),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) { if (value == null || value.isEmpty) return 'Введіть суму'; final cleanValue = value.replaceAll(',', '.'); if (double.tryParse(cleanValue) == null) return 'Коректне число'; if (double.parse(cleanValue) <= 0) return 'Більше нуля'; return null; },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<Currency>(
                        decoration: const InputDecoration(labelText: 'Валюта', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0)),
                        value: _selectedInputCurrency,
                        items: appCurrencies.map((Currency currency) => DropdownMenuItem<Currency>(value: currency, child: Text(currency.code))).toList(),
                        onChanged: (Currency? newValue) { if (mounted && newValue != null) { setState(() { _selectedInputCurrency = newValue; _isManuallyEnteringRate = false; _manualRateSetByButton = false; _manualRateController.clear(); }); _fetchAndSetExchangeRate(currency: newValue);}},
                        validator: (value) => value == null ? 'Оберіть' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isFetchingRate) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Center(child: SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2,)))),
                if (!_isFetchingRate && _rateFetchingError != null && !_isManuallyEnteringRate && _selectedInputCurrency?.code != _baseCurrencyCode) Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Column(children: [Text(_rateFetchingError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12), textAlign: TextAlign.center), TextButton(child: const Text('Ввести курс вручну?'), onPressed: () { if(mounted) setState(() { _isManuallyEnteringRate = true; _rateFetchingError = null; });})],),),
                if (_isManuallyEnteringRate && _selectedInputCurrency?.code != _baseCurrencyCode) Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [Expanded(child: TextFormField(controller: _manualRateController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '1 ${_selectedInputCurrency?.code} = X UAH', hintText: 'Введіть курс', border: const OutlineInputBorder()), validator: (value) {if (value == null || value.isEmpty) return 'Вкажіть курс'; final val = double.tryParse(value.replaceAll(',', '.')); if (val == null || val <= 0) return 'Невірне значення'; return null;},)), IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green), tooltip: 'Застосувати курс', onPressed: _applyManualRate), IconButton(icon: const Icon(Icons.cancel_outlined), tooltip: 'Скасувати ручне введення', onPressed: (){if(mounted)setState(() { _isManuallyEnteringRate = false; _manualRateSetByButton = false; _manualRateController.clear(); }); _fetchAndSetExchangeRate(calledFromManualCancel: true);})],),),
                if (!_isFetchingRate && _rateFetchingError == null && _currentRateInfo != null && _selectedInputCurrency?.code != _baseCurrencyCode) Padding(padding: const EdgeInsets.only(top: 4.0, bottom: 8.0), child: Text(_manualRateSetByButton ? "Встановлено вручну: 1 ${_selectedInputCurrency!.code} = ${(_currentRateInfo!.rate).toStringAsFixed(4)} $_baseCurrencyCode" : "1 ${_selectedInputCurrency!.code} ≈ ${(_currentRateInfo!.rate).toStringAsFixed(4)} $_baseCurrencyCode на ${DateFormat('dd.MM.yy').format(_currentRateInfo!.effectiveRateDate)}${_currentRateInfo!.isRateStale ? ' (застарілий)' : ''}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _manualRateSetByButton ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center)),
                const SizedBox(height: 12),
                if (_isLoadingCategories) const Center(child: CircularProgressIndicator())
                else if (_availableCategories.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Немає доступних категорій для типу "${_selectedTransactionType == FinTransaction.TransactionType.income ? "Дохід" : "Витрата"}".\nСпочатку додайте їх.', style: TextStyle(color: Colors.orange[700], fontStyle: FontStyle.italic), textAlign: TextAlign.center))
                else DropdownButtonFormField<Category>(value: _selectedCategory, decoration: const InputDecoration(labelText: 'Категорія', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_outlined)), hint: const Text('Оберіть категорію'), isExpanded: true, items: _availableCategories.map((Category category) => DropdownMenuItem<Category>(value: category, child: Text(category.name))).toList(), onChanged: (Category? newValue) { if (mounted) setState(() => _selectedCategory = newValue);}, validator: (value) => value == null ? 'Оберіть категорію' : null),
                if (_suggestedNewCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text("Створити та обрати: '${_suggestedNewCategory!.name}'"),
                      onPressed: _createAndSelectSuggestedCategory,
                    ),
                  ),
                const SizedBox(height: 20),
                Row(children: <Widget>[Expanded(child: Text("Дата: ${DateFormat('dd.MM.yyyy, HH:mm').format(_selectedDate)}", style: Theme.of(context).textTheme.titleMedium)), TextButton.icon(icon: const Icon(Icons.calendar_today_outlined), label: const Text('Обрати'), onPressed: () => _pickDate(context))]),
                const SizedBox(height: 20),
                TextFormField(
                    key: const Key('description_field'),
                    controller: _descriptionController, 
                    decoration: const InputDecoration(labelText: 'Опис (опціонально)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined), alignLabelWithHint: true), 
                    maxLines: 3, 
                    textInputAction: TextInputAction.done
                ),
                  const SizedBox(height: 20),
                  if (_isLoadingGoals) const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                  else if (_availableGoals.isNotEmpty)
                    DropdownButtonFormField<FinancialGoal?>(
                      value: _selectedLinkedGoal,
                      decoration: InputDecoration(
                        labelText: 'Прив\'язати до фінансової цілі (опціонально)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.assistant_photo_outlined),
                        suffixIcon: _selectedLinkedGoal != null ? 
                            IconButton(
                              icon: Icon(Icons.clear, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
                              tooltip: 'Відв\'язати від цілі',
                              onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _selectedLinkedGoal = null;
                                    });
                                  }
                                },
                            ) : null,
                      ),
                      hint: const Text('Не прив\'язувати'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<FinancialGoal?>(
                        value: null,
                        child: Text('Не прив\'язувати до цілі'),
                        ),
                        ..._availableGoals.map((FinancialGoal goal) {
                        return DropdownMenuItem<FinancialGoal?>(
                            value: goal,
                            child: Text(goal.name, overflow: TextOverflow.ellipsis),
                        );
                        }).toList(),
                      ],
                      onChanged: (FinancialGoal? newValue) {
                          if (mounted) {
                            setState(() {
                              _selectedLinkedGoal = newValue;
                            });
                          }
                      },
                    ),
                const SizedBox(height: 30),
                ElevatedButton.icon(icon: const Icon(Icons.save_outlined), label: Text(_isEditing ? 'Зберегти зміни' : 'Додати транзакцію', style: const TextStyle(fontSize: 16)), onPressed: canSave ? _saveTransaction : null, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15))),
              ],
            ),
          ),
          if (_isScanning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Обробка зображення...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}