import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/di/injector.dart';
import '../../models/budget_models.dart';
import '../../providers/wallet_provider.dart';
import '../../data/repositories/budget_repository.dart';
import 'add_edit_budget_screen.dart';
import 'budget_detail_screen.dart';

class BudgetsListScreen extends StatefulWidget {
  const BudgetsListScreen({super.key});

  @override
  BudgetsListScreenState createState() => BudgetsListScreenState();
}

class BudgetsListScreenState extends State<BudgetsListScreen> {
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  Stream<List<Budget>>? _budgetsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
  }

  void refreshData() {
    if (mounted) {
      final walletProvider = context.read<WalletProvider>();
      final currentWalletId = walletProvider.currentWallet?.id;
      if (currentWalletId != null) {
        setState(() {
          _budgetsStream = _budgetRepository.watchAllBudgets(currentWalletId);
        });
      } else {
        setState(() {
          _budgetsStream = Stream.value([]);
        });
      }
    }
  }

  Future<void> _navigateToAddBudget() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditBudgetScreen()),
    );
  }

  Future<void> _navigateToBudgetDetails(Budget budget) async {
    await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => BudgetDetailScreen(budget: budget)));
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Budget>>(
        stream: _budgetsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildShimmerList();
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Помилка завантаження бюджетів: ${snapshot.error}'));
          }

          final budgets = snapshot.data ?? [];

          if (budgets.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                color: !budget.isActive
                    ? theme.colorScheme.surface.withAlpha(128)
                    : theme.colorScheme.surface,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      _getIconForStrategy(budget.strategyType),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    budget.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: !budget.isActive
                          ? theme.colorScheme.onSurface.withAlpha(128)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                        "${DateFormat('dd.MM.yy', 'uk_UA').format(budget.startDate)} - ${DateFormat('dd.MM.yy', 'uk_UA').format(budget.endDate)}\n${budgetStrategyTypeToString(budget.strategyType)}",
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  isThreeLine: true,
                  onTap: () => _navigateToBudgetDetails(budget),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddBudget,
        label: const Text('Новий Бюджет'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.inventory_2_outlined,
                size: 80, color: theme.colorScheme.onSurface.withAlpha(77)),
            const SizedBox(height: 24),
            Text(
              'Жодного бюджету ще не створено',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Створіть свій перший бюджет, щоб почати планувати фінанси за обраною стратегією.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface,
      highlightColor: theme.colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
        itemCount: 5,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            leading: const CircleAvatar(radius: 24, backgroundColor: Colors.white),
            title:
                Container(height: 16, color: Colors.white, width: 150),
            subtitle: Container(
                height: 12,
                color: Colors.white,
                width: 200,
                margin: const EdgeInsets.only(top: 8)),
          ),
        ),
      ),
    );
  }
}