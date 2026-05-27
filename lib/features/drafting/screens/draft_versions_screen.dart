// drafting/screens/draft_versions_screen.dart — Track 1B Drafting Studio.
// -----------------------------------------------------------------------------
// Lists the historical `draft_versions` snapshots for a given draftId, newest
// first. Each row shows:
//   - timeago timestamp (e.g. "5m ago")
//   - sparkle icon when `is_ai_revision` is true
//   - first 100 chars of plaintext-stripped snapshot as preview
//   - "Restore" button that copies the snapshot back into the live draft.
//
// The restore action is reversible: `DraftService.restoreVersion` snapshots
// the *current* body BEFORE overwriting, so the user can roll back from
// this same screen.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/draft_model.dart';
import '../services/draft_service.dart';
import '../widgets/drafting_strings.dart';

/// Auto-disposed provider so navigating away clears the cache. We re-fetch
/// versions every time the screen is opened — the list is bounded at 10 rows
/// per draft (DB trigger) so this is cheap.
final draftVersionsProvider = FutureProvider.autoDispose
    .family<List<DraftVersion>, String>((ref, draftId) async {
  return ref.watch(draftServiceProvider).getVersions(draftId);
});

class DraftVersionsScreen extends ConsumerWidget {
  const DraftVersionsScreen({
    super.key,
    required this.draftId,
  });

  /// Owning draft. Used for both the version list query and the restore
  /// service call.
  final String draftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = DraftingStrings.of(context);
    final versionsAsync = ref.watch(draftVersionsProvider(draftId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.versionsTitle)),
      body: versionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          debugPrint('[draft_versions] load failed: $e\n$st');
          return Center(child: Text(l10n.versionsRestoreFailed));
        },
        data: (versions) {
          if (versions.isEmpty) {
            return _EmptyState(message: l10n.versionsEmpty);
          }
          return ListView.separated(
            key: const Key('draft_versions_list_view'),
            itemCount: versions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final v = versions[i];
              return _VersionRow(
                version: v,
                onRestore: () => _restore(context, ref, v.id),
                l10n: l10n,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, String versionId) async {
    final l10n = DraftingStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('draft_versions_restore_dialog'),
        title: Text(l10n.versionsRestoreConfirmTitle),
        content: Text(l10n.versionsRestoreConfirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.versionsRestoreConfirmAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(draftServiceProvider).restoreVersion(draftId, versionId);
      // Refresh the list so the new "pre_restore" snapshot shows up.
      ref.invalidate(draftVersionsProvider(draftId));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.versionsRestoreSuccess)),
      );
      if (!context.mounted) return;
      // Pop back to the editor — the host will reload its draft on focus.
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('[draft_versions] restore failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.versionsRestoreFailed)),
      );
    }
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.version,
    required this.onRestore,
    required this.l10n,
  });

  final DraftVersion version;
  final VoidCallback onRestore;
  final DraftingStrings l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = version.previewSnippet();
    return Padding(
      key: Key('draft_versions_row_${version.id}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      timeago.format(version.createdAt),
                      style: theme.textTheme.labelLarge,
                    ),
                    if (version.isAiRevision) ...<Widget>[
                      const SizedBox(width: 8),
                      _AiBadge(label: l10n.versionsAiBadge),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  preview.isEmpty ? l10n.empty : preview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            key: Key('draft_versions_restore_${version.id}'),
            onPressed: onRestore,
            child: Text(l10n.versionsRestoreAction),
          ),
        ],
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('draft_versions_ai_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.auto_awesome,
            size: 12,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              key: const Key('draft_versions_empty_message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
