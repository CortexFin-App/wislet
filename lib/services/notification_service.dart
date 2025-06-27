import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:sage_wallet_reborn/data/repositories/notification_repository.dart';
import 'package:sage_wallet_reborn/screens/financial_goals/financial_goals_list_screen.dart';
import 'package:sage_wallet_reborn/services/navigation_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final NotificationRepository _notificationRepository;

  NotificationService(this._flutterLocalNotificationsPlugin, this._notificationRepository);
  
  static const String goalNotificationChannelId = 'goal_notifications';
  static const String goalNotificationChannelName = 'Нагадування по цілях';
  static const String goalNotificationChannelDescription = 'Сповіщення про досягнення цілей та наближення дедлайнів';
  
  static const String repeatingTxnNotificationChannelId = 'repeating_txn_notifications';
  static const String repeatingTxnNotificationChannelName = 'Повторювані транзакції';
  static const String repeatingTxnNotificationChannelDescription = 'Сповіщення про автоматично створені транзакції';

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final androidImpl = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      goalNotificationChannelId,
      goalNotificationChannelName,
      description: goalNotificationChannelDescription,
      importance: Importance.max,
    ));
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      repeatingTxnNotificationChannelId,
      repeatingTxnNotificationChannelName,
      description: repeatingTxnNotificationChannelDescription,
      importance: Importance.defaultImportance,
    ));
  }
  
  Future<bool> requestPermissions(BuildContext context) async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Потрібен дозвіл"),
          content: const Text("Для відправки нагадувань, будь ласка, надайте дозвіл на сповіщення в налаштуваннях вашого пристрою."),
          actions: <Widget>[
            TextButton(
              child: const Text("Скасувати"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Налаштування"),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      return false;
    }
    return false;
  }
  
  void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _handlePayload(payload);
    }
  }
  
  void _handlePayload(String payload) {
    final uri = Uri.parse(payload);
    final path = uri.pathSegments;
    if (path.isEmpty) return;
    if (path[0] == 'goal' && path.length > 1) {
      final goalId = int.tryParse(path[1]);
      if (goalId != null) {
        final context = NavigationService.navigatorKey.currentContext;
        if (context != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => FinancialGoalsListScreen(goalIdToHighlight: goalId)));
        }
      }
    }
  }
  
  Future<void> showNotification(int id, String title, String body, {String? payload, String channelId = 'default_channel'}) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'General Notifications',
      channelDescription: 'Default channel for app notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _flutterLocalNotificationsPlugin.show(id, title, body, platformDetails, payload: payload);
    await _notificationRepository.addNotificationToHistory(title, body, payload);
  }

  Future<void> scheduleNotificationForDueDate({
    required int id,
    required String title,
    required String body,
    required DateTime dueDateTime,
    String? payload,
    String channelId = 'default_channel'
  }) async {
    
    if (dueDateTime.isBefore(DateTime.now())) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Scheduled Notifications',
      channelDescription: 'Channel for scheduled reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dueDateTime, tz.local),
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload
    );
    await _notificationRepository.addNotificationToHistory(title, body, payload);
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}