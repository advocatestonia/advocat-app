// =====================================================================
// Phase 2 Pkg 4 — Overview tab.
//
// Auto-generated case dashboard:
//   * Title + jurisdiction + status badges
//   * Free-text summary (when present)
//   * Last 5 timeline events
//   * Top active deadline (when present)
//   * Empty state when there's nothing to show
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../case_memory/models/case_deadline.dart';
import '../../case_memory/models/user_case.dart';
import '../../case_memory/state/case_deadline_providers.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key, required this.userCase});

  final UserCase userCase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deadlinesAsync = ref.watch(deadlinesProvider(userCase.id));

    final hasSummary =
        userCase.summary != null && userCase.summary!.trim().isNotEmpty;
    final hasTimeline = userCase.timeline.isNotEmpty;
    final hasContent = hasSummary || hasTimeline;

    if (!hasContent) {
      return _EmptyState(
        message: l10n?.workspaceOverviewEmpty ??
            'Add documents to build a summary.',
      );
    }

    return ListView(
      key: const Key('workspace-overview-tab'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _Header(userCase: userCase),
        const SizedBox(height: AppSpacing.md),
        if (hasSummary)
          _SectionCard(
            title: l10n?.summarySection ?? 'Summary',
            child: Text(
              userCase.summary!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        deadlinesAsync.maybeWhen(
          data: (list) => _topActive(list) == null
              ? const SizedBox.shrink()
              : _TopDeadlineSection(deadline: _topActive(list)!),
          orElse: () => const SizedBox.shrink(),
        ),
        if (hasTimeline)
          _SectionCard(
            title: l10n?.timelineSection ?? 'Timeline',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in userCase.timeline.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${t.date} — ${t.event}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  CaseDeadline? _topActive(List<CaseDeadline> list) {
    final active = list
        .where((d) => d.status == CaseDeadlineStatus.active)
        .toList(growable: false);
    if (active.isEmpty) return null;
    final sorted = [...active]
      ..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));
    return sorted.first;
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _TopDeadlineSection extends StatelessWidget {
  const _TopDeadlineSection({required this.deadline});
  final CaseDeadline deadline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final delta = deadline.deadlineAt.difference(DateTime.now()).inDays;
    final urgent = delta <= 7;
    return _SectionCard(
      title: l10n?.deadlineCaseScreenTitle ?? 'Top deadline',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: urgent
              ? AppColors.error.withValues(alpha: 0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              urgent ? Icons.warning_amber_rounded : Icons.event_note_outlined,
              size: 18,
              color: urgent ? AppColors.error : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                deadline.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: urgent ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('workspace-overview-empty'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dashboard_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
