import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../models/subscription_model.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../subscription_repository.dart';

class LocalSubscriptionRepositoryImpl implements SubscriptionRepository {
  final DatabaseHelper _dbHelper;

  LocalSubscriptionRepositoryImpl(this._dbHelper);
  
  @override
  Stream<List<Subscription>> watchAllSubscriptions(int walletId) {
    return Stream.fromFuture(getAllSubscriptions(walletId))
        .map((either) => either.getOrElse((_) => []));
  }

  @override
  Future<Either<AppFailure, int>> createSubscription(Subscription sub, int walletId) async {
    try {
      final db = await _dbHelper.database;
      int newId = -1;
      await db.transaction((txn) async {
        final map = sub.toMap();
        map.remove('id');
        map[DatabaseHelper.colSubWalletId] = walletId;
        newId = await txn.insert(DatabaseHelper.tableSubscriptions, map);
        
        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'subscription',
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
  Future<Either<AppFailure, Subscription?>> getSubscription(int id) async {
    try {
      final db = await _dbHelper.database;
      List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableSubscriptions,
        where: '${DatabaseHelper.colSubId} = ? AND ${DatabaseHelper.colSubIsDeleted} = 0',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
       return Right(Subscription.fromMap(maps.first));
      }
      return const Right(null);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Subscription>>> getAllSubscriptions(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableSubscriptions,
        where: '${DatabaseHelper.colSubWalletId} = ? AND ${DatabaseHelper.colSubIsDeleted} = 0',
        whereArgs: [walletId],
        orderBy: '${DatabaseHelper.colSubNextPaymentDate} ASC',
      );
      final subscriptions = List.generate(maps.length, (i) => Subscription.fromMap(maps[i]));
      return Right(subscriptions);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateSubscription(Subscription sub, int walletId) async {
    try {
      final db = await _dbHelper.database;
      int updatedRows = 0;
      await db.transaction((txn) async {
        final map = sub.toMap();
        map[DatabaseHelper.colSubWalletId] = walletId;
        updatedRows = await txn.update(
          DatabaseHelper.tableSubscriptions,
          map,
          where: '${DatabaseHelper.colSubId} = ?',
          whereArgs: [sub.id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'subscription',
          DatabaseHelper.colSyncEntityId: sub.id.toString(),
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
  Future<Either<AppFailure, int>> deleteSubscription(int id) async {
    try {
      final db = await _dbHelper.database;
      int deletedRows = 0;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        deletedRows = await txn.update(
          DatabaseHelper.tableSubscriptions,
          {
            DatabaseHelper.colSubIsDeleted: 1,
            DatabaseHelper.colSubUpdatedAt: now,
          },
          where: '${DatabaseHelper.colSubId} = ?',
          whereArgs: [id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'subscription',
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