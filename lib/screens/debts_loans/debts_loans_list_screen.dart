import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../core/error/failures.dart';
import '../../models/debt_loan_model.dart';
import '../../models/currency_model.dart';
import '../../providers/wallet_provider.dart';
import '../../data/repositories/debt_loan_repository.dart';
import 'add_edit_debt_loan_screen.dart';

class DebtsLoansListScreen extends StatefulWidget {
  const DebtsLoansListScreen({super.key});

  @override
  State<DebtsLoansListScreen> createState() => _DebtsLoansListScreenState();
}

class _DebtsLoansListScreenState extends State<DebtsLoansListScreen> with SingleTickerProviderStateMixin {
  final DebtLoanRepository _repository = getIt<DebtLoanRepository>();
  Future<Either<AppFailure, List<DebtLoan>>>? _debtsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDebts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    if (!mounted) return;
    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId != null) {
      setState(() {
        _debtsFuture = _repository.getAllDebtLoans(walletId);
      });
    }
  }

  Future<void> _toggleSettledStatus(DebtLoan item) async {
    if (item.id == null) return;
    await _repository.markAsSettled(item.id!, !item.isSettled);
    _loadDebts();
  }

  void _navigateToAddEditScreen([DebtLoan? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditDebtLoanScreen(debtLoanToEdit: item)),
    );
    if (result == true && mounted) {
      _loadDebts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Борги та Кредити'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Я винен'),
            Tab(text: 'Мені винні'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDebts,
        child: FutureBuilder<Either<AppFailure, List<DebtLoan>>>(
          future: _debtsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return _buildEmptyState();
            }

            return snapshot.data!.fold(
              (failure) => Center(child: Text('Помилка завантаження: ${failure.userMessage}')),
              (allItems) {
                if (allItems.isEmpty) {
                  return _buildEmptyState();
                }
                final debts = allItems.where((i) => i.type == DebtLoanType.debt).toList();
                final loans = allItems.where((i) => i.type == DebtLoanType.loan).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(debts),
                    _buildList(loans),
                  ],
                );
              }
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Записів про борги чи кредити немає',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<DebtLoan> items) {
    if (items.isEmpty) {
      return const Center(child: Text('У цій категорії немає записів.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isDebt = item.type == DebtLoanType.debt;
        final color = isDebt ? Colors.red.shade700 : Colors.green.shade700;
        final currency = appCurrencies.firstWhere((c) => c.code == item.currencyCode, orElse: () => Currency(code: item.currencyCode, name: '', symbol: item.currencyCode, locale: 'uk_UA'));
        return Card(
          color: item.isSettled ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128) : null,
          child: ListTile(
            leading: Icon(
              isDebt ? Icons.arrow_circle_up_rounded : Icons.arrow_circle_down_rounded,
              color: item.isSettled ? Colors.grey : color,
            ),
            title: Text(item.personName, style: TextStyle(decoration: item.isSettled ? TextDecoration.lineThrough : null)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(NumberFormat.currency(symbol: currency.symbol, decimalDigits: 2).format(item.originalAmount)),
                if (item.dueDate != null)
                  Text(
                    'До: ${DateFormat('dd.MM.yyyy').format(item.dueDate!)}',
                    style: TextStyle(color: !item.isSettled && item.dueDate!.isBefore(DateTime.now()) ? Colors.orange.shade800 : null),
                  ),
              ],
            ),
            trailing: Checkbox(
              value: item.isSettled,
              onChanged: (val) => _toggleSettledStatus(item),
              activeColor: color,
            ),
            onTap: () => _navigateToAddEditScreen(item),
          ),
        );
      },
    );
  }
}