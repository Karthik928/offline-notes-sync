import 'package:flutter/foundation.dart';

class SyncLogger {
  const SyncLogger({this.enabled = true});

  final bool enabled;

  void log(String message) {
    if (!enabled || !kDebugMode) {
      return;
    }

    debugPrint(message);
  }
}
