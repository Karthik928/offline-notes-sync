import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/note_conflict.dart';
import '../../data/services/sync_service.dart';
import '../providers/notes_provider.dart';

class ConflictResolutionScreen extends ConsumerStatefulWidget {
  final NoteConflict conflict;

  const ConflictResolutionScreen({super.key, required this.conflict});

  @override
  ConsumerState<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

enum _ResolutionChoice { local, server }

class _ConflictResolutionScreenState
    extends ConsumerState<ConflictResolutionScreen> {
  _ResolutionChoice? _resolving;

  bool get _isBusy => _resolving != null;

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy · h:mm a').format(date.toLocal());
  }

  Future<void> _resolve({
    required _ResolutionChoice choice,
    required Future<void> Function(String noteId) action,
    required String successMessage,
  }) async {
    if (_isBusy) return;

    setState(() => _resolving = choice);

    try {
      await action(widget.conflict.local.id);

      if (!mounted) return;

      ref.read(notesProvider.notifier).load();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => _resolving = null);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not resolve conflict: $e')));
    }
  }

  Future<void> _keepLocal() => _resolve(
    choice: _ResolutionChoice.local,
    action: SyncService.instance.resolveConflictKeepLocal,
    successMessage: 'Kept your version — uploaded to the server.',
  );

  Future<void> _keepServer() => _resolve(
    choice: _ResolutionChoice.server,
    action: SyncService.instance.resolveConflictKeepServer,
    successMessage: 'Kept the server version.',
  );

  @override
  Widget build(BuildContext context) {
    final local = widget.conflict.local;
    final server = widget.conflict.server;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve conflict'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ConflictBanner(
                      noteTitle: local.title.isEmpty
                          ? 'Untitled note'
                          : local.title,
                    ),
                    const SizedBox(height: 20),
                    _VersionCard(
                      label: 'Your version',
                      icon: Icons.person_rounded,
                      containerColor: AppColors.primary.withValues(alpha: 0.12),
                      onContainerColor: AppColors.primary,
                      title: local.title,
                      body: local.body,
                      updatedAtLabel: _formatDate(local.updatedAt),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.divider.withValues(alpha: 0.35),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.compare_arrows_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.divider.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _VersionCard(
                      label: 'Server version',
                      icon: Icons.cloud_rounded,
                      containerColor: AppColors.editAccent.withValues(
                        alpha: 0.12,
                      ),
                      onContainerColor: AppColors.editAccent,
                      title: server.title,
                      body: server.body,
                      updatedAtLabel: _formatDate(server.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            _ResolutionActions(
              isBusy: _isBusy,
              resolving: _resolving,
              onKeepLocal: _keepLocal,
              onKeepServer: _keepServer,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  final String noteTitle;

  const _ConflictBanner({required this.noteTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"$noteTitle" was edited in two places',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'It changed on this device and on the server since the last sync. '
                  'Choose which version to keep — the other will be discarded.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color containerColor;
  final Color onContainerColor;
  final String title;
  final String body;
  final String updatedAtLabel;

  const _VersionCard({
    required this.label,
    required this.icon,
    required this.containerColor,
    required this.onContainerColor,
    required this.title,
    required this.body,
    required this.updatedAtLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: onContainerColor),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: onContainerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title.isEmpty ? 'Untitled note' : title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: onContainerColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body.isEmpty ? 'No content' : body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: onContainerColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: onContainerColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Updated $updatedAtLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: onContainerColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResolutionActions extends StatelessWidget {
  final bool isBusy;
  final _ResolutionChoice? resolving;
  final VoidCallback onKeepLocal;
  final VoidCallback onKeepServer;

  const _ResolutionActions({
    required this.isBusy,
    required this.resolving,
    required this.onKeepLocal,
    required this.onKeepServer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: isBusy ? null : onKeepLocal,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: resolving == _ResolutionChoice.local
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.person_rounded),
            label: const Text('Keep my version'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onKeepServer,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: resolving == _ResolutionChoice.server
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.cloud_rounded),
            label: const Text('Keep server version'),
          ),
        ],
      ),
    );
  }
}
