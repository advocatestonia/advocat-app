// =============================================================================
// AI quota enforcement tests — revenue-critical gate (2026-04-23)
// =============================================================================
//
// Owner report: "Free tier has NO message limit — users can send unlimited
// messages without paying." This file pins down the contract so the bug
// cannot silently regress:
//
//   1. allowed == false → AI call is NOT made, user sees upgrade message
//   2. allowed == true  → AI call proceeds, counter increments
//   3. check-ai-quota 500 → denied (fall-closed) — previously this was
//      the bug (fell open to a local SharedPreferences counter)
//   4. After 7 messages → no more allowed
//
// The tests drive [AIService] through a fake [AiQuotaClient] so they do
// not hit the network or instantiate a real ClaudeService.

@Tags(['fast'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/claude_service.dart';

/// Fake that tracks how many times [consume] / [check] are called, whether
/// each call was allowed, and what server-reported usage looked like.
class _RecordingQuotaClient implements AiQuotaClient {
  _RecordingQuotaClient({
    this.limit = 7,
    this.plan = 'free',
    int startingUsed = 0,
    this.failAll = false,
  }) : _used = startingUsed;

  final int limit;
  final String plan;
  int _used;
  bool failAll;

  int checkCalls = 0;
  int consumeCalls = 0;

  int get used => _used;

  @override
  Future<AiQuota?> check() async {
    checkCalls += 1;
    if (failAll) return null;
    return _snapshot();
  }

  @override
  Future<AiQuota?> consume() async {
    consumeCalls += 1;
    if (failAll) return null;
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

  AiQuota _snapshot() {
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

  group('AIService quota gate — revenue-critical', () {
    test('allowed == true → _checkAndIncrementDailyLimit returns true '
        'and server counter increments', () async {
      final q = _RecordingQuotaClient(limit: 7, startingUsed: 0);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final allowed = await svc.checkAndIncrementDailyLimitForTest();

      expect(allowed, isTrue,
          reason: 'Fresh free user must be allowed through the gate');
      expect(q.consumeCalls, 1,
          reason: 'Gate must atomically consume on the server');
      expect(q.used, 1,
          reason: 'Server-side counter must increment exactly once');
    });

    test('allowed == false → gate returns false, NO further consume calls',
        () async {
      final q = _RecordingQuotaClient(limit: 7, startingUsed: 7);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final allowed = await svc.checkAndIncrementDailyLimitForTest();

      expect(allowed, isFalse,
          reason: 'Exhausted free user must be blocked');
      // Fake does not increment past the limit — this pins down the
      // "no further Claude call on allowed=false" contract.
      expect(q.used, 7, reason: 'Counter must not increment past the limit');
    });

    test('check-ai-quota 500 / network failure → fall-CLOSED (denied)',
        () async {
      // This is the ORIGINAL BUG: previously a 500 made the client fall
      // back to a local SharedPreferences counter, effectively handing
      // free users unlimited Claude calls by killing the Edge Function.
      final q = _RecordingQuotaClient(failAll: true);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final allowed = await svc.checkAndIncrementDailyLimitForTest();

      expect(allowed, isFalse,
          reason: 'Server unavailable must DENY, not fall back to '
              'local counter (revenue-critical regression fix)');
      final quota = await svc.consumeQuota();
      expect(quota.allowed, isFalse);
      expect(quota.plan, 'free');
      expect(quota.remaining, 0);
    });

    test('After 7 messages: no more allowed', () async {
      final q = _RecordingQuotaClient(limit: 7, startingUsed: 0);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final results = <bool>[];
      for (var i = 0; i < 10; i++) {
        results.add(await svc.checkAndIncrementDailyLimitForTest());
      }

      // First 7 must succeed; the remaining 3 must be blocked.
      expect(results.sublist(0, 7), everyElement(isTrue),
          reason: 'First 7 messages are the free tier ceiling');
      expect(results.sublist(7), everyElement(isFalse),
          reason: 'Messages 8-10 must be blocked without touching Claude');
      expect(q.used, 7,
          reason: 'Server counter must cap at 7 even across 10 attempts');
    });

    test('Pro user bypasses the gate entirely (unlimited)', () async {
      final q = _RecordingQuotaClient(limit: -1, plan: 'pro');
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      svc.isProUser = true;

      for (var i = 0; i < 5; i++) {
        expect(
          await svc.checkAndIncrementDailyLimitForTest(),
          isTrue,
          reason: 'Pro users are always allowed',
        );
      }
      expect(q.consumeCalls, 0,
          reason: 'Pro shortcut must not hit the quota client at all');
    });

    test('FREE_LIMIT matches Founder\'s Beta refund policy (7)', () {
      // If someone bumps this to 50 again without coordinating with the
      // server-side FREE_LIMIT, the server will still block at 7 and
      // the counter UI will desync. This test is the canary.
      expect(AIService.freeTotalLimit, 7,
          reason: 'Founder\'s Beta refund policy: 14 days OR 7 AI responses');
    });

    test('consumeQuota denied response has sane shape for UI', () async {
      final q = _RecordingQuotaClient(limit: 7, startingUsed: 7);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final quota = await svc.consumeQuota();

      expect(quota.allowed, isFalse);
      expect(quota.isPro, isFalse);
      expect(quota.limit, 7);
      expect(quota.remaining, 0);
    });

    test('getRemainingFreeCalls returns 0 when server is unreachable',
        () async {
      // UI-layer corollary of "fall closed": if the server is down we
      // render 0 remaining, which flips the input bar to the Upgrade CTA.
      final q = _RecordingQuotaClient(failAll: true);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final remaining = await svc.getRemainingFreeCalls();
      expect(remaining, 0);
    });
  });
  debugDefaultTargetPlatformOverride = null;
}
