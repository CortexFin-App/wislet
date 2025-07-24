import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../models/asset.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../asset_repository.dart';

class LocalAssetRepositoryImpl implements AssetRepository {
  final DatabaseHelper _dbHelper;
  LocalAssetRepositoryImpl(this._dbHelper);

  @override
  Stream<List<Asset>> watchAllAssets(int walletId) {
    return Stream.fromFuture(getAllAssets(walletId))
        .map((either) => either.getOrElse((_) => []));
  }
  
  Future<Either<AppFailure, List<Asset>>> getAllAssets(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableAssets,
        where: '${DatabaseHelper.colAssetWalletId} = ? AND ${DatabaseHelper.colAssetIsDeleted} = 0',
        whereArgs: [walletId],
      );
      return Right(maps.map((map) => Asset.fromMap(map)).toList());
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createAsset(Asset asset, int walletId, String userId) async {
    try {
      final db = await _dbHelper.database;
      final map = asset.toMap();
      map[DatabaseHelper.colAssetWalletId] = walletId;
      map[DatabaseHelper.colAssetUserId] = userId;
      final newId = await db.insert(DatabaseHelper.tableAssets, map);
      return Right(newId);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateAsset(Asset asset) async {
    try {
      final db = await _dbHelper.database;
      final map = asset.toMap();
      final updatedId = await db.update(
        DatabaseHelper.tableAssets,
        map,
        where: '${DatabaseHelper.colAssetId} = ?',
        whereArgs: [asset.id],
      );
      return Right(updatedId);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
  
  @override
  Future<Either<AppFailure, int>> deleteAsset(int assetId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      final deletedRows = await db.update(
        DatabaseHelper.tableAssets,
        {
          DatabaseHelper.colAssetIsDeleted: 1,
          DatabaseHelper.colAssetUpdatedAt: now
        },
        where: '${DatabaseHelper.colAssetId} = ?',
        whereArgs: [assetId],
      );
      return Right(deletedRows);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}