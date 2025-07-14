import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../models/subscription_model.dart';
import '../models/transaction.dart' as fin_transaction;
import './notification_service.dart';

class SubscriptionService {
  final SubscriptionRepository _subRepository;
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final NotificationService _notificationService;

  SubscriptionService(this._subRepository, this._transactionRepository, this._walletRepository, this._notificationService);

  Future<void> checkAndProcessSubscriptions() async {
    final walletsEither = await _walletRepository.getAllWallets();
    
    walletsEither.fold(
      (l) => null,
      (wallets) async {
        for (final wallet in wallets) {
          if (wallet.id == null) continue;
          final String userIdForWallet = wallet.ownerUserId;
          
          final subsEither = await _subRepository.getAllSubscriptions(wallet.id!);
          subsEither.fold(
            (l) => null,
            (activeSubs) async {
              for (Subscription sub in activeSubs) {
                if (!sub.isActive || sub.categoryId == null) continue;
                DateTime checkDate = sub.nextPaymentDate;
                while (checkDate.isBefore(DateTime.now()) || checkDate.isAtSameMomentAs(DateTime.now())) {
                  final transaction = fin_transaction.Transaction(
                    type: fin_transaction.TransactionType.expense,
                    originalAmount: sub.amount,
                    originalCurrencyCode: sub.currencyCode,
                    amountInBaseCurrency: sub.amount,
                    exchangeRateUsed: 1.0,
                    categoryId: sub.categoryId!,
                    date: checkDate,
                    description: sub.name,
                    subscriptionId: sub.id,
                  );
                  await _transactionRepository.createTransaction(transaction, wallet.id!, userIdForWallet);
                  sub.nextPaymentDate = sub.calculateNextPaymentDate(checkDate, sub.billingCycle);
                  await _subRepository.updateSubscription(sub, wallet.id!);
                  checkDate = sub.nextPaymentDate;
                }
              }
            }
          );
        }
      }
    );
  }

  Future<void> checkForUnusedSubscriptions() async {
    final walletsEither = await _walletRepository.getAllWallets();
    final prefs = await SharedPreferences.getInstance();

    walletsEither.fold(
      (l) => null,
      (wallets) {
        for (final wallet in wallets) {
          if (wallet.id == null) continue;
          _subRepository.getAllSubscriptions(wallet.id!).then((subsEither) {
            subsEither.fold(
              (l) => null,
              (subscriptions) {
                for (final sub in subscriptions) {
                  if (!sub.isActive || sub.id == null) continue;
                  final lastNinetyDays = DateTime.now().subtract(const Duration(days: 90));
                  if (sub.startDate.isAfter(lastNinetyDays)) continue;
                  
                  _transactionRepository.getTransactionsWithDetails(
                    walletId: wallet.id!,
                    startDate: lastNinetyDays,
                    endDate: DateTime.now(),
                  ).then((txsEither) {
                    txsEither.fold(
                      (l) => null,
                      (recentTransactions) async {
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
                    );
                  });
                }
              }
            );
          });
        }
      }
    );
  }
}