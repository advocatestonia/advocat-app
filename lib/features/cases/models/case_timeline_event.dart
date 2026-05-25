// ---------------------------------------------------------------------------
// Case Timeline Event — DB-backed model for the client-facing timeline UI.
//
// Source table: `case_timeline_events` (migration
// 20260525154500_case_timeline_events.sql). Pipelines emit rows from:
//   - email-inbox-sync  → event_type 'email_in'
//   - send-email        → event_type 'email_out'
//   - email-triage      → event_type 'consilium_decision'
//   - deadline-extractor→ event_type 'deadline_set'
//   - case-auto-patch   → event_type 'phase_change'
//   - PDF upload flow   → event_type 'doc_uploaded'  (TODO — owner write path)
//   - User UI           → event_type 'manual_note'
// ---------------------------------------------------------------------------

import 'dart:convert';

/// All seven event_type values allowed by the DB CHECK constraint.
enum CaseTimelineEventType {
  emailIn,
  emailOut,
  consiliumDecision,
  deadlineSet,
  docUploaded,
  phaseChange,
  manualNote,
}

extension CaseTimelineEventTypeX on CaseTimelineEventType {
  /// snake_case form used by the DB enum.
  String get dbValue => switch (this) {
        CaseTimelineEventType.emailIn => 'email_in',
        CaseTimelineEventType.emailOut => 'email_out',
        CaseTimelineEventType.consiliumDecision => 'consilium_decision',
        CaseTimelineEventType.deadlineSet => 'deadline_set',
        CaseTimelineEventType.docUploaded => 'doc_uploaded',
        CaseTimelineEventType.phaseChange => 'phase_change',
        CaseTimelineEventType.manualNote => 'manual_note',
      };

  static CaseTimelineEventType fromDb(String value) => switch (value) {
        'email_in' => CaseTimelineEventType.emailIn,
        'email_out' => CaseTimelineEventType.emailOut,
        'consilium_decision' => CaseTimelineEventType.consiliumDecision,
        'deadline_set' => CaseTimelineEventType.deadlineSet,
        'doc_uploaded' => CaseTimelineEventType.docUploaded,
        'phase_change' => CaseTimelineEventType.phaseChange,
        'manual_note' => CaseTimelineEventType.manualNote,
        _ => throw FormatException('Unknown event_type: $value'),
      };
}

/// One row from `case_timeline_events`.
class CaseTimelineEvent {
  const CaseTimelineEvent({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.type,
    required this.title,
    this.summary,
    this.payload = const {},
    required this.occurredAt,
    required this.createdAt,
  });

  final String id;
  final String caseId;
  final String userId;
  final CaseTimelineEventType type;
  final String title;
  final String? summary;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;
  final DateTime createdAt;

  /// Convenience: returns the dedupe_key from payload if present.
  String? get dedupeKey => payload['dedupe_key'] as String?;

  factory CaseTimelineEvent.fromJson(Map<String, dynamic> json) {
    // payload may arrive as a String (when a misconfigured PostgREST view
    // returns jsonb-as-text); coerce defensively.
    Map<String, dynamic> payload;
    final raw = json['payload'];
    if (raw is Map<String, dynamic>) {
      payload = raw;
    } else if (raw is Map) {
      payload = raw.cast<String, dynamic>();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        payload = decoded is Map<String, dynamic>
            ? decoded
            : (decoded is Map ? decoded.cast<String, dynamic>() : <String, dynamic>{});
      } catch (_) {
        payload = const {};
      }
    } else {
      payload = const {};
    }

    return CaseTimelineEvent(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      userId: json['user_id'] as String,
      type: CaseTimelineEventTypeX.fromDb(json['event_type'] as String),
      title: (json['title'] as String?) ?? '',
      summary: json['summary'] as String?,
      payload: payload,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Filter chip values for the timeline view.
enum CaseTimelineFilter {
  all,
  emails,
  consilium,
  deadlines,
  notes,
}

extension CaseTimelineFilterX on CaseTimelineFilter {
  /// Returns true if [event] passes this filter.
  bool accepts(CaseTimelineEvent event) {
    switch (this) {
      case CaseTimelineFilter.all:
        return true;
      case CaseTimelineFilter.emails:
        return event.type == CaseTimelineEventType.emailIn ||
            event.type == CaseTimelineEventType.emailOut;
      case CaseTimelineFilter.consilium:
        return event.type == CaseTimelineEventType.consiliumDecision;
      case CaseTimelineFilter.deadlines:
        return event.type == CaseTimelineEventType.deadlineSet;
      case CaseTimelineFilter.notes:
        return event.type == CaseTimelineEventType.manualNote;
    }
  }
}
