import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class FocusCard extends StatelessWidget {
  final Task? task;
  final VoidCallback onStart;
  final VoidCallback onSnooze;
  final VoidCallback onComplete;

  const FocusCard({
    super.key,
    required this.task,
    required this.onStart,
    required this.onSnooze,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentPurple.withOpacity(0.3),
            AppTheme.accentBlue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentPurple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.center_focus_strong,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'FOCUS NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (task!.scheduledTime != null)
                _buildTimeRemaining(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            task!.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (task!.description != null && task!.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task!.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (task!.scheduledTime != null) ...[
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('h:mm a').format(task!.scheduledTime!),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Text(
                '${task!.energyEmoji} ${_getEnergyLabel(task!.energyLevel)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Start',
                  color: AppTheme.accentGreen,
                  onTap: onStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.snooze,
                  label: 'Snooze',
                  color: AppTheme.accentBlue,
                  onTap: onSnooze,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_rounded,
                  label: 'Done',
                  color: AppTheme.accentPurple,
                  onTap: onComplete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRemaining() {
    if (task?.scheduledTime == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final diff = task!.scheduledTime!.difference(now);
    
    String timeText;
    Color timeColor;

    if (diff.isNegative) {
      timeText = '${diff.inMinutes.abs()}m overdue';
      timeColor = AppTheme.accentPink;
    } else if (diff.inMinutes < 60) {
      timeText = '${diff.inMinutes}m remaining';
      timeColor = diff.inMinutes < 15 ? AppTheme.accentPink : Colors.white;
    } else {
      timeText = '${diff.inHours}h ${diff.inMinutes % 60}m';
      timeColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          color: timeColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration,
            size: 48,
            color: AppTheme.accentGreen.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming tasks. Add a new task to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 1:
        return 'Low Energy';
      case 2:
        return 'Medium';
      case 3:
        return 'High Energy';
      default:
        return 'Medium';
    }
  }
}
