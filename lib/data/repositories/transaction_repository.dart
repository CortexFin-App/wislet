import '../../models/transaction.dart' as FinTransaction;
import '../../models/transaction_view_data.dart';
import '../../models/wallet.dart';

abstract class TransactionRepository {
  Future<void> createTransfer({
    required Wallet fromWallet,
    required Wallet toWallet,
    required double amount,
    required String currencyCode,
    required DateTime date,
    String? description,
  });

  Future<FinTransaction.Transaction?> getTransaction(int transactionId);
  Future<List<FinTransaction.Transaction>> getTransactionsForGoal(int goalId);
  Future<int> createTransaction(FinTransaction.Transaction transaction, int walletId);
  Future<int> updateTransaction(FinTransaction.Transaction transaction, int walletId);
  Future<int> deleteTransaction(int transactionId);
  Future<List<TransactionViewData>> getTransactionsWithDetails({
    required int walletId,
    String? orderBy,
    DateTime? startDate,
    DateTime? endDate,
    FinTransaction.TransactionType? filterTransactionType,
    int? filterCategoryId,
    int? limit,
    String? searchQuery,
  });
  Future<double> getOverallBalance(int walletId);
  Future<double> getTotalAmount({
    required int walletId,
    required DateTime startDate,
    required DateTime endDate,
    required FinTransaction.TransactionType transactionType,
    int? categoryId,
  });
  Future<List<Map<String, dynamic>>> getExpensesGroupedByCategory(int walletId, DateTime startDate, DateTime endDate);
}