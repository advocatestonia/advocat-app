import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round-trip JSON for [UserCase] and its nested types.
///
/// The DB row shape is the SOURCE of truth — see migration
/// `20260506100000_case_memory.sql` for column types. JSONB arrays of objects
/// (`case_numbers`, `parties`, `key_dates`, `authorities`, `timeline`,
/// `open_questions`, `next_actions`) MUST round-trip through fromJson/toJson
/// without data loss so Pkg 1.B's `load_active_case` RPC output is
/// faithfully decoded on the client.
void main() {
  group('UserCase round-trip', () {
    test('decodes a minimal Supabase row', () {
      final row = {
        'id': '11111111-1111-1111-1111-111111111111',
        'user_id': '22222222-2222-2222-2222-222222222222',
        'title': 'Sulga FI deportation',
        'jurisdiction': 'FI',
        'case_type': 'deportation',
        'status': 'active',
        'case_numbers': [],
        'parties': [],
        'key_dates': [],
        'authorities': [],
        'timeline': [],
        'open_questions': [],
        'next_actions': [],
        'summary': null,
        'language': 'ru',
        'created_at': '2026-05-05T12:00:00Z',
        'updated_at': '2026-05-05T12:00:00Z',
      };

      final c = UserCase.fromJson(row);

      expect(c.id, '11111111-1111-1111-1111-111111111111');
      expect(c.userId, '22222222-2222-2222-2222-222222222222');
      expect(c.title, 'Sulga FI deportation');
      expect(c.jurisdiction, 'FI');
      expect(c.caseType, 'deportation');
      expect(c.status, CaseMemoryStatus.active);
      expect(c.language, 'ru');
      expect(c.summary, isNull);
      expect(c.caseNumbers, isEmpty);
      expect(c.parties, isEmpty);
      expect(c.keyDates, isEmpty);
      expect(c.authorities, isEmpty);
      expect(c.timeline, isEmpty);
      expect(c.openQuestions, isEmpty);
      expect(c.nextActions, isEmpty);
    });

    test('round-trips populated jsonb arrays without loss', () {
      final row = {
        'id': '11111111-1111-1111-1111-111111111111',
        'user_id': '22222222-2222-2222-2222-222222222222',
        'title': 'Test case',
        'jurisdiction': 'EE',
        'case_type': 'criminal',
        'status': 'active',
        'case_numbers': [
          {'authority': 'Politsei', 'number': 'R-123/45', 'role': 'against'},
        ],
        'parties': [
          {'role': 'victim', 'name': 'Sofia Sulga', 'note': null},
        ],
        'key_dates': [
          {'label': 'incident', 'date': '2025-08-01', 'note': null},
        ],
        'authorities': [
          {'name': 'Helsinki politsei', 'contact': 'kirjaamo@poliisi.fi'},
        ],
        'timeline': [
          {'date': '2025-08-01', 'event': 'arrest'},
        ],
        'open_questions': [
          {'question': 'Is appeal still possible?', 'priority': 'high'},
        ],
        'next_actions': [
          {'action': 'File hallinto-oikeus appeal', 'due': '2026-01-04'},
        ],
        'summary': 'Deportation case from Finland',
        'language': 'ru',
        'created_at': '2026-05-05T12:00:00Z',
        'updated_at': '2026-05-05T12:30:00Z',
      };

      final c = UserCase.fromJson(row);
      final back = c.toJson();

      // The fields we control must be byte-equivalent on the way back.
      expect(back['title'], row['title']);
      expect(back['jurisdiction'], row['jurisdiction']);
      expect(back['case_type'], row['case_type']);
      expect(back['status'], row['status']);
      expect(back['language'], row['language']);
      expect(back['summary'], row['summary']);
      expect(back['case_numbers'], row['case_numbers']);
      expect(back['parties'], row['parties']);
      expect(back['key_dates'], row['key_dates']);
      expect(back['authorities'], row['authorities']);
      expect(back['timeline'], row['timeline']);
      expect(back['open_questions'], row['open_questions']);
      expect(back['next_actions'], row['next_actions']);
    });

    test('parses status closed/archived', () {
      for (final entry in {
        'archived': CaseMemoryStatus.archived,
        'closed': CaseMemoryStatus.closed,
      }.entries) {
        final row = _baseRow()..['status'] = entry.key;
        expect(UserCase.fromJson(row).status, entry.value,
            reason: 'status=${entry.key}');
      }
    });

    test('falls back to active for unknown status', () {
      final row = _baseRow()..['status'] = 'something-weird';
      expect(UserCase.fromJson(row).status, CaseMemoryStatus.active);
    });

    test('copyWith updates a single field', () {
      final c = UserCase.fromJson(_baseRow());
      final updated = c.copyWith(title: 'New title');
      expect(updated.title, 'New title');
      expect(updated.id, c.id);
      expect(updated.jurisdiction, c.jurisdiction);
    });

    test('CaseNumber/Party/KeyDate/Authority/TimelineEntry/OpenQuestion/'
        'NextAction round-trip individually', () {
      final cn = CaseNumber(authority: 'A', number: 'R-1', role: 'for');
      expect(CaseNumber.fromJson(cn.toJson()), cn);

      final p = Party(role: 'victim', name: 'X', note: 'note');
      expect(Party.fromJson(p.toJson()), p);

      final kd = KeyDate(label: 'incident', date: '2025-01-01', note: null);
      expect(KeyDate.fromJson(kd.toJson()), kd);

      final auth = Authority(name: 'Police', contact: 'a@b');
      expect(Authority.fromJson(auth.toJson()), auth);

      final t = TimelineEntry(date: '2025-01-01', event: 'event');
      expect(TimelineEntry.fromJson(t.toJson()), t);

      final oq = OpenQuestion(question: 'q?', priority: 'high');
      expect(OpenQuestion.fromJson(oq.toJson()), oq);

      final na = NextAction(action: 'do x', due: '2025-02-01');
      expect(NextAction.fromJson(na.toJson()), na);
    });
  });
}

Map<String, dynamic> _baseRow() => {
      'id': '11111111-1111-1111-1111-111111111111',
      'user_id': '22222222-2222-2222-2222-222222222222',
      'title': 'Test',
      'jurisdiction': 'EE',
      'case_type': 'civil',
      'status': 'active',
      'case_numbers': [],
      'parties': [],
      'key_dates': [],
      'authorities': [],
      'timeline': [],
      'open_questions': [],
      'next_actions': [],
      'summary': null,
      'language': 'ru',
      'created_at': '2026-05-05T12:00:00Z',
      'updated_at': '2026-05-05T12:00:00Z',
    };
