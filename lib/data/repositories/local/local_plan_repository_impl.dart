import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/failures.dart';
import '../../../models/plan.dart';
import '../../../models/plan_view_data.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../plan_repository.dart';

class LocalPlanRepositoryImpl implements PlanRepository {
  final DatabaseHelper _dbHelper;

  LocalPlanRepositoryImpl(this._dbHelper);

  @override
  Future<Either<AppFailure, int>> createPlan(Plan plan, int walletId) async {
    try {
      final db = await _dbHelper.database;
      int newId = -1;
      await db.transaction((txn) async {
        final map = plan.toMap();
        map[DatabaseHelper.colPlanWalletId] = walletId;
        newId = await txn.insert(DatabaseHelper.tablePlans, map, conflictAlgorithm: ConflictAlgorithm.replace);

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'plan',
          DatabaseHelper.colSyncEntityId: newId.toString(),
          DatabaseHelper.colSyncActionType: 'create',
          DatabaseHelper.colSyncPayload: jsonEncode(map),
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
  Future<Either<AppFailure, int>> updatePlan(Plan plan) async {
    try {
      final db = await _dbHelper.database;
      int updatedRows = 0;
      await db.transaction((txn) async {
        final map = plan.toMap();
        updatedRows = await txn.update(
          DatabaseHelper.tablePlans,
          map,
          where: '${DatabaseHelper.colPlanId} = ?',
          whereArgs: [plan.id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'plan',
          DatabaseHelper.colSyncEntityId: plan.id.toString(),
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
  Future<Either<AppFailure, int>> deletePlan(int id) async {
    try {
      final db = await _dbHelper.database;
      int deletedRows = 0;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        deletedRows = await txn.update(
          DatabaseHelper.tablePlans,
          {
            DatabaseHelper.colPlanIsDeleted: 1,
            DatabaseHelper.colPlanUpdatedAt: now,
          },
          where: '${DatabaseHelper.colPlanId} = ?',
          whereArgs: [id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'plan',
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

  @override
  Future<Either<AppFailure, List<Plan>>> getPlansForPeriod(int walletId, DateTime startDate, DateTime endDate) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePlans,
        where: '${DatabaseHelper.colPlanWalletId} = ? AND date(${DatabaseHelper.colPlanStartDate}) <= date(?) AND date(${DatabaseHelper.colPlanEndDate}) >= date(?) AND ${DatabaseHelper.colPlanIsDeleted} = 0',
        whereArgs: [walletId, endDate.toIso8601String(), startDate.toIso8601String()],
      );
      return Right(maps.map((map) => Plan.fromMap(map)).toList());
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<PlanViewData>>> getPlansWithCategoryDetails(int walletId, {String? orderBy}) async {
    try {
      final db = await _dbHelper.database;
      const String defaultOrderBy = "p.${DatabaseHelper.colPlanStartDate} DESC, c.${DatabaseHelper.colCategoryName} ASC, p.${DatabaseHelper.colPlanId} DESC";
      final String sql = '''
        SELECT 
          p.${DatabaseHelper.colPlanId}, p.${DatabaseHelper.colPlanCategoryId}, p.${DatabaseHelper.colPlanOriginalAmount},
          p.${DatabaseHelper.colPlanOriginalCurrencyCode}, p.${DatabaseHelper.colPlanAmountInBaseCurrency},
          p.${DatabaseHelper.colPlanExchangeRateUsed}, p.${DatabaseHelper.colPlanStartDate}, p.${DatabaseHelper.colPlanEndDate}, 
          c.${DatabaseHelper.colCategoryName} AS categoryName, c.${DatabaseHelper.colCategoryType} AS categoryType 
        FROM ${DatabaseHelper.tablePlans} p
        INNER JOIN ${DatabaseHelper.tableCategories} c ON p.${DatabaseHelper.colPlanCategoryId} = c.${DatabaseHelper.colCategoryId}
        WHERE p.${DatabaseHelper.colPlanWalletId} = ? AND p.${DatabaseHelper.colPlanIsDeleted} = 0
        ORDER BY ${orderBy ?? defaultOrderBy}
      ''';
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [walletId]);
      return Right(maps.map((map) => PlanViewData.fromMap(map)).toList());
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
  
  @override
  Future<Either<AppFailure, List<PlanViewData>>> getActivePlansForCategoryAndDate(int walletId, int categoryId, DateTime date) async {
    try {
      final db = await _dbHelper.database;
      final String dateOnlyString = DateFormat('yyyy-MM-dd').format(date);
      const String sql = '''
        SELECT 
          p.${DatabaseHelper.colPlanId}, p.${DatabaseHelper.colPlanCategoryId}, p.${DatabaseHelper.colPlanOriginalAmount},
          p.${DatabaseHelper.colPlanOriginalCurrencyCode}, p.${DatabaseHelper.colPlanAmountInBaseCurrency},
          p.${DatabaseHelper.colPlanExchangeRateUsed}, p.${DatabaseHelper.colPlanStartDate}, p.${DatabaseHelper.colPlanEndDate}, 
          c.${DatabaseHelper.colCategoryName} AS categoryName, c.${DatabaseHelper.colCategoryType} AS categoryType 
        FROM ${DatabaseHelper.tablePlans} p
        INNER JOIN ${DatabaseHelper.tableCategories} c ON p.${DatabaseHelper.colPlanCategoryId} = c.${DatabaseHelper.colCategoryId}
        WHERE p.${DatabaseHelper.colPlanWalletId} = ?
          AND p.${DatabaseHelper.colPlanCategoryId} = ? 
          AND date(p.${DatabaseHelper.colPlanStartDate}) <= ? 
          AND date(p.${DatabaseHelper.colPlanEndDate}) >= ?
          AND p.${DatabaseHelper.colPlanIsDeleted} = 0
      ''';
      
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [walletId, categoryId, dateOnlyString, dateOnlyString]);
      return Right(List.generate(maps.length, (i) => PlanViewData.fromMap(maps[i])));
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}