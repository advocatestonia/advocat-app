// ---------------------------------------------------------------------------
// Case Timeline Provider — DB-backed Riverpod state for the per-case
// timeline view.
//
// Sources rows from `case_timeline_events` (migration
// 20260525154500_case_timeline_events.sql) via SupabaseService. The
// notifier is family-keyed on caseId so each case has an independent
// pagination cursor.
//
// Loading state contract:
//   - First read: `AsyncLoading` until the first page resolves.
//   - Pagination: `loadMore()` is a no-op when already loading or when
//     the previous page returned fewer than [pageSize] rows
//     (`hasMore=false`). Subsequent pages append to the existing list
//     and re-emit `AsyncData` — no flicker.
//   - Refresh: `refresh()` resets the cursor and rebuilds from page 0;
//     drives pull-to-refresh in the UI.
//
// `appendManualNote()` is a passthrough to the service + local
// optimistic prepend so the new note appears immediately at the top of
// the timeline.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../models/case_timeline_event.dart';

/// Page size for cursor-based pagination. Matches the default in
/// SupabaseService.getCaseTimelineEvents.
const int kCaseTimelinePageSize = 50;

/// Snapshot of the timeline for a single case.
class CaseTimelineState {
  const CaseTimelineState({
    required this.events,
    required this.hasMore,
    required this.isLoadingMore,
  });

  /// Empty state — used as the seed before the first fetch.
  const CaseTimelineState.empty()
      : events = const [],
        hasMore = true,
        isLoadingMore = false;

  final List<CaseTimelineEvent> events;
  final bool hasMore;
  final bool isLoadingMore;

  CaseTimelineState copyWith({
    List<CaseTimelineEvent>? events,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      CaseTimelineState(
        events: events ?? this.events,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// Riverpod family — one notifier per caseId.
final caseTimelineProvider = AsyncNotifierProvider.family<
    CaseTimelineNotifier, CaseTimelineState, String>(
  CaseTimelineNotifier.new,
);

class CaseTimelineNotifier
    extends FamilyAsyncNotifier<CaseTimelineState, String> {
  SupabaseService get _supabase => ref.read(supabaseServiceProvider);

  @override
  Future<CaseTimelineState> build(String caseId) async {
    return _fetchPage(caseId: caseId, beforeOccurredAt: null);
  }

  /// Pull-to-refresh — re-run the initial fetch and replace state.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(
          caseId: arg,
          beforeOccurredAt: null,
        ));
  }

  /// Load the next page (older events). No-op if loading or `hasMore=false`.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    if (!current.hasMore || current.isLoadingMore) return;
    if (current.events.isEmpty) return;

    // Optimistic: mark loading so the UI can show a spinner without
    // dropping the existing rows.
    state = AsyncData(current.copyWith(isLoadingMore: true));

    final cursor = current.events.last.occurredAt;
    try {
      final next = await _supabase.getCaseTimelineEvents(
        caseId: arg,
        pageSize: kCaseTimelinePageSize,
        beforeOccurredAt: cursor,
      );
      state = AsyncData(CaseTimelineState(
        events: [...current.events, ...next],
        hasMore: next.length >= kCaseTimelinePageSize,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      // Restore prior state + bubble error via AsyncError. The UI will
      // show a retry control without losing already-loaded rows.
      state = AsyncValue<CaseTimelineState>.error(e, st)
          .copyWithPrevious(AsyncData(current));
    }
  }

  /// Append a manual note. Optimistic — prepends locally on success.
  /// Returns the new event_id (or null in demo mode).
  Future<String?> appendManualNote({
    required String title,
    String? summary,
  }) async {
    final id = await _supabase.appendManualNote(
      caseId: arg,
      title: title,
      summary: summary,
    );
    // Force a refresh so the new event lands with the canonical
    // occurred_at server timestamp (avoids drift if the local clock
    // disagrees with the DB).
    await refresh();
    return id;
  }

  /// Delete a manual note. Optimistic local removal + server delete.
  Future<void> deleteManualNote(String eventId) async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(
        events:
            current.events.where((e) => e.id != eventId).toList(growable: false),
      ));
    }
    try {
      await _supabase.deleteManualNote(eventId);
    } catch (_) {
      // On failure, refresh to recover the canonical row.
      await refresh();
    }
  }

  Future<CaseTimelineState> _fetchPage({
    required String caseId,
    DateTime? beforeOccurredAt,
  }) async {
    final page = await _supabase.getCaseTimelineEvents(
      caseId: caseId,
      pageSize: kCaseTimelinePageSize,
      beforeOccurredAt: beforeOccurredAt,
    );
    return CaseTimelineState(
      events: page,
      hasMore: page.length >= kCaseTimelinePageSize,
      isLoadingMore: false,
    );
  }
}

/// Filter chip state — single-selection. Lives outside the family
/// notifier so it survives provider rebuilds when refresh fires.
final caseTimelineFilterProvider =
    StateProvider.family<CaseTimelineFilter, String>(
  (ref, caseId) => CaseTimelineFilter.all,
);
