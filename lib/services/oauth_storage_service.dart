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
  });

  /// Currently only 'gmail' is accepted by the Edge Function.
  final String provider;
  final String accessToken;
  final String? refreshToken;
  final String? email;

  /// Lifetime of the access token in seconds (Google returns 3600).
  final int? expiresIn;

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
    return map;
  }
}

/// Result returned by the Edge Function on success.
class OAuthCallbackResult {
  const OAuthCallbackResult({
    required this.ok,
    this.email,
    this.expiresAt,
  });

  final bool ok;
  final String? email;
  final DateTime? expiresAt;

  factory OAuthCallbackResult.fromJson(Map<String, dynamic> json) {
    DateTime? expiresAt;
    final raw = json['expires_at'];
    if (raw is String) {
      expiresAt = DateTime.tryParse(raw);
    }
    return OAuthCallbackResult(
      ok: json['ok'] == true,
      email: json['email'] as String?,
      expiresAt: expiresAt,
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
  Future<OAuthCallbackResult> persistGmailToken({
    required String accessToken,
    String? refreshToken,
    String? email,
    int? expiresInSeconds,
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
}
