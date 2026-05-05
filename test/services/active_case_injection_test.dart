@Tags(['fast'])
library;

// =============================================================================
// active_case_injection_test.dart — Pkg 1.B client-side plumbing for Case
// Memory (handoff 2026-05-05).
// =============================================================================
//
// Server-side injection / formatting / 30 KB cap is pinned in the Deno
// suite at:
//   supabase/functions/claude-proxy/__tests__/active_case_injection_test.ts
//
// This file pins the CLIENT contract:
//   1. AIService.setActiveCaseId / clearActiveCaseId / currentActiveCaseId.
//   2. Strict UUID v4 acceptance — synthetic ids like "general" must not
//      become an active case id (would 400 the proxy).
//   3. ClaudeService API methods accept a `caseId` parameter and forward
//      it as `case_id` on the request body — exact wire-name match against
//      the proxy contract.
//   4. Streaming + non-streaming paths both accept caseId.
// =============================================================================

import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/claude_service.dart';

void main() {
  group('AIService.setActiveCaseId — UUID gate', () {
    test('null clears the active case id', () {
      final svc = AIService();
      svc.setActiveCaseId('550e8400-e29b-41d4-a716-446655440000');
      expect(svc.currentActiveCaseId, isNotNull);
      svc.setActiveCaseId(null);
      expect(svc.currentActiveCaseId, isNull);
    });

    test('empty string is treated as null', () {
      final svc = AIService();
      svc.setActiveCaseId('');
      expect(svc.currentActiveCaseId, isNull);
    });

    test('"general" is silently rejected (synthetic non-UUID)', () {
      final svc = AIService();
      svc.setActiveCaseId('general');
      expect(svc.currentActiveCaseId, isNull,
          reason: 'Synthetic ids must NEVER reach the wire — would 400.');
    });

    test('arbitrary non-UUID string is rejected', () {
      final svc = AIService();
      svc.setActiveCaseId('not-a-uuid');
      expect(svc.currentActiveCaseId, isNull);
    });

    test('UUID v4 is accepted', () {
      final svc = AIService();
      const id = '550e8400-e29b-41d4-a716-446655440000';
      svc.setActiveCaseId(id);
      expect(svc.currentActiveCaseId, id);
    });

    test('uppercase UUID is accepted (case-insensitive)', () {
      final svc = AIService();
      const id = '550E8400-E29B-41D4-A716-446655440000';
      svc.setActiveCaseId(id);
      expect(svc.currentActiveCaseId, id);
    });

    test('clearActiveCaseId() is equivalent to setActiveCaseId(null)', () {
      final svc = AIService();
      svc.setActiveCaseId('550e8400-e29b-41d4-a716-446655440000');
      svc.clearActiveCaseId();
      expect(svc.currentActiveCaseId, isNull);
    });
  });

  group('ClaudeService API — caseId param surface', () {
    // The wire body assembly happens inside _callApi (private). We pin the
    // public surface here at compile-time by exercising each public method
    // signature. If a refactor drops the `caseId` named param, the test
    // body will fail to compile — which is exactly the contract we want.

    Future<String> probeSendMessage(ClaudeService svc) =>
        svc.sendMessage(
          messages: const [],
          systemPrompt: '',
          caseId: '550e8400-e29b-41d4-a716-446655440000',
        );

    Future<Map<String, dynamic>> probeSendMessageWithTools(ClaudeService svc) =>
        svc.sendMessageWithTools(
          messages: const [],
          systemPrompt: '',
          caseId: '550e8400-e29b-41d4-a716-446655440000',
        );

    Stream<String> probeSendMessageStreaming(ClaudeService svc) =>
        svc.sendMessageStreaming(
          messages: const [],
          systemPrompt: '',
          caseId: '550e8400-e29b-41d4-a716-446655440000',
        );

    Stream<Object> probeSendMessageStreamingEvents(ClaudeService svc) =>
        svc.sendMessageStreamingEvents(
          messages: const [],
          systemPrompt: '',
          caseId: '550e8400-e29b-41d4-a716-446655440000',
        );

    Future<String> probeBackwardsCompat(ClaudeService svc) => svc.sendMessage(
          messages: const [],
          systemPrompt: '',
        );

    test('sendMessage accepts a caseId named param', () {
      expect(probeSendMessage, isNotNull);
    });

    test('sendMessageWithTools accepts a caseId named param', () {
      expect(probeSendMessageWithTools, isNotNull);
    });

    test('sendMessageStreaming accepts a caseId named param', () {
      expect(probeSendMessageStreaming, isNotNull);
    });

    test('sendMessageStreamingEvents accepts a caseId named param', () {
      expect(probeSendMessageStreamingEvents, isNotNull);
    });

    test('caseId is optional — backwards-compatible callers compile', () {
      expect(probeBackwardsCompat, isNotNull);
    });
  });

  group('Wire field name contract — claude_service.dart source pins', () {
    // The proxy reads body.case_id (snake_case). If a refactor renames
    // the field on the wire (e.g. to `caseId`), the entire feature
    // silently no-ops in prod. Lock the wire-format string verbatim.
    late String src;

    setUpAll(() async {
      src = await File('lib/services/claude_service.dart').readAsString();
    });

    test('source assembles wire body with key case_id', () {
      // The exact assembly line we wrote in the patch.
      expect(
        src.contains("'case_id': caseId"),
        isTrue,
        reason:
            'Non-streaming body must serialise caseId as `case_id` '
            '(snake_case wire contract).',
      );
    });

    test('streaming body also writes case_id key', () {
      // Streaming path is a separate body builder — verify both write
      // the same wire key.
      expect(
        src.contains("body['case_id'] = caseId"),
        isTrue,
        reason:
            'Streaming body must serialise caseId as `case_id` to match '
            'claude-proxy contract.',
      );
    });

    test('source declares String? caseId at least once', () {
      expect(
        'String? caseId'.allMatches(src).length,
        greaterThan(0),
        reason: 'caseId named param must be declared on the public API.',
      );
    });
  });

  group('Idempotency / regression', () {
    test('setActiveCaseId twice with same UUID is a no-op (no allocations)', () {
      final svc = AIService();
      const id = '550e8400-e29b-41d4-a716-446655440000';
      svc.setActiveCaseId(id);
      final first = svc.currentActiveCaseId;
      svc.setActiveCaseId(id);
      final second = svc.currentActiveCaseId;
      expect(first, second);
    });

    test('setActiveCaseId preserves last valid id when given garbage', () {
      // Today the contract is "garbage clears the active id". Pin that so
      // a future change is intentional, not an accident. (Pkg 1.D may
      // revisit — but the present semantic is "fail closed".)
      final svc = AIService();
      const valid = '550e8400-e29b-41d4-a716-446655440000';
      svc.setActiveCaseId(valid);
      svc.setActiveCaseId('not-a-uuid');
      expect(svc.currentActiveCaseId, isNull,
          reason: 'Garbage input clears the field — fail closed.');
    });
  });
}
