@Tags(['fast'])
library;

// =============================================================================
// oauth_storage_service_test.dart — payload + result shape contract.
// -----------------------------------------------------------------------------
// Pure unit tests. No Supabase init, no IO. We pin the wire contract that the
// oauth-callback Edge Function depends on: payload field names, optional-field
// elision, response parsing, and the empty-token guard.
//
// The actual network call is exercised by the Deno tests for oauth-callback
// (server-side) and by the canary smoke after deploy.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/oauth_storage_service.dart';

void main() {
  group('OAuthCallbackRequest.toJson', () {
    test('emits provider + access_token at minimum', () {
      const req = OAuthCallbackRequest(
        provider: 'gmail',
        accessToken: 'ya29.abc',
      );
      final json = req.toJson();
      expect(json['provider'], 'gmail');
      expect(json['access_token'], 'ya29.abc');
      expect(json.containsKey('refresh_token'), isFalse);
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('expires_in'), isFalse);
    });

    test('includes all optional fields when present', () {
      const req = OAuthCallbackRequest(
        provider: 'gmail',
        accessToken: 'ya29.abc',
        refreshToken: '1//rt',
        email: 'user@gmail.com',
        expiresIn: 3600,
        scope: 'email https://www.googleapis.com/auth/gmail.send',
      );
      final json = req.toJson();
      expect(json['provider'], 'gmail');
      expect(json['access_token'], 'ya29.abc');
      expect(json['refresh_token'], '1//rt');
      expect(json['email'], 'user@gmail.com');
      expect(json['expires_in'], 3600);
      expect(json['scope'],
          'email https://www.googleapis.com/auth/gmail.send');
    });

    test('elides empty-string scope', () {
      const req = OAuthCallbackRequest(
        provider: 'gmail',
        accessToken: 'ya29.abc',
        scope: '',
      );
      final json = req.toJson();
      expect(json.containsKey('scope'), isFalse,
          reason: 'empty scope must not be persisted as empty-string NULL');
    });

    test('elides empty-string refresh_token', () {
      const req = OAuthCallbackRequest(
        provider: 'gmail',
        accessToken: 'ya29.abc',
        refreshToken: '',
      );
      final json = req.toJson();
      expect(json.containsKey('refresh_token'), isFalse,
          reason: 'empty string should not pollute the wire payload');
    });

    test('elides empty-string email', () {
      const req = OAuthCallbackRequest(
        provider: 'gmail',
        accessToken: 'ya29.abc',
        email: '',
      );
      final json = req.toJson();
      expect(json.containsKey('email'), isFalse);
    });

    test('field names use snake_case to match Edge Function contract', () {
      // The Edge Function (supabase/functions/oauth-callback/payload.ts)
      // expects exactly these snake_case keys. If this regresses to
      // camelCase, oauth-callback returns 400 and Gmail send falls back to
      // Resend silently — which is exactly the bug this task closes.
      const req = OAuthCallbackRequest(
        provider: 'gmail',
        accessToken: 'tok',
        refreshToken: 'r',
        email: 'a@b.co',
        expiresIn: 60,
      );
      final keys = req.toJson().keys.toSet();
      expect(keys, containsAll(<String>{
        'provider',
        'access_token',
        'refresh_token',
        'email',
        'expires_in',
      }));
    });
  });

  group('OAuthCallbackResult.fromJson', () {
    test('parses ok=true with email and expires_at', () {
      final r = OAuthCallbackResult.fromJson({
        'ok': true,
        'email': 'user@gmail.com',
        'expires_at': '2026-05-05T13:00:00.000Z',
        'has_refresh_token': true,
      });
      expect(r.ok, isTrue);
      expect(r.email, 'user@gmail.com');
      expect(r.expiresAt, isNotNull);
      expect(r.expiresAt!.toUtc().year, 2026);
      expect(r.expiresAt!.toUtc().hour, 13);
      expect(r.hasRefreshToken, isTrue);
    });

    test('handles missing optional fields', () {
      final r = OAuthCallbackResult.fromJson({'ok': true});
      expect(r.ok, isTrue);
      expect(r.email, isNull);
      expect(r.expiresAt, isNull);
      expect(r.hasRefreshToken, isNull,
          reason: 'absent flag must be null, not false — distinguishes '
              'older Edge Function build from explicit no-refresh-token');
    });

    test('parses has_refresh_token=false explicitly', () {
      final r = OAuthCallbackResult.fromJson({
        'ok': true,
        'has_refresh_token': false,
      });
      expect(r.hasRefreshToken, isFalse);
    });

    test('treats ok!=true as false', () {
      final r = OAuthCallbackResult.fromJson({'ok': false});
      expect(r.ok, isFalse);
    });

    test('tolerates malformed expires_at by yielding null', () {
      final r = OAuthCallbackResult.fromJson({
        'ok': true,
        'expires_at': 'not-a-date',
      });
      expect(r.expiresAt, isNull,
          reason: 'tryParse should swallow malformed timestamps');
    });
  });

  group('OAuthStorageException', () {
    test('toString includes message', () {
      const e = OAuthStorageException('boom');
      expect(e.toString(), 'OAuthStorageException: boom');
    });

    test('stores cause when provided', () {
      final cause = Exception('inner');
      final e = OAuthStorageException('outer', cause);
      expect(e.message, 'outer');
      expect(e.cause, isNotNull);
    });
  });

  group('OAuthStorageService.persistGmailToken — guards', () {
    test('throws OAuthStorageException on empty access_token', () async {
      // Empty token must be rejected client-side before we waste an
      // Edge Function invocation (and to surface the bug fast in dev).
      final svc = OAuthStorageService();
      expect(
        () => svc.persistGmailToken(accessToken: ''),
        throwsA(isA<OAuthStorageException>().having(
          (e) => e.message,
          'message',
          contains('access_token'),
        )),
      );
    });
  });
}
