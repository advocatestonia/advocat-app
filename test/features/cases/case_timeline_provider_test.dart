@Tags(['fast'])
library;

import 'package:advocat/features/cases/models/case_timeline_event.dart';
import 'package:advocat/features/cases/providers/case_timeline_provider.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Provider-only tests — no DB. FakeSupabaseService overrides the read
// path so we can assert pagination, refresh, filter scoping, and the
// manual-note round trip.
// ---------------------------------------------------------------------------

const _caseA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

CaseTimelineEvent _evt({
  required String id,
  required String caseId,
  required CaseTimelineEventType type,
  required DateTime occurredAt,
  String title = 'Event',
  String? summary,
  Map<String, dynamic>? payload,
}) {
  return CaseTimelineEvent(
    id: id,
    caseId: caseId,
    userId: 'user-001',
    type: type,
    title: title,
    summary: summary,
    payload: payload ?? const {},
    occurredAt: occurredAt,
    createdAt: occurredAt,
  );
}

class FakeSupabaseService extends SupabaseService {
  /// Each `getCaseTimelineEvents` call shifts one page off the front of
  /// this queue. Lets tests script the loadMore / pagination sequence.
  final List<List<CaseTimelineEvent>> pagesByCall = [];
  final List<Map<String, dynamic>> getCalls = [];
  String? lastAppendNoteCaseId;
  String? lastAppendNoteTitle;
  String? lastDeletedId;
  Exception? throwOnNextGet;

  @override
  Future<List<CaseTimelineEvent>> getCaseTimelineEvents({
    required String caseId,
    int pageSize = 50,
    DateTime? beforeOccurredAt,
  }) async {
    getCalls.add({
      'caseId': caseId,
      'pageSize': pageSize,
      'beforeOccurredAt': beforeOccurredAt?.toIso8601String(),
    });
    if (throwOnNextGet != null) {
      final err = throwOnNextGet!;
      throwOnNextGet = null;
      throw err;
    }
    if (pagesByCall.isEmpty) return const [];
    return pagesByCall.removeAt(0);
  }

  @override
  Future<String?> appendManualNote({
    required String caseId,
    required String title,
    String? summary,
  }) async {
    lastAppendNoteCaseId = caseId;
    lastAppendNoteTitle = title;
    return 'new-note-${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Future<void> deleteManualNote(String eventId) async {
    lastDeletedId = eventId;
  }
}

ProviderContainer makeContainer(FakeSupabaseService fake) {
  final container = ProviderContainer(
    overrides: [supabaseServiceProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> resolveAsync(
    ProviderContainer container, ProviderListenable<dynamic> provider) async {
  // Allow microtasks to drain.
  for (var i = 0; i < 50; i++) {
    final s = container.read(provider);
    if (s is AsyncValue && (s.isLoading == false)) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  group('caseTimelineProvider — initial fetch', () {
    test('loads first page on read', () async {
      final fake = FakeSupabaseService()
        ..pagesByCall.add([
          _evt(
            id: 'e1',
            caseId: _caseA,
            type: CaseTimelineEventType.emailIn,
            occurredAt: DateTime(2026, 5, 25, 12),
          ),
          _evt(
            id: 'e2',
            caseId: _caseA,
            type: CaseTimelineEventType.consiliumDecision,
            occurredAt: DateTime(2026, 5, 25, 11),
          ),
        ]);
      final c = makeContainer(fake);

      // Trigger build + wait.
      c.read(caseTimelineProvider(_caseA));
      await resolveAsync(c, caseTimelineProvider(_caseA));

      final state = c.read(caseTimelineProvider(_caseA)).value!;
      expect(state.events, hasLength(2));
      expect(state.events.first.id, 'e1');
      expect(state.hasMore, isFalse,
          reason: 'page returned fewer than pageSize → hasMore=false');
      expect(fake.getCalls, hasLength(1));
      expect(fake.getCalls.first['beforeOccurredAt'], isNull);
    });

    test('hasMore=true when page is full', () async {
      // Build a full page so the notifier thinks more remain.
      final full = List.generate(
        kCaseTimelinePageSize,
        (i) => _evt(
          id: 'e$i',
          caseId: _caseA,
          type: CaseTimelineEventType.emailIn,
          occurredAt: DateTime(2026, 5, 25).subtract(Duration(hours: i)),
        ),
      );
      final fake = FakeSupabaseService()..pagesByCall.add(full);
      final c = makeContainer(fake);
      c.read(caseTimelineProvider(_caseA));
      await resolveAsync(c, caseTimelineProvider(_caseA));

      expect(c.read(caseTimelineProvider(_caseA)).value!.hasMore, isTrue);
    });

    test('error path bubbles AsyncError', () async {
      final fake = FakeSupabaseService()
        ..throwOnNextGet = Exception('network');
      final c = makeContainer(fake);
      c.read(caseTimelineProvider(_caseA));
      await resolveAsync(c, caseTimelineProvider(_caseA));
      final s = c.read(caseTimelineProvider(_caseA));
      expect(s.hasError, isTrue);
    });
  });

  group('caseTimelineProvider — loadMore', () {
    test('appends next page and uses last occurred_at as cursor', () async {
      final page1 = List.generate(
        kCaseTimelinePageSize,
        (i) => _evt(
          id: 'p1-$i',
          caseId: _caseA,
          type: CaseTimelineEventType.emailIn,
          occurredAt:
              DateTime(2026, 5, 25, 12).subtract(Duration(minutes: i)),
        ),
      );
      final cursorMatch = page1.last.occurredAt;
      final page2 = [
        _evt(
          id: 'p2-1',
          caseId: _caseA,
          type: CaseTimelineEventType.deadlineSet,
          occurredAt: cursorMatch.subtract(const Duration(minutes: 1)),
        ),
      ];

      final fake = FakeSupabaseService()
        ..pagesByCall.add(page1)
        ..pagesByCall.add(page2);

      final c = makeContainer(fake);
      c.read(caseTimelineProvider(_caseA));
      await resolveAsync(c, caseTimelineProvider(_caseA));

      await c
          .read(caseTimelineProvider(_caseA).notifier)
          .loadMore();
      await resolveAsync(c, caseTimelineProvider(_caseA));

      final state = c.read(caseTimelineProvider(_caseA)).value!;
      expect(state.events, hasLength(kCaseTimelinePageSize + 1));
      expect(state.events.last.id, 'p2-1');
      expect(state.hasMore, isFalse);
      expect(fake.getCalls, hasLength(2));
      expect(
        fake.getCalls[1]['beforeOccurredAt'],
        cursorMatch.toIso8601String(),
      );
    });

    test('loadMore no-ops when hasMore=false', () async {
      final fake = FakeSupabaseService()
        ..pagesByCall.add([
          _evt(
            id: 'e1',
            caseId: _caseA,
            type: CaseTimelineEventType.emailIn,
            occurredAt: DateTime(2026, 5, 25, 12),
          ),
        ]);
      final c = makeContainer(fake);
      c.read(caseTimelineProvider(_caseA));
      await resolveAsync(c, caseTimelineProvider(_caseA));

      await c.read(caseTimelineProvider(_caseA).notifier).loadMore();
      expect(fake.getCalls, hasLength(1),
          reason: 'second call must not be issued when hasMore=false');
    });
  });

  group('caseTimelineProvider — manual note', () {
    test('appendManualNote triggers refresh and forwards args', () async {
      final fake = FakeSupabaseService()
        ..pagesByCall.add([]) // initial
        ..pagesByCall.add([
          _evt(
            id: 'note-1',
            caseId: _caseA,
            type: CaseTimelineEventType.manualNote,
            occurredAt: DateTime(2026, 5, 25, 14),
            title: 'Call notes',
          ),
        ]);
      final c = makeContainer(fake);
      c.read(caseTimelineProvider(_caseA));
      await resolveAsync(c, caseTimelineProvider(_caseA));

      final newId = await c
          .read(caseTimelineProvider(_caseA).notifier)
          .appendManualNote(title: 'Call notes', summary: 'Owner called');
      await resolveAsync(c, caseTimelineProvider(_caseA));

      expect(newId, isNotNull);
      expect(fake.lastAppendNoteCaseId, _caseA);
      expect(fake.lastAppendNoteTitle, 'Call notes');
      final events = c.read(caseTimelineProvider(_caseA)).value!.events;
      expect(events, hasLength(1));
      expect(events.first.title, 'Call notes');
    });

    test('deleteManualNote optimistically removes locally', () async {
      final fake = FakeSupabaseService()
        ..pagesByCall.add([
          _evt(
            id: 'note-1',
            caseId: _caseA,
            type: CaseTimelineEventType.manualNote,
            occurredAt: DateTime(2026, 5, 25, 14),
          ),
          _evt(
            id: 'email-1',
            caseId: _caseA,
            type: CaseTimelineEventType.emailIn,
            occurredAt: DateTime(2026, 5, 25, 12),
          ),
        ]);
      final c = makeContainer(fake);
      c.read(caseTimelineProvider(_caseA));
      await resolveAsync(c, caseTimelineProvider(_caseA));

      await c
          .read(caseTimelineProvider(_caseA).notifier)
          .deleteManualNote('note-1');

      final remaining = c.read(caseTimelineProvider(_caseA)).value!.events;
      expect(remaining, hasLength(1));
      expect(remaining.single.id, 'email-1');
      expect(fake.lastDeletedId, 'note-1');
    });
  });

  group('CaseTimelineFilter', () {
    final email = _evt(
      id: 'e',
      caseId: _caseA,
      type: CaseTimelineEventType.emailIn,
      occurredAt: DateTime(2026, 5, 25),
    );
    final consilium = _evt(
      id: 'c',
      caseId: _caseA,
      type: CaseTimelineEventType.consiliumDecision,
      occurredAt: DateTime(2026, 5, 25),
    );
    final deadline = _evt(
      id: 'd',
      caseId: _caseA,
      type: CaseTimelineEventType.deadlineSet,
      occurredAt: DateTime(2026, 5, 25),
    );
    final note = _evt(
      id: 'n',
      caseId: _caseA,
      type: CaseTimelineEventType.manualNote,
      occurredAt: DateTime(2026, 5, 25),
    );

    test('All accepts every type', () {
      for (final e in [email, consilium, deadline, note]) {
        expect(CaseTimelineFilter.all.accepts(e), isTrue);
      }
    });
    test('Emails matches in + out', () {
      expect(CaseTimelineFilter.emails.accepts(email), isTrue);
      expect(CaseTimelineFilter.emails.accepts(consilium), isFalse);
    });
    test('Consilium matches consilium_decision only', () {
      expect(CaseTimelineFilter.consilium.accepts(consilium), isTrue);
      expect(CaseTimelineFilter.consilium.accepts(email), isFalse);
    });
    test('Deadlines matches deadline_set only', () {
      expect(CaseTimelineFilter.deadlines.accepts(deadline), isTrue);
      expect(CaseTimelineFilter.deadlines.accepts(note), isFalse);
    });
    test('Notes matches manual_note only', () {
      expect(CaseTimelineFilter.notes.accepts(note), isTrue);
      expect(CaseTimelineFilter.notes.accepts(consilium), isFalse);
    });
  });

  group('CaseTimelineEvent.fromJson', () {
    test('parses canonical row shape', () {
      final e = CaseTimelineEvent.fromJson({
        'id': 'e1',
        'case_id': _caseA,
        'user_id': 'u1',
        'event_type': 'consilium_decision',
        'title': 'AI triage: HIGH',
        'summary': 'Reply now suggested',
        'payload': {'triage_id': 't1', 'severity': 'HIGH'},
        'occurred_at': '2026-05-25T12:00:00Z',
        'created_at': '2026-05-25T12:00:00Z',
      });
      expect(e.id, 'e1');
      expect(e.type, CaseTimelineEventType.consiliumDecision);
      expect(e.payload['severity'], 'HIGH');
    });

    test('coerces payload from String when PostgREST returns jsonb-as-text',
        () {
      final e = CaseTimelineEvent.fromJson({
        'id': 'e1',
        'case_id': _caseA,
        'user_id': 'u1',
        'event_type': 'email_in',
        'title': 'New email',
        'summary': null,
        'payload': '{"thread_id": "tid-1"}',
        'occurred_at': '2026-05-25T12:00:00Z',
        'created_at': '2026-05-25T12:00:00Z',
      });
      expect(e.payload['thread_id'], 'tid-1');
    });

    test('unknown event_type throws FormatException', () {
      expect(
        () => CaseTimelineEvent.fromJson({
          'id': 'e1',
          'case_id': _caseA,
          'user_id': 'u1',
          'event_type': 'totally_unknown',
          'title': 't',
          'summary': null,
          'payload': const <String, dynamic>{},
          'occurred_at': '2026-05-25T12:00:00Z',
          'created_at': '2026-05-25T12:00:00Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
