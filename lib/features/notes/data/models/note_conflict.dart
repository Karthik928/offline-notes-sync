import 'note.dart';

class NoteConflict {
  final Note local;
  final Note server;

  NoteConflict({
    required this.local,
    required this.server,
  });
}