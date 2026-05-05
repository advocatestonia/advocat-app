// case_file_service.dart — Supabase persistence layer for the Case File.
// -----------------------------------------------------------------------------
// Ref: lib/models/case_file.dart
//      lib/services/case_file_extractor.dart
//      supabase/migrations/20260505_case_file.sql
//
// CRUD on three tables:
//   * case_file_events
//   * case_file_parties
//   * case_file_deadlines
//
// Idempotency: every insert path dedupes against existing rows by
// (user_id, case_id, dedupeKey) BEFORE writing. Without this, every chat
// turn would create duplicate "PPA decision received" rows because the
// extractor re-emits the same event from the conversation context.
//
// Demo-mode safe: when no Supabase client is initialised, every write
// silently no-ops and reads return empty lists. This matches the rest of
// the codebase (see SupabaseService.isDemo).
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/case_file.dart';

/// Riverpod DI — tests override to inject a fake.
final caseFileServiceProvider = Provider<CaseFileService>((ref) {
  return CaseFileService();
});

class CaseFileService {
  CaseFileService({SupabaseClient? client}) : _injected = client;

  final SupabaseClient? _injected;

  /// Resolve the Supabase client lazily. Returns null when running in
  /// demo / unit-test environments where Supabase has not been initialised.
  SupabaseClient? get _client {
    if (_injected != null) return _injected;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _currentUserId => _client?.auth.currentUser?.id;

  bool get isAvailable => _client != null && _currentUserId != null;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<List<CaseEvent>> listEvents({String? caseId, int limit = 200}) async {
    final c = _client;
    final uid = _currentUserId;
    if (c == null || uid == null) return const [];
    try {
      var q = c.from('case_file_events').select().eq('user_id', uid);
      if (caseId != null) q = q.eq('case_id', caseId);
      final rows = await q
          .order('event_date', ascending: true)
          .order('created_at', ascending: true)
          .limit(limit);
      return (rows as List)
          .map((r) => CaseEvent.fromRow(r as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<CaseParty>> listParties({String? caseId}) async {
    final c = _client;
    final uid = _currentUserId;
    if (c == null || uid == null) return const [];
    try {
      var q = c.from('case_file_parties').select().eq('user_id', uid);
      if (caseId != null) q = q.eq('case_id', caseId);
      final rows = await q.order('created_at', ascending: true);
      return (rows as List)
          .map((r) => CaseParty.fromRow(r as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<CaseDeadline>> listDeadlines({String? caseId}) async {
    final c = _client;
    final uid = _currentUserId;
    if (c == null || uid == null) return const [];
    try {
      var q = c.from('case_file_deadlines').select().eq('user_id', uid);
      if (caseId != null) q = q.eq('case_id', caseId);
      final rows = await q.order('deadline_date', ascending: true);
      return (rows as List)
          .map((r) => CaseDeadline.fromRow(r as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Idempotent upserts
  // ---------------------------------------------------------------------------

  /// Diff [incoming] against [existing] by [CaseEvent.dedupeKey] and return the
  /// items that need to be inserted. Pure — unit-testable in isolation.
  static List<CaseEvent> diffEvents(
    List<CaseEvent> incoming,
    List<CaseEvent> existing,
  ) {
    final seen = existing.map((e) => e.dedupeKey).toSet();
    final out = <CaseEvent>[];
    final batchSeen = <String>{};
    for (final e in incoming) {
      if (seen.contains(e.dedupeKey)) continue;
      if (!batchSeen.add(e.dedupeKey)) continue; // dedupe within the batch too
      out.add(e);
    }
    return out;
  }

  static List<CaseParty> diffParties(
    List<CaseParty> incoming,
    List<CaseParty> existing,
  ) {
    final seen = existing.map((p) => p.dedupeKey).toSet();
    final out = <CaseParty>[];
    final batchSeen = <String>{};
    for (final p in incoming) {
      if (seen.contains(p.dedupeKey)) continue;
      if (!batchSeen.add(p.dedupeKey)) continue;
      out.add(p);
    }
    return out;
  }

  static List<CaseDeadline> diffDeadlines(
    List<CaseDeadline> incoming,
    List<CaseDeadline> existing,
  ) {
    final seen = existing.map((d) => d.dedupeKey).toSet();
    final out = <CaseDeadline>[];
    final batchSeen = <String>{};
    for (final d in incoming) {
      if (seen.contains(d.dedupeKey)) continue;
      if (!batchSeen.add(d.dedupeKey)) continue;
      out.add(d);
    }
    return out;
  }

  /// Persist a fresh extraction. Idempotent: existing (user_id, case_id, key)
  /// rows are not duplicated.  Safe no-op when offline / not signed in.
  Future<void> upsertExtraction(
    CaseFileExtraction extraction, {
    String? caseId,
  }) async {
    if (extraction.isEmpty) return;
    final c = _client;
    final uid = _currentUserId;
    if (c == null || uid == null) return;

    try {
      // Read existing rows once per table so we can dedupe locally before
      // writing. With ~1 chat turn / minute this is cheap; if it ever turns
      // hot we'll add a unique constraint server-side and switch to upsert
      // on (user_id, case_id, normalised_key).
      final existingEvents = await listEvents(caseId: caseId);
      final existingParties = await listParties(caseId: caseId);
      final existingDeadlines = await listDeadlines(caseId: caseId);

      final newEvents = diffEvents(extraction.events, existingEvents);
      final newParties = diffParties(extraction.parties, existingParties);
      final newDeadlines = diffDeadlines(extraction.deadlines, existingDeadlines);

      if (newEvents.isNotEmpty) {
        final rows = newEvents
            .map((e) => e.toRow(userId: uid, caseId: caseId))
            .toList(growable: false);
        await c.from('case_file_events').insert(rows);
      }
      if (newParties.isNotEmpty) {
        final rows = newParties
            .map((p) => p.toRow(userId: uid, caseId: caseId))
            .toList(growable: false);
        await c.from('case_file_parties').insert(rows);
      }
      if (newDeadlines.isNotEmpty) {
        final rows = newDeadlines
            .map((d) => d.toRow(userId: uid, caseId: caseId))
            .toList(growable: false);
        await c.from('case_file_deadlines').insert(rows);
      }
    } catch (_) {
      // RLS denial / network blip — never crash the chat pipeline.
    }
  }

  /// Toggle a deadline's `completed` flag.
  Future<void> markDeadlineCompleted(String deadlineId, {bool completed = true}) async {
    final c = _client;
    final uid = _currentUserId;
    if (c == null || uid == null) return;
    try {
      await c
          .from('case_file_deadlines')
          .update({'completed': completed})
          .eq('id', deadlineId)
          .eq('user_id', uid);
    } catch (_) {/* swallow */}
  }

  /// Delete an extracted row. Used by the UI when the user disagrees with
  /// what was auto-extracted.
  Future<void> deleteEvent(String id) async {
    final c = _client;
    final uid = _currentUserId;
    if (c == null || uid == null) return;
    try {
      await c.from('case_file_events').delete().eq('id', id).eq('user_id', uid);
    } catch (_) {/* swallow */}
  }

  Future<void> deleteParty(String id) async {
    final c = _client;
    final uid = _currentUserId;
    if (c == null || uid == null) return;
    try {
      await c.from('case_file_parties').delete().eq('id', id).eq('user_id', uid);
    } catch (_) {/* swallow */}
  }

  Future<void> deleteDeadline(String id) async {
    final c = _client;
    final uid = _currentUserId;
    if (c == null || uid == null) return;
    try {
      await c.from('case_file_deadlines').delete().eq('id', id).eq('user_id', uid);
    } catch (_) {/* swallow */}
  }

  // ---------------------------------------------------------------------------
  // Dossier rendering — pure helper, easy to unit-test
  // ---------------------------------------------------------------------------

  /// Render a clean Markdown dossier suitable for [PdfService.renderDocument].
  /// Pure — no IO. Public + static so the UI can call it without an instance.
  static String buildDossierMarkdown({
    required List<CaseEvent> events,
    required List<CaseParty> parties,
    required List<CaseDeadline> deadlines,
    List<CaseDocument> documents = const [],
    List<CaseKeyFact> keyFacts = const [],
    DateTime? today,
    String locale = 'en',
  }) {
    final t = today ?? DateTime.now();
    final L = _DossierStrings.forLocale(locale);
    final buf = StringBuffer();

    buf.writeln('# ${L.title}');
    buf.writeln();
    buf.writeln('${L.generated}: ${_fmtDate(t)}');
    buf.writeln();

    if (keyFacts.isNotEmpty) {
      buf.writeln('## ${L.keyFacts}');
      for (final k in keyFacts) {
        buf.writeln('- **${k.key}**: ${k.value}');
      }
      buf.writeln();
    }

    final activeDeadlines =
        deadlines.where((d) => !d.completed).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    if (activeDeadlines.isNotEmpty) {
      buf.writeln('## ${L.deadlines}');
      for (final d in activeDeadlines) {
        final days = d.daysFrom(t);
        final daysLabel = days < 0
            ? '${L.overdue} ${-days}d'
            : '${days}d ${L.remaining}';
        final law = d.law != null && d.law!.isNotEmpty ? ' (${d.law})' : '';
        buf.writeln('- ${_fmtDate(d.date)} — **${d.title}**$law — $daysLabel');
      }
      buf.writeln();
    }

    if (events.isNotEmpty) {
      final sorted = [...events]
        ..sort((a, b) {
          final da = a.date;
          final db = b.date;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      buf.writeln('## ${L.timeline}');
      for (final e in sorted) {
        final d = e.date != null ? _fmtDate(e.date!) : '—';
        buf.writeln('- $d — **${e.title}**');
        if (e.description != null && e.description!.isNotEmpty) {
          buf.writeln('  ${e.description}');
        }
      }
      buf.writeln();
    }

    if (parties.isNotEmpty) {
      buf.writeln('## ${L.parties}');
      for (final p in parties) {
        final ctx = p.context != null && p.context!.isNotEmpty
            ? ' — ${p.context}'
            : '';
        buf.writeln('- **${p.name}** _(${p.type.toWire()})_$ctx');
      }
      buf.writeln();
    }

    if (documents.isNotEmpty) {
      buf.writeln('## ${L.documents}');
      for (final d in documents) {
        final t = d.type != null ? ' _(${d.type})_' : '';
        buf.writeln('- ${d.name}$t');
      }
      buf.writeln();
    }

    buf.writeln('---');
    buf.writeln(L.disclaimer);
    return buf.toString();
  }

  /// Test seam.
  @visibleForTesting
  static String buildDossierMarkdownForTest({
    required List<CaseEvent> events,
    required List<CaseParty> parties,
    required List<CaseDeadline> deadlines,
    List<CaseDocument> documents = const [],
    List<CaseKeyFact> keyFacts = const [],
    DateTime? today,
    String locale = 'en',
  }) =>
      buildDossierMarkdown(
        events: events,
        parties: parties,
        deadlines: deadlines,
        documents: documents,
        keyFacts: keyFacts,
        today: today,
        locale: locale,
      );
}

// -----------------------------------------------------------------------------
// Localised dossier strings — kept tiny on purpose; full app l10n still drives
// the UI, but the PDF output for the lawyer sticks to a fixed minimal set.
// -----------------------------------------------------------------------------

class _DossierStrings {
  final String title;
  final String generated;
  final String keyFacts;
  final String deadlines;
  final String timeline;
  final String parties;
  final String documents;
  final String overdue;
  final String remaining;
  final String disclaimer;

  const _DossierStrings({
    required this.title,
    required this.generated,
    required this.keyFacts,
    required this.deadlines,
    required this.timeline,
    required this.parties,
    required this.documents,
    required this.overdue,
    required this.remaining,
    required this.disclaimer,
  });

  static _DossierStrings forLocale(String locale) {
    switch (locale.toLowerCase()) {
      case 'et':
        return const _DossierStrings(
          title: 'Toimik',
          generated: 'Loodud',
          keyFacts: 'Põhiandmed',
          deadlines: 'Tähtajad',
          timeline: 'Ajatelg',
          parties: 'Osalised',
          documents: 'Dokumendid',
          overdue: 'Ületatud',
          remaining: 'jäänud',
          disclaimer:
              'See dokument on AI-genereeritud kokkuvõte kasutaja vestlusest. '
              'See ei ole õigusnõuanne. Konsulteeri vandeadvokaadiga.',
        );
      case 'ru':
        return const _DossierStrings(
          title: 'Досье',
          generated: 'Создано',
          keyFacts: 'Ключевые факты',
          deadlines: 'Сроки',
          timeline: 'Хронология',
          parties: 'Стороны',
          documents: 'Документы',
          overdue: 'Просрочено',
          remaining: 'осталось',
          disclaimer:
              'Этот документ — AI-сводка из чата пользователя. Это не юридическая '
              'консультация. Обратитесь к квалифицированному адвокату.',
        );
      default:
        return const _DossierStrings(
          title: 'Case File',
          generated: 'Generated',
          keyFacts: 'Key facts',
          deadlines: 'Deadlines',
          timeline: 'Timeline',
          parties: 'Parties',
          documents: 'Documents',
          overdue: 'overdue',
          remaining: 'remaining',
          disclaimer:
              'This document is an AI-generated summary of the user\'s chat. '
              'It is not legal advice. Consult a licensed attorney.',
        );
    }
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
