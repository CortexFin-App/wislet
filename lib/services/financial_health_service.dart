import 'dart:math';

import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/debt_loan_repository.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;

class HealthScoreProfile {
  HealthScoreProfile({
    required this.score,
    required this.savingsRate,
    required this.isSavingsRatePositive,
    required this.debtToIncomeRatio,
    required this.budgetAdherence,
    required this.activeGoals,
  });

  final int score;
  final double savingsRate;
  final bool isSavingsRatePositive;
  final double debtToIncomeRatio;
  final double budgetAdherence;
  final int activeGoals;

  Map<String, dynamic> toJson() => {
        'score': score,
        'savingsRate': savingsRate,
        'isSavingsRatePositive': isSavingsRatePositive,
        'debtToIncomeRatio': debtToIncomeRatio,
        'budgetAdherence': budgetAdherence,
        'activeGoals': activeGoals,
      };
}

class FinancialHealthService {
  final TransactionRepository _transactionRepo = getIt<TransactionRepository>();
  final DebtLoanRepository _debtLoanRepo = getIt<DebtLoanRepository>();

  Future<HealthScoreProfile> calculateHealthScore(int walletId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);

    final incomeEither = await _transactionRepo.getTotalAmount(
      walletId: walletId,
      startDate: startOfMonth,
      endDate: now,
      transactionType: fin_transaction.TransactionType.income,
    );
    final expensesEither = await _transactionRepo.getTotalAmount(
      walletId: walletId,
      startDate: startOfMonth,
      endDate: now,
      transactionType: fin_transaction.TransactionType.expense,
    );
    final debtsEither = await _debtLoanRepo.getAllDebtLoans(walletId);

    final totalIncome = incomeEither.getOrElse((_) => 0.0);
    final totalExpenses = expensesEither.getOrElse((_) => 0.0);
    final allDebts = debtsEither.getOrElse((_) => []);

    final savingsRate = totalIncome > 0
        ? (totalIncome - totalExpenses) / totalIncome
        : (totalExpenses > 0 ? -1.0 : 0.0);
    final savingsScore = (savingsRate.clamp(-0.5, 0.3) + 0.5) / 0.8 * 50;

    final totalDebtAmount = allDebts
        .where((d) => !d.isSettled)
        .fold<double>(0, (sum, d) => sum + d.amountInBaseCurrency);
    final debtToIncomeRatio =
        totalIncome > 0 ? totalDebtAmount / (totalIncome * 6) : 1.0;
    final debtScore = (1 - debtToIncomeRatio.clamp(0, 1)) * 30;

    const activeGoalsCount = 0;
    final goalScore = min(activeGoalsCount * 10.0, 20);

    final score = savingsScore + debtScore + goalScore;

    return HealthScoreProfile(
      score: score.clamp(0, 100).toInt(),
      savingsRate: savingsRate,
      isSavingsRatePositive: totalIncome >= totalExpenses,
      debtToIncomeRatio: debtToIncomeRatio,
      budgetAdherence: 1,
      activeGoals: activeGoalsCount,
    );
  }
}
