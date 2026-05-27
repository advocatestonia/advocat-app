// drafting/screens/draft_templates_screen.dart — Track 1B Drafting Studio.
// -----------------------------------------------------------------------------
// Five-card picker that replaces the bare "New draft" CTA. Choosing a card
// creates a draft via `DraftService.createDraft` with the matching
// `source_type` and a localised starter title + body, then navigates to the
// Drafting Studio editor for the new row.
//
// The "Contract review reply" card is locked until the user has at least one
// row in `contract_reviews`. We do a cheap count(*) on mount; the server is
// the authoritative gate (`source_id` is free-form anyway, so blocking here
// is purely UX guidance).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/draft_model.dart';
import '../services/draft_service.dart';
import '../widgets/drafting_strings.dart';
import 'drafting_studio_screen.dart';

/// Returns true if the signed-in user has at least one contract review row.
/// Used purely to enable/disable the "Contract review reply" template card.
///
/// Test-only override hook so widget tests don't need to spin up Supabase.
typedef ContractReviewProbe = Future<bool> Function();
ContractReviewProbe? debugContractReviewProbe;

final hasContractReviewsProvider = FutureProvider.autoDispose<bool>((ref) async {
  final override = debugContractReviewProbe;
  if (override != null) return override();
  try {
    final client = Supabase.instance.client;
    // Cheap exists check — `head: true` + `count: exact` returns just the
    // count, no rows. RLS already scopes this to the current user.
    final res = await client
        .from('contract_reviews')
        .select('id')
        .limit(1)
        .maybeSingle();
    return res != null;
  } catch (e, st) {
    debugPrint('[draft_templates] contract review probe failed: $e\n$st');
    // Fail-closed: don't enable the card if we can't verify.
    return false;
  }
});

/// Pure description of a starter template. Kept top-level so widget tests
/// can verify the catalogue without a Supabase round-trip.
class DraftTemplateOption {
  const DraftTemplateOption({
    required this.key,
    required this.sourceType,
    required this.icon,
    required this.title,
    required this.description,
    required this.starterTitle,
    required this.starterMarkdown,
    this.requiresContractReview = false,
  });

  final String key;
  final DraftSourceType sourceType;
  final IconData icon;
  final String title;
  final String description;
  final String starterTitle;
  final String starterMarkdown;
  final bool requiresContractReview;
}

/// Builds the 5 starter cards for the active locale. Order matches the spec
/// (Blank · Letter · Appeal · Memo · Contract review reply).
List<DraftTemplateOption> buildTemplateCatalogue(DraftingStrings l10n) {
  return <DraftTemplateOption>[
    DraftTemplateOption(
      key: 'blank',
      sourceType: DraftSourceType.blank,
      icon: Icons.edit_note,
      title: l10n.templateBlankTitle,
      description: l10n.templateBlankDescription,
      starterTitle: l10n.templateStarterTitleBlank,
      starterMarkdown: l10n.templateStarterBodyBlank,
    ),
    DraftTemplateOption(
      key: 'letter',
      sourceType: DraftSourceType.letter,
      icon: Icons.mail_outline,
      title: l10n.templateLetterTitle,
      description: l10n.templateLetterDescription,
      starterTitle: l10n.templateStarterTitleLetter,
      starterMarkdown: l10n.templateStarterBodyLetter,
    ),
    DraftTemplateOption(
      key: 'appeal',
      sourceType: DraftSourceType.appeal,
      icon: Icons.gavel,
      title: l10n.templateAppealTitle,
      description: l10n.templateAppealDescription,
      starterTitle: l10n.templateStarterTitleAppeal,
      starterMarkdown: l10n.templateStarterBodyAppeal,
    ),
    DraftTemplateOption(
      key: 'memo',
      sourceType: DraftSourceType.memo,
      icon: Icons.sticky_note_2_outlined,
      title: l10n.templateMemoTitle,
      description: l10n.templateMemoDescription,
      starterTitle: l10n.templateStarterTitleMemo,
      starterMarkdown: l10n.templateStarterBodyMemo,
    ),
    DraftTemplateOption(
      key: 'contract_review_reply',
      sourceType: DraftSourceType.contractReviewReply,
      icon: Icons.reply,
      title: l10n.templateContractReplyTitle,
      description: l10n.templateContractReplyDescription,
      starterTitle: l10n.templateStarterTitleContractReply,
      starterMarkdown: l10n.templateStarterBodyContractReply,
      requiresContractReview: true,
    ),
  ];
}

class DraftTemplatesScreen extends ConsumerWidget {
  const DraftTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = DraftingStrings.of(context);
    final hasReviewsAsync = ref.watch(hasContractReviewsProvider);
    final templates = buildTemplateCatalogue(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.templatesTitle)),
      body: ListView(
        key: const Key('draft_templates_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Text(
              l10n.templatesSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (final t in templates)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TemplateCard(
                option: t,
                locked: t.requiresContractReview &&
                    !(hasReviewsAsync.asData?.value ?? false),
                lockedLabel: l10n.templateContractReplyLocked,
                onTap: () => _create(context, ref, t),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    DraftTemplateOption option,
  ) async {
    final svc = ref.read(draftServiceProvider);
    final l10n = DraftingStrings.of(context);
    final userId = _currentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailed)),
      );
      return;
    }
    try {
      final draft = await svc.createDraft(
        userId: userId,
        sourceType: option.sourceType,
        title: option.starterTitle,
        contentMarkdown: option.starterMarkdown,
        language: Localizations.localeOf(context).languageCode,
      );
      if (!context.mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DraftingStudioScreen(draftId: draft.id),
        ),
      );
    } catch (e, st) {
      debugPrint('[draft_templates] createDraft failed: $e\n$st');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailed)),
      );
    }
  }

  String? _currentUserId() {
    // Same hook the Drafting Studio uses so widget tests can inject a fake
    // user id without booting Supabase.
    final override = debugSupabaseUserIdAccessor;
    if (override != null) return override();
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.option,
    required this.locked,
    required this.lockedLabel,
    required this.onTap,
  });

  final DraftTemplateOption option;
  final bool locked;
  final String lockedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = theme.disabledColor;
    return Card(
      key: Key('draft_template_card_${option.key}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                option.icon,
                size: 28,
                color: locked ? disabledColor : theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      option.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: locked ? disabledColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: locked
                            ? disabledColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (locked) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(Icons.lock_outline, size: 14, color: disabledColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              lockedLabel,
                              key: Key(
                                'draft_template_locked_${option.key}',
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: disabledColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
