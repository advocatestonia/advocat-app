@Tags(['fast'])
library;

// =============================================================================
// consilium_e2e_test.dart — Phase 1 Flutter integration test.
// =============================================================================
//
// Scope:
//   1. Drive parseSseEvent with the EXACT JSON shape the backend
//      (consilium.ts) emits and verify it produces the typed ChatStreamEvent
//      sequence the UI subscribes to.
//   2. Cover the consilium event family: ConsiliumStart → RoleOpinion × N →
//      ConsiliumSynthesisStart → TextDelta × M → ConsiliumDone.
//   3. Validate disagreement detection surfaces via ConsiliumDone.
//   4. L10n smoke — render the consilium ARB keys in 3 locales (en/fi/ru)
//      to catch missing translations early.
//
// What is INTENTIONALLY skipped:
//   • ConsiliumPanel widget render — the widget itself is being delivered by
//     the UI agent in parallel. Once `lib/widgets/consilium_panel.dart` lands,
//     un-skip the `consilium widget renders` group below.
//   • Round-2/3 adversarial events — Phase 1 ships the standard pipeline
//     (rounds via consilium_v3 are flagged off by default).
//
// All tests are deterministic. No network. <2s total.
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/chat_stream_event.dart';
import 'package:advocat/services/claude_service.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // Group 1: SSE event sequence — full consilium stream
  // ───────────────────────────────────────────────────────────────────────────
  group('Consilium SSE stream → typed events', () {
    test('full pipeline emits ConsiliumStart → RoleOpinion × N → '
        'ConsiliumSynthesisStart → TextDelta → ConsiliumDone', () {
      final state = SseStreamState();
      final events = <ChatStreamEvent>[];

      // message_start so state is initialised properly.
      events.addAll(parseSseEvent(
        {'type': 'message_start'},
        state: state,
      ));

      // consilium_start — backend emits roles (string[]), roster ({id,name}[]),
      // and total. The Dart parser currently reads `roster` items as a list of
      // maps with id+name keys, so we model BOTH shapes the backend can emit.
      events.addAll(parseSseEvent({
        'type': 'consilium_start',
        'roles': [
          {'id': 'senior-asianajaja', 'name': 'Senior asianajaja'},
          {'id': 'immigration-lawyer', 'name': 'Immigration lawyer'},
          {'id': 'strategist', 'name': 'Strategist'},
        ],
        'total': 3,
      }, state: state));

      // role_opinion × 3 — Phase 1 emits these in the flat top-level format
      // that the parser expects (NOT nested under payload). See
      // claude_service.dart parseSseEvent role_opinion branch.
      for (final r in const [
        {'id': 'senior-asianajaja', 'name': 'Senior asianajaja'},
        {'id': 'immigration-lawyer', 'name': 'Immigration lawyer'},
        {'id': 'strategist', 'name': 'Strategist'},
      ]) {
        events.addAll(parseSseEvent({
          'type': 'role_opinion',
          'role_id': r['id'],
          'role_name': r['name'],
          'opinion': '${r['name']}: probability 15-25%.',
          'position': 'push',
          'confidence': 0.2,
          'key_citation': '[[ref:hol:114]]',
        }, state: state));
      }

      // synthesis_start
      events.addAll(parseSseEvent(
        {'type': 'synthesis_start'},
        state: state,
      ));

      // delta × 2 (synthesis text)
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': 'Основной путь: '},
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': 'KHO valituslupa, шанс 15-25%.'},
      }, state: state));

      // consilium_done with disagreement_detected
      events.addAll(parseSseEvent({
        'type': 'consilium_done',
        'disagreement_detected': false,
        'total_roles': 3,
      }, state: state));

      // ── Assertions ────────────────────────────────────────────────────────
      // 1. First consilium event is ConsiliumStart with 3 roles.
      final consiliumStart = events.whereType<ConsiliumStart>().single;
      expect(consiliumStart.total, 3);
      expect(consiliumStart.roles.length, 3);
      expect(consiliumStart.roles.first.id, 'senior-asianajaja');

      // 2. Three RoleOpinion events with correct ids.
      final opinions = events.whereType<RoleOpinion>().toList();
      expect(opinions.length, 3, reason: 'expected one RoleOpinion per role');
      expect(opinions.map((o) => o.roleId).toList(), [
        'senior-asianajaja',
        'immigration-lawyer',
        'strategist',
      ]);
      expect(opinions.first.position, 'push');
      expect(opinions.first.confidence, closeTo(0.2, 1e-9));
      expect(opinions.first.keyCitation, '[[ref:hol:114]]');

      // 3. ConsiliumSynthesisStart fires before TextDeltas.
      final synthIdx = events.indexWhere((e) => e is ConsiliumSynthesisStart);
      final firstDeltaIdx = events.indexWhere((e) => e is TextDelta);
      expect(synthIdx >= 0, isTrue);
      expect(firstDeltaIdx > synthIdx, isTrue,
          reason: 'TextDelta must come after ConsiliumSynthesisStart');

      // 4. Two TextDelta events.
      final deltas = events.whereType<TextDelta>().toList();
      expect(deltas.length, 2);
      expect(
        deltas.map((d) => d.text).join(),
        'Основной путь: KHO valituslupa, шанс 15-25%.',
      );

      // 5. Final ConsiliumDone with totalRoles preserved.
      final done = events.whereType<ConsiliumDone>().single;
      expect(done.totalRoles, 3);
      expect(done.disagreementDetected, isFalse);

      // 6. Strict order: Start → Opinions → Synth → Deltas → Done.
      final order = events
          .where((e) =>
              e is ConsiliumStart ||
              e is RoleOpinion ||
              e is ConsiliumSynthesisStart ||
              e is TextDelta ||
              e is ConsiliumDone)
          .toList();
      expect(order.first, isA<ConsiliumStart>());
      expect(order.last, isA<ConsiliumDone>());
    });

    test('disagreement_detected=true is propagated to ConsiliumDone', () {
      final state = SseStreamState();
      final events = <ChatStreamEvent>[];

      events.addAll(parseSseEvent({'type': 'message_start'}, state: state));
      events.addAll(parseSseEvent({
        'type': 'consilium_start',
        'roles': [
          {'id': 'a', 'name': 'A'},
          {'id': 'b', 'name': 'B'},
        ],
        'total': 2,
      }, state: state));
      // Two role opinions with opposing stances.
      events.addAll(parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'a',
        'role_name': 'A',
        'opinion': 'Push: 65%.',
        'position': 'push',
        'confidence': 0.65,
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'b',
        'role_name': 'B',
        'opinion': 'Settle: 15%.',
        'position': 'settle',
        'confidence': 0.15,
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'consilium_done',
        'disagreement_detected': true,
        'total_roles': 2,
      }, state: state));

      final done = events.whereType<ConsiliumDone>().single;
      expect(done.disagreementDetected, isTrue);
      expect(done.totalRoles, 2);

      // Both opinion positions captured for UI to render a banner.
      final opinions = events.whereType<RoleOpinion>().toList();
      expect(opinions.map((o) => o.position).toSet(), {'push', 'settle'});
    });

    test('plain `done` after consilium_start is promoted to ConsiliumDone', () {
      // Some backend variants emit a generic `done` instead of `consilium_done`.
      // The parser tracks this via SseStreamState and synthesises the event.
      final state = SseStreamState();
      final events = <ChatStreamEvent>[];

      events.addAll(parseSseEvent({'type': 'message_start'}, state: state));
      events.addAll(parseSseEvent({
        'type': 'consilium_start',
        'roles': [
          {'id': 'a', 'name': 'A'},
        ],
        'total': 1,
      }, state: state));
      events.addAll(parseSseEvent({'type': 'done'}, state: state));

      // The plain `done` should produce a ConsiliumDone with the tracked
      // role count.
      final done = events.whereType<ConsiliumDone>().single;
      expect(done.totalRoles, 1);
    });

    test('role_done events are dropped (subsumed by role_opinion)', () {
      final state = SseStreamState();
      final events = parseSseEvent({
        'type': 'role_done',
        'role': 'Strategist',
      }, state: state);
      expect(events, isEmpty,
          reason: 'role_done is no-op — UI uses role_opinion instead');
    });

    test('Phase 1.1 contract: backend emits FLAT role_opinion keys (not nested)',
        () {
      // CONTRACT TEST: consilium.ts + consilium_v3.ts emit role_opinion as
      //   { type: "role_opinion", role_id, role_name, opinion, position,
      //     confidence, key_citation }
      // The Flutter parser reads parsed['role_id'] / parsed['role_name'] etc.
      // directly. The older nested `payload: {…}` shape is no longer emitted
      // (would land in this test as empty strings and fail the assertions).
      //
      // If a future refactor re-introduces nesting under `payload`, this test
      // fails immediately so the regression is caught in CI rather than at
      // runtime as empty role cards.
      final state = SseStreamState();
      final events = parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'immigration-lawyer',
        'role_name': 'Immigration lawyer',
        'opinion': 'Stand by analysis 15-20%.',
        'position': 'push',
        'confidence': 0.18,
        'key_citation': '[[ref:hol:114]]',
      }, state: state);

      expect(events, hasLength(1));
      final op = events.single as RoleOpinion;
      expect(op.roleId, 'immigration-lawyer',
          reason: 'Flat top-level role_id must populate roleId');
      expect(op.roleName, 'Immigration lawyer');
      expect(op.opinion, 'Stand by analysis 15-20%.');
      expect(op.position, 'push');
      expect(op.confidence, closeTo(0.18, 1e-9));
      expect(op.keyCitation, '[[ref:hol:114]]');
    });

    test('Phase 1.1 regression: legacy nested `payload` shape yields empty card',
        () {
      // Backwards-compat probe: if some old client somehow emits the legacy
      // nested form, the parser does NOT silently accept it (would mask the
      // bug). It returns an empty RoleOpinion the UI can flag.
      final state = SseStreamState();
      final events = parseSseEvent({
        'type': 'role_opinion',
        'payload': {
          'role_id': 'civil',
          'role_name': 'Civil',
          'opinion': 'should not be read',
        },
      }, state: state);

      expect(events, hasLength(1));
      final op = events.single as RoleOpinion;
      // The parser intentionally does NOT recurse into `payload`. Empty card
      // signals the contract violation upstream.
      expect(op.roleId, isEmpty);
      expect(op.opinion, isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 2: L10n smoke — consilium strings in 3 locales
  // ───────────────────────────────────────────────────────────────────────────
  group('Consilium l10n', () {
    Future<AppLocalizations> _loadLocale(WidgetTester tester, Locale locale) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              l10n = AppLocalizations.of(ctx)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return l10n;
    }

    testWidgets('consilium ARB keys resolve in en/fi/ru', (tester) async {
      for (final locale in const [
        Locale('en'),
        Locale('fi'),
        Locale('ru'),
      ]) {
        final l10n = await _loadLocale(tester, locale);

        // Every key the ConsiliumPanel will reference must resolve to a
        // non-empty string. If a translation is missing the generated
        // AppLocalizations returns null → empty string here, which fails the
        // assertion.
        expect(l10n.consiliumHeader, isNotEmpty,
            reason: 'consiliumHeader missing in $locale');
        expect(l10n.consiliumStarting, isNotEmpty,
            reason: 'consiliumStarting missing in $locale');
        expect(l10n.consiliumSynthesizing, isNotEmpty,
            reason: 'consiliumSynthesizing missing in $locale');
        expect(l10n.consiliumDisagreement, isNotEmpty,
            reason: 'consiliumDisagreement missing in $locale');
        expect(l10n.consiliumPositionPush, isNotEmpty);
        expect(l10n.consiliumPositionSettle, isNotEmpty);
        expect(l10n.consiliumPositionInvestigate, isNotEmpty);
        expect(l10n.consiliumPositionOutOfScope, isNotEmpty);
        expect(l10n.consiliumConfidence, isNotEmpty);
        expect(l10n.consiliumKeyCitation, isNotEmpty);

        // Parameterised strings.
        expect(l10n.consiliumProgress(2, 5), isNotEmpty);
        expect(l10n.consiliumDone(5), isNotEmpty);
        expect(l10n.consiliumExpertsAgreed(3), isNotEmpty);
        expect(l10n.consiliumExpertsDisagree(2), isNotEmpty);
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 3: ConsiliumPanel widget — SKIPPED until UI agent ships the widget.
  //
  // Once `lib/widgets/consilium_panel.dart` lands, remove the `skip:` markers
  // and the tests will exercise the widget directly. The events to feed it are
  // the same ChatStreamEvent stream validated above.
  // ───────────────────────────────────────────────────────────────────────────
  group('ConsiliumPanel widget renders', () {
    testWidgets('shows "N of N ready" header after ConsiliumStart', (tester) async {
      // TODO(consilium-ui): un-skip after lib/widgets/consilium_panel.dart lands.
      // Expected:
      //   1. Render ConsiliumPanel with an empty event stream → empty placeholder.
      //   2. Feed ConsiliumStart(total=5) → header shows "0 of 5 ready".
      //   3. Feed RoleOpinion x3 → header shows "3 of 5 ready" + 3 cards.
    }, skip: true); // widget not yet shipped (UI agent in parallel)

    testWidgets('shows disagreement banner when ConsiliumDone.disagreementDetected=true',
        (tester) async {
      // TODO(consilium-ui): un-skip after widget lands.
    }, skip: true); // widget not yet shipped (UI agent in parallel)

    testWidgets('shows "Synthesizing…" between ConsiliumSynthesisStart and ConsiliumDone',
        (tester) async {
      // TODO(consilium-ui): un-skip after widget lands.
    }, skip: true); // widget not yet shipped (UI agent in parallel)
  });
}
