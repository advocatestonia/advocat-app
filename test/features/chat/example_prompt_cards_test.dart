// example_prompt_cards_test.dart
//
// Backlog #36 Layer 4 — empty-state example prompt cards.
//
// Lock the widget contract: 3 cards render, each is tappable, each fires
// onPromptSelected with the localized text. Independent of chat_screen
// (it's wired in there as a list slot — that integration is exercised
// elsewhere).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/example_prompt_cards.dart';

void main() {
  group('ExamplePromptCards — rendering', () {
    testWidgets('renders exactly 3 cards in EN', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamplePromptCards(
              locale: 'en',
              onPromptSelected: (_, {required bool autoSend}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('example_prompt_translate')),
          findsOneWidget);
      expect(find.byKey(const Key('example_prompt_landlord')),
          findsOneWidget);
      expect(find.byKey(const Key('example_prompt_nda')), findsOneWidget);
    });

    testWidgets('EN cards show the spec-mandated prompt copy',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamplePromptCards(
              locale: 'en',
              onPromptSelected: (_, {required bool autoSend}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Translate this contract from German to Estonian'),
        findsOneWidget,
      );
      expect(
        find.text('What are my rights if my landlord raises rent?'),
        findsOneWidget,
      );
      expect(
        find.text('Draft a non-disclosure agreement for a freelancer'),
        findsOneWidget,
      );
    });

    testWidgets('ET locale renders Estonian copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamplePromptCards(
              locale: 'et',
              onPromptSelected: (_, {required bool autoSend}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // ET translation card must contain Estonian "saksa" (German) keyword.
      expect(find.textContaining('saksa'), findsOneWidget);
    });

    testWidgets('RU locale renders Russian copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamplePromptCards(
              locale: 'ru',
              onPromptSelected: (_, {required bool autoSend}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // RU translation card must contain Cyrillic "немецкого".
      expect(find.textContaining('немецкого'), findsOneWidget);
    });
  });

  group('ExamplePromptCards — interaction', () {
    testWidgets(
        'tapping a card fires onPromptSelected with prompt text and autoSend=true',
        (tester) async {
      String? got;
      bool? gotAutoSend;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamplePromptCards(
              locale: 'en',
              onPromptSelected: (s, {required bool autoSend}) {
                got = s;
                gotAutoSend = autoSend;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('example_prompt_nda')));
      await tester.pumpAndSettle();

      expect(got, isNotNull);
      expect(got, contains('non-disclosure'));
      // FIX-WAVE 6 (2026-05-20 — onboarding speedup B): tap = auto-send.
      expect(gotAutoSend, isTrue);
    });

    testWidgets(
        'long-pressing a card fires onPromptSelected with autoSend=false (edit mode)',
        (tester) async {
      String? got;
      bool? gotAutoSend;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamplePromptCards(
              locale: 'en',
              onPromptSelected: (s, {required bool autoSend}) {
                got = s;
                gotAutoSend = autoSend;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('example_prompt_landlord')));
      await tester.pumpAndSettle();

      expect(got, isNotNull);
      expect(got, contains('landlord'));
      // Long-press preserves the pre-fill-only behavior so the user
      // can edit the example before sending.
      expect(gotAutoSend, isFalse);
    });

    testWidgets('FI tap returns Finnish text', (tester) async {
      String? got;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamplePromptCards(
              locale: 'fi',
              onPromptSelected: (s, {required bool autoSend}) => got = s,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('example_prompt_landlord')));
      await tester.pumpAndSettle();

      expect(got, isNotNull);
      // "vuokra" = rent in Finnish — must appear in the landlord prompt.
      expect(got!.toLowerCase(), contains('vuokra'));
    });
  });
}
