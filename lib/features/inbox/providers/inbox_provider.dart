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
import '../../../services/supabase_service.dart';
import '../models/inbox_severity.dart';
import '../models/inbox_thread.dart';

/// Aggregate result returned by [InboxNotifier.approveSelectedActions].
/// (sent, failed) drives the success-vs-partial-failure toast in
/// ParallelActionsCard. `failed == 0` ⇒ all OK; otherwise the UI keeps the
/// card visible so the user can retry the failed actions individually.
class ParallelApproveResult {
  const ParallelApproveResult({required this.sent, required this.failed});
  final int sent;
  final int failed;
}

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
  InboxNotifier(this._tools, {SupabaseService? supabase})
      : _supabase = supabase,
        super(InboxState.initial()) {
    // ignore: discarded_futures — fire-and-forget initial load
    refresh();
  }

  final AssistantTools _tools;

  /// Optional Supabase service for direct edge-function calls
  /// (approve_send_draft → `email-send`). Falls back to the assistant
  /// tools' wrapped service when not injected (test seam).
  final SupabaseService? _supabase;

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

  /// D6 — "Approve & Send" loop. Calls the `email-send` edge function
  /// with the persisted triage row, optionally swapping in the user's
  /// `editedBody` (the edit screen forwards the textarea contents
  /// verbatim).
  ///
  /// Returns an [ApproveAndSendResult] so the caller can render the
  /// success snackbar / error retry banner without re-implementing
  /// edge-function plumbing in the widget.
  Future<ApproveAndSendResult> approveAndSend(
    String triageId, {
    String? editedBody,
  }) async {
    final supabase = _supabase;
    if (supabase == null) {
      // Defence-in-depth: a misconfigured provider tree would otherwise
      // silently no-op; surface a structured error so the snackbar is
      // visible to the user (and to the widget tests).
      return const ApproveAndSendResult(
        success: false,
        errorCode: 'service_unavailable',
        errorMessage: 'Supabase service not wired into the inbox provider.',
      );
    }
    final body = <String, dynamic>{
      'triage_id': triageId,
      if (editedBody != null && editedBody.isNotEmpty) 'edited_body': editedBody,
    };
    final res = await supabase.callEdgeFunction('email-send', body: body);
    if (res == null) {
      // Demo mode — pretend success so the UI flow stays exercisable.
      return const ApproveAndSendResult(success: true, demo: true);
    }
    // Edge fn returns `{ ok: true, ... }` on success and `{ error, ... }`
    // (plus often error_code / reason) on failure.
    if (res['ok'] == true) {
      return ApproveAndSendResult(
        success: true,
        gmailMessageId: res['gmail_message_id'] as String?,
        sentAt: res['sent_at'] as String?,
        idempotent: res['idempotent'] == true,
      );
    }
    return ApproveAndSendResult(
      success: false,
      errorCode: (res['error_code'] as String?) ??
          (res['reason'] as String?) ??
          'send_failed',
      errorMessage:
          (res['error'] as String?) ?? 'Could not send the prepared reply.',
    );
  }

  /// Parallel Actions Panel (2026-05-25) — dispatch N selected actions for
  /// a single triage row in parallel. Each invocation of `email-send` is
  /// independent; one failure does NOT short-circuit the rest. The result
  /// rolls them up into (sent, failed) so the UI can render the right toast.
  ///
  /// Wire shape per call:
  ///   POST email-send  { triage_id, action_idx }
  ///
  /// `action_idx` defaults to 0 when omitted, which preserves the legacy
  /// single-draft contract used by [approveAndSend]. When the sibling
  /// "Approve&Send UI" agent's edge function lands, the only thing it
  /// needs to do is read `action_idx` and pick the matching row from
  /// `email_triage_results.proposed_actions` (idx 0 falls back to the
  /// legacy draft_* columns).
  Future<ParallelApproveResult> approveSelectedActions(
    String triageId,
    List<int> selectedIdxes,
  ) async {
    if (selectedIdxes.isEmpty) {
      return const ParallelApproveResult(sent: 0, failed: 0);
    }
    final supabase = _supabase;
    if (supabase == null) {
      // No service wired — defence-in-depth, mirrors approveAndSend's
      // service_unavailable branch but for the parallel case.
      return ParallelApproveResult(sent: 0, failed: selectedIdxes.length);
    }
    int sent = 0;
    int failed = 0;
    // Fan out in parallel via Future.wait so the user doesn't pay
    // serial-latency for N round-trips. Each request body carries the
    // same triage_id but a unique action_idx so the edge fn can pick
    // the right draft from `proposed_actions`.
    final futures = selectedIdxes.map((idx) async {
      try {
        final res = await supabase.callEdgeFunction(
          'email-send',
          body: <String, dynamic>{
            'triage_id': triageId,
            'action_idx': idx,
          },
        );
        if (res == null) {
          // Demo / offline — treat as success (mirrors approveAndSend).
          return true;
        }
        return res['ok'] == true;
      } catch (_) {
        return false;
      }
    }).toList(growable: false);
    final results = await Future.wait(futures);
    for (final ok in results) {
      if (ok) {
        sent += 1;
      } else {
        failed += 1;
      }
    }
    return ParallelApproveResult(sent: sent, failed: failed);
  }
}

/// Structured outcome of [InboxNotifier.approveAndSend].
class ApproveAndSendResult {
  const ApproveAndSendResult({
    required this.success,
    this.gmailMessageId,
    this.sentAt,
    this.idempotent = false,
    this.demo = false,
    this.errorCode,
    this.errorMessage,
  });

  final bool success;
  final String? gmailMessageId;
  final String? sentAt;
  final bool idempotent;
  final bool demo;
  final String? errorCode;
  final String? errorMessage;
}

/// Inbox provider — single source of truth for the Inbox screen, also
/// readable from the chat surface so a snooze in chat updates the screen
/// (and vice-versa).
final inboxProvider =
    StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final tools = ref.watch(assistantToolsProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return InboxNotifier(tools, supabase: supabase);
});
