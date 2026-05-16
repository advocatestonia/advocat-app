// welcome_modal_test.dart
//
// Backlog #36 — first-time user onboarding.
//
// Locks the contract of the post-signup welcome modal:
//   - Renders 3 quick-action cards (sample / upload / ask)
//   - Renders a "Skip" text button that returns WelcomeAction.skip
//   - Each card returns its corresponding WelcomeAction
//   - Localizes headline for EN/ET/FI/RU
//
// The modal is pure UI — no Riverpod, no Supabase. Safe to test in
// isolation with a vanilla MaterialApp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/onboarding/widgets/welcome_modal.dart';

void main() {
  group('WelcomeModal — rendering', () {
    testWidgets('renders all 3 action cards + skip in EN', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WelcomeModal(locale: 'en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Advocat'), findsOneWidget);
      expect(find.byKey(const Key('welcome_modal_sample')), findsOneWidget);
      expect(find.byKey(const Key('welcome_modal_upload')), findsOneWidget);
      expect(find.byKey(const Key('welcome_modal_ask')), findsOneWidget);
      expect(find.byKey(const Key('welcome_modal_skip')), findsOneWidget);
    });

    testWidgets('localizes headline for ET', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WelcomeModal(locale: 'et')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tere tulemast Advocati'), findsOneWidget);
    });

    testWidgets('localizes headline for FI', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WelcomeModal(locale: 'fi')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tervetuloa Advocatiin'), findsOneWidget);
    });

    testWidgets('localizes headline for RU', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WelcomeModal(locale: 'ru')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Добро пожаловать в Advocat'), findsOneWidget);
    });

    testWidgets('unknown locale falls back to EN', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WelcomeModal(locale: 'xx')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Advocat'), findsOneWidget);
    });
  });

  group('showWelcomeModal — return values', () {
    Future<WelcomeAction> open(WidgetTester tester, Key cardKey) async {
      WelcomeAction? out;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    out = await showWelcomeModal(ctx, locale: 'en');
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
      // The featured upload card (Bentley P8 reorder, 2026-05-16) made the
      // modal taller than the default 800x600 test viewport — the lower
      // cards can scroll partially off-screen. `ensureVisible` brings the
      // target row into the SingleChildScrollView before we tap it.
      await tester.ensureVisible(find.byKey(cardKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(cardKey));
      await tester.pumpAndSettle();
      return out!;
    }

    testWidgets('sample card returns WelcomeAction.sampleCase',
        (tester) async {
      final got = await open(tester, const Key('welcome_modal_sample'));
      expect(got, WelcomeAction.sampleCase);
    });

    testWidgets('upload card returns WelcomeAction.uploadContract',
        (tester) async {
      final got = await open(tester, const Key('welcome_modal_upload'));
      expect(got, WelcomeAction.uploadContract);
    });

    testWidgets('ask card returns WelcomeAction.askQuestion',
        (tester) async {
      final got = await open(tester, const Key('welcome_modal_ask'));
      expect(got, WelcomeAction.askQuestion);
    });

    testWidgets('skip button returns WelcomeAction.skip', (tester) async {
      final got = await open(tester, const Key('welcome_modal_skip'));
      expect(got, WelcomeAction.skip);
    });
  });
}
