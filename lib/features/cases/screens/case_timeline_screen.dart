import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/date_utils.dart';
import '../providers/cases_provider.dart';

// ---------------------------------------------------------------------------
// Case Timeline Screen — Full vertical timeline with expandable events
// ---------------------------------------------------------------------------

/// The types of events that can appear on the timeline.
enum TimelineEventType {
  documentUploaded,
  aiAnalysis,
  emailSent,
  emailReceived,
  deadlineSet,
  draftGenerated,
  caseCreated,
  statusChanged,
}

/// A single event on the case timeline.
class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.date,
  });

  final String id;
  final TimelineEventType type;
  final String title;
  final String? description;
  final DateTime date;
}

/// Provider for timeline events of a given case.
/// Currently generates placeholder events from the case data.
/// In production, this would fetch from a dedicated `timeline_events` table.
final caseTimelineProvider =
    FutureProvider.family<List<TimelineEvent>, String>((ref, caseId) async {
  final legalCase = await ref.watch(caseByIdProvider(caseId).future);

  final events = <TimelineEvent>[
    TimelineEvent(
      id: '${caseId}_created',
      type: TimelineEventType.caseCreated,
      title: 'Case created',
      description: 'Case "${legalCase.title}" was created.',
      date: legalCase.createdAt,
    ),
  ];

  if (legalCase.decisionDate != null) {
    events.add(TimelineEvent(
      id: '${caseId}_decision',
      type: TimelineEventType.statusChanged,
      title: 'Decision received',
      description: 'An official decision was received for this case.',
      date: legalCase.decisionDate!,
    ));
  }

  if (legalCase.appealDeadline != null) {
    events.add(TimelineEvent(
      id: '${caseId}_appeal_deadline',
      type: TimelineEventType.deadlineSet,
      title: 'Appeal deadline set',
      description:
          'Appeal must be filed by ${AppDateUtils.formatDate(legalCase.appealDeadline!)}.',
      date: legalCase.appealDeadline!,
    ));
  }

  if (legalCase.hearingDate != null) {
    events.add(TimelineEvent(
      id: '${caseId}_hearing',
      type: TimelineEventType.deadlineSet,
      title: 'Hearing scheduled',
      description:
          'Court hearing scheduled for ${AppDateUtils.formatDate(legalCase.hearingDate!)}.',
      date: legalCase.hearingDate!,
    ));
  }

  if (legalCase.updatedAt != null &&
      legalCase.updatedAt != legalCase.createdAt) {
    events.add(TimelineEvent(
      id: '${caseId}_updated',
      type: TimelineEventType.statusChanged,
      title: 'Case updated',
      description: 'Case information was last updated.',
      date: legalCase.updatedAt!,
    ));
  }

  // Sort newest first
  events.sort((a, b) => b.date.compareTo(a.date));
  return events;
});

class CaseTimelineScreen extends ConsumerWidget {
  const CaseTimelineScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(caseTimelineProvider(caseId));

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.caseTimeline)),
      body: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.couldNotLoadTimeline,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () =>
                    ref.invalidate(caseTimelineProvider(caseId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timeline, size: 56, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.noEventsYet,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.activityWillAppear,
                    style: const TextStyle(color: AppColors.textTertiary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              return _TimelineEventTile(
                event: event,
                isLast: isLast,
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Event Tile
// ---------------------------------------------------------------------------

class _TimelineEventTile extends StatefulWidget {
  const _TimelineEventTile({
    required this.event,
    this.isLast = false,
  });

  final TimelineEvent event;
  final bool isLast;

  @override
  State<_TimelineEventTile> createState() => _TimelineEventTileState();
}

class _TimelineEventTileState extends State<_TimelineEventTile> {
  bool _isExpanded = false;

  Color get _eventColor => switch (widget.event.type) {
        TimelineEventType.documentUploaded => AppColors.accent,
        TimelineEventType.aiAnalysis => AppColors.info,
        TimelineEventType.emailSent => AppColors.primary,
        TimelineEventType.emailReceived => AppColors.primaryLight,
        TimelineEventType.deadlineSet => AppColors.warning,
        TimelineEventType.draftGenerated => AppColors.accentDark,
        TimelineEventType.caseCreated => AppColors.success,
        TimelineEventType.statusChanged => AppColors.textSecondary,
      };

  IconData get _eventIcon => switch (widget.event.type) {
        TimelineEventType.documentUploaded => Icons.upload_file,
        TimelineEventType.aiAnalysis => Icons.psychology_outlined,
        TimelineEventType.emailSent => Icons.send_outlined,
        TimelineEventType.emailReceived => Icons.mail_outlined,
        TimelineEventType.deadlineSet => Icons.schedule,
        TimelineEventType.draftGenerated => Icons.description_outlined,
        TimelineEventType.caseCreated => Icons.add_circle_outline,
        TimelineEventType.statusChanged => Icons.sync_alt,
      };

  @override
  Widget build(BuildContext context) {
    final color = _eventColor;
    final hasDescription =
        widget.event.description != null && widget.event.description!.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline rail ──────────────────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_eventIcon, size: 18, color: color),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // ── Event content ──────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: hasDescription
                  ? () => setState(() => _isExpanded = !_isExpanded)
                  : null,
              child: Container(
                margin: EdgeInsets.only(
                  bottom: widget.isLast ? 0 : AppSpacing.md,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (hasDescription)
                          Icon(
                            _isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.formatDateTime(widget.event.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    if (hasDescription && _isExpanded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.event.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
