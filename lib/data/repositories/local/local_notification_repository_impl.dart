import 'package:sage_wallet_reborn/models/notification_history_item.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/notification_repository.dart';

class LocalNotificationRepositoryImpl implements NotificationRepository {
  final DatabaseHelper _dbHelper;

  LocalNotificationRepositoryImpl(this._dbHelper);

  @override
  Future<void> addNotificationToHistory(String title, String body, String? payload) async {
    final db = await _dbHelper.database;
    await db.insert(DatabaseHelper.tableNotificationHistory, {
      DatabaseHelper.colNotificationTitle: title,
      DatabaseHelper.colNotificationBody: body,
      DatabaseHelper.colNotificationPayload: payload,
      DatabaseHelper.colNotificationTimestamp: DateTime.now().toIso8601String(),
      DatabaseHelper.colNotificationIsRead: 0,
    });
  }

  @override
  Future<List<NotificationHistoryItem>> getNotificationHistory() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableNotificationHistory, 
      orderBy: '${DatabaseHelper.colNotificationTimestamp} DESC'
    );
    return maps.map((map) => NotificationHistoryItem.fromMap(map)).toList();
  }

  @override
  Future<int> markNotificationAsRead(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableNotificationHistory,
      {DatabaseHelper.colNotificationIsRead: 1},
      where: '${DatabaseHelper.colNotificationId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> clearNotificationHistory() async {
    final db = await _dbHelper.database;
    return await db.delete(DatabaseHelper.tableNotificationHistory);
  }
}