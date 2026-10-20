import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/group_class.dart';
import '../models/schedule_slot.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../utils/time_utils.dart';
import 'sheets_service.dart';
import 'connectivity_service.dart';
import 'pending_queue_service.dart';
import 'auth_service.dart';

class SyncService extends GetxService {
  static const String groupsBoxName    = 'cached_groups';
  static const String schedulesBoxName = 'cached_schedules';
  static const String studentsBoxName  = 'cached_students';
  static const String attendancesBoxName = 'cached_attendances';

  late final Box<GroupClass> _groupsBox;
  late final Box<ScheduleSlot> _schedulesBox;
  late final Box<Student> _studentsBox;
  late final Box<AttendanceRecord> _attendancesBox;

  final isLoading = false.obs;
  final attendancesVersion = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _groupsBox = Hive.box<GroupClass>(groupsBoxName);
    _schedulesBox = Hive.box<ScheduleSlot>(schedulesBoxName);
    _studentsBox = Hive.box<Student>(studentsBoxName);
    _attendancesBox = Hive.box<AttendanceRecord>(attendancesBoxName);
  }

  List<GroupClass> get groups => _groupsBox.values.toList();
  List<ScheduleSlot> get schedules => _schedulesBox.values.toList();
  List<Student> get students => _studentsBox.values.toList();
  List<AttendanceRecord> get attendances => _attendancesBox.values.toList();

  static String normalizeSlot(String s) => s.replaceAll(' ', '').trim();

  /// Checks whether an attendance roll has already been submitted for a given slot/session
  bool isSessionSubmitted({
    required String groupId,
    required String sessionDate,
    String? timeSlot,
  }) {
    // Read attendancesVersion for reactive listeners in Obx
    final _ = attendancesVersion.value;
    final cleanSlot = normalizeSlot(timeSlot ?? '');
    return _attendancesBox.values.any((att) {
      if (att.groupId != groupId || att.sessionDate != sessionDate) return false;
      if (cleanSlot.isNotEmpty && att.timeSlot.isNotEmpty) {
        return normalizeSlot(att.timeSlot) == cleanSlot;
      }
      return true;
    });
  }

  /// Gets existing attendance records for a specific session
  List<AttendanceRecord> getSessionAttendances({
    required String groupId,
    required String sessionDate,
    String? timeSlot,
  }) {
    final cleanSlot = normalizeSlot(timeSlot ?? '');
    return _attendancesBox.values.where((att) {
      if (att.groupId != groupId || att.sessionDate != sessionDate) return false;
      if (cleanSlot.isNotEmpty && att.timeSlot.isNotEmpty) {
        return normalizeSlot(att.timeSlot) == cleanSlot;
      }
      return true;
    }).toList();
  }

  /// Returns slots scheduled for today
  List<ScheduleSlot> get todaySchedules {
    final list = schedules.where((s) => TimeUtils.isTodaySlot(s)).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  /// Returns current active slot if any right now
  ScheduleSlot? get currentActiveSlot {
    return TimeUtils.findCurrentActiveSlot(schedules);
  }

  /// Returns next upcoming slot today if any
  ScheduleSlot? get nextUpcomingSlot {
    return TimeUtils.findNextUpcomingSlot(schedules);
  }

  /// Returns students enrolled in a specific group
  List<Student> getStudentsForGroup(String groupId) {
    return students.where((st) => st.groupId == groupId && st.active).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  /// Fetches and caches teacher's groups, schedule slots, and students from Sheets
  Future<bool> refreshTeacherData() async {
    final auth = Get.find<AuthService>();
    final teacher = auth.currentTeacher.value;
    if (teacher == null) return false;

    final conn = Get.find<ConnectivityService>();
    if (!conn.isOnline.value) return false;

    isLoading.value = true;
    try {
      final sheets = Get.find<SheetsService>();
      final result = await sheets.fetchTeacherData(teacher.id);

      if (result['success'] == true) {
        // Cache groups
        final List<GroupClass> newGroups = result['groups'];
        await _groupsBox.clear();
        for (final g in newGroups) {
          await _groupsBox.put(g.id, g);
        }

        // Cache schedules
        final List<ScheduleSlot> newSchedules = result['schedules'];
        await _schedulesBox.clear();
        for (final s in newSchedules) {
          await _schedulesBox.put(s.id, s);
        }

        // Cache students
        final List<Student> newStudents = result['students'];
        await _studentsBox.clear();
        for (final st in newStudents) {
          await _studentsBox.put(st.id, st);
        }

        // Fetch and cache today's existing attendances from Sheets
        try {
          final todayStr = TimeUtils.getTodayDateString();
          final remoteAttendances = await sheets.fetchTeacherAttendances(teacher.id, date: todayStr);
          for (final att in remoteAttendances) {
            await _attendancesBox.put(att.id, att);
          }
        } catch (_) {}

        attendancesVersion.value++;
        isLoading.value = false;
        return true;
      }
    } catch (_) {}

    // Fallback: If cache is empty, seed demo data for immediate offline testing
    if (_groupsBox.isEmpty) {
      await seedDemoData(teacher.id);
    }

    isLoading.value = false;
    return false;
  }

  /// Seeds realistic demo data for testing when offline or Google Sheets is not yet configured
  Future<void> seedDemoData(String teacherId) async {
    final now = DateTime.now();
    final todayArabic = TimeUtils.getTodayDayName(inArabic: true);
    final currentH = now.hour;
    final startHStr = currentH.toString().padLeft(2, '0');
    final endHStr = (currentH + 1).toString().padLeft(2, '0');
    final nextHStr = (currentH + 2).toString().padLeft(2, '0');
    final nextEndHStr = (currentH + 3).toString().padLeft(2, '0');

    // Groups
    final g1 = GroupClass(id: '1', name: '1AS-G1 (أولى ثانوي)', levelName: 'المرحلة الثانوية', subjectName: 'الرياضيات', roomName: 'قاعة 04', teacherId: teacherId);
    final g2 = GroupClass(id: '2', name: '2AS-G2 (ثانية ثانوي)', levelName: 'المرحلة الثانوية', subjectName: 'الرياضيات', roomName: 'مدرج العلوم', teacherId: teacherId);
    await _groupsBox.clear();
    await _groupsBox.put(g1.id, g1);
    await _groupsBox.put(g2.id, g2);

    // Schedules
    final s1 = ScheduleSlot(
      id: '101',
      groupId: g1.id,
      groupName: g1.name,
      teacherId: teacherId,
      teacherName: 'الأستاذ الرئيسي',
      dayOfWeek: todayArabic,
      startTime: '$startHStr:00',
      endTime: '$endHStr:00',
      roomName: g1.roomName,
      subjectName: g1.subjectName,
    );
    final s2 = ScheduleSlot(
      id: '102',
      groupId: g2.id,
      groupName: g2.name,
      teacherId: teacherId,
      teacherName: 'الأستاذ الرئيسي',
      dayOfWeek: todayArabic,
      startTime: '$nextHStr:00',
      endTime: '$nextEndHStr:00',
      roomName: g2.roomName,
      subjectName: g2.subjectName,
    );
    await _schedulesBox.clear();
    await _schedulesBox.put(s1.id, s1);
    await _schedulesBox.put(s2.id, s2);

    // Students for Group 1
    final studentsList = [
      Student(id: '1', matricule: 'ETU-001', firstName: 'محمد أمين', lastName: 'بلقاسم', fullName: 'محمد أمين بلقاسم', groupId: g1.id, groupName: g1.name),
      Student(id: '2', matricule: 'ETU-002', firstName: 'سارة', lastName: 'عثماني', fullName: 'سارة عثماني', groupId: g1.id, groupName: g1.name),
      Student(id: '3', matricule: 'ETU-003', firstName: 'يوسف', lastName: 'بلحاج', fullName: 'يوسف بلحاج', groupId: g1.id, groupName: g1.name),
      Student(id: '4', matricule: 'ETU-004', firstName: 'إيناس', lastName: 'شريف', fullName: 'إيناس شريف', groupId: g1.id, groupName: g1.name),
      Student(id: '5', matricule: 'ETU-005', firstName: 'ريان', lastName: 'حداد', fullName: 'ريان حداد', groupId: g1.id, groupName: g1.name),
      Student(id: '6', matricule: 'ETU-006', firstName: 'مريم', lastName: 'بوزيد', fullName: 'مريم بوزيد', groupId: g1.id, groupName: g1.name),
      Student(id: '7', matricule: 'ETU-007', firstName: 'أحمد', lastName: 'بن علي', fullName: 'أحمد بن علي', groupId: g1.id, groupName: g1.name),
      Student(id: '8', matricule: 'ETU-008', firstName: 'فاطمة الزهراء', lastName: 'قاسمي', fullName: 'فاطمة الزهراء قاسمي', groupId: g1.id, groupName: g1.name),
      Student(id: '9', matricule: 'ETU-009', firstName: 'حمزة', lastName: 'تواتي', fullName: 'حمزة تواتي', groupId: g1.id, groupName: g1.name),
      Student(id: '10', matricule: 'ETU-010', firstName: 'نور الهدى', lastName: 'معمر', fullName: 'نور الهدى معمر', groupId: g1.id, groupName: g1.name),
      // Students for Group 2
      Student(id: '11', matricule: 'ETU-011', firstName: 'ياسين', lastName: 'عماري', fullName: 'ياسين عماري', groupId: g2.id, groupName: g2.name),
      Student(id: '12', matricule: 'ETU-012', firstName: 'خديجة', lastName: 'بن سالم', fullName: 'خديجة بن سالم', groupId: g2.id, groupName: g2.name),
      Student(id: '13', matricule: 'ETU-013', firstName: 'وليد', lastName: 'براهيمي', fullName: 'وليد براهيمي', groupId: g2.id, groupName: g2.name),
      Student(id: '14', matricule: 'ETU-014', firstName: 'آية', lastName: 'منصوري', fullName: 'آية منصوري', groupId: g2.id, groupName: g2.name),
      Student(id: '15', matricule: 'ETU-015', firstName: 'عبد الرحمن', lastName: 'زروق', fullName: 'عبد الرحمن زروق', groupId: g2.id, groupName: g2.name),
    ];
    await _studentsBox.clear();
    for (final st in studentsList) {
      await _studentsBox.put(st.id, st);
    }
  }

  /// Submits an attendance roll: caches locally and sends/enqueues
  Future<bool> submitAttendanceRoll(List<AttendanceRecord> records) async {
    if (records.isEmpty) return true;

    // 1. Save in local cache
    for (final r in records) {
      await _attendancesBox.put(r.id, r);
    }
    attendancesVersion.value++;

    // 2. Queue for sync (which immediately pushes if online)
    final queue = Get.find<PendingQueueService>();
    await queue.enqueueAttendanceSheet(records);

    return true;
  }
}
