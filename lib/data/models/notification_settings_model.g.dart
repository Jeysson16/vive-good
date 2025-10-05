// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingsModelAdapter
    extends TypeAdapter<NotificationSettingsModel> {
  @override
  final int typeId = 4;

  @override
  NotificationSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettingsModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      globalNotificationsEnabled: fields[2] as bool,
      quietHoursEnabled: fields[3] as bool,
      quietHoursStart: fields[4] as DateTime,
      quietHoursEnd: fields[5] as DateTime,
      snoozeMinutes: fields[6] as int,
      maxSnoozeCount: fields[7] as int,
      defaultSound: fields[8] as String,
      vibrationEnabled: fields[9] as bool,
      defaultPriority: fields[10] as int,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettingsModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.globalNotificationsEnabled)
      ..writeByte(3)
      ..write(obj.quietHoursEnabled)
      ..writeByte(4)
      ..write(obj.quietHoursStart)
      ..writeByte(5)
      ..write(obj.quietHoursEnd)
      ..writeByte(6)
      ..write(obj.snoozeMinutes)
      ..writeByte(7)
      ..write(obj.maxSnoozeCount)
      ..writeByte(8)
      ..write(obj.defaultSound)
      ..writeByte(9)
      ..write(obj.vibrationEnabled)
      ..writeByte(10)
      ..write(obj.defaultPriority)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
