import 'package:hive/hive.dart';

part 'group_class.g.dart';

@HiveType(typeId: 11)
class GroupClass extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String levelName;

  @HiveField(3)
  final String subjectName;

  @HiveField(4)
  final String roomName;

  @HiveField(5)
  final String teacherId;

  GroupClass({
    required this.id,
    required this.name,
    this.levelName = '',
    this.subjectName = '',
    this.roomName = '',
    this.teacherId = '',
  });

  factory GroupClass.fromJson(Map<String, dynamic> json) {
    return GroupClass(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      levelName: json['level_name']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level_name': levelName,
    'subject_name': subjectName,
    'room_name': roomName,
    'teacher_id': teacherId,
  };
}
