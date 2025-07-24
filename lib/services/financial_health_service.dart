import '../core/di/injector.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/debt_loan_repository.dart';
import '../models/transaction.dart' as fin_transaction;
import 'dart:math';

class HealthScoreProfile {
  final int score;
  final double savingsRate;
  final bool isSavingsRatePositive;
  final double debtToIncomeRatio;
  final double budgetAdherence;
  final int activeGoals;

  HealthScoreProfile({
    required this.score,
    required this.savingsRate,
    required this.isSavingsRatePositive,
    required this.debtToIncomeRatio,
    required this.budgetAdherence,
    required this.activeGoals,
  });

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
    final startOfMonth = DateTime(now.year, now.month, 1);

    final incomeEither = await _transactionRepo.getTotalAmount(
      walletId: walletId, 
      startDate: startOfMonth, 
      endDate: now, 
      transactionType: fin_transaction.TransactionType.income
    );
    final expensesEither = await _transactionRepo.getTotalAmount(
      walletId: walletId, 
      startDate: startOfMonth, 
      endDate: now, 
      transactionType: fin_transaction.TransactionType.expense
    );
    final debtsEither = await _debtLoanRepo.getAllDebtLoans(walletId);

    final totalIncome = incomeEither.getOrElse((_) => 0.0);
    final totalExpenses = expensesEither.getOrElse((_) => 0.0);
    final allDebts = debtsEither.getOrElse((_) => []);

    double savingsRate = totalIncome > 0 ? (totalIncome - totalExpenses) / totalIncome : 0.0;
    double savingsScore = (savingsRate.clamp(0, 0.2) * 200).roundToDouble();

    double totalDebtAmount = allDebts.where((d) => !d.isSettled).fold(0, (sum, d) => sum + d.amountInBaseCurrency);
    double debtToIncomeRatio = totalIncome > 0 ? totalDebtAmount / totalIncome : 1.0;
    double debtScore = ((1 - debtToIncomeRatio.clamp(0, 1)) * 25).roundToDouble();

    int activeGoalsCount = 0;
    double goalScore = min(activeGoalsCount * 5.0, 15.0);

    double score = savingsScore + debtScore + goalScore + 20;

    return HealthScoreProfile(
      score: score.clamp(0, 100).toInt(),
      savingsRate: savingsRate,
      isSavingsRatePositive: totalIncome > totalExpenses,
      debtToIncomeRatio: debtToIncomeRatio,
      budgetAdherence: 1.0,
      activeGoals: activeGoalsCount,
    );
  }
}