// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_step_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OnboardingStepModelAdapter extends TypeAdapter<OnboardingStepModel> {
  @override
  final int typeId = 1;

  @override
  OnboardingStepModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OnboardingStepModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      imagePath: fields[3] as String,
      order: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OnboardingStepModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingStepModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
