import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:offline_notes_sync/features/notes/data/models/sync_result.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_manager.dart';

import '../../../../core/network/api_client.dart';
import 'queue_service.dart';

class SyncService {
  final ApiClient api = ApiClient();
  final Future<bool> Function() _connectivityCheck;

  late final QueueService queue;

  VoidCallback? get onSyncComplete => _manager.onSyncComplete;

  set onSyncComplete(VoidCallback? value) {
    _manager.onSyncComplete = value;
  }

  SyncService({
    Future<bool> Function()? connectivityCheck,
    QueueService? queueService,
  }) : _connectivityCheck = connectivityCheck ?? _defaultConnectivityCheck {
    _manager = SyncManager(
      connectivityCheck: connectivityCheck,
      queueService: queueService,
    );
    queue = _manager.queue;
  }

  SyncService._({
    Future<bool> Function()? connectivityCheck,
    QueueService? queueService,
  }) : _connectivityCheck = connectivityCheck ?? _defaultConnectivityCheck {
    _manager = SyncManager(
      connectivityCheck: connectivityCheck,
      queueService: queueService,
    );
    queue = _manager.queue;
  }

  static final SyncService instance = SyncService._();

  late final SyncManager _manager;

  static Future<bool> _defaultConnectivityCheck() async {
    return Connectivity().checkConnectivity().then(
      (results) => results.any((result) => result != ConnectivityResult.none),
    );
  }

  Future<void> startListening() async => _manager.startListening();

  void dispose() => _manager.dispose();

  Future<bool> checkConnection() async => _connectivityCheck();

  Future<ConflictDetectionResult> detectConflicts() async =>
      _manager.conflictDetector.detectConflicts(api: api, queue: queue);

  Future<PushResult> pushQueue() async =>
      _manager.pushSyncService.pushQueue(queueService: queue);

  Future<PullResult> pullLatest() async =>
      _manager.pullSyncService.pullLatest();

  Future<SyncResult> sync() async => _manager.sync();

  Future<void> resolveConflictKeepLocal(String noteId) async =>
      _manager.resolveConflictKeepLocal(noteId);

  Future<void> resolveConflictKeepServer(String noteId) async =>
      _manager.resolveConflictKeepServer(noteId);

  @Deprecated('Call sync() instead; it already pulls latest data internally.')
  Future<void> pullFromServer() => pullLatest();
}
