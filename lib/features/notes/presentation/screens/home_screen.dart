import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/note.dart';
import '../../data/models/sync_status.dart';
import '../providers/notes_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Offline Notes"), centerTitle: true),

      body: notes.isEmpty
          ? const _EmptyView()
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];

                return _NoteCard(note: note);
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Batch 2C
        },
        icon: const Icon(Icons.add),
        label: const Text("Note"),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 80),
          SizedBox(height: 16),
          Text(
            "No Notes Yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text("Tap + to create your first note."),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;

  const _NoteCard({required this.note});

  Color _statusColor() {
    switch (note.syncStatus) {
      case SyncStatus.synced:
        return Colors.green;

      case SyncStatus.pending:
        return Colors.orange;

      case SyncStatus.conflict:
        return Colors.red;
    }
  }

  String _statusText() {
    switch (note.syncStatus) {
      case SyncStatus.synced:
        return "Synced";

      case SyncStatus.pending:
        return "Pending";

      case SyncStatus.conflict:
        return "Conflict";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),

            const SizedBox(height: 10),

            Chip(
              backgroundColor: _statusColor().withOpacity(.15),
              label: Text(
                _statusText(),
                style: TextStyle(
                  color: _statusColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => const [
            PopupMenuItem(value: "edit", child: Text("Edit")),
            PopupMenuItem(value: "delete", child: Text("Delete")),
          ],
          onSelected: (value) async {
            if (value == "delete") {
              await ref.read(notesProvider.notifier).delete(note.id);
            }

            if (value == "edit") {
              // Batch 2C
            }
          },
        ),
      ),
    );
  }
}
