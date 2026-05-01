// claude_proxy_error_test.dart
//
// OMEGA pre-launch QA expansion (2026-04-29). Pins the contract for
// `ClaudeServiceException.fromProxyError` — the factory that
// translates the structured `claude-proxy` Edge Function error body
// into a typed exception the chat layer uses to decide whether to
//
//   • refund the quota slot (rate_limit / overload → refund),
//   • surface a localized friendly message,
//   • show a generic error.
//
// This decision matters because (per docs/security/) the front-end
// hits the proxy, not Anthropic directly, so EVERY 4xx/5xx travels
// through this factory. Misclassifying a rate_limit as "generic"
// would burn the user's quota AND show the wrong message.
//
// The factory must:
//   • recognise the structured shape `{error:'rate_limit'|'overload',
//     user_message_key, retry_after_seconds}`
//   • fall back gracefully to legacy `{error:'<message string>'}`
//   • survive non-Map bodies, null bodies, missing fields, wrong
//     field types
//   • never throw — it is invoked from a catch block
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/claude_service.dart';

void main() {
  group('ClaudeServiceException.fromProxyError — structured shape', () {
    test('rate_limit body → errorCode=rate_limit + retry_after preserved', () {
      final ex = ClaudeServiceException.fromProxyError(
        {
          'error': 'rate_limit',
          'user_message_key': 'errors.rate_limit',
          'retry_after_seconds': 30,
        },
        statusCode: 429,
      );
      expect(ex.errorCode, 'rate_limit');
      expect(ex.userMessageKey, 'errors.rate_limit');
      expect(ex.retryAfterSeconds, 30);
      expect(ex.message, contains('429'));
      expect(ex.message, contains('rate_limit'));
    });

    test('overload body → errorCode=overload', () {
      final ex = ClaudeServiceException.fromProxyError(
        {
          'error': 'overload',
          'user_message_key': 'errors.overload',
          'retry_after_seconds': 10,
        },
        statusCode: 529,
      );
      expect(ex.errorCode, 'overload');
      expect(ex.userMessageKey, 'errors.overload');
      expect(ex.retryAfterSeconds, 10);
    });

    test('rate_limit without retry_after_seconds → null retryAfterSeconds',
        () {
      final ex = ClaudeServiceException.fromProxyError(
        {'error': 'rate_limit'},
        statusCode: 429,
      );
      expect(ex.errorCode, 'rate_limit');
      expect(ex.retryAfterSeconds, isNull);
    });

    test('rate_limit with non-int retry_after_seconds → null', () {
      final ex = ClaudeServiceException.fromProxyError(
        {
          'error': 'rate_limit',
          'retry_after_seconds': 'thirty',
        },
        statusCode: 429,
      );
      expect(ex.errorCode, 'rate_limit');
      expect(ex.retryAfterSeconds, isNull,
          reason: 'wrong type must NOT crash — falls back to null');
    });
  });

  group('ClaudeServiceException.fromProxyError — legacy + degenerate', () {
    test('legacy {error: "string message"} → errorCode null, message preserved',
        () {
      final ex = ClaudeServiceException.fromProxyError(
        {'error': 'invalid_api_key'},
        statusCode: 401,
      );
      expect(ex.errorCode, isNull,
          reason: 'legacy message strings have no structured code');
      expect(ex.message, 'invalid_api_key');
    });

    test('null body → fallback message includes status code', () {
      final ex = ClaudeServiceException.fromProxyError(
        null,
        statusCode: 500,
      );
      expect(ex.errorCode, isNull);
      expect(ex.message, contains('500'));
    });

    test('non-Map body (string) → fallback message', () {
      final ex = ClaudeServiceException.fromProxyError(
        'just a raw string',
        statusCode: 502,
      );
      expect(ex.errorCode, isNull);
      expect(ex.message, contains('502'));
    });

    test('Map without "error" field → generic fallback with status', () {
      final ex = ClaudeServiceException.fromProxyError(
        {'foo': 'bar'},
        statusCode: 500,
      );
      expect(ex.errorCode, isNull);
      expect(ex.message, contains('500'));
    });

    test('Map with unknown error code "unknown_blah" → legacy passthrough',
        () {
      final ex = ClaudeServiceException.fromProxyError(
        {'error': 'unknown_blah'},
        statusCode: 500,
      );
      // Unknown structured codes fall through to legacy: errorCode null,
      // message = the raw error string.
      expect(ex.errorCode, isNull);
      expect(ex.message, 'unknown_blah');
    });

    test('Map with int "error" field → fallback (non-string error)', () {
      final ex = ClaudeServiceException.fromProxyError(
        {'error': 42},
        statusCode: 500,
      );
      expect(ex.errorCode, isNull);
      expect(ex.message, contains('500'));
    });

    test('cause exception is preserved when supplied', () {
      final cause = Exception('underlying network failure');
      final ex = ClaudeServiceException.fromProxyError(
        null,
        statusCode: 500,
        cause: cause,
      );
      expect(ex.cause, same(cause));
    });
  });

  group('ClaudeServiceException — toString contract', () {
    test('toString includes class name + message', () {
      const ex = ClaudeServiceException('boom');
      expect(ex.toString(), 'ClaudeServiceException: boom');
    });

    test('default constructor has null structured fields', () {
      const ex = ClaudeServiceException('legacy');
      expect(ex.errorCode, isNull);
      expect(ex.userMessageKey, isNull);
      expect(ex.retryAfterSeconds, isNull);
    });
  });

  group('ClaudeService.estimateTokens — sanity check', () {
    test('empty string → 0 tokens', () {
      expect(ClaudeService.estimateTokens(''), 0);
    });

    test('1-char string → 1 token (rounded up from 0.25)', () {
      expect(ClaudeService.estimateTokens('a'), 1);
    });

    test('4-char string → 1 token (4/4 = 1.0 ceiling)', () {
      expect(ClaudeService.estimateTokens('abcd'), 1);
    });

    test('5-char string → 2 tokens (rounded up)', () {
      expect(ClaudeService.estimateTokens('abcde'), 2);
    });

    test('long Cyrillic string still returns positive int', () {
      // 100 Cyrillic chars — heuristic is 4 chars/token regardless of
      // codepoint width. Pin the formula.
      const text =
          'Привет помоги пожалуйста спасибо большое нужна юридическая консультация';
      expect(ClaudeService.estimateTokens(text), greaterThan(0));
      expect(ClaudeService.estimateTokens(text), (text.length / 4).ceil());
    });
  });

  group('TokenUsage.fromJson — defensive parsing', () {
    test('full payload sums correctly', () {
      final u = TokenUsage.fromJson({
        'input_tokens': 100,
        'output_tokens': 50,
      });
      expect(u.inputTokens, 100);
      expect(u.outputTokens, 50);
      expect(u.totalTokens, 150);
    });

    test('missing fields default to 0', () {
      final u = TokenUsage.fromJson(<String, dynamic>{});
      expect(u.inputTokens, 0);
      expect(u.outputTokens, 0);
      expect(u.totalTokens, 0);
    });

    test('partial payload is tolerated', () {
      final u = TokenUsage.fromJson({'input_tokens': 25});
      expect(u.inputTokens, 25);
      expect(u.outputTokens, 0);
      expect(u.totalTokens, 25);
    });
  });
}
