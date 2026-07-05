import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:offline_notes_sync/features/notes/data/services/connectivity_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_detector.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_resolver.dart';
import 'package:offline_notes_sync/features/notes/data/services/pull_sync_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/push_sync_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/queue_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_logger.dart';
import '../../../../core/network/api_client.dart';

class SyncManager {
  SyncManager({
    Future<bool> Function()? connectivityCheck,
    ApiClient? apiClient,
    SyncLogger? logger,
    ConnectivityService? connectivityService,
  }) : _connectivityCheck = connectivityCheck ?? _defaultConnectivityCheck,
       _apiClient = apiClient ?? ApiClient(),
       _logger = logger ?? const SyncLogger(),
       _connectivityService = connectivityService ?? ConnectivityService() {
    queue = QueueService();
    conflictDetector = ConflictDetector(logger: _logger);
    pushSyncService = PushSyncService(apiClient: _apiClient, logger: _logger);
    pullSyncService = PullSyncService(apiClient: _apiClient, logger: _logger);
    conflictResolver = ConflictResolver(apiClient: _apiClient, logger: _logger);
  }

  final Future<bool> Function() _connectivityCheck;
  final ApiClient _apiClient;
  final SyncLogger _logger;
  final ConnectivityService _connectivityService;

  late final QueueService queue;
  late final ConflictDetector conflictDetector;
  late final PushSyncService pushSyncService;
  late final PullSyncService pullSyncService;
  late final ConflictResolver conflictResolver;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _isSyncing = false;
  bool _lastConnectivityWasOnline = false;
  DateTime? _lastSyncAt;
  Future<void> _operationGate = Future.value();

  VoidCallback? onSyncComplete;

  static Future<bool> _defaultConnectivityCheck() async {
    return ConnectivityService().isOnline;
  }

  Future<void> startListening() async {
    _subscription?.cancel();
    _timer?.cancel();

    final initialConnectivity = await _connectivityService.checkConnectivity();
    _lastConnectivityWasOnline = initialConnectivity;

    _timer = Timer.periodic(const Duration(minutes: 10), (_) async {
      final now = DateTime.now();
      final shouldRun =
          _lastConnectivityWasOnline &&
          (_lastSyncAt == null || now.difference(_lastSyncAt!).inMinutes >= 10);
      if (shouldRun) {
        await sync();
      }
    });

    _subscription = _connectivityService.stream.listen((results) async {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      if (!isOnline) {
        _lastConnectivityWasOnline = false;
        return;
      }

      if (!_lastConnectivityWasOnline) {
        _lastConnectivityWasOnline = true;
        await sync();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
  }

  Future<bool> checkConnection() async => _connectivityCheck();

  Future<T> _runSerialized<T>(Future<T> Function() action) {
    final previous = _operationGate;
    late Future<T> current;
    current = previous.then((_) => action(), onError: (_, _) => action());
    _operationGate = current.catchError((_) => Future<T>.value());
    return current;
  }

  Future<void> sync() async {
    if (_isSyncing) {
      onSyncComplete?.call();
      return;
    }

    await _runSerialized(() async {
      if (_isSyncing) {
        onSyncComplete?.call();
        return;
      }

      if (!await checkConnection()) {
        onSyncComplete?.call();
        return;
      }

      _isSyncing = true;

      try {
        final hasConflict = await conflictDetector.detectConflicts(
          api: _apiClient,
          queue: queue,
        );

        if (hasConflict) {
          _logger.log('sync: conflict(s) detected, halting before push');
          return;
        }

        await pushSyncService.pushQueue(queueService: queue);
        await pullSyncService.pullLatest();
      } catch (error) {
        _logger.log('Sync failed');
        _logger.log(error.toString());
      } finally {
        _isSyncing = false;
        _lastSyncAt = DateTime.now();
        onSyncComplete?.call();
      }
    });
  }

  Future<void> resolveConflictKeepLocal(String noteId) async {
    await _runSerialized(() async {
      try {
        await conflictResolver.resolveKeepLocal(noteId);
      } finally {
        onSyncComplete?.call();
      }
    });
  }

  Future<void> resolveConflictKeepServer(String noteId) async {
    await _runSerialized(() async {
      try {
        await conflictResolver.resolveKeepServer(noteId);
      } finally {
        onSyncComplete?.call();
      }
    });
  }
}
