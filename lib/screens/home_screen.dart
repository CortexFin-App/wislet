import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/providers/dashboard_provider.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/widgets/home/health_score_widget.dart';
import 'package:sage_wallet_reborn/widgets/home/main_goal_card_widget.dart';
import 'package:sage_wallet_reborn/widgets/home/summary_card_widget.dart';

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
    final provider = context.watch<DashboardProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'uk_UA', symbol: 'в‚ґ', decimalDigits: 0);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                const SizedBox(height: 16),
                Text(
                  'Р—Р°РіР°Р»СЊРЅРёР№ Р±Р°Р»Р°РЅСЃ',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  currencyFormat.format(provider.health.balance),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                if (provider.healthScoreProfile != null &&
                    provider.aiAdvice != null)
                  HealthScoreWidget(
                    profile: provider.healthScoreProfile!,
                    advice: provider.aiAdvice!,
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Р”РѕС…РѕРґРё',
                        amount: provider.health.income,
                        color: Colors.green.shade400,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Р’РёС‚СЂР°С‚Рё',
                        amount: provider.health.expenses,
                        color: Colors.red.shade400,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
                if (provider.mainGoal != null) ...[
                  const SizedBox(height: 16),
                  MainGoalCard(goal: provider.mainGoal!),
                ],
              ],
            ),
    );
  }
}
