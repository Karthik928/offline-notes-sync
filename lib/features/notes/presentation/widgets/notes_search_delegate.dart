import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/note.dart';
import '../../data/models/sync_status.dart';
import '../../data/services/conflict_service.dart';
import '../../data/services/sync_service.dart';
import '../providers/notes_provider.dart';
import '../screens/add_edit_note_screen.dart';
import '../screens/conflict_resolution_screen.dart';

class NotesSearchDelegate extends SearchDelegate {
  final List<Note> notes;

  NotesSearchDelegate(this.notes);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      onPressed: () => query = '',
      icon: const Icon(Icons.clear_rounded),
      tooltip: 'Clear search',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: 'Back',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filtered = notes.where((note) {
      final searchText = query.toLowerCase();
      return note.title.toLowerCase().contains(searchText) ||
          note.body.toLowerCase().contains(searchText);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'No matches found',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try a different title or body text.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final note = filtered[index];
        return _SearchResultCard(note: note);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

class _SearchResultCard extends ConsumerStatefulWidget {
  final Note note;

  const _SearchResultCard({required this.note});

  @override
  ConsumerState<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends ConsumerState<_SearchResultCard> {
  bool _isBusy = false;

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
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ConflictResolutionScreen(conflict: resolvedConflict),
          ),
        );
        if (mounted) {
          ref.read(notesProvider.notifier).load();
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Connect to reload conflict details.'),
            ),
          );
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: widget.note)),
    );
    if (mounted) {
      ref.read(notesProvider.notifier).load();
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be removed permanently.'),
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

    if (confirm != true) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(notesProvider.notifier).delete(widget.note.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.note.syncStatus);

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _isBusy ? null : _handleEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _handleEdit();
                      } else if (value == 'delete') {
                        _handleDelete();
                      }
                    },
                    iconColor: AppColors.textSecondary,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.note.body.isEmpty ? 'No content yet' : widget.note.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.note.syncStatus.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Updated ${_formatDate(widget.note.updatedAt)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
