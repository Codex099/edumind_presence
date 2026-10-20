import 'package:flutter_test/flutter_test.dart';
import 'package:edumind_presence/models/attendance_record.dart';
import 'package:edumind_presence/models/schedule_slot.dart';
import 'package:edumind_presence/services/sync_service.dart';
import 'package:edumind_presence/utils/translations.dart';

void main() {
  group('Translations Tests for Confirmation and Locked Session', () {
    test('Arabic translations exist and are complete', () {
      expect(AppTranslations.get('confirm_dialog_title', lang: 'ar'), isNotEmpty);
      expect(AppTranslations.get('confirm_lock_warning', lang: 'ar'), isNotEmpty);
      expect(AppTranslations.get('absent_students_list', lang: 'ar'), isNotEmpty);
      expect(AppTranslations.get('session_locked_banner_title', lang: 'ar'), isNotEmpty);
      expect(AppTranslations.get('session_locked_footer', lang: 'ar'), isNotEmpty);
      expect(AppTranslations.get('btn_final_submit', lang: 'ar'), isNotEmpty);
      expect(AppTranslations.get('btn_review_edit', lang: 'ar'), isNotEmpty);
      expect(AppTranslations.get('view_attendance', lang: 'ar'), isNotEmpty);
    });

    test('French translations exist and are complete', () {
      expect(AppTranslations.get('confirm_dialog_title', lang: 'fr'), isNotEmpty);
      expect(AppTranslations.get('confirm_lock_warning', lang: 'fr'), isNotEmpty);
      expect(AppTranslations.get('absent_students_list', lang: 'fr'), isNotEmpty);
      expect(AppTranslations.get('session_locked_banner_title', lang: 'fr'), isNotEmpty);
      expect(AppTranslations.get('session_locked_footer', lang: 'fr'), isNotEmpty);
      expect(AppTranslations.get('btn_final_submit', lang: 'fr'), isNotEmpty);
      expect(AppTranslations.get('btn_review_edit', lang: 'fr'), isNotEmpty);
      expect(AppTranslations.get('view_attendance', lang: 'fr'), isNotEmpty);
    });
  });

  group('Slot normalization & Idempotency logic', () {
    test('SyncService.normalizeSlot removes extra spaces', () {
      expect(SyncService.normalizeSlot('08:00 - 09:00'), '08:00-09:00');
      expect(SyncService.normalizeSlot('  08:00-09:00 '), '08:00-09:00');
    });

    test('ScheduleSlot cleanTime formats correctly', () {
      final slot = ScheduleSlot(
        id: '1',
        groupId: 'g1',
        groupName: '1AS-G1',
        teacherId: 't1',
        dayOfWeek: 'Lundi',
        startTime: '8:00',
        endTime: '9:00',
      );
      expect(slot.cleanStartTime, '08:00');
      expect(slot.cleanEndTime, '09:00');
      expect(slot.timeSlotLabel, '08:00 - 09:00');
    });

    test('AttendanceRecord preserves absent/late/present statuses', () {
      final rec = AttendanceRecord(
        id: 'att_g1_0800_st1_2026-10-20',
        sessionDate: '2026-10-20',
        timeSlot: '08:00 - 09:00',
        groupId: 'g1',
        teacherId: 't1',
        studentId: 'st1',
        studentName: 'Ali Ahmed',
        status: AttendanceStatus.absent,
        timestamp: 12345678,
      );

      final json = rec.toJson();
      expect(json['status'], 'absent');
      expect(json['session_date'], '2026-10-20');
      expect(json['time_slot'], '08:00 - 09:00');

      final fromJson = AttendanceRecord.fromJson(json);
      expect(fromJson.status, AttendanceStatus.absent);
    });
  });
}
