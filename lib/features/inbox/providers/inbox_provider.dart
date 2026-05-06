// inbox_provider.dart
// -----------------------------------------------------------------------------
// Riverpod state for the Inbox feature (D6).
//
// Responsibilities:
//   - Load triaged threads via the chat-side `list_inbox` tool (which
//     already does the severity sort + 24h-snooze filter), so the inbox
//     UI and the chat assistant see exactly the same state.
//   - Expose the thread list as InboxState (loading / data / error).
//   - Surface action mutators (snooze / approve_send / archive) so the
//     widgets stay dumb: they call `ref.read(inboxProvider.notifier).snooze(...)`
//     and the notifier handles persistence + optimistic refresh.
//
// We deliberately bridge through AssistantTools rather than re-implementing
// the Supabase query: the chat assistant tool is the contract surface for
// the email-triage state. Two read paths would drift over time; one path
// keeps drift to zero.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/assistant_tools.dart';
import '../models/inbox_severity.dart';
import '../models/inbox_thread.dart';

/// Inbox UI state. Immutable — copyWith for changes.
class InboxState {
  const InboxState({
    required this.threads,
    required this.severityFilter,
    required this.isLoading,
    required this.errorMessage,
  });

  factory InboxState.initial() => const InboxState(
        threads: <InboxThread>[],
        severityFilter: null,
        isLoading: true,
        errorMessage: null,
      );

  /// Severity-sorted threads, snoozed-within-24h already filtered out.
  final List<InboxThread> threads;

  /// Optional filter — when set, only threads of this severity are shown.
  final InboxSeverity? severityFilter;

  final bool isLoading;
  final String? errorMessage;

  InboxState copyWith({
    List<InboxThread>? threads,
    InboxSeverity? severityFilter,
    bool clearSeverityFilter = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InboxState(
      threads: threads ?? this.threads,
      severityFilter: clearSeverityFilter
          ? null
          : (severityFilter ?? this.severityFilter),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Inbox notifier. Fans out to the assistant tool layer for I/O so the
/// chat and the dedicated inbox UI agree on what is "in the inbox".
class InboxNotifier extends StateNotifier<InboxState> {
  InboxNotifier(this._tools) : super(InboxState.initial()) {
    // ignore: discarded_futures — fire-and-forget initial load
    refresh();
  }

  final AssistantTools _tools;

  /// Re-load threads from the assistant tool layer.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{};
      if (state.severityFilter != null) {
        params['severity'] = state.severityFilter!.raw;
      }
      final res = await _tools.execute('list_inbox', params);
      if (!res.success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.displayText,
        );
        return;
      }
      final raw =
          (res.data?['threads'] as List? ?? const <dynamic>[]).cast<Object?>();
      final parsed = <InboxThread>[];
      for (final r in raw) {
        if (r is Map<String, dynamic>) {
          parsed.add(InboxThread.fromAssistantTool(r));
        } else if (r is Map) {
          parsed.add(InboxThread.fromAssistantTool(
              Map<String, dynamic>.from(r)));
        }
      }
      // Defence in depth: re-apply the snooze filter even if list_inbox
      // already did it. Keeps the UI honest if the tool layer ever drifts.
      final now = DateTime.now().toUtc();
      final visible =
          parsed.where((t) => !t.isSnoozeHidden(now)).toList(growable: false);
      state = state.copyWith(
        threads: visible,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load inbox: $e',
      );
    }
  }

  /// Apply or clear the severity filter and refresh.
  Future<void> setSeverityFilter(InboxSeverity? severity) async {
    state = state.copyWith(
      severityFilter: severity,
      clearSeverityFilter: severity == null,
    );
    await refresh();
  }

  /// Mark a thread snoozed via the chat-side `snooze_thread` tool. Hides
  /// the row immediately for snappy UI; the cron + edge fn write happens
  /// inside the tool.
  Future<void> snooze(String threadId) async {
    // Optimistic remove — UI hides the row immediately.
    state = state.copyWith(
      threads:
          state.threads.where((t) => t.threadId != threadId).toList(),
    );
    await _tools.execute('snooze_thread', {'thread_id': threadId});
  }

  /// Optimistically remove an archived row. Caller is responsible for
  /// the actual archive write (Edge fn / Gmail label) — the inbox UI
  /// just hides the card so the user sees instant feedback.
  void hideAfterAction(String threadId) {
    state = state.copyWith(
      threads:
          state.threads.where((t) => t.threadId != threadId).toList(),
    );
  }
}

/// Inbox provider — single source of truth for the Inbox screen, also
/// readable from the chat surface so a snooze in chat updates the screen
/// (and vice-versa).
final inboxProvider =
    StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final tools = ref.watch(assistantToolsProvider);
  return InboxNotifier(tools);
});
