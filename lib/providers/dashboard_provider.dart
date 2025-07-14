import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import '../core/di/injector.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/financial_health.dart';
import '../utils/app_colors.dart';
import '../models/transaction.dart' as fin_transaction;


class DashboardProvider with ChangeNotifier {
  final TransactionRepository _transactionRepo = getIt<TransactionRepository>();

  FinancialHealth _health = FinancialHealth.initial();
  bool _isLoading = true;
  bool _isDetailsVisible = false;

  FinancialHealth get health => _health;
  bool get isLoading => _isLoading;
  bool get isDetailsVisible => _isDetailsVisible;

  Color get sphereColor {
    final ratio = _health.expenses / (_health.income > 0 ? _health.income : 1);
    if (ratio > 0.95) return AppColors.sphereRed;
    if (ratio > 0.70) return AppColors.sphereYellow;
    return AppColors.sphereGreen;
  }
  
  double get pulseRate {
    if (_health.dailyBalance >= 0) {
      return 1.0; 
    } else {
      return 1.5;
    }
  }

  Future<void> fetchFinancialHealth(int walletId) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day);
    
    final results = await Future.wait([
      _transactionRepo.getOverallBalance(walletId),
      _transactionRepo.getTotalAmount(
        walletId: walletId,
        startDate: startOfMonth,
        endDate: now,
        transactionType: fin_transaction.TransactionType.income
      ),
      _transactionRepo.getTotalAmount(
        walletId: walletId,
        startDate: startOfMonth,
        endDate: now,
        transactionType: fin_transaction.TransactionType.expense
      ),
       _transactionRepo.getTotalAmount(
        walletId: walletId,
        startDate: today,
        endDate: now,
        transactionType: fin_transaction.TransactionType.income
      ),
       _transactionRepo.getTotalAmount(
        walletId: walletId,
        startDate: today,
        endDate: now,
        transactionType: fin_transaction.TransactionType.expense
      ),
    ]);
    
    final overallBalance = (results[0] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final monthlyIncome = (results[1] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final monthlyExpenses = (results[2] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final dailyIncome = (results[3] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final dailyExpenses = (results[4] as Either<dynamic, double>).getOrElse((_) => 0.0);


    _health = FinancialHealth(
      income: monthlyIncome,
      expenses: monthlyExpenses,
      balance: overallBalance,
      dailyBalance: dailyIncome - dailyExpenses
    );
    
    _isLoading = false;
    notifyListeners();
  }

  void toggleDetailsVisibility(bool isVisible) {
    if (_isDetailsVisible != isVisible) {
      _isDetailsVisible = isVisible;
      notifyListeners();
    }
  }
}