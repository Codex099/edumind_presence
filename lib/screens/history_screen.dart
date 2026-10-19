import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../services/pending_queue_service.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _syncService = Get.find<SyncService>();
  final _authService = Get.find<AuthService>();
  final _queue = Get.find<PendingQueueService>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lang = _authService.currentLang.value;
      final isAr = lang == 'ar';
      final attendances = _syncService.attendances.reversed.toList();
      final pendingCount = _queue.pendingCount.value;

      // Group records by session_date + group_name + time_slot
      final Map<String, List> sessionGroups = {};
      for (final att in attendances) {
        final key = '${att.sessionDate} • ${att.groupName} (${att.timeSlot})';
        sessionGroups.putIfAbsent(key, () => []).add(att);
      }

      return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: EdumindTheme.bgDark,
          appBar: AppBar(
            backgroundColor: EdumindTheme.bgDark,
            title: Text(AppTranslations.get('history_title', lang: lang)),
            actions: [
              if (pendingCount > 0)
                IconButton(
                  icon: _queue.isSyncing.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined, color: EdumindTheme.lateOrange),
                  tooltip: AppTranslations.get('sync_now', lang: lang),
                  onPressed: () => _queue.processPendingQueue(),
                ),
            ],
          ),
          body: sessionGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.get('empty_history', lang: lang),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: sessionGroups.keys.length,
                  itemBuilder: (context, index) {
                    final sessionTitle = sessionGroups.keys.elementAt(index);
                    final records = sessionGroups[sessionTitle]!;

                    final absentCount = records.where((r) => r.statusString == 'absent').length;
                    final lateCount = records.where((r) => r.statusString == 'late').length;
                    final total = records.length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: EdumindTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: EdumindTheme.borderDark),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EdumindTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.class_rounded, color: EdumindTheme.primaryBlue, size: 22),
                        ),
                        title: Text(
                          sessionTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              '$total تلميذ',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            if (absentCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: EdumindTheme.absentBgDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$absentCount غائب',
                                  style: const TextStyle(color: EdumindTheme.absentRed, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 6),
                            if (lateCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: EdumindTheme.lateBgDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$lateCount متأخر',
                                  style: const TextStyle(color: EdumindTheme.lateOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        children: records.map<Widget>((r) {
                          final isAbsent = r.statusString == 'absent';
                          final isLate = r.statusString == 'late';
                          final color = isAbsent
                              ? EdumindTheme.absentRed
                              : (isLate ? EdumindTheme.lateOrange : EdumindTheme.presentGreen);

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            leading: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                            ),
                            title: Text(r.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: r.note.isNotEmpty
                                ? Text(r.note, style: const TextStyle(fontSize: 11, color: Colors.grey))
                                : null,
                            trailing: Text(
                              isAbsent ? 'غائب' : (isLate ? 'متأخر' : 'حاضر'),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      );
    });
  }
}
