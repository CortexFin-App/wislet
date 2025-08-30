import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as fin_transaction;
import 'package:sage_wallet_reborn/models/transaction_view_data.dart';
import 'package:sage_wallet_reborn/models/wallet.dart';

abstract class TransactionRepository {
  Future<Either<AppFailure, void>> createTransfer({
    required Wallet fromWallet,
    required Wallet toWallet,
    required double amount,
    required String currencyCode,
    required DateTime date,
    String? description,
  });

  Future<Either<AppFailure, fin_transaction.Transaction?>> getTransaction(
    int transactionId,
  );

  Future<Either<AppFailure, List<fin_transaction.Transaction>>>
      getTransactionsForGoal(int goalId);

  Future<Either<AppFailure, List<fin_transaction.Transaction>>>
      getTransactionsSince(int walletId, String? lastSyncTimestamp);

  Future<Either<AppFailure, int>> createTransaction(
    fin_transaction.Transaction transaction,
    int walletId,
    String userId,
  );

  Future<Either<AppFailure, int>> updateTransaction(
    fin_transaction.Transaction transaction,
    int walletId,
    String userId,
  );

  Future<Either<AppFailure, int>> deleteTransaction(int transactionId);

  Future<Either<AppFailure, List<TransactionViewData>>>
      getTransactionsWithDetails({
    required int walletId,
    String? orderBy,
    DateTime? startDate,
    DateTime? endDate,
    fin_transaction.TransactionType? filterTransactionType,
    int? filterCategoryId,
    int? limit,
    String? searchQuery,
  });

  Stream<List<TransactionViewData>> watchTransactionsWithDetails({
    required int walletId,
  });

  Future<Either<AppFailure, double>> getOverallBalance(int walletId);

  Future<Either<AppFailure, double>> getTotalAmount({
    required int walletId,
    required DateTime startDate,
    required DateTime endDate,
    required fin_transaction.TransactionType transactionType,
    int? categoryId,
  });

  Future<Either<AppFailure, List<Map<String, dynamic>>>>
      getExpensesGroupedByCategory(
    int walletId,
    DateTime startDate,
    DateTime endDate,
  );
}
