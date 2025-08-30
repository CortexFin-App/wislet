import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/goal_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';
import 'package:sage_wallet_reborn/models/financial_goal.dart';
import 'package:sage_wallet_reborn/models/financial_health.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as fin_transaction;
import 'package:sage_wallet_reborn/services/financial_health_service.dart';
import 'package:sage_wallet_reborn/utils/app_palette.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiAdvice {
  AiAdvice({
    required this.title,
    required this.positive,
    required this.suggestion,
  });
  final String title;
  final String positive;
  final String suggestion;
}

class SpendingCategory {
  SpendingCategory({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
  final String name;
  final double amount;
  final double percentage;
  final Color color;
}

class DashboardProvider with ChangeNotifier {
  final TransactionRepository _transactionRepo = getIt<TransactionRepository>();
  final GoalRepository _goalRepo = getIt<GoalRepository>();
  final FinancialHealthService _healthService = FinancialHealthService();
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
    final startOfMonth = DateTime(now.year, now.month);

    final overallBalanceEither = _transactionRepo.getOverallBalance(walletId);
    final monthlyIncomeEither = _transactionRepo.getTotalAmount(
      walletId: walletId,
      startDate: startOfMonth,
      endDate: now,
      transactionType: fin_transaction.TransactionType.income,
    );
    final monthlyExpensesEither = _transactionRepo.getTotalAmount(
      walletId: walletId,
      startDate: startOfMonth,
      endDate: now,
      transactionType: fin_transaction.TransactionType.expense,
    );
    final expensesGroupedEither = _transactionRepo.getExpensesGroupedByCategory(
      walletId,
      startOfMonth,
      now,
    );
    final goalsEither = _goalRepo.getAllFinancialGoals(walletId);
    final healthScoreProfileFuture =
        _healthService.calculateHealthScore(walletId);

    final results = await Future.wait([
      overallBalanceEither,
      monthlyIncomeEither,
      monthlyExpensesEither,
      expensesGroupedEither,
      goalsEither,
      healthScoreProfileFuture,
    ]);

    final overallBalance =
        (results[0] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final monthlyIncome =
        (results[1] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final monthlyExpenses =
        (results[2] as Either<dynamic, double>).getOrElse((_) => 0.0);
    final expensesGrouped =
        (results[3] as Either<dynamic, List<Map<String, dynamic>>>)
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

    _mainGoal = allGoals.firstWhereOrNull((g) => !g.isAchieved);

    if (monthlyExpenses > 0) {
      final pieColors = <Color>[
        AppPalette.darkAccent,
        Colors.purpleAccent.shade100,
        Colors.orangeAccent.shade100,
        Colors.cyan.shade300,
        Colors.pinkAccent.shade100,
      ];
      _topCategories = expensesGrouped.take(4).map((e) {
        final index = expensesGrouped.indexOf(e);
        return SpendingCategory(
          name: e['categoryName'] as String,
          amount: e['totalAmount'] as double,
          percentage: (e['totalAmount'] as double) / monthlyExpenses,
          color: pieColors[index % pieColors.length],
        );
      }).toList();

      final topCategoriesSum =
          _topCategories.fold<double>(0, (sum, item) => sum + item.amount);
      if (monthlyExpenses - topCategoriesSum > 0) {
        _topCategories.add(
          SpendingCategory(
            name: 'Р†РЅС€Рµ',
            amount: monthlyExpenses - topCategoriesSum,
            percentage: (monthlyExpenses - topCategoriesSum) / monthlyExpenses,
            color: Colors.grey.shade700,
          ),
        );
      }
    } else {
      _topCategories = [];
    }

    try {
      final response = await _supabase.functions.invoke(
        'generate-health-advice',
        body: _healthScoreProfile!.toJson(),
      );
      final responseData = response.data as Map<String, dynamic>?;
      _aiAdvice = AiAdvice(
        title: responseData?['title'] as String? ?? '',
        positive: responseData?['positive'] as String? ?? '',
        suggestion: responseData?['suggestion'] as String? ?? '',
      );
    } on Exception {
      _aiAdvice = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}
