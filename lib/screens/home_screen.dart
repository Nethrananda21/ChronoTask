import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import 'stats_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _pendingTasks = const [];
  List<Task> _completedTasks = const [];
  int _streak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NotificationService.init();
    _loadTasks();
  }

  void _loadTasks() {
    final all = StorageService.getAllTasks();
    setState(() {
      _pendingTasks = all.where((t) => !t.isCompleted).toList()
        ..sort((a, b) {
          if (a.scheduledTime == null) return 1;
          if (b.scheduledTime == null) return -1;
          return a.scheduledTime!.compareTo(b.scheduledTime!);
        });
      _completedTasks = all.where((t) => t.isCompleted).toList();
      _streak = StorageService.getStreak();
      _isLoading = false;
    });
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
    if (result == true) _loadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    await StorageService.toggleTaskCompletion(task.id);
    if (task.isCompleted) {
      await NotificationService.scheduleTaskAlarm(task);
    } else {
      await NotificationService.cancelTaskAlarm(task);
    }
    _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    await NotificationService.cancelTaskAlarm(task);
    await StorageService.deleteTask(task.id);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _Header(
                    onCalendar: () => Navigator.push(context, 
                      MaterialPageRoute(builder: (_) => const CalendarScreen())),
                    onStats: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const StatsScreen())),
                  ),
                  _QuickStats(
                    pending: _pendingTasks.length,
                    completed: _completedTasks.length,
                    streak: _streak,
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildTaskList()),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: AppTheme.accentPurple,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildTaskList() {
    if (_pendingTasks.isEmpty && _completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, 
                 color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('No tasks yet', 
                 style: TextStyle(color: Colors.white.withOpacity(0.3))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_pendingTasks.isNotEmpty) ...[
          _SectionHeader(title: 'Upcoming', count: _pendingTasks.length),
          const SizedBox(height: 8),
          ..._pendingTasks.map((task) => TaskCard(
            key: ValueKey(task.id),
            task: task,
            onComplete: () => _toggleTask(task),
            onTap: () {},
            onDelete: () => _deleteTask(task),
          )),
        ],
        if (_completedTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: 'Completed', count: _completedTasks.length),
          const SizedBox(height: 8),
          ..._completedTasks.map((task) => TaskCard(
            key: ValueKey(task.id),
            task: task,
            onComplete: () => _toggleTask(task),
            onTap: () {},
            onDelete: () => _deleteTask(task),
          )),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

// Extracted as const-friendly widgets
class _Header extends StatelessWidget {
  final VoidCallback onCalendar;
  final VoidCallback onStats;

  const _Header({required this.onCalendar, required this.onStats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTheme.greeting,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCalendar,
            icon: Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.5)),
          ),
          IconButton(
            onPressed: onStats,
            icon: Icon(Icons.bar_chart, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final int pending;
  final int completed;
  final int streak;

  const _QuickStats({
    required this.pending,
    required this.completed,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatChip(text: '$pending pending', color: AppTheme.accentPurple),
          const SizedBox(width: 8),
          _StatChip(text: '$completed done', color: AppTheme.accentGreen),
          if (streak > 0) ...[
            const SizedBox(width: 8),
            _StatChip(text: '🔥 $streak day streak', color: Colors.orange),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }
}
