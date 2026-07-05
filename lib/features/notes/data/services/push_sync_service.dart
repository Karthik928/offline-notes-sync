import 'package:dio/dio.dart';
import 'package:offline_notes_sync/features/notes/data/models/note.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_action.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_status.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/hive_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/queue_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_logger.dart';
import '../../../../core/network/api_client.dart';

class PushSyncService {
  PushSyncService({ApiClient? apiClient, SyncLogger? logger})
      : _apiClient = apiClient ?? ApiClient(),
        _logger = logger ?? SyncLogger();

  final ApiClient _apiClient;
  final SyncLogger _logger;

  Future<void> pushQueue({QueueService? queueService}) async {
    final queue = queueService ?? QueueService();
    final operations = queue.getAll();

    if (operations.isEmpty) {
      _logger.log('pushQueue: queue empty, nothing to push');
      return;
    }

    final notesBox = HiveService.noteBox;

    for (final operation in operations) {
      var shouldRemoveFromQueue = true;

      try {
        final Note? note = notesBox.get(operation.noteId);

        if (note == null) {
          await queue.remove(operation.id);
          continue;
        }

        if (note.syncStatus == SyncStatus.conflict) {
          _logger.log('pushQueue: skipping ${note.id}, still in conflict');
          continue;
        }

        switch (operation.action) {
          case SyncAction.create:
            if (note.serverId != null) {
              break;
            }

            if (note.isDeleted) {
              ConflictService.remove(note.id);
              await notesBox.delete(note.id);
              break;
            }

            final response = await _apiClient.createNote({
              'localId': note.id,
              'title': note.title,
              'body': note.body,
              'updatedAt': note.updatedAt.toIso8601String(),
              'isDeleted': false,
            });

            final serverId = _readCreatedServerId(response.data);
            if (serverId == null) {
              throw const FormatException(
                'Create response did not contain a server id.',
              );
            }

            note.serverId = serverId;
            note.syncStatus = SyncStatus.synced;
            note.lastSyncedAt = DateTime.now();
            ConflictService.remove(note.id);

            await note.save();
            break;

          case SyncAction.update:
            if (note.serverId == null) {
              shouldRemoveFromQueue = false;
              break;
            }

            await _apiClient.updateNote(note.serverId!, {
              'localId': note.id,
              'title': note.title,
              'body': note.body,
              'updatedAt': note.updatedAt.toIso8601String(),
              'isDeleted': false,
            });

            note.syncStatus = SyncStatus.synced;
            note.lastSyncedAt = DateTime.now();
            ConflictService.remove(note.id);

            await note.save();
            break;

          case SyncAction.delete:
            if (note.serverId == null) {
              ConflictService.remove(note.id);
              await notesBox.delete(note.id);
              break;
            }

            try {
              await _apiClient.deleteNote(note.serverId!);
            } catch (error) {
              if (!_isNotFound(error)) {
                rethrow;
              }
            }
            ConflictService.remove(note.id);
            await notesBox.delete(note.id);
            break;
        }

        if (shouldRemoveFromQueue) {
          await queue.remove(operation.id);
        }
      } catch (error) {
        _logger.log('pushQueue: failed to push ${operation.id} -> $error');

        operation.retryCount++;
        await operation.save();
        _logger.log('Retry Count: ${operation.retryCount}');
      }
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
