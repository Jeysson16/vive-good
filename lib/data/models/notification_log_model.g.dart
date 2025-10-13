// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationLogModelAdapter extends TypeAdapter<NotificationLogModel> {
  @override
  final int typeId = 5;

  @override
  NotificationLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationLogModel(
      id: fields[0] as String,
      notificationScheduleId: fields[1] as String,
      scheduledFor: fields[2] as DateTime,
      sentAt: fields[3] as DateTime?,
      status: fields[4] as NotificationStatus,
      actionTaken: fields[5] as NotificationAction?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.notificationScheduleId)
      ..writeByte(2)
      ..write(obj.scheduledFor)
      ..writeByte(3)
      ..write(obj.sentAt)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.actionTaken)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
