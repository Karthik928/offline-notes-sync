import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce/src/adapters/date_time_adapter.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_action.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_operation.dart';
import 'package:offline_notes_sync/features/notes/data/services/queue_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_service.dart';
import 'package:offline_notes_sync/hive_registrar.g.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_notes_sync_test');
    Hive.init(tempDir.path);
    Hive.resetAdapters();
    Hive.registerAdapter(DateTimeAdapter());
    Hive.registerAdapters();
    await Hive.openBox<SyncOperation>('operations');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('sync notifies listeners even when the device is offline', () async {
    final syncService = SyncService(connectivityCheck: () async => false);
    var notified = false;

    syncService.onSyncComplete = () => notified = true;

    await syncService.sync();

    expect(notified, isTrue);
  });

  test('queue deduplicates repeated updates for the same note', () async {
    final queue = QueueService();

    final first = SyncOperation(
      id: 'op-1',
      noteId: 'note-1',
      action: SyncAction.update,
      createdAt: DateTime(2024),
    );
    final second = SyncOperation(
      id: 'op-2',
      noteId: 'note-1',
      action: SyncAction.update,
      createdAt: DateTime(2024, 1, 2),
    );

    await queue.add(first);
    await queue.add(second);

    final operations = queue.getAll();
    expect(operations, hasLength(1));
    expect(operations.single.id, 'op-2');
  });
}
