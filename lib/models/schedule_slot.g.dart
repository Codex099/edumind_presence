part of 'schedule_slot.dart';

class ScheduleSlotAdapter extends TypeAdapter<ScheduleSlot> {
  @override
  final int typeId = 12;

  @override
  ScheduleSlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleSlot(
      id: fields[0] as String,
      groupId: fields[1] as String,
      groupName: fields[2] as String,
      teacherId: fields[3] as String,
      teacherName: fields[4] as String? ?? '',
      dayOfWeek: fields[5] as String,
      startTime: fields[6] as String,
      endTime: fields[7] as String,
      roomName: fields[8] as String? ?? '',
      subjectName: fields[9] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleSlot obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.groupName)
      ..writeByte(3)
      ..write(obj.teacherId)
      ..writeByte(4)
      ..write(obj.teacherName)
      ..writeByte(5)
      ..write(obj.dayOfWeek)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.roomName)
      ..writeByte(9)
      ..write(obj.subjectName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
