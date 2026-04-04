// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SetAdapter extends TypeAdapter<Set> {
  @override
  final int typeId = 0;

  @override
  Set read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Set(
      id: fields[0] as String?,
      reps: fields[1] as int,
      weight: fields[2] as double,
      rpe: fields[3] as int?,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Set obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.rpe)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
