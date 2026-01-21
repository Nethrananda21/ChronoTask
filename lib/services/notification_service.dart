import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/task.dart';

/// Service handling both silent notifications (flutter_local_notifications)
/// and continuous alarms (alarm package).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static const String _notificationChannelId = 'chronotask_notifications';

  /// Initialize mechanisms
  static Future<bool> init() async {
    if (_initialized) return true;

    try {
      // 1. Init Alarm package
      await Alarm.init();

      // 2. Init Timezones
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      // 3. Init Local Notifications
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _notificationChannelId,
            'Task Notifications',
            description: 'Reminder notifications for tasks',
            importance: Importance.high,
          ),
        );
        await androidPlugin.requestNotificationsPermission();
      }

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      await _notifications.initialize(initSettings);
      
      _initialized = true;
      debugPrint('NotificationService: Initialized (Alarm + LocalNotifications)');
      return true;
    } catch (e) {
      debugPrint('NotificationService: Error during init: $e');
      return false;
    }
  }

  /// Schedule reminders
  static Future<void> scheduleTaskReminder(Task task) async {
    try {
      if (task.scheduledTime == null) return;
      if (!task.hasNotification && !task.hasAlarm) return;

      await init();

      final scheduledTime = task.scheduledTime!;
      final now = DateTime.now();

      if (scheduledTime.isBefore(now)) {
        debugPrint('NotificationService: Time in past, skipping');
        return;
      }

      // Cleanup existing
      await cancelTaskReminder(task);

      final id = task.id.hashCode.abs() % 100000;
      final alarmId = id + 50000;

      // 1. Schedule Notification (Silent/Standard)
      if (task.hasNotification) {
        // Safer timezone conversion
        tz.TZDateTime tzTime;
        try {
          tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
        } catch (e) {
          tzTime = tz.TZDateTime.from(scheduledTime, tz.UTC);
        }

        const notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            'Task Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        );

        await _notifications.zonedSchedule(
          id,
          '📋 ${task.title}',
          task.description ?? 'Task reminder',
          tzTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('NotificationService: Standard Notification scheduled id=$id');
      }

      // 2. Schedule Alarm (Continuous Ringing via Alarm package)
      if (task.hasAlarm) {
        final alarmSettings = AlarmSettings(
          id: alarmId,
          dateTime: scheduledTime,
      assetAudioPath: task.soundPath ?? 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      notificationSettings: NotificationSettings(
        title: '🔔 ALARM: ${task.title}',
        body: task.description ?? 'Tap to stop alarm',
        stopButton: 'Stop Alarm',
        icon: 'ic_launcher',
      ),
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
          volumeSettings: VolumeSettings.fade(
            fadeDuration: const Duration(seconds: 3),
            volume: null, // Use system volume (don't force 100%)
            volumeEnforced: false, // Allow user to change volume
          ),
        );

        await Alarm.set(alarmSettings: alarmSettings);
        debugPrint('NotificationService: Alarm package scheduled id=$alarmId at $scheduledTime');
      }

    } catch (e) {
      debugPrint('NotificationService: Error scheduling: $e');
    }
  }

  /// Cancel reminders
  static Future<void> cancelTaskReminder(Task task) async {
    final id = task.id.hashCode.abs() % 100000;
    
    // Cancel notification
    await _notifications.cancel(id);
    
    // Cancel alarm
    await Alarm.stop(id + 50000);
    
    debugPrint('NotificationService: Cancelled reminders for "${task.title}"');
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    await Alarm.stopAll();
  }

  // Legacy
  static Future<void> scheduleTaskAlarm(Task task) => scheduleTaskReminder(task);
  static Future<void> cancelTaskAlarm(Task task) => cancelTaskReminder(task);
}
