import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  Future<void> _stop() async {
    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) Navigator.pop(context); // Close alarm screen
  }

  Future<void> _snooze() async {
    await Alarm.stop(widget.alarmSettings.id);
    
    final now = DateTime.now();
    final snoozeTime = now.add(const Duration(minutes: 10));
    
    // Create new notification settings for snooze
    final snoozeNotification = NotificationSettings(
      title: '${widget.alarmSettings.notificationSettings.title} (Snoozed)',
      body: 'Snoozed for 10 minutes',
      stopButton: 'Stop Alarm',
      icon: 'ic_launcher',
    );
    
    final snoozeSettings = widget.alarmSettings.copyWith(
      dateTime: snoozeTime,
      notificationSettings: snoozeNotification,
    );
    
    await Alarm.set(alarmSettings: snoozeSettings);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snoozed for 10 minutes')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure AMOLED black
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Date
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: StreamBuilder<DateTime>(
                stream: _clockStream,
                builder: (context, snapshot) {
                  final now = snapshot.data ?? DateTime.now();
                  return Column(
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(now),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('HH:mm').format(now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 90,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Middle: Task Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Icon(Icons.alarm, size: 48, color: AppTheme.accentPurple),
                  const SizedBox(height: 24),
                  Text(
                    widget.alarmSettings.notificationSettings.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.alarmSettings.notificationSettings.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom: Slide to Action
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
              child: Dismissible(
                key: const Key('alarm_slider'),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _stop();
                    return true;
                  } else {
                    await _snooze();
                    return true;
                  }
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppTheme.accentGreen, width: 2),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 30),
                  child: const Row(
                    children: [
                      Icon(Icons.stop_circle_outlined, color: AppTheme.accentGreen, size: 32),
                      SizedBox(width: 8),
                      Text('STOP', style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 30),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('SNOOZE', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(width: 8),
                      Icon(Icons.snooze, color: Colors.amber, size: 32),
                    ],
                  ),
                ),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chevron_left, color: Colors.white54),
                        SizedBox(width: 8),
                        Text(
                          '<< Snooze  |  Stop >>',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
