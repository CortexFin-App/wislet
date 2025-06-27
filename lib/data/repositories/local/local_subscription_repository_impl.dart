import 'package:sage_wallet_reborn/models/subscription_model.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/subscription_repository.dart';

class LocalSubscriptionRepositoryImpl implements SubscriptionRepository {
  final DatabaseHelper _dbHelper;

  LocalSubscriptionRepositoryImpl(this._dbHelper);

  @override
  Future<int> createSubscription(Subscription sub, int walletId) async {
    final db = await _dbHelper.database;
    final map = sub.toMap();
    map[DatabaseHelper.colSubWalletId] = walletId;
    return await db.insert(DatabaseHelper.tableSubscriptions, map);
  }

  @override
  Future<Subscription?> getSubscription(int id) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableSubscriptions,
      where: '${DatabaseHelper.colSubId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Subscription.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<Subscription>> getAllSubscriptions(int walletId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableSubscriptions,
      where: '${DatabaseHelper.colSubWalletId} = ?',
      whereArgs: [walletId],
      orderBy: '${DatabaseHelper.colSubNextPaymentDate} ASC',
    );
    return List.generate(maps.length, (i) {
      return Subscription.fromMap(maps[i]);
    });
  }

  @override
  Future<int> updateSubscription(Subscription sub, int walletId) async {
    final db = await _dbHelper.database;
    final map = sub.toMap();
    map[DatabaseHelper.colSubWalletId] = walletId;
    return await db.update(
      DatabaseHelper.tableSubscriptions,
      map,
      where: '${DatabaseHelper.colSubId} = ?',
      whereArgs: [sub.id],
    );
  }

  @override
  Future<int> deleteSubscription(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableSubscriptions,
      where: '${DatabaseHelper.colSubId} = ?',
      whereArgs: [id],
    );
  }
}