import '../../models/budget_models.dart';
import '../../models/transaction.dart' as FinTransaction;

abstract class BudgetRepository {
  Future<int> createBudget(Budget budget, int walletId);
  Future<int> updateBudget(Budget budget);
  Future<int> deleteBudget(int budgetId);
  Future<List<Budget>> getAllBudgets(int walletId);
  Future<Budget?> getActiveBudgetForDate(int walletId, DateTime date);
  Future<int> createBudgetEnvelope(BudgetEnvelope envelope);
  Future<int> updateBudgetEnvelope(BudgetEnvelope envelope);
  Future<int> deleteBudgetEnvelope(int id);
  Future<List<BudgetEnvelope>> getEnvelopesForBudget(int budgetId);
  Future<BudgetEnvelope?> getEnvelopeForCategory(int budgetId, int categoryId);
  Future<void> checkAndNotifyEnvelopeLimits(FinTransaction.Transaction transaction, int walletId);
}