import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_status.dart';

import '../../../../core/network/api_client.dart';
import '../models/note.dart';
import '../models/sync_action.dart';
import 'hive_service.dart';
import 'queue_service.dart';

// NEW
class SyncService {
  final ApiClient api = ApiClient();

  late final QueueService queue;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Called after every sync() attempt (success, no-op, or partial failure)
  // so listeners (e.g. Riverpod notifiers) can refresh their state.
  VoidCallback? onSyncComplete;

  SyncService._() {
    queue = QueueService();
  }

  static final SyncService instance = SyncService._();

  bool _isSyncing = false;

  Timer? _timer;

  Future<void> startListening() async {
    _subscription?.cancel();

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final result = await Connectivity().checkConnectivity();

      final connected = result.any((e) => e != ConnectivityResult.none);

      if (connected) {
        await sync();
      }
    });

    _subscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final connected = results.any((e) => e != ConnectivityResult.none);

      if (connected) {
        await sync();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  // NEW
  Future<void> sync() async {
    if (_isSyncing) return;

    final connectivity = await Connectivity().checkConnectivity();
    final connected = connectivity.any((e) => e != ConnectivityResult.none);

    if (!connected) {
      return;
    }

    _isSyncing = true;

    try {
      final operations = queue.getAll();

      if (operations.isEmpty) {
        debugPrint("Queue Empty");
      } else {
        final notesBox = HiveService.noteBox;

        for (final operation in operations) {
          bool shouldRemoveFromQueue = true;

          try {
            final Note? note = notesBox.get(operation.noteId);

            if (note == null) {
              await queue.remove(operation.id);
              continue;
            }

            switch (operation.action) {
              case SyncAction.create:
                final response = await api.createNote({
                  "localId": note.id,
                  "title": note.title,
                  "body": note.body,
                  "updatedAt": note.updatedAt.toIso8601String(),
                  "isDeleted": false,
                });

                note.serverId = response.data["id"];
                note.syncStatus = SyncStatus.synced;
                note.lastSyncedAt = DateTime.now();

                await note.save();
                break;

              case SyncAction.update:
                if (note.serverId == null) {
                  shouldRemoveFromQueue = false;
                  break;
                }

                await api.updateNote(note.serverId!, {
                  "localId": note.id,
                  "title": note.title,
                  "body": note.body,
                  "updatedAt": note.updatedAt.toIso8601String(),
                  "isDeleted": false,
                });

                note.syncStatus = SyncStatus.synced;
                note.lastSyncedAt = DateTime.now();

                await note.save();
                break;

              case SyncAction.delete:
                if (note.serverId == null) {
                  shouldRemoveFromQueue = false;
                  break;
                }

                await api.deleteNote(note.serverId!);
                await notesBox.delete(note.id);
                break;
            }

            if (shouldRemoveFromQueue) {
              await queue.remove(operation.id);
            }
          } catch (e) {
            debugPrint("Sync Failed");
            debugPrint(e.toString());

            operation.retryCount++;
            await operation.save();
            debugPrint("Retry Count: ${operation.retryCount}");
          }
        }
      }
    } finally {
      _isSyncing = false;
      onSyncComplete?.call();
    }
    await pullFromServer();
  }

  Future<void> pullFromServer() async {
    final serverNotes = await api.fetchNotes();

    final notesBox = HiveService.noteBox;
    debugPrint("Hive Count: ${notesBox.length}");

    for (final n in notesBox.values) {
      debugPrint("${n.title} - ${n.id}");
    }
    debugPrint("Pulling ${serverNotes.length} notes from server");
    for (final json in serverNotes) {
      final localId = json["localId"] as String;

      final localNote = notesBox.get(localId);
      debugPrint("Checking server note: ${json["title"]}");
      if (localNote == null) {
        final note = Note(
          id: localId,
          serverId: json["id"],
          title: json["title"],
          body: json["body"],
          createdAt: DateTime.now(),
          updatedAt: DateTime.parse(json["updatedAt"]),
          lastSyncedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          isDeleted: json["isDeleted"] ?? false,
        );

        await notesBox.put(note.id, note);
        continue;
      }

      final serverUpdated = DateTime.parse(json["updatedAt"]);
      debugPrint("Updated local note from server");
      if (serverUpdated.isAfter(localNote.updatedAt)) {
        localNote.title = json["title"];
        localNote.body = json["body"];
        localNote.updatedAt = serverUpdated;
        localNote.serverId = json["id"];
        localNote.syncStatus = SyncStatus.synced;
        localNote.lastSyncedAt = DateTime.now();

        await localNote.save();
      }
    }

    onSyncComplete?.call();
  }
}
