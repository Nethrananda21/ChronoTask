import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/task.dart';

/// Battery-optimized notification service using Android's native AlarmManager.
/// The app does NOT need to stay running - Android will wake it up when needed.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize the notification service
  static Future<bool> init() async {
    if (_initialized) return true;

    try {
      // Initialize timezone for India
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      // Create high-priority notification channel
      const channel = AndroidNotificationChannel(
        'chronotask_alarms',
        'Task Alarms',
        description: 'Notifications for scheduled tasks',
        importance: Importance.high,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      await _notifications.initialize(initSettings);
      _initialized = true;
      debugPrint('NotificationService: Initialized');
      return true;
    } catch (e) {
      debugPrint('NotificationService: Error during init: $e');
      return false;
    }
  }

  /// Show an immediate test notification
  static Future<void> testNotification() async {
    await init();
    
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chronotask_alarms',
        'Task Alarms',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _notifications.show(
      0,
      '✅ ChronoTask',
      'Notifications are working!',
      details,
    );
  }

  /// Schedule an alarm for a task using Android's native AlarmManager.
  /// Battery efficient - app does NOT need to stay running.
  static Future<void> scheduleTaskAlarm(Task task) async {
    try {
      if (task.scheduledTime == null || !task.hasAlarm) return;

      await init();

      final scheduledTime = task.scheduledTime!;
      final now = DateTime.now();

      if (scheduledTime.isBefore(now)) {
        debugPrint('NotificationService: Time in past, skipping');
        return;
      }

      // Cancel existing alarm for this task
      await cancelTaskAlarm(task);

      final id = task.id.hashCode.abs() % 100000;
      
      // Safer timezone conversion
      tz.TZDateTime tzTime;
      try {
        tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
      } catch (e) {
        debugPrint('NotificationService: Timezone error, falling back to UTC');
        tzTime = tz.TZDateTime.from(scheduledTime, tz.UTC);
      }

      debugPrint('NotificationService: Scheduling "${task.title}" at $tzTime');

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'chronotask_alarms',
          'Task Alarms',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
        ),
      );

      await _notifications.zonedSchedule(
        id,
        '🔔 ${task.title}',
        task.description ?? 'Time for your task!',
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('NotificationService: Alarm scheduled with id=$id');
    } catch (e) {
      debugPrint('NotificationService: Error scheduling alarm: $e');
    }
  }

  /// Cancel a scheduled alarm
  static Future<void> cancelTaskAlarm(Task task) async {
    final id = task.id.hashCode.abs() % 100000;
    await _notifications.cancel(id);
    debugPrint('NotificationService: Cancelled alarm id=$id');
  }

  /// Cancel all scheduled alarms
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
