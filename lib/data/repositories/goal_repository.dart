import '../../models/financial_goal.dart';

abstract class GoalRepository {
  Future<int> createFinancialGoal(FinancialGoal goal, int walletId);
  Future<FinancialGoal?> getFinancialGoal(int id);
  Future<List<FinancialGoal>> getAllFinancialGoals(int walletId);
  Future<int> updateFinancialGoal(FinancialGoal goal);
  Future<int> deleteFinancialGoal(int id);
  Future<void> updateFinancialGoalProgress(int goalId);
}