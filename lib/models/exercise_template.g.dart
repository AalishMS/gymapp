// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseTemplateAdapter extends TypeAdapter<ExerciseTemplate> {
  @override
  final int typeId = 2;

  @override
  ExerciseTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseTemplate(
      name: fields[0] as String,
      sets: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseTemplate obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.sets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
