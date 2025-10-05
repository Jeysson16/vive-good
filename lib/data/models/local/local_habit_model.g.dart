// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_habit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalHabitModelAdapter extends TypeAdapter<LocalHabitModel> {
  @override
  final int typeId = 1;

  @override
  LocalHabitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalHabitModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      categoryId: fields[3] as String?,
      iconName: fields[4] as String?,
      color: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      isLocalOnly: fields[8] as bool,
      needsSync: fields[9] as bool,
      lastSyncAt: fields[10] as DateTime?,
      isActive: fields[11] as bool,
      targetFrequency: fields[12] as int?,
      frequencyType: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalHabitModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.iconName)
      ..writeByte(5)
      ..write(obj.color)
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
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.targetFrequency)
      ..writeByte(13)
      ..write(obj.frequencyType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalHabitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
