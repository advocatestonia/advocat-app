// ErrorReporter unit tests.
//
// Covers the pure scrubbing logic — looksLikePii, hashedUserId,
// _scrubExtras, beforeSend, beforeBreadcrumb. We do NOT exercise the
// real Sentry transport (it's gated by sentryEnabled which is compile-
// time false in tests because SENTRY_DSN is unset). The capture/message
// API contract under that gate is verified separately.
//
// Why this matters: PII scrubbing is a privilege/GDPR guardrail for the
// product. Any regression here leaks chat/email/case content to a
// third-party processor.

import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:advocat/core/services/error_reporter.dart';

void main() {
  group('ErrorReporter — looksLikePii', () {
    test('flags emails', () {
      expect(ErrorReporter.looksLikePii('contact me at john@example.com please'),
          isTrue);
    });

    test('flags Finnish henkilötunnus', () {
      // Example shape DDMMYY[+-A]NNNX — sample is synthetic.
      expect(ErrorReporter.looksLikePii('hetu 010101-1230'), isTrue);
    });

    test('flags Estonian isikukood (11 digits, starts 3-6)', () {
      expect(ErrorReporter.looksLikePii('isikukood 38001012345'), isTrue);
    });

    test('flags case-number patterns like 5500/R/75170/25', () {
      expect(ErrorReporter.looksLikePii('case 5500/R/75170/25 pending'),
          isTrue);
    });

    test('flags card-like 13-19 digit runs', () {
      expect(ErrorReporter.looksLikePii('paid with 4111 1111 1111 1111'),
          isTrue);
    });

    test('flags JWT tokens', () {
      expect(
        ErrorReporter.looksLikePii(
            'eyJhbGciOiJIUzI1NiJ9.eyJzdWIxMjMifQ.abc'),
        isTrue,
      );
    });

    test('flags long free-text (> 500 chars)', () {
      final long = 'x' * 600;
      expect(ErrorReporter.looksLikePii(long), isTrue);
    });

    test('does not flag innocuous error messages', () {
      expect(
        ErrorReporter.looksLikePii('Connection timeout after 30s'),
        isFalse,
      );
      expect(
        ErrorReporter.looksLikePii('TypeError: null is not a function'),
        isFalse,
      );
      expect(ErrorReporter.looksLikePii(''), isFalse);
    });
  });

  group('ErrorReporter — hashedUserId', () {
    test('returns anon for null', () {
      expect(ErrorReporter.hashedUserId(null), equals('anon'));
    });

    test('returns anon for empty', () {
      expect(ErrorReporter.hashedUserId(''), equals('anon'));
    });

    test('returns 8-hex-char stable digest', () {
      final h = ErrorReporter.hashedUserId('user-uuid-1234');
      expect(h.length, equals(8));
      expect(RegExp(r'^[0-9a-f]{8}$').hasMatch(h), isTrue);
      // Stability
      expect(
        ErrorReporter.hashedUserId('user-uuid-1234'),
        equals(h),
      );
    });

    test('different uids produce different digests', () {
      expect(
        ErrorReporter.hashedUserId('user-a'),
        isNot(equals(ErrorReporter.hashedUserId('user-b'))),
      );
    });
  });

  group('ErrorReporter — beforeSend', () {
    test('drops event whose message looks like PII', () async {
      final ev = SentryEvent(
        message: SentryMessage('Login failed for jane@example.com'),
      );
      final result = await ErrorReporter.beforeSend(ev, Hint());
      expect(result, isNull);
    });

    test('keeps event with safe message', () async {
      final ev = SentryEvent(
        message: SentryMessage('Network unreachable'),
      );
      final result = await ErrorReporter.beforeSend(ev, Hint());
      expect(result, isNotNull);
      expect(result!.message?.formatted, equals('Network unreachable'));
    });

    test('strips user object down to hashed id', () async {
      final ev = SentryEvent(
        message: SentryMessage('boom'),
        user: SentryUser(
          id: 'supabase-uid-abc',
          email: 'leak@example.com',
          name: 'Should Not Leak',
          ipAddress: '1.2.3.4',
        ),
      );
      final result = await ErrorReporter.beforeSend(ev, Hint());
      expect(result, isNotNull);
      final user = result!.user;
      expect(user, isNotNull);
      expect(user!.email, isNull);
      expect(user.name, isNull);
      expect(user.ipAddress, isNull);
      expect(user.id, equals(ErrorReporter.hashedUserId('supabase-uid-abc')));
    });

    test('strips query string from request url', () async {
      final ev = SentryEvent(
        message: SentryMessage('http boom'),
        request: SentryRequest(
          url: 'https://app.advocat.ee/drafts?case_id=secret-uuid&token=abc',
          method: 'GET',
        ),
      );
      final result = await ErrorReporter.beforeSend(ev, Hint());
      expect(result, isNotNull);
      final url = result!.request?.url ?? '';
      expect(url.contains('case_id'), isFalse);
      expect(url.contains('token'), isFalse);
      expect(url.startsWith('https://app.advocat.ee/drafts'), isTrue);
    });
  });

  group('ErrorReporter — beforeBreadcrumb', () {
    test('drops breadcrumb whose message looks like PII', () {
      final bc = Breadcrumb(message: 'user@example.com clicked login');
      final out = ErrorReporter.beforeBreadcrumb(bc, Hint());
      expect(out, isNull);
    });

    test('keeps innocuous breadcrumb', () {
      final bc = Breadcrumb(message: 'navigated to /home', category: 'nav');
      final out = ErrorReporter.beforeBreadcrumb(bc, Hint());
      expect(out, isNotNull);
      expect(out!.message, equals('navigated to /home'));
    });

    test('scrubs url data field (strips query) and PII keys', () {
      final bc = Breadcrumb(
        message: 'http call',
        data: <String, dynamic>{
          'url': 'https://api.advocat.ee/v1/draft?secret=xyz',
          'email': 'leak@example.com',
          'method': 'POST',
        },
      );
      final out = ErrorReporter.beforeBreadcrumb(bc, Hint());
      expect(out, isNotNull);
      final data = out!.data ?? const <String, dynamic>{};
      expect(data.containsKey('email'), isFalse);
      expect(data['method'], equals('POST'));
      expect((data['url'] as String).contains('secret'), isFalse);
    });
  });

  group('ErrorReporter — capture/message (no-op without DSN)', () {
    test('capture is a no-op when Sentry is disabled', () async {
      // sentryEnabled is false in tests (SENTRY_DSN not provided at compile
      // time) — capture must not throw, and must not initialise Sentry.
      expect(sentryEnabled, isFalse,
          reason: 'tests should run without SENTRY_DSN');
      await expectLater(
        ErrorReporter.capture(StateError('test'), StackTrace.current,
            extras: {'route': '/drafts'}),
        completes,
      );
    });

    test('message is a no-op when Sentry is disabled', () async {
      await expectLater(
        ErrorReporter.message('something happened'),
        completes,
      );
    });

    test('setUser is a no-op when Sentry is disabled', () {
      expect(
        () => ErrorReporter.setUser(uid: 'abc-123'),
        returnsNormally,
      );
      expect(() => ErrorReporter.clearUser(), returnsNormally);
    });
  });
}
