import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final AttendanceStatus status;
  final String note;
  final VoidCallback onToggleStatus;
  final Function(String note) onNoteChanged;
  final String lang;
  final bool isReadOnly;

  const StudentCard({
    super.key,
    required this.student,
    required this.status,
    required this.note,
    required this.onToggleStatus,
    required this.onNoteChanged,
    this.lang = 'ar',
    this.isReadOnly = false,
  });

  Color _getStatusColor() {
    switch (status) {
      case AttendanceStatus.absent:
        return EdumindTheme.absentRed;
      case AttendanceStatus.late:
        return EdumindTheme.lateOrange;
      case AttendanceStatus.present:
        return EdumindTheme.presentGreen;
    }
  }

  Color _getStatusBg() {
    switch (status) {
      case AttendanceStatus.absent:
        return EdumindTheme.absentBgDark;
      case AttendanceStatus.late:
        return EdumindTheme.lateBgDark;
      case AttendanceStatus.present:
        return EdumindTheme.presentBgDark;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case AttendanceStatus.absent:
        return AppTranslations.get('absent_count', lang: lang);
      case AttendanceStatus.late:
        return AppTranslations.get('late_count', lang: lang);
      case AttendanceStatus.present:
        return AppTranslations.get('present_count', lang: lang);
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case AttendanceStatus.absent:
        return Icons.close_rounded;
      case AttendanceStatus.late:
        return Icons.access_time_filled_rounded;
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusBg = _getStatusBg();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status != AttendanceStatus.present ? statusColor.withValues(alpha: 0.5) : EdumindTheme.borderDark,
          width: status != AttendanceStatus.present ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: status != AttendanceStatus.present ? 0.12 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onToggleStatus();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar with initial or photo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Matricule
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (student.matricule.isNotEmpty)
                            Text(
                              student.matricule,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                              ),
                            ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: EdumindTheme.primaryBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.note_alt_outlined, size: 10, color: EdumindTheme.primaryBlue),
                                  const SizedBox(width: 3),
                                  Text(
                                    note,
                                    style: const TextStyle(fontSize: 10, color: EdumindTheme.primaryBlue),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),

                // Note icon button
                if (isReadOnly) ...[
                  if (note.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.note_alt,
                        size: 20,
                        color: EdumindTheme.primaryBlue,
                      ),
                      onPressed: () => _showReadOnlyNoteDialog(context),
                      tooltip: AppTranslations.get('view_note', lang: lang),
                    )
                  else
                    const SizedBox(width: 8),
                ] else
                  IconButton(
                    icon: Icon(
                      note.isEmpty ? Icons.note_add_outlined : Icons.note_alt,
                      size: 20,
                      color: note.isEmpty ? Colors.grey : EdumindTheme.primaryBlue,
                    ),
                    onPressed: () => _showNoteDialog(context),
                    tooltip: AppTranslations.get('add_note', lang: lang),
                  ),

                // Interactive Status Pill Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(), size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusLabel(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReadOnlyNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EdumindTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.note_alt, size: 20, color: EdumindTheme.accentCyan),
            const SizedBox(width: 8),
            Text(
              AppTranslations.get('view_note', lang: lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EdumindTheme.inputDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            note,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: EdumindTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppTranslations.get('close', lang: lang)),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context) {
    final controller = TextEditingController(text: note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EdumindTheme.cardDark,
        title: Text(
          AppTranslations.get('add_note', lang: lang),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppTranslations.get('note_hint', lang: lang),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.get('cancel', lang: lang)),
          ),
          ElevatedButton(
            onPressed: () {
              onNoteChanged(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(AppTranslations.get('save', lang: lang)),
          ),
        ],
      ),
    );
  }
}
