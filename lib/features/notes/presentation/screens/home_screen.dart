import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:offline_notes_sync/features/notes/data/services/conflict_service.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_service.dart';
import 'package:offline_notes_sync/features/notes/presentation/widgets/notes_search_delegate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/note.dart';
import '../../data/models/sync_status.dart';
import '../providers/notes_provider.dart';

import 'add_edit_note_screen.dart';
import 'conflict_resolution_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSyncing = false;

  Future<void> _handleSync({bool showFeedback = true}) async {
    if (_isSyncing) return;

    final connectivity = await Connectivity().checkConnectivity();
    final connected = connectivity.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!connected) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Saved locally. Will sync automatically.'),
            ),
          );
      }
      return;
    }

    setState(() => _isSyncing = true);

    try {
      await SyncService.instance.sync();

      if (mounted) {
        ref.read(notesProvider.notifier).load();
        if (showFeedback) {
          final hasConflicts = ref
              .read(notesProvider)
              .any((note) => note.syncStatus == SyncStatus.conflict);
          final message = hasConflicts
              ? 'Sync paused. Resolve conflicts to continue.'
              : 'Synced successfully';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
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
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    final pendingCount = notes
        .where((note) => note.syncStatus == SyncStatus.pending)
        .length;
    final conflictCount = notes
        .where((note) => note.syncStatus == SyncStatus.conflict)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Offline notes'),
            const SizedBox(height: 2),
            Text(
              _summaryLine(notes.length, pendingCount, conflictCount),
              style: const TextStyle(
                color: AppColors.onPrimaryMuted,
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
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          _isSyncing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.onPrimary,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _handleSync,
                  icon: const Icon(Icons.sync_rounded),
                  tooltip: 'Sync notes',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleSync,
        child: Container(
          color: AppColors.background,
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
          );

          ref.read(notesProvider.notifier).load();
        },
        child: const Icon(Icons.add_rounded),
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
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sticky_note_2_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first note. Notes automatically sync when online.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
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
        return AppColors.success;
      case SyncStatus.pending:
        return AppColors.warning;
      case SyncStatus.conflict:
        return AppColors.error;
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
    if (widget.note.syncStatus == SyncStatus.conflict) {
      var conflict = ConflictService.getForNote(widget.note.id);

      if (conflict == null) {
        await SyncService.instance.sync();
        if (!mounted) return;
        ref.read(notesProvider.notifier).load();
        conflict = ConflictService.getForNote(widget.note.id);
      }

      final resolvedConflict = conflict;
      if (resolvedConflict != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ConflictResolutionScreen(conflict: resolvedConflict),
          ),
        );

        ref.read(notesProvider.notifier).load();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Connect to reload conflict details.')),
        );
      return;
    }

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
              bottom: BorderSide(color: AppColors.divider, width: 1.5),
            ),
          ),
          child: Material(
            color: AppColors.transparent,
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
                                    color: AppColors.textPrimary,
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
                          color: AppColors.editAccent,
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
                          color: AppColors.error,
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
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        widget.note.syncStatus == SyncStatus.conflict
                            ? 'Tap to resolve conflict'
                            : 'Last edit: ${_formatDate(widget.note.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight:
                              widget.note.syncStatus == SyncStatus.conflict
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: widget.note.syncStatus == SyncStatus.conflict
                              ? AppColors.error
                              : AppColors.textMuted,
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
