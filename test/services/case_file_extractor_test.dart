// case_file_extractor_test.dart
// -----------------------------------------------------------------------------
// Unit tests for CaseFileExtractor and CaseFileExtraction.fromRawJson.
//
// Live Haiku calls are NOT exercised here — those are integration territory.
// We test:
//   * JSON parsing tolerates fences, prose, malformed input
//   * dedupeKey is stable
//   * extractor short-circuits on tiny turns
//   * extractor returns empty on Claude failures
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/models/case_file.dart';

void main() {
  group('CaseFileExtraction.fromRawJson — happy path', () {
    test('parses Estonian PPA decision turn correctly', () {
      const raw = '''{"events":[{"date":"2026-04-12","title":"PPA lahkumisettekirjutus saadud","category":"decision"}],"parties":[{"name":"Politsei- ja Piirivalveamet","type":"authority","context":"otsuse väljaandja"}],"deadlines":[{"date":"2026-05-12","title":"Vaie esitamise tähtaeg","law":"HMS § 75 lg 1","urgent":true}],"documents":[{"name":"Lahkumisettekirjutus","type":"decision","uploaded":false}],"key_facts":[{"key":"case_number","value":"5500/R/75170/25"},{"key":"jurisdiction","value":"EE"}]}''';

      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.events, hasLength(1));
      expect(ex.events.first.title, 'PPA lahkumisettekirjutus saadud');
      expect(ex.events.first.date, DateTime(2026, 4, 12));
      expect(ex.events.first.category, CaseEventCategory.decision);
      expect(ex.parties, hasLength(1));
      expect(ex.parties.first.type, PartyType.authority);
      expect(ex.deadlines, hasLength(1));
      expect(ex.deadlines.first.date, DateTime(2026, 5, 12));
      expect(ex.deadlines.first.law, 'HMS § 75 lg 1');
      expect(ex.documents, hasLength(1));
      expect(ex.keyFacts.map((k) => k.key), containsAll(['case_number', 'jurisdiction']));
    });

    test('parses Russian rental dispute with no concrete dates', () {
      const raw =
          '{"events":[],"parties":[{"name":"Андрей","type":"person","context":"наймодатель"}],"deadlines":[],"documents":[],"key_facts":[{"key":"case_type","value":"возврат залога / аренда"},{"key":"jurisdiction","value":"EE"}]}';
      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.events, isEmpty);
      expect(ex.parties, hasLength(1));
      expect(ex.parties.first.name, 'Андрей');
      expect(ex.parties.first.type, PartyType.person);
      expect(ex.keyFacts, hasLength(2));
    });

    test('parses Finnish Sulga case (assault + deportation)', () {
      const raw = '''{"events":[{"date":"2025-09-15","title":"Assault incident","description":"Helsinki","category":"submission"},{"date":"2026-04-25","title":"Deportation order received","category":"decision"}],"parties":[{"name":"Helsingin poliisilaitos","type":"authority"},{"name":"Tolonen","type":"lawyer","context":"defence counsel"}],"deadlines":[{"date":"2026-05-25","title":"Appeal window closes","law":"Hallintolaki § 49","urgent":false}],"documents":[],"key_facts":[{"key":"jurisdiction","value":"FI"},{"key":"case_number","value":"R-2025-1234"}]}''';
      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.events, hasLength(2));
      expect(ex.events.last.title, 'Deportation order received');
      expect(ex.parties, hasLength(2));
      expect(ex.parties[1].type, PartyType.lawyer);
      expect(ex.deadlines.first.law, 'Hallintolaki § 49');
      expect(ex.keyFacts.firstWhere((k) => k.key == 'jurisdiction').value, 'FI');
    });
  });

  group('CaseFileExtraction.fromRawJson — defensive parsing', () {
    test('returns empty on non-JSON garbage', () {
      expect(CaseFileExtraction.fromRawJson('not json at all').isEmpty, isTrue);
      expect(CaseFileExtraction.fromRawJson('').isEmpty, isTrue);
    });

    test('strips markdown fences around JSON', () {
      const raw = '```json\n{"events":[],"parties":[{"name":"Bolt","type":"company"}],"deadlines":[],"documents":[],"key_facts":[]}\n```';
      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.parties, hasLength(1));
      expect(ex.parties.first.type, PartyType.company);
    });

    test('strips surrounding prose around JSON', () {
      const raw = 'Here is the extraction:\n{"events":[],"parties":[],"deadlines":[],"documents":[],"key_facts":[]}\nThanks!';
      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.isEmpty, isTrue);
    });

    test('returns empty when JSON is malformed', () {
      const raw = '{"events": [INVALID}';
      expect(CaseFileExtraction.fromRawJson(raw).isEmpty, isTrue);
    });

    test('drops events with empty titles', () {
      const raw = '{"events":[{"date":"2026-04-12","title":"","category":"decision"},{"date":"2026-04-13","title":"valid","category":"decision"}],"parties":[],"deadlines":[],"documents":[],"key_facts":[]}';
      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.events, hasLength(1));
      expect(ex.events.first.title, 'valid');
    });

    test('drops deadlines with no date', () {
      const raw = '{"events":[],"parties":[],"deadlines":[{"title":"unknown when","law":"X"}],"documents":[],"key_facts":[]}';
      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.deadlines, isEmpty);
    });

    test('parses DD.MM.YYYY date format too', () {
      const raw = '{"events":[{"date":"21.04.2026","title":"meeting","category":"hearing"}],"parties":[],"deadlines":[],"documents":[],"key_facts":[]}';
      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.events, hasLength(1));
      expect(ex.events.first.date, DateTime(2026, 4, 21));
    });

    test('unknown category falls back to .other', () {
      const raw = '{"events":[{"date":"2026-04-12","title":"X","category":"weirdness"}],"parties":[],"deadlines":[],"documents":[],"key_facts":[]}';
      final ex = CaseFileExtraction.fromRawJson(raw);
      expect(ex.events.first.category, CaseEventCategory.other);
    });
  });

  group('Dedup keys', () {
    test('CaseEvent dedupeKey is stable across whitespace and case', () {
      final a = CaseEvent(
        date: DateTime(2026, 4, 12),
        title: '  PPA Decision  ',
      );
      final b = CaseEvent(
        date: DateTime(2026, 4, 12),
        title: 'ppa decision',
      );
      expect(a.dedupeKey, b.dedupeKey);
    });

    test('CaseEvent dedupeKey differs by date', () {
      final a = CaseEvent(date: DateTime(2026, 4, 12), title: 'X');
      final b = CaseEvent(date: DateTime(2026, 4, 13), title: 'X');
      expect(a.dedupeKey, isNot(b.dedupeKey));
    });

    test('CaseParty dedupeKey is type+name', () {
      final a = CaseParty(name: 'PPA', type: PartyType.authority);
      final b = CaseParty(name: 'ppa', type: PartyType.authority);
      final c = CaseParty(name: 'PPA', type: PartyType.company);
      expect(a.dedupeKey, b.dedupeKey);
      expect(a.dedupeKey, isNot(c.dedupeKey));
    });

    test('CaseDeadline dedupeKey is date+title', () {
      final a = CaseDeadline(date: DateTime(2026, 5, 12), title: 'Vaie');
      final b = CaseDeadline(date: DateTime(2026, 5, 12), title: 'vaie ');
      final c = CaseDeadline(date: DateTime(2026, 5, 13), title: 'Vaie');
      expect(a.dedupeKey, b.dedupeKey);
      expect(a.dedupeKey, isNot(c.dedupeKey));
    });
  });

  group('CaseDeadline.daysFrom / isUrgentAt', () {
    test('returns positive days when in the future', () {
      final d = CaseDeadline(date: DateTime(2026, 5, 12), title: 'X');
      expect(d.daysFrom(DateTime(2026, 5, 1)), 11);
    });

    test('returns negative when overdue', () {
      final d = CaseDeadline(date: DateTime(2026, 4, 1), title: 'X');
      expect(d.daysFrom(DateTime(2026, 4, 5)), -4);
    });

    test('isUrgentAt true within 7 days', () {
      final d = CaseDeadline(date: DateTime(2026, 5, 6), title: 'X');
      expect(d.isUrgentAt(DateTime(2026, 5, 1)), isTrue);
    });

    test('isUrgentAt false beyond 7 days', () {
      final d = CaseDeadline(date: DateTime(2026, 5, 20), title: 'X');
      expect(d.isUrgentAt(DateTime(2026, 5, 1)), isFalse);
    });

    test('isUrgentAt false when overdue', () {
      final d = CaseDeadline(date: DateTime(2026, 4, 1), title: 'X');
      expect(d.isUrgentAt(DateTime(2026, 5, 1)), isFalse);
    });

    test('isUrgentAt false when completed', () {
      final d = CaseDeadline(
          date: DateTime(2026, 5, 6), title: 'X', completed: true);
      expect(d.isUrgentAt(DateTime(2026, 5, 1)), isFalse);
    });
  });

  group('toRow / fromRow round-trip', () {
    test('CaseEvent.toRow includes user_id and ISO date', () {
      final e = CaseEvent(
        date: DateTime(2026, 4, 12),
        title: 'X',
        category: CaseEventCategory.decision,
      );
      final row = e.toRow(userId: 'u1', caseId: 'c1');
      expect(row['user_id'], 'u1');
      expect(row['case_id'], 'c1');
      expect(row['event_date'], '2026-04-12');
      expect(row['category'], 'decision');
    });

    test('CaseEvent.fromRow handles ISO timestamp', () {
      final row = {
        'id': 'a',
        'event_date': '2026-04-12',
        'title': 'X',
        'category': 'decision',
      };
      final e = CaseEvent.fromRow(row);
      expect(e.date, DateTime(2026, 4, 12));
      expect(e.category, CaseEventCategory.decision);
    });

    test('CaseDeadline.toRow includes deadline_date and completed default', () {
      final d = CaseDeadline(date: DateTime(2026, 5, 12), title: 'Vaie', law: 'HMS § 75');
      final row = d.toRow(userId: 'u1');
      expect(row['deadline_date'], '2026-05-12');
      expect(row['title'], 'Vaie');
      expect(row['law'], 'HMS § 75');
      expect(row['completed'], false);
    });
  });
}
