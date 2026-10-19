import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/schedule_slot.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';
import '../utils/time_utils.dart';
import '../widgets/student_card.dart';
import '../widgets/status_counter_bar.dart';

class AttendanceRollScreen extends StatefulWidget {
  final ScheduleSlot slot;

  const AttendanceRollScreen({super.key, required this.slot});

  @override
  State<AttendanceRollScreen> createState() => _AttendanceRollScreenState();
}

class _AttendanceRollScreenState extends State<AttendanceRollScreen> {
  final _syncService = Get.find<SyncService>();
  final _authService = Get.find<AuthService>();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSubmitting = false;

  late List<Student> _allStudents;
  final Map<String, AttendanceStatus> _statusMap = {};
  final Map<String, String> _notesMap = {};

  @override
  void initState() {
    super.initState();
    _allStudents = _syncService.getStudentsForGroup(widget.slot.groupId);

    // Default: Every student is PRESENT
    for (final st in _allStudents) {
      _statusMap[st.id] = AttendanceStatus.present;
      _notesMap[st.id] = '';
    }

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cycleStatus(String studentId) {
    setState(() {
      final current = _statusMap[studentId] ?? AttendanceStatus.present;
      switch (current) {
        case AttendanceStatus.present:
          _statusMap[studentId] = AttendanceStatus.absent;
          break;
        case AttendanceStatus.absent:
          _statusMap[studentId] = AttendanceStatus.late;
          break;
        case AttendanceStatus.late:
          _statusMap[studentId] = AttendanceStatus.present;
          break;
      }
    });
  }

  int get _presentCount => _statusMap.values.where((s) => s == AttendanceStatus.present).length;
  int get _absentCount => _statusMap.values.where((s) => s == AttendanceStatus.absent).length;
  int get _lateCount => _statusMap.values.where((s) => s == AttendanceStatus.late).length;

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _allStudents;
    return _allStudents.where((st) {
      return st.fullName.toLowerCase().contains(_searchQuery) ||
             st.matricule.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _submitAttendance() async {
    final lang = _authService.currentLang.value;
    final teacher = _authService.currentTeacher.value;
    final todayStr = TimeUtils.getTodayDateString();
    final nowTs = DateTime.now().millisecondsSinceEpoch;

    setState(() => _isSubmitting = true);

    final records = _allStudents.map((st) {
      final stStatus = _statusMap[st.id] ?? AttendanceStatus.present;
      final stNote = _notesMap[st.id] ?? '';
      return AttendanceRecord(
        id: 'att_${widget.slot.groupId}_${st.id}_$todayStr',
        sessionDate: todayStr,
        timeSlot: widget.slot.timeSlotLabel,
        groupId: widget.slot.groupId,
        groupName: widget.slot.groupName,
        subjectName: widget.slot.subjectName,
        roomName: widget.slot.roomName,
        teacherId: teacher?.id ?? widget.slot.teacherId,
        teacherName: teacher?.name ?? widget.slot.teacherName,
        studentId: st.id,
        studentMatricule: st.matricule,
        studentName: st.fullName,
        status: stStatus,
        note: stNote,
        timestamp: nowTs,
      );
    }).toList();

    await _syncService.submitAttendanceRoll(records);

    final isOnline = Get.find<ConnectivityService>().isOnline.value;

    if (mounted) {
      setState(() => _isSubmitting = false);

      Get.snackbar(
        AppTranslations.get('attendance_sheet', lang: lang),
        isOnline ? AppTranslations.get('saved_online', lang: lang) : AppTranslations.get('saved_offline', lang: lang),
        backgroundColor: isOnline ? EdumindTheme.presentGreen : EdumindTheme.lateOrange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: Icon(
          isOnline ? Icons.cloud_done_rounded : Icons.save_alt_rounded,
          color: Colors.white,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _authService.currentLang.value;
    final isAr = lang == 'ar';
    final filtered = _filteredStudents;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: EdumindTheme.bgDark,
        appBar: AppBar(
          backgroundColor: EdumindTheme.bgDark,
          title: Column(
            children: [
              Text(
                widget.slot.groupName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.slot.subjectName} · ${widget.slot.timeSlotLabel} · ${AppTranslations.get('room', lang: lang)} ${widget.slot.roomName}',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Live Counter Bar
            StatusCounterBar(
              total: _allStudents.length,
              present: _presentCount,
              absent: _absentCount,
              late: _lateCount,
              lang: lang,
            ),

            // Tip Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: EdumindTheme.cardSubtleDark,
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, size: 16, color: EdumindTheme.accentCyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppTranslations.get('tap_tip', lang: lang),
                      style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // Search Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppTranslations.get('search_student', lang: lang),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),

            // Students List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'لا يوجد تلاميذ مطابقين',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final st = filtered[index];
                        final status = _statusMap[st.id] ?? AttendanceStatus.present;
                        final note = _notesMap[st.id] ?? '';

                        return StudentCard(
                          student: st,
                          status: status,
                          note: note,
                          lang: lang,
                          onToggleStatus: () => _cycleStatus(st.id),
                          onNoteChanged: (newNote) {
                            setState(() => _notesMap[st.id] = newNote);
                          },
                        );
                      },
                    ),
            ),

            // Sticky Bottom Submit Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: EdumindTheme.cardDark,
                border: Border(top: BorderSide(color: EdumindTheme.borderDark)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Quick counts summary pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: EdumindTheme.inputDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_absentCount غائب',
                            style: const TextStyle(
                              color: EdumindTheme.absentRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$_lateCount متأخر',
                            style: const TextStyle(
                              color: EdumindTheme.lateOrange,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Confirm and Send Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EdumindTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          AppTranslations.get('confirm_submit', lang: lang),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
