@Tags(['fast'])
library;

// Unit tests for the Drafting Studio data layer (Pkg 7 MVP).
// -----------------------------------------------------------------------------
// Pure-data tests — no Flutter widget pump needed. Verifies:
//   * Wire-format enum round trips (source_type / status).
//   * Draft.fromJson tolerates nullable fields.
//   * markdownToPlaintext strips common syntax without nuking inner text.
//   * AiRevision.fromJson handles missing fields gracefully.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/drafting/models/draft_model.dart';

void main() {
  group('DraftSourceType', () {
    test('round-trips every enum value through .wire / .fromWire', () {
      for (final v in DraftSourceType.values) {
        expect(DraftSourceType.fromWire(v.wire), v);
      }
    });

    test('falls back to blank on unknown wire value', () {
      expect(DraftSourceType.fromWire('bogus'), DraftSourceType.blank);
      expect(DraftSourceType.fromWire(null), DraftSourceType.blank);
    });
  });

  group('DraftStatus', () {
    test('round-trips through .wire / .fromWire', () {
      for (final v in DraftStatus.values) {
        expect(DraftStatus.fromWire(v.wire), v);
      }
    });

    test('falls back to draft on unknown wire value', () {
      expect(DraftStatus.fromWire('weird'), DraftStatus.draft);
      expect(DraftStatus.fromWire(null), DraftStatus.draft);
    });
  });

  group('Draft.fromJson', () {
    test('parses a minimal row', () {
      final d = Draft.fromJson(<String, dynamic>{
        'id': 'a',
        'user_id': 'u',
        'case_id': null,
        'source_type': 'blank',
        'source_id': null,
        'title': null,
        'content_markdown': null,
        'content_plaintext': null,
        'language': null,
        'jurisdiction': null,
        'status': 'draft',
        'created_at': '2026-05-13T10:00:00Z',
        'updated_at': '2026-05-13T10:00:00Z',
        'metadata': null,
      });
      expect(d.id, 'a');
      expect(d.sourceType, DraftSourceType.blank);
      expect(d.status, DraftStatus.draft);
      expect(d.contentMarkdown, '');
      expect(d.metadata, isEmpty);
      expect(d.isEmpty, isTrue);
    });

    test('parses a Contract Review reply row', () {
      final d = Draft.fromJson(<String, dynamic>{
        'id': 'b',
        'user_id': 'u',
        'case_id': 'c1',
        'source_type': 'contract_review_reply',
        'source_id': 's1',
        'title': 'Reply to Acme',
        'content_markdown': 'Hello',
        'content_plaintext': 'Hello',
        'language': 'en',
        'jurisdiction': 'EE',
        'status': 'draft',
        'created_at': '2026-05-13T10:00:00Z',
        'updated_at': '2026-05-13T10:01:00Z',
        'metadata': <String, dynamic>{'foo': 'bar'},
      });
      expect(d.sourceType, DraftSourceType.contractReviewReply);
      expect(d.metadata['foo'], 'bar');
      expect(d.displayTitle(), 'Reply to Acme');
      expect(d.isEmpty, isFalse);
    });

    test('falls back to "Untitled" when title is blank', () {
      final d = Draft.fromJson(<String, dynamic>{
        'id': 'b',
        'user_id': 'u',
        'source_type': 'blank',
        'status': 'draft',
        'content_markdown': 'body',
        'content_plaintext': 'body',
        'created_at': '2026-05-13T10:00:00Z',
        'updated_at': '2026-05-13T10:00:00Z',
        'metadata': <String, dynamic>{},
      });
      expect(d.displayTitle(), 'Untitled');
      expect(d.displayTitle(untitledFallback: 'No title'), 'No title');
    });
  });

  group('markdownToPlaintext', () {
    test('strips bold, italic, headings, lists, code, links', () {
      const md =
          '# Heading\n\nThis is **bold** and *italic* and `code`.\n- bullet one\n- bullet two\n1. first\n2. second\n[link](https://example.com)';
      final plain = markdownToPlaintext(md);
      expect(plain.contains('Heading'), isTrue);
      expect(plain.contains('bold'), isTrue);
      expect(plain.contains('italic'), isTrue);
      expect(plain.contains('code'), isTrue);
      expect(plain.contains('bullet one'), isTrue);
      expect(plain.contains('first'), isTrue);
      expect(plain.contains('link'), isTrue);
      expect(plain.contains('https://example.com'), isFalse);
      expect(plain.contains('**'), isFalse);
      expect(plain.contains('# '), isFalse);
    });

    test('returns empty string for empty input', () {
      expect(markdownToPlaintext(''), '');
    });
  });

  group('AiRevision.fromJson', () {
    test('parses well-formed payload', () {
      final r = AiRevision.fromJson(<String, dynamic>{
        'revised_text': 'Hello.',
        'explanation': 'Added period.',
        'changes_made': ['Added period'],
      });
      expect(r.revisedText, 'Hello.');
      expect(r.explanation, 'Added period.');
      expect(r.changesMade.length, 1);
    });

    test('tolerates missing fields', () {
      final r = AiRevision.fromJson(<String, dynamic>{});
      expect(r.revisedText, '');
      expect(r.explanation, '');
      expect(r.changesMade, isEmpty);
    });

    test('filters non-string entries in changes_made', () {
      final r = AiRevision.fromJson(<String, dynamic>{
        'revised_text': 'x',
        'changes_made': <dynamic>['a', null, '', 'b', 42],
      });
      expect(r.changesMade, <String>['a', 'b']);
    });
  });
}
