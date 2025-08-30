import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/debt_loan_repository.dart';
import 'package:sage_wallet_reborn/models/currency_model.dart';
import 'package:sage_wallet_reborn/models/debt_loan_model.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/screens/debts_loans/add_edit_debt_loan_screen.dart';
import 'package:sage_wallet_reborn/utils/app_palette.dart';

class DebtsLoansListScreen extends StatefulWidget {
  const DebtsLoansListScreen({super.key});

  @override
  State<DebtsLoansListScreen> createState() => _DebtsLoansListScreenState();
}

class _DebtsLoansListScreenState extends State<DebtsLoansListScreen>
    with SingleTickerProviderStateMixin {
  final DebtLoanRepository _repository = getIt<DebtLoanRepository>();
  Stream<List<DebtLoan>>? _debtsStream;
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

  void _loadDebts() {
    if (!mounted) return;
    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId != null) {
      setState(() {
        _debtsStream = _repository.watchAllDebtLoans(walletId);
      });
    }
  }

  Future<void> _toggleSettledStatus(DebtLoan item) async {
    if (item.id == null) return;
    await _repository.markAsSettled(item.id!, isSettled: !item.isSettled);
  }

  Future<void> _navigateToAddEditScreen([DebtLoan? item]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditDebtLoanScreen(debtLoanToEdit: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Р‘РѕСЂРіРё С‚Р° РљСЂРµРґРёС‚Рё'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.darkAccent,
          tabs: const [
            Tab(text: 'РЇ РІРёРЅРµРЅ'),
            Tab(text: 'РњРµРЅС– РІРёРЅРЅС–'),
          ],
        ),
      ),
      body: StreamBuilder<List<DebtLoan>>(
        stream: _debtsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'РџРѕРјРёР»РєР° Р·Р°РІР°РЅС‚Р°Р¶РµРЅРЅСЏ: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allItems = snapshot.data!;
          final debts =
              allItems.where((i) => i.type == DebtLoanType.debt).toList();
          final loans =
              allItems.where((i) => i.type == DebtLoanType.loan).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(debts),
              _buildList(loans),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEditScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Р—Р°РїРёСЃС–РІ РїСЂРѕ Р±РѕСЂРіРё С‡Рё РєСЂРµРґРёС‚Рё РЅРµРјР°С”',
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
      return const Center(
        child: Text('РЈ С†С–Р№ РєР°С‚РµРіРѕСЂС–С— РЅРµРјР°С” Р·Р°РїРёСЃС–РІ.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isDebt = item.type == DebtLoanType.debt;
        final color =
            isDebt ? AppPalette.darkNegative : AppPalette.darkPositive;
        final currency = appCurrencies.firstWhere(
          (c) => c.code == item.currencyCode,
          orElse: () => Currency(
            code: item.currencyCode,
            name: '',
            symbol: item.currencyCode,
            locale: 'uk_UA',
          ),
        );

        return Card(
          color: item.isSettled
              ? Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withAlpha(128)
              : null,
          child: ListTile(
            leading: Icon(
              isDebt
                  ? Icons.arrow_circle_up_rounded
                  : Icons.arrow_circle_down_rounded,
              color: item.isSettled ? Colors.grey : color,
              size: 32,
            ),
            title: Text(
              item.personName,
              style: TextStyle(
                decoration: item.isSettled ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumberFormat.currency(
                    symbol: currency.symbol,
                    decimalDigits: 2,
                  ).format(item.originalAmount),
                ),
                if (item.dueDate != null)
                  Text(
                    'Р”Рѕ: ${DateFormat('dd.MM.yyyy').format(item.dueDate!)}',
                    style: TextStyle(
                      color: !item.isSettled &&
                              item.dueDate!.isBefore(DateTime.now())
                          ? Colors.orange.shade800
                          : null,
                    ),
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
