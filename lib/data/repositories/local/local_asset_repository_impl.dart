import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/asset_repository.dart';
import 'package:wislet/models/asset.dart';
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:wislet/utils/database_helper.dart';

class LocalAssetRepositoryImpl implements AssetRepository {
  LocalAssetRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

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
        where:
            '${DatabaseHelper.colAssetWalletId} = ? AND ${DatabaseHelper.colAssetIsDeleted} = 0',
        whereArgs: [walletId],
      );
      return Right(maps.map(Asset.fromMap).toList());
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createAsset(
    Asset asset,
    int walletId,
    String userId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final map = asset.toMap();
      map[DatabaseHelper.colAssetWalletId] = walletId;
      map[DatabaseHelper.colAssetUserId] = userId;
      final newId = await db.insert(DatabaseHelper.tableAssets, map);
      return Right(newId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
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
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
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
          DatabaseHelper.colAssetUpdatedAt: now,
        },
        where: '${DatabaseHelper.colAssetId} = ?',
        whereArgs: [assetId],
      );
      return Right(deletedRows);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}
