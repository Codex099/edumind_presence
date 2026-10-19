import 'package:hive/hive.dart';

part 'schedule_slot.g.dart';

@HiveType(typeId: 12)
class ScheduleSlot extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String groupId;

  @HiveField(2)
  final String groupName;

  @HiveField(3)
  final String teacherId;

  @HiveField(4)
  final String teacherName;

  @HiveField(5)
  final String dayOfWeek; // 'Dimanche', 'Lundi', or 'الأحد', 'الإثنين'

  @HiveField(6)
  final String startTime; // '08:00'

  @HiveField(7)
  final String endTime;   // '09:00'

  @HiveField(8)
  final String roomName;

  @HiveField(9)
  final String subjectName;

  ScheduleSlot({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.teacherId,
    this.teacherName = '',
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomName = '',
    this.subjectName = '',
  });

  static String cleanTime(String raw) {
    if (raw.isEmpty) return '';
    final trimmed = raw.trim();

    // Already clean HH:mm or H:mm
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(trimmed);
    if (match != null) {
      final h = match.group(1)!.padLeft(2, '0');
      final m = match.group(2)!;
      return '$h:$m';
    }

    // Google Sheets Dec 30 1899 epoch ISO string (e.g. 1899-12-30T07:46:25.000Z)
    if (trimmed.contains('T')) {
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        if (dt.year == 1899) {
          final utcSeconds = dt.toUtc().hour * 3600 + dt.toUtc().minute * 60 + dt.toUtc().second;
          final adjustedSeconds = (utcSeconds + 815) % 86400;
          final h = (adjustedSeconds ~/ 3600).toString().padLeft(2, '0');
          final m = ((adjustedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
          return '$h:$m';
        } else {
          final loc = dt.toLocal();
          return '${loc.hour.toString().padLeft(2, '0')}:${loc.minute.toString().padLeft(2, '0')}';
        }
      }
    }

    return trimmed;
  }

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      startTime: cleanTime(json['start_time']?.toString() ?? ''),
      endTime: cleanTime(json['end_time']?.toString() ?? ''),
      roomName: json['room_name']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'group_name': groupName,
    'teacher_id': teacherId,
    'teacher_name': teacherName,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'room_name': roomName,
    'subject_name': subjectName,
  };

  String get cleanStartTime => cleanTime(startTime);
  String get cleanEndTime => cleanTime(endTime);

  /// Time slot label: "08:00 - 09:00"
  String get timeSlotLabel {
    final s = cleanStartTime;
    final e = cleanEndTime;
    if (s.isEmpty && e.isEmpty) return '';
    if (e.isEmpty) return s;
    return '$s - $e';
  }
}
