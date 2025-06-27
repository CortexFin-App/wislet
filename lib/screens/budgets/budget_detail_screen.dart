import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../models/budget_models.dart';
import '../../models/transaction.dart' as FinTransactionModel;
import '../../models/transaction_view_data.dart';
import '../../providers/currency_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/fade_page_route.dart';
import 'add_edit_envelope_screen.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;
  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> with SingleTickerProviderStateMixin {
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final TransactionRepository _transactionRepository = getIt<TransactionRepository>();
  late TabController _tabController;
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetails();
  }

  void _loadDetails() {
    if (mounted) {
      setState(() {
        _detailsFuture = _fetchDetails();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchDetails() async {
    final walletId = Provider.of<WalletProvider>(context, listen: false).currentWallet!.id!;
    final envelopes = await _budgetRepository.getEnvelopesForBudget(widget.budget.id!);
    double totalPlannedInBase = 0;
    double totalActualInBase = 0;
    Map<int, double> envelopeActuals = {};

    for (var envelope in envelopes) {
      totalPlannedInBase += envelope.plannedAmountInBaseCurrency;
      double actualSpent = await _transactionRepository.getTotalAmount(
        walletId: walletId,
        startDate: widget.budget.startDate,
        endDate: widget.budget.endDate,
        transactionType: FinTransactionModel.TransactionType.expense,
        categoryId: envelope.categoryId,
      );
      totalActualInBase += actualSpent;
      envelopeActuals[envelope.id!] = actualSpent;
    }

    return {
      'envelopes': envelopes,
      'totalPlannedInBase': totalPlannedInBase,
      'totalActualInBase': totalActualInBase,
      'envelopeActuals': envelopeActuals,
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget.name, style: const TextStyle(overflow: TextOverflow.ellipsis)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Огляд'),
            Tab(text: 'Транзакції'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Помилка: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Немає даних.'));
          }
          final data = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, data),
              _buildTransactionsTab(context),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            FadePageRoute(builder: (_) => AddEditEnvelopeScreen(budgetId: widget.budget.id!)),
          );
          if (result == true) {
            _loadDetails();
          }
        },
        label: const Text('Новий конверт'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, Map<String, dynamic> data) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final NumberFormat currencyFormatter = currencyProvider.currencyFormatter;
    final List<BudgetEnvelope> envelopes = data['envelopes'];
    final Map<int, double> envelopeActuals = data['envelopeActuals'];

    if (envelopes.isEmpty) {
      return const Center(
        child: Text('Додайте конверти для цього бюджету.'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: envelopes.length,
      itemBuilder: (context, index) {
        final envelope = envelopes[index];
        final double actualSpent = envelopeActuals[envelope.id!] ?? 0.0;
        final double plannedAmount = envelope.plannedAmountInBaseCurrency;
        final double difference = plannedAmount - actualSpent;
        double progress = 0.0;
        if(plannedAmount > 0) {
          progress = (actualSpent / plannedAmount).clamp(0.0, 1.0);
        }

        Color progressColor = Colors.green.shade600;
        if (progress > 0.8) progressColor = Colors.orange.shade600;
        if (progress >= 1.0) progressColor = Colors.red.shade700;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  envelope.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Заплановано:'),
                    Text(currencyFormatter.format(plannedAmount), style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Витрачено:'),
                    Text(currencyFormatter.format(actualSpent), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: progressColor)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Залишок:'),
                    Text(
                      currencyFormatter.format(difference),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: difference >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: progressColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(BuildContext context) {
    return FutureBuilder<List<TransactionViewData>>(
      future: _transactionRepository.getTransactionsWithDetails(
        walletId: Provider.of<WalletProvider>(context, listen: false).currentWallet!.id!,
        startDate: widget.budget.startDate,
        endDate: widget.budget.endDate,
        filterTransactionType: FinTransactionModel.TransactionType.expense,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Помилка завантаження транзакцій: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Немає транзакцій за цей період.'));
        }
        final transactions = snapshot.data!;
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return ListTile(
              title: Text(tx.categoryName),
              subtitle: Text(tx.description ?? ''),
              trailing: Text(
                '- ${NumberFormat.currency(symbol: tx.originalCurrencyCode).format(tx.originalAmount)}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          },
        );
      },
    );
  }
}