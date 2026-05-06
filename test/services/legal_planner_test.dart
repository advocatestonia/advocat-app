@Tags(['fast'])
library;

// =============================================================================
// legal_planner_test.dart — Phase 2 Pkg 6 (client-side gate + result parsing).
// =============================================================================
//
// Three contract pins:
//   1. shouldRouteToPlanner gate semantics (3-AND): isPro && enabledByPref
//      && looksLegalish. Each missing input must short-circuit to false.
//   2. PlannerResult.fromAugmented unwraps the augmented JSON shape that
//      claude-proxy emits in mode='legal_planner'. Reply text comes from
//      content[0].text, citations[] passes through, planner.* maps to
//      PlannerSummary.
//   3. PlannerSummary defaults are safe when the proxy ever forgets to
//      include the metadata block — the chat path must keep rendering.
// =============================================================================

import 'package:advocat/services/claude_service.dart';
import 'package:advocat/services/legal_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldRouteToPlanner', () {
    test('returns true only when all 3 conditions hold', () {
      expect(
        shouldRouteToPlanner(
          isPro: true,
          enabledByPref: true,
          looksLegalish: true,
        ),
        isTrue,
      );
    });

    test('returns false when not Pro', () {
      expect(
        shouldRouteToPlanner(
          isPro: false,
          enabledByPref: true,
          looksLegalish: true,
        ),
        isFalse,
      );
    });

    test('returns false when pref is OFF (default-OFF contract)', () {
      expect(
        shouldRouteToPlanner(
          isPro: true,
          enabledByPref: false,
          looksLegalish: true,
        ),
        isFalse,
      );
    });

    test('returns false when query is not legal-ish', () {
      expect(
        shouldRouteToPlanner(
          isPro: true,
          enabledByPref: true,
          looksLegalish: false,
        ),
        isFalse,
      );
    });
  });

  group('looksLegalish (server-side trigger contract)', () {
    test('catches Estonian dispute vocabulary', () {
      // Pinning the contract that the planner gate uses ClaudeService.looksLegalish
      // — if that method ever stops detecting "vaidlustada", the planner stops
      // firing for Estonian appeals.
      expect(ClaudeService.looksLegalish('kas ma saan vaidlustada otsust'),
          isTrue);
    });

    test('catches RU appeal vocabulary', () {
      expect(ClaudeService.looksLegalish('хочу подать жалобу'), isTrue);
    });

    test('rejects small talk', () {
      expect(ClaudeService.looksLegalish('hello, how are you'), isFalse);
    });
  });

  group('PlannerResult.fromAugmented', () {
    test('extracts replyText from content[0].text', () {
      final res = PlannerResult.fromAugmented({
        'mode': 'legal_planner',
        'content': [
          {'type': 'text', 'text': 'The answer is [[ref:tls:88]].'},
        ],
        'citations': [],
        'planner': {
          'regenerated_once': false,
          'latency_ms': 4200,
          'cost_cents': 7,
        },
      });
      expect(res.replyText, contains('[[ref:tls:88]]'));
      expect(res.summary.regeneratedOnce, isFalse);
      expect(res.summary.latencyMs, 4200);
      expect(res.summary.costCents, 7);
    });

    test('passes citations[] through unchanged', () {
      final res = PlannerResult.fromAugmented({
        'content': [
          {'type': 'text', 'text': 'x'},
        ],
        'citations': [
          {'marker': '[[ref:tls:88]]', 'status': 'verified'},
        ],
        'planner': {},
      });
      expect(res.citations, hasLength(1));
      expect(res.citations.first, isA<Map>());
    });

    test('flags regenerated_once when present', () {
      final res = PlannerResult.fromAugmented({
        'content': [
          {'type': 'text', 'text': 'regen'},
        ],
        'citations': [],
        'planner': {
          'regenerated_once': true,
          'latency_ms': 9500,
          'cost_cents': 12,
        },
      });
      expect(res.summary.regeneratedOnce, isTrue);
      expect(res.summary.latencyMs, 9500);
    });

    test('safe defaults when planner block absent', () {
      final res = PlannerResult.fromAugmented({
        'content': [
          {'type': 'text', 'text': 'x'},
        ],
        'citations': [],
      });
      expect(res.summary.regeneratedOnce, isFalse);
      expect(res.summary.latencyMs, 0);
    });

    test('echoes back message_id when proxy persisted it', () {
      final res = PlannerResult.fromAugmented({
        'content': [
          {'type': 'text', 'text': 'x'},
        ],
        'citations': [],
        'planner': {},
        'message_id': '00000000-0000-0000-0000-000000000abc',
      });
      expect(res.messageId, '00000000-0000-0000-0000-000000000abc');
    });
  });
}
