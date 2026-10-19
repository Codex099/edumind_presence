import 'package:hive/hive.dart';

part 'pending_action.g.dart';

@HiveType(typeId: 16)
class PendingAction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String actionType; // 'submit_attendance_sheet'

  @HiveField(2)
  final String payloadJson;

  @HiveField(3)
  final int createdAt;

  @HiveField(4)
  int attempts;

  @HiveField(5)
  String? lastError;

  PendingAction({
    required this.id,
    required this.actionType,
    required this.payloadJson,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });
}
