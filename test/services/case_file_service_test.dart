// case_file_service_test.dart
// -----------------------------------------------------------------------------
// Tests the pure logic of CaseFileService (diff/dedupe + dossier markdown).
// Network-backed CRUD is exercised by integration tests against a live
// Supabase test project — unit-tests stay hermetic.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/models/case_file.dart';
import 'package:advocat/services/case_file_service.dart';

void main() {
  group('CaseFileService.diffEvents', () {
    test('returns all incoming when no existing rows', () {
      final incoming = [
        CaseEvent(date: DateTime(2026, 4, 12), title: 'PPA decision'),
      ];
      final out = CaseFileService.diffEvents(incoming, const []);
      expect(out, hasLength(1));
    });

    test('drops events that match an existing dedupe key', () {
      final incoming = [
        CaseEvent(date: DateTime(2026, 4, 12), title: 'PPA Decision'),
        CaseEvent(date: DateTime(2026, 4, 13), title: 'New event'),
      ];
      final existing = [
        CaseEvent(date: DateTime(2026, 4, 12), title: 'ppa decision'),
      ];
      final out = CaseFileService.diffEvents(incoming, existing);
      expect(out, hasLength(1));
      expect(out.first.title, 'New event');
    });

    test('dedupes within the same incoming batch too', () {
      final incoming = [
        CaseEvent(date: DateTime(2026, 4, 12), title: 'X'),
        CaseEvent(date: DateTime(2026, 4, 12), title: 'X'),
      ];
      final out = CaseFileService.diffEvents(incoming, const []);
      expect(out, hasLength(1));
    });
  });

  group('CaseFileService.diffParties', () {
    test('skips party that exists with same type+name', () {
      final incoming = [
        CaseParty(name: 'PPA', type: PartyType.authority),
        CaseParty(name: 'Bolt OÜ', type: PartyType.company),
      ];
      final existing = [CaseParty(name: 'ppa', type: PartyType.authority)];
      final out = CaseFileService.diffParties(incoming, existing);
      expect(out, hasLength(1));
      expect(out.first.name, 'Bolt OÜ');
    });

    test('keeps same name with different type', () {
      final incoming = [CaseParty(name: 'X', type: PartyType.company)];
      final existing = [CaseParty(name: 'X', type: PartyType.person)];
      final out = CaseFileService.diffParties(incoming, existing);
      expect(out, hasLength(1));
    });
  });

  group('CaseFileService.diffDeadlines', () {
    test('skips matching (date,title) deadlines', () {
      final incoming = [
        CaseDeadline(date: DateTime(2026, 5, 12), title: 'Vaie'),
        CaseDeadline(date: DateTime(2026, 6, 1), title: 'Hearing'),
      ];
      final existing = [
        CaseDeadline(date: DateTime(2026, 5, 12), title: 'vaie'),
      ];
      final out = CaseFileService.diffDeadlines(incoming, existing);
      expect(out, hasLength(1));
      expect(out.first.title, 'Hearing');
    });
  });

  group('CaseFileService.buildDossierMarkdown', () {
    final today = DateTime(2026, 5, 1);

    test('renders title, generated date, key facts', () {
      final md = CaseFileService.buildDossierMarkdownForTest(
        events: const [],
        parties: const [],
        deadlines: const [],
        keyFacts: const [
          CaseKeyFact(key: 'case_number', value: '5500/R/75170/25'),
          CaseKeyFact(key: 'jurisdiction', value: 'EE'),
        ],
        today: today,
        locale: 'en',
      );
      expect(md, contains('# Case File'));
      expect(md, contains('Generated: 2026-05-01'));
      expect(md, contains('case_number'));
      expect(md, contains('5500/R/75170/25'));
    });

    test('renders deadlines with countdown', () {
      final md = CaseFileService.buildDossierMarkdownForTest(
        events: const [],
        parties: const [],
        deadlines: [
          CaseDeadline(
            date: DateTime(2026, 5, 12),
            title: 'Vaie',
            law: 'HMS § 75 lg 1',
          ),
        ],
        today: today,
        locale: 'en',
      );
      expect(md, contains('## Deadlines'));
      expect(md, contains('Vaie'));
      expect(md, contains('11d'));
      expect(md, contains('HMS § 75 lg 1'));
    });

    test('renders timeline ascending by date', () {
      final md = CaseFileService.buildDossierMarkdownForTest(
        events: [
          CaseEvent(date: DateTime(2026, 4, 13), title: 'B'),
          CaseEvent(date: DateTime(2026, 4, 12), title: 'A'),
        ],
        parties: const [],
        deadlines: const [],
        today: today,
        locale: 'en',
      );
      final aIdx = md.indexOf('A');
      final bIdx = md.indexOf('B');
      expect(aIdx, greaterThan(0));
      expect(aIdx, lessThan(bIdx));
    });

    test('renders Estonian disclaimer when locale=et', () {
      final md = CaseFileService.buildDossierMarkdownForTest(
        events: const [],
        parties: const [],
        deadlines: const [],
        keyFacts: const [CaseKeyFact(key: 'a', value: 'b')],
        today: today,
        locale: 'et',
      );
      expect(md, contains('# Toimik'));
      expect(md, contains('vandeadvokaadiga'));
    });

    test('renders Russian disclaimer when locale=ru', () {
      final md = CaseFileService.buildDossierMarkdownForTest(
        events: const [],
        parties: const [],
        deadlines: const [],
        keyFacts: const [CaseKeyFact(key: 'a', value: 'b')],
        today: today,
        locale: 'ru',
      );
      expect(md, contains('# Досье'));
      expect(md, contains('адвокату'));
    });

    test('marks overdue deadlines with negative count', () {
      final md = CaseFileService.buildDossierMarkdownForTest(
        events: const [],
        parties: const [],
        deadlines: [
          CaseDeadline(date: DateTime(2026, 4, 1), title: 'Late one'),
        ],
        today: today,
        locale: 'en',
      );
      expect(md, contains('Late one'));
      expect(md, contains('overdue'));
      expect(md, contains('30d'));
    });

    test('skips empty sections', () {
      final md = CaseFileService.buildDossierMarkdownForTest(
        events: const [],
        parties: const [],
        deadlines: const [],
        today: today,
        locale: 'en',
      );
      expect(md.contains('## Deadlines'), isFalse);
      expect(md.contains('## Timeline'), isFalse);
      expect(md.contains('## Parties'), isFalse);
      // Title and disclaimer always present
      expect(md, contains('# Case File'));
    });
  });

  group('CaseFileExtractor short-circuits (pure logic)', () {
    // We don't hit Claude in unit tests — we just verify that an empty
    // extraction is the correct fallback for tiny turns.
    test('CaseFileExtraction.empty has zero items in every list', () {
      expect(CaseFileExtraction.empty.events, isEmpty);
      expect(CaseFileExtraction.empty.parties, isEmpty);
      expect(CaseFileExtraction.empty.deadlines, isEmpty);
      expect(CaseFileExtraction.empty.documents, isEmpty);
      expect(CaseFileExtraction.empty.keyFacts, isEmpty);
      expect(CaseFileExtraction.empty.isEmpty, isTrue);
    });
  });
}
