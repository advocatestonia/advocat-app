// =============================================================================
// Regression guard for HomeScreen _QuickActions tile layout.
// =============================================================================
//
// On 2026-04-29 the owner asked to remove the duplicate "Pro" CTA from the
// quick-action grid (Pro now lives ONLY in the full-width PremiumUpgradeCard
// below the tiles), move the pulsing AI Assistant tile from row1#2 to row2#3,
// and put a new Checker tile in the freed row1#2 slot.
//
// Later same day: the owner asked to keep the "shield" visual on the AI
// Assistant tile (the look that used to belong to the removed Pro tile —
// scale animation + accent shadow + shield_pro.png). We restored that visual
// as a parameterized widget `_ShieldPulsingButton` that routes to /chat/general
// instead of /subscription. The original `_AdvocatProQuickActionButton` class
// stays deleted; tests below assert on the new `_ShieldPulsingButton`.
//
// We don't boot HomeScreen widget here — Riverpod + Supabase + GoRouter
// scaffolding is heavy and the change is purely structural. Instead we read
// the source file and assert the order of widget invocations inside the
// `_QuickActions` build, plus the absence of the now-removed
// `_AdvocatProQuickActionButton` class. Same lightweight-regression style as
// `launch_wave1_ux_test.dart`.
//
// If a future refactor moves these widgets, update these assertions
// deliberately — the test exists to make accidental shuffles loud.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen _QuickActions layout (2026-04-29 reshuffle)', () {
    late String source;

    setUpAll(() {
      source = File('lib/features/home/screens/home_screen.dart')
          .readAsStringSync();
    });

    test('row1#2 is Checker tile (replaces former AI Assistant pulsing tile)',
        () {
      // Find the _QuickActions class body.
      final classStart = source.indexOf('class _QuickActions');
      expect(classStart, greaterThan(0),
          reason: '_QuickActions class missing');

      // After scanDocument tile, the next tile must be the Checker tile.
      final scanIdx = source.indexOf('label: l.scanDocument', classStart);
      final checkerLabelIdx =
          source.indexOf('label: l.checkerTitle', scanIdx);
      final legalSectionLabelIdx =
          source.indexOf('label: l.legalSection', scanIdx);

      expect(checkerLabelIdx, greaterThan(scanIdx),
          reason: 'Checker tile must come after scanDocument tile');
      expect(checkerLabelIdx, lessThan(legalSectionLabelIdx),
          reason: 'Checker tile must come before legalSection tile (row1#2)');

      // Build a wider window covering the whole Checker tile constructor
      // call: from the previous `_QuickActionButton(` opener up to
      // legalSection's label (next tile).
      final checkerStart = source.lastIndexOf(
          '_QuickActionButton(', checkerLabelIdx);
      expect(checkerStart, greaterThan(scanIdx),
          reason: 'Checker tile constructor call not found');
      final checkerBlock =
          source.substring(checkerStart, legalSectionLabelIdx);
      expect(checkerBlock, contains('AppRoutes.checker'),
          reason: 'Checker tile must navigate to AppRoutes.checker');
      expect(checkerBlock, contains('Icons.verified_user_rounded'),
          reason: 'Checker tile should use verified_user_rounded icon');
    });

    test('row2#3 is the shield-pulsing AI Assistant tile (moved from row1#2)',
        () {
      // The single _ShieldPulsingButton invocation must point at /chat/general
      // and sit between email and callAI tiles.
      final pulsingIdx = source.indexOf('_ShieldPulsingButton(');
      expect(pulsingIdx, greaterThan(0),
          reason: 'Shield-pulsing AI tile must still exist');

      // It must come after the email tile and before the callAI tile.
      final emailIdx = source.indexOf('label: l.email');
      final callAIIdx = source.indexOf('label: l.callAI');
      expect(emailIdx, greaterThan(0));
      expect(callAIIdx, greaterThan(emailIdx));
      expect(pulsingIdx, greaterThan(emailIdx),
          reason: 'Shield-pulsing AI tile must come after email tile');
      expect(pulsingIdx, lessThan(callAIIdx),
          reason:
              'Shield-pulsing AI tile must come before callAI tile (row2#3)');

      // It must still route to /chat/general and use aiAssistant label.
      final pulsingEnd = source.indexOf('),', pulsingIdx);
      final pulsingBlock = source.substring(pulsingIdx, pulsingEnd + 2);
      expect(pulsingBlock, contains("'/chat/general'"),
          reason:
              'Shield-pulsing AI tile must keep its /chat/general route');
      expect(pulsingBlock, contains('l.aiAssistant'),
          reason: 'Shield-pulsing AI tile must keep aiAssistant label');
    });

    test('shield-pulsing tile uses shield_pro.png artwork', () {
      // The _ShieldPulsingButton implementation must render the shield image —
      // that is the entire point of restoring this visual.
      final classStart = source.indexOf('class _ShieldPulsingButton');
      expect(classStart, greaterThan(0),
          reason: '_ShieldPulsingButton class must exist');
      final classBody = source.substring(classStart);
      expect(classBody, contains("'assets/images/shield_pro.png'"),
          reason:
              '_ShieldPulsingButton must render shield_pro.png — that is the '
              'whole reason it exists (owner wanted the shield visual back)');
    });

    test(
        'no _AdvocatProQuickActionButton tile in quick-actions grid '
        '(Pro CTA lives only in PremiumUpgradeCard)', () {
      expect(source.contains('_AdvocatProQuickActionButton'), isFalse,
          reason:
              '_AdvocatProQuickActionButton must be removed — the duplicate '
              'Pro tile is gone, Pro CTA lives only in _PremiumUpgradeCard');
    });

    test(
        '_PulsingQuickActionButton is gone (replaced by _ShieldPulsingButton)',
        () {
      // The intermediate widget that briefly held this slot (with a balance
      // icon) was replaced by _ShieldPulsingButton on the same day. Make sure
      // nobody re-introduces it accidentally.
      expect(source.contains('_PulsingQuickActionButton'), isFalse,
          reason:
              '_PulsingQuickActionButton must be removed — the AI Assistant '
              'tile uses _ShieldPulsingButton (shield artwork) now');
    });

    test('exactly one _ShieldPulsingButton invocation in the grid', () {
      // Constructor signature + invocation site = 2 occurrences of the
      // literal string `_ShieldPulsingButton(`. The state class and class
      // header use the bare name without `(` so they don't count.
      final allMatches = '_ShieldPulsingButton('.allMatches(source);
      expect(allMatches.length, 2,
          reason:
              'Expected exactly one _ShieldPulsingButton invocation plus its '
              'constructor; found ${allMatches.length} matches');
    });
  });
}
