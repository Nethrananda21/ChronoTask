import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/task.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadTasks();
  }

  void _loadTasks() {
    final tasks = StorageService.getAllTasks();
    final Map<DateTime, List<Task>> grouped = {};

    for (final task in tasks) {
      if (task.scheduledTime != null) {
        final date = DateTime(
          task.scheduledTime!.year,
          task.scheduledTime!.month,
          task.scheduledTime!.day,
        );
        grouped.putIfAbsent(date, () => []).add(task);
      }
      
      // Also add repeating tasks to their active days
      if (task.isRepeating && task.scheduledTime != null) {
        // Add to next 30 days if active on that weekday
        for (int i = 0; i < 30; i++) {
          final day = DateTime.now().add(Duration(days: i));
          final date = DateTime(day.year, day.month, day.day);
          
          if (task.repeatDays.contains(day.weekday) || task.isDaily) {
            if (!grouped.containsKey(date) || 
                !grouped[date]!.any((t) => t.id == task.id)) {
              grouped.putIfAbsent(date, () => []).add(task);
            }
          }
        }
      }
    }

    setState(() => _tasksByDate = grouped);
  }

  List<Task> _getTasksForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _tasksByDate[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Calendar'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar<Task>(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getTasksForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                // Today
                todayDecoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: Colors.white),
                // Selected
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.accentPurple,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                // Default
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                // Markers
                markerDecoration: const BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markerSize: 6,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                formatButtonVisible: false,
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Colors.white.withOpacity(0.6),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Tasks for selected day
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _selectedDay != null ? _getTasksForDay(_selectedDay!) : [];
    
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks for this day',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: task.isCompleted
                ? null
                : Border.all(
                    color: task.isOverdue
                        ? AppTheme.accentPink.withOpacity(0.5)
                        : Colors.transparent,
                  ),
          ),
          child: Row(
            children: [
              Icon(
                task.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: task.isCompleted
                    ? AppTheme.accentGreen
                    : Colors.white.withOpacity(0.3),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: task.isCompleted
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.scheduledTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${task.scheduledTime!.hour.toString().padLeft(2, '0')}:${task.scheduledTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (task.isRepeating)
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
            ],
          ),
        );
      },
    );
  }
}
