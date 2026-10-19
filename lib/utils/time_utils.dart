import 'package:intl/intl.dart';
import '../models/schedule_slot.dart';

class TimeUtils {
  static const List<String> arabicDays = [
    'الإثنين',   // Monday (DateTime.monday = 1)
    'الثلاثاء',  // Tuesday = 2
    'الأربعاء',  // Wednesday = 3
    'الخميس',    // Thursday = 4
    'الجمعة',    // Friday = 5
    'السبت',     // Saturday = 6
    'الأحد',     // Sunday = 7
  ];

  static const List<String> frenchDays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  /// Returns today's day of week matching either Arabic or French
  static String getTodayDayName({bool inArabic = true}) {
    final weekday = DateTime.now().weekday; // 1 = Monday .. 7 = Sunday
    if (inArabic) {
      return arabicDays[weekday - 1];
    } else {
      return frenchDays[weekday - 1];
    }
  }

  /// Formats current date to YYYY-MM-DD
  static String getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Formats date to user-friendly string
  static String formatDisplayDate(DateTime dt, {String lang = 'ar'}) {
    if (lang == 'ar') {
      final dayName = arabicDays[dt.weekday - 1];
      return '$dayName ${DateFormat('dd/MM/yyyy').format(dt)}';
    } else {
      final dayName = frenchDays[dt.weekday - 1];
      return '$dayName ${DateFormat('dd/MM/yyyy').format(dt)}';
    }
  }

  /// Checks if a schedule slot matches today's day of week
  static bool isTodaySlot(ScheduleSlot slot, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final arDay = arabicDays[current.weekday - 1];
    final frDay = frenchDays[current.weekday - 1];

    final slotDay = slot.dayOfWeek.trim();
    return slotDay == arDay || slotDay == frDay;
  }

  /// Parses HH:mm string to minutes from start of day
  static int _parseTimeToMinutes(String timeStr) {
    try {
      final cleaned = ScheduleSlot.cleanTime(timeStr);
      final parts = cleaned.trim().split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final mins = int.parse(parts[1]);
        return hours * 60 + mins;
      }
    } catch (_) {}
    return -1;
  }

  /// Checks if a slot is currently ongoing
  static bool isSlotActive(ScheduleSlot slot, {DateTime? now}) {
    if (!isTodaySlot(slot, now: now)) return false;

    final current = now ?? DateTime.now();
    final currentMinutes = current.hour * 60 + current.minute;

    final startMinutes = _parseTimeToMinutes(slot.startTime);
    final endMinutes   = _parseTimeToMinutes(slot.endTime);

    if (startMinutes == -1 || endMinutes == -1) return false;

    // Active if current time is within [start - 5 mins buffer, end]
    return currentMinutes >= (startMinutes - 5) && currentMinutes < endMinutes;
  }

  /// Finds the currently active slot among a list of slots
  static ScheduleSlot? findCurrentActiveSlot(List<ScheduleSlot> slots, {DateTime? now}) {
    for (final slot in slots) {
      if (isSlotActive(slot, now: now)) {
        return slot;
      }
    }
    return null;
  }

  /// Finds the next upcoming slot today
  static ScheduleSlot? findNextUpcomingSlot(List<ScheduleSlot> slots, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final currentMinutes = current.hour * 60 + current.minute;

    final todaySlots = slots.where((s) => isTodaySlot(s, now: now)).toList();
    todaySlots.sort((a, b) {
      final aMin = _parseTimeToMinutes(a.startTime);
      final bMin = _parseTimeToMinutes(b.startTime);
      return aMin.compareTo(bMin);
    });

    for (final slot in todaySlots) {
      final startMin = _parseTimeToMinutes(slot.startTime);
      if (startMin > currentMinutes) {
        return slot;
      }
    }
    return null;
  }
}
