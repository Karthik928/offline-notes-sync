import 'package:flutter/material.dart';

import '../../data/models/note.dart';
import '../../data/models/sync_status.dart';

class NotesSearchDelegate extends SearchDelegate {
  final List<Note> notes;

  NotesSearchDelegate(this.notes);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear_rounded),
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded),
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
              Icon(Icons.search_off_rounded, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('No matches found', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('Try a different title or body text.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final note = filtered[index];
        return _SearchResultCard(note: note);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

class _SearchResultCard extends StatelessWidget {
  final Note note;

  const _SearchResultCard({required this.note});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(note.syncStatus);

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Untitled note' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    note.syncStatus.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.body.isEmpty ? 'No content yet' : note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}