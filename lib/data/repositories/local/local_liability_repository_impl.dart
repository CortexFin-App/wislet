import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../models/liability.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../liability_repository.dart';

class LocalLiabilityRepositoryImpl implements LiabilityRepository {
  final DatabaseHelper _dbHelper;
  LocalLiabilityRepositoryImpl(this._dbHelper);

  @override
  Stream<List<Liability>> watchAllLiabilities(int walletId) {
    return Stream.fromFuture(getAllLiabilities(walletId))
        .map((either) => either.getOrElse((_) => []));
  }
  
  Future<Either<AppFailure, List<Liability>>> getAllLiabilities(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableLiabilities,
        where: '${DatabaseHelper.colLiabilityWalletId} = ? AND ${DatabaseHelper.colLiabilityIsDeleted} = 0',
        whereArgs: [walletId],
      );
      return Right(maps.map((map) => Liability.fromMap(map)).toList());
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createLiability(Liability liability, int walletId, String userId) async {
    try {
      final db = await _dbHelper.database;
      final map = liability.toMap();
      map[DatabaseHelper.colLiabilityWalletId] = walletId;
      map[DatabaseHelper.colLiabilityUserId] = userId;
      final newId = await db.insert(DatabaseHelper.tableLiabilities, map);
      return Right(newId);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateLiability(Liability liability) async {
    try {
      final db = await _dbHelper.database;
      final map = liability.toMap();
      final updatedId = await db.update(
        DatabaseHelper.tableLiabilities,
        map,
        where: '${DatabaseHelper.colLiabilityId} = ?',
        whereArgs: [liability.id],
      );
      return Right(updatedId);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
  
  @override
  Future<Either<AppFailure, int>> deleteLiability(int liabilityId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      final deletedRows = await db.update(
        DatabaseHelper.tableLiabilities,
        {
          DatabaseHelper.colLiabilityIsDeleted: 1,
          DatabaseHelper.colLiabilityUpdatedAt: now
        },
        where: '${DatabaseHelper.colLiabilityId} = ?',
        whereArgs: [liabilityId],
      );
      return Right(deletedRows);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}