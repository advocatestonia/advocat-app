// =====================================================================
// UserCase — client-side model for the `public.user_cases` row shape.
//
// Schema source of truth: supabase/migrations/20260506_case_memory.sql
// JSONB columns are stored as arrays of objects on the DB side; here
// they are typed as small immutable classes so the UI layer never
// reaches into raw maps.
//
// Only this model and [CaseDocument] are part of Pkg 1.D. The auto-patch
// worker (Pkg 1.C) writes to these JSONB columns server-side; we only
// read/edit them. Pkg 1.B's `load_active_case` RPC returns the case as
// a jsonb object — see the RPC contract in the migration.
// =====================================================================

import 'package:flutter/foundation.dart';

/// Status mirrors the `user_cases.status` CHECK constraint.
enum CaseMemoryStatus {
  active,
  archived,
  closed;

  String get dbValue => name;

  static CaseMemoryStatus fromDb(String? raw) {
    switch (raw) {
      case 'archived':
        return CaseMemoryStatus.archived;
      case 'closed':
        return CaseMemoryStatus.closed;
      case 'active':
      default:
        // Defensive: unknown values fall back to active so the UI never
        // crashes on a server-side schema additon.
        return CaseMemoryStatus.active;
    }
  }
}

@immutable
class UserCase {
  const UserCase({
    required this.id,
    required this.userId,
    required this.title,
    required this.jurisdiction,
    this.caseType,
    this.status = CaseMemoryStatus.active,
    this.caseNumbers = const [],
    this.parties = const [],
    this.keyDates = const [],
    this.authorities = const [],
    this.timeline = const [],
    this.openQuestions = const [],
    this.nextActions = const [],
    this.summary,
    this.language = 'ru',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String jurisdiction;
  final String? caseType;
  final CaseMemoryStatus status;
  final List<CaseNumber> caseNumbers;
  final List<Party> parties;
  final List<KeyDate> keyDates;
  final List<Authority> authorities;
  final List<TimelineEntry> timeline;
  final List<OpenQuestion> openQuestions;
  final List<NextAction> nextActions;
  final String? summary;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Factory ────────────────────────────────────────────────────────

  factory UserCase.fromJson(Map<String, dynamic> json) {
    return UserCase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      jurisdiction: json['jurisdiction'] as String,
      caseType: json['case_type'] as String?,
      status: CaseMemoryStatus.fromDb(json['status'] as String?),
      caseNumbers: _parseList(json['case_numbers'], CaseNumber.fromJson),
      parties: _parseList(json['parties'], Party.fromJson),
      keyDates: _parseList(json['key_dates'], KeyDate.fromJson),
      authorities: _parseList(json['authorities'], Authority.fromJson),
      timeline: _parseList(json['timeline'], TimelineEntry.fromJson),
      openQuestions: _parseList(json['open_questions'], OpenQuestion.fromJson),
      nextActions: _parseList(json['next_actions'], NextAction.fromJson),
      summary: json['summary'] as String?,
      language: (json['language'] as String?) ?? 'ru',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'jurisdiction': jurisdiction,
        'case_type': caseType,
        'status': status.dbValue,
        'case_numbers': caseNumbers.map((e) => e.toJson()).toList(),
        'parties': parties.map((e) => e.toJson()).toList(),
        'key_dates': keyDates.map((e) => e.toJson()).toList(),
        'authorities': authorities.map((e) => e.toJson()).toList(),
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'open_questions': openQuestions.map((e) => e.toJson()).toList(),
        'next_actions': nextActions.map((e) => e.toJson()).toList(),
        'summary': summary,
        'language': language,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Returns just the writable fields suitable for an UPDATE statement.
  /// Excludes id / user_id / created_at / updated_at — those are managed
  /// by the DB.
  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'jurisdiction': jurisdiction,
        'case_type': caseType,
        'status': status.dbValue,
        'case_numbers': caseNumbers.map((e) => e.toJson()).toList(),
        'parties': parties.map((e) => e.toJson()).toList(),
        'key_dates': keyDates.map((e) => e.toJson()).toList(),
        'authorities': authorities.map((e) => e.toJson()).toList(),
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'open_questions': openQuestions.map((e) => e.toJson()).toList(),
        'next_actions': nextActions.map((e) => e.toJson()).toList(),
        'summary': summary,
        'language': language,
      };

  // ── copyWith ───────────────────────────────────────────────────────

  UserCase copyWith({
    String? id,
    String? userId,
    String? title,
    String? jurisdiction,
    String? caseType,
    CaseMemoryStatus? status,
    List<CaseNumber>? caseNumbers,
    List<Party>? parties,
    List<KeyDate>? keyDates,
    List<Authority>? authorities,
    List<TimelineEntry>? timeline,
    List<OpenQuestion>? openQuestions,
    List<NextAction>? nextActions,
    Object? summary = _sentinel,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      caseType: caseType ?? this.caseType,
      status: status ?? this.status,
      caseNumbers: caseNumbers ?? this.caseNumbers,
      parties: parties ?? this.parties,
      keyDates: keyDates ?? this.keyDates,
      authorities: authorities ?? this.authorities,
      timeline: timeline ?? this.timeline,
      openQuestions: openQuestions ?? this.openQuestions,
      nextActions: nextActions ?? this.nextActions,
      summary: identical(summary, _sentinel) ? this.summary : summary as String?,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _sentinel = Object();
}

// ── Parser helper ─────────────────────────────────────────────────────

List<T> _parseList<T>(
  Object? raw,
  T Function(Map<String, dynamic>) factory,
) {
  if (raw == null) return const [];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((m) => factory(Map<String, dynamic>.from(m)))
      .toList(growable: false);
}

// ──────────────────────────────────────────────────────────────────────
// Nested types — intentionally tolerant of unknown keys (Pkg 1.C may
// add keys server-side ahead of the client).
// ──────────────────────────────────────────────────────────────────────

@immutable
class CaseNumber {
  const CaseNumber({required this.authority, required this.number, this.role});
  final String authority;
  final String number;
  final String? role;

  factory CaseNumber.fromJson(Map<String, dynamic> json) => CaseNumber(
        authority: (json['authority'] as String?) ?? '',
        number: (json['number'] as String?) ?? '',
        role: json['role'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'authority': authority,
        'number': number,
        'role': role,
      };

  @override
  bool operator ==(Object other) =>
      other is CaseNumber &&
      other.authority == authority &&
      other.number == number &&
      other.role == role;

  @override
  int get hashCode => Object.hash(authority, number, role);
}

@immutable
class Party {
  const Party({required this.role, required this.name, this.note});
  final String role;
  final String name;
  final String? note;

  factory Party.fromJson(Map<String, dynamic> json) => Party(
        role: (json['role'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'name': name,
        'note': note,
      };

  @override
  bool operator ==(Object other) =>
      other is Party &&
      other.role == role &&
      other.name == name &&
      other.note == note;

  @override
  int get hashCode => Object.hash(role, name, note);
}

@immutable
class KeyDate {
  const KeyDate({required this.label, required this.date, this.note});
  final String label;
  final String date; // ISO yyyy-MM-dd, kept as String (jsonb side)
  final String? note;

  factory KeyDate.fromJson(Map<String, dynamic> json) => KeyDate(
        label: (json['label'] as String?) ?? '',
        date: (json['date'] as String?) ?? '',
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'date': date,
        'note': note,
      };

  @override
  bool operator ==(Object other) =>
      other is KeyDate &&
      other.label == label &&
      other.date == date &&
      other.note == note;

  @override
  int get hashCode => Object.hash(label, date, note);
}

@immutable
class Authority {
  const Authority({required this.name, this.contact});
  final String name;
  final String? contact;

  factory Authority.fromJson(Map<String, dynamic> json) => Authority(
        name: (json['name'] as String?) ?? '',
        contact: json['contact'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'contact': contact,
      };

  @override
  bool operator ==(Object other) =>
      other is Authority && other.name == name && other.contact == contact;

  @override
  int get hashCode => Object.hash(name, contact);
}

@immutable
class TimelineEntry {
  const TimelineEntry({required this.date, required this.event});
  final String date;
  final String event;

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
        date: (json['date'] as String?) ?? '',
        event: (json['event'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'event': event,
      };

  @override
  bool operator ==(Object other) =>
      other is TimelineEntry && other.date == date && other.event == event;

  @override
  int get hashCode => Object.hash(date, event);
}

@immutable
class OpenQuestion {
  const OpenQuestion({required this.question, this.priority});
  final String question;
  final String? priority;

  factory OpenQuestion.fromJson(Map<String, dynamic> json) => OpenQuestion(
        question: (json['question'] as String?) ?? '',
        priority: json['priority'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'priority': priority,
      };

  @override
  bool operator ==(Object other) =>
      other is OpenQuestion &&
      other.question == question &&
      other.priority == priority;

  @override
  int get hashCode => Object.hash(question, priority);
}

@immutable
class NextAction {
  const NextAction({required this.action, this.due});
  final String action;
  final String? due;

  factory NextAction.fromJson(Map<String, dynamic> json) => NextAction(
        action: (json['action'] as String?) ?? '',
        due: json['due'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'action': action,
        'due': due,
      };

  @override
  bool operator ==(Object other) =>
      other is NextAction && other.action == action && other.due == due;

  @override
  int get hashCode => Object.hash(action, due);
}
