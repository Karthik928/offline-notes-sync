import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_service.dart';
import 'package:offline_notes_sync/features/notes/presentation/widgets/notes_search_delegate.dart';

import '../../data/models/note.dart';
import '../../data/models/sync_status.dart';
import '../providers/notes_provider.dart';

import 'add_edit_note_screen.dart';

/// Fixed brand palette for the notepad look — deep teal chrome over a warm
/// ivory list. Not derived from Theme.of(context) on purpose: this screen's
/// colors are a deliberate identity, not a Material color scheme.
///
/// If this palette ends up reused on other screens, pull it out into its own
/// AppColors file the same way the rider app does.
class _NotesPalette {
  static const appBar = Color(0xFF1B6E64);
  static const appBarSubtitle = Color(0xFFCFE8E3);
  static const background = Color(0xFFF4F1E6);
  static const divider = Color(0xFF1D2F2C);
  static const title = Color(0xFF1B2B28);
  static const body = Color(0xFF5C6D69);
  static const timestamp = Color(0xFF7A8B87);
  static const synced = Color(0xFF2F7D4A);
  static const pending = Color(0xFFA8681E);
  static const conflict = Color(0xFFA23B32);
  static const edit = Color(0xFF4C7A72);
  static const delete = Color(0xFFA23B32);
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _handleSync(
    BuildContext context,
    WidgetRef ref, {
    bool showFeedback = true,
  }) async {
    final connectivity = await Connectivity().checkConnectivity();
    final connected = connectivity.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!connected) {
      if (showFeedback && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally. Will sync automatically.'),
          ),
        );
      }
      return;
    }

    await SyncService.instance.sync();
    await SyncService.instance.pullFromServer();

    if (context.mounted) {
      ref.read(notesProvider.notifier).load();
      if (showFeedback) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Synced successfully')));
      }
    }
  }

  String _summaryLine(int total, int pending, int conflict) {
    final parts = <String>['$total ${total == 1 ? 'note' : 'notes'}'];

    if (pending > 0) {
      parts.add('$pending pending');
    }

    if (conflict > 0) {
      parts.add('$conflict conflict${conflict == 1 ? '' : 's'}');
    }

    if (pending == 0 && conflict == 0 && total > 0) {
      parts.add('all synced');
    }

    return parts.join(' \u00B7 ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    final pendingCount = notes
        .where((note) => note.syncStatus == SyncStatus.pending)
        .length;
    final conflictCount = notes
        .where((note) => note.syncStatus == SyncStatus.conflict)
        .length;

    return Scaffold(
      backgroundColor: _NotesPalette.background,
      appBar: AppBar(
        backgroundColor: _NotesPalette.appBar,
        elevation: 0,
        toolbarHeight: 72,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Offline notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _summaryLine(notes.length, pendingCount, conflictCount),
              style: const TextStyle(
                color: _NotesPalette.appBarSubtitle,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: NotesSearchDelegate(notes),
              );
            },
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search notes',
          ),
          IconButton(
            onPressed: () => _handleSync(context, ref),
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync notes',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _handleSync(context, ref),
        child: Container(
          color: _NotesPalette.background,
          child: notes.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 48),
                    _EmptyView(),
                    SizedBox(height: 48),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _AnimatedNoteRow(note: note);
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _NotesPalette.appBar,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
          );

          ref.read(notesProvider.notifier).load();
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: _NotesPalette.appBar.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sticky_note_2_outlined,
                size: 56,
                color: _NotesPalette.appBar,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _NotesPalette.title,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first note. Notes automatically sync when online.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: _NotesPalette.body),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _NotesPalette.appBar,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNoteRow extends ConsumerStatefulWidget {
  final Note note;

  const _AnimatedNoteRow({required this.note});

  @override
  ConsumerState<_AnimatedNoteRow> createState() => _AnimatedNoteRowState();
}

class _AnimatedNoteRowState extends ConsumerState<_AnimatedNoteRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _statusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return _NotesPalette.synced;
      case SyncStatus.pending:
        return _NotesPalette.pending;
      case SyncStatus.conflict:
        return _NotesPalette.conflict;
    }
  }

  IconData _statusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Icons.check_circle_rounded;
      case SyncStatus.pending:
        return Icons.cloud_upload_rounded;
      case SyncStatus.conflict:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('M/d/yy, h:mm a').format(date.toLocal());
  }

  Future<void> _handleDelete() async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be removed from your local list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (delete == true) {
      await ref.read(notesProvider.notifier).delete(widget.note.id);
    }
  }

  Future<void> _handleEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: widget.note)),
    );

    ref.read(notesProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.note.syncStatus);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _NotesPalette.divider, width: 1.5),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.note.title.isEmpty
                                      ? 'Untitled note'
                                      : widget.note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: _NotesPalette.title,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _statusIcon(widget.note.syncStatus),
                                size: 15,
                                color: statusColor,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _handleEdit,
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 19,
                          color: _NotesPalette.edit,
                          tooltip: 'Edit note',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          onPressed: _handleDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          iconSize: 19,
                          color: _NotesPalette.delete,
                          tooltip: 'Delete note',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.note.body.isEmpty
                          ? 'No content yet'
                          : widget.note.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _NotesPalette.body,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Last edit: ${_formatDate(widget.note.updatedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: _NotesPalette.timestamp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
