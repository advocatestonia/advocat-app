// =============================================================================
// Regression guard for HomeScreen _QuickActions tile layout.
// =============================================================================
//
// On 2026-04-29 the owner asked to remove the duplicate "Pro" CTA from the
// quick-action grid (Pro now lives ONLY in the full-width PremiumUpgradeCard
// below the tiles), move the pulsing AI Assistant tile from row1#2 to row2#3,
// and put a new Checker tile in the freed row1#2 slot.
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

    test('row2#3 is the pulsing AI Assistant tile (moved from row1#2)', () {
      // The single remaining _PulsingQuickActionButton invocation must point
      // at /chat/general and sit between email and callAI tiles.
      final pulsingIdx = source.indexOf('_PulsingQuickActionButton(');
      expect(pulsingIdx, greaterThan(0),
          reason: 'Pulsing AI tile must still exist');

      // It must come after the email tile and before the callAI tile.
      final emailIdx = source.indexOf('label: l.email');
      final callAIIdx = source.indexOf('label: l.callAI');
      expect(emailIdx, greaterThan(0));
      expect(callAIIdx, greaterThan(emailIdx));
      expect(pulsingIdx, greaterThan(emailIdx),
          reason: 'Pulsing AI tile must come after email tile');
      expect(pulsingIdx, lessThan(callAIIdx),
          reason: 'Pulsing AI tile must come before callAI tile (row2#3)');

      // It must still route to /chat/general and use aiAssistant label.
      final pulsingEnd = source.indexOf('),', pulsingIdx);
      final pulsingBlock = source.substring(pulsingIdx, pulsingEnd + 2);
      expect(pulsingBlock, contains("'/chat/general'"),
          reason: 'Pulsing AI tile must keep its /chat/general route');
      expect(pulsingBlock, contains('l.aiAssistant'),
          reason: 'Pulsing AI tile must keep aiAssistant label');
    });

    test(
        'no _AdvocatProQuickActionButton tile in quick-actions grid '
        '(Pro CTA lives only in PremiumUpgradeCard)', () {
      expect(source.contains('_AdvocatProQuickActionButton'), isFalse,
          reason:
              '_AdvocatProQuickActionButton must be removed — the duplicate '
              'Pro tile is gone, Pro CTA lives only in _PremiumUpgradeCard');
    });

    test('exactly one _PulsingQuickActionButton invocation in the grid', () {
      // Class definition + state class + single invocation = 3 occurrences
      // of the literal string. If anyone re-adds a second pulsing tile this
      // count goes up.
      final allMatches = '_PulsingQuickActionButton('.allMatches(source);
      // 1 invocation site + 1 constructor signature
      expect(allMatches.length, 2,
          reason:
              'Expected exactly one _PulsingQuickActionButton invocation '
              'plus its constructor; found ${allMatches.length} matches');
    });
  });
}
