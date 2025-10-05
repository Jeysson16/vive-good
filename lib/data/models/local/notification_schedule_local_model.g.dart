// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_schedule_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationScheduleLocalModelAdapter
    extends TypeAdapter<NotificationScheduleLocalModel> {
  @override
  final int typeId = 11;

  @override
  NotificationScheduleLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationScheduleLocalModel(
      id: fields[0] as String,
      habitNotificationId: fields[1] as String,
      dayOfWeek: fields[2] as String,
      scheduledTime: fields[3] as String,
      isActive: fields[4] as bool,
      snoozeCount: fields[5] as int,
      lastTriggered: fields[6] as DateTime?,
      platformNotificationId: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationScheduleLocalModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitNotificationId)
      ..writeByte(2)
      ..write(obj.dayOfWeek)
      ..writeByte(3)
      ..write(obj.scheduledTime)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.snoozeCount)
      ..writeByte(6)
      ..write(obj.lastTriggered)
      ..writeByte(7)
      ..write(obj.platformNotificationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationScheduleLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
