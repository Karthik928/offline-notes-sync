import 'package:offline_notes_sync/features/notes/data/models/note.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_status.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/hive_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/queue_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_logger.dart';
import '../../../../core/network/api_client.dart';

class ConflictDetector {
  ConflictDetector({SyncLogger? logger}) : _logger = logger ?? SyncLogger();

  final SyncLogger _logger;

  Future<bool> detectConflicts({
    required ApiClient api,
    QueueService? queue,
  }) async {
    final List<dynamic> serverNotes;
    try {
      serverNotes = await api.fetchNotes();
    } catch (error) {
      _logger.log('detectConflicts: failed to reach server -> $error');
      rethrow;
    }

    final notesBox = HiveService.noteBox;
    var hasAnyConflict = false;

    for (final json in serverNotes) {
      final record = _readServerRecord(json, noteId: 'server-record');
      final localId = record['localId']?.toString();
      if (localId == null || localId.trim().isEmpty) {
        _logger.log('Skipping server record without localId: $json');
        continue;
      }

      final localNote = notesBox.get(localId);
      if (localNote == null) {
        continue;
      }

      final createdAt = _parseServerDateTime(
        record['createdAt'],
        localId,
        'createdAt',
      );
      if (createdAt == null) {
        continue;
      }

      final serverUpdated = _parseServerDateTime(
        record['updatedAt'],
        localId,
        'updatedAt',
        fallback: createdAt,
      );
      if (serverUpdated == null) {
        continue;
      }

      final lastSync =
          localNote.lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final localChanged = localNote.updatedAt.isAfter(lastSync);
      final serverChanged = serverUpdated.isAfter(lastSync);

      if (localChanged && serverChanged) {
        if (_serverMatchesLocal(localNote, record)) {
          localNote.serverId = _readServerId(record) ?? localNote.serverId;
          localNote.syncStatus = SyncStatus.synced;
          localNote.lastSyncedAt = serverUpdated;
          ConflictService.remove(localId);
          await localNote.save();
          await queue?.removeForNote(localId);
          continue;
        }

        if (hasConflict(localNote, record, serverUpdated)) {
          hasAnyConflict = true;

          final localSnapshot = localNote.copyWith();

          localNote.syncStatus = SyncStatus.conflict;
          await localNote.save();

          final serverSnapshot = Note(
            id: localNote.id,
            serverId: record['id']?.toString() ?? localNote.serverId,
            title: record['title']?.toString() ?? '',
            body: record['body']?.toString() ?? '',
            createdAt: createdAt,
            updatedAt: serverUpdated,
            lastSyncedAt: lastSync,
            syncStatus: SyncStatus.synced,
            isDeleted: _parseServerBool(record['isDeleted']),
          );

          ConflictService.add(localSnapshot, serverSnapshot);
          _logger.log('Conflict detected for note $localId');
        }
      }
    }

    return hasAnyConflict;
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

  bool hasConflict(
    Note localNote,
    Map<String, dynamic> record,
    DateTime? serverUpdated,
  ) {
    if (serverUpdated == null) {
      return false;
    }

    final lastSync =
        localNote.lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final localChanged = localNote.updatedAt.isAfter(lastSync);
    final serverChanged = serverUpdated.isAfter(lastSync);

    return localChanged &&
        serverChanged &&
        !_serverMatchesLocal(localNote, record);
  }

  bool _serverMatchesLocal(Note localNote, Map<String, dynamic> record) {
    return localNote.title == (record['title']?.toString() ?? '') &&
        localNote.body == (record['body']?.toString() ?? '') &&
        localNote.isDeleted == _parseServerBool(record['isDeleted']);
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
