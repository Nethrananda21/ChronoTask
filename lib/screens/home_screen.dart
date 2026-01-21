import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _allTasks = [];
  List<Task> _pendingTasks = [];
  List<Task> _completedTasks = [];
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadTasks();
  }

  Future<void> _initNotifications() async {
    await NotificationService.init();
  }

  void _loadTasks() {
    setState(() {
      _allTasks = StorageService.getAllTasks();
      _pendingTasks = _allTasks.where((t) => !t.isCompleted).toList()
        ..sort((a, b) {
          if (a.scheduledTime == null) return 1;
          if (b.scheduledTime == null) return -1;
          return a.scheduledTime!.compareTo(b.scheduledTime!);
        });
      _completedTasks = _allTasks.where((t) => t.isCompleted).toList();
      _streak = StorageService.getStreak();
    });
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );
    if (result == true) {
      _loadTasks();
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${task.title}"'),
          backgroundColor: AppTheme.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildQuickStats(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTaskList(),
            ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // Test notification button
          IconButton(
            onPressed: () async {
              await NotificationService.testNotification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent!'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              }
            },
            icon: Icon(
              Icons.notifications_active,
              color: Colors.white.withOpacity(0.5),
            ),
            tooltip: 'Test Notifications',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final pendingCount = _pendingTasks.length;
    final completedCount = _completedTasks.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatChip('$pendingCount pending', AppTheme.accentPurple),
          const SizedBox(width: 8),
          _buildStatChip('$completedCount done', AppTheme.accentGreen),
          const SizedBox(width: 8),
          if (_streak > 0)
            _buildStatChip('🔥 $_streak day streak', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (_allTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first task',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Pending tasks section
        if (_pendingTasks.isNotEmpty) ...[
          _buildSectionHeader('Upcoming', _pendingTasks.length),
          const SizedBox(height: 8),
          ..._pendingTasks.map((task) => TaskCard(
                task: task,
                onComplete: () => _toggleTaskCompletion(task),
                onTap: () => _showTaskDetails(task),
                onDelete: () => _deleteTask(task),
              )),
        ],
        // Completed tasks section
        if (_completedTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Completed', _completedTasks.length),
          const SizedBox(height: 8),
          ..._completedTasks.map((task) => TaskCard(
                task: task,
                onComplete: () => _toggleTaskCompletion(task),
                onTap: () => _showTaskDetails(task),
                onDelete: () => _deleteTask(task),
              )),
        ],
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (task.scheduledTime != null)
              _buildDetailRow(
                Icons.schedule,
                DateFormat('h:mm a').format(task.scheduledTime!) +
                    (task.isDaily ? ' (Daily)' : ''),
              ),
            if (task.hasAlarm)
              _buildDetailRow(Icons.alarm, 'Alarm enabled'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleTaskCompletion(task);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentGreen,
                      side: const BorderSide(color: AppTheme.accentGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(task.isCompleted ? 'Undo' : 'Complete'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteTask(task);
                  },
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.accentPink,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.4)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
