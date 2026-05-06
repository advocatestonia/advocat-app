// =====================================================================
// Phase 2 Pkg 4 — Drafts tab.
//
// Surfaces in-memory drafts (chat tool result history + email triage
// drafts attributed to this case). Until Pkg 7 ships the
// `case_drafts` table, this tab reads from
// [workspaceCaseDraftsProvider]; Pkg 7 swaps the provider for a
// repo-backed store without touching this file.
//
// Tap a draft → opens the existing DraftViewerScreen (full-screen)
// pre-populated with title + body.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../drafts/screens/draft_viewer_screen.dart';
import '../providers/case_workspace_provider.dart';

class DraftsTab extends ConsumerWidget {
  const DraftsTab({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final drafts = ref.watch(workspaceCaseDraftsProvider(caseId));

    if (drafts.isEmpty) {
      return Center(
        key: const Key('workspace-drafts-empty'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_note_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n?.workspaceDraftsEmpty ?? 'No drafts yet.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('workspace-drafts-tab'),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: drafts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, i) {
        final d = drafts[i];
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            key: Key('workspace-draft-${d.id}'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DraftViewerScreen(
                  caseId: caseId,
                  draftTitle: d.title,
                  draftContent: d.body,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: d.pending
                          ? AppColors.accent.withValues(alpha: 0.10)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 18,
                      color:
                          d.pending ? AppColors.accent : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
