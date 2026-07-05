import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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

class _SearchResultCard extends StatelessWidget {
  final Note note;

  const _SearchResultCard({required this.note});

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(note.syncStatus);

    return Material(
      color: AppColors.background,
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                    note.syncStatus.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.body.isEmpty ? 'No content yet' : note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
