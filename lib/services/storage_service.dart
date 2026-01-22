import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class StorageService {
  static const String _taskBoxName = 'tasks';
  static Box<Task>? _taskBox;

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    _taskBox = await Hive.openBox<Task>(_taskBoxName);
    await _resetRepeatingTasks();
  }

  // Reset repeating tasks completed on previous days
  static Future<void> _resetRepeatingTasks() async {
    final tasks = _taskBox?.values.toList() ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (final task in tasks) {
      if (task.shouldReset) {
        task.isCompleted = false;
        if (task.scheduledTime != null) {
          task.scheduledTime = DateTime(
            today.year, today.month, today.day,
            task.scheduledTime!.hour, task.scheduledTime!.minute,
          );
        }
        await task.save();
      }
    }
  }

  // Get all tasks (cached list)
  static List<Task> getAllTasks() => _taskBox?.values.toList() ?? const [];

  // Get tasks for today
  static List<Task> getTodayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return getAllTasks().where((task) {
      if (task.isRepeating && task.isActiveToday) return true;
      final time = task.scheduledTime;
      if (time == null) return false;
      return time.isAfter(today) && time.isBefore(tomorrow);
    }).toList()
      ..sort((a, b) {
        final aTime = a.scheduledTime;
        final bTime = b.scheduledTime;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });
  }

  // Get upcoming task
  static Task? getUpcomingTask() {
    final now = DateTime.now();
    final threshold = now.subtract(const Duration(minutes: 15));
    
    final tasks = getAllTasks()
        .where((t) => !t.isCompleted && t.scheduledTime != null && t.isActiveToday)
        .toList()
      ..sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));

    for (final task in tasks) {
      if (task.scheduledTime!.isAfter(threshold)) return task;
    }
    return tasks.isNotEmpty ? tasks.first : null;
  }

  // CRUD operations
  static Future<void> addTask(Task task) => _taskBox?.put(task.id, task) ?? Future.value();
  static Future<void> updateTask(Task task) => task.save();
  static Future<void> deleteTask(String id) => _taskBox?.delete(id) ?? Future.value();

  // Toggle task completion
  static Future<void> toggleTaskCompletion(String id) async {
    final task = _taskBox?.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      if (task.isCompleted) task.lastCompletedDate = DateTime.now();
      await task.save();
    }
  }

  // Get streak (optimized)
  static int getStreak() {
    final completedTasks = getAllTasks().where((t) => t.isCompleted).toList();
    if (completedTasks.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    while (true) {
      final hasTask = completedTasks.any((t) {
        final d = t.createdAt;
        return DateTime(d.year, d.month, d.day).isAtSameMomentAs(checkDate);
      });

      if (hasTask) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // Get completion rate for today
  static double getTodayCompletionRate() {
    final todayTasks = getTodayTasks();
    if (todayTasks.isEmpty) return 0.0;
    return todayTasks.where((t) => t.isCompleted).length / todayTasks.length;
  }
}
