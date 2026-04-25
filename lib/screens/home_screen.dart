import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/models/transaction_view_data.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/dashboard_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/services/sync_service.dart';
import 'package:wislet/widgets/home/summary_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  WalletProvider? _walletProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _walletProvider = context.read<WalletProvider>();
      if (_walletProvider!.currentWallet != null) {
        context.read<DashboardProvider>()
            .fetchFinancialHealth(_walletProvider!.currentWallet!.id!);
      }
      _walletProvider!.addListener(_onWalletChanged);
    });
  }

  @override
  void dispose() {
    _walletProvider?.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    final wp = context.read<WalletProvider>();
    if (wp.currentWallet != null) {
      context.read<DashboardProvider>().fetchFinancialHealth(wp.currentWallet!.id!);
    }
  }

  Future<void> _refresh() async {
    final wp = context.read<WalletProvider>();
    if (wp.currentWallet != null) {
      await context.read<DashboardProvider>().fetchFinancialHealth(wp.currentWallet!.id!);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброго ранку';
    if (h < 17) return 'Добрий день';
    if (h < 24) return 'Добрий вечір';
    return 'Доброї ночі';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final currency = context.watch<CurrencyProvider>().selectedCurrency;
    final sync = context.watch<SyncService>();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 0,
    );

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          walletProvider.currentWallet?.name ?? 'Wislet',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          _SyncStatusIcon(sync: sync),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            const SizedBox(height: 24),

            // Привітання
            Text(
              '${_greeting()}!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 28),

            // Баланс
            Text(
              'Загальний баланс',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(provider.health.balance),
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 24),

            // Доходи / Витрати
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Доходи',
                    amount: provider.health.income,
                    color: theme.colorScheme.tertiary,
                    icon: Icons.arrow_downward_rounded,
                    currencyFormat: currencyFormat,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(
                    title: 'Витрати',
                    amount: provider.health.expenses,
                    color: theme.colorScheme.tertiaryContainer,
                    icon: Icons.arrow_upward_rounded,
                    currencyFormat: currencyFormat,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Останні операції
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Останні операції',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/wallet'),
                  child: const Text('Усі →'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Список недавніх транзакцій
            if (provider.recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Транзакцій ще немає',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Натисніть + щоб додати першу',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...provider.recentTransactions.map(
                    (tx) => _RecentTransactionTile(
                  tx: tx,
                  currencyFormat: currencyFormat,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Іконка статусу синхронізації

class _SyncStatusIcon extends StatelessWidget {
  const _SyncStatusIcon({required this.sync});

  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (sync.isSyncing) {
      return Tooltip(
        message: 'Синхронізація…',
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (sync.lastError != null) {
      return Tooltip(
        message: 'Помилка синхронізації',
        child: Icon(
          Icons.sync_problem_outlined,
          color: theme.colorScheme.error,
        ),
      );
    }

    if (sync.lastSyncedAt != null) {
      final time = _formatSyncTime(sync.lastSyncedAt!);
      return Tooltip(
        message: 'Синхронізовано $time',
        child: Icon(
          Icons.cloud_done_outlined,
          color: theme.colorScheme.primary,
        ),
      );
    }

    // Сеанс ще не синхронізовано (гість або щойно запущено)
    return Tooltip(
      message: 'Офлайн',
      child: Icon(
        Icons.cloud_off_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _formatSyncTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'щойно';
    if (diff.inMinutes < 60) return '${diff.inMinutes} хв тому';
    return DateFormat('HH:mm').format(dt);
  }
}

// Блок останніх транзакцій
class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({
    required this.tx,
    required this.currencyFormat,
  });

  final TransactionViewData tx;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = tx.type == fin_transaction.TransactionType.income;
    final amountColor = isIncome
        ? theme.colorScheme.tertiary
        : theme.colorScheme.tertiaryContainer;
    final amountPrefix = isIncome ? '+' : '−';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          isIncome
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: amountColor,
          size: 20,
        ),
      ),
      title: Text(
        (tx.description?.isNotEmpty ?? false) ? tx.description! : tx.categoryName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        tx.categoryName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$amountPrefix${currencyFormat.format(tx.amountInBaseCurrency)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            DateFormat('d MMM', 'uk').format(tx.date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: () => context.push(
        '/add',
        extra: tx.toTransactionModel(),
      ),
    );
  }
}
