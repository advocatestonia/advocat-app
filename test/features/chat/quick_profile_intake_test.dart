@Tags(['fast'])
library;

// =============================================================================
// quick_profile_intake_test.dart — Quick Profile intake (2026-05-05)
// =============================================================================
//
// Why this exists:
//   Memory Tier 2 (commit aec133a) added legal_status / nationality /
//   residence_status to the bounded vocabulary, but the AI only learns them
//   if the user happens to mention their status in a regular chat. For
//   first-time users we need a one-shot intake that asks the question once
//   and never again.
//
// Contract under test:
//   - QuickProfileGate.shouldShow() returns true ONLY when there is no
//     `legal_status` memory AND the SharedPreferences flag
//     `advocat_quick_profile_completed_at` is unset.
//   - QuickProfileGate.markCompleted() writes the timestamp flag.
//   - The QuickProfileIntake widget renders the localised question + four
//     chips (Estonian citizen / EU citizen / Residence permit / Skip).
//   - Tapping a status chip fires onAnswer with the structured answer
//     (key=legal_status, value=<canonical English label>).
//   - Tapping skip fires onSkip (no extract-memory call from the parent).
//   - Free-text fallback is still possible — the widget exposes the input
//     to the regular chat composer; the test for that lives in chat_screen
//     integration (out of scope here — this test pins the widget surface).
//
// Why widget-level + pure helpers, not full chat_screen integration:
//   chat_screen.dart is 4000+ LoC. A full pump would drag in supabase auth,
//   AIService, voice, telemetry, half a dozen riverpod providers — slow and
//   flaky. We test the intake unit in isolation and the gate decision
//   helpers as pure functions. The chat_screen wiring is mechanical and
//   covered by manual smoke + the existing chat_provider tests.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocat/features/chat/quick_profile/quick_profile_gate.dart';
import 'package:advocat/features/chat/quick_profile/quick_profile_intake.dart';
import 'package:advocat/models/user_memory.dart';

void main() {
  // =========================================================================
  // QuickProfileGate.shouldShow — pure decision logic
  // =========================================================================

  group('QuickProfileGate.shouldShow', () {
    setUp(() async {
      // Each test starts with empty SharedPreferences so flag-not-set is
      // the default; tests that need the flag set it explicitly.
      SharedPreferences.setMockInitialValues({});
    });

    test('returns true when no legal_status memory + no flag set', () async {
      final show = await QuickProfileGate.shouldShow(memories: const []);
      expect(show, isTrue);
    });

    test('returns false when legal_status memory already exists', () async {
      final mem = UserMemory(
        id: 'm1',
        key: 'legal_status',
        text: '3rd country national with humanitarian residence permit',
        confidence: 0.95,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        lastReinforcedAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      final show = await QuickProfileGate.shouldShow(memories: [mem]);
      expect(show, isFalse,
          reason: 'A user who already told us their status must not be '
              're-asked — that\'s the whole point of remembering.');
    });

    test('returns false when nationality memory exists (any legal-status key)',
        () async {
      // legal_status / nationality / residence_status are all gates.
      final mem = UserMemory(
        id: 'm2',
        key: 'nationality',
        text: 'EE',
        confidence: 0.9,
        createdAt: DateTime.now(),
        lastReinforcedAt: DateTime.now(),
      );
      final show = await QuickProfileGate.shouldShow(memories: [mem]);
      expect(show, isFalse);
    });

    test('returns false when SharedPreferences flag set, even if memory empty',
        () async {
      SharedPreferences.setMockInitialValues({
        'advocat_quick_profile_completed_at':
            DateTime.now().toUtc().toIso8601String(),
      });
      final show = await QuickProfileGate.shouldShow(memories: const []);
      expect(show, isFalse,
          reason: 'A user who skipped intake should not see it again, even '
              'if extract-memory came back empty for them.');
    });

    test('ignores unrelated memory keys (tone, preference, etc.)', () async {
      final mem = UserMemory(
        id: 'm3',
        key: 'tone',
        text: 'You prefer short replies',
        confidence: 0.8,
        createdAt: DateTime.now(),
        lastReinforcedAt: DateTime.now(),
      );
      final show = await QuickProfileGate.shouldShow(memories: [mem]);
      expect(show, isTrue,
          reason: 'Only the legal-status trio gates the intake.');
    });
  });

  group('QuickProfileGate.markCompleted', () {
    test('writes the localStorage flag with a timestamp string', () async {
      SharedPreferences.setMockInitialValues({});
      await QuickProfileGate.markCompleted();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('advocat_quick_profile_completed_at');
      expect(stored, isNotNull);
      // Must parse as a valid ISO-8601 datetime so we can later display
      // "you completed onboarding on …" in settings if we ever want to.
      expect(() => DateTime.parse(stored!), returnsNormally);
    });

    test('shouldShow returns false after markCompleted', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await QuickProfileGate.shouldShow(memories: const []), isTrue);
      await QuickProfileGate.markCompleted();
      expect(await QuickProfileGate.shouldShow(memories: const []), isFalse);
    });
  });

  // =========================================================================
  // QuickProfileAnswer — canonical labels per chip
  // =========================================================================

  group('QuickProfileAnswer canonical mapping', () {
    test('Estonian citizen → legal_status=citizen + nationality=EE', () {
      final ans = QuickProfileAnswer.estonianCitizen.toFacts();
      expect(ans, hasLength(2));
      expect(
        ans.firstWhere((f) => f.key == 'legal_status').value,
        contains('citizen'),
      );
      expect(
        ans.firstWhere((f) => f.key == 'nationality').value,
        'EE',
      );
    });

    test('EU citizen → legal_status=eu_citizen', () {
      final ans = QuickProfileAnswer.euCitizen.toFacts();
      expect(ans.any((f) => f.key == 'legal_status'), isTrue);
      expect(
        ans.firstWhere((f) => f.key == 'legal_status').value.toLowerCase(),
        contains('eu'),
      );
    });

    test('Residence permit → legal_status=3rd_country + residence_status', () {
      final ans = QuickProfileAnswer.residencePermit.toFacts();
      expect(ans.any((f) => f.key == 'legal_status'), isTrue);
      expect(ans.any((f) => f.key == 'residence_status'), isTrue);
      // Per ADR-001, 3rd_country is the legal-status enum value used when
      // the user is not a citizen and not an EU citizen. The residence
      // status defaults to "temporary" for the permit chip — temporary is
      // the most common case and cheap to correct in chat later.
      expect(
        ans.firstWhere((f) => f.key == 'legal_status').value,
        contains('3rd_country'),
      );
    });

    test('Skip yields zero facts (nothing to extract)', () {
      expect(QuickProfileAnswer.skip.toFacts(), isEmpty);
    });
  });

  // =========================================================================
  // QuickProfileIntake widget — render + interaction
  // =========================================================================

  group('QuickProfileIntake widget', () {
    Widget wrap(Widget child) => MaterialApp(
          home: Scaffold(body: child),
        );

    testWidgets('renders prompt + 4 chips in EN', (tester) async {
      await tester.pumpWidget(wrap(
        QuickProfileIntake(
          locale: 'en',
          onAnswer: (_) {},
          onSkip: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // The prompt copy contains a recognisable anchor in every locale
      // ("status" in EN, "статус" in RU, "staatus" in ET).
      expect(
        find.textContaining(RegExp('status', caseSensitive: false)),
        findsWidgets,
      );

      // 4 tappable chips: Estonian citizen / EU citizen / Residence / Skip
      expect(find.byType(InkWell), findsAtLeast(4));
    });

    testWidgets('renders RU prompt with "гражданин" anchor', (tester) async {
      await tester.pumpWidget(wrap(
        QuickProfileIntake(
          locale: 'ru',
          onAnswer: (_) {},
          onSkip: () {},
        ),
      ));
      await tester.pumpAndSettle();
      // The prompt uses "гражданин Эстонии / гражданин ЕС" which is the
      // natural Russian phrasing for the legal-status question — pin
      // it so a future copy edit can't silently strip the anchor.
      expect(
        find.textContaining(RegExp('гражданин', caseSensitive: false)),
        findsWidgets,
      );
    });

    testWidgets('renders ET prompt with "staatus" or "kodakondsus" anchor',
        (tester) async {
      await tester.pumpWidget(wrap(
        QuickProfileIntake(
          locale: 'et',
          onAnswer: (_) {},
          onSkip: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
            RegExp('staatus|kodakondsus|elamisluba', caseSensitive: false)),
        findsWidgets,
      );
    });

    testWidgets('tapping Estonian-citizen chip fires onAnswer with that enum',
        (tester) async {
      QuickProfileAnswer? picked;
      await tester.pumpWidget(wrap(
        QuickProfileIntake(
          locale: 'en',
          onAnswer: (a) => picked = a,
          onSkip: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final chip = find.text('Estonian citizen');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(picked, QuickProfileAnswer.estonianCitizen);
    });

    testWidgets('tapping EU-citizen chip fires onAnswer with that enum',
        (tester) async {
      QuickProfileAnswer? picked;
      await tester.pumpWidget(wrap(
        QuickProfileIntake(
          locale: 'en',
          onAnswer: (a) => picked = a,
          onSkip: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Use the canonical chip label. The prompt above also mentions
      // "EU citizen", so a substring match would be ambiguous — pin to
      // the exact chip label that ships in the public API
      // (`quickProfileAnswerLabel(...)`).
      final chip = find.text('EU citizen (other)');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(picked, QuickProfileAnswer.euCitizen);
    });

    testWidgets('tapping Residence-permit chip fires onAnswer with that enum',
        (tester) async {
      QuickProfileAnswer? picked;
      await tester.pumpWidget(wrap(
        QuickProfileIntake(
          locale: 'en',
          onAnswer: (a) => picked = a,
          onSkip: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final chip = find.text('Residence permit');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(picked, QuickProfileAnswer.residencePermit);
    });

    testWidgets('tapping Skip fires onSkip and NOT onAnswer', (tester) async {
      QuickProfileAnswer? picked;
      var skipped = false;
      await tester.pumpWidget(wrap(
        QuickProfileIntake(
          locale: 'en',
          onAnswer: (a) => picked = a,
          onSkip: () => skipped = true,
        ),
      ));
      await tester.pumpAndSettle();

      final skip = find.text('Skip');
      expect(skip, findsOneWidget);
      await tester.tap(skip);
      await tester.pumpAndSettle();

      expect(skipped, isTrue);
      expect(picked, isNull,
          reason: 'Skip is a separate path — must not call onAnswer.');
    });
  });
}
