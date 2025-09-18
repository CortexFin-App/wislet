import 'package:wislet/data/repositories/notification_repository.dart';
import 'package:wislet/models/notification_history_item.dart';

class SupabaseNotificationRepositoryImpl implements NotificationRepository {
  SupabaseNotificationRepositoryImpl();

  @override
  Future<void> addNotificationToHistory(
    String title,
    String body,
    String? payload,
  ) async {
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
