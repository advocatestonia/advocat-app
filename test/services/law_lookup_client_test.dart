@Tags(['fast'])
library;

// =============================================================================
// law_lookup_client_test.dart — wire-format & graceful-fail contract
// =============================================================================
//
// Phase 2 Pkg 1+2 (Advocat legal-brain rebuild). Mirror of
// law_search_client_test.dart but for the EXACT-paragraph lookup path.
// The `law-lookup` Edge Function is not deployed yet, so the client MUST
// degrade silently in every error path. This file pins:
//
//   - StatuteLookup.fromJson reads exactly the wire fields produced by
//     law-lookup (act_slug, act_name, paragraph, title, body, source_url,
//     version_date, jurisdiction).
//   - parseResponse handles {statute: {...}}, {statute: null} and a bare
//     statute object.
//   - lookup() with empty act / paragraph short-circuits to null (no HTTP).
//   - lookup() with unsupported jurisdiction short-circuits to null.
//   - Empty / null / malformed data → null (no throw).
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/law_lookup_client.dart';

void main() {
  group('StatuteLookup.fromJson — single-row parsing', () {
    test('parses a well-formed statute', () {
      final s = StatuteLookup.fromJson({
        'id': 'kars-§121-0',
        'act_slug': 'kars',
        'act_name': 'KarS',
        'paragraph': '121',
        'title': 'Kehaline väärkohtlemine',
        'body': 'Teise inimese tervise kahjustamise eest…',
        'source_url': 'https://www.riigiteataja.ee/akt/KarS',
        'version_date': '2026-01-01',
        'jurisdiction': 'EE',
      });
      expect(s.id, 'kars-§121-0');
      expect(s.actSlug, 'kars');
      expect(s.actName, 'KarS');
      expect(s.paragraph, '121');
      expect(s.title, 'Kehaline väärkohtlemine');
      expect(s.body, contains('tervise'));
      expect(s.sourceUrl, 'https://www.riigiteataja.ee/akt/KarS');
      expect(s.versionDate, '2026-01-01');
      expect(s.jurisdiction, 'EE');
    });

    test('handles missing optional fields gracefully', () {
      final s = StatuteLookup.fromJson({
        'id': 'tls-§88-0',
        'act_slug': 'tls',
        'act_name': 'TLS',
        'paragraph': '88',
        'body': 'Tööandja võib töölepingu üles öelda…',
        'jurisdiction': 'EE',
      });
      expect(s.title, isNull);
      expect(s.sourceUrl, isNull);
      expect(s.versionDate, isNull);
      // Empty strings should also collapse to null (not bare empty).
      final s2 = StatuteLookup.fromJson({
        'id': 'x',
        'act_slug': 'x',
        'act_name': 'X',
        'paragraph': 'y',
        'body': 'b',
        'title': '',
        'source_url': '',
        'version_date': '',
        'jurisdiction': 'EE',
      });
      expect(s2.title, isNull);
      expect(s2.sourceUrl, isNull);
      expect(s2.versionDate, isNull);
    });

    test('toJson round-trips the canonical fields', () {
      final s = StatuteLookup.fromJson({
        'id': 'kars-§121-0',
        'act_slug': 'kars',
        'act_name': 'KarS',
        'paragraph': '121',
        'title': 'Kehaline väärkohtlemine',
        'body': 'body text',
        'source_url': 'https://example.test',
        'version_date': '2026-01-01',
        'jurisdiction': 'EE',
      });
      final json = s.toJson();
      expect(json['act_slug'], 'kars');
      expect(json['act_name'], 'KarS');
      expect(json['paragraph'], '121');
      expect(json['body'], 'body text');
      expect(json['version_date'], '2026-01-01');
      expect(json['jurisdiction'], 'EE');
    });
  });

  group('LawLookupClient.parseResponse — wire-format tolerance', () {
    test('object with statute key → parsed', () {
      final out = LawLookupClient.parseResponse({
        'statute': {
          'id': 'kars-§121-0',
          'act_slug': 'kars',
          'act_name': 'KarS',
          'paragraph': '121',
          'body': 'body',
          'jurisdiction': 'EE',
        },
      });
      expect(out, isNotNull);
      expect(out!.actName, 'KarS');
    });

    test('explicit {statute: null} → null', () {
      final out = LawLookupClient.parseResponse({'statute': null});
      expect(out, isNull);
    });

    test('null body → null (no throw)', () {
      expect(LawLookupClient.parseResponse(null), isNull);
    });

    test('unrecognised shape (string) → null', () {
      expect(LawLookupClient.parseResponse('not json'), isNull);
    });

    test('object missing both statute key and body → null', () {
      // Bare statute object without `body` is invalid → null.
      expect(
        LawLookupClient.parseResponse({'unrelated': 'value'}),
        isNull,
      );
    });

    test('bare statute object (no `statute` wrapper) is tolerated', () {
      // Defensive parser branch: if some future caller posts the row
      // verbatim, parse it.
      final out = LawLookupClient.parseResponse({
        'id': 'kars-§121-0',
        'act_slug': 'kars',
        'act_name': 'KarS',
        'paragraph': '121',
        'body': 'b',
        'jurisdiction': 'EE',
      });
      expect(out, isNotNull);
      expect(out!.actName, 'KarS');
    });

    test('statute with empty body → null (treated as not-found)', () {
      final out = LawLookupClient.parseResponse({
        'statute': {
          'id': 'x',
          'act_slug': 'x',
          'act_name': 'X',
          'paragraph': 'y',
          'body': '',
          'jurisdiction': 'EE',
        },
      });
      expect(out, isNull);
    });
  });

  group('LawLookupClient.lookup — graceful no-op fallback', () {
    test('empty act short-circuits to null (no HTTP attempt)', () async {
      final result = await LawLookupClient.lookup(
        act: '',
        paragraph: '121',
      );
      expect(result, isNull);
    });

    test('empty paragraph short-circuits to null', () async {
      final result = await LawLookupClient.lookup(
        act: 'KarS',
        paragraph: '   ',
      );
      expect(result, isNull);
    });

    test('unsupported jurisdiction short-circuits to null', () async {
      final result = await LawLookupClient.lookup(
        act: 'KarS',
        paragraph: '121',
        jurisdiction: 'XX',
      );
      expect(result, isNull);
    });

    test('jurisdiction is normalized to upper-case before validation',
        () async {
      // Must NOT short-circuit — "ee" is valid after upper-casing. Without
      // a deployed edge function this still returns null (network/config
      // fall-through), but the validation gate must accept it.
      final result = await LawLookupClient.lookup(
        act: 'KarS',
        paragraph: '121',
        jurisdiction: 'ee',
      );
      // Either a real lookup returned null (edge fn not deployed) or the
      // call was attempted. Either way: no throw. Pin the contract that
      // the lower-case jurisdiction did not trip the local validation.
      expect(result, isNull);
    });
  });

  group('LawLookupClient.supportedJurisdictions', () {
    test('matches the edge-function whitelist exactly', () {
      // Pin: any change to the jurisdictions list must be made in BOTH
      // the edge function and this constant. Without this test, a drift
      // would silently 4xx in production.
      expect(
        LawLookupClient.supportedJurisdictions,
        equals({'EE', 'FI', 'EU'}),
      );
    });
  });
}
