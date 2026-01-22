import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/task.dart';

/// Service handling both silent notifications (flutter_local_notifications)
/// and continuous alarms (alarm package).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _permissionGranted = false;
  static const String _notificationChannelId = 'chronotask_notifications';

  // Cached notification details for reuse
  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _notificationChannelId,
      'Task Notifications',
      channelDescription: 'Reminder notifications for tasks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
  );

  /// Initialize mechanisms
  static Future<bool> init() async {
    if (_initialized) return _permissionGranted;

    try {
      // 1. Init Alarm package
      await Alarm.init();

      // 2. Init Timezones
      tzdata.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

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
            playSound: true,
            enableVibration: true,
          ),
        );
        
        final notifPermission = await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        _permissionGranted = notifPermission == true;
      }

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      await _notifications.initialize(initSettings);
      _initialized = true;
      return _permissionGranted;
    } catch (_) {
      return false;
    }
  }

  /// Check if we have permission
  static Future<bool> hasPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return androidPlugin != null 
        ? (await androidPlugin.areNotificationsEnabled() ?? false)
        : false;
  }

  /// Schedule reminders
  static Future<void> scheduleTaskReminder(Task task) async {
    if (task.scheduledTime == null) return;
    if (!task.hasNotification && !task.hasAlarm) return;

    await init();

    final scheduledTime = task.scheduledTime!;
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    // Cleanup existing
    await cancelTaskReminder(task);

    final id = task.id.hashCode.abs() % 100000;

    // 1. Schedule Notification
    if (task.hasNotification) {
      final tzTime = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      await _notifications.zonedSchedule(
        id,
        '📋 ${task.title}',
        task.description ?? 'Task reminder',
        tzTime,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 2. Schedule Alarm
    if (task.hasAlarm) {
      final alarmSettings = AlarmSettings(
        id: id + 50000,
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
          volume: null,
          volumeEnforced: false,
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
    }
  }

  /// Cancel reminders
  static Future<void> cancelTaskReminder(Task task) async {
    final id = task.id.hashCode.abs() % 100000;
    await Future.wait([
      _notifications.cancel(id),
      Alarm.stop(id + 50000),
    ]);
  }

  static Future<void> cancelAll() async {
    await Future.wait([
      _notifications.cancelAll(),
      Alarm.stopAll(),
    ]);
  }

  // Legacy aliases
  static Future<void> scheduleTaskAlarm(Task task) => scheduleTaskReminder(task);
  static Future<void> cancelTaskAlarm(Task task) => cancelTaskReminder(task);
}
