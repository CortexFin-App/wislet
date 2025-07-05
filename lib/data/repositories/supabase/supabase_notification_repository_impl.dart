import '../../../models/notification_history_item.dart';
import '../notification_repository.dart';

class SupabaseNotificationRepositoryImpl implements NotificationRepository {
  SupabaseNotificationRepositoryImpl();
  
  @override
  Future<void> addNotificationToHistory(String title, String body, String? payload) async {
    // Client-side notifications are not stored on the server.
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