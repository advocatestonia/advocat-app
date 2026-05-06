@Tags(['fast'])
library;

// =============================================================================
// citation_detail_sheet_test.dart — Phase 2 Pkg 2 bottom sheet contract.
// =============================================================================
//
// Pins the contract that:
//   1. The sheet shows the act name, § + title subhead, and the snippet.
//   2. Verified citations get a "Verified" status badge; unverified get a
//      red badge + the "verify before relying" note.
//   3. The "Open in Riigi Teataja" button is rendered with the documented
//      key so an integration test (or smoke) can find it.
//   4. Long snippets show the expand/collapse toggle.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/citations/citation_model.dart';
import 'package:advocat/features/chat/widgets/citations/citation_detail_sheet.dart';
import 'package:advocat/l10n/app_localizations.dart';

Citation _verified() => const Citation(
      marker: '[[ref:TLS:88]]',
      status: CitationStatus.verified,
      actSlug: 'tls',
      paragraph: '88',
      occurrences: 1,
      chunkId: 'tls-§88-1',
      actName: 'Töölepingu seadus',
      title: 'Tööandja erakorraline ülesütlemine',
      snippet:
          'Tööandja võib töölepingu erakorraliselt üles öelda mõjuval põhjusel...',
      sourceUrl: 'https://www.riigiteataja.ee/akt/tls',
      jurisdiction: 'EE',
      inForce: true,
    );

Citation _unverified() => const Citation(
      marker: '[[ref:KarS:999]]',
      status: CitationStatus.unverified,
      actSlug: 'kars',
      paragraph: '999',
      occurrences: 1,
    );

Citation _withLongSnippet() {
  // 1000-char body forces the expand/collapse toggle (cap is 800).
  final long = 'A' * 1000;
  return Citation(
    marker: '[[ref:TLS:88]]',
    status: CitationStatus.verified,
    actSlug: 'tls',
    paragraph: '88',
    occurrences: 1,
    chunkId: 'tls-§88-1',
    actName: 'Töölepingu seadus',
    title: 'Tööandja erakorraline ülesütlemine',
    snippet: long,
    sourceUrl: 'https://www.riigiteataja.ee/akt/tls',
    jurisdiction: 'EE',
    inForce: true,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Future<void> _showSheet(WidgetTester tester, Citation c) async {
  // We pump the sheet directly as the body to keep the harness fast — the
  // showModalBottomSheet wrapper is a thin convenience and not under test.
  await tester.pumpWidget(_wrap(CitationDetailSheet(citation: c)));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('CitationDetailSheet — verified', () {
    testWidgets('shows act name, § subhead, snippet and RT button',
        (tester) async {
      await _showSheet(tester, _verified());

      // Act name heading.
      expect(find.text('Töölepingu seadus'), findsOneWidget);
      // § + title subhead.
      expect(
        find.textContaining('§88'),
        findsAtLeastNWidgets(1),
        reason: 'Subhead must include the paragraph number',
      );
      expect(
        find.textContaining('Tööandja erakorraline ülesütlemine'),
        findsOneWidget,
      );
      // Snippet body.
      expect(find.textContaining('mõjuval põhjusel'), findsOneWidget);
      // RT link button (uses the documented key).
      expect(find.byKey(const Key('citation_rt_link_button')), findsOneWidget);
      expect(find.textContaining('Riigi Teataja'), findsOneWidget,
          reason: 'EN locale RT button label includes the source name');
      // Verified status badge.
      expect(find.text('Verified'), findsOneWidget);
    });
  });

  group('CitationDetailSheet — unverified', () {
    testWidgets('shows red status badge + warning note + RT button',
        (tester) async {
      await _showSheet(tester, _unverified());

      // The unverified status badge label.
      expect(find.text('Unverified'), findsOneWidget);
      // The "verify before relying" sheet note.
      expect(
        find.textContaining('not retrieved'),
        findsOneWidget,
        reason: 'Unverified rows show the warn note in the sheet body',
      );
      // RT link button still renders — even when there is no source URL,
      // the builder fills in a default Riigi Teataja URL.
      expect(find.byKey(const Key('citation_rt_link_button')), findsOneWidget);
    });
  });

  group('CitationDetailSheet — long snippets', () {
    testWidgets('shows expand toggle when snippet >800 chars', (tester) async {
      await _showSheet(tester, _withLongSnippet());

      // The "Show full text" toggle is rendered when the snippet exceeds
      // _snippetEllipsisAt (= 800 chars).
      expect(find.textContaining('Show full text'), findsOneWidget);
    });
  });
}
