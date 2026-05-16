// contract_upsell_card_test.dart
//
// Locks the contract of the mid-conversation contract review upsell card
// (Bentley P8, 2026-05-16).
//
// What we assert here (UI surface only — telemetry is fire-and-forget and
// gated on a Supabase user that does not exist in the test environment, so
// the insert() call is a silent no-op):
//
//   1. Renders the card key and title for each of EN / ET / FI / RU.
//   2. Unknown locale falls back to EN.
//   3. Upload CTA + dismiss "X" each invoke their callback exactly once.
//   4. The free-pill copy is rendered per locale.
//
// The widget is pure UI — no Riverpod. Vanilla MaterialApp is enough.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/contract_upsell_card.dart';

void main() {
  group('ContractUpsellCard — rendering', () {
    testWidgets('renders card + CTA + dismiss in EN', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractUpsellCard(
              locale: 'en',
              onUpload: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('contract_upsell_card')), findsOneWidget);
      expect(find.byKey(const Key('contract_upsell_cta')), findsOneWidget);
      expect(find.byKey(const Key('contract_upsell_dismiss')), findsOneWidget);
      expect(
        find.textContaining('contract you'),
        findsOneWidget,
      );
      // "First one" appears in the free pill — once is enough.
      expect(find.textContaining('First one'), findsWidgets);
    });

    testWidgets('localizes title for ET', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractUpsellCard(
              locale: 'et',
              onUpload: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('leping'), findsWidgets);
      // "Esimene" appears both in body copy and in the free pill, so we
      // just assert presence, not cardinality.
      expect(find.textContaining('Esimene'), findsWidgets);
    });

    testWidgets('localizes title for FI', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractUpsellCard(
              locale: 'fi',
              onUpload: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('sopimus'), findsWidgets);
      // "Ensimmäinen" appears in body + free pill.
      expect(find.textContaining('Ensimmäinen'), findsWidgets);
    });

    testWidgets('localizes title for RU', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractUpsellCard(
              locale: 'ru',
              onUpload: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('договор'), findsWidgets);
      // "Первый" appears in body + free pill.
      expect(find.textContaining('Первый'), findsWidgets);
    });

    testWidgets('unknown locale falls back to EN', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractUpsellCard(
              locale: 'xx',
              onUpload: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // English title contains the literal word "contract".
      expect(find.textContaining('contract'), findsWidgets);
    });
  });

  group('ContractUpsellCard — callbacks', () {
    testWidgets('CTA tap invokes onUpload exactly once', (tester) async {
      var uploads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractUpsellCard(
              locale: 'en',
              onUpload: () => uploads += 1,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contract_upsell_cta')));
      await tester.pumpAndSettle();
      expect(uploads, 1);
    });

    testWidgets('dismiss tap invokes onDismiss exactly once', (tester) async {
      var dismisses = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractUpsellCard(
              locale: 'en',
              onUpload: () {},
              onDismiss: () => dismisses += 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contract_upsell_dismiss')));
      await tester.pumpAndSettle();
      expect(dismisses, 1);
    });

    testWidgets('CTA tap does NOT invoke onDismiss (independent paths)',
        (tester) async {
      var dismisses = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractUpsellCard(
              locale: 'en',
              onUpload: () {},
              onDismiss: () => dismisses += 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contract_upsell_cta')));
      await tester.pumpAndSettle();
      expect(dismisses, 0);
    });
  });
}
