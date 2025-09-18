import 'package:wislet/data/repositories/repeating_transaction_repository.dart';
import 'package:wislet/data/repositories/subscription_repository.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/models/forecast_data_point.dart';
import 'package:wislet/models/transaction.dart';

class CashflowForecastService {
  CashflowForecastService(
    this._transactionRepo,
    this._rtRepo,
    this._subRepo,
  );

  final TransactionRepository _transactionRepo;
  final RepeatingTransactionRepository _rtRepo;
  final SubscriptionRepository _subRepo;

  Future<List<ForecastDataPoint>> getForecast({
    required int walletId,
    required int days,
  }) async {
    final forecast = <ForecastDataPoint>[];
    final now = DateTime.now();

    final balanceEither = await _transactionRepo.getOverallBalance(walletId);
    if (balanceEither.isLeft()) return [];
    var currentBalance = balanceEither.getRight().toNullable() ?? 0.0;

    final rtEither = await _rtRepo.getAllRepeatingTransactions(walletId);
    if (rtEither.isLeft()) return [];
    final activeRepeatingTxs = rtEither.getRight().toNullable() ?? [];

    final subEither = await _subRepo.getAllSubscriptions(walletId);
    if (subEither.isLeft()) return [];
    final activeSubscriptions = subEither.getRight().toNullable() ?? [];

    forecast.add(ForecastDataPoint(date: now, balance: currentBalance));

    for (var i = 1; i <= days; i++) {
      final day = now.add(Duration(days: i));
      double dailyChange = 0;

      for (final rt in activeRepeatingTxs) {
        if (!rt.isActive) continue;
        if (rt.nextDueDate.year == day.year &&
            rt.nextDueDate.month == day.month &&
            rt.nextDueDate.day == day.day) {
          dailyChange += (rt.type == TransactionType.income
              ? rt.originalAmount
              : -rt.originalAmount);
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
