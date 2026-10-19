import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/pending_action.dart';
import '../models/attendance_record.dart';
import 'connectivity_service.dart';
import 'sheets_service.dart';

class PendingQueueService extends GetxService {
  static const String boxName = 'pending_actions';
  late final Box<PendingAction> _box;

  final pendingCount = 0.obs;
  final isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _box = Hive.box<PendingAction>(boxName);
    _updateCount();

    // Auto-trigger sync when transitioning to Online
    final conn = Get.find<ConnectivityService>();
    ever(conn.isOnline, (online) {
      if (online && pendingCount.value > 0 && !isSyncing.value) {
        processPendingQueue();
      }
    });
  }

  void _updateCount() {
    pendingCount.value = _box.values.length;
  }

  /// Adds a batch of attendance records to the pending offline queue
  Future<void> enqueueAttendanceSheet(List<AttendanceRecord> records) async {
    final action = PendingAction(
      id: 'pending_att_${DateTime.now().millisecondsSinceEpoch}',
      actionType: 'submit_attendance_sheet',
      payloadJson: jsonEncode(records.map((r) => r.toJson()).toList()),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _box.put(action.id, action);
    _updateCount();

    // If online, attempt immediate sync
    if (Get.find<ConnectivityService>().isOnline.value) {
      processPendingQueue();
    }
  }

  /// Processes all pending offline items sequentially
  Future<int> processPendingQueue() async {
    if (isSyncing.value || _box.isEmpty) return 0;
    isSyncing.value = true;

    final sheets = Get.find<SheetsService>();
    final keys = _box.keys.toList();
    int syncedTotal = 0;

    for (final key in keys) {
      final item = _box.get(key);
      if (item == null) continue;

      try {
        if (item.actionType == 'submit_attendance_sheet') {
          final List list = jsonDecode(item.payloadJson);
          final records = list.map((m) => AttendanceRecord.fromJson(m)).toList();

          final result = await sheets.submitAttendanceSheet(records);
          if (result['success'] == true) {
            await _box.delete(key);
            syncedTotal += records.length;
          } else {
            item.attempts++;
            item.lastError = result['error']?.toString();
            await item.save();
          }
        }
      } catch (e) {
        item.attempts++;
        item.lastError = e.toString();
        await item.save();
      }
    }

    _updateCount();
    isSyncing.value = false;
    return syncedTotal;
  }
}
