// lib/services/oauth_storage_service.dart
// -----------------------------------------------------------------------------
// Persists the user's Google OAuth provider tokens (returned in-memory by
// Supabase signInWithOAuth) to the `user_oauth_tokens` table via the
// oauth-callback Edge Function. Once persisted, the send-email function can
// read them and dispatch via Gmail API ("processor" GDPR posture) instead of
// falling back to Resend ("controller" posture).
//
// See: supabase/functions/oauth-callback/index.ts for the server contract.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Riverpod provider so call sites can ref.read(oauthStorageServiceProvider).
final oauthStorageServiceProvider = Provider<OAuthStorageService>((ref) {
  return OAuthStorageService();
});

/// Pure data class describing the body we POST to /oauth-callback.
///
/// Lives in this file (not a separate `model` file) so a single import buys
/// you both the service and the payload — the caller never builds the JSON
/// shape themselves.
class OAuthCallbackRequest {
  const OAuthCallbackRequest({
    required this.provider,
    required this.accessToken,
    this.refreshToken,
    this.email,
    this.expiresIn,
    this.scope,
  });

  /// Currently only 'gmail' is accepted by the Edge Function.
  final String provider;
  final String accessToken;
  final String? refreshToken;
  final String? email;

  /// Lifetime of the access token in seconds (Google returns 3600).
  final int? expiresIn;

  /// Space-separated OAuth scopes the provider granted (or that we requested,
  /// as a fallback hint when the SDK doesn't expose the granted set).
  ///
  /// Persisted server-side in `user_oauth_tokens.scope` so other edge
  /// functions can verify capability (`gmail.readonly` vs `gmail.send`) at
  /// runtime without probing the Google API.
  final String? scope;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'provider': provider,
      'access_token': accessToken,
    };
    if (refreshToken != null && refreshToken!.isNotEmpty) {
      map['refresh_token'] = refreshToken;
    }
    if (email != null && email!.isNotEmpty) {
      map['email'] = email;
    }
    if (expiresIn != null) {
      map['expires_in'] = expiresIn;
    }
    if (scope != null && scope!.isNotEmpty) {
      map['scope'] = scope;
    }
    return map;
  }
}

/// Result returned by the Edge Function on success.
class OAuthCallbackResult {
  const OAuthCallbackResult({
    required this.ok,
    this.email,
    this.expiresAt,
    this.hasRefreshToken,
  });

  final bool ok;
  final String? email;
  final DateTime? expiresAt;

  /// `true` when the server persisted a refresh_token alongside the access
  /// token. Powers the "you'll need to sign in again at expiry" warning UI
  /// when this is `false` (no offline access). `null` when the field is
  /// absent in the response (older Edge Function build — treat as unknown).
  final bool? hasRefreshToken;

  factory OAuthCallbackResult.fromJson(Map<String, dynamic> json) {
    DateTime? expiresAt;
    final raw = json['expires_at'];
    if (raw is String) {
      expiresAt = DateTime.tryParse(raw);
    }
    bool? hasRefreshToken;
    final rawRefresh = json['has_refresh_token'];
    if (rawRefresh is bool) {
      hasRefreshToken = rawRefresh;
    }
    return OAuthCallbackResult(
      ok: json['ok'] == true,
      email: json['email'] as String?,
      expiresAt: expiresAt,
      hasRefreshToken: hasRefreshToken,
    );
  }
}

/// Thrown by [OAuthStorageService] when the Edge Function call fails or
/// returns a non-2xx status.
class OAuthStorageException implements Exception {
  const OAuthStorageException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => 'OAuthStorageException: $message';
}

/// Service wrapper around the oauth-callback Edge Function.
///
/// Constructor takes an optional [SupabaseClient] for testability — production
/// callers leave it null and the service grabs Supabase.instance.client at
/// call time (so a misconfigured init doesn't crash the constructor when
/// the service is bound at startup).
class OAuthStorageService {
  OAuthStorageService({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;

  SupabaseClient get _client {
    final c = _injectedClient ?? Supabase.instance.client;
    return c;
  }

  /// Persist Gmail OAuth tokens server-side. Called immediately after
  /// signInWithOAuth completes and the session contains a `providerToken`.
  ///
  /// `scope` is the space-separated OAuth scope string. Pass the actually-
  /// granted scopes if the SDK surfaces them; otherwise pass the requested
  /// scope set (`kGmailScopesActive`) as a best-effort hint — the server
  /// stores whatever it receives and the audit layer flags mismatches.
  Future<OAuthCallbackResult> persistGmailToken({
    required String accessToken,
    String? refreshToken,
    String? email,
    int? expiresInSeconds,
    String? scope,
  }) async {
    if (accessToken.isEmpty) {
      throw const OAuthStorageException('access_token must not be empty');
    }
    final req = OAuthCallbackRequest(
      provider: 'gmail',
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: email,
      expiresIn: expiresInSeconds,
      scope: scope,
    );

    try {
      final response = await _client.functions.invoke(
        'oauth-callback',
        body: req.toJson(),
      );

      if (response.status >= 400) {
        final data = response.data;
        final errMsg = data is Map ? (data['error']?.toString()) : null;
        throw OAuthStorageException(
          errMsg ?? 'oauth-callback returned ${response.status}',
        );
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw OAuthStorageException(
          'Unexpected response shape: ${data.runtimeType}',
        );
      }
      return OAuthCallbackResult.fromJson(data);
    } on OAuthStorageException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('oauth-callback invoke failed: $e');
      }
      throw OAuthStorageException('Failed to persist OAuth token', e);
    }
  }

  /// Phase 2a (2026-05-27) — direct Google OAuth side-channel.
  ///
  /// Bypasses Supabase Auth's signInWithOAuth (which silently drops
  /// access_type=offline + prompt=consent and yields a refresh_token-less
  /// session). Instead we call our own `gmail-oauth-init` edge fn, which
  /// builds the Google authorize URL with the right params + a signed
  /// state JWT, and returns it.
  ///
  /// Caller (`email_screen.dart::connectGmail`) then opens the URL in a
  /// browser. Google redirects to `https://advocat.ee/oauth/gmail/return`
  /// which is a Flutter route that reads `?code=&state=` and calls
  /// [exchangeGmailCode] below.
  Future<GmailOAuthInitResult> initGmailOAuth() async {
    try {
      final response = await _client.functions.invoke(
        'gmail-oauth-init',
        body: const <String, dynamic>{},
      );
      if (response.status >= 400) {
        final data = response.data;
        final errMsg = data is Map ? (data['error']?.toString()) : null;
        throw OAuthStorageException(
          errMsg ?? 'gmail-oauth-init returned ${response.status}',
        );
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw OAuthStorageException(
          'Unexpected init response shape: ${data.runtimeType}',
        );
      }
      final authUrl = data['auth_url'] as String?;
      final state = data['state'] as String?;
      if (authUrl == null || state == null) {
        throw const OAuthStorageException(
          'gmail-oauth-init missing auth_url or state',
        );
      }
      return GmailOAuthInitResult(authUrl: authUrl, state: state);
    } on OAuthStorageException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('gmail-oauth-init invoke failed: $e');
      }
      throw OAuthStorageException('Failed to init Gmail OAuth', e);
    }
  }

  /// Phase 2a (2026-05-27) — finish the side-channel OAuth flow.
  ///
  /// After Google redirects with `?code=` + `?state=`, the Flutter return
  /// route calls this. The edge fn `gmail-oauth-exchange` verifies the
  /// state JWT (we never trust the body's user_id), exchanges the code at
  /// Google's token endpoint, and upserts `user_oauth_tokens` with a real
  /// refresh_token.
  ///
  /// Returns the same [OAuthCallbackResult] shape so the UI doesn't need
  /// to branch on which flow produced it.
  Future<OAuthCallbackResult> exchangeGmailCode({
    required String code,
    required String state,
  }) async {
    if (code.isEmpty) {
      throw const OAuthStorageException('code must not be empty');
    }
    if (state.isEmpty) {
      throw const OAuthStorageException('state must not be empty');
    }
    try {
      final response = await _client.functions.invoke(
        'gmail-oauth-exchange',
        body: <String, dynamic>{'code': code, 'state': state},
      );
      if (response.status >= 400) {
        final data = response.data;
        final errMsg = data is Map ? (data['error']?.toString()) : null;
        throw OAuthStorageException(
          errMsg ?? 'gmail-oauth-exchange returned ${response.status}',
        );
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw OAuthStorageException(
          'Unexpected exchange response shape: ${data.runtimeType}',
        );
      }
      return OAuthCallbackResult.fromJson(data);
    } on OAuthStorageException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('gmail-oauth-exchange invoke failed: $e');
      }
      throw OAuthStorageException('Failed to exchange Gmail OAuth code', e);
    }
  }
}

/// Result of `gmail-oauth-init`. The UI opens [authUrl] in a browser; the
/// server bound [state] inside a signed JWT so a malicious redirect cannot
/// inject another user's identity.
class GmailOAuthInitResult {
  const GmailOAuthInitResult({required this.authUrl, required this.state});
  final String authUrl;
  final String state;
}
