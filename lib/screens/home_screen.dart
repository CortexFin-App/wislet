import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../providers/wallet_provider.dart';
import 'transactions/add_edit_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = context.read<WalletProvider>();
      if (walletProvider.currentWallet != null) {
        context
            .read<DashboardProvider>()
            .fetchFinancialHealth(walletProvider.currentWallet!.id!);
      }
      walletProvider.addListener(_onWalletChanged);
    });
  }

  @override
  void dispose() {
    if (mounted) {
      context.read<WalletProvider>().removeListener(_onWalletChanged);
    }
    super.dispose();
  }

  void _onWalletChanged() {
    final walletProvider = context.read<WalletProvider>();
    if (walletProvider.currentWallet != null) {
      context
          .read<DashboardProvider>()
          .fetchFinancialHealth(walletProvider.currentWallet!.id!);
    }
  }

  Future<void> _refresh() async {
    final walletProvider = context.read<WalletProvider>();
    if (walletProvider.currentWallet != null) {
      await context
          .read<DashboardProvider>()
          .fetchFinancialHealth(walletProvider.currentWallet!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 20),
              title: Consumer<DashboardProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const SizedBox.shrink();
                  }
                  final currencyFormat = NumberFormat.currency(
                      locale: 'uk_UA', symbol: '₴', decimalDigits: 0);
                  return Text(
                    currencyFormat.format(provider.health.balance),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Consumer<DashboardProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final currencyFormat = NumberFormat.currency(
                      locale: 'uk_UA', symbol: '₴', decimalDigits: 2);

                  return Column(
                    children: [
                      if (provider.aiAdvice != null && provider.healthScoreProfile != null) ...[
                        AiAdviceCard(
                          advice: provider.aiAdvice!, 
                          score: provider.healthScoreProfile!.score
                        ),
                        const SizedBox(height: 16),
                      ],
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          SolidInfoCard(
                            title: 'Доходи',
                            amount: currencyFormat.format(provider.health.income),
                            color: Colors.green.shade400,
                          ),
                          SolidInfoCard(
                            title: 'Витрати',
                            amount:
                                currencyFormat.format(provider.health.expenses),
                            color: Colors.red.shade400,
                          ),
                        ],
                      )
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuantumFab extends StatelessWidget {
  const QuantumFab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditTransactionScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(128),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary, size: 28),
            const SizedBox(width: 8),
            Text('Транзакція',
                style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class SolidInfoCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const SolidInfoCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minWidth: 160),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class AiAdviceCard extends StatelessWidget {
  final AiAdvice advice;
  final int score;

  const AiAdviceCard({super.key, required this.advice, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(child: Text(advice.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(height: 24),
          Text(advice.positive, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(advice.suggestion, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}