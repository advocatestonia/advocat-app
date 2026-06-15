// Tests for the pure Document-Collection (Feature #4) model logic — parsing
// the RPC payload, computing collection progress, applying optimistic toggle
// + file-link updates, and the plain-text export. No Supabase / widget
// dependencies, so these run fast and isolated.
//
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/doc_collection/models/doc_requirement.dart';

Map<String, dynamic> _row({
  required String id,
  int sortOrder = 1,
  String title = 'Doc',
  bool optional = false,
  bool collected = false,
  String? documentId,
}) {
  return {
    'requirement_id': id,
    'sort_order': sortOrder,
    'title': title,
    'where_to_get': 'Some office',
    'why_needed': 'A reason',
    'optional': optional,
    'collected': collected,
    'document_id': documentId,
  };
}

void main() {
  group('DocProblemType', () {
    test('round-trips known keys', () {
      expect(DocProblemType.fromKey('residence_permit'),
          DocProblemType.residencePermit);
      expect(DocProblemType.fromKey('divorce'), DocProblemType.divorce);
      expect(DocProblemType.residencePermit.key, 'residence_permit');
    });

    test('returns null for unknown / null keys', () {
      expect(DocProblemType.fromKey('nope'), isNull);
      expect(DocProblemType.fromKey(null), isNull);
    });
  });

  group('DocRequirement.fromJson', () {
    test('parses a full row', () {
      final r = DocRequirement.fromJson(_row(
        id: 'a',
        sortOrder: 3,
        title: 'Passport',
        optional: true,
        collected: true,
        documentId: 'doc-1',
      ));
      expect(r.requirementId, 'a');
      expect(r.sortOrder, 3);
      expect(r.title, 'Passport');
      expect(r.optional, isTrue);
      expect(r.collected, isTrue);
      expect(r.hasLinkedDocument, isTrue);
      expect(r.documentId, 'doc-1');
    });

    test('tolerates missing optional fields', () {
      final r = DocRequirement.fromJson({'requirement_id': 'x'});
      expect(r.requirementId, 'x');
      expect(r.title, '');
      expect(r.optional, isFalse);
      expect(r.collected, isFalse);
      expect(r.hasLinkedDocument, isFalse);
    });

    test('empty document_id does not count as linked', () {
      final r = DocRequirement.fromJson(_row(id: 'a', documentId: ''));
      expect(r.hasLinkedDocument, isFalse);
    });
  });

  group('DocRequirementSet.fromRpc + progress', () {
    test('sorts by sort_order and computes progress', () {
      final set = DocRequirementSet.fromRpc([
        _row(id: 'b', sortOrder: 2, collected: true),
        _row(id: 'a', sortOrder: 1, collected: false),
        _row(id: 'c', sortOrder: 3, collected: true),
      ]);
      expect(set.items.map((i) => i.requirementId), ['a', 'b', 'c']);
      expect(set.total, 3);
      expect(set.collected, 2);
      expect(set.progress, closeTo(2 / 3, 1e-9));
      expect(set.allCollected, isFalse);
    });

    test('empty list -> empty set, no NaN progress', () {
      final set = DocRequirementSet.fromRpc([]);
      expect(set.isEmpty, isTrue);
      expect(set.progress, 0);
      expect(set.allCollected, isFalse);
    });

    test('non-list input -> empty', () {
      expect(DocRequirementSet.fromRpc('oops').isEmpty, isTrue);
      expect(DocRequirementSet.fromRpc(null).isEmpty, isTrue);
    });

    test('all collected flips allCollected', () {
      final set = DocRequirementSet.fromRpc([
        _row(id: 'a', sortOrder: 1, collected: true),
        _row(id: 'b', sortOrder: 2, collected: true),
      ]);
      expect(set.allCollected, isTrue);
      expect(set.progress, 1.0);
    });
  });

  group('withCollected', () {
    test('flips only the targeted requirement', () {
      final set = DocRequirementSet.fromRpc([
        _row(id: 'a', sortOrder: 1, collected: false),
        _row(id: 'b', sortOrder: 2, collected: false),
      ]);
      final next = set.withCollected('a', true);
      expect(next.items[0].collected, isTrue);
      expect(next.items[1].collected, isFalse);
      // Original is unchanged (immutability).
      expect(set.items[0].collected, isFalse);
    });
  });

  group('withLinkedDocument', () {
    test('linking a file marks the row collected', () {
      final set = DocRequirementSet.fromRpc([
        _row(id: 'a', sortOrder: 1, collected: false),
      ]);
      final next = set.withLinkedDocument('a', 'doc-9');
      expect(next.items[0].documentId, 'doc-9');
      expect(next.items[0].collected, isTrue);
      expect(next.items[0].hasLinkedDocument, isTrue);
    });

    test('clearing a file keeps collected but drops the link', () {
      final set = DocRequirementSet.fromRpc([
        _row(id: 'a', sortOrder: 1, collected: true, documentId: 'doc-9'),
      ]);
      final cleared = set.withLinkedDocument('a', null);
      expect(cleared.items[0].documentId, isNull);
      expect(cleared.items[0].hasLinkedDocument, isFalse);
      expect(cleared.items[0].collected, isTrue);
    });

    test('empty string id is treated as clear', () {
      final set = DocRequirementSet.fromRpc([
        _row(id: 'a', sortOrder: 1, documentId: 'doc-9'),
      ]);
      final cleared = set.withLinkedDocument('a', '');
      expect(cleared.items[0].hasLinkedDocument, isFalse);
    });
  });

  group('toPlainText export', () {
    test('renders check state, optional tag, where + why', () {
      final set = DocRequirementSet.fromRpc([
        _row(id: 'a', sortOrder: 1, title: 'Passport', collected: true),
        _row(
          id: 'b',
          sortOrder: 2,
          title: 'Family proof',
          optional: true,
          collected: false,
        ),
      ]);
      final text = set.toPlainText();
      expect(text, contains('[x] Passport'));
      expect(text, contains('[ ] Family proof (optional)'));
      expect(text, contains('Where: Some office'));
      expect(text, contains('Why: A reason'));
    });
  });

  group('DocSuggestion.fromJson', () {
    test('parses an AI suggestion', () {
      final s = DocSuggestion.fromJson({
        'title': 'Tax certificate',
        'where_to_get': 'Tax office',
        'why_needed': 'Proves residency',
      });
      expect(s.title, 'Tax certificate');
      expect(s.whereToGet, 'Tax office');
      expect(s.whyNeeded, 'Proves residency');
    });
  });
}
