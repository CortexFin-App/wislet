import 'package:sage_wallet_reborn/data/repositories/subscription_repository.dart';
import 'package:sage_wallet_reborn/models/transaction.dart';
import 'package:sage_wallet_reborn/data/repositories/repeating_transaction_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';
import 'package:sage_wallet_reborn/models/forecast_data_point.dart';

class CashflowForecastService {
  final TransactionRepository _transactionRepo;
  final RepeatingTransactionRepository _rtRepo;
  final SubscriptionRepository _subRepo;

  CashflowForecastService(this._transactionRepo, this._rtRepo, this._subRepo);

  Future<List<ForecastDataPoint>> getForecast({
    required int walletId,
    required int days,
  }) async {
    final List<ForecastDataPoint> forecast = [];
    final now = DateTime.now();
    double currentBalance = await _transactionRepo.getOverallBalance(walletId);
    final activeRepeatingTxs = await _rtRepo.getAllRepeatingTransactions(walletId);
    final activeSubscriptions = await _subRepo.getAllSubscriptions(walletId);
    forecast.add(ForecastDataPoint(date: now, balance: currentBalance));

    for (int i = 1; i <= days; i++) {
      final DateTime day = now.add(Duration(days: i));
      double dailyChange = 0.0;

      for (final rt in activeRepeatingTxs) {
        if (!rt.isActive) continue;
        if (rt.nextDueDate.year == day.year &&
            rt.nextDueDate.month == day.month &&
            rt.nextDueDate.day == day.day) {
          dailyChange += (rt.type == TransactionType.income ? rt.originalAmount : -rt.originalAmount);
        }
      }

      for (final sub in activeSubscriptions) {
        if (!sub.isActive) continue;
        if (sub.nextPaymentDate.year == day.year &&
            sub.nextPaymentDate.month == day.month &&
            sub.nextPaymentDate.day == day.day) {
          dailyChange -= sub.amount;
        }
      }

      if (dailyChange != 0) {
        currentBalance += dailyChange;
      }
      
      forecast.add(ForecastDataPoint(date: day, balance: currentBalance));
    }

    return forecast;
  }
}