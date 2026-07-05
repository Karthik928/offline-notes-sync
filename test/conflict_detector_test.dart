import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes_sync/features/notes/data/models/note.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_status.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_detector.dart';

void main() {
  group('ConflictDetector', () {
    late ConflictDetector detector;

    setUp(() {
      detector = ConflictDetector();
    });

    test(
      'detects a conflict when local and server both changed after the last sync',
      () {
        final localNote = Note(
          id: 'local-1',
          title: 'Local title',
          body: 'Local body',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 4),
          lastSyncedAt: DateTime(2024, 1, 2),
          syncStatus: SyncStatus.pending,
        );

        final serverRecord = {
          'id': 'server-1',
          'localId': 'local-1',
          'title': 'Server title',
          'body': 'Server body',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-03T00:00:00.000Z',
          'isDeleted': false,
        };

        expect(
          detector.hasConflict(localNote, serverRecord, DateTime(2024, 1, 3)),
          isTrue,
        );
      },
    );

    test(
      'does not report a conflict when the server matches the local snapshot',
      () {
        final localNote = Note(
          id: 'local-2',
          title: 'Same title',
          body: 'Same body',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 4),
          lastSyncedAt: DateTime(2024, 1, 2),
          syncStatus: SyncStatus.pending,
        );

        final serverRecord = {
          'id': 'server-2',
          'localId': 'local-2',
          'title': 'Same title',
          'body': 'Same body',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-03T00:00:00.000Z',
          'isDeleted': false,
        };

        expect(
          detector.hasConflict(localNote, serverRecord, DateTime(2024, 1, 3)),
          isFalse,
        );
      },
    );
  });
}
