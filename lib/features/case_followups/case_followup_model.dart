/// Smart Case Follow-ups (Feature #2) — client model.
///
/// A SOFT, user/AI-authored next-step task attached to a case. Distinct from
/// [Deadline] (statutory deadlines from documents) — see the migration header
/// for the rationale. Maps the `public.case_followups` row shape returned by
/// the `case_followups_for_case` RPC and the `case-followups` edge function.
library;

enum FollowupStatus { open, done, snoozed, dismissed }

enum FollowupSource { suggested, ai, manual }

class CaseFollowup {
  final String id;
  final String caseId;
  final String title;
  final String? detail;
  final DateTime? dueAt;
  final FollowupStatus status;
  final FollowupSource source;
  final int snoozeCount;
  final DateTime? createdAt;

  const CaseFollowup({
    required this.id,
    required this.caseId,
    required this.title,
    this.detail,
    this.dueAt,
    this.status = FollowupStatus.open,
    this.source = FollowupSource.manual,
    this.snoozeCount = 0,
    this.createdAt,
  });

  bool get isDone => status == FollowupStatus.done;

  /// True when this task carries a due date that has already passed.
  bool get isOverdue {
    final due = dueAt;
    if (due == null || isDone) return false;
    return due.isBefore(DateTime.now());
  }

  CaseFollowup copyWith({
    FollowupStatus? status,
    DateTime? dueAt,
    int? snoozeCount,
  }) {
    return CaseFollowup(
      id: id,
      caseId: caseId,
      title: title,
      detail: detail,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      source: source,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      createdAt: createdAt,
    );
  }

  factory CaseFollowup.fromJson(Map<String, dynamic> json) {
    return CaseFollowup(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String?,
      dueAt: _parseDate(json['due_at']),
      status: _statusFromJson(json['status'] as String?),
      source: _sourceFromJson(json['source'] as String?),
      snoozeCount: (json['snooze_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v)?.toLocal();
    }
    return null;
  }

  static FollowupStatus _statusFromJson(String? v) {
    switch (v) {
      case 'done':
        return FollowupStatus.done;
      case 'snoozed':
        return FollowupStatus.snoozed;
      case 'dismissed':
        return FollowupStatus.dismissed;
      default:
        return FollowupStatus.open;
    }
  }

  static FollowupSource _sourceFromJson(String? v) {
    switch (v) {
      case 'ai':
        return FollowupSource.ai;
      case 'suggested':
        return FollowupSource.suggested;
      default:
        return FollowupSource.manual;
    }
  }
}

/// A Haiku-proposed next-step, not yet persisted. The user accepts these into
/// real [CaseFollowup] rows from the suggestion sheet.
class FollowupSuggestion {
  final String title;
  final String? detail;
  final int dueOffsetDays;

  const FollowupSuggestion({
    required this.title,
    this.detail,
    this.dueOffsetDays = 0,
  });

  /// Absolute due date this suggestion implies, or null for a someday task.
  DateTime? dueAtFrom([DateTime? now]) {
    if (dueOffsetDays <= 0) return null;
    return (now ?? DateTime.now()).add(Duration(days: dueOffsetDays));
  }

  factory FollowupSuggestion.fromJson(Map<String, dynamic> json) {
    return FollowupSuggestion(
      title: json['title'] as String,
      detail: json['detail'] as String?,
      dueOffsetDays: (json['due_offset_days'] as num?)?.toInt() ?? 0,
    );
  }
}
