import 'package:offline_notes_sync/features/notes/data/models/note.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_status.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/hive_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_logger.dart';
import '../../../../core/network/api_client.dart';

class PullSyncService {
  PullSyncService({ApiClient? apiClient, SyncLogger? logger})
      : _apiClient = apiClient ?? ApiClient(),
        _logger = logger ?? SyncLogger();

  final ApiClient _apiClient;
  final SyncLogger _logger;

  Future<void> pullLatest() async {
    final List<dynamic> serverNotes;
    try {
      serverNotes = await _apiClient.fetchNotes();
    } catch (error) {
      _logger.log('pullLatest: failed to reach server -> $error');
      rethrow;
    }

    final notesBox = HiveService.noteBox;

    _logger.log('pullLatest: pulling ${serverNotes.length} notes from server');

    final activeServerNoteIds = <String>{};
    var canPruneMissingServerNotes = true;

    for (final json in serverNotes) {
      final record = _readServerRecord(json, noteId: 'server-record');

      final localId = record['localId']?.toString();
      if (localId == null || localId.trim().isEmpty) {
        canPruneMissingServerNotes = false;
        _logger.log('Skipping server record without localId: $json');
        continue;
      }

      final serverId = _readServerId(record);
      if (serverId == null) {
        canPruneMissingServerNotes = false;
      }

      activeServerNoteIds.add(localId);

      final localNote = notesBox.get(localId);

      final createdAt = record.containsKey('createdAt')
          ? _parseServerDateTime(record['createdAt'], localId, 'createdAt')
          : localNote?.createdAt;
      if (createdAt == null) {
        canPruneMissingServerNotes = false;
        continue;
      }

      final serverUpdated = _parseServerDateTime(
        record['updatedAt'],
        localId,
        'updatedAt',
        fallback: createdAt,
      );
      if (serverUpdated == null) {
        canPruneMissingServerNotes = false;
        continue;
      }

      final lastSyncedAt = record.containsKey('lastSyncedAt')
          ? _parseServerDateTime(
              record['lastSyncedAt'],
              localId,
              'lastSyncedAt',
              fallback: createdAt,
            )
          : null;
      if (record.containsKey('lastSyncedAt') && lastSyncedAt == null) {
        canPruneMissingServerNotes = false;
      }

      final isDeleted = _parseServerBool(record['isDeleted']);

      if (localNote == null) {
        if (serverId == null) {
          continue;
        }

        final note = Note(
          id: localId,
          serverId: serverId,
          title: record['title']?.toString() ?? '',
          body: record['body']?.toString() ?? '',
          createdAt: createdAt,
          updatedAt: serverUpdated,
          lastSyncedAt: lastSyncedAt ?? serverUpdated,
          syncStatus: SyncStatus.synced,
          isDeleted: isDeleted,
        );

        await notesBox.put(note.id, note);
        continue;
      }

      if (localNote.syncStatus == SyncStatus.conflict) {
        continue;
      }

      final lastSync =
          localNote.lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final localChanged = localNote.updatedAt.isAfter(lastSync);
      final serverChanged = serverUpdated.isAfter(lastSync);

      if (localChanged && serverChanged) {
        continue;
      }

      if (serverChanged || localNote.serverId == null) {
        localNote.serverId = serverId ?? localNote.serverId;
        localNote.title = record['title']?.toString() ?? localNote.title;
        localNote.body = record['body']?.toString() ?? localNote.body;
        localNote.updatedAt = serverUpdated;
        localNote.isDeleted = isDeleted;
        localNote.syncStatus = SyncStatus.synced;
        localNote.lastSyncedAt = lastSyncedAt ?? serverUpdated;
        ConflictService.remove(localNote.id);
        await localNote.save();
      }
    }

    ConflictService.removeStaleConflicts(activeServerNoteIds);

    if (canPruneMissingServerNotes) {
      final localNotes = notesBox.values.toList();
      for (final localNote in localNotes) {
        if (localNote.serverId != null &&
            localNote.syncStatus == SyncStatus.synced &&
            !activeServerNoteIds.contains(localNote.id)) {
          ConflictService.remove(localNote.id);
          await notesBox.delete(localNote.id);
        }
      }
    }
  }

  Map<String, dynamic> _readServerRecord(dynamic value, {required String noteId}) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    _logger.log(
      'Skipping invalid server record for note $noteId: expected a map but got ${value.runtimeType}',
    );
    return {};
  }

  String? _readServerId(Map<String, dynamic> record) {
    final id = record['id']?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  bool _parseServerBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }

    return fallback;
  }

  DateTime? _parseServerDateTime(
    dynamic value,
    String noteId,
    String fieldName, {
    DateTime? fallback,
  }) {
    if (value == null) {
      if (fallback != null) {
        return fallback;
      }
      _logger.log('Skipping note $noteId because "$fieldName" is missing.');
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      if (fallback != null) {
        return fallback;
      }
      _logger.log(
        'Skipping note $noteId because "$fieldName" has an invalid date: $value',
      );
      return null;
    }

    return parsed;
  }
}
