import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../models/budget_models.dart';
import '../../models/transaction.dart' as fin_transaction;

abstract class BudgetRepository {
  Future<Either<AppFailure, int>> createBudget(Budget budget, int walletId);
  Future<Either<AppFailure, int>> updateBudget(Budget budget);
  Future<Either<AppFailure, int>> deleteBudget(int budgetId);
  Future<Either<AppFailure, List<Budget>>> getAllBudgets(int walletId);
  Stream<List<Budget>> watchAllBudgets(int walletId);
  Future<Either<AppFailure, Budget?>> getActiveBudgetForDate(int walletId, DateTime date);
  Future<Either<AppFailure, int>> createBudgetEnvelope(BudgetEnvelope envelope);
  Future<Either<AppFailure, int>> updateBudgetEnvelope(BudgetEnvelope envelope);
  Future<Either<AppFailure, int>> deleteBudgetEnvelope(int id);
  Future<Either<AppFailure, List<BudgetEnvelope>>> getEnvelopesForBudget(int budgetId);
  Future<Either<AppFailure, BudgetEnvelope?>> getEnvelopeForCategory(int budgetId, int categoryId);
  Future<Either<AppFailure, void>> checkAndNotifyEnvelopeLimits(fin_transaction.Transaction transaction, int walletId);
}