// Unit tests for the Plain-Language Explainer response model (pure parsing).
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/plain_language/models/explain_result.dart';

void main() {
  group('ExplainLevel', () {
    test('round-trips wire values', () {
      expect(ExplainLevel.friend.wire, 'friend');
      expect(ExplainLevel.withTerms.wire, 'with_terms');
      expect(ExplainLevel.fromWire('with_terms'), ExplainLevel.withTerms);
      expect(ExplainLevel.fromWire('friend'), ExplainLevel.friend);
      // Unknown / null defaults to friend.
      expect(ExplainLevel.fromWire(null), ExplainLevel.friend);
      expect(ExplainLevel.fromWire('garbage'), ExplainLevel.friend);
    });
  });

  group('ExplainBody.fromJson', () {
    test('parses a full body', () {
      final body = ExplainBody.fromJson(<String, dynamic>{
        'tldr': ['You must reply within 30 days.'],
        'paragraphs': [
          {'heading': 'Decision', 'plain': 'Your permit was refused.'},
        ],
        'glossary': [
          {
            'term': 'käännytys',
            'plain': 'removal from the country',
            'ref': 'fi-ulkomaalaislaki:148',
          },
        ],
        'next_steps': ['You may appeal to the administrative court.'],
      });

      expect(body.tldr.length, 1);
      expect(body.paragraphs.single.heading, 'Decision');
      expect(body.glossary.single.ref, 'fi-ulkomaalaislaki:148');
      expect(body.nextSteps.length, 1);
      expect(body.isEmpty, isFalse);
    });

    test('drops malformed paragraph and glossary rows', () {
      final body = ExplainBody.fromJson(<String, dynamic>{
        'tldr': ['ok', 42, '', '  keep  '],
        'paragraphs': [
          {'heading': 'H', 'plain': 'good'},
          {'heading': 'no-plain'}, // dropped
          'not-a-map', // dropped
          {'plain': ''}, // dropped (empty)
        ],
        'glossary': [
          {'term': 'a', 'plain': 'x'},
          {'term': '', 'plain': 'y'}, // dropped (empty term)
          {'term': 'b'}, // dropped (no plain)
          {'term': 'c', 'plain': 'z', 'ref': '   '}, // blank ref omitted
        ],
        'next_steps': ['step'],
      });

      expect(body.tldr, ['ok', 'keep']);
      expect(body.paragraphs.length, 1);
      expect(body.glossary.length, 2);
      expect(body.glossary[1].ref, isNull);
    });

    test('defaults missing sections to empty', () {
      final body = ExplainBody.fromJson(<String, dynamic>{'tldr': ['only']});
      expect(body.paragraphs, isEmpty);
      expect(body.glossary, isEmpty);
      expect(body.nextSteps, isEmpty);
    });

    test('isEmpty true when everything is absent', () {
      final body = ExplainBody.fromJson(const <String, dynamic>{});
      expect(body.isEmpty, isTrue);
    });
  });

  group('ExplainQuota', () {
    test('free tier reports limits, isPro false', () {
      final q = ExplainQuota.fromJson(
        const <String, dynamic>{'used': 2, 'limit': 3, 'tier': 'free'},
      );
      expect(q.used, 2);
      expect(q.limit, 3);
      expect(q.isPro, isFalse);
    });

    test('paid tier reports nulls, isPro true', () {
      final q = ExplainQuota.fromJson(
        const <String, dynamic>{'used': null, 'limit': null, 'tier': 'premium'},
      );
      expect(q.isPro, isTrue);
    });

    test('defaults tier to free', () {
      final q = ExplainQuota.fromJson(const <String, dynamic>{});
      expect(q.tier, 'free');
      expect(q.isPro, isFalse);
    });
  });

  group('ExplainResult.fromJson', () {
    test('parses the top-level envelope', () {
      final r = ExplainResult.fromJson(<String, dynamic>{
        'explain_request_id': 'req-1',
        'language': 'fi',
        'level': 'with_terms',
        'explanation': {
          'tldr': ['bottom line'],
          'paragraphs': [],
          'glossary': [],
          'next_steps': [],
        },
        'quota': {'used': null, 'limit': null, 'tier': 'basic'},
      });

      expect(r.id, 'req-1');
      expect(r.language, 'fi');
      expect(r.level, ExplainLevel.withTerms);
      expect(r.body.tldr.single, 'bottom line');
      expect(r.quota.isPro, isTrue);
    });

    test('tolerates missing optional fields', () {
      final r = ExplainResult.fromJson(const <String, dynamic>{});
      expect(r.id, isNull);
      expect(r.language, 'en');
      expect(r.level, ExplainLevel.friend);
      expect(r.body.isEmpty, isTrue);
      expect(r.quota.tier, 'free');
    });
  });
}
