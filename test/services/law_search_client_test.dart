@Tags(['fast'])
library;

// =============================================================================
// law_search_client_test.dart — wire-format & graceful-fail contract
// =============================================================================
//
// 2026-05-05 — P0-3 of the Advocat legal-brain rebuild. The `law-search`
// Edge Function (P0-2) is not deployed yet, so the client MUST degrade
// silently in every error path. This file pins:
//
//   - The JSON parser tolerates {chunks:[…]}, {results:[…]}, {data:[…]},
//     and a top-level list. P0-2 owns the exact shape; P0-3 stays tolerant.
//   - LawChunk.fromJson clamps similarity to [0,1] and treats missing
//     source_url as null.
//   - Empty / null / malformed data → empty list (no throw).
//   - approximateBytes() roughly reflects the size cost the budget-trim
//     path uses in the prompt.
//   - search() with empty query short-circuits to [] (no HTTP).
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/law_search_client.dart';

void main() {
  group('LawChunk.fromJson — single-chunk parsing', () {
    test('parses a well-formed chunk', () {
      final c = LawChunk.fromJson({
        'act_name': 'KarS',
        'paragraph': '§ 121',
        'body': 'Kehaline väärkohtlemine — rahaline karistus või vangistus.',
        'similarity': 0.87,
        'source_url': 'https://www.riigiteataja.ee/akt/KarS',
      });
      expect(c.actName, 'KarS');
      expect(c.paragraph, '§ 121');
      expect(c.body, contains('väärkohtlemine'));
      expect(c.similarity, closeTo(0.87, 1e-9));
      expect(c.sourceUrl, 'https://www.riigiteataja.ee/akt/KarS');
    });

    test('clamps similarity to [0, 1]', () {
      final tooHigh = LawChunk.fromJson({
        'act_name': 'HMS',
        'paragraph': '§ 26',
        'body': '',
        'similarity': 1.7,
      });
      final tooLow = LawChunk.fromJson({
        'act_name': 'HMS',
        'paragraph': '§ 26',
        'body': '',
        'similarity': -0.4,
      });
      expect(tooHigh.similarity, 1.0);
      expect(tooLow.similarity, 0.0);
    });

    test('handles missing source_url gracefully (null, never empty string)',
        () {
      final c = LawChunk.fromJson({
        'act_name': 'TLS',
        'paragraph': '§ 88',
        'body': 'Tööandja võib töölepingu üles öelda…',
        'similarity': 0.7,
      });
      expect(c.sourceUrl, isNull);
    });

    test('coerces numeric similarity from int', () {
      final c = LawChunk.fromJson({
        'act_name': 'X',
        'paragraph': 'Y',
        'body': '',
        'similarity': 1, // int, not double
      });
      expect(c.similarity, 1.0);
    });

    test('approximateBytes reflects total content cost', () {
      final c = LawChunk.fromJson({
        'act_name': 'KarS',
        'paragraph': '§ 121',
        'body': 'a' * 500,
        'similarity': 0.9,
        'source_url': 'https://x.example/y',
      });
      final size = c.approximateBytes();
      // Body alone is 500 chars; total must include it plus header overhead.
      expect(size, greaterThan(500));
      // Sanity upper bound — body + act + paragraph + url + 32 headroom.
      expect(size, lessThan(700));
    });
  });

  group('LawSearchClient.parseResponse — wire-format tolerance', () {
    test('top-level list of chunks', () {
      final out = LawSearchClient.parseResponse([
        {'act_name': 'A', 'paragraph': '§ 1', 'body': 'x', 'similarity': 0.9},
        {'act_name': 'B', 'paragraph': '§ 2', 'body': 'y', 'similarity': 0.8},
      ]);
      expect(out, hasLength(2));
      expect(out.first.actName, 'A');
    });

    test('object with chunks key', () {
      final out = LawSearchClient.parseResponse({
        'chunks': [
          {'act_name': 'A', 'paragraph': '§ 1', 'body': 'x', 'similarity': 0.5}
        ],
      });
      expect(out, hasLength(1));
    });

    test('object with results key', () {
      final out = LawSearchClient.parseResponse({
        'results': [
          {'act_name': 'A', 'paragraph': '§ 1', 'body': 'x', 'similarity': 0.5}
        ],
      });
      expect(out, hasLength(1));
    });

    test('object with data key', () {
      final out = LawSearchClient.parseResponse({
        'data': [
          {'act_name': 'A', 'paragraph': '§ 1', 'body': 'x', 'similarity': 0.5}
        ],
      });
      expect(out, hasLength(1));
    });

    test('null body → empty list', () {
      expect(LawSearchClient.parseResponse(null), isEmpty);
    });

    test('unrecognised shape (string) → empty list, no throw', () {
      expect(LawSearchClient.parseResponse('not json'), isEmpty);
    });

    test('object without recognised key → empty list', () {
      expect(
        LawSearchClient.parseResponse({'unrelated': 'value'}),
        isEmpty,
      );
    });

    test('skips non-map entries inside the array', () {
      final out = LawSearchClient.parseResponse([
        'invalid',
        42,
        {'act_name': 'A', 'paragraph': '§ 1', 'body': 'x', 'similarity': 0.5},
        null,
      ]);
      expect(out, hasLength(1));
      expect(out.first.actName, 'A');
    });
  });

  group('LawSearchClient.search — graceful no-op fallback', () {
    test('empty query short-circuits to [] (no HTTP attempt)', () async {
      final result = await LawSearchClient.search(
        query: '',
        lang: 'ru',
      );
      expect(result, isEmpty);
    });

    test('whitespace-only query short-circuits to []', () async {
      final result = await LawSearchClient.search(
        query: '   \n  \t ',
        lang: 'et',
      );
      expect(result, isEmpty);
    });
  });
}
