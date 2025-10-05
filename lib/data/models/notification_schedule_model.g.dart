// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_schedule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationScheduleModelAdapter
    extends TypeAdapter<NotificationScheduleModel> {
  @override
  final int typeId = 3;

  @override
  NotificationScheduleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationScheduleModel(
      id: fields[0] as String,
      habitNotificationId: fields[1] as String,
      dayOfWeek: fields[2] as String,
      scheduledTime: fields[3] as String,
      isActive: fields[4] as bool,
      snoozeCount: fields[5] as int,
      platformNotificationId: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationScheduleModel obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.platformNotificationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationScheduleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
