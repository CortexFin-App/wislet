import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/di/injector.dart';
import '../../models/budget_models.dart';
import '../../providers/wallet_provider.dart';
import '../../data/repositories/budget_repository.dart';
import '../../utils/fade_page_route.dart';
import 'add_edit_budget_screen.dart';
import 'budget_detail_screen.dart';

class BudgetsListScreen extends StatefulWidget {
  const BudgetsListScreen({super.key});

  @override
  BudgetsListScreenState createState() => BudgetsListScreenState();
}

class BudgetsListScreenState extends State<BudgetsListScreen> {
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  Future<List<Budget>>? _budgetsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgets();
    });
  }

  Future<void> _loadBudgets() async {
    if (mounted) {
      final walletProvider = context.read<WalletProvider>();
      final currentWalletId = walletProvider.currentWallet?.id;
      if (currentWalletId != null) {
        setState(() {
          _budgetsFuture = _budgetRepository.getAllBudgets(currentWalletId);
        });
      }
    }
  }

  void refreshData() {
    _loadBudgets();
  }

  Future<void> _navigateToAddBudget() async {
    final result = await Navigator.push(
      context,
      FadePageRoute(builder: (context) => const AddEditBudgetScreen()),
    );
    if (result == true && mounted) {
      refreshData();
    }
  }

  Future<void> _navigateToBudgetDetails(Budget budget) async {
    final result = await Navigator.push(context, FadePageRoute(builder: (_) => BudgetDetailScreen(budget: budget)));
    if (result == true && mounted) {
      refreshData();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.inventory_2_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'Жодного бюджету ще не створено',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Створіть свій перший бюджет, щоб почати планувати фінанси за обраною стратегією.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Створити бюджет'),
              onPressed: _navigateToAddBudget,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!,
      highlightColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[500]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            leading: const CircleAvatar(radius: 24),
            title: Container(height: 16, color: Colors.white),
            subtitle: Container(height: 12, margin: const EdgeInsets.only(top: 6), color: Colors.white),
          ),
        ),
      ),
    );
  }

  IconData _getIconForStrategy(BudgetStrategyType type) {
    switch (type) {
      case BudgetStrategyType.categoryBased:
        return Icons.pie_chart_outline_rounded;
      case BudgetStrategyType.envelope:
        return Icons.wallet_outlined;
      case BudgetStrategyType.rule50_30_20:
        return Icons.balance_outlined;
      case BudgetStrategyType.zeroBased:
        return Icons.filter_center_focus_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBudgets,
        child: FutureBuilder<List<Budget>>(
          future: _budgetsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _budgetsFuture == null) {
              return _buildShimmerList();
            } else if (snapshot.hasError) {
              return Center(child: Text('Помилка завантаження бюджетів: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            } else {
              final budgets = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                    color: !budget.isActive ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5) : null,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          _getIconForStrategy(budget.strategyType),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        budget.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: !budget.isActive ? TextDecoration.lineThrough : null,
                            ),
                      ),
                      subtitle: Text(
                        "${DateFormat('dd.MM.yy').format(budget.startDate)} - ${DateFormat('dd.MM.yy').format(budget.endDate)}\n${budgetStrategyTypeToString(budget.strategyType)}",
                        style: Theme.of(context).textTheme.bodySmall),
                      trailing: budget.isActive ? const Icon(Icons.keyboard_arrow_right) : const Chip(label: Text('Архівний'), padding: EdgeInsets.zero),
                      isThreeLine: true,
                      onTap: () => _navigateToBudgetDetails(budget),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}