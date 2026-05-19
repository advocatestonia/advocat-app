// drafting/screens/drafts_list_screen.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Shows the user's saved drafts sorted by updated_at. Empty state offers a
// CTA that opens an empty editor (which creates the row on first save).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../l10n/app_localizations.dart';
import '../models/draft_model.dart';
import '../services/draft_service.dart';
import '../widgets/drafting_strings.dart';
import 'drafting_studio_screen.dart';

final myDraftsProvider = FutureProvider.autoDispose<List<Draft>>((ref) async {
  return ref.watch(draftServiceProvider).listMyDrafts();
});

class DraftsListScreen extends ConsumerWidget {
  const DraftsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = DraftingStrings.of(context);
    final draftsAsync = ref.watch(myDraftsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.draftsList)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('drafts_list_new_fab'),
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newDraft),
      ),
      body: draftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
              onCreate: () => _openEditor(context),
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
                title: Text(d.displayTitle(untitledFallback: l10n.untitled)),
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
    );
  }

  static void _openEditor(BuildContext context, {DraftPrefill? prefill}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DraftingStudioScreen(prefill: prefill),
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
    }
  }

  String _subtitleFor(Draft d, BuildContext ctx) {
    final preview = d.contentPlaintext.replaceAll('\n', ' ').trim();
    if (preview.isEmpty) {
      return DraftingStrings.of(ctx).empty;
    }
    return preview.length > 80 ? '${preview.substring(0, 80)}…' : preview;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.l10n});
  final VoidCallback onCreate;
  final DraftingStrings l10n;

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
              l10n.emptyListMessage,
              key: const Key('drafts_list_empty_message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('drafts_list_empty_cta'),
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.emptyListAction),
            ),
          ],
        ),
      ),
    );
  }
}
