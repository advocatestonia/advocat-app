@Tags(['fast'])
library;

// Unit tests for the Legal Template Library models (Feature #5).
// -----------------------------------------------------------------------------
// Pure parsing + helper logic — no Flutter widgets, no Supabase.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/legal_templates/models/legal_template.dart';

void main() {
  group('LegalTemplate.fromJson', () {
    test('parses a full row', () {
      final t = LegalTemplate.fromJson(<String, dynamic>{
        'id': 'abc',
        'slug': 'fi_kantelu_poliisi',
        'category': 'complaint',
        'jurisdiction': 'FI',
        'locale': 'fi',
        'title': 'Kantelu',
        'description': 'desc',
        'body_markdown': 'Hi {{full_name}}',
        'required_fields': <dynamic>['recipient', 'subject'],
        'auto_fields': <dynamic>['full_name', 'today'],
        'is_sample': true,
        'sort_order': 10,
      });
      expect(t.slug, 'fi_kantelu_poliisi');
      expect(t.jurisdiction, 'FI');
      expect(t.requiredFields, <String>['recipient', 'subject']);
      expect(t.autoFields, <String>['full_name', 'today']);
      expect(t.isSample, true);
      expect(t.sortOrder, 10);
    });

    test('tolerates missing/odd fields with defaults', () {
      final t = LegalTemplate.fromJson(<String, dynamic>{
        'id': 'x',
        'slug': 's',
      });
      expect(t.category, 'request');
      expect(t.jurisdiction, 'FI');
      expect(t.locale, 'fi');
      expect(t.requiredFields, isEmpty);
      expect(t.isSample, true);
    });

    test('non-string entries in field arrays are dropped', () {
      final t = LegalTemplate.fromJson(<String, dynamic>{
        'id': 'x',
        'slug': 's',
        'required_fields': <dynamic>['ok', 1, null, 'fine'],
      });
      expect(t.requiredFields, <String>['ok', 'fine']);
    });
  });

  group('FilledTemplate.fromJson', () {
    test('parses edge-function response', () {
      final f = FilledTemplate.fromJson(<String, dynamic>{
        'filled': 'Dear Police, I am Jane.',
        'title': 'Kantelu',
        'slug': 'fi_kantelu_poliisi',
        'jurisdiction': 'FI',
        'locale': 'fi',
        'tokens': <dynamic>['recipient', 'full_name'],
        'resolved': <dynamic>['recipient', 'full_name'],
        'unresolved': <dynamic>[],
        'required_fields': <dynamic>['recipient'],
      });
      expect(f.filled, 'Dear Police, I am Jane.');
      expect(f.unresolved, isEmpty);
      expect(f.resolved.length, 2);
    });

    test('defaults when fields absent', () {
      final f = FilledTemplate.fromJson(<String, dynamic>{});
      expect(f.filled, '');
      expect(f.tokens, isEmpty);
      expect(f.unresolved, isEmpty);
    });
  });

  group('humanizeToken', () {
    test('converts snake_case to a readable label', () {
      expect(humanizeToken('case_number'), 'Case number');
      expect(humanizeToken('recipient'), 'Recipient');
      expect(humanizeToken('migri_ref'), 'Migri ref');
    });

    test('handles empty + single-char tokens', () {
      expect(humanizeToken(''), '');
      expect(humanizeToken('a'), 'A');
    });
  });
}
