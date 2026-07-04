import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_notes_sync/features/notes/data/models/note.dart';
import 'package:offline_notes_sync/features/notes/data/repository/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends Notifier<List<Note>> {
  late final NotesRepository _repository;

  @override
  List<Note> build() {
    _repository = ref.read(notesRepositoryProvider);
    return _repository.getNotes();
  }

  Future<void> refresh() async {
    state = _repository.getNotes();
  }

  Future<void> add(Note note) async {
    await _repository.add(note);
    await refresh();
  }

  Future<void> update(Note note) async {
    await _repository.update(note);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await refresh();
  }
}
