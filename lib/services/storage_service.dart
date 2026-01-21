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
    
    // Reset repeating tasks that were completed on previous days
    await _resetRepeatingTasks();
  }

  // Reset repeating tasks completed on previous days
  static Future<void> _resetRepeatingTasks() async {
    final tasks = _taskBox?.values.toList() ?? [];
    for (final task in tasks) {
      if (task.shouldReset) {
        task.isCompleted = false;
        // Update scheduled time to today
        if (task.scheduledTime != null) {
          final now = DateTime.now();
          task.scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            task.scheduledTime!.hour,
            task.scheduledTime!.minute,
          );
        }
        await task.save();
      }
    }
  }

  // Get all tasks
  static List<Task> getAllTasks() {
    return _taskBox?.values.toList() ?? [];
  }

  // Get tasks for today (including repeating tasks active today)
  static List<Task> getTodayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return getAllTasks().where((task) {
      // Include repeating tasks if active today
      if (task.isRepeating && task.isActiveToday) return true;
      // Include tasks scheduled for today
      if (task.scheduledTime == null) return false;
      return task.scheduledTime!.isAfter(today) &&
          task.scheduledTime!.isBefore(tomorrow);
    }).toList()
      ..sort((a, b) {
        if (a.scheduledTime == null) return 1;
        if (b.scheduledTime == null) return -1;
        return a.scheduledTime!.compareTo(b.scheduledTime!);
      });
  }

  // Get upcoming task
  static Task? getUpcomingTask() {
    final now = DateTime.now();
    final tasks = getAllTasks()
        .where((t) => !t.isCompleted && t.scheduledTime != null && t.isActiveToday)
        .toList()
      ..sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));

    for (final task in tasks) {
      if (task.scheduledTime!.isAfter(now) ||
          task.scheduledTime!.isAfter(now.subtract(const Duration(minutes: 15)))) {
        return task;
      }
    }
    return tasks.isNotEmpty ? tasks.first : null;
  }

  // Add task
  static Future<void> addTask(Task task) async {
    await _taskBox?.put(task.id, task);
  }

  // Update task
  static Future<void> updateTask(Task task) async {
    await task.save();
  }

  // Delete task
  static Future<void> deleteTask(String id) async {
    await _taskBox?.delete(id);
  }

  // Toggle task completion
  static Future<void> toggleTaskCompletion(String id) async {
    final task = _taskBox?.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      // Track when completed for reset logic
      if (task.isCompleted) {
        task.lastCompletedDate = DateTime.now();
      }
      await task.save();
    }
  }

  // Get streak
  static int getStreak() {
    final tasks = getAllTasks().where((t) => t.isCompleted).toList();
    if (tasks.isEmpty) return 0;

    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int streak = 0;
    DateTime checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    while (true) {
      final hasCompletedTask = tasks.any((t) {
        final taskDate = DateTime(
          t.createdAt.year,
          t.createdAt.month,
          t.createdAt.day,
        );
        return taskDate.isAtSameMomentAs(checkDate);
      });

      if (hasCompletedTask) {
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
    final completed = todayTasks.where((t) => t.isCompleted).length;
    return completed / todayTasks.length;
  }
}
