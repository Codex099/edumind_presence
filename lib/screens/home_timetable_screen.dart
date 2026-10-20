import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../models/schedule_slot.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';
import '../utils/time_utils.dart';
import '../widgets/offline_banner.dart';
import 'attendance_roll_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeTimetableScreen extends StatefulWidget {
  const HomeTimetableScreen({super.key});

  @override
  State<HomeTimetableScreen> createState() => _HomeTimetableScreenState();
}

class _HomeTimetableScreenState extends State<HomeTimetableScreen> {
  final _syncService = Get.find<SyncService>();
  final _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    _syncService.refreshTeacherData();
  }

  void _openAttendance(ScheduleSlot slot, {bool isReadOnly = false}) {
    Get.to(() => AttendanceRollScreen(slot: slot, isReadOnly: isReadOnly));
  }

  void _showManualClassPicker(BuildContext context, String lang) {
    final groups = _syncService.groups;
    if (groups.isEmpty) {
      Get.snackbar('EDUMIND', 'لا توجد أقسام مسندة لك', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: EdumindTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.get('manual_selection', lang: lang),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, i) {
                      final g = groups[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: EdumindTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.groups_rounded, color: EdumindTheme.primaryBlue),
                        ),
                        title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${g.subjectName} · ${g.roomName}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.pop(ctx);
                          final manualSlot = ScheduleSlot(
                            id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                            groupId: g.id,
                            groupName: g.name,
                            teacherId: _authService.currentTeacher.value?.id ?? '',
                            teacherName: _authService.currentTeacher.value?.name ?? '',
                            dayOfWeek: TimeUtils.getTodayDayName(inArabic: lang == 'ar'),
                            startTime: DateFormat('HH:00').format(DateTime.now()),
                            endTime: DateFormat('HH:00').format(DateTime.now().add(const Duration(hours: 1))),
                            roomName: g.roomName,
                            subjectName: g.subjectName,
                          );
                          _openAttendance(manualSlot);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = Get.find<ConnectivityService>();

    return Obx(() {
      final _ = _syncService.attendancesVersion.value;
      final lang = _authService.currentLang.value;
      final isAr = lang == 'ar';
      final teacher = _authService.currentTeacher.value;
      final activeSlot = _syncService.currentActiveSlot;
      final nextSlot = _syncService.nextUpcomingSlot;
      final todaySlots = _syncService.todaySchedules;

      return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: EdumindTheme.bgDark,
          appBar: AppBar(
            backgroundColor: EdumindTheme.bgDark,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conn.isOnline.value ? EdumindTheme.presentGreen : EdumindTheme.lateOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  teacher?.name ?? AppTranslations.get('app_title', lang: lang),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                tooltip: AppTranslations.get('history_title', lang: lang),
                onPressed: () => Get.to(() => const HistoryScreen()),
              ),
              IconButton(
                icon: _syncService.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync_rounded, color: Colors.white),
                tooltip: 'Sync',
                onPressed: () => _syncService.refreshTeacherData(),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: AppTranslations.get('settings', lang: lang),
                onPressed: () => Get.to(() => const SettingsScreen()),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: EdumindTheme.primaryBlue,
            backgroundColor: EdumindTheme.cardDark,
            onRefresh: () => _syncService.refreshTeacherData(),
            child: Column(
              children: [
                OfflineBanner(lang: lang),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    children: [
                      // Date Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            TimeUtils.formatDisplayDate(DateTime.now(), lang: lang),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: EdumindTheme.accentCyan,
                            ),
                          ),
                          if (teacher != null && teacher.subject.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: EdumindTheme.primaryBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: EdumindTheme.primaryBlue.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                teacher.subject,
                                style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── HERO CARD: Active Class OR Free Period ──
                      if (activeSlot != null)
                        _buildActiveSlotHero(activeSlot, lang)
                      else
                        _buildFreePeriodHero(nextSlot, lang),

                      const SizedBox(height: 24),

                      // Today's Timetable Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppTranslations.get('today_schedule', lang: lang),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          TextButton.icon(
                            onPressed: () => _showManualClassPicker(context, lang),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: EdumindTheme.accentCyan),
                            label: Text(
                              AppTranslations.get('manual_selection', lang: lang),
                              style: const TextStyle(fontSize: 12, color: EdumindTheme.accentCyan),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (todaySlots.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: EdumindTheme.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: EdumindTheme.borderDark),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(
                                AppTranslations.get('no_schedule_today', lang: lang),
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ...todaySlots.map((slot) => _buildSlotCard(slot, lang)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildActiveSlotHero(ScheduleSlot slot, String lang) {
    final enrolledCount = _syncService.getStudentsForGroup(slot.groupId).length;
    final todayStr = TimeUtils.getTodayDateString();
    final isSubmitted = _syncService.isSessionSubmitted(
      groupId: slot.groupId,
      sessionDate: todayStr,
      timeSlot: slot.timeSlotLabel,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isSubmitted
              ? [const Color(0xFF0F3D2E), const Color(0xFF134E4A), const Color(0xFF0F172A)]
              : const [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSubmitted ? EdumindTheme.presentGreen : EdumindTheme.primaryBlue).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: (isSubmitted ? EdumindTheme.presentGreen : EdumindTheme.accentCyan).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On Air / Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EdumindTheme.presentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EdumindTheme.presentGreen),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: EdumindTheme.presentGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppTranslations.get('current_session', lang: lang),
                          style: const TextStyle(color: EdumindTheme.presentGreen, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (isSubmitted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 12, color: EdumindTheme.presentGreen),
                          const SizedBox(width: 4),
                          Text(
                            AppTranslations.get('session_completed', lang: lang),
                            style: const TextStyle(color: EdumindTheme.presentGreen, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                slot.timeSlotLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Class Name & Subject
          Text(
            slot.groupName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (slot.subjectName.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 16, color: EdumindTheme.accentCyan),
                    const SizedBox(width: 4),
                    Text(
                      slot.subjectName,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              if (slot.roomName.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 16, color: EdumindTheme.accentCyan),
                    const SizedBox(width: 4),
                    Text(
                      '${AppTranslations.get('room', lang: lang)} ${slot.roomName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Enrolled Students Count & CTA Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$enrolledCount ${AppTranslations.get('total_students', lang: lang)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openAttendance(slot, isReadOnly: isSubmitted),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitted
                      ? EdumindTheme.presentGreen.withValues(alpha: 0.25)
                      : EdumindTheme.accentCyan,
                  foregroundColor: isSubmitted ? Colors.white : const Color(0xFF0A1124),
                  side: isSubmitted
                      ? const BorderSide(color: EdumindTheme.presentGreen, width: 1.5)
                      : BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  isSubmitted ? Icons.visibility_rounded : Icons.checklist_rounded,
                  size: 20,
                  color: isSubmitted ? EdumindTheme.presentGreen : const Color(0xFF0A1124),
                ),
                label: Text(
                  isSubmitted
                      ? AppTranslations.get('view_attendance', lang: lang)
                      : AppTranslations.get('mark_attendance', lang: lang),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreePeriodHero(ScheduleSlot? nextSlot, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: EdumindTheme.cardDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: EdumindTheme.borderDark),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EdumindTheme.lateOrange.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.coffee_rounded, size: 36, color: EdumindTheme.lateOrange),
          ),
          const SizedBox(height: 12),
          Text(
            AppTranslations.get('free_period_title', lang: lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.get('free_period_desc', lang: lang),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          if (nextSlot != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: EdumindTheme.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${AppTranslations.get('next_session', lang: lang)}: ${nextSlot.groupName} (${nextSlot.timeSlotLabel})',
                style: const TextStyle(color: EdumindTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotCard(ScheduleSlot slot, String lang) {
    final isActive = TimeUtils.isSlotActive(slot);
    final todayStr = TimeUtils.getTodayDateString();
    final isSubmitted = _syncService.isSessionSubmitted(
      groupId: slot.groupId,
      sessionDate: todayStr,
      timeSlot: slot.timeSlotLabel,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSubmitted
            ? EdumindTheme.presentGreen.withValues(alpha: 0.06)
            : (isActive ? EdumindTheme.primaryBlue.withValues(alpha: 0.12) : EdumindTheme.cardDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSubmitted
              ? EdumindTheme.presentGreen.withValues(alpha: 0.4)
              : (isActive ? EdumindTheme.primaryBlue : EdumindTheme.borderDark),
          width: isActive || isSubmitted ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSubmitted
                ? EdumindTheme.presentGreen.withValues(alpha: 0.18)
                : (isActive ? EdumindTheme.primaryBlue : EdumindTheme.cardSubtleDark),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            slot.cleanStartTime,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSubmitted ? EdumindTheme.presentGreen : (isActive ? Colors.white : Colors.white70),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                slot.groupName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (isSubmitted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: EdumindTheme.presentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EdumindTheme.presentGreen.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: EdumindTheme.presentGreen),
                    const SizedBox(width: 4),
                    Text(
                      AppTranslations.get('session_completed', lang: lang),
                      style: const TextStyle(
                        fontSize: 11,
                        color: EdumindTheme.presentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${slot.subjectName} · ${AppTranslations.get('room', lang: lang)} ${slot.roomName} (${slot.timeSlotLabel})',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _openAttendance(slot, isReadOnly: isSubmitted),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSubmitted
                ? EdumindTheme.presentGreen.withValues(alpha: 0.15)
                : (isActive ? EdumindTheme.primaryBlue : EdumindTheme.cardHoverDark),
            foregroundColor: isSubmitted ? EdumindTheme.presentGreen : Colors.white,
            side: isSubmitted ? const BorderSide(color: EdumindTheme.presentGreen, width: 1.0) : BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(
            isSubmitted ? Icons.visibility_rounded : Icons.edit_note_rounded,
            size: 14,
            color: isSubmitted ? EdumindTheme.presentGreen : Colors.white,
          ),
          label: Text(
            isSubmitted
                ? AppTranslations.get('view_attendance_short', lang: lang)
                : (lang == 'fr' ? 'Appel' : 'تسجيل'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
