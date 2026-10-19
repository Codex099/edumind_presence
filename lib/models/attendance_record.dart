import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 14)
enum AttendanceStatus {
  @HiveField(0)
  present,

  @HiveField(1)
  absent,

  @HiveField(2)
  late,
}

@HiveType(typeId: 15)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionDate; // YYYY-MM-DD

  @HiveField(2)
  final String timeSlot;    // '08:00 - 09:00'

  @HiveField(3)
  final String groupId;

  @HiveField(4)
  final String groupName;

  @HiveField(5)
  final String subjectName;

  @HiveField(6)
  final String roomName;

  @HiveField(7)
  final String teacherId;

  @HiveField(8)
  final String teacherName;

  @HiveField(9)
  final String studentId;

  @HiveField(10)
  final String studentMatricule;

  @HiveField(11)
  final String studentName;

  @HiveField(12)
  AttendanceStatus status;

  @HiveField(13)
  String note;

  @HiveField(14)
  final int timestamp; // epoch ms

  @HiveField(15)
  bool isSynced;

  AttendanceRecord({
    required this.id,
    required this.sessionDate,
    required this.timeSlot,
    required this.groupId,
    this.groupName = '',
    this.subjectName = '',
    this.roomName = '',
    required this.teacherId,
    this.teacherName = '',
    required this.studentId,
    this.studentMatricule = '',
    required this.studentName,
    this.status = AttendanceStatus.present,
    this.note = '',
    required this.timestamp,
    this.isSynced = false,
  });

  String get statusString {
    switch (status) {
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.present:
        return 'present';
    }
  }

  static AttendanceStatus parseStatus(String? str) {
    if (str == null) return AttendanceStatus.present;
    final lower = str.toLowerCase().trim();
    if (lower == 'absent' || lower == 'غائب') return AttendanceStatus.absent;
    if (lower == 'late' || lower == 'retard' || lower == 'متأخر') return AttendanceStatus.late;
    return AttendanceStatus.present;
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      sessionDate: json['session_date']?.toString() ?? '',
      timeSlot: json['time_slot']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentMatricule: json['student_matricule']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      status: parseStatus(json['status']?.toString()),
      note: json['note']?.toString() ?? '',
      timestamp: int.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_date': sessionDate,
    'time_slot': timeSlot,
    'group_id': groupId,
    'group_name': groupName,
    'subject_name': subjectName,
    'room_name': roomName,
    'teacher_id': teacherId,
    'teacher_name': teacherName,
    'student_id': studentId,
    'student_matricule': studentMatricule,
    'student_name': studentName,
    'status': statusString,
    'note': note,
    'timestamp': timestamp,
  };
}
