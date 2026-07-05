import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/note.dart';
import '../../data/models/sync_status.dart';
import '../providers/notes_provider.dart';

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

    late final String savedNoteId;

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
      savedNoteId = note.id;
    } else {
      final updated = widget.note!.copyWith(
        title: title,
        body: body,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await ref.read(notesProvider.notifier).update(updated);
      savedNoteId = updated.id;
    }

    if (!mounted) return;

    ref.read(notesProvider.notifier).load();

    final savedNote = ref.read(notesRepositoryProvider).getById(savedNoteId);
    final message = savedNote?.syncStatus == SyncStatus.synced
        ? 'Synced successfully'
        : 'Saved locally. Will sync automatically.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  fillColor: AppColors.background.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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
                    fillColor: AppColors.background.withValues(alpha: 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    alignLabelWithHint: true,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
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
