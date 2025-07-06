import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../models/subscription_model.dart';
import '../models/transaction.dart' as FinTransaction;
import './notification_service.dart';

class SubscriptionService {
  final SubscriptionRepository _subRepository;
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final NotificationService _notificationService;

  SubscriptionService(this._subRepository, this._transactionRepository, this._walletRepository, this._notificationService);

  Future<void> checkAndProcessSubscriptions() async {
    final wallets = await _walletRepository.getAllWallets();
    for (final wallet in wallets) {
      if (wallet.id == null) continue;
      final List<Subscription> activeSubs = await _subRepository.getAllSubscriptions(wallet.id!);
      for (Subscription sub in activeSubs) {
        if (!sub.isActive) continue;
        DateTime checkDate = sub.nextPaymentDate;
        while (checkDate.isBefore(DateTime.now()) || checkDate.isAtSameMomentAs(DateTime.now())) {
          final transaction = FinTransaction.Transaction(
            type: FinTransaction.TransactionType.expense,
            originalAmount: sub.amount,
            originalCurrencyCode: sub.currencyCode,
            amountInBaseCurrency: sub.amount,
            exchangeRateUsed: 1.0,
            categoryId: sub.categoryId!,
            date: checkDate,
            description: sub.name,
            subscriptionId: sub.id,
          );
          await _transactionRepository.createTransaction(transaction, wallet.id!);
          sub.nextPaymentDate = sub.calculateNextPaymentDate(checkDate, sub.billingCycle);
          await _subRepository.updateSubscription(sub, wallet.id!);
          checkDate = sub.nextPaymentDate;
        }
      }
    }
  }

  Future<void> checkForUnusedSubscriptions() async {
    final wallets = await _walletRepository.getAllWallets();
    final prefs = await SharedPreferences.getInstance();
    for (final wallet in wallets) {
      if (wallet.id == null) continue;
      final subscriptions = await _subRepository.getAllSubscriptions(wallet.id!);
      for (final sub in subscriptions) {
        if (!sub.isActive || sub.id == null) continue;
        final lastNinetyDays = DateTime.now().subtract(const Duration(days: 90));
        if (sub.startDate.isAfter(lastNinetyDays)) continue;
        final recentTransactions = await _transactionRepository.getTransactionsWithDetails(
          walletId: wallet.id!,
          startDate: lastNinetyDays,
          endDate: DateTime.now(),
        );
        bool hasBeenUsed = recentTransactions.any((tx) => tx.subscriptionId == sub.id);
        String notificationKey = 'unused_sub_notif_${sub.id}';
        bool alreadyNotified = prefs.getBool(notificationKey) ?? false;
        if (!hasBeenUsed && !alreadyNotified) {
          await _notificationService.showNotification(
            sub.id! + 800000,
            "Невикористана підписка? 🤔",
            "Здається, ви давно не користувались '${sub.name}'. Можливо, варто її скасувати?",
            payload: 'subscription/${sub.id}',
            channelId: NotificationService.goalNotificationChannelId,
          );
          await prefs.setBool(notificationKey, true);
        } else if (hasBeenUsed && alreadyNotified) {
          await prefs.remove(notificationKey);
        }
      }
    }
  }
}