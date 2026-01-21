import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppTheme.accentPink),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: task.isOverdue && !task.isCompleted
                ? Border.all(color: AppTheme.accentPink.withOpacity(0.5))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              // Animated Checkbox
              GestureDetector(
                onTap: onComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted
                        ? AppTheme.accentGreen
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted
                          ? AppTheme.accentGreen
                          : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: null, // Use system font
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: task.isCompleted
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      child: Text(task.title),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (task.scheduledTime != null) ...[
                          Text(
                            DateFormat('h:mm a').format(task.scheduledTime!),
                            style: TextStyle(
                              fontSize: 12,
                              color: task.isOverdue && !task.isCompleted
                                  ? AppTheme.accentPink
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!task.isCompleted) _buildTimeRemaining(),
                        ],
                        if (task.isRepeating) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.repeat,
                            size: 12,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.repeatDaysText,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Alarm indicator
              if (task.hasAlarm && !task.isCompleted)
                Icon(
                  Icons.alarm,
                  size: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRemaining() {
    if (task.scheduledTime == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final diff = task.scheduledTime!.difference(now);

    String text;
    Color color;

    if (diff.isNegative) {
      final abs = diff.abs();
      if (abs.inHours > 0) {
        text = '${abs.inHours}h overdue';
      } else {
        text = '${abs.inMinutes}m overdue';
      }
      color = AppTheme.accentPink; // New Red/Orange color
    } else {
      if (diff.inHours > 0) {
        text = '${diff.inHours}h ${diff.inMinutes % 60}m';
      } else if (diff.inMinutes > 0) {
        text = '${diff.inMinutes}m';
      } else {
        text = 'now';
      }
      color = diff.inMinutes <= 30 ? Colors.orange : AppTheme.accentGreen;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
