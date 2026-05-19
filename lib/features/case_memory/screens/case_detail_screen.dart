// =====================================================================
// CaseDetailScreen — read-only view of a UserCase row.
//
// Renders all jsonb sections as collapsible cards. Actions:
//   - "Edit" → /cases-v2/:id/edit (full form)
//   - "Continue chat about this case" → sets active + navigates to chat
//   - Overflow → archive / close
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/case_repository.dart';
import '../models/case_deadline.dart';
import '../models/user_case.dart';
import '../state/active_case_provider.dart';
import '../state/case_deadline_providers.dart';
import '../state/cases_list_provider.dart';
import '../widgets/deadline_card.dart';

class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final caseAsync = ref.watch(caseByIdProvider(caseId));

    return caseAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        debugPrint('case_detail load failed: $e');
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(
              l10n?.genericError ?? 'Something went wrong. Please try again.',
            ),
          ),
        );
      },
      data: (c) {
        if (c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n?.error ?? 'Case not found')),
          );
        }
        return _Body(userCase: c);
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.userCase});
  final UserCase userCase;

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);
    final ack = AppLocalizations.of(context)?.caseArchivedAck ??
        'Case archived';
    await ref.read(caseRepositoryProvider).archiveCase(userCase.id);
    ref.invalidate(casesListProvider);
    ref.invalidate(caseByIdProvider(userCase.id));
    messenger.showSnackBar(SnackBar(content: Text(ack)));
    navigator.pop();
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final navigator = GoRouter.of(context);
    await ref.read(caseRepositoryProvider).closeCase(userCase.id);
    ref.invalidate(casesListProvider);
    ref.invalidate(caseByIdProvider(userCase.id));
    navigator.pop();
  }

  Future<void> _continueChat(BuildContext context, WidgetRef ref) async {
    final navigator = GoRouter.of(context);
    await ref.read(activeCaseProvider.notifier).setActiveCase(userCase);
    // The legacy chat route requires a UUID caseId; if the new case
    // hasn't been linked to a chat session yet, we go back to the
    // home screen with the case active. The chat composer reads
    // activeCaseProvider and shows the badge regardless of route.
    navigator.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(userCase.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            key: const Key('case-edit-btn'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n?.edit ?? 'Edit',
            onPressed: () => context.push('/cases-v2/${userCase.id}/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'archive') {
                _archive(context, ref);
              } else if (v == 'close') {
                _close(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(l10n?.archiveCase ?? 'Archive case'),
              ),
              PopupMenuItem(
                value: 'close',
                child: Text(l10n?.closeCase ?? 'Close case'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Header(userCase: userCase),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            key: const Key('continue-chat-btn'),
            onPressed: () => _continueChat(context, ref),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              l10n?.continueChatAboutCase ?? 'Continue chat about this case',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (userCase.summary != null && userCase.summary!.isNotEmpty)
            _SectionCard(
              title: l10n?.summarySection ?? 'Summary',
              child: Text(
                userCase.summary!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          // Pkg 9 — inline section listing top deadlines for this case.
          // Tapping the section header navigates to the full screen.
          _CaseDeadlinesSection(caseId: userCase.id),
          _ListSection(
            title: l10n?.caseNumbersSection ?? 'Case numbers',
            items: userCase.caseNumbers
                .map((n) => '${n.authority} — ${n.number}'
                    '${n.role == null ? '' : ' (${n.role})'}')
                .toList(),
          ),
          _ListSection(
            title: l10n?.partiesSection ?? 'Parties',
            items: userCase.parties
                .map((p) => '${p.role}: ${p.name}'
                    '${p.note == null || p.note!.isEmpty ? '' : ' — ${p.note}'}')
                .toList(),
          ),
          _ListSection(
            title: 'Key dates',
            items: userCase.keyDates
                .map((d) => '${d.date} — ${d.label}'
                    '${d.note == null || d.note!.isEmpty ? '' : ' (${d.note})'}')
                .toList(),
          ),
          _ListSection(
            title: l10n?.authoritiesSection ?? 'Authorities',
            items: userCase.authorities
                .map((a) =>
                    '${a.name}${a.contact == null ? '' : ' — ${a.contact}'}')
                .toList(),
          ),
          _ListSection(
            title: l10n?.timelineSection ?? 'Timeline',
            items: userCase.timeline
                .map((t) => '${t.date} — ${t.event}')
                .toList(),
          ),
          _ListSection(
            title: l10n?.openQuestionsSection ?? 'Open questions',
            items: userCase.openQuestions
                .map((q) => '• ${q.question}'
                    '${q.priority == null ? '' : ' [${q.priority}]'}')
                .toList(),
          ),
          _ListSection(
            title: l10n?.nextActionsSection ?? 'Next actions',
            items: userCase.nextActions
                .map((a) =>
                    '→ ${a.action}${a.due == null ? '' : ' (due ${a.due})'}')
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.userCase});
  final UserCase userCase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _Tag(
                label: userCase.jurisdiction.toUpperCase(),
                color: AppColors.primary,
              ),
              if (userCase.caseType != null)
                _Tag(label: userCase.caseType!, color: AppColors.accent),
              _Tag(
                label: userCase.status.dbValue,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            userCase.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [Align(alignment: Alignment.centerLeft, child: child)],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: '$title (${items.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    s,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Pkg 9 — collapsed deadline section: top-3 active rows + a link to
/// the full per-case list. Hidden when no Pkg-9 deadlines exist.
class _CaseDeadlinesSection extends ConsumerWidget {
  const _CaseDeadlinesSection({required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(deadlinesProvider(caseId));
    return asyncList.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        final active = rows
            .where((d) => d.status == CaseDeadlineStatus.active)
            .take(3)
            .toList(growable: false);
        if (active.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.deadlineCaseScreenTitle ?? 'Deadlines',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      key: const Key('case-detail-view-deadlines'),
                      onPressed: () => GoRouter.of(context)
                          .push('/cases-v2/$caseId/deadlines'),
                      child: Text(
                        l10n?.deadlineRadarViewAll ?? 'View all',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ...active.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: DeadlineCard(
                      deadline: d,
                      mode: DeadlineCardMode.compact,
                      onTap: () => GoRouter.of(context)
                          .push('/cases-v2/$caseId/deadlines'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
