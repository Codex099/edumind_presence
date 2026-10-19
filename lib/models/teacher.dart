import 'package:hive/hive.dart';

part 'teacher.g.dart';

@HiveType(typeId: 10)
class Teacher extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String matricule;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String subject;

  @HiveField(5)
  final bool active;

  Teacher({
    required this.id,
    required this.matricule,
    required this.name,
    required this.phone,
    required this.subject,
    this.active = true,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final act = json['active'];
    final isActive = act == 1 || act == true || act == '1' || act == 'true';
    return Teacher(
      id: json['id']?.toString() ?? '',
      matricule: json['matricule']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      active: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matricule': matricule,
    'name': name,
    'phone': phone,
    'subject': subject,
    'active': active ? 1 : 0,
  };
}
