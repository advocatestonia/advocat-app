// drafting/screens/drafts_list_screen.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Shows the user's saved drafts sorted by updated_at. Empty state offers a
// CTA that opens an empty editor (which creates the row on first save).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../l10n/app_localizations.dart';
// WAVE 2 FIX W2-03 (F3): drafts list reveals client-matter titles.
import '../../../shared/secure_screen.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../models/draft_model.dart';
import '../services/draft_service.dart';
import 'draft_templates_screen.dart';
import 'drafting_studio_screen.dart';

final myDraftsProvider = FutureProvider.autoDispose<List<Draft>>((ref) async {
  return ref.watch(draftServiceProvider).listMyDrafts();
});

class DraftsListScreen extends ConsumerWidget {
  const DraftsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final draftsAsync = ref.watch(myDraftsProvider);

    return SecureScreenScope(
      child: Scaffold(
      appBar: AppBar(title: Text(l10n.draftingDraftsList)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('drafts_list_new_fab'),
        onPressed: () => _openTemplates(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.draftingNewDraft),
      ),
      body: draftsAsync.when(
        // Cold-start: 4 draft-tile skeletons (matches the real ListTile
        // layout below). Honors WCAG reduce-motion via _ReduceMotionShimmer.
        loading: () => const DocumentListSkeleton(itemCount: 4),
        error: (e, st) {
          debugPrint('[drafts_list] myDraftsProvider failed: $e\n$st');
          return Center(
            child: Text(
              AppLocalizations.of(context)?.genericError ??
                  'Something went wrong. Please try again.',
            ),
          );
        },
        data: (drafts) {
          if (drafts.isEmpty) {
            return _EmptyState(
              onCreate: () => _openTemplates(context),
              l10n: l10n,
            );
          }
          return ListView.separated(
            key: const Key('drafts_list_view'),
            itemCount: drafts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = drafts[i];
              return ListTile(
                key: Key('drafts_list_item_${d.id}'),
                leading: Icon(_iconFor(d.sourceType)),
                title: Text(d.displayTitle(untitledFallback: l10n.draftingUntitled)),
                subtitle: Text(_subtitleFor(d, ctx)),
                trailing: Text(timeago.format(d.updatedAt)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DraftingStudioScreen(draftId: d.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }

  /// Track 1B — empty-state CTA and FAB both open the templates picker first.
  /// The picker creates the draft (with the chosen source_type + starter
  /// content) and then pushReplacement-s the editor.
  static void _openTemplates(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DraftTemplatesScreen(),
      ),
    );
  }

  IconData _iconFor(DraftSourceType t) {
    switch (t) {
      case DraftSourceType.contractReviewReply:
        return Icons.reply;
      case DraftSourceType.letter:
        return Icons.mail_outline;
      case DraftSourceType.appeal:
        return Icons.gavel;
      case DraftSourceType.memo:
        return Icons.sticky_note_2_outlined;
      case DraftSourceType.blank:
        return Icons.edit_note;
      case DraftSourceType.vaultNote:
      case DraftSourceType.vaultImport:
        return Icons.lock_outline;
    }
  }

  String _subtitleFor(Draft d, BuildContext ctx) {
    final preview = d.contentPlaintext.replaceAll('\n', ' ').trim();
    if (preview.isEmpty) {
      return AppLocalizations.of(ctx)!.draftingEmpty;
    }
    return preview.length > 80 ? '${preview.substring(0, 80)}…' : preview;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.l10n});
  final VoidCallback onCreate;
  final AppLocalizations l10n;

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
              Icons.edit_note,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.draftingEmptyListMessage,
              key: const Key('drafts_list_empty_message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('drafts_list_empty_cta'),
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.draftingEmptyListAction),
            ),
          ],
        ),
      ),
    );
  }
}
