import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../models/financial_goal.dart';

abstract class GoalRepository {
  Future<Either<AppFailure, int>> createFinancialGoal(FinancialGoal goal, int walletId);
  Future<Either<AppFailure, FinancialGoal?>> getFinancialGoal(int id);
  Future<Either<AppFailure, List<FinancialGoal>>> getAllFinancialGoals(int walletId);
  Stream<List<FinancialGoal>> watchAllFinancialGoals(int walletId);
  Future<Either<AppFailure, int>> updateFinancialGoal(FinancialGoal goal);
  Future<Either<AppFailure, int>> deleteFinancialGoal(int id);
  Future<Either<AppFailure, void>> updateFinancialGoalProgress(int goalId);
}