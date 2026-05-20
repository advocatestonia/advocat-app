// =====================================================================
// Widget tests for the three EU-features mockups.
//
// These are UI-only smoke tests — no Riverpod scope, no Supabase, no
// l10n delegates. Each test wraps the widget in a bare MaterialApp and
// drives one user interaction.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/widgets/citation_badge.dart';
import 'package:advocat/widgets/deadline_radar_eu.dart';
import 'package:advocat/widgets/landmark_explorer.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('DeadlineRadarEu', () {
    testWidgets('renders headline + dropdowns + compute button',
        (tester) async {
      await tester.pumpWidget(_wrap(const DeadlineRadarEu()));
      await tester.pumpAndSettle();

      expect(find.text('EU deadline radar'), findsOneWidget);
      expect(find.byKey(const Key('deadline-eu-jurisdiction')), findsOneWidget);
      expect(find.byKey(const Key('deadline-eu-category')), findsOneWidget);
      expect(find.byKey(const Key('deadline-eu-start-date')), findsOneWidget);
      expect(find.byKey(const Key('deadline-eu-compute')), findsOneWidget);
    });

    testWidgets('tapping Compute renders the mock result card',
        (tester) async {
      await tester.pumpWidget(_wrap(const DeadlineRadarEu()));
      await tester.pumpAndSettle();

      // Result card is not shown before computation.
      expect(find.byKey(const Key('deadline-eu-result')), findsNothing);

      await tester.tap(find.byKey(const Key('deadline-eu-compute')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('deadline-eu-result')), findsOneWidget);
      expect(find.byKey(const Key('deadline-eu-due-date')), findsOneWidget);
      // Default jurisdiction FI + appeal_civil → statute basis is OK 25:5.
      expect(find.textContaining('OK 25:5'), findsOneWidget);
    });

    testWidgets('changing the category dropdown updates state', (tester) async {
      await tester.pumpWidget(_wrap(const DeadlineRadarEu()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deadline-eu-category')));
      await tester.pumpAndSettle();

      // Pick "ECHR application" from the menu.
      final option = find.text('ECHR application').last;
      await tester.tap(option);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deadline-eu-compute')));
      await tester.pumpAndSettle();

      // ECHR rows always include the Protocol 15 warning.
      expect(
        find.textContaining('Protocol 15'),
        findsOneWidget,
      );
    });
  });

  group('LandmarkExplorer', () {
    testWidgets('renders search bar + 20 mock cases', (tester) async {
      await tester.pumpWidget(_wrap(const LandmarkExplorer()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('landmark-search-bar')), findsOneWidget);
      expect(find.byKey(const Key('landmark-result-list')), findsOneWidget);
      // "20 of 20 cases" line is rendered initially.
      expect(find.textContaining('20 of 20 cases'), findsOneWidget);
    });

    testWidgets('typing in the search bar filters the list', (tester) async {
      await tester.pumpWidget(_wrap(const LandmarkExplorer()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('landmark-search-bar')),
        'Schrems',
      );
      await tester.pumpAndSettle();

      // Two Schrems cases (I and II) are in the mock dataset.
      expect(find.textContaining('Schrems'), findsWidgets);
      expect(find.textContaining('20 of 20 cases'), findsNothing);
    });

    testWidgets('tapping CJEU chip activates the filter', (tester) async {
      await tester.pumpWidget(_wrap(const LandmarkExplorer()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('landmark-court-cjeu')));
      await tester.pumpAndSettle();

      // After filtering to CJEU only, the counter line drops below 20.
      expect(find.textContaining('of 20 cases'), findsOneWidget);
      expect(find.textContaining('20 of 20 cases'), findsNothing);
    });

    testWidgets('tapping a row opens the detail panel', (tester) async {
      await tester.pumpWidget(_wrap(const LandmarkExplorer()));
      await tester.pumpAndSettle();

      // Tap the first visible row — Google Spain.
      await tester.tap(find.text('Google Spain v. AEPD (C-131/12)'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('landmark-detail-panel')), findsOneWidget);
      expect(find.textContaining('right to be forgotten'), findsOneWidget);

      // Close the panel.
      await tester.tap(find.byKey(const Key('landmark-detail-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('landmark-detail-panel')), findsNothing);
    });
  });

  group('CitationBadge', () {
    testWidgets('renders BGB statute, EU regulation, ECHR app', (tester) async {
      await tester.pumpWidget(_wrap(const Column(
        children: [
          CitationBadge(ref: mockBgbCitation),
          CitationBadge(ref: mockGdprArt17Citation),
          CitationBadge(ref: mockEchrApplicationCitation),
        ],
      )));
      await tester.pumpAndSettle();

      expect(find.text('BGB § 433'), findsOneWidget);
      expect(find.text('Verordnung (EU) 2016/679 Art 17'), findsOneWidget);
      expect(find.text('Application 12345/67'), findsOneWidget);
    });

    testWidgets('tapping a badge opens the drawer with the statute snippet',
        (tester) async {
      await tester.pumpWidget(_wrap(const CitationBadge(ref: mockBgbCitation)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('citation-badge-BGB § 433')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('citation-drawer-title')), findsOneWidget);
      expect(find.textContaining('Kaufvertrag'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
    });
  });
}
