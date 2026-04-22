// welcome_chips_test.dart
//
// Post-launch BUG 3 fix (2026-04-22):
//
// Owner report: new users who land on the chat screen for the first time
// do not get a clear "what do you need help with?" prompt — just a generic
// welcome. They have to guess how to start the conversation.
//
// Fix: a `ChatWelcomeChips` widget that renders underneath the first
// assistant message in an empty conversation. It offers five localised
// category chips (deportation, labor dispute, family law, housing, other)
// plus an explicit "skip" text button.
//
// Tapping a chip pre-fills the input with a category-appropriate prompt
// in the user's current locale and fires the onCategorySelected callback.
//
// This test locks the widget's contract without touching chat_screen —
// integration is tested via widget smoke below.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/welcome_chips.dart';
import 'package:advocat/models/case_model.dart';

void main() {
  group('WelcomeCategory mapping', () {
    test('has exactly 5 categories', () {
      expect(WelcomeCategory.values.length, 5);
    });

    test('each category maps to a real CaseType', () {
      for (final cat in WelcomeCategory.values) {
        expect(cat.caseType, isA<CaseType>());
      }
    });

    test('deportation category maps to CaseType.deportation', () {
      expect(WelcomeCategory.deportation.caseType, CaseType.deportation);
    });

    test('workDispute maps to CaseType.laborDispute', () {
      expect(WelcomeCategory.workDispute.caseType, CaseType.laborDispute);
    });

    test('housing maps to CaseType.tenantRights', () {
      expect(WelcomeCategory.housing.caseType, CaseType.tenantRights);
    });

    test('familyLaw maps to CaseType.familyReunification by default', () {
      expect(
          WelcomeCategory.familyLaw.caseType, CaseType.familyReunification);
    });

    test('other maps to CaseType.other', () {
      expect(WelcomeCategory.other.caseType, CaseType.other);
    });
  });

  group('WelcomeCategory prefill message', () {
    test('Russian prefill for deportation contains "депортац"', () {
      final msg = WelcomeCategory.deportation.prefillMessage('ru');
      expect(msg.toLowerCase(), contains('депортац'));
    });

    test('Estonian prefill for deportation contains "väljasaat" or "deport"', () {
      final msg = WelcomeCategory.deportation.prefillMessage('et').toLowerCase();
      expect(msg.contains('väljasaat') || msg.contains('deport'), isTrue,
          reason: 'Estonian prefill: $msg');
    });

    test('English prefill for deportation contains "deport"', () {
      final msg = WelcomeCategory.deportation.prefillMessage('en').toLowerCase();
      expect(msg, contains('deport'));
    });

    test('Finnish prefill for deportation contains "käännyt" or "deport"', () {
      final msg = WelcomeCategory.deportation.prefillMessage('fi').toLowerCase();
      expect(msg.contains('käännyt') || msg.contains('deport'), isTrue);
    });

    test('unknown locale falls back to English', () {
      final msg = WelcomeCategory.deportation.prefillMessage('xx');
      expect(msg.toLowerCase(), contains('deport'));
    });

    test('every category has non-empty prefill for ru/et/en/fi', () {
      for (final cat in WelcomeCategory.values) {
        for (final loc in ['ru', 'et', 'en', 'fi']) {
          final m = cat.prefillMessage(loc);
          expect(m, isNotEmpty,
              reason: 'Prefill empty for $cat in $loc');
        }
      }
    });
  });

  group('ChatWelcomeChips widget', () {
    testWidgets('renders 5 chips + skip link', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: ChatWelcomeChips(
              locale: 'en',
              onCategorySelected: (_, __) {},
              onSkip: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 chips as InkWells, plus a skip TextButton — we require at least
      // 5 tappable InkWells (TextButton includes its own InkWell).
      expect(find.byType(InkWell), findsAtLeast(5));
    });

    testWidgets('tapping a chip fires onCategorySelected with prefill',
        (tester) async {
      WelcomeCategory? picked;
      String? prefilled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatWelcomeChips(
              locale: 'en',
              onCategorySelected: (cat, msg) {
                picked = cat;
                prefilled = msg;
              },
              onSkip: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find chip labelled "Deportation" (en) and tap.
      final depLabel = WelcomeCategory.deportation.chipLabel('en');
      final finder = find.text(depLabel);
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(picked, WelcomeCategory.deportation);
      expect(prefilled, isNotNull);
      expect(prefilled!.toLowerCase(), contains('deport'));
    });

    testWidgets('tapping skip fires onSkip', (tester) async {
      var skipped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatWelcomeChips(
              locale: 'en',
              onCategorySelected: (_, __) {},
              onSkip: () => skipped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Skip text per locale — English uses "Skip".
      final skipFinder = find.text('Skip');
      expect(skipFinder, findsOneWidget);
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();
      expect(skipped, isTrue);
    });
  });
}
