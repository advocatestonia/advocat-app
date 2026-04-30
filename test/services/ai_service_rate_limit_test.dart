// =============================================================================
// AI service — friendly rate-limit (429) & overload (529) error mapping
// =============================================================================
//
// Pre-launch fix (2026-04-29): when Anthropic returns 429 (rate limit) or
// 529 (overloaded), the Edge Function `claude-proxy` now forwards a
// structured JSON shape:
//
//   429 → { "error": "rate_limit", "retry_after_seconds": N,
//           "user_message_key": "ai_error_rate_limit" }
//   529 → { "error": "overload",
//           "user_message_key": "ai_error_overload" }
//
// This test pins the contract on the Dart side:
//
//   1. ClaudeServiceException carries the parsed error code so callers
//      (chat_screen) can pick a localized user-facing message.
//   2. AIService refunds local quota when the request fails with
//      rate_limit / overload — the user must NOT lose a free message
//      just because Anthropic was momentarily unavailable.
//
// We deliberately stay at the seam level (no real Dio / Supabase) so the
// test is hermetic and runs in <100ms.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/claude_service.dart';

class _CountingQuotaClient implements AiQuotaClient {
  _CountingQuotaClient({this.limit = 7, int startingUsed = 0})
      : _used = startingUsed;

  final int limit;
  int _used;

  int consumeCalls = 0;
  int checkCalls = 0;

  @override
  Future<AiQuota?> check() async {
    checkCalls += 1;
    return AiQuota(
      allowed: _used < limit,
      remaining: (limit - _used).clamp(0, limit),
      limit: limit,
      plan: 'free',
      used: _used,
    );
  }

  @override
  Future<AiQuota?> consume() async {
    consumeCalls += 1;
    if (_used >= limit) {
      return AiQuota(
        allowed: false,
        remaining: 0,
        limit: limit,
        plan: 'free',
        used: _used,
      );
    }
    _used += 1;
    return AiQuota(
      allowed: _used <= limit,
      remaining: (limit - _used).clamp(0, limit),
      limit: limit,
      plan: 'free',
      used: _used,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClaudeServiceException error code parsing', () {
    test(
        'rate_limit body → exception carries errorCode "rate_limit" and the '
        'localization key "ai_error_rate_limit"', () {
      final body = {
        'error': 'rate_limit',
        'retry_after_seconds': 30,
        'user_message_key': 'ai_error_rate_limit',
      };
      final ex = ClaudeServiceException.fromProxyError(body, statusCode: 429);
      expect(ex.errorCode, 'rate_limit');
      expect(ex.userMessageKey, 'ai_error_rate_limit');
      expect(ex.retryAfterSeconds, 30);
    });

    test(
        'overload body → exception carries errorCode "overload" and the '
        'localization key "ai_error_overload"', () {
      final body = {
        'error': 'overload',
        'user_message_key': 'ai_error_overload',
      };
      final ex = ClaudeServiceException.fromProxyError(body, statusCode: 529);
      expect(ex.errorCode, 'overload');
      expect(ex.userMessageKey, 'ai_error_overload');
      expect(ex.retryAfterSeconds, isNull);
    });

    test(
        'legacy body without error code falls back to a generic exception '
        'so existing callers stay working', () {
      final body = {'error': 'Internal error', 'details': 'something'};
      final ex = ClaudeServiceException.fromProxyError(body, statusCode: 500);
      expect(ex.errorCode, isNull);
      expect(ex.userMessageKey, isNull);
    });

    test('null / non-map body → generic exception, no crash', () {
      final ex = ClaudeServiceException.fromProxyError(null, statusCode: 500);
      expect(ex.errorCode, isNull);
      expect(ex.userMessageKey, isNull);
    });
  });

  group('AIService quota refund on rate-limit / overload', () {
    test(
        'refundLocalQuota after rate_limit must NOT leave the user '
        'short one free message', () async {
      // Free user at 5/7. Streaming starts → consume → 6/7.
      // Anthropic returns 429 → service must refund → cached remaining
      // reflects 2 (back to original 7 - 5 = 2).
      final q = _CountingQuotaClient(limit: 7, startingUsed: 5);
      final svc = AIService(
        claudeService: ClaudeService(),
        quotaClient: q,
      );

      // Pretend the streaming path has consumed.
      final consumed = await svc.checkAndIncrementDailyLimitForTest();
      expect(consumed, isTrue);
      expect(q.consumeCalls, 1);

      // Cached state right after consume: remaining == 1 (was 2, we used 1).
      final cachedAfter = await svc.checkQuota();
      expect(cachedAfter.remaining, 1,
          reason: 'After one consume the local cache should drop by 1');

      // Anthropic now 429s → refund.
      svc.refundLocalQuotaForTest();

      // Cached state must reflect refund: remaining is back to 2.
      final cachedRefunded = await svc.checkQuota();
      expect(cachedRefunded.remaining, 2,
          reason:
              'BUG: a 429 (rate-limit) or 529 (overload) must NOT cost the '
              'user a free message — refund the local cache so the UI shows '
              'the correct count immediately');
      expect(cachedRefunded.allowed, isTrue,
          reason: 'After refund the user is allowed to retry');
    });

    test(
        'refundLocalQuota is a no-op for pro users (they have no quota '
        'to refund)', () async {
      final q = _CountingQuotaClient(limit: 7, startingUsed: 0);
      final svc = AIService(
        claudeService: ClaudeService(),
        quotaClient: q,
      );
      svc.isProUser = true;

      // Should be safe to call even when no consume happened.
      svc.refundLocalQuotaForTest();
      final fresh = await svc.checkQuota();
      expect(fresh.isPro, isTrue);
    });

    test(
        'refundLocalQuota is bounded — cannot push remaining above the '
        'monthly limit', () async {
      // Free user with full quota — refund must be a no-op (no negative
      // used count, no remaining > limit).
      final q = _CountingQuotaClient(limit: 7, startingUsed: 0);
      final svc = AIService(
        claudeService: ClaudeService(),
        quotaClient: q,
      );

      // Seed cache with full quota.
      final fresh = await svc.checkQuota();
      expect(fresh.remaining, 7);

      svc.refundLocalQuotaForTest();
      final after = await svc.checkQuota();
      expect(after.remaining, 7,
          reason: 'Refund must not push remaining above the limit');
      expect(after.used, 0,
          reason: 'Refund must not push used below zero');
    });
  });

  debugDefaultTargetPlatformOverride = null;
}
