import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_service.dart';
import 'package:offline_notes_sync/features/notes/presentation/widgets/notes_search_delegate.dart';

import '../../data/models/note.dart';
import '../../data/models/sync_status.dart';
import '../providers/notes_provider.dart';

import 'add_edit_note_screen.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final theme = Theme.of(context);

    final pendingCount = notes
        .where((note) => note.syncStatus == SyncStatus.pending)
        .length;
    final conflictCount = notes
        .where((note) => note.syncStatus == SyncStatus.conflict)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offline Notes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
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
        child: notes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 48),
                  _EmptyView(),
                  SizedBox(height: 48),
                ],
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _SyncStatusBar(
                      totalCount: notes.length,
                      pendingCount: pendingCount,
                      conflictCount: conflictCount,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final note = notes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnimatedNoteCard(note: note),
                        );
                      }, childCount: notes.length),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
          );

          ref.read(notesProvider.notifier).load();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New note'),
      ),
    );
  }
}

/// A single glanceable line summarizing sync state — replaces the previous
/// 4-card stat grid, which wrapped awkwardly on narrow screens and competed
/// with the notes list for attention.
class _SyncStatusBar extends StatelessWidget {
  final int totalCount;
  final int pendingCount;
  final int conflictCount;

  const _SyncStatusBar({
    required this.totalCount,
    required this.pendingCount,
    required this.conflictCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final allSynced = pendingCount == 0 && conflictCount == 0 && totalCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sticky_note_2_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '$totalCount ${totalCount == 1 ? 'note' : 'notes'}',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (pendingCount > 0) ...[
            const SizedBox(width: 16),
            _StatusDot(color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Text(
              '$pendingCount pending',
              style: textTheme.labelLarge?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (conflictCount > 0) ...[
            const SizedBox(width: 16),
            _StatusDot(color: colorScheme.error),
            const SizedBox(width: 6),
            Text(
              '$conflictCount need attention',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          if (allSynced)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'All synced',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 56,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notes Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first note. Notes automatically sync when online.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
              label: const Text('Create Note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNoteCard extends ConsumerStatefulWidget {
  final Note note;

  const _AnimatedNoteCard({required this.note});

  @override
  ConsumerState<_AnimatedNoteCard> createState() => _AnimatedNoteCardState();
}

class _AnimatedNoteCardState extends ConsumerState<_AnimatedNoteCard>
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
        return Colors.green.shade700;
      case SyncStatus.pending:
        return Colors.orange.shade700;
      case SyncStatus.conflict:
        return Colors.red.shade700;
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

  String _statusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(widget.note.syncStatus);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: InkWell(
            onTap: _handleEdit,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.note.title.isEmpty
                                  ? 'Untitled note'
                                  : widget.note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.note.body.isEmpty
                                  ? 'No content yet'
                                  : widget.note.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _handleEdit();
                          } else if (value == 'delete') {
                            await _handleDelete();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Updated ${_formatDate(widget.note.updatedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Builder(
                        builder: (context) {
                          // "Synced" is the default, expected state — giving it
                          // the same bold color treatment as Pending/Conflict on
                          // every single card is just noise once the summary bar
                          // already says "All synced". Only states that need the
                          // user's attention get the loud filled badge.
                          final needsAttention =
                              widget.note.syncStatus != SyncStatus.synced;
                          final badgeColor = needsAttention
                              ? statusColor
                              : colorScheme.onSurfaceVariant;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: needsAttention
                                  ? statusColor.withValues(alpha: 0.14)
                                  : null,
                              border: needsAttention
                                  ? null
                                  : Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon(widget.note.syncStatus),
                                  size: 14,
                                  color: badgeColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _statusLabel(widget.note.syncStatus),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: badgeColor,
                                    fontWeight: needsAttention
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
