import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_status.dart';
import 'package:offline_notes_sync/hive_registrar.g.dart';

import '../../data/models/note.dart';

import '../../data/models/sync_action.dart';
import '../../data/models/sync_operation.dart';

class HiveService {
  static const notesBox = 'notes';
  static const operationBox = "operations";

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register all generated adapters
    Hive.registerAdapters();

    await Hive.openBox<Note>(notesBox);
    await Hive.openBox<SyncOperation>(operationBox);
  }

  static Box<SyncOperation> get operationQueue =>
      Hive.box<SyncOperation>(operationBox);

  static Box<Note> get noteBox => Hive.box<Note>(notesBox);
}
