import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'period_prediction_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'period_tracker_channel';
  static const String channelName = 'Period Tracker Alerts';
  static const String channelDescription =
      'Notifications for upcoming and late periods';

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    // For iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  /// Schedules notifications for the upcoming period based on prediction logic.
  static Future<void> schedulePeriodNotifications() async {
    // 1. Cancel existing notifications first
    await _notificationsPlugin.cancelAll();

    // 2. Check if feature is enabled
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('isPeriodTrackerEnabled') ?? false;
    if (!isEnabled) return;

    // 3. Get prediction
    final nextPeriodDate = await PeriodPredictionService.estimateNextPeriod();
    if (nextPeriodDate == null) return; // No logs yet

    // 4. Get notification text setting
    final discreetText =
        prefs.getString('discreetNotificationText') ?? 'Check the app';

    final now = DateTime.now();

    // Schedule: 2 Days before
    final twoDaysBefore = nextPeriodDate.subtract(const Duration(days: 2));
    if (twoDaysBefore.isAfter(now)) {
      await _scheduleNotification(
        id: 1,
        title: 'Reminder',
        body: discreetText,
        scheduledDate: _normalizeTime(twoDaysBefore),
      );
    }

    // Schedule: 1 Day before
    final oneDayBefore = nextPeriodDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await _scheduleNotification(
        id: 2,
        title: 'Reminder',
        body: discreetText,
        scheduledDate: _normalizeTime(oneDayBefore),
      );
    }

    // Schedule: 1 Day late
    final oneDayLate = nextPeriodDate.add(const Duration(days: 1));
    if (oneDayLate.isAfter(now)) {
      await _scheduleNotification(
        id: 3,
        title: 'Reminder',
        body: discreetText,
        scheduledDate: _normalizeTime(oneDayLate),
      );
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Helper to set the notification time to 9:00 AM on the target date.
  static DateTime _normalizeTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, 9, 0);
  }
}
