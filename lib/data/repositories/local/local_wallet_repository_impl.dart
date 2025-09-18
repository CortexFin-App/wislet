import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/constants/app_constants.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/wallet_repository.dart';
import 'package:wislet/data/static/default_categories.dart';
import 'package:wislet/models/user.dart';
import 'package:wislet/models/wallet.dart';
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:wislet/utils/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class LocalWalletRepositoryImpl implements WalletRepository {
  LocalWalletRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<List<WalletUser>> _getMembersForWallet(
    DatabaseExecutor db,
    int walletId,
  ) async {
    final membersMaps = await db.rawQuery(
      '''
      SELECT wu.${DatabaseHelper.colWalletUsersRole}, u.${DatabaseHelper.colUserId}, u.${DatabaseHelper.colUserName}
      FROM ${DatabaseHelper.tableWalletUsers} wu
      JOIN ${DatabaseHelper.tableUsers} u ON wu.${DatabaseHelper.colWalletUsersUserId} = u.${DatabaseHelper.colUserId}
      WHERE wu.${DatabaseHelper.colWalletUsersWalletId} = ?
    ''',
      [walletId],
    );
    return membersMaps.map((m) {
      return WalletUser(
        user: User.fromMap(m),
        role: m[DatabaseHelper.colWalletUsersRole]! as String,
      );
    }).toList();
  }

  @override
  Future<Either<AppFailure, List<Wallet>>> getAllWallets() async {
    try {
      final db = await _dbHelper.database;
      final walletMaps = await db.query(
        DatabaseHelper.tableWallets,
        where: '${DatabaseHelper.colWalletIsDeleted} = 0',
      );
      final wallets = <Wallet>[];
      for (final walletMap in walletMaps) {
        final members = await _getMembersForWallet(
          db,
          walletMap[DatabaseHelper.colWalletId]! as int,
        );
        final wallet = Wallet.fromMap(walletMap)..members = members;
        wallets.add(wallet);
      }
      return Right(wallets);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Wallet?>> getWallet(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableWallets,
        where:
            '${DatabaseHelper.colWalletId} = ? AND ${DatabaseHelper.colWalletIsDeleted} = 0',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        final wallet = Wallet.fromMap(maps.first)
          ..members = await _getMembersForWallet(db, id);
        return Right(wallet);
      }
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createWallet({
    required String name,
    required String ownerUserId,
    bool isDefault = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      var newId = -1;
      await db.transaction((txn) async {
        final walletMap = {
          DatabaseHelper.colWalletName: name,
          DatabaseHelper.colWalletIsDefault: isDefault ? 1 : 0,
          DatabaseHelper.colWalletOwnerUserId: ownerUserId,
          DatabaseHelper.colWalletUpdatedAt: DateTime.now().toIso8601String(),
          DatabaseHelper.colWalletIsDeleted: 0,
        };
        newId = await txn.insert(DatabaseHelper.tableWallets, walletMap);

        await txn.insert(DatabaseHelper.tableWalletUsers, {
          DatabaseHelper.colWalletUsersWalletId: newId,
          DatabaseHelper.colWalletUsersUserId: ownerUserId,
          DatabaseHelper.colWalletUsersRole: 'owner',
        });

        for (final catData in defaultCategories) {
          final categoryMap = {
            DatabaseHelper.colCategoryName: catData['name'],
            DatabaseHelper.colCategoryType: catData['type'],
            DatabaseHelper.colCategoryWalletId: newId,
            DatabaseHelper.colCategoryUserId: ownerUserId,
          };
          await txn.insert(
            DatabaseHelper.tableCategories,
            categoryMap,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      });
      return Right(newId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateWallet(Wallet wallet) async {
    try {
      final db = await _dbHelper.database;
      final map = wallet.toMapForDb();
      final updatedRows = await db.update(
        DatabaseHelper.tableWallets,
        map,
        where: '${DatabaseHelper.colWalletId} = ?',
        whereArgs: [wallet.id],
      );
      return Right(updatedRows);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteWallet(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      final deletedRows = await db.update(
        DatabaseHelper.tableWallets,
        {
          DatabaseHelper.colWalletIsDeleted: 1,
          DatabaseHelper.colWalletUpdatedAt: now,
        },
        where: '${DatabaseHelper.colWalletId} = ?',
        whereArgs: [walletId],
      );
      return Right(deletedRows);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> createInitialWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(AppConstants.isInitialSetupComplete) ?? false) {
        return const Right(null);
      }

      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.insert(
          DatabaseHelper.tableUsers,
          {
            DatabaseHelper.colUserName: 'Основний користувач',
            DatabaseHelper.colUserId: '1',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        const userId = '1';
        final walletMap = {
          DatabaseHelper.colWalletName: 'Особистий гаманець',
          DatabaseHelper.colWalletIsDefault: 1,
          DatabaseHelper.colWalletOwnerUserId: userId,
          DatabaseHelper.colWalletUpdatedAt: DateTime.now().toIso8601String(),
          DatabaseHelper.colWalletIsDeleted: 0,
        };
        final newWalletId =
            await txn.insert(DatabaseHelper.tableWallets, walletMap);

        await txn.insert(DatabaseHelper.tableWalletUsers, {
          DatabaseHelper.colWalletUsersWalletId: newWalletId,
          DatabaseHelper.colWalletUsersUserId: userId,
          DatabaseHelper.colWalletUsersRole: 'owner',
        });

        for (final catData in defaultCategories) {
          final categoryMap = {
            DatabaseHelper.colCategoryName: catData['name'],
            DatabaseHelper.colCategoryType: catData['type'],
            DatabaseHelper.colCategoryWalletId: newWalletId,
            DatabaseHelper.colCategoryUserId: userId,
          };
          await txn.insert(
            DatabaseHelper.tableCategories,
            categoryMap,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      });

      await prefs.setBool(AppConstants.isInitialSetupComplete, true);
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> changeUserRole(
    int walletId,
    String userId,
    String newRole,
  ) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        DatabaseHelper.tableWalletUsers,
        {DatabaseHelper.colWalletUsersRole: newRole},
        where:
            '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
        whereArgs: [walletId, userId],
      );
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> removeUserFromWallet(
    int walletId,
    String userId,
  ) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        DatabaseHelper.tableWalletUsers,
        where:
            '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
        whereArgs: [walletId, userId],
      );
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}
