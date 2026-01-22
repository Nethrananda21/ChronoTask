import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;
  bool _hasNotification = true; // Silent notification popup
  bool _hasAlarm = false; // Continuous ringing alarm
  String _selectedSound = 'assets/alarm.mp3'; // Default sound
  
  // Repeat days: 1=Monday, 2=Tuesday, ... 7=Sunday
  Set<int> _selectedDays = {};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentPurple,
              surface: AppTheme.surfaceCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        if (_selectedDays.isEmpty && _selectedDate == null) {
          _selectedDate = DateTime.now();
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentPurple,
              surface: AppTheme.surfaceCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      // Clear specific date if repeating
      if (_selectedDays.isNotEmpty) {
        _selectedDate = null;
      }
    });
  }

  void _selectAllDays() {
    setState(() {
      if (_selectedDays.length == 7) {
        _selectedDays.clear();
      } else {
        _selectedDays = {1, 2, 3, 4, 5, 6, 7};
      }
    });
  }

  DateTime? get _scheduledDateTime {
    if (_selectedTime == null) return null;
    
    final now = DateTime.now();
    var date = _selectedDays.isNotEmpty ? now : _selectedDate ?? now;
    
    // Create the scheduled datetime
    var scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    // If using repeat days or today's date and time is in the past, use tomorrow
    if ((_selectedDays.isNotEmpty || _selectedDate == null) && scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      scheduledTime: _scheduledDateTime,
      hasNotification: _hasNotification && _scheduledDateTime != null,
      hasAlarm: _hasAlarm && _scheduledDateTime != null,
      soundPath: _hasAlarm ? _selectedSound : null,
      isDaily: _selectedDays.length == 7, // For backwards compat
      repeatDays: _selectedDays.toList(),
      createdAt: DateTime.now(),
    );

    await StorageService.addTask(task);

    // Schedule notification/alarm if either is enabled
    if (task.hasNotification || task.hasAlarm) {
      try {
        await NotificationService.scheduleTaskReminder(task);
        debugPrint('Notification scheduled for task: ${task.title}');
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Task'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _inputDecoration('What needs to be done?'),
              validator: (v) => v?.trim().isEmpty == true ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            // Description
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecoration('Notes (optional)'),
            ),
            const SizedBox(height: 24),

            // Repeat Days Section
            Text(
              'Repeat',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildDaySelector(),
            const SizedBox(height: 16),

            // Time picker
            _buildPickerRow(
              icon: Icons.schedule,
              title: _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Set time',
              onTap: _selectTime,
              isSet: _selectedTime != null,
            ),
            const SizedBox(height: 12),

            // Date picker (only if not repeating)
            if (_selectedDays.isEmpty)
              _buildPickerRow(
                icon: Icons.calendar_today,
                title: _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Set date',
                onTap: _selectDate,
                isSet: _selectedDate != null,
              ),
            if (_selectedDays.isEmpty) const SizedBox(height: 12),

            // Notification toggle
            _buildToggleRow(
              icon: Icons.notifications_outlined,
              title: 'Notification',
              subtitle: 'Silent popup at scheduled time',
              value: _hasNotification,
              onChanged: (v) => setState(() => _hasNotification = v),
            ),
            const SizedBox(height: 12),

            // Alarm toggle
            _buildToggleRow(
              icon: Icons.alarm,
              title: 'Alarm',
              subtitle: 'Rings continuously until dismissed',
              value: _hasAlarm,
              onChanged: (v) => setState(() => _hasAlarm = v),
              isAlarm: true,
            ),
            if (_hasAlarm) ...[
              const SizedBox(height: 12),
              _buildSoundSelector(),
            ],
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const dayValues = [1, 2, 3, 4, 5, 6, 7]; // Monday = 1, Sunday = 7

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final isSelected = _selectedDays.contains(dayValues[index]);
            return GestureDetector(
              onTap: () => _toggleDay(dayValues[index]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentPurple
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentPurple
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectAllDays,
          child: Row(
            children: [
              Icon(
                _selectedDays.length == 7 
                    ? Icons.check_circle 
                    : Icons.circle_outlined,
                size: 18,
                color: _selectedDays.length == 7
                    ? AppTheme.accentPurple
                    : Colors.white.withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              Text(
                'Everyday',
                style: TextStyle(
                  color: _selectedDays.length == 7
                      ? AppTheme.accentPurple
                      : Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: AppTheme.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isAlarm = false,
  }) {
    final activeColor = isAlarm ? AppTheme.accentPink : AppTheme.accentPurple;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: isAlarm && value ? Border.all(color: activeColor.withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? activeColor : Colors.white.withOpacity(0.4)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: isSet ? Border.all(color: AppTheme.accentPurple.withOpacity(0.5)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSet ? AppTheme.accentPurple : Colors.white.withOpacity(0.4)),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: isSet ? Colors.white : Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSoundSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alarm Sound',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _soundOption('Classic Beep', 'assets/alarm.mp3'),
              const SizedBox(width: 12),
              _soundOption('Gentle Melody', 'assets/melodic.mp3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _soundOption(String label, String path) {
    final isSelected = _selectedSound == path;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSound = path),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentPink.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.accentPink : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentPink : Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
