import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/models/liability.dart';

abstract class LiabilityRepository {
  Stream<List<Liability>> watchAllLiabilities(int walletId);

  Future<Either<AppFailure, int>> createLiability(
    Liability liability,
    int walletId,
    String userId,
  );

  Future<Either<AppFailure, int>> updateLiability(Liability liability);

  Future<Either<AppFailure, int>> deleteLiability(int liabilityId);
}
