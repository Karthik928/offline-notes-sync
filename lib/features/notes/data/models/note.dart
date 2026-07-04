import 'package:hive_ce/hive.dart';
import 'sync_status.dart';

part 'note.g.dart';

const _unset = Object();

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  DateTime? lastSyncedAt;

  @HiveField(6)
  SyncStatus syncStatus;

  @HiveField(7)
  bool isDeleted;

  @HiveField(8)
  String? serverId;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pending,
    this.isDeleted = false,
    this.serverId,
  });

  Note copyWith({
    String? title,
    String? body,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
    Object? lastSyncedAt = _unset,
    bool? isDeleted,
    Object? serverId = _unset,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: identical(lastSyncedAt, _unset)
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      serverId: identical(serverId, _unset)
          ? this.serverId
          : serverId as String?,
    );
  }
}
