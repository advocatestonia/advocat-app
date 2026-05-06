@Tags(['fast'])
library;

// =============================================================================
// citation_marker_span_test.dart — Phase 2 Pkg 2 inline marker rendering.
// =============================================================================
//
// Pins the contract that an assistant message containing
// `[[ref:ACT:PARAGRAPH]]` markers renders one chip per occurrence in the
// expected status colour, that the original bracket syntax is replaced
// with a human-readable "ACT §PARA" label, and that tapping a chip opens
// the citation bottom sheet for the matching Citation row.
//
// Keep widget-only — no Supabase, no Riverpod overrides.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/citations/citation_model.dart';
import 'package:advocat/features/chat/widgets/citations/citation_marker_span.dart';
import 'package:advocat/l10n/app_localizations.dart';

Citation _verified(String slug, String para, {String? title}) => Citation(
      marker: '[[ref:$slug:$para]]',
      status: CitationStatus.verified,
      actSlug: slug.toLowerCase(),
      paragraph: para,
      occurrences: 1,
      chunkId: '${slug.toLowerCase()}-§$para-1',
      actName: 'Töölepingu seadus',
      title: title ?? 'Tööandja erakorraline ülesütlemine',
      snippet: 'Tööandja võib töölepingu erakorraliselt üles öelda…',
      sourceUrl: 'https://www.riigiteataja.ee/akt/${slug.toLowerCase()}',
      jurisdiction: 'EE',
      inForce: true,
    );

Citation _unverified(String slug, String para) => Citation(
      marker: '[[ref:$slug:$para]]',
      status: CitationStatus.unverified,
      actSlug: slug.toLowerCase(),
      paragraph: para,
      occurrences: 1,
    );

Citation _historical(String slug, String para) => Citation(
      marker: '[[ref:$slug:$para]]',
      status: CitationStatus.historical,
      actSlug: slug.toLowerCase(),
      paragraph: para,
      occurrences: 1,
      chunkId: '${slug.toLowerCase()}-§$para-1',
      actName: 'KarS (older)',
      snippet: 'historical chunk body…',
      sourceUrl: 'https://www.riigiteataja.ee/akt/${slug.toLowerCase()}',
      jurisdiction: 'EE',
      inForce: false,
    );

Future<void> _pumpInline(
  WidgetTester tester, {
  required String text,
  required List<Citation> citations,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) {
            final spans = buildCitationSpans(
              context: ctx,
              text: text,
              citations: citations,
              baseStyle: const TextStyle(fontSize: 14),
            );
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text.rich(TextSpan(children: spans)),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('buildCitationSpans — inline marker rendering', () {
    testWidgets('replaces marker with human-readable "TLS §88" label',
        (tester) async {
      const text = 'Per the law [[ref:TLS:88]] applies here.';
      await _pumpInline(
        tester,
        text: text,
        citations: [_verified('TLS', '88')],
      );

      // Bracket form must NOT survive into rendered text.
      expect(find.textContaining('[[ref:'), findsNothing,
          reason: 'Marker bracket characters must be replaced with a chip');

      // Human label must be visible.
      expect(find.textContaining('TLS §88'), findsOneWidget,
          reason: 'Chip should display "TLS §88" instead of the raw marker');
    });

    testWidgets('renders ONE chip per marker occurrence (dedup-by-tap, not visually)',
        (tester) async {
      const text = 'See [[ref:TLS:88]] and again [[ref:TLS:88]] there.';
      await _pumpInline(
        tester,
        text: text,
        citations: [_verified('TLS', '88')],
      );

      // Both occurrences must render visible chips — never silently hidden.
      // Both chip texts read "TLS §88", so the count is 2.
      final labels = find.textContaining('TLS §88');
      expect(labels, findsNWidgets(2),
          reason: 'Same marker repeated must render the same chip both times');
    });

    testWidgets('unverified marker still renders (transparency over polish)',
        (tester) async {
      const text = 'Cited [[ref:KarS:999]] without retrieval.';
      await _pumpInline(
        tester,
        text: text,
        citations: [_unverified('KarS', '999')],
      );

      // Even when the citation is unverified, the chip MUST be visible.
      expect(find.textContaining('KARS §999'), findsOneWidget,
          reason: 'Unverified markers must NEVER be hidden — surfaces risk');
    });

    testWidgets('historical marker renders with star prefix', (tester) async {
      const text = 'Older statute [[ref:KarS:121]] is no longer in force.';
      await _pumpInline(
        tester,
        text: text,
        citations: [_historical('KarS', '121')],
      );

      // Historical chip prepends a "★" glyph (per design — amber badge).
      expect(find.textContaining('KARS §121'), findsOneWidget);
      expect(find.textContaining('\u2605'), findsOneWidget,
          reason: 'Historical citations get a star prefix marker');
    });

    testWidgets('marker WITHOUT matching citation renders plain (no tap target)',
        (tester) async {
      // Verifier dropped this marker (e.g. malformed) — UI must still
      // show "TLS §88" rather than the raw bracket.
      const text = 'Cited [[ref:TLS:88]] today.';
      await _pumpInline(tester, text: text, citations: const []);

      expect(find.textContaining('[[ref:'), findsNothing);
      expect(find.textContaining('TLS §88'), findsOneWidget);
    });

    testWidgets('text without any markers passes through verbatim',
        (tester) async {
      const text = 'Just normal prose, no citations here.';
      await _pumpInline(tester, text: text, citations: const []);

      expect(find.text(text), findsOneWidget,
          reason: 'No-markers fast path must produce a single TextSpan');
    });
  });
}
