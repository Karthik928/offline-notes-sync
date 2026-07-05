class ConflictDetectionResult {
  final int conflictCount;
  final int reconciledCount;

  const ConflictDetectionResult({
    this.conflictCount = 0,
    this.reconciledCount = 0,
  });

  bool get hasConflict => conflictCount > 0;
  bool get hasReconciled => reconciledCount > 0;
}

class PushResult {
  final int pushedOperations;
  final int skippedConflicts;

  const PushResult({this.pushedOperations = 0, this.skippedConflicts = 0});

  bool get hasPushed => pushedOperations > 0;
}

class PullResult {
  final int appliedChanges;

  const PullResult({this.appliedChanges = 0});

  bool get hasChanges => appliedChanges > 0;
}

class SyncResult {
  final int pushedOperations;
  final int pulledChanges;
  final int reconciledConflicts;
  final int conflictCount;

  const SyncResult({
    this.pushedOperations = 0,
    this.pulledChanges = 0,
    this.reconciledConflicts = 0,
    this.conflictCount = 0,
  });

  bool get hasWork =>
      pushedOperations > 0 || pulledChanges > 0 || reconciledConflicts > 0;

  bool get hasConflicts => conflictCount > 0;

  String get feedbackMessage {
    if (hasWork) {
      if (hasConflicts) {
        return 'Sync completed. $conflictCount conflict(s) require your attention.';
      }
      return 'Sync completed';
    }

    if (hasConflicts) {
      return 'You\'re up to date. $conflictCount conflict(s) still require resolution.';
    }

    return 'You\'re up to date.';
  }
}
