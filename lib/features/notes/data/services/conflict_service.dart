import '../models/note.dart';
import '../models/note_conflict.dart';

class ConflictService {
  static final List<NoteConflict> _conflicts = [];

  static List<NoteConflict> get conflicts =>
      List.unmodifiable(_conflicts);

  static void clear() {
    _conflicts.clear();
  }

  static void add(Note local, Note server) {
    _conflicts.removeWhere((e) => e.local.id == local.id);

    _conflicts.add(
      NoteConflict(
        local: local,
        server: server,
      ),
    );
  }

  static void remove(String id) {
    _conflicts.removeWhere(
      (e) => e.local.id == id,
    );
  }

  static void removeStaleConflicts(Set<String> activeNoteIds) {
    _conflicts.removeWhere((conflict) => !activeNoteIds.contains(conflict.local.id));
  }

  static NoteConflict? getForNote(String noteId) {
    for (final conflict in _conflicts) {
      if (conflict.local.id == noteId) {
        return conflict;
      }
    }
    return null;
  }
}