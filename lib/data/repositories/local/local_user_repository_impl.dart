import 'package:sqflite/sqflite.dart';
import 'package:wislet/data/repositories/user_repository.dart';
import 'package:wislet/models/user.dart';
import 'package:wislet/utils/database_helper.dart';

class LocalUserRepositoryImpl implements UserRepository {
  LocalUserRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  @override
  Future<int> createDefaultUser() async {
    final db = await _dbHelper.database;
    return db.insert(
      DatabaseHelper.tableUsers,
      {
        DatabaseHelper.colUserName: 'Основний користувач',
        DatabaseHelper.colUserId: '1',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final maps = await db.query(DatabaseHelper.tableUsers);
    return maps.map(User.fromMap).toList();
  }

  @override
  Future<List<User>> getUsersForWallet(int walletId) async {
    final db = await _dbHelper.database;
    const sql = '''
      SELECT u.* FROM ${DatabaseHelper.tableUsers} u
      INNER JOIN ${DatabaseHelper.tableWalletUsers} wu ON u.${DatabaseHelper.colUserId} = wu.${DatabaseHelper.colWalletUsersUserId}
      WHERE wu.${DatabaseHelper.colWalletUsersWalletId} = ?
    ''';
    final maps = await db.rawQuery(sql, [walletId]);
    return maps.map(User.fromMap).toList();
  }

  @override
  Future<int> addUserToWallet(int walletId, String userId, String role) async {
    final db = await _dbHelper.database;
    return db.insert(
      DatabaseHelper.tableWalletUsers,
      {
        DatabaseHelper.colWalletUsersWalletId: walletId,
        DatabaseHelper.colWalletUsersUserId: userId,
        DatabaseHelper.colWalletUsersRole: role,
      },
    );
  }

  @override
  Future<int> removeUserFromWallet(int walletId, String userId) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseHelper.tableWalletUsers,
      where:
          '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
      whereArgs: [walletId, userId],
    );
  }

  @override
  Future<int> updateUserRoleInWallet(
    int walletId,
    String userId,
    String newRole,
  ) async {
    final db = await _dbHelper.database;
    return db.update(
      DatabaseHelper.tableWalletUsers,
      {DatabaseHelper.colWalletUsersRole: newRole},
      where:
          '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
      whereArgs: [walletId, userId],
    );
  }

  @override
  Future<User?> getUser(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      where: '${DatabaseHelper.colUserId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
}
