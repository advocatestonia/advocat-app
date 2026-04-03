import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/deadline.dart';
import '../../../shared/utils/date_utils.dart';
import '../providers/deadlines_provider.dart';

// ---------------------------------------------------------------------------
// Deadlines Screen
// ---------------------------------------------------------------------------

/// Segment filter for deadlines.
enum _DeadlineSegment { upcoming, overdue, completed }

final _deadlineSegmentProvider =
    StateProvider<_DeadlineSegment>((_) => _DeadlineSegment.upcoming);

class DeadlinesScreen extends ConsumerWidget {
  const DeadlinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final deadlinesAsync = ref.watch(allDeadlinesProvider);
    final segment = ref.watch(_deadlineSegmentProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.deadlines),
          ],
        ),
      ),
      body: Column(
        children: [
          // -- Segmented control --
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_DeadlineSegment>(
                segments: [
                  ButtonSegment(
                    value: _DeadlineSegment.upcoming,
                    label: Text(l10n.upcoming),
                  ),
                  ButtonSegment(
                    value: _DeadlineSegment.overdue,
                    label: Text(l10n.overdue),
                  ),
                  ButtonSegment(
                    value: _DeadlineSegment.completed,
                    label: Text(l10n.completed),
                  ),
                ],
                selected: {segment},
                onSelectionChanged: (sel) =>
                    ref.read(_deadlineSegmentProvider.notifier).state =
                        sel.first,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),

          // -- Deadlines list --
          Expanded(
            child: deadlinesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.couldNotLoadDeadlines,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(allDeadlinesProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (deadlines) {
                final filtered = _filter(deadlines, segment);

                if (filtered.isEmpty) {
                  return _EmptyDeadlines(segment: segment);
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(allDeadlinesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return _DeadlineCard(
                        deadline: filtered[index],
                        onMarkComplete: () {
                          ref
                              .read(allDeadlinesProvider.future)
                              .then((_) => ref.invalidate(allDeadlinesProvider));
                          // TODO: Call supabase to update deadline status
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Deadline> _filter(List<Deadline> deadlines, _DeadlineSegment segment) {
    final now = DateTime.now();
    return switch (segment) {
      _DeadlineSegment.upcoming => deadlines
          .where((d) =>
              d.status == DeadlineStatus.upcoming &&
              d.dueDate.isAfter(now))
          .toList(),
      _DeadlineSegment.overdue => deadlines
          .where((d) =>
              d.status == DeadlineStatus.overdue ||
              (d.status == DeadlineStatus.upcoming &&
                  d.dueDate.isBefore(now)))
          .toList(),
      _DeadlineSegment.completed => deadlines
          .where((d) => d.status == DeadlineStatus.completed)
          .toList(),
    };
  }
}

// ---------------------------------------------------------------------------
// Deadline Card
// ---------------------------------------------------------------------------

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({
    required this.deadline,
    required this.onMarkComplete,
  });

  final Deadline deadline;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = AppDateUtils.daysUntil(deadline.dueDate);
    final isOverdue = days < 0;
    final isCompleted = deadline.status == DeadlineStatus.completed;

    // Color coding: green >7d, amber 3-7d, red <3d
    final urgencyColor = isCompleted
        ? AppColors.textTertiary
        : isOverdue || days < 3
            ? AppColors.error
            : days <= 7
                ? AppColors.warning
                : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // -- Days remaining (big number) --
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCompleted)
                    Icon(Icons.check, color: urgencyColor, size: 28)
                  else ...[
                    Text(
                      isOverdue ? '${-days}' : '$days',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: urgencyColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOverdue ? l10n.daysLate : l10n.days,
                      style: TextStyle(
                        fontSize: 11,
                        color: urgencyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // -- Deadline info --
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deadline.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppDateUtils.formatDate(deadline.dueDate),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (deadline.sourceDocumentId != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.link,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.fromDocument,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // -- Mark complete --
            if (!isCompleted)
              IconButton(
                onPressed: onMarkComplete,
                tooltip: l10n.markComplete,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyDeadlines extends StatelessWidget {
  const _EmptyDeadlines({required this.segment});

  final _DeadlineSegment segment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, title, subtitle) = switch (segment) {
      _DeadlineSegment.upcoming => (
          Icons.event_available_outlined,
          l10n.noUpcomingDeadlines,
          l10n.allClearDeadlines,
        ),
      _DeadlineSegment.overdue => (
          Icons.check_circle_outline,
          l10n.nothingOverdue,
          l10n.greatJobDeadlines,
        ),
      _DeadlineSegment.completed => (
          Icons.history_outlined,
          l10n.noCompletedDeadlines,
          l10n.completedDeadlinesDesc,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.success),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
