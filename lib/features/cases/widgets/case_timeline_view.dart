// ---------------------------------------------------------------------------
// Case Timeline View — vertical timeline of `case_timeline_events`.
//
// Visual layout:
//   ┌─────────────────────────────────────────────────────────┐
//   │ [All] [Emails] [Consilium] [Deadlines] [Notes]          │  filter row
//   ├─────────────────────────────────────────────────────────┤
//   │  ●─┐                                                    │
//   │    └─ icon  card { title · summary · "3 hours ago" }    │
//   │  │                                                      │
//   │  ●─┐                                                    │
//   │    └─ icon  card                                        │
//   │  ▼ tap expands → JSON payload viewer                    │
//   └─────────────────────────────────────────────────────────┘
//
// Pull-to-refresh re-runs the first page; on-scroll-to-bottom triggers
// loadMore() until the notifier reports `hasMore=false`.
// ---------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/date_utils.dart';
import '../models/case_timeline_event.dart';
import '../providers/case_timeline_provider.dart';

class CaseTimelineView extends ConsumerStatefulWidget {
  const CaseTimelineView({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseTimelineView> createState() => _CaseTimelineViewState();
}

class _CaseTimelineViewState extends ConsumerState<CaseTimelineView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // 200px from bottom — trigger before the user hits the visual end.
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(caseTimelineProvider(widget.caseId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stateAsync = ref.watch(caseTimelineProvider(widget.caseId));
    final filter = ref.watch(caseTimelineFilterProvider(widget.caseId));

    return Column(
      key: const Key('case-timeline-view'),
      children: [
        _FilterRow(
          caseId: widget.caseId,
          current: filter,
          l10n: l10n,
        ),
        Expanded(
          child: stateAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(
              caseId: widget.caseId,
              l10n: l10n,
            ),
            data: (state) {
              final filtered =
                  state.events.where(filter.accepts).toList(growable: false);
              if (filtered.isEmpty) {
                return _EmptyState(filter: filter, l10n: l10n);
              }
              return RefreshIndicator(
                onRefresh: () => ref
                    .read(caseTimelineProvider(widget.caseId).notifier)
                    .refresh(),
                child: ListView.builder(
                  key: const Key('case-timeline-list'),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  // +1 for the bottom loader, only when more pages remain.
                  itemCount: filtered.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= filtered.length) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: state.isLoadingMore
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const SizedBox.shrink(),
                        ),
                      );
                    }
                    final event = filtered[index];
                    final isLast = index == filtered.length - 1 &&
                        !state.hasMore;
                    return _TimelineEventTile(
                      event: event,
                      isLast: isLast,
                      l10n: l10n,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter row
// ---------------------------------------------------------------------------

class _FilterRow extends ConsumerWidget {
  const _FilterRow({
    required this.caseId,
    required this.current,
    required this.l10n,
  });

  final String caseId;
  final CaseTimelineFilter current;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = <(CaseTimelineFilter, String)>[
      (CaseTimelineFilter.all, l10n.timelineFilterAll),
      (CaseTimelineFilter.emails, l10n.timelineFilterEmails),
      (CaseTimelineFilter.consilium, l10n.timelineFilterConsilium),
      (CaseTimelineFilter.deadlines, l10n.timelineFilterDeadlines),
      (CaseTimelineFilter.notes, l10n.timelineFilterNotes),
    ];

    return Padding(
      key: const Key('case-timeline-filter-row'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final opt in options) ...[
              ChoiceChip(
                key: Key('case-timeline-filter-${opt.$1.name}'),
                label: Text(opt.$2),
                selected: current == opt.$1,
                onSelected: (_) => ref
                    .read(caseTimelineFilterProvider(caseId).notifier)
                    .state = opt.$1,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / Error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.l10n});

  final CaseTimelineFilter filter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('case-timeline-empty'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              filter == CaseTimelineFilter.all
                  ? l10n.noEventsYet
                  : l10n.noEventsForFilter,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.activityWillAppear,
              style: const TextStyle(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.caseId, required this.l10n});

  final String caseId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      key: const Key('case-timeline-error'),
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
                ref.read(caseTimelineProvider(caseId).notifier).refresh(),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event tile
// ---------------------------------------------------------------------------

class _TimelineEventTile extends StatefulWidget {
  const _TimelineEventTile({
    required this.event,
    required this.isLast,
    required this.l10n,
  });

  final CaseTimelineEvent event;
  final bool isLast;
  final AppLocalizations l10n;

  @override
  State<_TimelineEventTile> createState() => _TimelineEventTileState();
}

class _TimelineEventTileState extends State<_TimelineEventTile> {
  bool _isExpanded = false;

  Color get _eventColor => switch (widget.event.type) {
        CaseTimelineEventType.emailIn => AppColors.primaryLight,
        CaseTimelineEventType.emailOut => AppColors.primary,
        CaseTimelineEventType.consiliumDecision => AppColors.info,
        CaseTimelineEventType.deadlineSet => AppColors.warning,
        CaseTimelineEventType.docUploaded => AppColors.accent,
        CaseTimelineEventType.phaseChange => AppColors.accentDark,
        CaseTimelineEventType.manualNote => AppColors.textSecondary,
      };

  IconData get _eventIcon => switch (widget.event.type) {
        CaseTimelineEventType.emailIn => Icons.mail_outline,
        CaseTimelineEventType.emailOut => Icons.send_outlined,
        CaseTimelineEventType.consiliumDecision => Icons.psychology_outlined,
        CaseTimelineEventType.deadlineSet => Icons.schedule,
        CaseTimelineEventType.docUploaded => Icons.upload_file,
        CaseTimelineEventType.phaseChange => Icons.sync_alt,
        CaseTimelineEventType.manualNote => Icons.sticky_note_2_outlined,
      };

  String _typeLabel(AppLocalizations l10n) => switch (widget.event.type) {
        CaseTimelineEventType.emailIn => l10n.timelineEventEmailIn,
        CaseTimelineEventType.emailOut => l10n.timelineEventEmailOut,
        CaseTimelineEventType.consiliumDecision =>
          l10n.timelineEventConsiliumDecision,
        CaseTimelineEventType.deadlineSet => l10n.timelineEventDeadlineSet,
        CaseTimelineEventType.docUploaded => l10n.timelineEventDocUploaded,
        CaseTimelineEventType.phaseChange => l10n.timelineEventPhaseChange,
        CaseTimelineEventType.manualNote => l10n.timelineEventManualNote,
      };

  /// Localised "X ago" string. Falls back to absolute date when older
  /// than 30 days.
  String _relativeTime(DateTime when, AppLocalizations l10n) {
    final diff = DateTime.now().difference(when);
    if (diff.isNegative) return AppDateUtils.formatDateTime(when);
    if (diff.inMinutes < 1) return l10n.timelineJustNow;
    if (diff.inHours < 1) {
      return l10n.timelineMinutesAgo(diff.inMinutes);
    }
    if (diff.inDays < 1) return l10n.timelineHoursAgo(diff.inHours);
    if (diff.inDays < 30) return l10n.timelineDaysAgo(diff.inDays);
    return AppDateUtils.formatDate(when);
  }

  @override
  Widget build(BuildContext context) {
    final color = _eventColor;
    final l10n = widget.l10n;
    final hasSummary =
        widget.event.summary != null && widget.event.summary!.isNotEmpty;
    final hasPayload = widget.event.payload.isNotEmpty;
    final isExpandable = hasSummary || hasPayload;

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
              key: Key('case-timeline-tile-${widget.event.id}'),
              onTap: isExpandable
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _typeLabel(l10n),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isExpandable)
                          Icon(
                            _isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(widget.event.occurredAt, l10n),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    if (hasSummary && _isExpanded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.event.summary!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (hasPayload && _isExpanded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _PayloadView(payload: widget.event.payload),
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

class _PayloadView extends StatelessWidget {
  const _PayloadView({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    // Render the payload as pretty JSON. Pre-format outside the
    // SelectableText so the encoder runs once per state change.
    const encoder = JsonEncoder.withIndent('  ');
    String pretty;
    try {
      pretty = encoder.convert(payload);
    } catch (_) {
      pretty = payload.toString();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SelectableText(
        pretty,
        key: const Key('case-timeline-payload'),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.35,
        ),
      ),
    );
  }
}
