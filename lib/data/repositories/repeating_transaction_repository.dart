import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/models/repeating_transaction_model.dart';

abstract class RepeatingTransactionRepository {
  Future<Either<AppFailure, int>> createRepeatingTransaction(
    RepeatingTransaction rt,
    int walletId,
  );

  Future<Either<AppFailure, RepeatingTransaction?>> getRepeatingTransaction(
    int id,
  );

  Future<Either<AppFailure, List<RepeatingTransaction>>>
      getAllRepeatingTransactions(int walletId);

  Future<Either<AppFailure, int>> updateRepeatingTransaction(
    RepeatingTransaction rt,
  );

  Future<Either<AppFailure, int>> deleteRepeatingTransaction(int id);
}
