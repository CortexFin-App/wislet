import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/data/static/default_categories.dart';
import 'package:wislet/models/category.dart';
import 'package:wislet/services/auth_service.dart';
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:wislet/utils/database_helper.dart';

class LocalCategoryRepositoryImpl implements CategoryRepository {
  LocalCategoryRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  @override
  Future<void> addDefaultCategories(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final authService = getIt<AuthService>();
      final userId = authService.currentUser?.id ?? '1';

      await db.transaction((txn) async {
        for (final catData in defaultCategories) {
          final categoryMap = {
            DatabaseHelper.colCategoryName: catData['name'],
            DatabaseHelper.colCategoryType: catData['type'],
            DatabaseHelper.colCategoryWalletId: walletId,
            DatabaseHelper.colCategoryUserId: userId,
          };
          await txn.insert(
            DatabaseHelper.tableCategories,
            categoryMap,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      });
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
    }
  }

  @override
  Future<Either<AppFailure, int>> createCategory(
    Category category,
    int walletId,
  ) async {
    try {
      final db = await _dbHelper.database;
      var newId = -1;
      await db.transaction((txn) async {
        final map = category.toMap();
        map[DatabaseHelper.colCategoryWalletId] = walletId;
        newId = await txn.insert(
          DatabaseHelper.tableCategories,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'category',
          DatabaseHelper.colSyncEntityId: newId.toString(),
          DatabaseHelper.colSyncActionType: 'create',
          DatabaseHelper.colSyncPayload: jsonEncode(map),
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
  Future<Either<AppFailure, int>> updateCategory(Category category) async {
    try {
      final db = await _dbHelper.database;
      var updatedRows = 0;
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
  Future<Either<AppFailure, int>> deleteCategory(int id) async {
    try {
      final db = await _dbHelper.database;
      var deletedRows = 0;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        deletedRows = await txn.update(
          DatabaseHelper.tableCategories,
          {
            DatabaseHelper.colCategoryIsDeleted: 1,
            DatabaseHelper.colCategoryUpdatedAt: now,
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
          DatabaseHelper.colSyncStatus: 'pending',
        });
      });
      return Right(deletedRows);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Category>>> getAllCategories(
    int walletId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableCategories,
        where:
            '${DatabaseHelper.colCategoryWalletId} = ? AND ${DatabaseHelper.colCategoryIsDeleted} = 0',
        whereArgs: [walletId],
      );
      return Right(
        List.generate(maps.length, (i) => Category.fromMap(maps[i])),
      );
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Category>>> getCategoriesByType(
    int walletId,
    CategoryType type,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableCategories,
        where:
            '${DatabaseHelper.colCategoryWalletId} = ? AND ${DatabaseHelper.colCategoryType} = ? AND ${DatabaseHelper.colCategoryIsDeleted} = 0',
        whereArgs: [walletId, type.name],
      );
      return Right(
        List.generate(maps.length, (i) => Category.fromMap(maps[i])),
      );
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, String>> getCategoryNameById(
    int categoryId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableCategories,
        columns: [DatabaseHelper.colCategoryName],
        where: '${DatabaseHelper.colCategoryId} = ?',
        whereArgs: [categoryId],
      );
      if (maps.isNotEmpty) {
        final val = maps.first[DatabaseHelper.colCategoryName];
        if (val is String && val.isNotEmpty) {
          return Right(val);
        }
      }
      return const Right('Категорія не знайдена');
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Category>> createCategoryFromMap(
    Map<String, dynamic> categoryMap,
    int walletId,
  ) async {
    try {
      final category = Category.fromMap(categoryMap);
      final result = await createCategory(category, walletId);
      return result.fold(
        Left.new,
        (newId) => Right(
          Category(
            id: newId,
            name: category.name,
            type: category.type,
            bucket: category.bucket,
          ),
        ),
      );
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}
