import 'package:sage_wallet_reborn/models/notification_history_item.dart';
import 'package:sage_wallet_reborn/data/repositories/notification_repository.dart';

class ApiNotificationRepositoryImpl implements NotificationRepository {
  ApiNotificationRepositoryImpl();

  @override
  Future<void> addNotificationToHistory(String title, String body, String? payload) async {
    return;
  }

  @override
  Future<List<NotificationHistoryItem>> getNotificationHistory() async {
    return [];
  }

  @override
  Future<int> markNotificationAsRead(int id) async {
    return 0;
  }

  @override
  Future<int> clearNotificationHistory() async {
    return 0;
  }
}