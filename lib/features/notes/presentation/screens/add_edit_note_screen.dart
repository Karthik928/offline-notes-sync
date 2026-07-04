import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_service.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/note.dart';
import '../../data/models/sync_status.dart';
import '../providers/notes_provider.dart';
import '../../data/services/sync_service.dart';

class AddEditNoteScreen extends ConsumerStatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  ConsumerState<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends ConsumerState<AddEditNoteScreen> {
  late final TextEditingController titleController;
  late final TextEditingController bodyController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?.title ?? '');
    bodyController = TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) return;

    final connectivity = await Connectivity().checkConnectivity();
    final connected = connectivity.any((result) => result != ConnectivityResult.none);

    if (widget.note == null) {
      final now = DateTime.now();

      final note = Note(
        id: const Uuid().v4(),
        title: title,
        body: body,
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: null,
        syncStatus: SyncStatus.pending,
        isDeleted: false,
      );

      await ref.read(notesProvider.notifier).add(note);
    } else {
      final updated = widget.note!.copyWith(
        title: title,
        body: body,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await ref.read(notesProvider.notifier).update(updated);
    }

    if (!mounted) return;

    if (connected) {
      await SyncService.instance.sync();
      await SyncService.instance.pullFromServer();
      ref.read(notesProvider.notifier).load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synced successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved locally. Will sync automatically.')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Title',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: bodyController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Write something...',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: save,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Save'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
