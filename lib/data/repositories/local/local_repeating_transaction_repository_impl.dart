import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../models/repeating_transaction_model.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../repeating_transaction_repository.dart';

class LocalRepeatingTransactionRepositoryImpl implements RepeatingTransactionRepository {
  final DatabaseHelper _dbHelper;

  LocalRepeatingTransactionRepositoryImpl(this._dbHelper);

  @override
  Future<Either<AppFailure, int>> createRepeatingTransaction(RepeatingTransaction rt, int walletId) async {
    try {
      final db = await _dbHelper.database;
      int newId = -1;
      await db.transaction((txn) async {
        final map = rt.toMap();
        map[DatabaseHelper.colRtWalletId] = walletId;
        newId = await txn.insert(DatabaseHelper.tableRepeatingTransactions, map);

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'repeating_transaction',
          DatabaseHelper.colSyncEntityId: newId.toString(),
          DatabaseHelper.colSyncActionType: 'create',
          DatabaseHelper.colSyncPayload: jsonEncode(map..['id'] = newId),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(newId);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, RepeatingTransaction?>> getRepeatingTransaction(int id) async {
    try {
      final db = await _dbHelper.database;
      List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableRepeatingTransactions,
        where: '${DatabaseHelper.colRtId} = ? AND ${DatabaseHelper.colRtIsDeleted} = 0',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Right(RepeatingTransaction.fromMap(maps.first));
      }
      return const Right(null);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<RepeatingTransaction>>> getAllRepeatingTransactions(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableRepeatingTransactions,
        where: '${DatabaseHelper.colRtWalletId} = ? AND ${DatabaseHelper.colRtIsDeleted} = 0',
        whereArgs: [walletId],
        orderBy: '${DatabaseHelper.colRtNextDueDate} ASC',
      );
      final transactions = List.generate(maps.length, (i) => RepeatingTransaction.fromMap(maps[i]));
      return Right(transactions);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateRepeatingTransaction(RepeatingTransaction rt) async {
    try {
      final db = await _dbHelper.database;
      int updatedRows = 0;
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
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(updatedRows);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteRepeatingTransaction(int id) async {
    try {
      final db = await _dbHelper.database;
      int deletedRows = 0;
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
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(deletedRows);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}