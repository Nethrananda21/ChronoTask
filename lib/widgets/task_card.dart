import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

/// Optimized TaskCard with minimal rebuilds
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
    final isOverdue = task.isOverdue && !task.isCompleted;
    
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal, // Enable both directions
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onComplete(); // Swipe Right -> Complete
        } else {
          onDelete?.call(); // Swipe Left -> Delete
        }
      },
      // Swipe Right (Start to End) -> Green/Complete
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppTheme.accentGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
      ),
      // Swipe Left (End to Start) -> Red/Delete
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.accentPink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: isOverdue 
                ? Border.all(color: AppTheme.accentPink.withOpacity(0.5))
                : null,
          ),
          child: Row(
            children: [
              _CheckBox(
                isCompleted: task.isCompleted,
                onTap: onComplete,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: task.isCompleted
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _TaskMeta(task: task, isOverdue: isOverdue),
                  ],
                ),
              ),
              if (task.hasAlarm && !task.isCompleted)
                Icon(Icons.alarm, size: 16, color: Colors.white.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const _CheckBox({required this.isCompleted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? AppTheme.accentGreen : Colors.transparent,
          border: Border.all(
            color: isCompleted ? AppTheme.accentGreen : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : null,
      ),
    );
  }
}

class _TaskMeta extends StatelessWidget {
  final Task task;
  final bool isOverdue;

  const _TaskMeta({required this.task, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (task.scheduledTime != null) ...[
          Text(
            DateFormat('h:mm a').format(task.scheduledTime!),
            style: TextStyle(
              fontSize: 12,
              color: isOverdue ? AppTheme.accentPink : Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 8),
          if (!task.isCompleted) _TimeRemaining(task: task),
        ],
        if (task.isRepeating) ...[
          const SizedBox(width: 8),
          Icon(Icons.repeat, size: 12, color: Colors.white.withOpacity(0.3)),
          const SizedBox(width: 4),
          Text(
            task.repeatDaysText,
            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ],
    );
  }
}

class _TimeRemaining extends StatelessWidget {
  final Task task;

  const _TimeRemaining({required this.task});

  @override
  Widget build(BuildContext context) {
    if (task.scheduledTime == null) return const SizedBox.shrink();

    final diff = task.scheduledTime!.difference(DateTime.now());
    
    String text;
    Color color;

    if (diff.isNegative) {
      final abs = diff.abs();
      text = abs.inHours > 0 ? '${abs.inHours}h overdue' : '${abs.inMinutes}m overdue';
      color = AppTheme.accentPink;
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
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
    );
  }
}
