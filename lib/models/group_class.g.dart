part of 'group_class.dart';

class GroupClassAdapter extends TypeAdapter<GroupClass> {
  @override
  final int typeId = 11;

  @override
  GroupClass read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupClass(
      id: fields[0] as String,
      name: fields[1] as String,
      levelName: fields[2] as String? ?? '',
      subjectName: fields[3] as String? ?? '',
      roomName: fields[4] as String? ?? '',
      teacherId: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, GroupClass obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.levelName)
      ..writeByte(3)
      ..write(obj.subjectName)
      ..writeByte(4)
      ..write(obj.roomName)
      ..writeByte(5)
      ..write(obj.teacherId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupClassAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
