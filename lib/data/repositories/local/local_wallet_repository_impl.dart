import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../models/wallet.dart';
import '../../../models/user.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../wallet_repository.dart';
import '../../static/default_categories.dart';

class LocalWalletRepositoryImpl implements WalletRepository {
  final DatabaseHelper _dbHelper;

  LocalWalletRepositoryImpl(this._dbHelper);

  Future<List<WalletUser>> _getMembersForWallet(DatabaseExecutor db, int walletId) async {
    final List<Map<String, dynamic>> membersMaps = await db.rawQuery('''
      SELECT wu.${DatabaseHelper.colWalletUsersRole}, u.${DatabaseHelper.colUserId}, u.${DatabaseHelper.colUserName}
      FROM ${DatabaseHelper.tableWalletUsers} wu
      JOIN ${DatabaseHelper.tableUsers} u ON wu.${DatabaseHelper.colWalletUsersUserId} = u.${DatabaseHelper.colUserId}
      WHERE wu.${DatabaseHelper.colWalletUsersWalletId} = ?
    ''', [walletId]);
    return membersMaps.map((m) {
      return WalletUser(
        user: User.fromMap(m),
        role: m[DatabaseHelper.colWalletUsersRole],
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
  Future<Either<AppFailure, int>> createWallet(
      {required String name, required String ownerUserId, bool isDefault = false}) async {
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
          DatabaseHelper.colWalletUsersRole: 'owner'
        });

        for (var catData in defaultCategories) {
          final categoryMap = {
            DatabaseHelper.colCategoryName: catData['name'],
            DatabaseHelper.colCategoryType: catData['type'],
            DatabaseHelper.colCategoryWalletId: newId,
            DatabaseHelper.colCategoryUserId: ownerUserId,
          };
          await txn.insert(DatabaseHelper.tableCategories, categoryMap, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
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
      final map = wallet.toMapForDb();
      final updatedRows = await db.update(
        DatabaseHelper.tableWallets,
        map,
        where: '${DatabaseHelper.colWalletId} = ?',
        whereArgs: [wallet.id],
      );
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
      final now = DateTime.now().toIso8601String();
      final deletedRows = await db.update(
        DatabaseHelper.tableWallets,
        {
          DatabaseHelper.colWalletIsDeleted: 1,
          DatabaseHelper.colWalletUpdatedAt: now
        },
        where: '${DatabaseHelper.colWalletId} = ?',
        whereArgs: [walletId],
      );
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
      if (prefs.getBool(AppConstants.isInitialSetupComplete) ?? false) {
        return const Right(null);
      }
      
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.insert(
          DatabaseHelper.tableUsers,
          {DatabaseHelper.colUserName: 'Основний користувач', DatabaseHelper.colUserId: '1'},
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
        final newWalletId = await txn.insert(DatabaseHelper.tableWallets, walletMap);

        await txn.insert(DatabaseHelper.tableWalletUsers, {
          DatabaseHelper.colWalletUsersWalletId: newWalletId,
          DatabaseHelper.colWalletUsersUserId: userId,
          DatabaseHelper.colWalletUsersRole: 'owner'
        });

        for (var catData in defaultCategories) {
          final categoryMap = {
            DatabaseHelper.colCategoryName: catData['name'],
            DatabaseHelper.colCategoryType: catData['type'],
            DatabaseHelper.colCategoryWalletId: newWalletId,
            DatabaseHelper.colCategoryUserId: userId,
          };
          await txn.insert(DatabaseHelper.tableCategories, categoryMap, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });
      
      await prefs.setBool(AppConstants.isInitialSetupComplete, true);
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
        {DatabaseHelper.colWalletUsersRole: newRole},
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