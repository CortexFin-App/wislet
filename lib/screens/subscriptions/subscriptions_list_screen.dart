import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/data/repositories/subscription_repository.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/subscription_model.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/subscriptions/add_edit_subscription_screen.dart';
import 'package:wislet/services/exchange_rate_service.dart';
import 'package:wislet/services/notification_service.dart';
import 'package:wislet/utils/app_palette.dart';
import 'package:wislet/widgets/scaffold/patterned_scaffold.dart';
import 'package:shimmer/shimmer.dart';

class SubscriptionsListScreen extends StatefulWidget {
  const SubscriptionsListScreen({super.key});

  @override
  State<SubscriptionsListScreen> createState() =>
      _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState extends State<SubscriptionsListScreen> {
  final SubscriptionRepository _subscriptionRepository =
      getIt<SubscriptionRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  final NotificationService _notificationService = getIt<NotificationService>();
  final ExchangeRateService _exchangeRateService = getIt<ExchangeRateService>();

  Stream<List<Subscription>>? _subscriptionsStream;
  Map<int, String> _categoryNames = {};
  bool _isLoading = true;
  double _totalMonthlyCostUAH = 0;
  bool _isLoadingSummary = true;
  ConversionRateInfo? _displayRateInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAllData());
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    if (!_isLoading) setState(() => _isLoading = true);

    _loadSubscriptionsAndCategories();
    await _calculateMonthlySummary();

    if (mounted) setState(() => _isLoading = false);
  }

  void _loadSubscriptionsAndCategories() {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _categoryRepository
        .getAllCategories(currentWalletId)
        .then((categoriesEither) {
      if (!mounted) return;
      categoriesEither.fold(
        (l) => _categoryNames = {},
        (categories) => _categoryNames = {
          for (final cat in categories)
            if (cat.id != null) cat.id!: cat.name,
        },
      );
    });

    setState(() {
      _subscriptionsStream =
          _subscriptionRepository.watchAllSubscriptions(currentWalletId);
    });
  }

  Future<void> _calculateMonthlySummary() async {
    if (!mounted) return;
    if (!_isLoadingSummary) setState(() => _isLoadingSummary = true);

    final currencyProvider = context.read<CurrencyProvider>();
    final displayCurrencyCode = currencyProvider.selectedCurrency.code;

    if (displayCurrencyCode != 'UAH') {
      try {
        _displayRateInfo = await _exchangeRateService.getConversionRate(
          'UAH',
          displayCurrencyCode,
        );
      } catch (e) {
        _displayRateInfo = null;
      }
    } else {
      _displayRateInfo = ConversionRateInfo(
        rate: 1,
        effectiveRateDate: DateTime.now(),
      );
    }

    _subscriptionsStream?.listen((subscriptions) async {
      final rates = await _exchangeRateService
          .getRatesForCurrencies(appCurrencies.map((c) => c.code).toList());

      double totalMonthlyCost = 0;
      for (final sub in subscriptions) {
        if (sub.isActive) {
          final rateToUAH = rates[sub.currencyCode] ?? 1.0;
          final amountInUAH = sub.amount * rateToUAH;
          switch (sub.billingCycle) {
            case BillingCycle.daily:
              totalMonthlyCost += amountInUAH * 30.44;
            case BillingCycle.weekly:
              totalMonthlyCost += amountInUAH * 4.33;
            case BillingCycle.monthly:
              totalMonthlyCost += amountInUAH;
            case BillingCycle.quarterly:
              totalMonthlyCost += amountInUAH / 3.0;
            case BillingCycle.yearly:
              totalMonthlyCost += amountInUAH / 12.0;
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
    });
  }

  Future<void> _deleteSubscription(Subscription sub) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Видалити підписку?'),
        content: Text(
          'Підписка "${sub.name}" буде видалена. Цю дію неможливо скасувати.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmDelete == true && mounted) {
      if (sub.id == null) return;
      await _subscriptionRepository.deleteSubscription(sub.id!);

      final reminderId = sub.id! * 20000 + 1;
      await _notificationService.cancelNotification(reminderId);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Підписку "${sub.name}" видалено'),
          ),
        );
      }
    }
  }

  String billingCycleToString(BillingCycle cycle, BuildContext context) {
    switch (cycle) {
      case BillingCycle.daily:
        return 'Щодня';
      case BillingCycle.weekly:
        return 'Щотижня';
      case BillingCycle.monthly:
        return 'Щомісяця';
      case BillingCycle.quarterly:
        return 'Щокварталу';
      case BillingCycle.yearly:
        return 'Щороку';
      case BillingCycle.custom:
        return 'Користувацький';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PatternedScaffold(
      appBar: AppBar(
        title: const Text('Підписки'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: Column(
          children: [
            _buildSummaryCard(),
            Expanded(
              child: StreamBuilder<List<Subscription>>(
                stream: _subscriptionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return _buildShimmerList();
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Помилка: ${snapshot.error}'),
                    );
                  }

                  final subscriptions = snapshot.data ?? [];

                  if (subscriptions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildSubscriptionList(subscriptions);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Нова підписка'),
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditSubscriptionScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final currencyProvider = context.watch<CurrencyProvider>();
    final amountInDisplayCurrency =
        _totalMonthlyCostUAH * (_displayRateInfo?.rate ?? 1.0);
    final formattedAmount = NumberFormat.currency(
      locale: currencyProvider.selectedCurrency.locale,
      symbol: currencyProvider.selectedCurrency.symbol,
      decimalDigits: 2,
    ).format(amountInDisplayCurrency);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Витрати на підписки / міс.:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_isLoadingSummary)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                formattedAmount,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppPalette.darkPrimary,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionList(List<Subscription> subscriptions) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 100),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        final currency = appCurrencies.firstWhere(
          (c) => c.code == sub.currencyCode,
          orElse: () => Currency(
            code: sub.currencyCode,
            symbol: '',
            name: '',
            locale: 'uk_UA',
          ),
        );
        final formattedAmount = NumberFormat.currency(
          locale: currency.locale,
          symbol: currency.symbol,
          decimalDigits: 2,
        ).format(sub.amount);
        final categoryName =
            sub.categoryId != null ? _categoryNames[sub.categoryId] : null;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          color: !sub.isActive
              ? AppPalette.darkSurface.withAlpha(128)
              : AppPalette.darkSurface,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: sub.isActive
                  ? AppPalette.darkAccent.withAlpha(38)
                  : Colors.grey.withAlpha(38),
              child: Icon(
                Icons.star_purple500_sharp,
                color: sub.isActive ? AppPalette.darkAccent : Colors.grey,
              ),
            ),
            title: Text(
              sub.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration:
                        !sub.isActive ? TextDecoration.lineThrough : null,
                    color: !sub.isActive
                        ? AppPalette.darkSecondaryText
                        : AppPalette.darkPrimaryText,
                  ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Наступний платіж: ${DateFormat('dd.MM.yyyy').format(sub.nextPaymentDate)}",
                ),
                if (categoryName != null)
                  Text(
                    'Категорія: $categoryName',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedAmount,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  billingCycleToString(sub.billingCycle, context),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            onTap: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditSubscriptionScreen(subscriptionToEdit: sub),
                ),
              );
            },
            onLongPress: () => _deleteSubscription(sub),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppPalette.darkSurface,
      highlightColor: AppPalette.darkBackground,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
        itemCount: 5,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(backgroundColor: Colors.white),
            title: Container(height: 16, width: 150, color: Colors.white),
            subtitle: Container(
              height: 12,
              width: 100,
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
            ),
            trailing: Container(height: 16, width: 60, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.subscriptions_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
            ),
            const SizedBox(height: 24),
            Text(
              'Список підписок порожній',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Додайте свої регулярні платежі, щоб відстежувати їх та отримувати нагадування.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
