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
      notificationId: fields[1] as String,
      action: fields[2] as String,
      timestamp: fields[3] as DateTime,
      details: fields[4] as String?,
      errorMessage: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationLogModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.notificationId)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.details)
      ..writeByte(5)
      ..write(obj.errorMessage);
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
