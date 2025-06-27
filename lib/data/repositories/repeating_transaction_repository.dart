import '../../models/repeating_transaction_model.dart';

abstract class RepeatingTransactionRepository {
  Future<int> createRepeatingTransaction(RepeatingTransaction rt, int walletId);
  Future<RepeatingTransaction?> getRepeatingTransaction(int id);
  Future<List<RepeatingTransaction>> getAllRepeatingTransactions(int walletId);
  Future<int> updateRepeatingTransaction(RepeatingTransaction rt);
  Future<int> deleteRepeatingTransaction(int id);
}