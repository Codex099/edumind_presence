import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';

class StatusCounterBar extends StatelessWidget {
  final int total;
  final int present;
  final int absent;
  final int late;
  final String lang;

  const StatusCounterBar({
    super.key,
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    this.lang = 'ar',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: EdumindTheme.borderDark),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Total
          _buildPill(
            label: AppTranslations.get('total_students', lang: lang),
            count: total,
            color: Colors.blueGrey,
            bg: Colors.blueGrey.withValues(alpha: 0.12),
          ),
          // Present
          _buildPill(
            label: AppTranslations.get('present_count', lang: lang),
            count: present,
            color: EdumindTheme.presentGreen,
            bg: EdumindTheme.presentBgDark,
          ),
          // Absent
          _buildPill(
            label: AppTranslations.get('absent_count', lang: lang),
            count: absent,
            color: EdumindTheme.absentRed,
            bg: EdumindTheme.absentBgDark,
          ),
          // Late
          _buildPill(
            label: AppTranslations.get('late_count', lang: lang),
            count: late,
            color: EdumindTheme.lateOrange,
            bg: EdumindTheme.lateBgDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required int count,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
