import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes_sync/features/notes/data/models/note.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_status.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_service.dart';

void main() {
  setUp(() {
    ConflictService.clear();
  });

  test(
    'removes stale conflicts when a local note is no longer present on the server',
    () {
      final activeLocal = Note(
        id: 'local-active',
        title: 'Active',
        body: 'Body',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024, 1, 2),
        syncStatus: SyncStatus.conflict,
      );
      final staleLocal = Note(
        id: 'local-stale',
        title: 'Stale',
        body: 'Body',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024, 1, 2),
        syncStatus: SyncStatus.conflict,
      );

      final serverVersion = Note(
        id: 'server',
        title: 'Server',
        body: 'Body',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024, 1, 3),
        syncStatus: SyncStatus.synced,
      );

      ConflictService.add(activeLocal, serverVersion);
      ConflictService.add(staleLocal, serverVersion);

      ConflictService.removeStaleConflicts({'local-active'});

      expect(ConflictService.conflicts, hasLength(1));
      expect(ConflictService.getForNote('local-active'), isNotNull);
      expect(ConflictService.getForNote('local-stale'), isNull);
    },
  );
}
