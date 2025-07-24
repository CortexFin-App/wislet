import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/notification_repository.dart';
import '../../models/notification_history_item.dart';
import '../../services/navigation_service.dart';
import '../../screens/financial_goals/financial_goals_list_screen.dart';
import '../../widgets/scaffold/patterned_scaffold.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final NotificationRepository _notificationRepository = getIt<NotificationRepository>();
  late Future<List<NotificationHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    if (mounted) {
      setState(() {
        _historyFuture = _notificationRepository.getNotificationHistory();
      });
    }
  }

  void _handleNotificationTap(String? payload, int id) async {
    await _notificationRepository.markNotificationAsRead(id);
    _loadHistory();
    if (payload != null && payload.isNotEmpty) {
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      final uri = Uri.parse(payload);
      final path = uri.pathSegments;
      if (path.isEmpty) return;
      if (path[0] == 'goal' && path.length > 1) {
        final goalId = int.tryParse(path[1]);
        if (goalId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => FinancialGoalsListScreen(goalIdToHighlight: goalId)));
        }
      }
    }
  }

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Очистити історію?'),
              content: const Text('Вся історія сповіщень буде видалена. Цю дію неможливо скасувати.'),
              actions: [
                TextButton(
                  child: const Text('Скасувати'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Очистити'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ));

    if (confirm == true) {
      await _notificationRepository.clearNotificationHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PatternedScaffold(
      appBar: AppBar(
        title: const Text('Історія сповіщень'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Очистити історію',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Помилка завантаження історії: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Theme.of(context).colorScheme.onSurface.withAlpha(77)),
                    const SizedBox(height: 16),
                    Text('Історія сповіщень порожня', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(
                  notification.isRead ? Icons.drafts_outlined : Icons.notifications_active,
                  color: notification.isRead ? Theme.of(context).disabledColor : Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Text(
                  "${notification.body}\n${DateFormat('dd.MM.yyyy HH:mm').format(notification.timestamp)}",
                ),
                isThreeLine: true,
                onTap: () => _handleNotificationTap(
                  notification.payload,
                  notification.id!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}