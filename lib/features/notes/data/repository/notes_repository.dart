import 'package:offline_notes_sync/features/notes/data/services/hive_service.dart';

import '../models/note.dart';

class NotesRepository {
  final box = HiveService.noteBox;

  List<Note> getNotes() {
    return box.values.where((e) => !e.isDeleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> add(Note note) async {
    await box.put(note.id, note);
  }

  Future<void> update(Note note) async {
    await box.put(note.id, note);
  }

  Future<void> delete(String id) async {
    final note = box.get(id);

    if (note == null) return;

    note.isDeleted = true;
    note.updatedAt = DateTime.now();

    await note.save();
  }

  Note? getById(String id) {
    return box.get(id);
  }
}
