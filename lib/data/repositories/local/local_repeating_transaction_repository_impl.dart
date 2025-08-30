import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/data/repositories/repeating_transaction_repository.dart';
import 'package:sage_wallet_reborn/models/repeating_transaction_model.dart';
import 'package:sage_wallet_reborn/services/error_monitoring_service.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';

class LocalRepeatingTransactionRepositoryImpl
    implements RepeatingTransactionRepository {
  LocalRepeatingTransactionRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  @override
  Future<Either<AppFailure, int>> createRepeatingTransaction(
    RepeatingTransaction rt,
    int walletId,
  ) async {
    try {
      final db = await _dbHelper.database;
      var newId = -1;
      await db.transaction((txn) async {
        final map = rt.toMap();
        map[DatabaseHelper.colRtWalletId] = walletId;
        newId =
            await txn.insert(DatabaseHelper.tableRepeatingTransactions, map);

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'repeating_transaction',
          DatabaseHelper.colSyncEntityId: newId.toString(),
          DatabaseHelper.colSyncActionType: 'create',
          DatabaseHelper.colSyncPayload: jsonEncode(map..['id'] = newId),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending',
        });
      });
      return Right(newId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, RepeatingTransaction?>> getRepeatingTransaction(
    int id,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableRepeatingTransactions,
        where:
            '${DatabaseHelper.colRtId} = ? AND ${DatabaseHelper.colRtIsDeleted} = 0',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Right(RepeatingTransaction.fromMap(maps.first));
      }
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<RepeatingTransaction>>>
      getAllRepeatingTransactions(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableRepeatingTransactions,
        where:
            '${DatabaseHelper.colRtWalletId} = ? AND ${DatabaseHelper.colRtIsDeleted} = 0',
        whereArgs: [walletId],
        orderBy: '${DatabaseHelper.colRtNextDueDate} ASC',
      );
      final transactions = List.generate(
        maps.length,
        (i) => RepeatingTransaction.fromMap(maps[i]),
      );
      return Right(transactions);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateRepeatingTransaction(
    RepeatingTransaction rt,
  ) async {
    try {
      final db = await _dbHelper.database;
      var updatedRows = 0;
      await db.transaction((txn) async {
        final map = rt.toMap();
        updatedRows = await txn.update(
          DatabaseHelper.tableRepeatingTransactions,
          map,
          where: '${DatabaseHelper.colRtId} = ?',
          whereArgs: [rt.id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'repeating_transaction',
          DatabaseHelper.colSyncEntityId: rt.id.toString(),
          DatabaseHelper.colSyncActionType: 'update',
          DatabaseHelper.colSyncPayload: jsonEncode(map),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending',
        });
      });
      return Right(updatedRows);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteRepeatingTransaction(int id) async {
    try {
      final db = await _dbHelper.database;
      var deletedRows = 0;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        deletedRows = await txn.update(
          DatabaseHelper.tableRepeatingTransactions,
          {
            DatabaseHelper.colRtIsDeleted: 1,
            DatabaseHelper.colRtUpdatedAt: now,
          },
          where: '${DatabaseHelper.colRtId} = ?',
          whereArgs: [id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'repeating_transaction',
          DatabaseHelper.colSyncEntityId: id.toString(),
          DatabaseHelper.colSyncActionType: 'delete',
          DatabaseHelper.colSyncPayload: jsonEncode({'id': id}),
          DatabaseHelper.colSyncTimestamp: now,
          DatabaseHelper.colSyncStatus: 'pending',
        });
      });
      return Right(deletedRows);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}
