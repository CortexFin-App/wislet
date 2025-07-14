import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/error/failures.dart';
import '../../models/transaction_view_data.dart';
import '../../providers/wallet_provider.dart';
import '../../models/transaction.dart' as fin_transaction;
import '../../models/category.dart' as fin_category;
import '../../models/currency_model.dart';
import 'transactions/add_edit_transaction_screen.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});
  @override
  TransactionsListScreenState createState() => TransactionsListScreenState();
}

class TransactionsListScreenState extends State<TransactionsListScreen> {
  Future<Either<AppFailure, List<TransactionViewData>>>? _transactionsFuture;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  fin_transaction.TransactionType? _filterTransactionType;
  int? _filterCategoryId;
  List<fin_category.Category> _allCategoriesForFilter = [];
  bool isScreenSearching = false;
  String _currentSearchQuery = '';

  bool areFiltersActive() {
    return _filterStartDate != null ||
        _filterEndDate != null ||
        _filterTransactionType != null ||
        _filterCategoryId != null ||
        (_currentSearchQuery.isNotEmpty && isScreenSearching);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        refreshData();
      }
    });
  }

  Future<void> _loadAllCategoriesForFilter() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) return;
    
    final categoriesEither = await walletProvider.categoryRepository.getAllCategories(currentWalletId);
    categoriesEither.fold(
      (l) => _allCategoriesForFilter = [], 
      (r) => _allCategoriesForFilter = r
    );

    if (mounted) setState(() {});
  }

  void _applyFiltersAndLoadTransactions() {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    
    if (walletProvider.currentWallet?.id != null) {
      setState(() {
        _transactionsFuture = walletProvider.transactionRepository.getTransactionsWithDetails(
           walletId: walletProvider.currentWallet!.id!,
          startDate: _filterStartDate,
          endDate: _filterEndDate,
          filterTransactionType: _filterTransactionType,
          filterCategoryId: _filterCategoryId,
          searchQuery: _currentSearchQuery,
        );
      });
    }
  }

  void performSearchQuery(String query) {
    if (!mounted) return;
    if (_currentSearchQuery != query.trim()) {
      setState(() {
        _currentSearchQuery = query.trim();
      });
      _applyFiltersAndLoadTransactions();
    }
  }

  void toggleSearchMode(bool searching) {
    if (!mounted) return;
    setState(() {
      isScreenSearching = searching;
      if (!isScreenSearching && _currentSearchQuery.isNotEmpty) {
        _currentSearchQuery = '';
      }
    });
    _applyFiltersAndLoadTransactions();
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() {
      _transactionsFuture = null;
    });
    await _loadAllCategoriesForFilter();
    _applyFiltersAndLoadTransactions();
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTransactionScreen()),
    );
    if (result == true && mounted) {
      refreshData();
    }
  }

  Future<void> _navigateToEditTransaction(
      TransactionViewData transactionData) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(
          transactionToEdit: transactionData.toTransactionModel(),
        ),
      ),
    );
    if (result == true && mounted) {
      refreshData();
    }
  }

  Future<void> _confirmDeleteTransaction(
      BuildContext context, TransactionViewData transactionData) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final walletProvider = context.read<WalletProvider>();
    final currency = appCurrencies.firstWhere(
        (c) => c.code == transactionData.originalCurrencyCode,
        orElse: () => Currency(
            code: transactionData.originalCurrencyCode,
            symbol: transactionData.originalCurrencyCode,
            name: '',
            locale: ''));
    final formattedAmount = NumberFormat.currency(
            locale: currency.locale,
            symbol: currency.symbol,
            decimalDigits: 2)
        .format(transactionData.originalAmount);
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Підтвердити видалення'),
          content: Text(
              'Ви впевнені, що хочете видалити транзакцію на суму $formattedAmount (${transactionData.categoryName}) від ${DateFormat('dd.MM.yyyy').format(transactionData.date)}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Скасувати'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Видалити'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
    if (confirmDelete == true && mounted) {
      await walletProvider.transactionRepository.deleteTransaction(transactionData.id);
      if (mounted) {
         messenger.showSnackBar(
         SnackBar(
              content: Text('Транзакцію "${transactionData.categoryName}" видалено')),
      );
        refreshData();
      }
    }
  }

  void showFilterDialog() {
    DateTime? tempStartDate = _filterStartDate;
    DateTime? tempEndDate = _filterEndDate;
    fin_transaction.TransactionType? tempTransactionType = _filterTransactionType;
    int? tempCategoryId = _filterCategoryId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Фільтри', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text('Період:', style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        Expanded(
                            child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(tempStartDate == null
                                ? 'Дата початку'
                                : DateFormat('dd.MM.yyyy').format(tempStartDate!)),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: tempStartDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setModalState(() => tempStartDate = pickedDate);
                              }
                            },
                        ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(tempEndDate == null
                                ? 'Дата кінця'
                                : DateFormat('dd.MM.yyyy').format(tempEndDate!)),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: tempEndDate ?? tempStartDate ?? DateTime.now(),
                                firstDate: tempStartDate ?? DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setModalState(() => tempEndDate = pickedDate);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Тип транзакції:',
                         style: Theme.of(context).textTheme.titleMedium),
                    DropdownButtonFormField<fin_transaction.TransactionType?>(
                       value: tempTransactionType,
                      hint: const Text('Всі типи'),
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: [
                        const DropdownMenuItem<fin_transaction.TransactionType?>(
                          value: null,
                          child: Text('Всі типи'),
                        ),
                        ...fin_transaction.TransactionType.values.map((type) {
                          return DropdownMenuItem<fin_transaction.TransactionType?>(
                            value: type,
                            child: Text(type ==
                                  fin_transaction.TransactionType.income
                                ? 'Дохід'
                                : 'Витрата'),
                          );
                         }),
                       ],
                       onChanged: (value) {
                         setModalState(() => tempTransactionType = value);
                       },
                    ),
                    const SizedBox(height: 16),
                    Text('Категорія:', style: Theme.of(context).textTheme.titleMedium),
                     DropdownButtonFormField<int?>(
                      value: tempCategoryId,
                      hint: const Text('Всі категорії'),
                      isExpanded: true,
                       decoration: const InputDecoration(border: OutlineInputBorder()),
                       items: [
                        const DropdownMenuItem<int?>(
                           value: null,
                           child: Text('Всі категорії'),
                        ),
                        ..._allCategoriesForFilter
                            .map((fin_category.Category category) {
                           return DropdownMenuItem<int?>(
                             value: category.id,
                            child: Text(category.name),
                           );
                        }),
                       ],
                       onChanged: (value) {
                        setModalState(() => tempCategoryId = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                         TextButton(
                          onPressed: () {
                             if (mounted) {
                                setState(() {
                                _filterStartDate = null;
                                _filterEndDate = null;
                                _filterTransactionType = null;
                                _filterCategoryId = null;
                              });
                             }
                            _applyFiltersAndLoadTransactions();
                            Navigator.pop(ctx);
                           },
                          child: const Text('Скинути фільтри'),
                        ),
                      const SizedBox(width: 8),
                         ElevatedButton(
                          onPressed: () {
                             if (mounted) {
                                setState(() {
                                _filterStartDate = tempStartDate;
                                _filterEndDate = tempEndDate;
                                _filterTransactionType = tempTransactionType;
                                _filterCategoryId = tempCategoryId;
                              });
                            }
                            _applyFiltersAndLoadTransactions();
                            Navigator.pop(ctx);
                          },
                           child: const Text('Застосувати'),
                        ),
                      ],
                     ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    bool localAreFiltersActive = areFiltersActive();
    String title = localAreFiltersActive && _currentSearchQuery.isNotEmpty
        ? 'За запитом "$_currentSearchQuery" нічого не знайдено'
        : (localAreFiltersActive
            ? 'Транзакцій не знайдено'
            : 'Транзакцій ще немає');
     String message = localAreFiltersActive
        ? 'Спробуйте змінити параметри фільтрації або пошуковий запит.'
        : 'Додайте свою першу транзакцію, щоб почати відстежувати фінанси.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              localAreFiltersActive
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
               ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!localAreFiltersActive ||
                (_currentSearchQuery.isEmpty &&
                    !(_filterStartDate != null ||
                         _filterEndDate != null ||
                         _filterTransactionType != null ||
                         _filterCategoryId != null)))
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Додати транзакцію'),
                 onPressed: _navigateToAddTransaction,
               ),
            if (localAreFiltersActive &&
                !(_currentSearchQuery.isNotEmpty &&
                   _filterStartDate == null &&
                   _filterEndDate == null &&
                     _filterTransactionType == null &&
                    _filterCategoryId == null))
              TextButton(
                onPressed: () {
                   if (mounted) {
                    setState(() {
                      _filterStartDate = null;
                      _filterEndDate = null;
                      _filterTransactionType = null;
                      _filterCategoryId = null;
                    });
                   }
                   _applyFiltersAndLoadTransactions();
                },
                child: const Text('Очистити фільтри'),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoadingList() {
    final Color baseColor =
        Theme.of(context).brightness == Brightness.light
             ? Colors.grey[300]!
            : Colors.grey[700]!;
    final Color highlightColor =
        Theme.of(context).brightness == Brightness.light
            ? Colors.grey[100]!
            : Colors.grey[500]!;
    return Shimmer.fromColors(
       baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
         itemCount: 7,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Container(
               padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                 color: baseColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                 children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                       shape: BoxShape.circle,
                    ),
                  ),
                   const SizedBox(width: 12),
                  Expanded(
                     child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                        Container(
                             width: MediaQuery.of(context).size.width * 0.4,
                             height: 14,
                            color: Theme.of(context).cardColor),
                         const SizedBox(height: 6),
                         Container(
                              width: MediaQuery.of(context).size.width * 0.25,
                             height: 12,
                             color: Theme.of(context).cardColor),
                       ],
                    ),
                   ),
                  const SizedBox(width: 12),
                  Container(width: 60, height: 16, color: Theme.of(context).cardColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: FutureBuilder<Either<AppFailure, List<TransactionViewData>>>(
           future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _transactionsFuture == null) {
              return _buildShimmerLoadingList();
             }
            
            return snapshot.data!.fold(
              (failure) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        'Помилка завантаження транзакцій: ${failure.userMessage}\nБудь ласка, спробуйте ще раз.',
                        textAlign: TextAlign.center),
                  )),
              (transactions) {
                if (transactions.isEmpty) {
                  return _buildEmptyState(context);
                 }
                final TextTheme textTheme = Theme.of(context).textTheme;
                final ColorScheme colorScheme = Theme.of(context).colorScheme;
                return SafeArea(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: transactions.length,
                     itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final isIncome =
                           transaction.type == fin_transaction.TransactionType.income;
                      final amountColor = isIncome
                          ? colorScheme.tertiary.withAlpha(230)
                          : colorScheme.error;
                      final amountPrefix = isIncome ? '+' : '-';

                      final currency = appCurrencies.firstWhere(
                          (c) => c.code == transaction.originalCurrencyCode,
                          orElse: () => Currency(
                             code: transaction.originalCurrencyCode,
                             symbol: transaction.originalCurrencyCode,
                             name: '',
                              locale: ''));
                      final formattedAmount = NumberFormat.currency(
                              locale: currency.locale,
                              symbol: currency.symbol,
                              decimalDigits: 2)
                          .format(transaction.originalAmount.abs());
                      String subtitleText =
                         DateFormat('dd.MM.yyyy, HH:mm').format(transaction.date);
                      bool hasDescription = transaction.description?.isNotEmpty == true;
                      if (hasDescription) {
                        subtitleText =
                            "${transaction.description!.replaceAll("\n", " ")}\n$subtitleText";
                      }

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: amountColor.withAlpha(26),
                            child: Icon(
                                isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                                  color: amountColor,
                              size: 20,
                            ),
                          ),
                           title: Text(
                            transaction.categoryName,
                            style: textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                              subtitleText,
                            style: textTheme.bodySmall,
                            maxLines: hasDescription ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                           isThreeLine: hasDescription,
                          trailing: Row(
                             mainAxisSize: MainAxisSize.min,
                            children: [
                               Flexible(
                                  child: Text(
                                  '$amountPrefix$formattedAmount',
                                  style: textTheme.titleMedium?.copyWith(
                                   fontWeight: FontWeight.bold, color: amountColor),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _navigateToEditTransaction(transaction);
                                  } else if (value == 'delete') {
                                    _confirmDeleteTransaction(context, transaction);
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('Редагувати'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Видалити'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _navigateToEditTransaction(transaction),
                        ),
                    );
                    },
                  ),
                );
              }
            );
          },
        ),
      ),
    );
  }
}