import 'package:sage_wallet_reborn/models/notification_history_item.dart';

abstract class NotificationRepository {
  Future<void> addNotificationToHistory(
    String title,
    String body,
    String? payload,
  );

  Future<List<NotificationHistoryItem>> getNotificationHistory();

  Future<int> markNotificationAsRead(int id);

  Future<int> clearNotificationHistory();
}
