import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/failures.dart';
import '../../../models/category.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../category_repository.dart';

class LocalCategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper _dbHelper;
  LocalCategoryRepositoryImpl(this._dbHelper);

  @override
  Future<Either<AppFailure, int>> createCategory(Category category, int walletId) async {
    try {
      final db = await _dbHelper.database;
      int newId = -1;
      await db.transaction((txn) async {
        final map = category.toMap();
        map[DatabaseHelper.colCategoryWalletId] = walletId;
        newId = await txn.insert(DatabaseHelper.tableCategories, map, conflictAlgorithm: ConflictAlgorithm.replace);
        
        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'category',
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
  Future<Either<AppFailure, int>> updateCategory(Category category) async {
    try {
      final db = await _dbHelper.database;
      int updatedRows = 0;
      await db.transaction((txn) async {
          final map = category.toMap();
          updatedRows = await txn.update(
            DatabaseHelper.tableCategories,
            map,
            where: '${DatabaseHelper.colCategoryId} = ?',
            whereArgs: [category.id],
          );

          await txn.insert(DatabaseHelper.tableSyncQueue, {
            DatabaseHelper.colSyncEntityType: 'category',
            DatabaseHelper.colSyncEntityId: category.id.toString(),
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
  Future<Either<AppFailure, int>> deleteCategory(int id) async {
     try {
      final db = await _dbHelper.database;
      int deletedRows = 0;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        deletedRows = await txn.update(
          DatabaseHelper.tableCategories,
          {
            DatabaseHelper.colCategoryIsDeleted: 1,
            DatabaseHelper.colCategoryUpdatedAt: now
          },
          where: '${DatabaseHelper.colCategoryId} = ?',
          whereArgs: [id],
        );
        
        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'category',
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
  Future<Either<AppFailure, List<Category>>> getAllCategories(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableCategories,
        where: '${DatabaseHelper.colCategoryWalletId} = ? AND ${DatabaseHelper.colCategoryIsDeleted} = 0',
        whereArgs: [walletId],
      );
      return Right(List.generate(maps.length, (i) => Category.fromMap(maps[i])));
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Category>>> getCategoriesByType(int walletId, CategoryType type) async {
     try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableCategories,
        where: '${DatabaseHelper.colCategoryWalletId} = ? AND ${DatabaseHelper.colCategoryType} = ? AND ${DatabaseHelper.colCategoryIsDeleted} = 0',
        whereArgs: [walletId, type.toString()],
      );
      return Right(List.generate(maps.length, (i) => Category.fromMap(maps[i])));
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, String>> getCategoryNameById(int categoryId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableCategories,
        columns: [DatabaseHelper.colCategoryName],
        where: '${DatabaseHelper.colCategoryId} = ?',
        whereArgs: [categoryId],
      );
      if (maps.isNotEmpty) {
        return Right(maps.first[DatabaseHelper.colCategoryName] as String);
      }
      return const Right('Категорія не знайдена');
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Category>> createCategoryFromMap(Map<String, dynamic> categoryMap, int walletId) async {
    try {
      final category = Category.fromMap(categoryMap);
      final result = await createCategory(category, walletId);
      return result.fold(
        (l) => Left(l), 
        (newId) => Right(
          Category(
            id: newId,
            name: category.name,
            type: category.type,
            bucket: category.bucket,
          )
        )
      );
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}