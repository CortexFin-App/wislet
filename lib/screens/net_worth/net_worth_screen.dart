import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/models/asset.dart';
import 'package:wislet/models/liability.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/net_worth/add_edit_asset_screen.dart';
import 'package:wislet/screens/net_worth/add_edit_liability_screen.dart';
import 'package:wislet/services/net_worth_service.dart';

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
      _loadNetWorth();
      context.read<WalletProvider>().addListener(_onWalletChanged);
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
    _loadNetWorth();
  }

  void _loadNetWorth() {
    if (!mounted) return;
    final walletId = context.read<WalletProvider>().currentWallet?.id;
    if (walletId != null) {
      setState(() {
        _netWorthStream = _netWorthService.watchNetWorth(walletId);
      });
    }
  }

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.arrow_upward, color: Colors.green.shade400),
            title: const Text('Додати Актив'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const AddEditAssetScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.arrow_downward, color: Colors.red.shade400),
            title: const Text('Додати Пасив'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditLiabilityScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<NetWorthData>(
        stream: _netWorthStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Не вдалося завантажити дані.'),
            );
          }
          final data = snapshot.data!;

          if (data.assets.isEmpty && data.liabilities.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNetWorthDashboard(data);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            'Відстежуйте свій капітал',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Додайте свої активи (нерухомість, авто) та пасиви (кредити, іпотеки), щоб бачити повну фінансову картину.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthDashboard(NetWorthData data) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          'Чистий капітал',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        Text(
          currencyFormat.format(data.netWorth),
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: _buildPieChart(data),
        ),
        const SizedBox(height: 24),
        _buildDetailSection('Активи', data.assets, currencyFormat, true),
        const SizedBox(height: 16),
        _buildDetailSection('Пасиви', data.liabilities, currencyFormat, false),
      ],
    );
  }

  Widget _buildPieChart(NetWorthData data) {
    final hasAssets = data.totalAssets > 0;
    final hasLiabilities = data.totalLiabilities > 0;

    if (!hasAssets && !hasLiabilities) {
      return Center(
        child: Text(
          'Додайте активи та пасиви',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          if (hasAssets)
            PieChartSectionData(
              value: data.totalAssets,
              title:
                  '${(data.totalAssets / (data.totalAssets + data.totalLiabilities) * 100).toStringAsFixed(0)}%',
              color: Colors.green.shade400,
              radius: 60,
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (hasLiabilities)
            PieChartSectionData(
              value: data.totalLiabilities,
              title:
                  '${(data.totalLiabilities / (data.totalAssets + data.totalLiabilities) * 100).toStringAsFixed(0)}%',
              color: Colors.red.shade400,
              radius: 60,
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildDetailSection<T>(
    String title,
    List<T> items,
    NumberFormat formatter,
    bool isAsset,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Немає записів'),
          )
        else
          ...items.map(
            (item) {
              if (item is Asset) {
                return _buildItemTile(
                  item.name,
                  item.value,
                  formatter,
                  true,
                );
              } else if (item is Liability) {
                return _buildItemTile(
                  item.name,
                  item.amount,
                  formatter,
                  false,
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
      ],
    );
  }

  Widget _buildItemTile(
    String name,
    double value,
    NumberFormat formatter,
    bool isAsset,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          isAsset ? Icons.arrow_upward : Icons.arrow_downward,
          color: isAsset ? Colors.green : Colors.red,
        ),
        title: Text(name),
        trailing: Text(formatter.format(value)),
      ),
    );
  }
}
