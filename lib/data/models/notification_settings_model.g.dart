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
      userId: fields[0] as String,
      globalNotificationsEnabled: fields[1] as bool,
      permissionsGranted: fields[2] as bool,
      quietHoursStart: fields[3] as String?,
      quietHoursEnd: fields[4] as String?,
      defaultSnoozeMinutes: fields[5] as int,
      maxSnoozeCount: fields[6] as int,
      defaultNotificationSound: fields[7] as String,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettingsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.globalNotificationsEnabled)
      ..writeByte(2)
      ..write(obj.permissionsGranted)
      ..writeByte(3)
      ..write(obj.quietHoursStart)
      ..writeByte(4)
      ..write(obj.quietHoursEnd)
      ..writeByte(5)
      ..write(obj.defaultSnoozeMinutes)
      ..writeByte(6)
      ..write(obj.maxSnoozeCount)
      ..writeByte(7)
      ..write(obj.defaultNotificationSound)
      ..writeByte(8)
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
