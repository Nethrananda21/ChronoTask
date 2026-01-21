import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TimeRiver extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;

  const TimeRiver({
    super.key,
    required this.tasks,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '🌊 TIME RIVER',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tasks.where((t) => t.isCompleted).length}/${tasks.length} completed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks scheduled for today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) => _buildConnector(),
                    itemBuilder: (context, index) {
                      return _buildTaskStone(context, tasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 30,
      alignment: Alignment.center,
      child: Container(
        height: 2,
        width: 30,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentPurple.withOpacity(0.3),
              AppTheme.accentBlue.withOpacity(0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStone(BuildContext context, Task task) {
    final isCompleted = task.isCompleted;
    final isOverdue = task.isOverdue;
    final isUpcoming = task.isUpcoming;

    Color stoneColor = AppTheme.surfaceCard;
    if (isCompleted) {
      stoneColor = AppTheme.accentGreen.withOpacity(0.3);
    } else if (isOverdue) {
      stoneColor = AppTheme.accentPink.withOpacity(0.3);
    } else if (isUpcoming) {
      stoneColor = AppTheme.accentPurple.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: () => onTaskTap(task),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        decoration: BoxDecoration(
          color: stoneColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUpcoming
                ? AppTheme.accentPurple
                : Colors.white.withOpacity(0.1),
            width: isUpcoming ? 2 : 1,
          ),
          boxShadow: isUpcoming
              ? [
                  BoxShadow(
                    color: AppTheme.accentPurple.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              task.scheduledTime != null
                  ? DateFormat('HH:mm').format(task.scheduledTime!)
                  : '--:--',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getTaskEmoji(task),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            if (isCompleted)
              const Icon(
                Icons.check_circle,
                color: AppTheme.accentGreen,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  String _getTaskEmoji(Task task) {
    final title = task.title.toLowerCase();
    if (title.contains('workout') || title.contains('exercise') || title.contains('gym')) {
      return '🏃';
    } else if (title.contains('email') || title.contains('mail')) {
      return '📧';
    } else if (title.contains('meeting') || title.contains('call')) {
      return '💼';
    } else if (title.contains('lunch') || title.contains('dinner') || title.contains('breakfast') || title.contains('eat')) {
      return '🍽️';
    } else if (title.contains('study') || title.contains('read') || title.contains('learn')) {
      return '📚';
    } else if (title.contains('code') || title.contains('work') || title.contains('project')) {
      return '💻';
    } else if (title.contains('shop') || title.contains('buy') || title.contains('grocery')) {
      return '🛒';
    } else if (title.contains('sleep') || title.contains('rest')) {
      return '😴';
    } else if (title.contains('home') || title.contains('clean')) {
      return '🏠';
    }
    return '📌';
  }
}
