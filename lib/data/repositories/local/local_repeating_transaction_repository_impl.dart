import 'package:sage_wallet_reborn/models/repeating_transaction_model.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/repeating_transaction_repository.dart';

class LocalRepeatingTransactionRepositoryImpl implements RepeatingTransactionRepository {
  final DatabaseHelper _dbHelper;

  LocalRepeatingTransactionRepositoryImpl(this._dbHelper);

  @override
  Future<int> createRepeatingTransaction(RepeatingTransaction rt, int walletId) async {
    final db = await _dbHelper.database;
    final map = rt.toMap();
    map[DatabaseHelper.colRtWalletId] = walletId;
    return await db.insert(DatabaseHelper.tableRepeatingTransactions, map);
  }

  @override
  Future<RepeatingTransaction?> getRepeatingTransaction(int id) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableRepeatingTransactions,
      where: '${DatabaseHelper.colRtId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return RepeatingTransaction.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<RepeatingTransaction>> getAllRepeatingTransactions(int walletId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableRepeatingTransactions,
      where: '${DatabaseHelper.colRtWalletId} = ?',
      whereArgs: [walletId],
      orderBy: '${DatabaseHelper.colRtNextDueDate} ASC',
    );
    return List.generate(maps.length, (i) {
      return RepeatingTransaction.fromMap(maps[i]);
    });
  }

  @override
  Future<int> updateRepeatingTransaction(RepeatingTransaction rt) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableRepeatingTransactions,
      rt.toMap(),
      where: '${DatabaseHelper.colRtId} = ?',
      whereArgs: [rt.id],
    );
  }

  @override
  Future<int> deleteRepeatingTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableRepeatingTransactions,
      where: '${DatabaseHelper.colRtId} = ?',
      whereArgs: [id],
    );
  }
}