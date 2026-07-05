import 'package:dio/dio.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_status.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/hive_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/queue_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_logger.dart';
import '../../../../core/network/api_client.dart';

class ConflictResolver {
  ConflictResolver({ApiClient? apiClient, SyncLogger? logger})
      : _apiClient = apiClient ?? ApiClient(),
        _logger = logger ?? SyncLogger();

  final ApiClient _apiClient;
  final SyncLogger _logger;

  Future<void> resolveKeepLocal(String noteId) async {
    final notesBox = HiveService.noteBox;
    final note = notesBox.get(noteId);

    try {
      if (note == null) {
        ConflictService.remove(noteId);
        await QueueService().removeForNote(noteId);
        return;
      }

      final payload = {
        'localId': note.id,
        'title': note.title,
        'body': note.body,
        'updatedAt': note.updatedAt.toIso8601String(),
        'isDeleted': note.isDeleted,
      };

      if (note.isDeleted) {
        if (note.serverId != null) {
          try {
            await _apiClient.deleteNote(note.serverId!);
          } catch (error) {
            if (!_isNotFound(error)) {
              rethrow;
            }
          }
        }

        await notesBox.delete(note.id);
        ConflictService.remove(noteId);
        await QueueService().removeForNote(noteId);
        return;
      }

      if (note.serverId != null) {
        await _apiClient.updateNote(note.serverId!, payload);
      } else {
        final response = await _apiClient.createNote(payload);
        final serverId = _readCreatedServerId(response.data);
        if (serverId == null) {
          throw const FormatException(
            'Create response did not contain a server id.',
          );
        }
        note.serverId = serverId;
      }

      note.syncStatus = SyncStatus.synced;
      note.lastSyncedAt = DateTime.now();
      await note.save();

      ConflictService.remove(noteId);
      await QueueService().removeForNote(noteId);
    } catch (error) {
      _logger.log('resolveKeepLocal failed for note $noteId -> $error');
      rethrow;
    }
  }

  Future<void> resolveKeepServer(String noteId) async {
    final notesBox = HiveService.noteBox;
    final note = notesBox.get(noteId);
    final conflict = ConflictService.getForNote(noteId);
    final serverVersion = conflict?.server;

    try {
      if (note == null) {
        ConflictService.remove(noteId);
        await QueueService().removeForNote(noteId);
        return;
      }

      if (serverVersion != null) {
        if (serverVersion.isDeleted) {
          await notesBox.delete(note.id);
          ConflictService.remove(noteId);
          await QueueService().removeForNote(noteId);
          return;
        }

        note.title = serverVersion.title;
        note.body = serverVersion.body;
        note.updatedAt = serverVersion.updatedAt;
        note.isDeleted = serverVersion.isDeleted;
      }

      note.syncStatus = SyncStatus.synced;
      note.lastSyncedAt = DateTime.now();
      await note.save();

      ConflictService.remove(noteId);
      await QueueService().removeForNote(noteId);
    } catch (error) {
      _logger.log('resolveKeepServer failed for note $noteId -> $error');
      rethrow;
    }
  }

  bool _isNotFound(Object error) {
    return error is DioException && error.response?.statusCode == 404;
  }

  String? _readCreatedServerId(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['id']?.toString().trim();
    }

    if (data is Map) {
      return data['id']?.toString().trim();
    }

    return null;
  }
}
