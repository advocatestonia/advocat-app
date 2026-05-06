@Tags(['fast'])
library;

// =============================================================================
// riigi_teataja_url_test.dart — Phase 2 Pkg 2 source-URL builder.
// =============================================================================
//
// Pin the resolution order documented in the architect spec §7:
//   1. sourceUrl set → use it; append `#paraN` only when no fragment exists.
//   2. EE jurisdiction → riigiteataja.ee/akt/<slug>#paraN
//   3. EU jurisdiction → eur-lex CELEX URL
//   4. FI jurisdiction → finlex keyword search
//   5. Default fallback → Riigi Teataja
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/citations/riigi_teataja_url.dart';

void main() {
  group('buildRiigiTeatajaUrl', () {
    test('uses sourceUrl verbatim and appends #para when no fragment', () {
      final url = buildRiigiTeatajaUrl(
        actSlug: 'tls',
        paragraph: '88',
        sourceUrl: 'https://example.test/tls',
      );
      expect(url, 'https://example.test/tls#para88');
    });

    test('uses sourceUrl verbatim when it already has a fragment', () {
      final url = buildRiigiTeatajaUrl(
        actSlug: 'tls',
        paragraph: '88',
        sourceUrl: 'https://example.test/tls#page2',
      );
      expect(url, 'https://example.test/tls#page2');
    });

    test('builds Riigi Teataja URL for EE jurisdiction with no sourceUrl', () {
      final url = buildRiigiTeatajaUrl(
        actSlug: 'TLS',
        paragraph: '88',
        jurisdiction: 'EE',
      );
      expect(url, 'https://www.riigiteataja.ee/akt/tls#para88');
    });

    test('builds EUR-Lex CELEX URL for EU jurisdiction', () {
      final url = buildRiigiTeatajaUrl(
        actSlug: '32019l1152',
        paragraph: '5',
        jurisdiction: 'EU',
      );
      expect(
        url,
        'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32019L1152',
      );
    });

    test('builds Finlex keyword URL for FI jurisdiction', () {
      final url = buildRiigiTeatajaUrl(
        actSlug: 'rikoslaki',
        paragraph: '21',
        jurisdiction: 'FI',
      );
      expect(url, 'https://www.finlex.fi/fi/laki/ajantasa/?keyword=rikoslaki');
    });

    test('defaults to Riigi Teataja when jurisdiction is unknown', () {
      final url = buildRiigiTeatajaUrl(
        actSlug: 'kars',
        paragraph: '121',
      );
      expect(url, 'https://www.riigiteataja.ee/akt/kars#para121');
    });
  });
}
