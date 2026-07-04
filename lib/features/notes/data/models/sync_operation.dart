import 'package:hive_ce/hive.dart';

import 'sync_action.dart';

part 'sync_operation.g.dart';

@HiveType(typeId: 2)
class SyncOperation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String noteId;

  @HiveField(2)
  SyncAction action;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  int retryCount;

  SyncOperation({
    required this.id,
    required this.noteId,
    required this.action,
    required this.createdAt,
    this.retryCount = 0,
  });
}