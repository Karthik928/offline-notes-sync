import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:offline_notes_sync/hive_registrar.g.dart';

import '../../data/models/note.dart';

class HiveService {
  static const notesBox = 'notes';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register all generated adapters
    Hive.registerAdapters();

    await Hive.openBox<Note>(notesBox);
  }

  static Box<Note> get noteBox => Hive.box<Note>(notesBox);
}
