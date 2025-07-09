import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../models/wallet.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../wallet_repository.dart';
import '../../../models/user.dart';
import '../../../data/static/default_categories.dart';

class LocalWalletRepositoryImpl implements WalletRepository {
  final DatabaseHelper _dbHelper;
  LocalWalletRepositoryImpl(this._dbHelper);

  Future<List<WalletUser>> _getMembersForWallet(DatabaseExecutor db, int walletId) async {
    final List<Map<String, dynamic>> membersMaps = await db.rawQuery('''
      SELECT wu.role, u.id, u.name 
      FROM ${DatabaseHelper.tableWalletUsers} wu
      JOIN ${DatabaseHelper.tableUsers} u ON wu.${DatabaseHelper.colWalletUsersUserId} = u.${DatabaseHelper.colUserId}
      WHERE wu.${DatabaseHelper.colWalletUsersWalletId} = ?
    ''', [walletId]);
    return membersMaps.map((m) {
      return WalletUser(
        user: User.fromMap(m),
        role: m['role'],
      );
    }).toList();
  }

  @override
  Future<Either<AppFailure, List<Wallet>>> getAllWallets() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> walletMaps = await db.query(
        DatabaseHelper.tableWallets,
        where: '${DatabaseHelper.colWalletIsDeleted} = 0'
      );
      final List<Wallet> wallets = [];
      for (var walletMap in walletMaps) {
        final members = await _getMembersForWallet(db, walletMap[DatabaseHelper.colWalletId]);
        final wallet = Wallet.fromMap(walletMap);
        wallet.members = members;
        wallets.add(wallet);
      }
      return Right(wallets);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Wallet?>> getWallet(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableWallets,
        where: '${DatabaseHelper.colWalletId} = ? AND ${DatabaseHelper.colWalletIsDeleted} = 0',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        final wallet = Wallet.fromMap(maps.first);
        wallet.members = await _getMembersForWallet(db, id);
        return Right(wallet);
      }
      return const Right(null);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createWallet({required String name, required String ownerUserId, bool isDefault = false}) async {
    try {
      final db = await _dbHelper.database;
      int newId = -1;
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
          'role': 'owner'
        });
        
        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'wallet',
          DatabaseHelper.colSyncEntityId: newId.toString(),
          DatabaseHelper.colSyncActionType: 'create',
          DatabaseHelper.colSyncPayload: jsonEncode(walletMap..['id'] = newId),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(newId);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateWallet(Wallet wallet) async {
    try {
      final db = await _dbHelper.database;
      int updatedRows = 0;
      await db.transaction((txn) async {
        final map = wallet.toMapForDb();
        updatedRows = await txn.update(
          DatabaseHelper.tableWallets,
          map,
          where: '${DatabaseHelper.colWalletId} = ?',
          whereArgs: [wallet.id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'wallet',
          DatabaseHelper.colSyncEntityId: wallet.id.toString(),
          DatabaseHelper.colSyncActionType: 'update',
          DatabaseHelper.colSyncPayload: jsonEncode(map),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(updatedRows);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteWallet(int walletId) async {
    try {
      final db = await _dbHelper.database;
      int deletedRows = 0;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        deletedRows = await txn.update(
          DatabaseHelper.tableWallets,
          {
            DatabaseHelper.colWalletIsDeleted: 1,
            DatabaseHelper.colWalletUpdatedAt: now
          },
          where: '${DatabaseHelper.colWalletId} = ?',
          whereArgs: [walletId],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'wallet',
          DatabaseHelper.colSyncEntityId: walletId.toString(),
          DatabaseHelper.colSyncActionType: 'delete',
          DatabaseHelper.colSyncPayload: jsonEncode({'id': walletId}),
          DatabaseHelper.colSyncTimestamp: now,
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(deletedRows);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> createInitialWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool alreadyCreated = prefs.getBool(AppConstants.prefsKeyInitialWalletCreated) ?? false;
      if (alreadyCreated) {
        return const Right(null);
      }
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        const userId = '1';
        await txn.insert(DatabaseHelper.tableUsers, {'id': userId, 'name': 'Основний користувач'}, conflictAlgorithm: ConflictAlgorithm.ignore);
        int walletId = await txn.insert(DatabaseHelper.tableWallets, {
          'name': 'Особистий гаманець',
          'isDefault': 1,
          'ownerUserId': userId,
          'updated_at': DateTime.now().toIso8601String(),
          'is_deleted': 0
        });
        await txn.insert(DatabaseHelper.tableWalletUsers,
            {'walletId': walletId, 'userId': userId, 'role': 'owner'});
        for (var catData in defaultCategories) {
          final categoryMap = Map<String, dynamic>.from(catData);
          categoryMap[DatabaseHelper.colCategoryWalletId] = walletId;
          await txn.insert(DatabaseHelper.tableCategories, categoryMap,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });
      await prefs.setBool(AppConstants.prefsKeyInitialWalletCreated, true);
      return const Right(null);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> changeUserRole(int walletId, String userId, String newRole) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        DatabaseHelper.tableWalletUsers,
        {'role': newRole},
        where:
            '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
        whereArgs: [walletId, userId],
      );
      return const Right(null);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> removeUserFromWallet(int walletId, String userId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        DatabaseHelper.tableWalletUsers,
        where:
            '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
        whereArgs: [walletId, userId],
      );
      return const Right(null);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}