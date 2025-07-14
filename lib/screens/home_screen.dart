import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
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
        context.read<DashboardProvider>().fetchFinancialHealth(walletProvider.currentWallet!.id!);
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
      context.read<DashboardProvider>().fetchFinancialHealth(walletProvider.currentWallet!.id!);
    }
  }

  Future<void> _refresh() async {
    final walletProvider = context.read<WalletProvider>();
    if (walletProvider.currentWallet != null) {
      await context.read<DashboardProvider>().fetchFinancialHealth(walletProvider.currentWallet!.id!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: const QuantumScaffold(),
      ),
      floatingActionButton: const QuantumFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
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
            Text('Транзакція', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class QuantumScaffold extends StatelessWidget {
  const QuantumScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: QuantumSphere(),
          )
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<DashboardProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final currencyFormat = NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 2);
                return Column(
                  children: [
                    GlassmorphicCard(
                      title: 'Поточний баланс',
                      amount: currencyFormat.format(provider.health.balance),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GlassmorphicCard(
                            title: 'Доходи',
                            amount: currencyFormat.format(provider.health.income),
                            color: Colors.green.shade400,
                            isSmall: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GlassmorphicCard(
                            title: 'Витрати',
                            amount: currencyFormat.format(provider.health.expenses),
                            color: Colors.red.shade400,
                            isSmall: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class GlassmorphicCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final bool isSmall;

  const GlassmorphicCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withAlpha(13),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.onSurface.withAlpha(26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: isSmall ? 14 : 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontSize: isSmall ? 24 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuantumSphere extends StatefulWidget {
  const QuantumSphere({super.key});

  @override
  State<QuantumSphere> createState() => _QuantumSphereState();
}

class _QuantumSphereState extends State<QuantumSphere> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                theme.colorScheme.primary.withAlpha(51),
                theme.colorScheme.primaryContainer.withAlpha(38),
                theme.scaffoldBackgroundColor,
              ],
              transform: GradientRotation(_controller.value * 2.0 * 3.14159),
            ),
          ),
          child: Center(
            child: Consumer<DashboardProvider>(
              builder: (context, provider, child) {
                final balance = provider.health.balance;
                return Text(
                  NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 0).format(balance),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    shadows: [
                      Shadow(blurRadius: 20, color: theme.colorScheme.primary),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}