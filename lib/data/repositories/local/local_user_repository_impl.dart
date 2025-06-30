import 'package:sage_wallet_reborn/models/user.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/user_repository.dart';

class LocalUserRepositoryImpl implements UserRepository {
  final DatabaseHelper _dbHelper;
  LocalUserRepositoryImpl(this._dbHelper);

  @override
  Future<int> createDefaultUser() async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableUsers, {'name': 'Основний користувач', 'id': '1'}); // Додаємо ID за замовчуванням
  }
  
  @override
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query(DatabaseHelper.tableUsers);
    return maps.map((map) => User.fromMap(map)).toList();
  }

  @override
  Future<List<User>> getUsersForWallet(int walletId) async {
    final db = await _dbHelper.database;
    const String sql = '''
      SELECT u.* FROM ${DatabaseHelper.tableUsers} u
      INNER JOIN ${DatabaseHelper.tableWalletUsers} wu ON u.${DatabaseHelper.colUserId} = wu.${DatabaseHelper.colWalletUsersUserId}
      WHERE wu.${DatabaseHelper.colWalletUsersWalletId} = ?
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [walletId]);
    return maps.map((map) => User.fromMap(map)).toList();
  }

  @override
  Future<int> addUserToWallet(int walletId, String userId, String role) async {
    final db = await _dbHelper.database;
    return await db.insert(
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
    return await db.delete(
      DatabaseHelper.tableWalletUsers,
      where:
          '${DatabaseHelper.colWalletUsersWalletId} = ? AND ${DatabaseHelper.colWalletUsersUserId} = ?',
      whereArgs: [walletId, userId],
    );
  }

  @override
  Future<int> updateUserRoleInWallet(
      int walletId, String userId, String newRole) async {
    final db = await _dbHelper.database;
    return await db.update(
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