import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/task.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Task> _allTasks = [];
  Map<int, int> _weeklyCompleted = {};
  Map<int, int> _weeklyTotal = {};
  int _streak = 0;
  int _totalCompleted = 0;
  int _totalTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final tasks = StorageService.getAllTasks();
    final now = DateTime.now();
    
    // Initialize weekly data (last 7 days)
    _weeklyCompleted = {};
    _weeklyTotal = {};
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final weekday = day.weekday;
      _weeklyCompleted[weekday] = 0;
      _weeklyTotal[weekday] = 0;
    }
    
    int completed = 0;
    for (final task in tasks) {
      if (task.isCompleted) completed++;
      
      // Count by weekday for last 7 days
      if (task.lastCompletedDate != null) {
        final diff = now.difference(task.lastCompletedDate!).inDays;
        if (diff < 7) {
          final weekday = task.lastCompletedDate!.weekday;
          _weeklyCompleted[weekday] = (_weeklyCompleted[weekday] ?? 0) + 1;
        }
      }
      
      // Count tasks created in last 7 days
      final createdDiff = now.difference(task.createdAt).inDays;
      if (createdDiff < 7) {
        final weekday = task.createdAt.weekday;
        _weeklyTotal[weekday] = (_weeklyTotal[weekday] ?? 0) + 1;
      }
    }

    setState(() {
      _allTasks = tasks;
      _streak = StorageService.getStreak();
      _totalCompleted = completed;
      _totalTasks = tasks.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Top Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('🔥', '$_streak', 'Day Streak')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('✅', '$_totalCompleted', 'Completed')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('📋', '$_totalTasks', 'Total Tasks')),
            ],
          ),
          const SizedBox(height: 24),
          
          // Completion Rate
          _buildSectionTitle('Completion Rate'),
          const SizedBox(height: 12),
          _buildCompletionRate(),
          const SizedBox(height: 24),
          
          // Weekly Activity
          _buildSectionTitle('Weekly Activity'),
          const SizedBox(height: 12),
          _buildWeeklyChart(),
          const SizedBox(height: 24),
          
          // Recent Completions
          _buildSectionTitle('Recently Completed'),
          const SizedBox(height: 12),
          _buildRecentCompletions(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }

  Widget _buildCompletionRate() {
    final rate = _totalTasks > 0 ? _totalCompleted / _totalTasks : 0.0;
    final percentage = (rate * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGreen,
                ),
              ),
              Text(
                '$_totalCompleted / $_totalTasks tasks',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxCompleted = _weeklyCompleted.values.fold(1, (a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final weekday = index + 1; // 1 = Monday
          final count = _weeklyCompleted[weekday] ?? 0;
          final height = count > 0 ? (count / maxCompleted) * 80 : 8.0;
          final isToday = weekday == DateTime.now().weekday;
          
          return Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: height,
                decoration: BoxDecoration(
                  color: isToday
                      ? AppTheme.accentPurple
                      : AppTheme.accentPurple.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? AppTheme.accentPurple : Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRecentCompletions() {
    final recentCompleted = _allTasks
        .where((t) => t.isCompleted && t.lastCompletedDate != null)
        .toList()
      ..sort((a, b) => b.lastCompletedDate!.compareTo(a.lastCompletedDate!));
    
    final toShow = recentCompleted.take(5).toList();
    
    if (toShow.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No completed tasks yet',
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: toShow.map((task) {
          final daysAgo = DateTime.now().difference(task.lastCompletedDate!).inDays;
          final timeText = daysAgo == 0 ? 'Today' : daysAgo == 1 ? 'Yesterday' : '$daysAgo days ago';
          
          return ListTile(
            leading: const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 20),
            title: Text(
              task.title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            trailing: Text(
              timeText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
