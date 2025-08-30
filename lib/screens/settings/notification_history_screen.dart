import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/notification_repository.dart';
import 'package:sage_wallet_reborn/models/notification_history_item.dart';
import 'package:sage_wallet_reborn/screens/financial_goals/financial_goals_list_screen.dart';
import 'package:sage_wallet_reborn/services/navigation_service.dart';
import 'package:sage_wallet_reborn/widgets/scaffold/patterned_scaffold.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final NotificationRepository _notificationRepository =
      getIt<NotificationRepository>();
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

  Future<void> _handleNotificationTap(String? payload, int id) async {
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
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FinancialGoalsListScreen(goalIdToHighlight: goalId),
            ),
          );
        }
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('РћС‡РёСЃС‚РёС‚Рё С–СЃС‚РѕСЂС–СЋ?'),
        content: const Text(
          'Р’СЃСЏ С–СЃС‚РѕСЂС–СЏ СЃРїРѕРІС–С‰РµРЅСЊ Р±СѓРґРµ РІРёРґР°Р»РµРЅР°. Р¦СЋ РґС–СЋ РЅРµРјРѕР¶Р»РёРІРѕ СЃРєР°СЃСѓРІР°С‚Рё.',
        ),
        actions: [
          TextButton(
            child: const Text('РЎРєР°СЃСѓРІР°С‚Рё'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('РћС‡РёСЃС‚РёС‚Рё'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _notificationRepository.clearNotificationHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PatternedScaffold(
      appBar: AppBar(
        title: const Text('Р†СЃС‚РѕСЂС–СЏ СЃРїРѕРІС–С‰РµРЅСЊ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'РћС‡РёСЃС‚РёС‚Рё С–СЃС‚РѕСЂС–СЋ',
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
            return Center(
              child: Text(
                'РџРѕРјРёР»РєР° Р·Р°РІР°РЅС‚Р°Р¶РµРЅРЅСЏ С–СЃС‚РѕСЂС–С—: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 80,
                      color:
                          Theme.of(context).colorScheme.onSurface.withAlpha(77),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Р†СЃС‚РѕСЂС–СЏ СЃРїРѕРІС–С‰РµРЅСЊ РїРѕСЂРѕР¶РЅСЏ',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(
                  notification.isRead
                      ? Icons.drafts_outlined
                      : Icons.notifications_active,
                  color: notification.isRead
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${notification.body}\n${DateFormat('dd.MM.yyyy HH:mm').format(notification.timestamp)}',
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
