@Tags(['fast'])
library;

// =============================================================================
// consilium_sse_parser_test.dart — Consilium v1 SSE → ChatStreamEvent mapping.
// =============================================================================
//
// Phase 1, 2026-05-25. Drives [parseSseEvent] with canned JSON payloads that
// match the wire format emitted by services/lawyer-router/consilium_v3.ts
// (and the legacy consilium.ts) and asserts the typed consilium event
// sequence is correct.
//
// Coverage:
//   • consilium_start with 5 roles
//   • role_opinion with all fields populated
//   • role_opinion with only required fields (optionals null)
//   • round_2_attack
//   • round_3_defense (attacker/target swap)
//   • round_1_done / round_2_done / round_3_done
//   • synthesis_start
//   • synthesis_done and bare `done` (only inside an active consilium)
//   • malformed JSON shape — no crash, no events
//   • unknown event type — no crash, no events
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/chat_stream_event.dart';
import 'package:advocat/services/claude_service.dart';

void main() {
  group('parseSseEvent — Consilium v1', () {
    test('consilium_start with 5 roles emits ConsiliumStart', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'consilium_start',
        'total': 5,
        'roles': [
          {'id': 'civil', 'name': 'Civil Lawyer'},
          {'id': 'criminal', 'name': 'Criminal Defence'},
          {'id': 'admin', 'name': 'Administrative'},
          {'id': 'eu', 'name': 'EU Law Expert'},
          {'id': 'tax', 'name': 'Tax Counsel'},
        ],
      }, state: state);

      expect(events, hasLength(1));
      final ev = events.single as ConsiliumStart;
      expect(ev.total, 5);
      expect(ev.roles, hasLength(5));
      expect(ev.roles.first.id, 'civil');
      expect(ev.roles.first.name, 'Civil Lawyer');
      expect(ev.roles.last.id, 'tax');

      // State bookkeeping
      expect(state.consiliumActive, isTrue);
      expect(state.consiliumRoleCount, 5);
    });

    test('consilium_start with missing roles array emits empty list', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'consilium_start',
        // no 'roles', no 'total'
      }, state: state);

      expect(events, hasLength(1));
      final ev = events.single as ConsiliumStart;
      expect(ev.roles, isEmpty);
      expect(ev.total, 0);
      expect(state.consiliumActive, isTrue);
    });

    test('role_opinion with all fields populated', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'civil',
        'role_name': 'Civil Lawyer',
        'opinion': 'The contract is voidable under §31 VÕS.',
        'position': 'plaintiff',
        'confidence': 0.82,
        'key_citation': 'VÕS §31',
      }, state: state);

      expect(events, hasLength(1));
      final ev = events.single as RoleOpinion;
      expect(ev.roleId, 'civil');
      expect(ev.roleName, 'Civil Lawyer');
      expect(ev.opinion, 'The contract is voidable under §31 VÕS.');
      expect(ev.position, 'plaintiff');
      expect(ev.confidence, 0.82);
      expect(ev.keyCitation, 'VÕS §31');
    });

    test('role_opinion with only required fields — optionals null', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'criminal',
        'role_name': 'Criminal Defence',
        'opinion': 'No criminal liability.',
        // no position, confidence, key_citation
      }, state: state);

      expect(events, hasLength(1));
      final ev = events.single as RoleOpinion;
      expect(ev.roleId, 'criminal');
      expect(ev.opinion, 'No criminal liability.');
      expect(ev.position, isNull);
      expect(ev.confidence, isNull);
      expect(ev.keyCitation, isNull);
    });

    test('role_opinion accepts integer confidence (coerced to double)', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'tax',
        'role_name': 'Tax Counsel',
        'opinion': 'See KMS §16.',
        'confidence': 1, // integer on the wire
      }, state: state);

      final ev = events.single as RoleOpinion;
      expect(ev.confidence, 1.0);
    });

    test('round_2_attack maps to AdversarialAttack', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'round_2_attack',
        'attacker': 'eu',
        'target_role': 'civil',
        'weak_point': 'Ignored CJEU C-186/87.',
        'counter_evidence': 'CJEU C-186/87 explicitly bars this defence.',
      }, state: state);

      expect(events, hasLength(1));
      final ev = events.single as AdversarialAttack;
      expect(ev.attacker, 'eu');
      expect(ev.targetRole, 'civil');
      expect(ev.weakPoint, 'Ignored CJEU C-186/87.');
      expect(ev.counterEvidence, contains('C-186/87'));
    });

    test('round_3_defense maps to AdversarialAttack with swapped roles', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'round_3_defense',
        'defender': 'civil',
        'original_attacker': 'eu',
        'defense_against': 'Ignored CJEU C-186/87.',
        'defense': 'C-186/87 applies only to harmonised goods, not services.',
      }, state: state);

      expect(events, hasLength(1));
      final ev = events.single as AdversarialAttack;
      expect(ev.attacker, 'civil'); // defender becomes attacker
      expect(ev.targetRole, 'eu'); // original attacker becomes target
      expect(ev.weakPoint, contains('C-186/87'));
      expect(ev.counterEvidence, contains('harmonised goods'));
    });

    test('round_1_done / round_2_done / round_3_done map to RoundDone', () {
      final state = SseStreamState();

      final r1 = parseSseEvent({'type': 'round_1_done'}, state: state);
      final r2 = parseSseEvent({'type': 'round_2_done'}, state: state);
      final r3 = parseSseEvent({'type': 'round_3_done'}, state: state);

      expect(r1.single, const RoundDone(round: 1));
      expect(r2.single, const RoundDone(round: 2));
      expect(r3.single, const RoundDone(round: 3));
    });

    test('synthesis_start maps to ConsiliumSynthesisStart', () {
      final state = SseStreamState();

      final events = parseSseEvent({'type': 'synthesis_start'}, state: state);

      expect(events, hasLength(1));
      expect(events.single, const ConsiliumSynthesisStart());
    });

    // Flagship UX fix (2026-07-02): consilium.ts / consilium_v3.ts stream
    // synthesis text as bare `{type: "delta", text: "..."}` frames — NOT
    // the Anthropic-native `content_block_delta`/`text_delta` shape. Before
    // this fix, `delta` fell into the parser's `default` branch (no
    // `citations` key present) and was silently dropped, so the consilium's
    // final synthesised answer never rendered even though every metadata
    // event (start/opinions/rounds/done) worked.
    test('delta maps to TextDelta (consilium synthesis wire shape)', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'delta',
        'text': 'Основной путь: KHO valituslupa.',
      }, state: state);

      expect(events, hasLength(1));
      final ev = events.single as TextDelta;
      expect(ev.text, 'Основной путь: KHO valituslupa.');
    });

    test('delta with empty text emits no event', () {
      final state = SseStreamState();

      final events = parseSseEvent({'type': 'delta', 'text': ''}, state: state);

      expect(events, isEmpty);
    });

    test('delta with missing text does not crash and emits no event', () {
      final state = SseStreamState();

      final events = parseSseEvent({'type': 'delta'}, state: state);

      expect(events, isEmpty);
    });

    test('synthesis_done with full payload maps to ConsiliumDone', () {
      final state = SseStreamState();

      // Prime state with consilium_start so the done event has context.
      parseSseEvent({
        'type': 'consilium_start',
        'total': 3,
        'roles': [
          {'id': 'a', 'name': 'A'},
          {'id': 'b', 'name': 'B'},
          {'id': 'c', 'name': 'C'},
        ],
      }, state: state);

      final events = parseSseEvent({
        'type': 'synthesis_done',
        'disagreement_detected': true,
        'total_roles': 3,
      }, state: state);

      expect(events, hasLength(1));
      final ev = events.single as ConsiliumDone;
      expect(ev.disagreementDetected, isTrue);
      expect(ev.totalRoles, 3);

      // State should be sealed
      expect(state.consiliumActive, isFalse);
      expect(state.consiliumDoneEmitted, isTrue);
    });

    test('bare `done` after consilium_start is promoted to ConsiliumDone', () {
      final state = SseStreamState();

      parseSseEvent({
        'type': 'consilium_start',
        'total': 2,
        'roles': [
          {'id': 'a', 'name': 'A'},
          {'id': 'b', 'name': 'B'},
        ],
      }, state: state);

      final events = parseSseEvent({'type': 'done'}, state: state);

      expect(events, hasLength(1));
      final ev = events.single as ConsiliumDone;
      expect(ev.totalRoles, 2);
      expect(ev.disagreementDetected, isFalse);
      expect(state.consiliumActive, isFalse);
    });

    test('bare `done` without consilium context is a no-op', () {
      final state = SseStreamState();

      final events = parseSseEvent({'type': 'done'}, state: state);

      expect(events, isEmpty);
      expect(state.consiliumActive, isFalse);
    });

    test('role_done is intentionally a no-op (subsumed by role_opinion)', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'role_done',
        'role_id': 'civil',
      }, state: state);

      expect(events, isEmpty);
    });

    test('unknown event type does not crash and produces no events', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'totally_made_up_event_type_xyz',
        'foo': 'bar',
      }, state: state);

      expect(events, isEmpty);
    });

    test('malformed consilium_start (roles is not a list) does not crash', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'consilium_start',
        'roles': 'not-a-list', // bad shape
        'total': 'also-bad',
      }, state: state);

      // Must not throw; emits ConsiliumStart with empty roles + total=0.
      expect(events, hasLength(1));
      final ev = events.single as ConsiliumStart;
      expect(ev.roles, isEmpty);
      expect(ev.total, 0);
    });

    test('role_opinion with non-numeric confidence ignores the field', () {
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'civil',
        'role_name': 'Civil',
        'opinion': 'x',
        'confidence': 'high', // not a number
      }, state: state);

      final ev = events.single as RoleOpinion;
      expect(ev.confidence, isNull);
    });

    test('full consilium turn — start → opinions → attack → done', () {
      final state = SseStreamState();
      final all = <ChatStreamEvent>[];

      all.addAll(parseSseEvent({
        'type': 'consilium_start',
        'total': 2,
        'roles': [
          {'id': 'civil', 'name': 'Civil'},
          {'id': 'eu', 'name': 'EU'},
        ],
      }, state: state));

      all.addAll(parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'civil',
        'role_name': 'Civil',
        'opinion': 'Contract holds.',
        'confidence': 0.7,
      }, state: state));

      all.addAll(parseSseEvent({
        'type': 'role_opinion',
        'role_id': 'eu',
        'role_name': 'EU',
        'opinion': 'CJEU disagrees.',
        'confidence': 0.85,
      }, state: state));

      all.addAll(parseSseEvent({'type': 'round_1_done'}, state: state));

      all.addAll(parseSseEvent({
        'type': 'round_2_attack',
        'attacker': 'eu',
        'target_role': 'civil',
        'weak_point': 'Missed CJEU precedent.',
        'counter_evidence': 'C-186/87.',
      }, state: state));

      all.addAll(parseSseEvent({'type': 'round_2_done'}, state: state));
      all.addAll(parseSseEvent({'type': 'synthesis_start'}, state: state));
      all.addAll(parseSseEvent({
        'type': 'synthesis_done',
        'disagreement_detected': true,
        'total_roles': 2,
      }, state: state));

      expect(all.map((e) => e.runtimeType).toList(), [
        ConsiliumStart,
        RoleOpinion,
        RoleOpinion,
        RoundDone,
        AdversarialAttack,
        RoundDone,
        ConsiliumSynthesisStart,
        ConsiliumDone,
      ]);
    });

    test('camelCase field aliases are also accepted', () {
      // The backend canonical form is snake_case, but some early consilium
      // dispatchers emit camelCase. The parser accepts both for safety.
      final state = SseStreamState();

      final events = parseSseEvent({
        'type': 'role_opinion',
        'roleId': 'civil',
        'roleName': 'Civil',
        'opinion': 'OK.',
        'keyCitation': 'VÕS §31',
      }, state: state);

      final ev = events.single as RoleOpinion;
      expect(ev.roleId, 'civil');
      expect(ev.roleName, 'Civil');
      expect(ev.keyCitation, 'VÕS §31');
    });

    test('state.reset() clears consilium bookkeeping', () {
      final state = SseStreamState();

      parseSseEvent({
        'type': 'consilium_start',
        'total': 1,
        'roles': [
          {'id': 'a', 'name': 'A'}
        ],
      }, state: state);
      expect(state.consiliumActive, isTrue);

      state.reset();
      expect(state.consiliumActive, isFalse);
      expect(state.consiliumRoleCount, 0);
      expect(state.consiliumDoneEmitted, isFalse);
    });
  });
}
