import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../models/budget_models.dart';
import '../../models/transaction.dart' as fin_transaction;
import '../../providers/currency_provider.dart';
import '../../providers/wallet_provider.dart';
import 'add_edit_envelope_screen.dart';
import 'add_edit_budget_screen.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;
  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final TransactionRepository _transactionRepository = getIt<TransactionRepository>();
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
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

    final envelopesEither = await _budgetRepository.getEnvelopesForBudget(widget.budget.id!);

    return envelopesEither.fold(
      (failure) => throw failure,
      (envelopes) async {
        double totalPlannedInBase = 0;
        double totalActualInBase = 0;
        Map<int, double> envelopeActuals = {};

        for (var envelope in envelopes) {
          totalPlannedInBase += envelope.plannedAmountInBaseCurrency;
          final actualSpentEither = await _transactionRepository.getTotalAmount(
            walletId: walletId,
            startDate: widget.budget.startDate,
            endDate: widget.budget.endDate,
            transactionType: fin_transaction.TransactionType.expense,
            categoryId: envelope.categoryId,
          );

          actualSpentEither.fold(
            (l) => totalActualInBase += 0,
            (actualSpent) {
              totalActualInBase += actualSpent;
              envelopeActuals[envelope.id!] = actualSpent;
            }
          );
        }

        return {
          'envelopes': envelopes,
          'totalPlannedInBase': totalPlannedInBase,
          'totalActualInBase': totalActualInBase,
          'envelopeActuals': envelopeActuals,
        };
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget.name, style: const TextStyle(overflow: TextOverflow.ellipsis)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final result = await navigator.push<bool>(MaterialPageRoute(builder: (_) => AddEditBudgetScreen(budgetToEdit: widget.budget)));
              if (result == true) {
                navigator.pop(true);
              }
            },
          )
        ],
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
          return _buildOverviewTab(context, data);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditEnvelopeScreen(budgetId: widget.budget.id!)),
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
    final theme = Theme.of(context);
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
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

        Color progressColor = Colors.green.shade400;
        if (progress > 0.8) progressColor = Colors.orange.shade400;
        if (progress >= 1.0) progressColor = theme.colorScheme.error;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  envelope.name,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Заплановано:'),
                    Text(currencyFormatter.format(plannedAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Витрачено:'),
                    Text(currencyFormatter.format(actualSpent), style: TextStyle(color: progressColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Залишок:'),
                    Text(
                      currencyFormatter.format(difference),
                      style: theme.textTheme.titleMedium?.copyWith(
                            color: difference >= 0 ? Colors.green.shade600 : theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: progressColor.withAlpha(50),
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
}