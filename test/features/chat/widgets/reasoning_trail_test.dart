@Tags(['fast'])
library;

// =============================================================================
// reasoning_trail_test.dart — widget tests for the visible reasoning pill.
// =============================================================================
//
// Reasoning Trail v1 (2026-05-05). Pins:
//   • Renders idle pill on creation
//   • Rotates caption on event
//   • Throttles caption rotation to ≥ 2.5s
//   • Collapses ~400ms after first TextDelta
//   • Tap collapsed pill toggles expanded view (and back)
//
// Uses FakeAsync to drive the throttle/collapse timers without sleeping.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocat/features/chat/widgets/reasoning_trail.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/chat_stream_event.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReasoningTrail — initial render', () {
    testWidgets('renders idle pill on creation', (tester) async {
      final ctrl = StreamController<ChatStreamEvent>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(ReasoningTrail(events: ctrl.stream)));
      await tester.pump(); // First frame

      expect(find.text('Thinking…'), findsOneWidget);
    });
  });

  group('ReasoningTrail — caption rotation', () {
    testWidgets('rotates caption on ToolUseStart', (tester) async {
      final ctrl = StreamController<ChatStreamEvent>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(ReasoningTrail(events: ctrl.stream)));
      await tester.pump();

      ctrl.add(const ToolUseStart('search_estonian_law', 't1'));
      // Pump past the 240ms AnimatedSwitcher transition so the old caption
      // is fully gone before assertions.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Searching Estonian law…'), findsOneWidget);
      expect(find.text('Thinking…'), findsNothing);
    });

    testWidgets('rotates on ThinkingDelta with first sentence cap', (tester) async {
      final ctrl = StreamController<ChatStreamEvent>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(ReasoningTrail(events: ctrl.stream)));
      await tester.pump();

      ctrl.add(const ThinkingDelta('Reading the deportation order. Then I check.'));
      await tester.pump();

      expect(find.text('Reading the deportation order'), findsOneWidget);
    });
  });

  group('ReasoningTrail — throttle (2.5s minimum)', () {
    testWidgets('drops second caption arriving before 2.5s elapses', (tester) async {
      final ctrl = StreamController<ChatStreamEvent>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(ReasoningTrail(events: ctrl.stream)));
      await tester.pump();

      // First update — accepted.
      ctrl.add(const ToolUseStart('search_estonian_law', 't1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Searching Estonian law…'), findsOneWidget);

      // Second update — only 100ms later, should be dropped (throttle).
      ctrl.add(const ToolUseStart('check_company', 't2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('Searching Estonian law…'),
        findsOneWidget,
        reason: 'second caption dropped by throttle',
      );
      expect(find.text('Checking company registry…'), findsNothing);
    });

    testWidgets('accepts second caption after 2.5s elapses', (tester) async {
      final ctrl = StreamController<ChatStreamEvent>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(ReasoningTrail(events: ctrl.stream)));
      await tester.pump();

      ctrl.add(const ToolUseStart('search_estonian_law', 't1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Wait full throttle window. The throttle uses a Timer (not wall
      // clock), so fake-clock pumps unlock it correctly.
      await tester.pump(const Duration(milliseconds: 2600));

      ctrl.add(const ToolUseStart('check_company', 't2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Checking company registry…'), findsOneWidget);
    });
  });

  group('ReasoningTrail — collapse on first TextDelta', () {
    testWidgets('collapses 400ms after first TextDelta arrives', (tester) async {
      final ctrl = StreamController<ChatStreamEvent>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(ReasoningTrail(events: ctrl.stream)));
      await tester.pump();

      ctrl.add(const TextDelta('Per VSS § 17, '));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Still expanded — only 100ms elapsed.
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
      // Now collapsed — check_circle_outline shown in summary chip.
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('Reasoned for'), findsOneWidget);
    });

    testWidgets('collapses immediately on MessageDone', (tester) async {
      final ctrl = StreamController<ChatStreamEvent>();
      bool closeCalled = false;
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(
        ReasoningTrail(
          events: ctrl.stream,
          onClose: () => closeCalled = true,
        ),
      ));
      await tester.pump();

      ctrl.add(const MessageDone(thinkingMs: 1200, sources: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(closeCalled, isTrue);
    });
  });

  group('ReasoningTrail — tap collapsed', () {
    testWidgets('tap collapsed pill toggles expanded list', (tester) async {
      final ctrl = StreamController<ChatStreamEvent>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(ReasoningTrail(events: ctrl.stream)));
      await tester.pump();

      // Drive two stages then collapse.
      ctrl.add(const ToolUseStart('search_estonian_law', 't1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      ctrl.add(const TextDelta('answer text'));
      await tester.pump(const Duration(milliseconds: 500)); // collapse done

      // Initially collapsed and NOT user-expanded → no step list.
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);

      // Tap the collapsed pill body to expand.
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      // The step list now contains the previous tool caption.
      expect(find.text('Searching Estonian law…'), findsOneWidget);

      // Tap again to collapse back.
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pump();

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });
}
