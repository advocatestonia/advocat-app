// Pure-Dart regression for the case-timeline model. Three user-visible
// surfaces are pinned here:
//   * CaseTimelineEventTypeX.dbValue/fromDb — the wire enum. fromDb THROWS on
//     an unknown value, so a backend that adds an 8th event_type would crash
//     the whole timeline parse rather than degrade — that contract is locked.
//   * CaseTimelineEvent.fromJson payload coercion — jsonb can arrive as a real
//     Map, a Map<dynamic,dynamic>, or jsonb-as-text (misconfigured PostgREST
//     view). A bug here silently drops payload (e.g. dedupe_key).
//   * CaseTimelineFilterX.accepts — the filter-chip predicate. A wrong `==`
//     silently hides events from the user's case timeline.

import 'package:advocat/features/cases/models/case_timeline_event.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({
  String eventType = 'manual_note',
  Object? payload,
  String? title,
  String? summary,
}) =>
    {
      'id': 'e1',
      'case_id': 'c1',
      'user_id': 'u1',
      'event_type': eventType,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (payload != null) 'payload': payload,
      'occurred_at': '2026-06-01T10:00:00Z',
      'created_at': '2026-06-01T10:00:01Z',
    };

void main() {
  group('CaseTimelineEventType wire', () {
    test('dbValue/fromDb round-trips every enum value', () {
      for (final t in CaseTimelineEventType.values) {
        expect(CaseTimelineEventTypeX.fromDb(t.dbValue), t);
      }
    });

    test('fromDb THROWS on an unknown event_type (fail-loud, not silent)', () {
      expect(
        () => CaseTimelineEventTypeX.fromDb('some_future_type'),
        throwsFormatException,
        reason: 'a new backend type must surface as a parse error, '
            'never silently map to a wrong/default kind',
      );
    });
  });

  group('CaseTimelineEvent.fromJson — payload coercion (jsonb defense)', () {
    test('reads a real Map<String,dynamic> payload', () {
      final e = CaseTimelineEvent.fromJson(
        _row(payload: {'dedupe_key': 'abc', 'n': 1}),
      );
      expect(e.payload['n'], 1);
      expect(e.dedupeKey, 'abc');
    });

    test('coerces a Map<dynamic,dynamic> payload', () {
      final dyn = <dynamic, dynamic>{'dedupe_key': 'k2'};
      final e = CaseTimelineEvent.fromJson(_row(payload: dyn));
      expect(e.dedupeKey, 'k2');
    });

    test('decodes jsonb-as-text (PostgREST view returning jsonb as String)',
        () {
      final e = CaseTimelineEvent.fromJson(
        _row(payload: '{"dedupe_key":"fromtext","x":true}'),
      );
      expect(e.dedupeKey, 'fromtext');
      expect(e.payload['x'], true);
    });

    test('malformed json string → empty payload (no throw)', () {
      final e = CaseTimelineEvent.fromJson(_row(payload: 'not json {{'));
      expect(e.payload, isEmpty);
      expect(e.dedupeKey, isNull);
    });

    test('non-string scalar / absent payload → empty map', () {
      expect(CaseTimelineEvent.fromJson(_row(payload: 42)).payload, isEmpty);
      expect(CaseTimelineEvent.fromJson(_row()).payload, isEmpty);
    });

    test('title defaults to empty string; summary stays nullable', () {
      final e = CaseTimelineEvent.fromJson(_row());
      expect(e.title, '');
      expect(e.summary, isNull);
      expect(e.type, CaseTimelineEventType.manualNote);
      expect(e.occurredAt.isUtc, isTrue);
    });
  });

  group('CaseTimelineFilterX.accepts', () {
    CaseTimelineEvent ev(CaseTimelineEventType t) => CaseTimelineEvent(
          id: 'e',
          caseId: 'c',
          userId: 'u',
          type: t,
          title: '',
          occurredAt: DateTime.utc(2026),
          createdAt: DateTime.utc(2026),
        );

    test('all accepts every event type', () {
      for (final t in CaseTimelineEventType.values) {
        expect(CaseTimelineFilter.all.accepts(ev(t)), isTrue);
      }
    });

    test('emails accepts only inbound + outbound email', () {
      expect(
          CaseTimelineFilter.emails.accepts(ev(CaseTimelineEventType.emailIn)),
          isTrue);
      expect(
          CaseTimelineFilter.emails.accepts(ev(CaseTimelineEventType.emailOut)),
          isTrue);
      expect(
          CaseTimelineFilter.emails
              .accepts(ev(CaseTimelineEventType.consiliumDecision)),
          isFalse);
    });

    test('consilium / deadlines / notes each accept exactly one type', () {
      expect(
          CaseTimelineFilter.consilium
              .accepts(ev(CaseTimelineEventType.consiliumDecision)),
          isTrue);
      expect(
          CaseTimelineFilter.deadlines
              .accepts(ev(CaseTimelineEventType.deadlineSet)),
          isTrue);
      expect(
          CaseTimelineFilter.notes
              .accepts(ev(CaseTimelineEventType.manualNote)),
          isTrue);
      // cross-checks: a deadline is not a note, a note is not consilium
      expect(
          CaseTimelineFilter.notes
              .accepts(ev(CaseTimelineEventType.deadlineSet)),
          isFalse);
      expect(
          CaseTimelineFilter.consilium
              .accepts(ev(CaseTimelineEventType.manualNote)),
          isFalse);
    });

    test('every (filter,type) pair is decided without throwing', () {
      for (final f in CaseTimelineFilter.values) {
        for (final t in CaseTimelineEventType.values) {
          expect(f.accepts(ev(t)), isA<bool>());
        }
      }
    });
  });
}
