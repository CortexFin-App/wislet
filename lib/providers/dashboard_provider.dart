import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/di/injector.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../models/financial_health.dart';
import '../models/transaction.dart' as fin_transaction;
import '../models/financial_goal.dart';
import '../services/financial_health_service.dart';
import '../utils/app_palette.dart';

class AiAdvice {
  final String title;
  final String positive;
  final String suggestion;
  AiAdvice({required this.title, required this.positive, required this.suggestion});
}

class SpendingCategory {
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  SpendingCategory({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class DashboardProvider with ChangeNotifier {
  final TransactionRepository _transactionRepo = getIt<TransactionRepository>();
  final GoalRepository _goalRepo = getIt<GoalRepository>();
  final FinancialHealthService _healthService = getIt<FinancialHealthService>();
  final SupabaseClient _supabase = getIt<SupabaseClient>();

  FinancialHealth _health = FinancialHealth.initial();
  List<SpendingCategory> _topCategories = [];
  FinancialGoal? _mainGoal;
  HealthScoreProfile? _healthScoreProfile;
  AiAdvice? _aiAdvice;
  bool _isLoading = true;

  FinancialHealth get health => _health;
  List<SpendingCategory> get topCategories => _topCategories;
  FinancialGoal? get mainGoal => _mainGoal;
  HealthScoreProfile? get healthScoreProfile => _healthScoreProfile;
  AiAdvice? get aiAdvice => _aiAdvice;
  bool get isLoading => _isLoading;

  Future<void> fetchFinancialHealth(int walletId) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final overallBalanceEither = _transactionRepo.getOverallBalance(walletId);
    final monthlyIncomeEither = _transactionRepo.getTotalAmount(
        walletId: walletId,
        startDate: startOfMonth,
        endDate: now,
        transactionType: fin_transaction.TransactionType.income);
    final monthlyExpensesEither = _transactionRepo.getTotalAmount(
        walletId: walletId,
        startDate: startOfMonth,
        endDate: now,
        transactionType: fin_transaction.TransactionType.expense);
    final expensesGroupedEither =
        _transactionRepo.getExpensesGroupedByCategory(walletId, startOfMonth, now);
    final goalsEither = _goalRepo.getAllFinancialGoals(walletId);
    final healthScoreProfile = _healthService.calculateHealthScore(walletId);

    final results = await Future.wait([
      overallBalanceEither,
      monthlyIncomeEither,
      monthlyExpensesEither,
      expensesGroupedEither,
      goalsEither,
      healthScoreProfile
    ]);

    final overallBalance =
        (results[0] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final monthlyIncome =
        (results[1] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final monthlyExpenses =
        (results[2] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final expensesGrouped = (results[3] as Either<dynamic, List<Map<String, dynamic>>>)
        .getOrElse((_) => []);
    final allGoals = (results[4] as Either<dynamic, List<FinancialGoal>>)
        .getOrElse((_) => []);
    
    _healthScoreProfile = results[5] as HealthScoreProfile;

    _health = FinancialHealth(
      income: monthlyIncome,
      expenses: monthlyExpenses,
      balance: overallBalance,
      dailyBalance: 0,
    );
    
    _mainGoal = allGoals.where((g) => !g.isAchieved).firstOrNull;

    if (monthlyExpenses > 0) {
      final List<Color> pieColors = [
        AppPalette.darkAccent,
        Colors.purpleAccent.shade100,
        Colors.orangeAccent.shade100,
        Colors.cyan.shade300,
        Colors.pinkAccent.shade100,
      ];
      _topCategories = expensesGrouped.take(4).map((e) {
        int index = expensesGrouped.indexOf(e);
        return SpendingCategory(
          name: e['categoryName'],
          amount: e['totalAmount'],
          percentage: (e['totalAmount'] / monthlyExpenses),
          color: pieColors[index % pieColors.length],
        );
      }).toList();

      double topCategoriesSum = _topCategories.fold(0.0, (sum, item) => sum + item.amount);
      if (monthlyExpenses - topCategoriesSum > 0) {
        _topCategories.add(SpendingCategory(
          name: 'Інше',
          amount: monthlyExpenses - topCategoriesSum,
          percentage: (monthlyExpenses - topCategoriesSum) / monthlyExpenses,
          color: Colors.grey.shade700,
        ));
      }
    } else {
      _topCategories = [];
    }

    try {
      final response = await _supabase.functions.invoke(
        'generate-health-advice',
        body: _healthScoreProfile!.toJson(),
      );
      _aiAdvice = AiAdvice(
        title: response.data['title'],
        positive: response.data['positive'],
        suggestion: response.data['suggestion'],
      );
    } catch (e) {
      _aiAdvice = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}