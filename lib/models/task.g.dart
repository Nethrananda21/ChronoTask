// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      scheduledTime: fields[3] as DateTime?,
      isCompleted: fields[4] as bool,
      energyLevel: fields[5] as int,
      focusType: fields[6] as String,
      timeElasticity: fields[7] as String,
      hasAlarm: fields[8] as bool,
      hasNotification: fields[15] as bool,
      soundPath: fields[16] as String?,
      category: fields[9] as String?,
      createdAt: fields[10] as DateTime,
      alarmNotificationId: fields[11] as int?,
      isDaily: fields[12] as bool,
      lastCompletedDate: fields[13] as DateTime?,
      repeatDays: (fields[14] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.scheduledTime)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.energyLevel)
      ..writeByte(6)
      ..write(obj.focusType)
      ..writeByte(7)
      ..write(obj.timeElasticity)
      ..writeByte(8)
      ..write(obj.hasAlarm)
      ..writeByte(9)
      ..write(obj.category)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.alarmNotificationId)
      ..writeByte(12)
      ..write(obj.isDaily)
      ..writeByte(13)
      ..write(obj.lastCompletedDate)
      ..writeByte(14)
      ..write(obj.repeatDays)
      ..writeByte(15)
      ..write(obj.hasNotification)
      ..writeByte(16)
      ..write(obj.soundPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
