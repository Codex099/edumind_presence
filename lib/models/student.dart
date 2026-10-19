import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 13)
class Student extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String matricule;

  @HiveField(2)
  final String firstName;

  @HiveField(3)
  final String lastName;

  @HiveField(4)
  final String fullName;

  @HiveField(5)
  final String groupId;

  @HiveField(6)
  final String groupName;

  @HiveField(7)
  final String photoUrl;

  @HiveField(8)
  final bool active;

  Student({
    required this.id,
    required this.matricule,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.groupId,
    this.groupName = '',
    this.photoUrl = '',
    this.active = true,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final act = json['active'];
    final isActive = act == 1 || act == true || act == '1' || act == 'true';
    final fn = json['first_name']?.toString() ?? '';
    final ln = json['last_name']?.toString() ?? '';
    final displayedName = json['full_name']?.toString() ?? '$fn $ln'.trim();

    return Student(
      id: json['id']?.toString() ?? '',
      matricule: json['matricule']?.toString() ?? '',
      firstName: fn,
      lastName: ln,
      fullName: displayedName.isNotEmpty ? displayedName : (json['name']?.toString() ?? 'Élève'),
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      active: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matricule': matricule,
    'first_name': firstName,
    'last_name': lastName,
    'full_name': fullName,
    'group_id': groupId,
    'group_name': groupName,
    'photo_url': photoUrl,
    'active': active ? 1 : 0,
  };
}
