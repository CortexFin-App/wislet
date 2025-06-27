import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/di/injector.dart';
import '../../models/subscription_model.dart';
import '../../models/currency_model.dart';
import '../../providers/wallet_provider.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/notification_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../providers/currency_provider.dart';
import 'add_edit_subscription_screen.dart';
import '../../utils/fade_page_route.dart';

class SubscriptionsListScreen extends StatefulWidget {
  const SubscriptionsListScreen({super.key});

  @override
  State<SubscriptionsListScreen> createState() => _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState extends State<SubscriptionsListScreen> {
  final SubscriptionRepository _subscriptionRepository = getIt<SubscriptionRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  final NotificationService _notificationService = getIt<NotificationService>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();

  List<Subscription> _subscriptions = [];
  Map<int, String> _categoryNames = {};
  bool _isLoading = true;
  double _totalMonthlyCostUAH = 0.0;
  bool _isLoadingSummary = true;
  ConversionRateInfo? _displayRateInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    if(!mounted) return;
    if(!_isLoading) setState(() => _isLoading = true);
    
    await _loadSubscriptionsAndCategories();
    await _calculateMonthlySummary();
    
    if(mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSubscriptionsAndCategories() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      if(mounted) setState(() => _isLoading = false);
      return;
    }

    final categories = await _categoryRepository.getAllCategories(currentWalletId);
    if (!mounted) return;
    _categoryNames = {for (var cat in categories) if (cat.id != null) cat.id!: cat.name};

    final subscriptions = await _subscriptionRepository.getAllSubscriptions(currentWalletId);
    if (!mounted) return;
    
    setState(() {
      _subscriptions = subscriptions;
    });
  }
  
  Future<void> _calculateMonthlySummary() async {
    if(!mounted) return;
    if(!_isLoadingSummary) setState(() => _isLoadingSummary = true);
    
    final currencyProvider = context.read<CurrencyProvider>();
    final displayCurrencyCode = currencyProvider.selectedCurrency.code;

    if (displayCurrencyCode != 'UAH') {
        try {
            _displayRateInfo = await _exchangeRateService.getConversionRate('UAH', displayCurrencyCode);
        } catch (e) {
            _displayRateInfo = null;
        }
    } else {
        _displayRateInfo = ConversionRateInfo(rate: 1.0, effectiveRateDate: DateTime.now(), isRateStale: false);
    }

    final rates = await _exchangeRateService.getRatesForCurrencies(appCurrencies.map((c) => c.code).toList());
    
    double totalMonthlyCost = 0;
    for (final sub in _subscriptions) {
        if (sub.isActive) {
            double rateToUAH = rates[sub.currencyCode] ?? 1.0;
            double amountInUAH = sub.amount * rateToUAH;
            switch (sub.billingCycle) {
                case BillingCycle.daily:
                    totalMonthlyCost += amountInUAH * 30.44;
                    break;
                case BillingCycle.weekly:
                    totalMonthlyCost += amountInUAH * 4.33;
                    break;
                case BillingCycle.monthly:
                    totalMonthlyCost += amountInUAH;
                    break;
                case BillingCycle.quarterly:
                    totalMonthlyCost += amountInUAH / 3.0;
                    break;
                case BillingCycle.yearly:
                    totalMonthlyCost += amountInUAH / 12.0;
                    break;
                case BillingCycle.custom:
                    break;
            }
        }
    }

    if (mounted) {
        setState(() {
            _totalMonthlyCostUAH = totalMonthlyCost;
            _isLoadingSummary = false;
        });
    }
  }

  Future<void> _deleteSubscription(Subscription sub) async {
    final messenger = ScaffoldMessenger.of(context);
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Видалити підписку?'),
        content: Text('Підписка "${sub.name}" буде видалена. Цю дію неможливо скасувати.'),
        actions: <Widget>[
          TextButton(child: const Text('Скасувати'), onPressed: () => Navigator.of(dialogContext).pop(false)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Видалити'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmDelete == true && mounted) {
      if (sub.id == null) return;
      await _subscriptionRepository.deleteSubscription(sub.id!);
      
      final int reminderId = sub.id! * 20000 + 1;
      await _notificationService.cancelNotification(reminderId);
      
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Підписку "${sub.name}" видалено')));
        _loadAllData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Підписки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Оновити список',
            onPressed: _isLoading ? null : _loadAllData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: Column(
          children: [
            _buildSummaryCard(),
            Expanded(
              child: _isLoading ? _buildShimmerList() : _buildSubscriptionList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Нова підписка'),
        onPressed: () async {
          final result = await Navigator.push(context, FadePageRoute(builder: (_) => const AddEditSubscriptionScreen()));
          if (result == true && mounted) {
            _loadAllData();
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final currencyProvider = context.watch<CurrencyProvider>();
    final amountInDisplayCurrency = _totalMonthlyCostUAH * (_displayRateInfo?.rate ?? 1.0);
    final formattedAmount = NumberFormat.currency(
        locale: currencyProvider.selectedCurrency.locale,
        symbol: currencyProvider.selectedCurrency.symbol,
        decimalDigits: 2)
    .format(amountInDisplayCurrency);

    return Card(
        margin: const EdgeInsets.all(12.0),
        elevation: 2,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text("Витрати на підписки / міс.:", style: Theme.of(context).textTheme.titleMedium),
                    _isLoadingSummary 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(formattedAmount, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ],
            ),
        ),
    );
  }

  Widget _buildSubscriptionList() {
    if (_subscriptions.isEmpty) {
        return Center(
            child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                    Icon(Icons.subscriptions_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(height: 24),
                    Text('Список підписок порожній', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text('Додайте свої регулярні платежі, щоб відстежувати їх та отримувати нагадування.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
            ),
            ),
        );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 80.0),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final sub = _subscriptions[index];
        final currency = appCurrencies.firstWhere((c) => c.code == sub.currencyCode, orElse: () => Currency(code: sub.currencyCode, symbol: '', name: '', locale: 'uk_UA'));
        final formattedAmount = NumberFormat.currency(locale: currency.locale, symbol: currency.symbol, decimalDigits: 2).format(sub.amount);
        final categoryName = sub.categoryId != null ? _categoryNames[sub.categoryId] : null;

        return Card(
          color: !sub.isActive ? Theme.of(context).colorScheme.surfaceContainer : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: sub.isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              child: Icon(Icons.star_purple500_sharp, color: sub.isActive ? Theme.of(context).colorScheme.primary : Colors.grey),
            ),
            title: Text(sub.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: !sub.isActive ? TextDecoration.lineThrough : null,
            )),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Наступний платіж: ${DateFormat('dd.MM.yyyy').format(sub.nextPaymentDate)}"),
                if (categoryName != null) Text("Категорія: $categoryName", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formattedAmount, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(billingCycleToString(sub.billingCycle, context), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            onTap: () async {
              final result = await Navigator.push(context, FadePageRoute(builder: (_) => AddEditSubscriptionScreen(subscriptionToEdit: sub)));
              if (result == true && mounted) {
                _loadAllData();
              }
            },
            onLongPress: () => _deleteSubscription(sub),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!,
        highlightColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[500]!,
        child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 80.0),
            itemCount: 5,
            itemBuilder: (_, __) => Card(
                  child: ListTile(
                      leading: const CircleAvatar(),
                      title: Container(height: 16, width: 150, color: Colors.white),
                      subtitle: Container(height: 12, width: 100, color: Colors.white),
                      trailing: Container(height: 16, width: 60, color: Colors.white),
                  ),
            ),
        ),
    );
  }
}