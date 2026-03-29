// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 4;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      date: fields[0] as DateTime,
      planName: fields[1] as String,
      exercises: (fields[2] as List).cast<Exercise>(),
      weekNumber: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.planName)
      ..writeByte(2)
      ..write(obj.exercises)
      ..writeByte(3)
      ..write(obj.weekNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
