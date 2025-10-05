// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_sync_operation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalSyncOperationModelAdapter
    extends TypeAdapter<LocalSyncOperationModel> {
  @override
  final int typeId = 4;

  @override
  LocalSyncOperationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSyncOperationModel(
      id: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      operationType: fields[3] as int,
      data: (fields[4] as Map).cast<String, dynamic>(),
      status: fields[5] as int,
      createdAt: fields[6] as DateTime,
      lastAttemptAt: fields[7] as DateTime?,
      retryCount: fields[8] as int,
      errorMessage: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalSyncOperationModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.operationType)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastAttemptAt)
      ..writeByte(8)
      ..write(obj.retryCount)
      ..writeByte(9)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSyncOperationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
