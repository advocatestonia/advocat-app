// =====================================================================
// Wiring test — AIService._triggerCaseAutoPatch fires only when a real
// active case id is set. This guards the contract that:
//   * No active case id  → no Edge Function call (no $$ burn).
//   * 'general' synthetic id → never reaches the Edge Function (UUID guard).
//   * Real UUID + service wired → call goes through with the right shape.
// =====================================================================

@Tags(['fast'])
library;

import 'package:advocat/features/case_memory/services/case_auto_patch_service.dart';
import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _validUuid = '550e8400-e29b-41d4-a716-446655440000';

class _SpyAutoPatchService implements CaseAutoPatchService {
  int callCount = 0;
  String? lastCaseId;
  String? lastUserMessage;
  String? lastAiReply;
  CaseAutoPatchOutcome outcome = CaseAutoPatchOutcome.patched;
  bool shouldThrow = false;

  @override
  Future<CaseAutoPatchOutcome> patchCase({
    required String caseId,
    required String userMessage,
    required String aiReply,
  }) async {
    callCount++;
    lastCaseId = caseId;
    lastUserMessage = userMessage;
    lastAiReply = aiReply;
    if (shouldThrow) throw StateError('boom');
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    throw UnimplementedError(
      '_SpyAutoPatchService.${i.memberName.toString()} not stubbed',
    );
  }
}

class _StubSupabaseService implements SupabaseService {
  @override
  bool get isDemo => true;
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

void main() {
  group('AIService._triggerCaseAutoPatch wiring', () {
    test('no-op when no active case id', () async {
      final spy = _SpyAutoPatchService();
      final svc = AIService(caseAutoPatchService: spy);
      // Default: _activeCaseId is null.
      await svc.triggerCaseAutoPatchForTest(
        userMessage: 'u',
        aiResponse: 'a',
      );
      expect(spy.callCount, 0);
    });

    test("no-op when active case id is 'general' (rejected by UUID guard)",
        () async {
      final spy = _SpyAutoPatchService();
      final svc = AIService(caseAutoPatchService: spy);
      svc.setActiveCaseId('general');
      // setActiveCaseId silently coerces non-UUID to null.
      expect(svc.currentActiveCaseId, isNull);
      await svc.triggerCaseAutoPatchForTest(
        userMessage: 'u',
        aiResponse: 'a',
      );
      expect(spy.callCount, 0);
    });

    test('fires patchCase with active UUID', () async {
      final spy = _SpyAutoPatchService();
      final svc = AIService(caseAutoPatchService: spy);
      svc.setActiveCaseId(_validUuid);
      await svc.triggerCaseAutoPatchForTest(
        userMessage: 'When is the deadline?',
        aiResponse: '30 days per HMS § 26.',
      );
      expect(spy.callCount, 1);
      expect(spy.lastCaseId, _validUuid);
      expect(spy.lastUserMessage, 'When is the deadline?');
      expect(spy.lastAiReply, '30 days per HMS § 26.');
    });

    test('NEVER throws when patchCase throws — best-effort', () async {
      final spy = _SpyAutoPatchService()..shouldThrow = true;
      final svc = AIService(caseAutoPatchService: spy);
      svc.setActiveCaseId(_validUuid);
      // No throw allowed — chat reply already shipped.
      await svc.triggerCaseAutoPatchForTest(
        userMessage: 'u',
        aiResponse: 'a',
      );
      expect(spy.callCount, 1);
    });

    test('no-op when no auto-patch service is wired (legacy callers)',
        () async {
      final svc = AIService(); // No service injected.
      svc.setActiveCaseId(_validUuid);
      // Just verify no exception bubbles.
      await svc.triggerCaseAutoPatchForTest(
        userMessage: 'u',
        aiResponse: 'a',
      );
    });
  });

  // Small smoke check that _StubSupabaseService is intentionally unused.
  test('stub supabase is demo', () {
    expect(_StubSupabaseService().isDemo, isTrue);
  });
}
