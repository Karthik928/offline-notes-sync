import 'package:hive_ce/hive.dart';

import '../models/sync_operation.dart';
import '../models/sync_action.dart';
import 'hive_service.dart';

class QueueService {
  Box<SyncOperation>? _box;

  Box<SyncOperation> get box => _box ??= HiveService.operationQueue;

  List<SyncOperation> getAll() {
    final list = box.values.toList();

    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return list;
  }

  Future<void> add(SyncOperation operation) async {
    final existing = box.values
        .where((queued) => queued.noteId == operation.noteId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    switch (operation.action) {
      case SyncAction.create:
        if (existing.any((queued) => queued.action == SyncAction.create)) {
          return;
        }
        break;

      case SyncAction.update:
        if (existing.any((queued) => queued.action == SyncAction.delete)) {
          return;
        }

        if (existing.any((queued) => queued.action == SyncAction.create)) {
          return;
        }

        for (final queued in existing.where(
          (queued) => queued.action == SyncAction.update,
        )) {
          await box.delete(queued.id);
        }
        break;

      case SyncAction.delete:
        for (final queued in existing) {
          await box.delete(queued.id);
        }
        break;
    }

    await box.put(operation.id, operation);
  }

  Future<void> remove(String id) async {
    await box.delete(id);
  }

  Future<void> clear() async {
    await box.clear();
  }

  Future<void> removeForNote(String noteId) async {
    final staleIds = box.values
        .where((operation) => operation.noteId == noteId)
        .map((operation) => operation.id)
        .toList();

    for (final id in staleIds) {
      await box.delete(id);
    }
  }
}
