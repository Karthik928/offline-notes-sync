# Offline Notes Sync

A production-oriented offline-first note sync app built with Flutter, Hive, Riverpod, and a queued sync engine.

---

# Project Overview

This application solves the common problem of maintaining a usable note-taking experience when network access is intermittent or unavailable.

It is designed as an offline-first app that stores notes locally in Hive, queues user operations, and synchronizes them with a remote REST API whenever the device is online.

Offline-first architecture is useful because it:

- keeps the app responsive when the network is unreliable
- prevents data loss by persisting user actions immediately
- reduces user frustration by minimizing sync delays and failures

This app combines Hive, Riverpod, and queue-based synchronization to provide a reliable local-first experience with structured sync and conflict handling.

---

# Features

- ✓ Offline First
- ✓ Local Storage (Hive)
- ✓ Queue Based Synchronization
- ✓ Automatic Background Sync
- ✓ Manual Sync
- ✓ Pull To Refresh
- ✓ Connectivity Monitoring
- ✓ Create Notes
- ✓ Edit Notes
- ✓ Delete Notes
- ✓ Search Notes
- ✓ Conflict Detection
- ✓ Conflict Resolution
- ✓ Keep Mine
- ✓ Keep Server
- ✓ Sync Status Indicators
- ✓ Material 3 UI
- ✓ Responsive Layout
- ✓ Theme System

---

# Screens

## Home Screen

The Home Screen is the main list of notes. It shows sync status, conflict counts, summary text, a search action, and manual sync controls. Notes are presented in cards with edit/delete actions and a tap-to-open flow.

## Add/Edit Screen

The Add/Edit Screen is used for new notes and existing notes. It includes a title field, body field, save button, and a loading dialog during save operations.

## Search Screen

The custom search delegate filters notes by title and body. It shows result cards and supports editing or conflict resolution directly from search results.

## Conflict Screen

The Conflict Screen is shown when a note is in conflict. It displays the local version and server version side by side and provides explicit choices for Keep Mine or Keep Server.

## Dialogs

The app uses dialogs for:

- delete confirmation
- loading states
- conflict resolution success
- offline sync notifications

## Empty State

The Home Screen displays a centered empty state with inviting copy and a call-to-action button when no notes exist.

## Loading States

Loading indicators are shown during note save operations, conflict resolution, and while syncing in the sync button area.

## Sync Status Chips

Each note shows an icon and status label for:

- synced
- pending
- conflict

---

# Folder Structure

```
lib/
  core/
    network/
      api_client.dart
    theme/
      app_colors.dart
      app_theme.dart
  features/
    notes/
      data/
        models/
          note.dart
          note_conflict.dart
          sync_action.dart
          sync_operation.dart
          sync_result.dart
          sync_status.dart
        repository/
          notes_repository.dart
        services/
          conflict_detector.dart
          conflict_resolver.dart
          conflict_service.dart
          connectivity_service.dart
          hive_service.dart
          pull_sync_service.dart
          push_sync_service.dart
          queue_service.dart
          sync_logger.dart
          sync_manager.dart
          sync_service.dart
      presentation/
        providers/
          notes_provider.dart
        screens/
          home_screen.dart
          add_edit_note_screen.dart
          conflict_resolution_screen.dart
        widgets/
          notes_search_delegate.dart
  main.dart
```

## Responsibility of each folder

- `core/` contains shared infrastructure for networking and theming.
- `core/network/` holds the API client.
- `core/theme/` configures the Material 3 theme and the app palette.
- `features/notes/data/` contains domain models, persistence, synchronization, and conflict logic.
- `features/notes/data/models/` defines Hive models and sync metadata.
- `features/notes/data/repository/` encapsulates local CRUD and queue integration.
- `features/notes/data/services/` implements the sync engine, connectivity, queueing, and conflict handling.
- `features/notes/presentation/` contains UI-related providers, screens, and widgets.
- `main.dart` bootstraps Hive and starts the sync listener.

This structure supports clear separation of UI, state, persistence, syncing, and business logic.

---

# Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | UI framework and runtime |
| Dart | Programming language |
| Riverpod | State management |
| Hive CE | Local key-value persistence |
| hive_ce_flutter | Flutter Hive integration |
| Dio | HTTP client for REST calls |
| connectivity_plus | Network connectivity monitoring |
| uuid | Unique IDs for notes and queue operations |
| intl | Date formatting for timestamps |
| google_fonts | Material typography |

---

# Application Architecture

The app is layered with clear responsibilities:

- **Presentation Layer**: Screens and widgets handle UI rendering and user input.
- **Provider Layer**: Riverpod notifiers expose note state and refresh data after sync.
- **Repository Layer**: `NotesRepository` persists notes locally and manages queue entries.
- **Service Layer**: Sync services manage connectivity, queue processing, push/pull sync, and conflict resolution.
- **Persistence + API**: Hive stores local state and queued operations, while the REST API provides remote data.

This separation ensures the UI remains independent of sync orchestration and offline persistence.

---

# Complete Synchronization Flow

```text
Application Launch
↓
Hive Initialization
↓
Connectivity Service Starts
↓
Auto Sync Starts
↓
Conflict Detection
↓
Push Local Changes
↓
Pull Latest Server Changes
↓
Update Hive
↓
Notify Riverpod
↓
Refresh UI
```

### Step-by-step

1. **Application Launch**: `main.dart` initializes Flutter and Hive.
2. **Hive Initialization**: `HiveService.init()` opens `notes` and `operations` boxes.
3. **Connectivity Service Starts**: `SyncService.startListening()` subscribes to connectivity updates.
4. **Auto Sync Starts**: If online, sync runs immediately and periodically.
5. **Conflict Detection**: `ConflictDetector` evaluates server/local divergence for each note.
6. **Push Local Changes**: `PushSyncService` processes the queue in order.
7. **Pull Latest Server Changes**: `PullSyncService` applies new or updated server notes.
8. **Update Hive**: Local state is updated with synced values.
9. **Notify Riverpod**: `SyncService.onSyncComplete` triggers provider refresh.
10. **Refresh UI**: The Home screen displays updated notes.

---

# Offline Workflow

### Create note offline

- The note is saved to Hive immediately.
- A `SyncOperation` with `create` is queued.
- The UI shows the note and pending sync status.

### Edit note offline

- The note is updated locally with `syncStatus = pending`.
- An `update` operation is queued.
- The note remains accessible offline.

### Delete note offline

- If the note has no server ID, it is deleted locally immediately.
- Otherwise, a `delete` operation is queued.

### When connectivity returns

- The sync listener detects online status.
- The queue is pushed to the server.
- The remote state is pulled back and local Hive is updated.
- The UI refreshes via Riverpod.

---

# Queue System

The queue exists to preserve user actions when offline and to ensure deterministic sync ordering.

### Storage

- Operations are stored in Hive as `SyncOperation` objects.
- Each operation records note ID, action, creation time, and retry count.

### Processing

- `PushSyncService` processes queued operations sequentially in timestamp order.
- Completed operations are removed from the queue.

### Ordering

- Create operations must run before update/delete operations for the same note.
- The queue prevents stale operations from being sent out of order.

### Retry mechanism

- Failed operations increment `retryCount`.
- The operation remains in the queue for future sync attempts.

### Duplicate prevention

- The queue deduplicates repeated updates for the same note.
- If a note is deleted, stale queued operations are removed.

---

# Conflict Resolution

### Detection

- A conflict is detected when both local and server versions changed after the last sync and are not identical.
- `ConflictDetector` flags the note and stores the local/server snapshots.

### Storage

- Conflicts are kept in `ConflictService` in-memory as `NoteConflict` pairs.

### Resolution

- The user chooses `Keep Mine` or `Keep Server`.
- `ConflictResolver` applies the chosen version and removes the conflict state.
- The note re-enters normal sync flow.

### Sync behavior with conflicts

- Conflicted notes are skipped during push and pull.
- Other queued operations proceed normally.
- Conflict notes do not block the entire synchronization process.

---

# Connectivity Flow

### Connectivity Listener

- `ConnectivityService` listens to `connectivity_plus` events.
- Sync begins on reconnect.

### Background Sync

- Sync runs automatically on network restoration and on a 10-minute timer.
- Background sync is silent and does not show SnackBars.

### Manual Sync

- The Home Screen sync icon triggers manual synchronization.
- Manual sync shows user feedback messages.

### Pull To Refresh

- `RefreshIndicator` triggers the same manual sync path.
- It refreshes note state on user demand.

### First App Launch

- The app initializes Hive and starts listening for connectivity immediately.
- If online, sync begins automatically.

---

# State Management

Riverpod is used to manage note state across the UI.

- `NotesNotifier` exposes a list of notes and reloads state after sync.
- `notesProvider` allows screens to reactively render the latest notes.
- Repository methods trigger state refreshes after CRUD operations.
- `SyncService.onSyncComplete` ensures remote updates refresh the note list.

This keeps state changes centralized and predictable.

---

# Local Database

Hive is used for local persistence:

- `notes` box stores `Note` objects.
- `operations` box stores `SyncOperation` queue entries.
- The app registers adapters for Hive types.

Hive was chosen because it provides fast, schema-less object storage and integrates cleanly with Flutter.

---

# Networking

Dio is the HTTP client for the REST API.

- `ApiClient` performs note fetch, create, update, and delete requests.
- `PushSyncService` sends local operations to the server.
- `PullSyncService` retrieves server notes and applies changes.
- The sync services guard against invalid server data and tolerate missing deletes.

---

# UI Design

The app uses Material 3 theming with a consistent palette and typography.

- Custom `AppTheme` configures colors, cards, chips, dialogs, and snack bars.
- `AppColors` defines the primary, error, warning, and text colors.
- Screens are spaced for readability, with rounded cards and clear status indicators.
- Conflict resolution screens and note cards are designed for easy decision-making.

---

# Error Handling

The app handles errors gracefully:

- offline detection prevents failed syncs when there is no network
- network errors are logged in debug mode
- invalid server payloads are skipped safely
- retry metadata keeps failed operations for later attempts
- conflict handling isolates problems to individual notes

---

# Performance Considerations

- Hive provides efficient local reads and writes.
- The sync engine serializes operations to avoid concurrent state conflicts.
- Queue processing reduces repeated API calls.
- Background syncing is limited to reconnection and periodic intervals.
- Riverpod ensures minimal rebuilds by scoping state updates to notes.

---

# Manual Testing Checklist

- **Online Create**: create a note while online and verify it saves and syncs.
- **Offline Create**: create a note while offline and verify it persists locally and is queued.
- **Online Edit**: edit a note with network available and verify it syncs immediately.
- **Offline Edit**: edit a note offline and verify the change is queued.
- **Online Delete**: delete a note online and verify it is removed from local and remote stores.
- **Offline Delete**: delete a note offline and verify the delete operation is queued.
- **Auto Sync**: disconnect and reconnect, then verify queued changes are processed.
- **Manual Sync**: tap the sync icon and verify status feedback appears.
- **Pull**: pull to refresh and verify sync executes.
- **Conflict Detection**: create divergent local/server versions and verify the note enters conflict state.
- **Keep Mine**: resolve a conflict by keeping local note and verify server update.
- **Keep Server**: resolve a conflict by keeping server note and verify local overwrite.
- **Restart**: restart the app and verify local notes and queue persist.
- **Search**: search notes by title/body and verify result accuracy.
- **Stress Test**: queue several updates to the same note and verify deduplication and correct final state.

---

# Future Improvements

Possible enhancements:

- Authentication and user accounts
- Real backend support instead of a mock API
- Encrypted local storage for sensitive notes
- Multi-device synchronization
- Push notifications for remote changes
- Richer conflict metadata and history

---

# Screenshots

Placeholders for:

- Home
- Create
- Search
- Conflict
- Dark Mode

---

# Demo

Placeholder for a demo GIF or short video showing:

- offline note creation
- manual sync
- conflict resolution

---

# How To Run

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
flutter build apk
```

Recommended Flutter version: Flutter 3.12-compatible stable channel.

---

# Project Highlights

This project demonstrates:

- offline-first architecture
- queue-based synchronization
- conflict detection and resolution
- local persistence with Hive
- state management with Riverpod
- scalable, feature-driven folder structure

---

# Challenges Faced

Key engineering challenges tackled in this project:

- keeping the app functional offline
- preserving operation order with a queue
- resolving individual note conflicts without blocking sync
- combining background and manual sync cleanly
- ensuring state refreshes after async sync operations
- handling connectivity transitions smoothly

---

# Lessons Learned

- offline persistence must be combined with robust sync logic
- state should be decoupled from UI rendering for maintainability
- queueing operations improves reliability under intermittent connectivity
- conflict handling should isolate issues at entity boundaries
- well-defined service layers simplify sync orchestration
