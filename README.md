# Offline Notes Sync

Offline Notes Sync is a Flutter application that demonstrates a robust offline-first note experience with queue-based synchronization, conflict detection, and conflict resolution. The project is built to feel production-ready while keeping the architecture simple enough to understand and extend.

## Features

- Offline-first note creation, editing, and deletion
- Queue-based synchronization for pending local changes
- Conflict detection when local and server versions diverge
- Conflict resolution with keep-local and keep-server actions
- Hive-backed local persistence
- Riverpod-powered state management
- Connectivity-aware auto-sync behavior

## Architecture

The application follows a clean feature-oriented structure with a repository layer, data services, and presentation providers. The sync flow is intentionally split into focused services so each responsibility stays easy to reason about and maintain.

## Folder Structure

```text
lib/
  core/
    network/
    theme/
    utils/
  features/
    notes/
      data/
        models/
        repository/
        services/
      presentation/
        providers/
        screens/
        widgets/
  main.dart
```

## Technology Stack

- Flutter
- Dart
- Hive CE
- Hive CE Flutter
- Riverpod
- Connectivity Plus
- Dio
- Flutter Test

## Offline-first Strategy

Notes are saved locally immediately, so the app remains responsive even when the network is unavailable. Local state is synchronized in the background when connectivity returns.

## Queue-based Synchronization

Local writes are captured as sync operations and stored in a queue. The queue ensures that retries and ordering remain predictable even under intermittent network conditions.

## Conflict Detection

The app compares local note updates against server changes using timestamps and content snapshots. When both sides changed after the last successful sync, a conflict is flagged and surfaced for resolution.

## Conflict Resolution

Conflicts can be resolved in two ways:

- Keep Mine: push the local version to the server
- Keep Server: apply the server version locally

The matching queue entries and conflict state are then cleaned up.

## Project Structure

The project is organized around the notes feature and is intentionally structured to preserve the existing app behavior while making maintenance easier. The sync subsystem is separated into dedicated services for queue processing, pull synchronization, conflict detection, conflict resolution, connectivity, and logging.

## Screenshots

Placeholder: Add screenshots of the note list, detail screen, and conflict resolution view.

## GIF Demo

Placeholder: Add a short GIF showing offline note creation and sync behavior.

## Installation

1. Clone the repository.
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Ensure you have an emulator or device connected.

## How to Run

```bash
flutter run
```

## How Sync Works

1. Local changes are written to Hive.
2. A sync operation is queued.
3. When the app is online, the queue is processed.
4. Server changes are pulled and merged.
5. Conflicts are detected before destructive updates continue.

## How Conflict Resolution Works

When a conflict is detected, the local note is marked as conflicted and stored with the server version for comparison. The user can then choose to keep the local version, keep the server version, or let the conflict be resolved through the sync flow.

## Future Improvements

- Add stronger conflict metadata and manual resolution history
- Improve retry backoff and network resilience
- Add sync state indicators and richer diagnostics
- Add integration tests for the full sync lifecycle

## Known Limitations

- Network errors are currently surfaced through the existing sync flow and retries
- Conflict resolution is intentionally simple and focused on the core experience
- The mock API service is suitable for demo and development use

## Why Hive?

Hive offers a lightweight and fast local storage layer for mobile applications and fits the offline-first nature of this app very well.

## Why Riverpod?

Riverpod provides a simple and scalable state management model that keeps UI state and data providers predictable without adding excessive ceremony.

## Why Queue-based Sync?

A queue ensures local changes are not lost during transient connectivity issues and makes retries and out-of-order updates easier to manage.

## Testing Strategy

The project uses Flutter’s built-in test framework for unit and widget coverage. The sync services are validated with targeted tests around conflict detection and the core sync behavior.

## Folder Structure Tree

```text
offline_notes_sync/
  android/
  ios/
  lib/
    core/
    features/
  test/
  web/
```

## Architecture Diagram

```text
UI -> Providers -> Repository -> SyncManager
                                  |-> PushSyncService
                                  |-> PullSyncService
                                  |-> ConflictDetector
                                  |-> ConflictResolver
                                  |-> ConnectivityService
                                  v
                              Hive / API
```

## Data Flow Diagram

```text
Local Note Edit
  -> Hive storage
  -> Sync queue
  -> PushSyncService
  -> API
  -> PullSyncService
  -> Hive update
  -> ConflictDetector
  -> ConflictResolver (if needed)
```

## License

This project is provided as a reference implementation for Flutter offline-sync patterns.

## Author

Built as a professional Flutter reference project focused on offline-first architecture and maintainable sync logic.
