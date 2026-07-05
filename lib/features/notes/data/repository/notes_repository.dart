import 'package:offline_notes_sync/features/notes/data/models/sync_action.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_operation.dart';
import 'package:offline_notes_sync/features/notes/data/services/hive_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/queue_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/note.dart';
import '../models/sync_status.dart';

class NotesRepository {
  final box = HiveService.noteBox;
  final QueueService queue = QueueService.instance;

  Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();

    return result.any((e) => e != ConnectivityResult.none);
  }

  List<Note> getNotes() {
    return box.values
        .where((e) => !e.isDeleted || e.syncStatus == SyncStatus.conflict)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> add(Note note) async {
    await box.put(note.id, note);
    await queue.add(
      SyncOperation(
        id: const Uuid().v4(),
        noteId: note.id,
        action: SyncAction.create,
        createdAt: DateTime.now(),
      ),
    );
    await SyncService.instance.sync();
  }

  Future<void> update(Note note) async {
    await box.put(note.id, note);

    await queue.add(
      SyncOperation(
        id: const Uuid().v4(),
        noteId: note.id,
        action: SyncAction.update,
        createdAt: DateTime.now(),
      ),
    );

    await SyncService.instance.sync();
  }

  Future<void> delete(String id) async {
    final note = box.get(id);

    if (note == null) return;

    if (note.serverId == null) {
      await queue.removeForNote(id);
      await box.delete(id);
      await SyncService.instance.sync();
      return;
    }

    note.isDeleted = true;
    note.updatedAt = DateTime.now();
    note.syncStatus = SyncStatus.pending;

    await note.save();
    await queue.add(
      SyncOperation(
        id: const Uuid().v4(),
        noteId: id,
        action: SyncAction.delete,
        createdAt: DateTime.now(),
      ),
    );
    await SyncService.instance.sync();
  }

  Note? getById(String id) {
    return box.get(id);
  }
}
