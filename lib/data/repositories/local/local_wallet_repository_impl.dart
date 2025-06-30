import 'package:sage_wallet_reborn/models/wallet.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/wallet_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sage_wallet_reborn/models/user.dart';
import 'package:sage_wallet_reborn/data/static/default_categories.dart';

class LocalWalletRepositoryImpl implements WalletRepository {
  final DatabaseHelper _dbHelper;
  LocalWalletRepositoryImpl(this._dbHelper);

  Future<List<WalletUser>> _getMembersForWallet(
      DatabaseExecutor db, int walletId) async {
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
  Future<List<Wallet>> getAllWallets() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> walletMaps =
        await db.query(DatabaseHelper.tableWallets);
    final List<Wallet> wallets = [];
    for (var walletMap in walletMaps) {
      final members =
          await _getMembersForWallet(db, walletMap[DatabaseHelper.colWalletId]);
      final wallet = Wallet.fromMap(walletMap);
      wallet.members = members;
      wallets.add(wallet);
    }
    return wallets;
  }

  @override
  Future<Wallet?> getWallet(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableWallets,
      where: '${DatabaseHelper.colWalletId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final wallet = Wallet.fromMap(maps.first);
      wallet.members = await _getMembersForWallet(db, id);
      return wallet;
    }
    return null;
  }

  @override
  Future<int> createWallet(
      {required String name,
      required String ownerUserId,
      bool isDefault = false}) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final walletMap = {
        DatabaseHelper.colWalletName: name,
        DatabaseHelper.colWalletIsDefault: isDefault ? 1 : 0,
        DatabaseHelper.colWalletOwnerUserId: ownerUserId,
      };
      final walletId = await txn.insert(DatabaseHelper.tableWallets, walletMap);
      await txn.insert(DatabaseHelper.tableWalletUsers, {
        DatabaseHelper.colWalletUsersWalletId: walletId,
        DatabaseHelper.colWalletUsersUserId: ownerUserId,
        'role': 'owner'
      });
      return walletId;
    });
  }

  @override
  Future<void> createInitialWallet() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      const userId = '1'; // Використовуємо String '1' для локального користувача
      await txn.insert(DatabaseHelper.tableUsers, {'id': userId, 'name': 'Основний користувач'}, conflictAlgorithm: ConflictAlgorithm.ignore);
      int walletId = await txn.insert(DatabaseHelper.tableWallets, {
        'name': 'Особистий гаманець',
        'isDefault': 1,
        'ownerUserId': userId
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
  }

  @override
  Future<int> updateWallet(Wallet wallet) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableWallets,
      wallet.toMapForDb(),
      where: '${DatabaseHelper.colWalletId} = ?',
      whereArgs: [wallet.id],
    );
  }

  @override
  Future<int> deleteWallet(int walletId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableWallets,
      where: '${DatabaseHelper.colWalletId} = ?',
      whereArgs: [walletId],
    );
  }

  @override
  Future<void> changeUserRole(int walletId, String userId, String newRole) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableWalletUsers,
      {'role': newRole},
      where:
          '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
      whereArgs: [walletId, userId],
    );
  }

  @override
  Future<void> removeUserFromWallet(int walletId, String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableWalletUsers,
      where:
          '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
      whereArgs: [walletId, userId],
    );
  }
}