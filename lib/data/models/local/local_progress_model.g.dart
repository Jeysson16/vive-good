// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalProgressModelAdapter extends TypeAdapter<LocalProgressModel> {
  @override
  final int typeId = 2;

  @override
  LocalProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalProgressModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      habitId: fields[2] as String,
      date: fields[3] as DateTime,
      completed: fields[4] as bool,
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      isLocalOnly: fields[8] as bool,
      needsSync: fields[9] as bool,
      lastSyncAt: fields[10] as DateTime?,
      value: fields[11] as double?,
      unit: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalProgressModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.habitId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.isLocalOnly)
      ..writeByte(9)
      ..write(obj.needsSync)
      ..writeByte(10)
      ..write(obj.lastSyncAt)
      ..writeByte(11)
      ..write(obj.value)
      ..writeByte(12)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
