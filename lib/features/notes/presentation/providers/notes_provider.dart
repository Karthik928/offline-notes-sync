import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_notes_sync/features/notes/data/repository/notes_repository.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_service.dart';

import '../../data/models/note.dart';

final notesRepositoryProvider = Provider((ref) => NotesRepository());

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends Notifier<List<Note>> {
  late NotesRepository repository;

  @override
  List<Note> build() {
    repository = ref.read(notesRepositoryProvider);

    // Refresh state whenever a background sync (timer or connectivity
    // change) completes, instead of only on manual .load() calls.
    SyncService.instance.onSyncComplete = load;
    ref.onDispose(() => SyncService.instance.onSyncComplete = null);

    return repository.getNotes();
  }

  void load() {
    state = repository.getNotes();
  }

  Future<void> add(Note note) async {
    await repository.add(note);
    load();
  }

  Future<void> update(Note note) async {
    await repository.update(note);
    load();
  }

  Future<void> delete(String id) async {
    await repository.delete(id);
    load();
  }
}
