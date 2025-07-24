import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../models/liability.dart';

abstract class LiabilityRepository {
  Stream<List<Liability>> watchAllLiabilities(int walletId);
  Future<Either<AppFailure, int>> createLiability(Liability liability, int walletId, String userId);
  Future<Either<AppFailure, int>> updateLiability(Liability liability);
  Future<Either<AppFailure, int>> deleteLiability(int liabilityId);
}