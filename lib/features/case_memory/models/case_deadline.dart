// =====================================================================
// CaseDeadline — Pkg 9 case_deadlines row.
//
// Mirrors the schema in:
//   supabase/migrations/20260507_10_case_deadlines.sql
//
// Two read shapes:
//   - [CaseDeadline.fromCaseRow]    — `case_deadlines_for(p_case_id)`
//     RPC returns the full row.
//   - [CaseDeadline.fromActiveRow]  — `active_deadlines(p_limit)` RPC
//     returns a joined projection (adds `case_title`, `delta_days`).
//
// We use a single class + nullable fields rather than two classes; the
// radar widget reads `caseTitle` + `deltaDays`, the per-case list
// ignores them.
//
// All enums kept as Dart `enum` with explicit string mapping to match
// Postgres `case_deadline_status` / `case_deadline_priority` /
// `case_deadline_source`. Unknown values fall back to safe defaults
// (architect §11 risk #1: never silently elevate priority).
// =====================================================================

import 'package:flutter/foundation.dart';

/// Status of a deadline. Mirrors Postgres `case_deadline_status` enum.
enum CaseDeadlineStatus {
  active('active'),
  completed('completed'),
  missed('missed'),
  archived('archived');

  const CaseDeadlineStatus(this.dbValue);
  final String dbValue;

  static CaseDeadlineStatus fromDb(String? raw) {
    return values.firstWhere(
      (v) => v.dbValue == raw,
      orElse: () => CaseDeadlineStatus.active,
    );
  }
}

/// Priority. Mirrors Postgres `case_deadline_priority` enum.
enum CaseDeadlinePriority {
  critical('critical'),
  high('high'),
  medium('medium'),
  low('low');

  const CaseDeadlinePriority(this.dbValue);
  final String dbValue;

  /// Default to `high` on unknown — matches the table default.
  static CaseDeadlinePriority fromDb(String? raw) {
    return values.firstWhere(
      (v) => v.dbValue == raw,
      orElse: () => CaseDeadlinePriority.high,
    );
  }
}

/// Source. Mirrors Postgres `case_deadline_source` enum.
enum CaseDeadlineSource {
  pdf('pdf'),
  intake('intake'),
  manual('manual'),
  email('email'),
  haikuExtract('haiku_extract'),
  statutoryTemplate('statutory_template');

  const CaseDeadlineSource(this.dbValue);
  final String dbValue;

  static CaseDeadlineSource fromDb(String? raw) {
    return values.firstWhere(
      (v) => v.dbValue == raw,
      orElse: () => CaseDeadlineSource.manual,
    );
  }
}

/// Computed urgency band the UI uses for color-coding. Independent
/// from `priority` — a `priority='medium'` deadline 12 hours away is
/// still rendered as `critical` urgency.
enum CaseDeadlineUrgency {
  /// `delta_days <= 1` (today / tomorrow). Red 700.
  critical,

  /// `delta_days <= 3`. Red 500.
  high,

  /// `delta_days <= 7`. Amber 700.
  medium,

  /// `delta_days > 7`. Theme `surfaceContainerHigh`.
  info,
}

/// One deadline row.
@immutable
class CaseDeadline {
  const CaseDeadline({
    required this.id,
    required this.caseId,
    required this.title,
    required this.deadlineAt,
    required this.status,
    required this.priority,
    required this.source,
    required this.holidayShifted,
    this.userId,
    this.caseTitle,
    this.description,
    this.statuteBasis,
    this.anchorKey,
    this.serviceDate,
    this.serviceBasis,
    this.holidayShiftNote,
    this.sourceDocId,
    this.completedAt,
    this.completedNote,
    this.createdAt,
    this.updatedAt,
    this.deltaDaysOverride,
  });

  final String id;
  final String caseId;
  final String? userId;

  /// Joined from `user_cases.title` by `active_deadlines` RPC. `null`
  /// when the row was loaded via `case_deadlines_for` (the screen
  /// already knows the case title).
  final String? caseTitle;

  final String title;
  final String? description;
  final String? statuteBasis;
  final String? anchorKey;
  final DateTime? serviceDate;
  final String? serviceBasis;
  final DateTime deadlineAt;
  final bool holidayShifted;
  final String? holidayShiftNote;
  final CaseDeadlineSource source;
  final String? sourceDocId;
  final CaseDeadlineStatus status;
  final CaseDeadlinePriority priority;
  final DateTime? completedAt;
  final String? completedNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Server-computed `delta_days` from `active_deadlines`. Used for
  /// the radar widget so we don't have to recompute against `now()`
  /// in Dart and risk a clock-skew off-by-one.
  final int? deltaDaysOverride;

  /// Calendar-day delta to the deadline, computed against [now].
  ///
  /// Rules (architect §7 — "today by 16:15" / "tomorrow" / "in 3 days"):
  ///   * Same calendar day → 0
  ///   * Tomorrow         → 1
  ///   * Yesterday        → -1
  ///
  /// We strip the time component so a deadline at 06:00 today and the
  /// user opening the app at 23:00 today both render as "today".
  ///
  /// Falls back to the server override when present and [now] is null.
  int daysUntil({DateTime? now}) {
    if (now == null && deltaDaysOverride != null) {
      return deltaDaysOverride!;
    }
    final clock = now ?? DateTime.now();
    final dueDay = DateTime.utc(
      deadlineAt.toUtc().year,
      deadlineAt.toUtc().month,
      deadlineAt.toUtc().day,
    );
    final today = DateTime.utc(
      clock.toUtc().year,
      clock.toUtc().month,
      clock.toUtc().day,
    );
    return dueDay.difference(today).inDays;
  }

  /// Urgency band for color-coding. See [CaseDeadlineUrgency].
  CaseDeadlineUrgency urgency({DateTime? now}) {
    final d = daysUntil(now: now);
    if (d <= 1) return CaseDeadlineUrgency.critical;
    if (d <= 3) return CaseDeadlineUrgency.high;
    if (d <= 7) return CaseDeadlineUrgency.medium;
    return CaseDeadlineUrgency.info;
  }

  /// Convenience: is the row still actionable?
  bool get isOpen => status == CaseDeadlineStatus.active;

  /// Build from `case_deadlines_for(p_case_id)` row (the full table).
  factory CaseDeadline.fromCaseRow(Map<String, dynamic> row) {
    return CaseDeadline(
      id: row['id'] as String,
      caseId: row['case_id'] as String,
      userId: row['user_id'] as String?,
      title: (row['title'] as String?) ?? '',
      description: row['description'] as String?,
      statuteBasis: row['statute_basis'] as String?,
      anchorKey: row['anchor_key'] as String?,
      serviceDate: _parseDate(row['service_date']),
      serviceBasis: row['service_basis'] as String?,
      deadlineAt: _parseDateRequired(row['deadline_at']),
      holidayShifted: (row['holiday_shifted'] as bool?) ?? false,
      holidayShiftNote: row['holiday_shift_note'] as String?,
      source: CaseDeadlineSource.fromDb(row['source'] as String?),
      sourceDocId: row['source_doc_id'] as String?,
      status: CaseDeadlineStatus.fromDb(row['status'] as String?),
      priority: CaseDeadlinePriority.fromDb(row['priority'] as String?),
      completedAt: _parseDate(row['completed_at']),
      completedNote: row['completed_note'] as String?,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  /// Build from `active_deadlines(p_limit)` row (joined projection).
  factory CaseDeadline.fromActiveRow(Map<String, dynamic> row) {
    return CaseDeadline(
      id: row['id'] as String,
      caseId: row['case_id'] as String,
      caseTitle: row['case_title'] as String?,
      title: (row['title'] as String?) ?? '',
      statuteBasis: row['statute_basis'] as String?,
      anchorKey: row['anchor_key'] as String?,
      deadlineAt: _parseDateRequired(row['deadline_at']),
      priority: CaseDeadlinePriority.fromDb(row['priority'] as String?),
      deltaDaysOverride: (row['delta_days'] as num?)?.toInt(),
      holidayShifted: (row['holiday_shifted'] as bool?) ?? false,
      holidayShiftNote: row['holiday_shift_note'] as String?,
      source: CaseDeadlineSource.fromDb(row['source'] as String?),
      // `active_deadlines` is filtered to status='active' server-side.
      status: CaseDeadlineStatus.active,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static DateTime _parseDateRequired(Object? raw) {
    final parsed = _parseDate(raw);
    if (parsed == null) {
      throw ArgumentError(
        'CaseDeadline: deadline_at is required, got $raw',
      );
    }
    return parsed;
  }

  CaseDeadline copyWith({
    CaseDeadlineStatus? status,
    DateTime? completedAt,
    String? completedNote,
  }) {
    return CaseDeadline(
      id: id,
      caseId: caseId,
      userId: userId,
      caseTitle: caseTitle,
      title: title,
      description: description,
      statuteBasis: statuteBasis,
      anchorKey: anchorKey,
      serviceDate: serviceDate,
      serviceBasis: serviceBasis,
      deadlineAt: deadlineAt,
      holidayShifted: holidayShifted,
      holidayShiftNote: holidayShiftNote,
      source: source,
      sourceDocId: sourceDocId,
      status: status ?? this.status,
      priority: priority,
      completedAt: completedAt ?? this.completedAt,
      completedNote: completedNote ?? this.completedNote,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deltaDaysOverride: deltaDaysOverride,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CaseDeadline && other.id == id && other.status == status;

  @override
  int get hashCode => Object.hash(id, status);
}
