import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/models/category.dart' as fin_category;
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/models/transaction_view_data.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/transactions/add_edit_transaction_screen.dart';
import 'package:shimmer/shimmer.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  TransactionsListScreenState createState() => TransactionsListScreenState();
}

class TransactionsListScreenState extends State<TransactionsListScreen> {
  Stream<List<TransactionViewData>>? _transactionsStream;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  fin_transaction.TransactionType? _filterTransactionType;
  int? _filterCategoryId;
  List<fin_category.Category> _allCategoriesForFilter = [];
  bool isScreenSearching = false;
  final TextEditingController _searchController = TextEditingController();

  String get _currentSearchQuery => _searchController.text;

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
    _searchController.addListener(() {
      performSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCategoriesForFilter() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) return;

    final categoriesEither = await walletProvider.categoryRepository
        .getAllCategories(currentWalletId);
    categoriesEither.fold(
      (l) => _allCategoriesForFilter = [],
      (r) => _allCategoriesForFilter = r,
    );

    if (mounted) setState(() {});
  }

  void _applyFiltersAndLoadTransactions() {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();

    if (walletProvider.currentWallet?.id != null) {
      setState(() {
        _transactionsStream =
            walletProvider.transactionRepository.watchTransactionsWithDetails(
          walletId: walletProvider.currentWallet!.id!,
        );
      });
    }
  }

  void performSearchQuery(String query) {
    if (!mounted) return;
    if (_currentSearchQuery != query.trim()) {
      _applyFiltersAndLoadTransactions();
    }
  }

  void toggleSearchMode({required bool isSearching}) {
    if (!mounted) return;
    setState(() {
      isScreenSearching = isSearching;
      if (!isScreenSearching && _currentSearchQuery.isNotEmpty) {
        _searchController.clear();
      }
    });
    _applyFiltersAndLoadTransactions();
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() {
      _transactionsStream = null;
    });
    await _loadAllCategoriesForFilter();
    _applyFiltersAndLoadTransactions();
  }

  Future<void> _navigateToAddTransaction() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditTransactionScreen(),
      ),
    );
  }

  Future<void> _navigateToEditTransaction(
    TransactionViewData transactionData,
  ) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(
          transactionToEdit: transactionData.toTransactionModel(),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    TransactionViewData transactionData,
  ) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final walletProvider = context.read<WalletProvider>();
    final currency = appCurrencies.firstWhere(
      (c) => c.code == transactionData.originalCurrencyCode,
      orElse: () => Currency(
        code: transactionData.originalCurrencyCode,
        symbol: transactionData.originalCurrencyCode,
        name: '',
        locale: '',
      ),
    );
    final formattedAmount = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 2,
    ).format(transactionData.originalAmount);
    final confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('РџС–РґС‚РІРµСЂРґРёС‚Рё РІРёРґР°Р»РµРЅРЅСЏ'),
          content: Text(
            'Р’Рё РІРїРµРІРЅРµРЅС–, С‰Рѕ С…РѕС‡РµС‚Рµ РІРёРґР°Р»РёС‚Рё С‚СЂР°РЅР·Р°РєС†С–СЋ РЅР° СЃСѓРјСѓ $formattedAmount (${transactionData.categoryName}) РІС–Рґ ${DateFormat('dd.MM.yyyy').format(transactionData.date)}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('РЎРєР°СЃСѓРІР°С‚Рё'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Р’РёРґР°Р»РёС‚Рё'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
    if (confirmDelete ?? false) {
      await walletProvider.transactionRepository
          .deleteTransaction(transactionData.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'РўСЂР°РЅР·Р°РєС†С–СЋ "${transactionData.categoryName}" РІРёРґР°Р»РµРЅРѕ',
            ),
          ),
        );
      }
    }
  }

  void showFilterDialog() {
    var tempStartDate = _filterStartDate;
    var tempEndDate = _filterEndDate;
    var tempTransactionType = _filterTransactionType;
    var tempCategoryId = _filterCategoryId;
    showModalBottomSheet<void>(
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
                    Text(
                      'Р¤С–Р»СЊС‚СЂРё',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'РџРµСЂС–РѕРґ:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              tempStartDate == null
                                  ? 'Р”Р°С‚Р° РїРѕС‡Р°С‚РєСѓ'
                                  : DateFormat('dd.MM.yyyy')
                                      .format(tempStartDate!),
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: tempStartDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setModalState(
                                  () => tempStartDate = pickedDate,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              tempEndDate == null
                                  ? 'Р”Р°С‚Р° РєС–РЅС†СЏ'
                                  : DateFormat('dd.MM.yyyy')
                                      .format(tempEndDate!),
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: tempEndDate ??
                                    tempStartDate ??
                                    DateTime.now(),
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
                    Text(
                      'РўРёРї С‚СЂР°РЅР·Р°РєС†С–С—:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    DropdownButtonFormField<fin_transaction.TransactionType?>(
                      value: tempTransactionType,
                      hint: const Text('Р’СЃС– С‚РёРїРё'),
                      isExpanded: true,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<
                            fin_transaction.TransactionType?>(
                          child: Text('Р’СЃС– С‚РёРїРё'),
                        ),
                        ...fin_transaction.TransactionType.values.map((type) {
                          return DropdownMenuItem<
                              fin_transaction.TransactionType?>(
                            value: type,
                            child: Text(
                              type == fin_transaction.TransactionType.income
                                  ? 'Р”РѕС…С–Рґ'
                                  : 'Р’РёС‚СЂР°С‚Р°',
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setModalState(() => tempTransactionType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'РљР°С‚РµРіРѕСЂС–СЏ:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    DropdownButtonFormField<int?>(
                      value: tempCategoryId,
                      hint: const Text('Р’СЃС– РєР°С‚РµРіРѕСЂС–С—'),
                      isExpanded: true,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<int?>(
                          child: Text('Р’СЃС– РєР°С‚РµРіРѕСЂС–С—'),
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
                          child: const Text('РЎРєРёРЅСѓС‚Рё С„С–Р»СЊС‚СЂРё'),
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
                          child: const Text('Р—Р°СЃС‚РѕСЃСѓРІР°С‚Рё'),
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
    final localAreFiltersActive = areFiltersActive();
    final title = localAreFiltersActive && _currentSearchQuery.isNotEmpty
        ? 'Р—Р° Р·Р°РїРёС‚РѕРј "$_currentSearchQuery" РЅС–С‡РѕРіРѕ РЅРµ Р·РЅР°Р№РґРµРЅРѕ'
        : (localAreFiltersActive
            ? 'РўСЂР°РЅР·Р°РєС†С–Р№ РЅРµ Р·РЅР°Р№РґРµРЅРѕ'
            : 'РўСЂР°РЅР·Р°РєС†С–Р№ С‰Рµ РЅРµРјР°С”');
    final message = localAreFiltersActive
        ? 'РЎРїСЂРѕР±СѓР№С‚Рµ Р·РјС–РЅРёС‚Рё РїР°СЂР°РјРµС‚СЂРё С„С–Р»СЊС‚СЂР°С†С–С— Р°Р±Рѕ РїРѕС€СѓРєРѕРІРёР№ Р·Р°РїРёС‚.'
        : 'Р”РѕРґР°Р№С‚Рµ СЃРІРѕСЋ РїРµСЂС€Сѓ С‚СЂР°РЅР·Р°РєС†С–СЋ, С‰РѕР± РїРѕС‡Р°С‚Рё РІС–РґСЃС‚РµР¶СѓРІР°С‚Рё С„С–РЅР°РЅСЃРё.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              localAreFiltersActive
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 80,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
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
                label: const Text('Р”РѕРґР°С‚Рё С‚СЂР°РЅР·Р°РєС†С–СЋ'),
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
                child: const Text('РћС‡РёСЃС‚РёС‚Рё С„С–Р»СЊС‚СЂРё'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoadingList() {
    final baseColor = Theme.of(context).brightness == Brightness.light
        ? Colors.grey[300]!
        : Colors.grey[700]!;
    final highlightColor = Theme.of(context).brightness == Brightness.light
        ? Colors.grey[100]!
        : Colors.grey[500]!;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
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
                          color: Theme.of(context).cardColor,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.25,
                          height: 12,
                          color: Theme.of(context).cardColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    height: 16,
                    color: Theme.of(context).cardColor,
                  ),
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
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: StreamBuilder<List<TransactionViewData>>(
          stream: _transactionsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _transactionsStream == null) {
              return _buildShimmerLoadingList();
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'РџРѕРјРёР»РєР° Р·Р°РІР°РЅС‚Р°Р¶РµРЅРЅСЏ С‚СЂР°РЅР·Р°РєС†С–Р№: ${snapshot.error}\nР‘СѓРґСЊ Р»Р°СЃРєР°, СЃРїСЂРѕР±СѓР№С‚Рµ С‰Рµ СЂР°Р·.',
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(context);
            }
            final transactions = snapshot.data!;
            final textTheme = Theme.of(context).textTheme;
            final colorScheme = Theme.of(context).colorScheme;
            return SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final isIncome = transaction.type ==
                      fin_transaction.TransactionType.income;
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
                      locale: '',
                    ),
                  );
                  final formattedAmount = NumberFormat.currency(
                    locale: currency.locale,
                    symbol: currency.symbol,
                    decimalDigits: 2,
                  ).format(transaction.originalAmount.abs());
                  var subtitleText =
                      DateFormat('dd.MM.yyyy, HH:mm').format(transaction.date);
                  final hasDescription =
                      transaction.description?.isNotEmpty ?? false;
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
                                fontWeight: FontWeight.bold,
                                color: amountColor,
                              ),
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
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Р РµРґР°РіСѓРІР°С‚Рё'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Р’РёРґР°Р»РёС‚Рё'),
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
          },
        ),
      ),
    );
  }
}
