// inbox_thread.dart
// -----------------------------------------------------------------------------
// View model for a single triaged email thread surfaced in the Inbox UI.
//
// Mirrors the column shape of email_triage_results JOIN email_threads exactly
// so the same Map<String, dynamic> can travel through:
//   - the chat assistant tools (list_inbox / get_thread_triage),
//   - the inbox provider (Riverpod),
//   - the triage_card widget.
//
// One factory each:
//   * fromTriageRow(...) — when the row is the JOIN result from Supabase.
//   * fromAssistantTool(...) — when the row arrived via assistant_tools.dart
//                              demo / list_inbox card data.
//
// Both factories tolerate missing keys (null-safe casts + sensible defaults)
// so the UI never crashes on partial data — the email-triage edge fn writes
// most fields but not all (e.g. draft_* are absent for posture=no_reply).
// -----------------------------------------------------------------------------

import 'inbox_severity.dart';

/// Single deadline surfaced from `email_triage_results.deadlines` jsonb.
///
/// Mirrors the shape produced by `parse_blocks.ts::DeadlineEntry`:
///   { iso_date: string, delta_days: int|null, description: string }
class InboxDeadline {
  const InboxDeadline({
    required this.isoDate,
    required this.deltaDays,
    required this.description,
  });

  /// ISO-8601 calendar date (YYYY-MM-DD) — empty when the model only had
  /// a relative-day estimate.
  final String isoDate;

  /// Calendar-day delta from "today" (per the triage run's CURRENT_DATE).
  /// Negative = overdue. Null when the model could not compute it.
  final int? deltaDays;

  /// Free-text label, e.g. "appeal window 14 days".
  final String description;

  factory InboxDeadline.fromJson(Map<String, dynamic> json) {
    final raw = json['delta_days'];
    int? delta;
    if (raw is int) {
      delta = raw;
    } else if (raw is num) {
      delta = raw.toInt();
    } else if (raw is String) {
      delta = int.tryParse(raw);
    }
    return InboxDeadline(
      isoDate: (json['iso_date'] as String?) ?? '',
      deltaDays: delta,
      description: (json['description'] as String?) ?? '',
    );
  }
}

/// Parallel Actions Panel (2026-05-25) — one structured action proposed by
/// the consilium synthesis. Mirrors `_shared/parallel_actions.ts::ProposedAction`
/// and the JSONB shape persisted to `email_triage_results.proposed_actions`.
///
/// When the consilium recommends 2+ related actions (e.g. one Jokela reply +
/// one asiakirjapyyntö to poliisi kirjaamo), the inbox surfaces them as a
/// grouped ParallelActionsCard with batch-approve. idx=0 always mirrors the
/// legacy `draft_*` columns so single-draft consumers keep working.
class ProposedAction {
  const ProposedAction({
    required this.idx,
    required this.kind,
    required this.toAddr,
    required this.cc,
    required this.subject,
    required this.body,
    required this.language,
    required this.citations,
    required this.rationale,
  });

  /// 0..N-1, stable ordering. Persistence + UI selection both rely on it.
  final int idx;

  /// "email_reply" | "email_new" — drives the icon + chip in the card.
  final String kind;

  /// Primary recipient address shown in the mini-preview.
  final String toAddr;

  /// Optional Cc list. Often empty.
  final List<String> cc;

  /// Subject line — for replies the consilium may emit "Re: …".
  final String subject;

  /// Plaintext body — the only format `send-email` accepts today.
  final String body;

  /// ISO language code, e.g. "fi", "et", "ru", "en".
  final String language;

  /// `[[ref:slug:para]]` markers preserved verbatim.
  final List<String> citations;

  /// 1-2 sentence "why this action" shown above the body preview.
  final String rationale;

  factory ProposedAction.fromJson(Map<String, dynamic> json) {
    int parseIdx(Object? raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    }

    List<String> parseStringList(Object? raw) {
      if (raw is List) {
        return raw
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false);
      }
      return const <String>[];
    }

    return ProposedAction(
      idx: parseIdx(json['idx']),
      kind: (json['kind'] as String?) ?? 'email_reply',
      toAddr: (json['to_addr'] as String?) ?? '',
      cc: parseStringList(json['cc']),
      subject: (json['subject'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      language: (json['language'] as String?) ?? 'en',
      citations: parseStringList(json['citations']),
      rationale: (json['rationale'] as String?) ?? '',
    );
  }
}

class InboxThread {
  const InboxThread({
    required this.threadId,
    required this.triageId,
    required this.subject,
    required this.senderEmail,
    required this.severity,
    required this.userBrief,
    required this.lastMessageAt,
    required this.hasDraft,
    required this.sendRecommendation,
    required this.userAction,
    required this.seenByUserAt,
    this.deadlines = const <InboxDeadline>[],
    this.caseId,
    this.proposedActions = const <ProposedAction>[],
  });

  /// `email_threads.id` (uuid).
  final String threadId;

  /// `email_triage_results.id` (uuid). Required by approve_send_draft +
  /// snooze chat tools.
  final String triageId;

  /// `email_threads.subject`.
  final String subject;

  /// First message's sender_email — what the user recognises a thread by.
  final String senderEmail;

  /// `email_triage_results.severity` enum.
  final InboxSeverity severity;

  /// `email_triage_results.user_brief` — 2-4 sentence Sonnet briefing.
  final String userBrief;

  /// `email_threads.last_message_at`. Used for the secondary sort within a
  /// severity bucket (newer first).
  final DateTime lastMessageAt;

  /// True iff `email_triage_results.draft_body` is non-null. Drives whether
  /// the "Edit / Approve & send" actions are shown.
  final bool hasDraft;

  /// `email_triage_results.send_recommendation`:
  /// auto_send_eligible | hold_for_user_review | archive.
  final String sendRecommendation;

  /// `email_triage_results.user_action`: sent | edited | rejected | snoozed.
  /// `null` when the user has not acted yet.
  final String? userAction;

  /// `email_triage_results.seen_by_user_at`. Used for the 24h snooze hide
  /// window; null means "never seen".
  final DateTime? seenByUserAt;

  /// Parsed deadlines from `email_triage_results.deadlines`. Empty list
  /// when the triage produced none (or the row was loaded from a thinner
  /// projection like the assistant tool's card data).
  final List<InboxDeadline> deadlines;

  /// Optional `case_id` linking this thread to a `user_cases` row. Set
  /// when the email triage agent has carried this thread into a case
  /// dossier; `null` for unattributed inbox traffic. Pkg 4 uses this
  /// to filter the per-case inbox tab.
  final String? caseId;

  /// The single most-urgent deadline (smallest non-null deltaDays, with
  /// negative/overdue values winning). Returns `null` when the thread has
  /// no deadlines.
  InboxDeadline? get topDeadline {
    if (deadlines.isEmpty) return null;
    InboxDeadline? best;
    for (final d in deadlines) {
      if (best == null) {
        best = d;
        continue;
      }
      final a = d.deltaDays;
      final b = best.deltaDays;
      if (a == null && b == null) continue;
      if (a == null) continue;
      if (b == null) {
        best = d;
        continue;
      }
      if (a < b) best = d;
    }
    return best;
  }

  /// True iff this thread was snoozed within the last 24h and should be
  /// hidden from the inbox list. Mirrors the same filter used by the
  /// chat-side `list_inbox` tool.
  bool isSnoozeHidden(DateTime now) {
    if (userAction != 'snoozed') return false;
    final at = seenByUserAt;
    if (at == null) return false;
    final cutoff = now.subtract(const Duration(hours: 24));
    return at.isAfter(cutoff);
  }

  /// Parallel Actions Panel (2026-05-25) — N>=0 structured actions the
  /// consilium proposed. When `length >= 2` the inbox renders a grouped
  /// ParallelActionsCard; otherwise the legacy single-draft TriageCard
  /// fallback fires. Empty for threads that never went through consilium
  /// (`email_triage_results.proposed_actions IS NULL`) or for single-draft
  /// rows where the column was deliberately left NULL.
  final List<ProposedAction> proposedActions;

  /// True iff the inbox should switch to the ParallelActionsCard. Single
  /// source of truth so the inbox screen + tests agree.
  bool get hasParallelActions => proposedActions.length >= 2;

  factory InboxThread.fromAssistantTool(Map<String, dynamic> row) {
    final lastIso = row['last_message_at'] as String?;
    final seenIso = row['seen_by_user_at'] as String?;
    final rawDeadlines = row['deadlines'];
    final parsedDeadlines = <InboxDeadline>[];
    if (rawDeadlines is List) {
      for (final d in rawDeadlines) {
        if (d is Map<String, dynamic>) {
          parsedDeadlines.add(InboxDeadline.fromJson(d));
        } else if (d is Map) {
          parsedDeadlines
              .add(InboxDeadline.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }
    final rawActions = row['proposed_actions'];
    final parsedActions = <ProposedAction>[];
    if (rawActions is List) {
      for (final a in rawActions) {
        if (a is Map<String, dynamic>) {
          parsedActions.add(ProposedAction.fromJson(a));
        } else if (a is Map) {
          parsedActions
              .add(ProposedAction.fromJson(Map<String, dynamic>.from(a)));
        }
      }
      // Stable ordering — persistence guarantees idx 0..N-1 but defend
      // against any consumer that re-orders the JSONB array.
      parsedActions.sort((a, b) => a.idx.compareTo(b.idx));
    }
    return InboxThread(
      threadId: (row['thread_id'] as String?) ?? '',
      triageId: (row['triage_id'] as String?) ?? '',
      subject: (row['subject'] as String?) ?? '',
      senderEmail: (row['sender_email'] as String?) ?? '',
      severity:
          InboxSeverityX.parse(row['severity'] as String?) ?? InboxSeverity.low,
      userBrief: (row['user_brief'] as String?) ?? '',
      lastMessageAt:
          (lastIso != null ? DateTime.tryParse(lastIso) : null) ?? DateTime.now(),
      hasDraft: row['has_draft'] == true,
      sendRecommendation:
          (row['send_recommendation'] as String?) ?? 'hold_for_user_review',
      userAction: row['user_action'] as String?,
      seenByUserAt: seenIso != null ? DateTime.tryParse(seenIso) : null,
      deadlines: parsedDeadlines,
      caseId: row['case_id'] as String?,
      proposedActions: parsedActions,
    );
  }
}
