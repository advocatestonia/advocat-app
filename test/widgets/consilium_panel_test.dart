@Tags(['fast'])
library;

// =============================================================================
// consilium_panel_test.dart — widget tests for the Phase 1 Consilium UI.
// =============================================================================
//
// Covers four user-visible states:
//   1. Empty events list                → ConsiliumPanel renders nothing.
//   2. Start + 3 RoleOpinion (of 5)     → 3 ready cards + 2 loading skeletons.
//   3. Done + disagreement              → DisagreementBanner appears + footer.
//   4. SynthesisStart (no Done)         → "Synthesizing…" indicator visible.
//
// [ChatStreamEvent] is `sealed`, so test code can't extend it from outside
// its library. Instead we drive [ConsiliumPanel] via:
//   * the public `events: []` path for the empty case, and
//   * the @visibleForTesting `ConsiliumPanel.fromSnapshot(...)` constructor
//     backed by `ConsiliumSnapshot.fromMaps(...)` for all other states.
// The map-shape under test is the same one the production fromEvents()
// parser populates from runtime-type-name dispatch.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/consilium_panel.dart';
import 'package:advocat/features/chat/widgets/disagreement_banner.dart';
import 'package:advocat/features/chat/widgets/role_opinion_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

ConsiliumSnapshot _snap(List<Map<String, Object?>> entries) =>
    ConsiliumSnapshot.fromMaps(entries);

void main() {
  group('ConsiliumPanel', () {
    testWidgets('empty events → renders empty container', (tester) async {
      await tester.pumpWidget(_wrap(const ConsiliumPanel(events: [])));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consilium_panel_empty')), findsOneWidget);
      expect(find.byKey(const Key('consilium_panel')), findsNothing);
      expect(find.byKey(const Key('consilium_progress')), findsNothing);
    });

    testWidgets(
        'start + 3 RoleOpinion of 5 → 3 cards filled + 2 loading skeletons',
        (tester) async {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': [
            'Иммиграционный юрист',
            'Уголовный юрист',
            'Адвокат-процессуалист',
            'Трудовой юрист',
            'Налоговый юрист',
          ],
        },
        {
          'kind': 'opinion',
          'role': 'Иммиграционный юрист',
          'position': 'push',
          'confidence': 0.82,
          'opinion': 'Случай подпадает под §149 UL — оспариваем.',
          'citation': 'UL §149',
        },
        {
          'kind': 'opinion',
          'role': 'Уголовный юрист',
          'position': 'settle',
          'confidence': 0.55,
          'opinion': 'Лучше предложить мировую — риски значительные.',
        },
        {
          'kind': 'opinion',
          'role': 'Адвокат-процессуалист',
          'position': 'investigate',
          'confidence': 0.40,
          'opinion': 'Нужны дополнительные материалы дела.',
        },
      ]);

      await tester
          .pumpWidget(_wrap(ConsiliumPanel.fromSnapshot(snapshot: snap)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consilium_panel')), findsOneWidget);
      expect(find.byKey(const Key('consilium_progress')), findsOneWidget);
      expect(find.textContaining('3 / 5'), findsOneWidget);

      // 5 cards total (3 ready + 2 loading skeletons)
      expect(find.byType(RoleOpinionCard), findsNWidgets(5));

      // Position labels visible for the three known opinions
      expect(find.text('push'), findsOneWidget);
      expect(find.text('settle'), findsOneWidget);
      expect(find.text('investigate'), findsOneWidget);

      // No synthesis indicator and no "done" footer yet
      expect(find.byKey(const Key('consilium_synthesis')), findsNothing);
      expect(find.byKey(const Key('consilium_done_footer')), findsNothing);
    });

    testWidgets(
        'done + disagreement (push vs settle) → banner + done footer visible',
        (tester) async {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': ['Иммиграционный юрист', 'Уголовный юрист'],
        },
        {
          'kind': 'opinion',
          'role': 'Иммиграционный юрист',
          'position': 'push',
          'confidence': 0.85,
          'opinion': 'Подаём апелляцию.',
        },
        {
          'kind': 'opinion',
          'role': 'Уголовный юрист',
          'position': 'settle',
          'confidence': 0.30,
          'opinion': 'Идём на мировое.',
        },
        {'kind': 'round_done'},
        {'kind': 'synthesis_start'},
        {'kind': 'done'},
      ]);

      await tester
          .pumpWidget(_wrap(ConsiliumPanel.fromSnapshot(snapshot: snap)));
      await tester.pumpAndSettle();

      // Disagreement banner present (push/settle clash + delta 0.55 > 0.2)
      expect(find.byKey(const Key('disagreement_banner')), findsOneWidget);

      // Done footer visible, synthesis indicator hidden once done
      expect(find.byKey(const Key('consilium_done_footer')), findsOneWidget);
      expect(find.byKey(const Key('consilium_synthesis')), findsNothing);

      // Expand the disagreement detail
      await tester.tap(find.byKey(const Key('disagreement_banner')));
      await tester.pumpAndSettle();
      expect(find.textContaining('push'), findsWidgets);
      expect(find.textContaining('settle'), findsWidgets);
    });

    testWidgets(
        'synthesis started but not done → shows "Synthesizing…" indicator',
        (tester) async {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': ['Иммиграционный юрист']
        },
        {
          'kind': 'opinion',
          'role': 'Иммиграционный юрист',
          'position': 'push',
          'confidence': 0.70,
          'opinion': 'Подаём.',
        },
        {'kind': 'synthesis_start'},
      ]);

      await tester
          .pumpWidget(_wrap(ConsiliumPanel.fromSnapshot(snapshot: snap)));
      // CircularProgressIndicator inside the synthesis row animates forever,
      // so pumpAndSettle would never return. A single pump is enough to
      // build the tree.
      await tester.pump();

      expect(find.byKey(const Key('consilium_synthesis')), findsOneWidget);
      expect(find.byKey(const Key('consilium_done_footer')), findsNothing);
    });

    testWidgets('adversarial attacks → collapsible section visible',
        (tester) async {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': ['Иммиграционный юрист']
        },
        {
          'kind': 'opinion',
          'role': 'Иммиграционный юрист',
          'position': 'push',
          'confidence': 0.6,
          'opinion': 'X',
        },
        {'kind': 'attack'},
        {'kind': 'attack'},
      ]);

      await tester
          .pumpWidget(_wrap(ConsiliumPanel.fromSnapshot(snapshot: snap)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consilium_adversarial_toggle')),
          findsOneWidget);
      expect(find.textContaining('Адверсариальный'), findsOneWidget);
    });
  });

  group('ConsiliumPanel localized labels', () {
    testWidgets(
        'doneLabelBuilder overrides the RU done footer with counts injected',
        (tester) async {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': ['Immigration lawyer', 'Criminal lawyer'],
        },
        {
          'kind': 'opinion',
          'role': 'Immigration lawyer',
          'position': 'push',
          'confidence': 0.8,
          'opinion': 'Appeal.',
        },
        {
          'kind': 'opinion',
          'role': 'Criminal lawyer',
          'position': 'push',
          'confidence': 0.75,
          'opinion': 'Agree.',
        },
        {'kind': 'round_done'},
        {'kind': 'round_done'},
        {'kind': 'done'},
      ]);

      await tester.pumpWidget(_wrap(ConsiliumPanel.fromSnapshot(
        snapshot: snap,
        doneLabelBuilder: (roles, rounds) =>
            'Consilium of $roles lawyers · $rounds rounds · done',
      )));
      await tester.pumpAndSettle();

      // Localized string rendered with the real counts (2 roles, 2 rounds).
      expect(find.text('Consilium of 2 lawyers · 2 rounds · done'),
          findsOneWidget);
      // RU fallback footer no longer present.
      expect(find.text('Консилиум 2 юристов · 2 раунда · готово'), findsNothing);
    });

    testWidgets('omitting doneLabelBuilder keeps the RU done footer',
        (tester) async {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': ['Иммиграционный юрист'],
        },
        {
          'kind': 'opinion',
          'role': 'Иммиграционный юрист',
          'position': 'push',
          'confidence': 0.8,
          'opinion': 'X',
        },
        {'kind': 'round_done'},
        {'kind': 'done'},
      ]);

      await tester
          .pumpWidget(_wrap(ConsiliumPanel.fromSnapshot(snapshot: snap)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consilium_done_footer')), findsOneWidget);
      expect(
          find.text('Консилиум 1 юристов · 1 раунд · готово'), findsOneWidget);
    });

    testWidgets(
        'adversarialLabelBuilder overrides the RU expanded label with count',
        (tester) async {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': ['Immigration lawyer'],
        },
        {
          'kind': 'opinion',
          'role': 'Immigration lawyer',
          'position': 'push',
          'confidence': 0.6,
          'opinion': 'X',
        },
        {'kind': 'attack'},
        {'kind': 'attack'},
      ]);

      await tester.pumpWidget(_wrap(ConsiliumPanel.fromSnapshot(
        snapshot: snap,
        adversarialLabelBuilder: (count) => 'Adversarial round · $count objections',
      )));
      await tester.pumpAndSettle();

      // Collapsed by default → custom expanded label not visible yet, RU
      // collapsed label shown.
      expect(find.textContaining('Adversarial round'), findsNothing);

      // Expand.
      await tester.tap(find.byKey(const Key('consilium_adversarial_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Adversarial round · 2 objections'), findsOneWidget);
      expect(find.textContaining('возражений'), findsNothing);
    });

    testWidgets('omitting adversarialLabelBuilder keeps the RU expanded label',
        (tester) async {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': ['Иммиграционный юрист'],
        },
        {
          'kind': 'opinion',
          'role': 'Иммиграционный юрист',
          'position': 'push',
          'confidence': 0.6,
          'opinion': 'X',
        },
        {'kind': 'attack'},
        {'kind': 'attack'},
      ]);

      await tester
          .pumpWidget(_wrap(ConsiliumPanel.fromSnapshot(snapshot: snap)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('consilium_adversarial_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Адверсариальный раунд · 2 возражений'), findsOneWidget);
    });
  });

  group('detectDisagreements', () {
    test('large confidence delta triggers disagreement', () {
      final out = detectDisagreements([
        (role: 'A', position: 'push', confidence: 0.9),
        (role: 'B', position: 'push', confidence: 0.4),
      ]);
      expect(out, hasLength(1));
      expect(out.first.delta, closeTo(0.5, 1e-9));
    });

    test('push vs settle is always a disagreement', () {
      final out = detectDisagreements([
        (role: 'A', position: 'push', confidence: 0.5),
        (role: 'B', position: 'settle', confidence: 0.5),
      ]);
      expect(out, hasLength(1));
    });

    test('similar push positions → no disagreement', () {
      final out = detectDisagreements([
        (role: 'A', position: 'push', confidence: 0.75),
        (role: 'B', position: 'push', confidence: 0.70),
      ]);
      expect(out, isEmpty);
    });
  });

  group('ConsiliumSnapshot.fromMaps', () {
    test('roster + 2 opinions yields correct counts', () {
      final snap = _snap([
        {
          'kind': 'start',
          'roster': ['A', 'B', 'C']
        },
        {
          'kind': 'opinion',
          'role': 'A',
          'position': 'push',
          'confidence': 0.8,
          'opinion': 'X',
        },
        {
          'kind': 'opinion',
          'role': 'B',
          'position': 'settle',
          'confidence': 0.3,
          'opinion': 'Y',
        },
      ]);
      expect(snap.started, isTrue);
      expect(snap.totalRoles, 3);
      expect(snap.readyCount, 2);
      expect(snap.done, isFalse);
    });
  });

  group('imports compile-check', () {
    test('detectDisagreements is exported from disagreement_banner', () {
      // Symbol resolves via the panel re-export path.
      expect(detectDisagreements, isA<Function>());
    });
  });
}

// Compile-time reference so the RolePosition import is exercised.
// ignore: unused_element
const _kSampleRolePosition = RolePosition.push;
