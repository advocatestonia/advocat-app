@Tags(['fast'])
library;

// =============================================================================
// citation_model_test.dart — Phase 2 Pkg 2 wire-shape decoder tests.
// =============================================================================
//
// Pin the contract that the proxy's JSON `citations: [...]` shape decodes
// cleanly into typed `Citation` instances, with the right status enum, key
// composition, and tolerant handling of malformed entries.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/citations/citation_model.dart';

void main() {
  group('Citation.fromJson', () {
    test('decodes a fully-populated verified citation', () {
      final c = Citation.fromJson(const {
        'marker': '[[ref:TLS:88]]',
        'status': 'verified',
        'chunk_id': 'tls-§88-1',
        'act_slug': 'tls',
        'paragraph': '88',
        'act_name': 'Töölepingu seadus',
        'title': 'Tööandja erakorraline ülesütlemine',
        'snippet': 'Tööandja võib töölepingu erakorraliselt …',
        'source_url': 'https://www.riigiteataja.ee/akt/tls',
        'jurisdiction': 'EE',
        'in_force': true,
        'occurrences': 2,
      });

      expect(c.marker, '[[ref:TLS:88]]');
      expect(c.status, CitationStatus.verified);
      expect(c.chunkId, 'tls-§88-1');
      expect(c.actSlug, 'tls');
      expect(c.paragraph, '88');
      expect(c.occurrences, 2);
      expect(c.inForce, isTrue);
      expect(c.key, 'tls:88');
    });

    test('unknown status string folds to CitationStatus.unknown', () {
      final c = Citation.fromJson(const {
        'marker': '[[ref:TLS:88]]',
        'status': 'something-future',
        'act_slug': 'tls',
        'paragraph': '88',
        'occurrences': 1,
      });
      expect(c.status, CitationStatus.unknown,
          reason: 'Forward-compat: never crash on a new status');
    });

    test('act_slug is normalised to lowercase', () {
      final c = Citation.fromJson(const {
        'marker': '[[ref:TLS:88]]',
        'status': 'verified',
        'act_slug': 'TLS',
        'paragraph': '88',
        'occurrences': 1,
      });
      expect(c.actSlug, 'tls');
      expect(c.key, 'tls:88');
    });
  });

  group('Citation.listFromJson', () {
    test('drops malformed entries silently', () {
      final list = Citation.listFromJson(const [
        // Valid.
        {
          'marker': '[[ref:TLS:88]]',
          'status': 'verified',
          'act_slug': 'tls',
          'paragraph': '88',
          'occurrences': 1,
        },
        // Missing required fields → dropped.
        {'marker': ''},
        // Wrong type entirely → dropped.
        'not a citation',
      ]);
      expect(list, hasLength(1));
      expect(list.first.actSlug, 'tls');
    });

    test('returns empty list when input is null or wrong type', () {
      expect(Citation.listFromJson(null), isEmpty);
      expect(Citation.listFromJson('not a list'), isEmpty);
      expect(Citation.listFromJson(const {}), isEmpty);
    });
  });

  group('Citation.displayLabel', () {
    test('uppercases the slug for display', () {
      const c = Citation(
        marker: '[[ref:tls:88]]',
        status: CitationStatus.verified,
        actSlug: 'tls',
        paragraph: '88',
        occurrences: 1,
      );
      expect(c.displayLabel, 'TLS §88');
    });

    test('CELEX numeric ids render uppercase too', () {
      const c = Citation(
        marker: '[[ref:32019l1152:5]]',
        status: CitationStatus.verified,
        actSlug: '32019l1152',
        paragraph: '5',
        occurrences: 1,
      );
      expect(c.displayLabel, '32019L1152 §5');
    });
  });

  group('citationStatusFromString', () {
    test('handles all four statuses + null', () {
      expect(citationStatusFromString('verified'), CitationStatus.verified);
      expect(citationStatusFromString('UNVERIFIED'), CitationStatus.unverified);
      expect(citationStatusFromString('historical'), CitationStatus.historical);
      expect(citationStatusFromString(null), CitationStatus.unknown);
      expect(citationStatusFromString(''), CitationStatus.unknown);
    });
  });
}
