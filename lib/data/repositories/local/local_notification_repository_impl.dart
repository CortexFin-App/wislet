import 'package:wislet/data/repositories/notification_repository.dart';
import 'package:wislet/models/notification_history_item.dart';
import 'package:wislet/utils/database_helper.dart';

class LocalNotificationRepositoryImpl implements NotificationRepository {
  LocalNotificationRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  @override
  Future<void> addNotificationToHistory(
    String title,
    String body,
    String? payload,
  ) async {
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
    final maps = await db.query(
      DatabaseHelper.tableNotificationHistory,
      orderBy: '${DatabaseHelper.colNotificationTimestamp} DESC',
    );
    return maps.map(NotificationHistoryItem.fromMap).toList();
  }

  @override
  Future<int> markNotificationAsRead(int id) async {
    final db = await _dbHelper.database;
    return db.update(
      DatabaseHelper.tableNotificationHistory,
      {DatabaseHelper.colNotificationIsRead: 1},
      where: '${DatabaseHelper.colNotificationId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> clearNotificationHistory() async {
    final db = await _dbHelper.database;
    return db.delete(DatabaseHelper.tableNotificationHistory);
  }
}
