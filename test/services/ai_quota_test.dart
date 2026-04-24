// =============================================================================
// AI quota enforcement tests — P0-3
// =============================================================================
//
// Covers the server-side free-tier quota logic in AIService:
//   1. Free user at 49 messages → allowed, remaining=1
//   2. Free user at 50 messages → blocked
//   3. Free user at 51 → still blocked (defensive)
//   4. Pro user (unlimited) → always allowed
//   5. Edge Function unreachable → fallback to SharedPreferences
//   6. Atomic race: two concurrent consumes increment monotonically
//
// We inject a fake [AiQuotaClient] to drive deterministic responses.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/claude_service.dart';

class _FakeQuotaClient implements AiQuotaClient {
  _FakeQuotaClient({
    required this.limit,
    required this.plan,
    int startingUsed = 0,
    this.nullOnCheck = false,
    this.nullOnConsume = false,
  })  : _used = startingUsed;

  final int limit;
  final String plan;
  final bool nullOnCheck;
  final bool nullOnConsume;
  int _used;

  int checkCalls = 0;
  int consumeCalls = 0;

  int get used => _used;

  @override
  Future<AiQuota?> check() async {
    checkCalls += 1;
    if (nullOnCheck) return null;
    return _build();
  }

  @override
  Future<AiQuota?> consume() async {
    consumeCalls += 1;
    if (nullOnConsume) return null;
    if (plan == 'pro') {
      return const AiQuota(
        allowed: true,
        remaining: null,
        limit: -1,
        plan: 'pro',
        unlimited: true,
      );
    }
    // Match the Edge Function's `allowed = newCount <= FREE_LIMIT` semantics:
    // a consume at used==limit is blocked, NOT incremented, allowed=false.
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
    final remaining = (limit - _used).clamp(0, limit);
    return AiQuota(
      allowed: _used < limit,
      remaining: remaining,
      limit: limit,
      plan: plan,
      used: _used,
    );
  }
}

/// Minimal ClaudeService stub so we can instantiate AIService without
/// hitting the network. None of the tests invoke chat — only quota paths.
class _DummyClaudeService extends ClaudeService {
  _DummyClaudeService();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AIService.checkQuota()', () {
    test('1. free user at 49/50 → allowed, remaining=1', () async {
      final q = _FakeQuotaClient(limit: 50, plan: 'free', startingUsed: 49);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      final result = await svc.checkQuota(forceRefresh: true);
      expect(result.allowed, isTrue);
      expect(result.remaining, 1);
      expect(result.plan, 'free');
      expect(result.isPro, isFalse);
    });

    test('2. free user at 50/50 → blocked', () async {
      final q = _FakeQuotaClient(limit: 50, plan: 'free', startingUsed: 50);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      final result = await svc.checkQuota(forceRefresh: true);
      expect(result.allowed, isFalse);
      expect(result.remaining, 0);
    });

    test('3. free user at 51/50 → still blocked (defensive)', () async {
      final q = _FakeQuotaClient(limit: 50, plan: 'free', startingUsed: 51);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      final result = await svc.checkQuota(forceRefresh: true);
      expect(result.allowed, isFalse);
      expect(result.remaining, 0);
    });

    test('4. pro user is always allowed and unlimited', () async {
      final q = _FakeQuotaClient(limit: -1, plan: 'pro');
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      final result = await svc.checkQuota(forceRefresh: true);
      expect(result.allowed, isTrue);
      expect(result.isPro, isTrue);
      expect(result.remaining, isNull);
      expect(result.plan, 'pro');
    });

    test('5. pro flag on service bypasses client entirely', () async {
      final q = _FakeQuotaClient(limit: 50, plan: 'free', startingUsed: 99);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      svc.isProUser = true;
      final result = await svc.checkQuota(forceRefresh: true);
      expect(result.isPro, isTrue);
      expect(q.checkCalls, 0,
          reason: 'Pro shortcut must not hit the quota client');
    });

    test('6. Edge Function unavailable → fall-closed (denied)',
        () async {
      // Revenue-critical rule (2026-04-23): when check-ai-quota fails we
      // deny the request instead of trusting a local counter. Otherwise a
      // free user could force unlimited messages by simulating a 500.
      SharedPreferences.setMockInitialValues({'ai_total_free_count': 7});
      final q = _FakeQuotaClient(
        limit: 7,
        plan: 'free',
        nullOnCheck: true,
      );
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      final result = await svc.checkQuota(forceRefresh: true);
      expect(result.plan, 'free');
      expect(result.allowed, isFalse,
          reason: 'Fall-closed: 500 must deny, not allow');
      expect(result.remaining, 0);
    });

    test('7. cache hit within 60 s does not hit client again', () async {
      final q = _FakeQuotaClient(limit: 50, plan: 'free', startingUsed: 3);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      await svc.checkQuota(forceRefresh: true);
      await svc.checkQuota();
      await svc.checkQuota();
      expect(q.checkCalls, 1);
    });
  });

  group('AIService.consumeQuota()', () {
    test('8. consume increments until 50, then blocks', () async {
      final q = _FakeQuotaClient(limit: 50, plan: 'free', startingUsed: 48);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final r1 = await svc.consumeQuota();
      expect(r1.allowed, isTrue);
      expect(r1.used, 49);

      final r2 = await svc.consumeQuota();
      expect(r2.allowed, isTrue);
      expect(r2.used, 50);

      final r3 = await svc.consumeQuota();
      expect(r3.allowed, isFalse,
          reason: '51st consume must be blocked by server counter');
      expect(r3.used, 50,
          reason: 'Fake must not increment past the limit');
    });

    test('9. pro user never increments counter', () async {
      final q = _FakeQuotaClient(limit: -1, plan: 'pro');
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      await svc.consumeQuota();
      await svc.consumeQuota();
      expect(q.used, 0);
    });

    test('10. race condition: two concurrent consumes yield monotonic count',
        () async {
      final q = _FakeQuotaClient(limit: 50, plan: 'free', startingUsed: 0);
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );

      final futures = List<Future<AiQuota>>.generate(
          5, (_) => svc.consumeQuota());
      final results = await Future.wait(futures);
      final counts = results.map((r) => r.used).toList()..sort();
      expect(counts, [1, 2, 3, 4, 5],
          reason: 'Each consume must produce a unique monotonic count');
    });

    test('11. consume fall-closed when Edge Function down',
        () async {
      // Previous behaviour (local SharedPreferences increment) was the
      // root cause of the "free tier has no message limit" bug — a free
      // user with Supabase unreachable would get unlimited messages. The
      // new contract is: transport failure → denied.
      SharedPreferences.setMockInitialValues({'ai_total_free_count': 10});
      final q = _FakeQuotaClient(
        limit: 7,
        plan: 'free',
        nullOnConsume: true,
      );
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: q,
      );
      final r = await svc.consumeQuota();
      expect(r.allowed, isFalse);
      expect(r.plan, 'free');
    });
  });

  group('AIService.getRemainingFreeCalls', () {
    test('12. pro user returns -1', () async {
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: _FakeQuotaClient(limit: -1, plan: 'pro'),
      );
      svc.isProUser = true;
      final remaining = await svc.getRemainingFreeCalls();
      expect(remaining, -1);
    });

    test('13. free user returns server-reported remaining', () async {
      final svc = AIService(
        claudeService: _DummyClaudeService(),
        quotaClient: _FakeQuotaClient(
            limit: 50, plan: 'free', startingUsed: 30),
      );
      final remaining = await svc.getRemainingFreeCalls();
      expect(remaining, 20);
    });
  });
  debugDefaultTargetPlatformOverride = null;
}
