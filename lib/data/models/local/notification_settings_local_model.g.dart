// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingsLocalModelAdapter
    extends TypeAdapter<NotificationSettingsLocalModel> {
  @override
  final int typeId = 13;

  @override
  NotificationSettingsLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettingsLocalModel(
      userId: fields[0] as String,
      globalNotificationsEnabled: fields[1] as bool,
      permissionsGranted: fields[2] as bool,
      quietHoursStart: fields[3] as String?,
      quietHoursEnd: fields[4] as String?,
      defaultSnoozeMinutes: fields[5] as int,
      maxSnoozeCount: fields[6] as int,
      defaultNotificationSound: fields[7] as String,
      updatedAt: fields[8] as DateTime,
      needsSync: fields[9] as bool,
      lastSyncAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettingsLocalModel obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.needsSync)
      ..writeByte(10)
      ..write(obj.lastSyncAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
