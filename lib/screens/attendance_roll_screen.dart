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
  final bool isReadOnly;

  const AttendanceRollScreen({
    super.key,
    required this.slot,
    this.isReadOnly = false,
  });

  @override
  State<AttendanceRollScreen> createState() => _AttendanceRollScreenState();
}

class _AttendanceRollScreenState extends State<AttendanceRollScreen> {
  final _syncService = Get.find<SyncService>();
  final _authService = Get.find<AuthService>();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSubmitting = false;
  late bool _isReadOnly;

  late List<Student> _allStudents;
  final Map<String, AttendanceStatus> _statusMap = {};
  final Map<String, String> _notesMap = {};

  @override
  void initState() {
    super.initState();
    _allStudents = _syncService.getStudentsForGroup(widget.slot.groupId);

    final todayStr = TimeUtils.getTodayDateString();
    final alreadySubmitted = _syncService.isSessionSubmitted(
      groupId: widget.slot.groupId,
      sessionDate: todayStr,
      timeSlot: widget.slot.timeSlotLabel,
    );

    _isReadOnly = widget.isReadOnly || alreadySubmitted;

    if (_isReadOnly) {
      // Restore existing attendance data
      final existingRecords = _syncService.getSessionAttendances(
        groupId: widget.slot.groupId,
        sessionDate: todayStr,
        timeSlot: widget.slot.timeSlotLabel,
      );
      final existingMap = {for (final r in existingRecords) r.studentId: r};

      // Ensure any student present in the submitted records is represented
      for (final r in existingRecords) {
        if (!_allStudents.any((s) => s.id == r.studentId)) {
          _allStudents.add(Student(
            id: r.studentId,
            matricule: r.studentMatricule,
            firstName: '',
            lastName: '',
            fullName: r.studentName,
            groupId: r.groupId,
            groupName: r.groupName,
          ));
        }
      }

      for (final st in _allStudents) {
        final rec = existingMap[st.id];
        _statusMap[st.id] = rec?.status ?? AttendanceStatus.present;
        _notesMap[st.id] = rec?.note ?? '';
      }
    } else {
      // Default: Every student is PRESENT
      for (final st in _allStudents) {
        _statusMap[st.id] = AttendanceStatus.present;
        _notesMap[st.id] = '';
      }
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
    if (_isReadOnly) {
      final lang = _authService.currentLang.value;
      Get.snackbar(
        AppTranslations.get('session_locked_title', lang: lang),
        AppTranslations.get('session_locked_desc', lang: lang),
        backgroundColor: EdumindTheme.cardDark,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.lock_outline_rounded, color: EdumindTheme.lateOrange),
      );
      return;
    }

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

  /// Displays a comprehensive confirmation sheet listing absent and late students before sending
  void _showAttendanceConfirmation() {
    final lang = _authService.currentLang.value;
    final isAr = lang == 'ar';
    final absentStudents = _allStudents.where((st) => _statusMap[st.id] == AttendanceStatus.absent).toList();
    final lateStudents = _allStudents.where((st) => _statusMap[st.id] == AttendanceStatus.late).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: EdumindTheme.bgDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: EdumindTheme.borderDark, width: 1.5),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header with Icon and Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EdumindTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.fact_check_outlined,
                            color: EdumindTheme.accentCyan,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.get('confirm_dialog_title', lang: lang),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.slot.groupName} · ${widget.slot.timeSlotLabel}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Counter Summary Badges
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: EdumindTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: EdumindTheme.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCountBadge(
                            '$_presentCount',
                            AppTranslations.get('present_count', lang: lang),
                            EdumindTheme.presentGreen,
                          ),
                          Container(width: 1, height: 28, color: EdumindTheme.borderDark),
                          _buildCountBadge(
                            '$_absentCount',
                            AppTranslations.get('absent_count', lang: lang),
                            EdumindTheme.absentRed,
                          ),
                          Container(width: 1, height: 28, color: EdumindTheme.borderDark),
                          _buildCountBadge(
                            '$_lateCount',
                            AppTranslations.get('late_count', lang: lang),
                            EdumindTheme.lateOrange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Scrollable Content (Absents & Late lists)
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // ABSENT SECTION
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: EdumindTheme.absentRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${AppTranslations.get('absent_students_list', lang: lang)} (${absentStudents.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: EdumindTheme.absentRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (absentStudents.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: EdumindTheme.presentGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: EdumindTheme.presentGreen.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: EdumindTheme.presentGreen, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    AppTranslations.get('no_absent_students', lang: lang),
                                    style: const TextStyle(
                                      color: EdumindTheme.presentGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...absentStudents.map((st) {
                            final note = _notesMap[st.id] ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: EdumindTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: EdumindTheme.absentRed.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: EdumindTheme.absentBgDark,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: EdumindTheme.absentRed.withValues(alpha: 0.4)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        st.fullName.isNotEmpty ? st.fullName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: EdumindTheme.absentRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          st.fullName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        if (st.matricule.isNotEmpty || note.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              if (st.matricule.isNotEmpty)
                                                Text(
                                                  st.matricule,
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                                                ),
                                              if (note.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: EdumindTheme.absentBgDark,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      note,
                                                      style: const TextStyle(fontSize: 10, color: EdumindTheme.absentRed),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: EdumindTheme.absentBgDark,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      AppTranslations.get('absent_count', lang: lang),
                                      style: const TextStyle(
                                        color: EdumindTheme.absentRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                        // LATE SECTION (if any)
                        if (lateStudents.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: EdumindTheme.lateOrange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${AppTranslations.get('late_students_list', lang: lang)} (${lateStudents.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: EdumindTheme.lateOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...lateStudents.map((st) {
                            final note = _notesMap[st.id] ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: EdumindTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: EdumindTheme.lateOrange.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: EdumindTheme.lateBgDark,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: EdumindTheme.lateOrange.withValues(alpha: 0.4)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        st.fullName.isNotEmpty ? st.fullName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: EdumindTheme.lateOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          st.fullName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        if (st.matricule.isNotEmpty || note.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              if (st.matricule.isNotEmpty)
                                                Text(
                                                  st.matricule,
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                                                ),
                                              if (note.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: EdumindTheme.lateBgDark,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      note,
                                                      style: const TextStyle(fontSize: 10, color: EdumindTheme.lateOrange),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: EdumindTheme.lateBgDark,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      AppTranslations.get('late_count', lang: lang),
                                      style: const TextStyle(
                                        color: EdumindTheme.lateOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 14),

                        // Lock Warning Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: EdumindTheme.lateOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EdumindTheme.lateOrange.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 20, color: EdumindTheme.lateOrange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppTranslations.get('confirm_lock_warning', lang: lang),
                                  style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: EdumindTheme.borderDark),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              AppTranslations.get('btn_review_edit', lang: lang),
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _submitAttendance();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EdumindTheme.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                            label: Text(
                              AppTranslations.get('btn_final_submit', lang: lang),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountBadge(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Future<void> _submitAttendance() async {
    if (_isReadOnly) return;

    final lang = _authService.currentLang.value;
    final teacher = _authService.currentTeacher.value;
    final todayStr = TimeUtils.getTodayDateString();
    final nowTs = DateTime.now().millisecondsSinceEpoch;

    // Guard against resubmission
    if (_syncService.isSessionSubmitted(
      groupId: widget.slot.groupId,
      sessionDate: todayStr,
      timeSlot: widget.slot.timeSlotLabel,
    )) {
      setState(() => _isReadOnly = true);
      Get.snackbar(
        AppTranslations.get('session_locked_title', lang: lang),
        AppTranslations.get('session_locked_desc', lang: lang),
        backgroundColor: EdumindTheme.cardDark,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final slotSlug = widget.slot.cleanStartTime.replaceAll(':', '');
    final records = _allStudents.map((st) {
      final stStatus = _statusMap[st.id] ?? AttendanceStatus.present;
      final stNote = _notesMap[st.id] ?? '';
      return AttendanceRecord(
        id: 'att_${widget.slot.groupId}_${slotSlug}_${st.id}_$todayStr',
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
      setState(() {
        _isSubmitting = false;
        _isReadOnly = true;
      });

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isReadOnly) ...[
                    const Icon(Icons.lock_rounded, size: 16, color: EdumindTheme.presentGreen),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.slot.groupName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
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

            // Top Status Banner: Locked Notice OR Interactive Tip
            if (_isReadOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: EdumindTheme.presentGreen.withValues(alpha: 0.12),
                  border: Border(
                    bottom: BorderSide(color: EdumindTheme.presentGreen.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 18, color: EdumindTheme.presentGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.get('session_locked_banner_title', lang: lang),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: EdumindTheme.presentGreen),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppTranslations.get('session_locked_banner_desc', lang: lang),
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
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
                          isReadOnly: _isReadOnly,
                          onToggleStatus: () => _cycleStatus(st.id),
                          onNoteChanged: (newNote) {
                            if (!_isReadOnly) {
                              setState(() => _notesMap[st.id] = newNote);
                            }
                          },
                        );
                      },
                    ),
            ),

            // Sticky Bottom Section: Read-Only Locked Notice OR Submit Button
            if (_isReadOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

                      // Locked notice pill
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: EdumindTheme.presentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: EdumindTheme.presentGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: EdumindTheme.presentGreen, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppTranslations.get('session_locked_footer', lang: lang),
                                      style: const TextStyle(
                                        color: EdumindTheme.presentGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppTranslations.get('session_locked_footer_sub', lang: lang),
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
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
                          onPressed: _isSubmitting ? null : _showAttendanceConfirmation,
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
