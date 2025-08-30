import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _defaultChannelId = 'default_channel';
  static const String _scheduledChannelId = 'scheduled_channel';
  static const String _goalChannelId = 'goal_channel';

  static String get goalNotificationChannelId => _goalChannelId;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) async {
        final payload = resp.payload;
        if (kDebugMode) {
          debugPrint('notification payload: $payload');
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _initialized = true;
  }

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await init();
    }
  }

  Future<void> requestPermissions() async {
    await _ensureInit();
    try {
      final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await a?.requestNotificationsPermission();
    } catch (_) {}
    try {
      final i = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await i?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
    try {
      final m = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
      await m?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = _defaultChannelId,
  }) async {
    await _ensureInit();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _readableNameForChannel(channelId),
        channelDescription: _descriptionForChannel(channelId),
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotificationForDueDate({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
    String? payload,
    String channelId = _scheduledChannelId,
    bool allowWhileIdle = true,
  }) async {
    await _ensureInit();
    final when = tz.TZDateTime.from(dueDate, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _readableNameForChannel(channelId),
        channelDescription: _descriptionForChannel(channelId),
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: allowWhileIdle ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexact,
      payload: payload,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _ensureInit();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _ensureInit();
    await _plugin.cancelAll();
  }

  String _readableNameForChannel(String id) {
    switch (id) {
      case _goalChannelId:
        return 'Goals';
      case _scheduledChannelId:
        return 'Scheduled';
      default:
        return 'General';
    }
  }

  String _descriptionForChannel(String id) {
    switch (id) {
      case _goalChannelId:
        return 'Goal-related notifications';
      case _scheduledChannelId:
        return 'Scheduled notifications';
      default:
        return 'General notifications';
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}
