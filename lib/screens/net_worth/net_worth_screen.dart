import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../providers/wallet_provider.dart';
import '../../services/net_worth_service.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  final NetWorthService _netWorthService = getIt<NetWorthService>();
  Stream<NetWorthData>? _netWorthStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletId = context.read<WalletProvider>().currentWallet?.id;
      if (walletId != null) {
        setState(() {
          _netWorthStream = _netWorthService.watchNetWorth(walletId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<NetWorthData>(
        stream: _netWorthStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Немає даних для розрахунку."));
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Чистий капітал", style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              Text(
                currencyFormat.format(data.netWorth),
                style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard(context, "Активи", data.totalAssets, Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard(context, "Пасиви", data.totalLiabilities, Colors.red)),
                ],
              ),
              const SizedBox(height: 24),
              Text("Активи", style: theme.textTheme.titleLarge),
              ...data.assets.map((asset) => ListTile(title: Text(asset.name), trailing: Text(currencyFormat.format(asset.value)))),
              const SizedBox(height: 24),
              Text("Пасиви", style: theme.textTheme.titleLarge),
              ...data.liabilities.map((liability) => ListTile(title: Text(liability.name), trailing: Text(currencyFormat.format(liability.amount)))),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, double value, Color color) {
    final currencyFormat = NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(value),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}