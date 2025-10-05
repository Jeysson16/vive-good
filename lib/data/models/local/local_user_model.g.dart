// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalUserModelAdapter extends TypeAdapter<LocalUserModel> {
  @override
  final int typeId = 3;

  @override
  LocalUserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalUserModel(
      id: fields[0] as String,
      email: fields[1] as String?,
      name: fields[2] as String?,
      avatarUrl: fields[3] as String?,
      birthDate: fields[4] as DateTime?,
      gender: fields[5] as String?,
      timezone: fields[6] as String?,
      preferences: (fields[7] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      isLocalOnly: fields[10] as bool,
      needsSync: fields[11] as bool,
      lastSyncAt: fields[12] as DateTime?,
      isActive: fields[13] as bool,
      lastLoginAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalUserModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.birthDate)
      ..writeByte(5)
      ..write(obj.gender)
      ..writeByte(6)
      ..write(obj.timezone)
      ..writeByte(7)
      ..write(obj.preferences)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.isLocalOnly)
      ..writeByte(11)
      ..write(obj.needsSync)
      ..writeByte(12)
      ..write(obj.lastSyncAt)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.lastLoginAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalUserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
