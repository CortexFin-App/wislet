import 'package:shared_preferences/shared_preferences.dart';
import 'package:wislet/data/repositories/subscription_repository.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/data/repositories/wallet_repository.dart';
import 'package:wislet/models/subscription_model.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/services/notification_service.dart';

class SubscriptionService {
  SubscriptionService(
    this._subRepository,
    this._transactionRepository,
    this._walletRepository,
    this._notificationService,
  );

  final SubscriptionRepository _subRepository;
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final NotificationService _notificationService;

  Future<void> checkAndProcessSubscriptions() async {
    final walletsEither = await _walletRepository.getAllWallets();

    await walletsEither.fold(
      (l) async => null,
      (wallets) async {
        for (final wallet in wallets) {
          if (wallet.id == null) continue;
          final userIdForWallet = wallet.ownerUserId;

          final subsEither =
              await _subRepository.getAllSubscriptions(wallet.id!);
          await subsEither.fold(
            (l) async => null,
            (activeSubs) async {
              for (final sub in activeSubs) {
                if (!sub.isActive || sub.categoryId == null) continue;

                var checkDate = sub.nextPaymentDate;
                final now = DateTime.now();

                // проганяємо, поки наступна дата <= зараз
                while (!checkDate.isAfter(now)) {
                  final transaction = fin_transaction.Transaction(
                    type: fin_transaction.TransactionType.expense,
                    originalAmount: sub.amount,
                    originalCurrencyCode: sub.currencyCode,
                    amountInBaseCurrency: sub.amount,
                    exchangeRateUsed: 1,
                    categoryId: sub.categoryId!,
                    date: checkDate,
                    description: sub.name,
                    subscriptionId: sub.id,
                  );

                  await _transactionRepository.createTransaction(
                    transaction,
                    wallet.id!,
                    userIdForWallet,
                  );

                  sub.nextPaymentDate = Subscription.calculateNextPaymentDate(
                      checkDate, sub.billingCycle,);

                  await _subRepository.updateSubscription(sub, wallet.id!);
                  checkDate = sub.nextPaymentDate;
                }
              }
            },
          );
        }
      },
    );
  }

  Future<void> checkForUnusedSubscriptions() async {
    final walletsEither = await _walletRepository.getAllWallets();
    final prefs = await SharedPreferences.getInstance();

    await walletsEither.fold(
      (l) async => null,
      (wallets) async {
        for (final wallet in wallets) {
          if (wallet.id == null) continue;

          final subsEither =
              await _subRepository.getAllSubscriptions(wallet.id!);
          await subsEither.fold(
            (l) async => null,
            (subscriptions) async {
              for (final sub in subscriptions) {
                if (!sub.isActive || sub.id == null) continue;

                final lastNinetyDays =
                    DateTime.now().subtract(const Duration(days: 90));
                if (sub.startDate.isAfter(lastNinetyDays)) continue;

                final txsEither =
                    await _transactionRepository.getTransactionsWithDetails(
                  walletId: wallet.id!,
                  startDate: lastNinetyDays,
                  endDate: DateTime.now(),
                );

                await txsEither.fold(
                  (l) async => null,
                  (recentTransactions) async {
                    final hasBeenUsed = recentTransactions
                        .any((tx) => tx.subscriptionId == sub.id);
                    final notificationKey = 'unused_sub_notif_${sub.id}';
                    final alreadyNotified =
                        prefs.getBool(notificationKey) ?? false;

                    if (!hasBeenUsed && !alreadyNotified) {
                      await _notificationService.showNotification(
                        id: sub.id! + 800000,
                        title: 'Невикористана підписка? 🤔',
                        body:
                            "Здається, ви давно не користувалися '${sub.name}'. Можливо, варто її скасувати?",
                        payload: 'subscription/${sub.id}',
                        channelId:
                            NotificationService.goalNotificationChannelId,
                      );
                      await prefs.setBool(notificationKey, true);
                    } else if (hasBeenUsed && alreadyNotified) {
                      await prefs.remove(notificationKey);
                    }
                  },
                );
              }
            },
          );
        }
      },
    );
  }
}
