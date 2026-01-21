import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? scheduledTime;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  int energyLevel;

  @HiveField(6)
  String focusType;

  @HiveField(7)
  String timeElasticity;

  @HiveField(8)
  bool hasAlarm;

  @HiveField(9)
  String? category;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  int? alarmNotificationId;

  @HiveField(12)
  bool isDaily; // Kept for backwards compatibility

  @HiveField(13)
  DateTime? lastCompletedDate;

  @HiveField(14)
  List<int> repeatDays; // 1=Monday, 2=Tuesday, ... 7=Sunday (matches DateTime.weekday)

  Task({
    required this.id,
    required this.title,
    this.description,
    this.scheduledTime,
    this.isCompleted = false,
    this.energyLevel = 2,
    this.focusType = 'routine',
    this.timeElasticity = 'flexible',
    this.hasAlarm = false,
    this.category,
    required this.createdAt,
    this.alarmNotificationId,
    this.isDaily = false,
    this.lastCompletedDate,
    List<int>? repeatDays,
  }) : repeatDays = repeatDays ?? [];

  // Check if task repeats (has any repeat days set)
  bool get isRepeating => repeatDays.isNotEmpty || isDaily;

  // Check if task should show today based on repeat days
  bool get isActiveToday {
    if (repeatDays.isEmpty && !isDaily) return true; // One-time task
    if (isDaily) return true; // Everyday
    return repeatDays.contains(DateTime.now().weekday);
  }

  // Check if repeating task should reset (completed on a previous day)
  bool get shouldReset {
    if (!isRepeating || !isCompleted || lastCompletedDate == null) return false;
    
    final now = DateTime.now();
    final completedDay = DateTime(lastCompletedDate!.year, lastCompletedDate!.month, lastCompletedDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    
    // Only reset if today is after completion AND today is an active day
    return today.isAfter(completedDay) && isActiveToday;
  }

  // For backwards compatibility
  bool get shouldResetDaily => shouldReset;

  // Get emoji for energy level
  String get energyEmoji {
    switch (energyLevel) {
      case 1: return '⚡';
      case 2: return '⚡⚡';
      case 3: return '⚡⚡⚡';
      default: return '⚡⚡';
    }
  }

  // Get icon for focus type
  String get focusEmoji {
    switch (focusType) {
      case 'deep': return '🎯';
      case 'routine': return '🔄';
      case 'social': return '💬';
      default: return '🔄';
    }
  }

  // Check if task is overdue
  bool get isOverdue {
    if (scheduledTime == null || isCompleted) return false;
    return DateTime.now().isAfter(scheduledTime!);
  }

  // Check if task is upcoming (within next hour)
  bool get isUpcoming {
    if (scheduledTime == null || isCompleted) return false;
    final now = DateTime.now();
    final diff = scheduledTime!.difference(now);
    return diff.inMinutes > 0 && diff.inMinutes <= 60;
  }

  // Get repeat days as short names
  String get repeatDaysText {
    if (isDaily || repeatDays.length == 7) return 'Everyday';
    if (repeatDays.isEmpty) return '';
    
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(repeatDays)..sort();
    return sortedDays.map((d) => dayNames[d]).join(', ');
  }
}
