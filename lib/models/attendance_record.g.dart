part of 'attendance_record.dart';

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  final int typeId = 14;

  @override
  AttendanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceStatus.present;
      case 1:
        return AttendanceStatus.absent;
      case 2:
        return AttendanceStatus.late;
      default:
        return AttendanceStatus.present;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    switch (obj) {
      case AttendanceStatus.present:
        writer.writeByte(0);
        break;
      case AttendanceStatus.absent:
        writer.writeByte(1);
        break;
      case AttendanceStatus.late:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 15;

  @override
  AttendanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceRecord(
      id: fields[0] as String,
      sessionDate: fields[1] as String,
      timeSlot: fields[2] as String,
      groupId: fields[3] as String,
      groupName: fields[4] as String? ?? '',
      subjectName: fields[5] as String? ?? '',
      roomName: fields[6] as String? ?? '',
      teacherId: fields[7] as String,
      teacherName: fields[8] as String? ?? '',
      studentId: fields[9] as String,
      studentMatricule: fields[10] as String? ?? '',
      studentName: fields[11] as String,
      status: fields[12] as AttendanceStatus? ?? AttendanceStatus.present,
      note: fields[13] as String? ?? '',
      timestamp: fields[14] as int? ?? 0,
      isSynced: fields[15] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionDate)
      ..writeByte(2)
      ..write(obj.timeSlot)
      ..writeByte(3)
      ..write(obj.groupId)
      ..writeByte(4)
      ..write(obj.groupName)
      ..writeByte(5)
      ..write(obj.subjectName)
      ..writeByte(6)
      ..write(obj.roomName)
      ..writeByte(7)
      ..write(obj.teacherId)
      ..writeByte(8)
      ..write(obj.teacherName)
      ..writeByte(9)
      ..write(obj.studentId)
      ..writeByte(10)
      ..write(obj.studentMatricule)
      ..writeByte(11)
      ..write(obj.studentName)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.note)
      ..writeByte(14)
      ..write(obj.timestamp)
      ..writeByte(15)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
