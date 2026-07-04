import 'package:hive_ce/hive.dart';

part 'sync_status.g.dart';

@HiveType(typeId: 1)
enum SyncStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  synced,

  @HiveField(2)
  conflict,
}
