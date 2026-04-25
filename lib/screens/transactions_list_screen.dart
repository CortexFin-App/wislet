import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wislet/models/category.dart' as fin_category;
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/models/transaction_view_data.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/transactions/add_edit_transaction_screen.dart';
import 'package:wislet/utils/transaction_grouping.dart';

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

  bool areFiltersActive() =>
      _filterStartDate != null ||
          _filterEndDate != null ||
          _filterTransactionType != null ||
          _filterCategoryId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refreshData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAllCategoriesForFilter() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) return;

    final result = await walletProvider.categoryRepository
        .getAllCategories(currentWalletId);
    result.fold(
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

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() => _transactionsStream = null);
    await _loadAllCategoriesForFilter();
    _applyFiltersAndLoadTransactions();
  }

  Future<void> _navigateToAddTransaction() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTransactionScreen()),
    );
  }

  Future<void> _navigateToEditTransaction(TransactionViewData tx) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(
          transactionToEdit: tx.toTransactionModel(),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(
      BuildContext context,
      TransactionViewData tx,
      ) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final walletProvider = context.read<WalletProvider>();
    final currency = appCurrencies.firstWhere(
          (c) => c.code == tx.originalCurrencyCode,
      orElse: () => Currency(
        code: tx.originalCurrencyCode,
        symbol: tx.originalCurrencyCode,
        name: '',
        locale: '',
      ),
    );
    final formattedAmount = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 2,
    ).format(tx.originalAmount);

    final confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Підтвердити видалення'),
        content: Text(
          'Видалити транзакцію на суму $formattedAmount '
              '(${tx.categoryName}) від ${DateFormat('dd.MM.yyyy').format(tx.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirmDelete ?? false) {
      await walletProvider.transactionRepository.deleteTransaction(tx.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Транзакцію "${tx.categoryName}" видалено')),
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              children: [
                Text('Фільтри', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Період:', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          tempStartDate == null
                              ? 'Дата початку'
                              : DateFormat('dd.MM.yyyy').format(tempStartDate!),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setModalState(() => tempStartDate = picked);
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
                              ? 'Дата кінця'
                              : DateFormat('dd.MM.yyyy').format(tempEndDate!),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                            tempEndDate ?? tempStartDate ?? DateTime.now(),
                            firstDate: tempStartDate ?? DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setModalState(() => tempEndDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Тип:', style: Theme.of(context).textTheme.titleMedium),
                DropdownButtonFormField<fin_transaction.TransactionType?>(
                  initialValue: tempTransactionType,
                  hint: const Text('Всі типи'),
                  isExpanded: true,
                  decoration:
                  const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(child: Text('Всі типи')),
                    ...fin_transaction.TransactionType.values.map(
                          (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == fin_transaction.TransactionType.income
                              ? 'Дохід'
                              : 'Витрата',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setModalState(() => tempTransactionType = v),
                ),
                const SizedBox(height: 16),
                Text('Категорія:',
                    style: Theme.of(context).textTheme.titleMedium,),
                DropdownButtonFormField<int?>(
                  initialValue: tempCategoryId,
                  hint: const Text('Всі категорії'),
                  isExpanded: true,
                  decoration:
                  const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(child: Text('Всі категорії')),
                    ..._allCategoriesForFilter.map(
                          (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => tempCategoryId = v),
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
                      child: const Text('Скинути'),
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final filtersActive = areFiltersActive();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filtersActive
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              filtersActive
                  ? 'Транзакцій не знайдено'
                  : 'Транзакцій ще немає',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              filtersActive
                  ? 'Спробуйте змінити параметри фільтрації.'
                  : 'Додайте першу транзакцію, щоб почати відстежувати фінанси.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!filtersActive)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Додати транзакцію'),
                onPressed: _navigateToAddTransaction,
              )
            else
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterStartDate = null;
                    _filterEndDate = null;
                    _filterTransactionType = null;
                    _filterCategoryId = null;
                  });
                  _applyFiltersAndLoadTransactions();
                },
                child: const Text('Очистити фільтри'),
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
        itemBuilder: (context, index) => Padding(
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
                    color: Theme.of(context).cardColor,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withAlpha(180),
            ),
            const SizedBox(height: 20),
            Text(
              'Не вдалося завантажити транзакції',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Спробувати знову'),
              onPressed: refreshData,
            ),
          ],
        ),
      ),
    );
  }

  String _formatGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Сьогодні';
    if (date == yesterday) return 'Вчора';
    return DateFormat('d MMMM', 'uk').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCurrency = context.watch<CurrencyProvider>().selectedCurrency;
    final currencyFormat = NumberFormat.currency(
      locale: selectedCurrency.locale,
      symbol: selectedCurrency.symbol,
      decimalDigits: 2,
    );

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
              return _buildErrorState(context, snapshot.error.toString());
            }

            final allTransactions = snapshot.data ?? [];

            // Apply type filter in-memory (chips + dialog share same field)
            final filtered = _filterTransactionType == null
                ? allTransactions
                : allTransactions
                .where((tx) => tx.type == _filterTransactionType)
                .toList();

            // Monthly summary — always from unfiltered full list
            final now = DateTime.now();
            final thisMonth = allTransactions.where(
                  (tx) =>
              tx.date.year == now.year && tx.date.month == now.month,
            );
            final monthIncome = thisMonth
                .where((tx) =>
            tx.type == fin_transaction.TransactionType.income,)
                .fold<double>(0, (sum, tx) => sum + tx.amountInBaseCurrency);
            final monthExpenses = thisMonth
                .where((tx) =>
            tx.type == fin_transaction.TransactionType.expense,)
                .fold<double>(0, (sum, tx) => sum + tx.amountInBaseCurrency);

            // Precompute flat index structure once per build
            final groups = groupTransactionsByDate(filtered);
            // Each group contributes 1 header + N tile entries
            final flatIndex = <({bool isHeader, TransactionGroup group, TransactionViewData? tx})>[];
            for (final group in groups) {
              flatIndex.add((isHeader: true, group: group, tx: null));
              for (final tx in group.items) {
                flatIndex.add((isHeader: false, group: group, tx: tx));
              }
            }

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Monthly summary bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14,),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Доходи',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currencyFormat.format(monthIncome),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        color: colorScheme.tertiary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: colorScheme.outlineVariant,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Витрати',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currencyFormat.format(monthExpenses),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        color: colorScheme.tertiaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Quick filter chips (write to _filterTransactionType)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          _QuickFilterChip(
                            label: 'Усі',
                            selected: _filterTransactionType == null,
                            onTap: () => setState(
                                    () => _filterTransactionType = null,),
                          ),
                          const SizedBox(width: 8),
                          _QuickFilterChip(
                            label: 'Доходи',
                            selected: _filterTransactionType ==
                                fin_transaction.TransactionType.income,
                            onTap: () => setState(() => _filterTransactionType =
                                fin_transaction.TransactionType.income,),
                          ),
                          const SizedBox(width: 8),
                          _QuickFilterChip(
                            label: 'Витрати',
                            selected: _filterTransactionType ==
                                fin_transaction.TransactionType.expense,
                            onTap: () => setState(() => _filterTransactionType =
                                fin_transaction.TransactionType.expense,),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Badge(
                              isLabelVisible: areFiltersActive(),
                              child: const Icon(Icons.tune_rounded),
                            ),
                            tooltip: 'Фільтри',
                            onPressed: showFilterDialog,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Empty state or grouped list
                  if (filtered.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState(context))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final entry = flatIndex[index];
                            if (entry.isHeader) {
                              return Padding(
                                padding:
                                const EdgeInsets.fromLTRB(8, 16, 8, 6),
                                child: Text(
                                  _formatGroupHeader(entry.group.date),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }

                            final tx = entry.tx!;
                            final isIncome = tx.type ==
                                fin_transaction.TransactionType.income;
                            final amountColor = isIncome
                                ? colorScheme.tertiary
                                : colorScheme.tertiaryContainer;
                            final txCurrency = appCurrencies.firstWhere(
                                  (c) => c.code == tx.originalCurrencyCode,
                              orElse: () => Currency(
                                code: tx.originalCurrencyCode,
                                symbol: tx.originalCurrencyCode,
                                name: '',
                                locale: '',
                              ),
                            );
                            final formatted = NumberFormat.currency(
                              locale: txCurrency.locale,
                              symbol: txCurrency.symbol,
                              decimalDigits: 2,
                            ).format(tx.originalAmount.abs());

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
                                  tx.categoryName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,),
                                ),
                                subtitle: tx.description?.isNotEmpty ?? false
                                    ? Text(
                                  tx.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                )
                                    : Text(
                                  DateFormat('HH:mm').format(tx.date),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '−'}$formatted',
                                      style:
                                      theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: amountColor,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _navigateToEditTransaction(tx);
                                        } else if (value == 'delete') {
                                          _confirmDeleteTransaction(
                                              context, tx,);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Редагувати'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Видалити'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _navigateToEditTransaction(tx),
                              ),
                            );
                          },
                          childCount: flatIndex.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight:
            selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
