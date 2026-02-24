// lib/models/alarm_log.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmLogAdapter extends TypeAdapter<AlarmLog> {
  @override
  final int typeId = 1;

  @override
  AlarmLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmLog(
      id: fields[0] as String,
      medicineId: fields[1] as String,
      scheduledDateTime: fields[2] as DateTime,
      status: fields[3] as String,
      actualTakenTime: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicineId)
      ..writeByte(2)
      ..write(obj.scheduledDateTime)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.actualTakenTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
