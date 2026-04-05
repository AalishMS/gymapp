// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queued_operation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueuedOperationAdapter extends TypeAdapter<QueuedOperation> {
  @override
  final int typeId = 5;

  @override
  QueuedOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedOperation(
      id: fields[0] as String,
      action: fields[1] as String,
      entity: fields[2] as String,
      payload: (fields[3] as Map).cast<String, dynamic>(),
      timestamp: fields[4] as DateTime,
      retryCount: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedOperation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.entity)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
