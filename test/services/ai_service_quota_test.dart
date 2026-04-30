// =============================================================================
// AI quota double-decrement regression test (pre-launch fix, 2026-04-29)
// =============================================================================
//
// Bug scenario:
//   1. Free user at 5/7. Streaming chat starts.
//   2. ai_service.sendChatMessageStreaming → _checkAndIncrementDailyLimit
//      consumes the quota (now 6/7).
//   3. Claude API throws a transient ClaudeServiceException
//      (cf_ECONNRESET / 503 / timeout / etc).
//   4. Catch handler in ai_service.dart:1278 falls back to sendChatMessage.
//   5. sendChatMessage at ai_service.dart:886 calls
//      _checkAndIncrementDailyLimit AGAIN → 7/7.
//   6. User loses 2 messages for one network blip.
//
// Fix (Variant A from task brief): thread `quotaAlreadyConsumed` through
// sendChatMessage so the streaming fallback can declare the quota was
// already paid and skip a second consume. Pro users are unaffected
// because they short-circuit consumeQuota at the top.
//
// This test pins down the contract directly via the test seam exposed
// on AIService — going through the public sendChatMessage path requires
// AppConfig.isUsingRealAI to be true, which depends on Supabase env
// vars and is not testable in unit tests.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/claude_service.dart';

class _CountingQuotaClient implements AiQuotaClient {
  _CountingQuotaClient({
    this.limit = 7,
    this.plan = 'free',
    int startingUsed = 0,
  }) : _used = startingUsed;

  final int limit;
  final String plan;
  int _used;

  int consumeCalls = 0;
  int checkCalls = 0;

  @override
  Future<AiQuota?> check() async {
    checkCalls += 1;
    return _build();
  }

  @override
  Future<AiQuota?> consume() async {
    consumeCalls += 1;
    if (plan == 'pro') {
      return const AiQuota(
        allowed: true,
        remaining: null,
        limit: -1,
        plan: 'pro',
        unlimited: true,
      );
    }
    if (_used >= limit) {
      return AiQuota(
        allowed: false,
        remaining: 0,
        limit: limit,
        plan: plan,
        used: _used,
      );
    }
    _used += 1;
    return AiQuota(
      allowed: _used <= limit,
      remaining: (limit - _used).clamp(0, limit),
      limit: limit,
      plan: plan,
      used: _used,
    );
  }

  AiQuota _build() {
    if (plan == 'pro') {
      return const AiQuota(
        allowed: true,
        remaining: null,
        limit: -1,
        plan: 'pro',
        unlimited: true,
      );
    }
    return AiQuota(
      allowed: _used < limit,
      remaining: (limit - _used).clamp(0, limit),
      limit: limit,
      plan: plan,
      used: _used,
    );
  }
}

class _DummyClaudeService extends ClaudeService {
  _DummyClaudeService();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AIService quota double-decrement regression', () {
    test(
        'Streaming fallback after ClaudeServiceException must NOT '
        're-consume quota (no double-decrement)', () async {
      // Simulates the post-fix contract: when the streaming path has
      // already consumed quota for this turn and falls back to
      // sendChatMessage on a transient API failure, the fallback must
      // be invoked with quotaAlreadyConsumed=true and therefore skip
      // its own consume call.
      final q = _CountingQuotaClient(limit: 7, startingUsed: 5);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      // Streaming path consumes once.
      final firstAllowed = await svc.checkAndIncrementDailyLimitForTest();
      expect(firstAllowed, isTrue);
      expect(q.consumeCalls, 1);

      // Fallback path enters sendChatMessage's gate with the
      // already-consumed flag set. Must NOT call consume again.
      final fallbackAllowed = await svc.sendChatMessageQuotaGateForTest(
        quotaAlreadyConsumed: true,
      );
      expect(fallbackAllowed, isTrue,
          reason: 'When quota was already paid, gate must let the '
              'fallback proceed without re-charging the user');
      expect(q.consumeCalls, 1,
          reason: 'BUG: a transient network error must not cost the '
              'user 2 quota slots — server consume must be invoked '
              'exactly once per user-visible message attempt');
    });

    test(
        'Default sendChatMessage gate (quotaAlreadyConsumed=false) '
        'still consumes exactly once', () async {
      // Regression guard for the non-streaming path: when sendChatMessage
      // is the primary entrypoint (no upstream consume), the gate MUST
      // still consume so the contract is unchanged.
      final q = _CountingQuotaClient(limit: 7, startingUsed: 0);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final allowed = await svc.sendChatMessageQuotaGateForTest(
        quotaAlreadyConsumed: false,
      );

      expect(allowed, isTrue);
      expect(q.consumeCalls, 1,
          reason: 'Primary sendChatMessage path must still consume');
    });

    test(
        'Pro user: streaming + fallback never touches the quota client '
        'regardless of flag', () async {
      final q = _CountingQuotaClient(limit: -1, plan: 'pro');
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      svc.isProUser = true;

      // Streaming path — pro shortcut.
      await svc.checkAndIncrementDailyLimitForTest();
      // Fallback path — pro shortcut, flag irrelevant.
      await svc.sendChatMessageQuotaGateForTest(
        quotaAlreadyConsumed: true,
      );

      expect(q.consumeCalls, 0,
          reason: 'Pro users must never hit the quota client');
    });

    test(
        'Exhausted free user with quotaAlreadyConsumed=true is still '
        'allowed (already paid for this turn)', () async {
      // Edge case: user is at 7/7 because the streaming consume
      // pushed them to the limit. The fallback must not block them
      // out of the answer they already paid for.
      final q = _CountingQuotaClient(limit: 7, startingUsed: 7);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final allowed = await svc.sendChatMessageQuotaGateForTest(
        quotaAlreadyConsumed: true,
      );

      expect(allowed, isTrue,
          reason: 'Already-paid turn must complete even if the user '
              'is now at the cap');
      expect(q.consumeCalls, 0);
    });
  });
  debugDefaultTargetPlatformOverride = null;
}
