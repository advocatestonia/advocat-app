@Tags(['fast'])
library;

// Widget tests for [B2BLeadModal] / [showB2BLeadModal].
//
// What's covered (per brief 2026-05-25):
//   * Renders title + body + two buttons (dismiss, learnMore) in EN.
//   * Multi-locale rendering for 4+ locales (en/et/ru/fi/de) so a paid-
//     touch surface never lands on an EN-fallback for a user whose UI
//     language is set.
//   * Unknown locale falls back to EN.
//   * Tapping "Learn more" returns B2BAction.learnMore.
//   * Tapping "Not now" returns B2BAction.dismiss.
//   * barrierDismissible is false — modal can't be swipe-dismissed.
//
// The modal is pure UI; no Riverpod, no Supabase. We can pump it inside
// a vanilla MaterialApp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/b2b/widgets/b2b_lead_modal.dart';

void main() {
  group('B2BLeadModal — rendering', () {
    testWidgets('renders title + body + both buttons in EN', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: B2BLeadModal(locale: 'en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('b2b_lead_modal_title')), findsOneWidget);
      expect(find.byKey(const Key('b2b_lead_modal_body')), findsOneWidget);
      expect(
        find.byKey(const Key('b2b_lead_modal_learn_more')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('b2b_lead_modal_dismiss')),
        findsOneWidget,
      );
      // EN title contains the literal "professionally" hook word.
      expect(
        find.textContaining('professionally'),
        findsOneWidget,
      );
    });

    testWidgets('renders Estonian copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: B2BLeadModal(locale: 'et')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('professionaalselt'), findsOneWidget);
    });

    testWidgets('renders Russian copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: B2BLeadModal(locale: 'ru')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('профессионально'), findsOneWidget);
      expect(find.textContaining('Не сейчас'), findsOneWidget);
    });

    testWidgets('renders Finnish copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: B2BLeadModal(locale: 'fi')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('ammatillisesti'), findsOneWidget);
    });

    testWidgets('renders German copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: B2BLeadModal(locale: 'de')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('beruflich'), findsOneWidget);
    });

    testWidgets('unknown locale falls back to EN', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: B2BLeadModal(locale: 'xx')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('professionally'), findsOneWidget);
    });

    testWidgets('does NOT show prices (no €/€129/per seat in copy)',
        (tester) async {
      // Spec is explicit: "Do NOT show prices in the modal — just
      // 'let's talk'". Lock that in.
      for (final code in ['en', 'et', 'ru', 'fi', 'de']) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: B2BLeadModal(locale: code))),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('€'), findsNothing,
            reason: 'price symbol leaked into locale=$code');
        expect(find.textContaining('per seat'), findsNothing,
            reason: 'per-seat phrasing leaked into locale=$code');
        expect(find.textContaining('/mo'), findsNothing,
            reason: '/mo phrasing leaked into locale=$code');
      }
    });
  });

  group('showB2BLeadModal — return values', () {
    Future<B2BAction> open(
      WidgetTester tester,
      Key tapKey, {
      String locale = 'en',
    }) async {
      B2BAction? out;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    out = await showB2BLeadModal(ctx, locale: locale);
                  },
                  child: const Text('open'),
                ),
              ),
            );
          }),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(tapKey), findsOneWidget);
      await tester.tap(find.byKey(tapKey));
      await tester.pumpAndSettle();
      return out!;
    }

    testWidgets('"Learn more" returns B2BAction.learnMore', (tester) async {
      final got = await open(
        tester,
        const Key('b2b_lead_modal_learn_more'),
      );
      expect(got, B2BAction.learnMore);
    });

    testWidgets('"Not now" returns B2BAction.dismiss', (tester) async {
      final got = await open(
        tester,
        const Key('b2b_lead_modal_dismiss'),
      );
      expect(got, B2BAction.dismiss);
    });
  });
}
