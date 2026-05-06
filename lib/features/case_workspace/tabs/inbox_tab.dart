// =====================================================================
// Phase 2 Pkg 4 — Inbox tab.
//
// Reuses the Email D6 inbox provider, filtered to the current case.
// Threads with `case_id == this caseId` render as TriageCards. The
// inboxProvider is the single source of truth — sharing it with the
// global inbox tab guarantees actions taken here (snooze / approve)
// reflect everywhere.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../inbox/providers/inbox_provider.dart';
import '../../inbox/widgets/triage_card.dart';

class InboxTab extends ConsumerWidget {
  const InboxTab({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(inboxProvider);

    if (state.isLoading && state.threads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = state.threads
        .where((t) => t.caseId != null && t.caseId == caseId)
        .toList(growable: false);

    if (filtered.isEmpty) {
      return Center(
        key: const Key('workspace-inbox-empty'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n?.workspaceInboxEmpty ?? 'No related email.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(inboxProvider.notifier).refresh(),
      child: ListView.separated(
        key: const Key('workspace-inbox-tab'),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, i) => TriageCard(
          key: ValueKey('workspace-inbox-${filtered[i].threadId}'),
          thread: filtered[i],
        ),
      ),
    );
  }
}
