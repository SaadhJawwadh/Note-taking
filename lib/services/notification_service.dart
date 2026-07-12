import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'period_prediction_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/repositories/note_repository.dart';
import '../screens/note_editor_screen.dart';
import '../utils/app_globals.dart';

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

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) =>
          _handleNotificationTap(response.payload),
    );

    // Cold start: the app may have been launched by tapping a notification.
    // Defer handling until the navigator exists (first frame + a beat).
    final launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails!.notificationResponse?.payload;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600),
            () => _handleNotificationTap(payload));
      });
    }
  }

  /// Opens the note a reminder notification points at (`note:` payload).
  static Future<void> _handleNotificationTap(String? payload) async {
    if (payload == null || !payload.startsWith('note:')) return;
    final noteId = payload.substring(5);
    try {
      final note = await NoteRepository.instance.readNote(noteId);
      if (note == null) return;
      await appNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
      );
    } catch (e) {
      debugPrint('Error opening note from notification: $e');
    }
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
    // 1. Cancel existing period notifications first (ids 1-3 only — a blanket
    // cancelAll() would also wipe scheduled note reminders).
    await _notificationsPlugin.cancel(1);
    await _notificationsPlugin.cancel(2);
    await _notificationsPlugin.cancel(3);

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
    );
  }

  /// Helper to set the notification time to 9:00 AM on the target date.
  static DateTime _normalizeTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, 9, 0);
  }

  /// Stable notification id for a note's reminder, namespaced into a high
  /// range so it can never collide with period (1-3) or sync notifications.
  static int noteReminderId(String noteId) =>
      0x4E000000 | (noteId.hashCode & 0x00FFFFFF);

  /// Schedules (or reschedules) the reminder for a note. Clears any previous
  /// one first; does nothing if [when] is in the past.
  static Future<void> scheduleNoteReminder({
    required String noteId,
    required String noteTitle,
    required DateTime when,
  }) async {
    await cancelNoteReminder(noteId);
    if (!when.isAfter(DateTime.now())) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'note_reminder_channel',
      'Note Reminders',
      channelDescription: 'Reminders you set on individual notes',
      importance: Importance.max,
      priority: Priority.high,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        noteReminderId(noteId),
        'Note reminder',
        noteTitle.trim().isEmpty ? 'You have a note to revisit' : noteTitle.trim(),
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'note:$noteId',
      );
    } catch (_) {
      // Plugin unavailable (tests / unsupported platform) — reminder is
      // still persisted on the note and reschedules on next edit.
    }
  }

  static Future<void> cancelNoteReminder(String noteId) async {
    try {
      await _notificationsPlugin.cancel(noteReminderId(noteId));
    } catch (_) {
      // Plugin unavailable (tests / unsupported platform).
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_sync_channel',
      'Daily Sync Alerts',
      channelDescription: 'Notifications for daily transaction synchronization results',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
