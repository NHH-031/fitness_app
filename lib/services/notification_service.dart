import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _waterNotificationId = 1001;
  static const int _testNotificationId = 1002;
  static const String _channelId = 'water_reminder_channel';
  static const String _channelName = 'Water Reminder';
  static const String _channelDescription =
      'Periodic notifications to help you stay properly hydrated.';

  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      await requestPermissions();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<bool?> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? grantedNotification =
          await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
      return grantedNotification;
    }
    return true;
  }

  NotificationDetails _getNotificationDetails({
    String title = 'Time to drink water! 💧',
    String body = 'Drink a glass of water (250ml) to keep your energy high!',
  }) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );
  }

  /// Send instant notification
  Future<void> showInstantNotification({
    String title = 'Time to drink water! 💧',
    String body = 'Drink a glass of water (250ml) to stay refreshed!',
  }) async {
    await _notificationsPlugin.show(
      id: _waterNotificationId,
      title: title,
      body: body,
      notificationDetails: _getNotificationDetails(title: title, body: body),
    );
  }

  /// Schedule test notification after a few seconds
  Future<void> scheduleTestNotification({int seconds = 5}) async {
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    await _notificationsPlugin.zonedSchedule(
      id: _testNotificationId,
      title: 'Water Reminder Test 💧',
      body: 'Water reminder is working perfectly! Don\'t forget to stay hydrated.',
      scheduledDate: scheduledDate,
      notificationDetails: _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule periodic daytime water reminders (every 1h, 2h, or 3h from 08:00 to 21:00)
  Future<void> schedulePeriodicWaterReminder({int intervalHours = 2}) async {
    // Cancel previous reminders to avoid duplicates
    await cancelWaterReminders();

    final now = tz.TZDateTime.now(tz.local);

    int count = 0;
    for (int hour = 8; hour <= 21; hour += intervalHours) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id: _waterNotificationId + count,
        title: 'Time to drink water! 💧',
        body: 'Drink a glass of water (250ml) at $hour:00 to keep your body energized.',
        scheduledDate: scheduledDate,
        notificationDetails: _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      count++;
    }
  }

  /// Hủy tất cả thông báo nhắc nước
  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 20; i++) {
      await _notificationsPlugin.cancel(id: _waterNotificationId + i);
    }
    await _notificationsPlugin.cancel(id: _testNotificationId);
  }

  /// Hủy toàn bộ thông báo
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
