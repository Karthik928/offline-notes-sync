import 'package:hive_ce/hive.dart';

part 'sync_action.g.dart';

@HiveType(typeId: 3)
enum SyncAction {
  @HiveField(0)
  create,

  @HiveField(1)
  update,

  @HiveField(2)
  delete,
}
