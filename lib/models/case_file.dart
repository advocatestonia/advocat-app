// case_file.dart — typed models for the Case File feature.
// -----------------------------------------------------------------------------
// Ref: lib/services/case_file_extractor.dart
//      lib/services/case_file_service.dart
//      supabase/migrations/20260505_case_file.sql
//
// Pure data classes. No IO, no Supabase, no Flutter — safe to unit-test.
// -----------------------------------------------------------------------------

import 'dart:convert';

/// Categories for timeline events. String-typed because the Supabase column is
/// a free `text` field — we validate against this allowlist on parse.
enum CaseEventCategory {
  decision,
  deadline,
  submission,
  communication,
  hearing,
  other;

  static CaseEventCategory parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'decision':
        return CaseEventCategory.decision;
      case 'deadline':
        return CaseEventCategory.deadline;
      case 'submission':
        return CaseEventCategory.submission;
      case 'communication':
        return CaseEventCategory.communication;
      case 'hearing':
        return CaseEventCategory.hearing;
      default:
        return CaseEventCategory.other;
    }
  }

  String toWire() => name;
}

/// Party roles — same allowlist style as event categories.
enum PartyType {
  authority,
  person,
  company,
  lawyer,
  other;

  static PartyType parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'authority':
        return PartyType.authority;
      case 'person':
        return PartyType.person;
      case 'company':
        return PartyType.company;
      case 'lawyer':
        return PartyType.lawyer;
      default:
        return PartyType.other;
    }
  }

  String toWire() => name;
}

/// One legal event extracted from a chat turn.
class CaseEvent {
  final String? id;
  final DateTime? date;
  final String title;
  final String? description;
  final CaseEventCategory category;

  const CaseEvent({
    this.id,
    this.date,
    required this.title,
    this.description,
    this.category = CaseEventCategory.other,
  });

  /// Build a deterministic dedupe key.  Two events that share the same
  /// (normalised title, date) are considered the same event.  Used by the
  /// service layer to avoid duplicate inserts on every chat turn.
  String get dedupeKey {
    final t = title.trim().toLowerCase();
    final d = date?.toIso8601String().substring(0, 10) ?? '';
    return '$d|$t';
  }

  Map<String, dynamic> toRow({required String userId, String? caseId}) => {
        'user_id': userId,
        if (caseId != null) 'case_id': caseId,
        if (date != null)
          'event_date': date!.toIso8601String().substring(0, 10),
        'title': title,
        if (description != null) 'description': description,
        'category': category.toWire(),
      };

  factory CaseEvent.fromRow(Map<String, dynamic> row) {
    return CaseEvent(
      id: row['id'] as String?,
      date: _parseDate(row['event_date']),
      title: (row['title'] as String?) ?? '',
      description: row['description'] as String?,
      category: CaseEventCategory.parse(row['category'] as String?),
    );
  }

  factory CaseEvent.fromJson(Map<String, dynamic> j) {
    return CaseEvent(
      date: _parseDate(j['date']),
      title: (j['title'] as String?)?.trim() ?? '',
      description: (j['description'] as String?)?.trim(),
      category: CaseEventCategory.parse(j['category'] as String?),
    );
  }
}

/// One named party in the user's case (authority, person, company, lawyer).
class CaseParty {
  final String? id;
  final String name;
  final PartyType type;
  final String? context;

  const CaseParty({
    this.id,
    required this.name,
    this.type = PartyType.other,
    this.context,
  });

  String get dedupeKey {
    final n = name.trim().toLowerCase();
    return '${type.toWire()}|$n';
  }

  Map<String, dynamic> toRow({required String userId, String? caseId}) => {
        'user_id': userId,
        if (caseId != null) 'case_id': caseId,
        'name': name,
        'type': type.toWire(),
        if (context != null) 'context': context,
      };

  factory CaseParty.fromRow(Map<String, dynamic> row) => CaseParty(
        id: row['id'] as String?,
        name: (row['name'] as String?) ?? '',
        type: PartyType.parse(row['type'] as String?),
        context: row['context'] as String?,
      );

  factory CaseParty.fromJson(Map<String, dynamic> j) => CaseParty(
        name: (j['name'] as String?)?.trim() ?? '',
        type: PartyType.parse(j['type'] as String?),
        context: (j['context'] as String?)?.trim(),
      );
}

/// One deadline with optional law reference and urgency flag.
class CaseDeadline {
  final String? id;
  final DateTime date;
  final String title;
  final String? law;
  final bool completed;

  const CaseDeadline({
    this.id,
    required this.date,
    required this.title,
    this.law,
    this.completed = false,
  });

  /// Days from [today] until the deadline. Negative when overdue.
  int daysFrom(DateTime today) {
    final t = DateTime(today.year, today.month, today.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.difference(t).inDays;
  }

  bool isUrgentAt(DateTime today) {
    final days = daysFrom(today);
    return !completed && days >= 0 && days <= 7;
  }

  String get dedupeKey {
    final t = title.trim().toLowerCase();
    final d = date.toIso8601String().substring(0, 10);
    return '$d|$t';
  }

  Map<String, dynamic> toRow({required String userId, String? caseId}) => {
        'user_id': userId,
        if (caseId != null) 'case_id': caseId,
        'deadline_date': date.toIso8601String().substring(0, 10),
        'title': title,
        if (law != null) 'law': law,
        'completed': completed,
      };

  factory CaseDeadline.fromRow(Map<String, dynamic> row) => CaseDeadline(
        id: row['id'] as String?,
        date: _parseDate(row['deadline_date']) ?? DateTime.now(),
        title: (row['title'] as String?) ?? '',
        law: row['law'] as String?,
        completed: (row['completed'] as bool?) ?? false,
      );

  factory CaseDeadline.fromJson(Map<String, dynamic> j) {
    final parsed = _parseDate(j['date']);
    return CaseDeadline(
      date: parsed ?? DateTime.now(),
      title: (j['title'] as String?)?.trim() ?? '',
      law: (j['law'] as String?)?.trim(),
    );
  }

  /// Whether the deadline JSON object was usable (had a real date + title).
  static bool isValidJson(Map<String, dynamic> j) {
    return _parseDate(j['date']) != null &&
        ((j['title'] as String?)?.trim().isNotEmpty ?? false);
  }
}

/// Document the user uploaded or AI generated.
class CaseDocument {
  final String name;
  final String? type;
  final bool uploaded;

  const CaseDocument({required this.name, this.type, this.uploaded = false});

  factory CaseDocument.fromJson(Map<String, dynamic> j) => CaseDocument(
        name: (j['name'] as String?)?.trim() ?? '',
        type: (j['type'] as String?)?.trim(),
        uploaded: (j['uploaded'] as bool?) ?? false,
      );
}

/// Free-form key/value extracted fact (case number, jurisdiction, ...).
class CaseKeyFact {
  final String key;
  final String value;

  const CaseKeyFact({required this.key, required this.value});

  factory CaseKeyFact.fromJson(Map<String, dynamic> j) => CaseKeyFact(
        key: (j['key'] as String?)?.trim() ?? '',
        value: (j['value'] as String?)?.trim() ?? '',
      );
}

/// The full result of a single extraction call.  `events`, `parties`,
/// `deadlines` are persisted to Supabase; `documents` and `keyFacts` are
/// surfaced in the UI but not (yet) persisted server-side — they live in
/// memory and refresh on each chat turn.
class CaseFileExtraction {
  final List<CaseEvent> events;
  final List<CaseParty> parties;
  final List<CaseDeadline> deadlines;
  final List<CaseDocument> documents;
  final List<CaseKeyFact> keyFacts;

  const CaseFileExtraction({
    this.events = const [],
    this.parties = const [],
    this.deadlines = const [],
    this.documents = const [],
    this.keyFacts = const [],
  });

  static const empty = CaseFileExtraction();

  bool get isEmpty =>
      events.isEmpty &&
      parties.isEmpty &&
      deadlines.isEmpty &&
      documents.isEmpty &&
      keyFacts.isEmpty;

  /// Parse a Claude-emitted JSON string. Tolerant of markdown fences and
  /// surrounding prose — finds the first balanced `{...}` block and parses
  /// it. Returns [empty] on any malformed input rather than throwing, so the
  /// chat pipeline never crashes on bad model output.
  static CaseFileExtraction fromRawJson(String raw) {
    final block = _extractJsonBlock(raw);
    if (block == null) return empty;
    try {
      final parsed = jsonDecode(block);
      if (parsed is! Map<String, dynamic>) return empty;
      return CaseFileExtraction(
        events: (parsed['events'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CaseEvent.fromJson)
            .where((e) => e.title.isNotEmpty)
            .toList(growable: false),
        parties: (parsed['parties'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CaseParty.fromJson)
            .where((p) => p.name.isNotEmpty)
            .toList(growable: false),
        deadlines: (parsed['deadlines'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .where(CaseDeadline.isValidJson)
            .map(CaseDeadline.fromJson)
            .toList(growable: false),
        documents: (parsed['documents'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CaseDocument.fromJson)
            .where((d) => d.name.isNotEmpty)
            .toList(growable: false),
        keyFacts: (parsed['key_facts'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CaseKeyFact.fromJson)
            .where((f) => f.key.isNotEmpty && f.value.isNotEmpty)
            .toList(growable: false),
      );
    } catch (_) {
      return empty;
    }
  }
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

DateTime? _parseDate(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  // Try ISO YYYY-MM-DD first.
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;
  // Try DD.MM.YYYY (Estonian / Russian convention).
  final m = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(s);
  if (m != null) {
    final d = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final y = int.tryParse(m.group(3)!);
    if (d != null && mo != null && y != null) {
      try {
        return DateTime(y, mo, d);
      } catch (_) {/* fall through */}
    }
  }
  return null;
}

/// Find the first balanced `{...}` block in [raw]. Returns null when none
/// found (e.g. model wrapped output in unexpected prose with no JSON).
String? _extractJsonBlock(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final start = s.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  for (var i = start; i < s.length; i++) {
    final c = s[i];
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) {
        return s.substring(start, i + 1);
      }
    }
  }
  return null;
}
