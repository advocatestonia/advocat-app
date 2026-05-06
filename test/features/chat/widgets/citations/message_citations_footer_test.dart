@Tags(['fast'])
library;

// =============================================================================
// message_citations_footer_test.dart — Phase 2 Pkg 2 per-message footer.
// =============================================================================
//
// Pins the contract that:
//   1. With 0 citations + legal-ish content → footer shows "no grounded
//      citations" warning.
//   2. With 0 citations + non-legal content → footer renders nothing
//      (ChatMessageBubble must not pollute every reply with the warning).
//   3. With N citations → summary line shows total + breakdown.
//   4. Tapping the toggle expands to show one row per citation.
//
// Footer widget is pumped in isolation — chat_message_bubble integration
// is covered by message_bubble_copy_test + selectable_message_test.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/citations/citation_model.dart';
import 'package:advocat/features/chat/widgets/citations/message_citations_footer.dart';
import 'package:advocat/l10n/app_localizations.dart';

Citation _c(String slug, String para, CitationStatus status) => Citation(
      marker: '[[ref:$slug:$para]]',
      status: status,
      actSlug: slug.toLowerCase(),
      paragraph: para,
      actName: 'Test Act',
      occurrences: 1,
    );

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(8), child: child)),
  );
}

void main() {
  group('MessageCitationsFooter — empty + warning gate', () {
    testWidgets('legal-ish content + zero citations shows warning',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const MessageCitationsFooter(citations: [], legalContent: true),
      ));
      await tester.pump();

      expect(find.textContaining('No grounded citations'), findsOneWidget,
          reason: 'Footer must surface missing-grounding signal to the user');
    });

    testWidgets('non-legal content + zero citations renders nothing',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const MessageCitationsFooter(citations: [], legalContent: false),
      ));
      await tester.pump();

      expect(find.textContaining('No grounded citations'), findsNothing,
          reason: 'No warning on ordinary chit-chat — would be noise');
    });
  });

  group('MessageCitationsFooter — populated', () {
    testWidgets('summary line shows total + verified + unverified counts',
        (tester) async {
      await tester.pumpWidget(_wrap(
        MessageCitationsFooter(
          citations: [
            _c('TLS', '88', CitationStatus.verified),
            _c('TLS', '90', CitationStatus.verified),
            _c('KarS', '999', CitationStatus.unverified),
          ],
          legalContent: true,
        ),
      ));
      await tester.pump();

      expect(find.textContaining('3 citations'), findsOneWidget);
      expect(find.textContaining('2 verified'), findsOneWidget);
      expect(find.textContaining('1 unverified'), findsOneWidget);
    });

    testWidgets('tapping toggle expands and renders one row per citation',
        (tester) async {
      await tester.pumpWidget(_wrap(
        MessageCitationsFooter(
          citations: [
            _c('TLS', '88', CitationStatus.verified),
            _c('KarS', '999', CitationStatus.unverified),
          ],
          legalContent: true,
        ),
      ));
      await tester.pump();

      // Collapsed by default — the per-citation labels aren't present yet.
      expect(find.textContaining('TLS §88'), findsNothing);

      await tester.tap(find.byKey(const Key('citation_footer_toggle')));
      await tester.pumpAndSettle();

      expect(find.textContaining('TLS §88'), findsOneWidget);
      expect(find.textContaining('KARS §999'), findsOneWidget);
    });
  });

  group('looksLegalish heuristic', () {
    test('returns true for messages containing "§"', () {
      expect(looksLegalish('Per the law (TLS § 88) you may apply.'), isTrue);
    });

    test('returns true for known legal stems', () {
      expect(looksLegalish('See KarS for criminal definitions.'), isTrue);
    });

    test('returns false for casual prose', () {
      expect(
        looksLegalish('Hello, I would like to know about working in Estonia.'),
        isFalse,
      );
    });
  });
}
