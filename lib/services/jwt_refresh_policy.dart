// jwt_refresh_policy.dart
// -----------------------------------------------------------------------------
// BUG#3 fix (2026-04-29 pre-launch). Pre-stream JWT freshness guarantee.
//
// Problem.
//   Sonnet streams can run 30-90 seconds. The client read the access token
//   once at request start; if the token's TTL was below the stream
//   duration, Supabase rotated the JWT mid-stream and the proxy started
//   returning 401, silently truncating the user's reply.
//
// Fix.
//   Before opening any SSE pipe, run [ensureFreshSession]. If the current
//   session expires within `minLifetimeSec` (default 600 = 10 min), call
//   `auth.refreshSession()` so the in-memory client picks up the rotated
//   token before we serialize the request. If the refresh itself fails,
//   throw [JwtRefreshException] so callers can route the user to login
//   instead of letting the chat path swallow the failure.
//
// Architecture.
//   The pure decision lives in [needsRefresh] (callable in tests with no
//   Supabase). The integration sits behind [JwtAuthShim], a 2-method
//   protocol implemented by the production [SupabaseAuthShim] adapter and
//   by mocks in test/services/jwt_refresh_test.dart.
// -----------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when [JwtRefreshPolicy.ensureFreshSession] cannot obtain a
/// usable session. Callers should send the user to login rather than
/// proceeding with a stale or absent token.
class JwtRefreshException implements Exception {
  const JwtRefreshException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => 'JwtRefreshException: $message';
}

/// Minimal seam around `Supabase.instance.client.auth` so the refresh
/// policy is testable without booting Supabase.
abstract class JwtAuthShim {
  /// Unix-second expiry of the current session, or null if no session.
  int? get currentSessionExpiresAt;

  /// Trigger a refresh. Throws [JwtRefreshException] on failure.
  Future<void> refreshSession();
}

/// Production adapter — backs [JwtAuthShim] onto the real Supabase
/// auth client. Kept alongside the policy so the production wiring is
/// trivial:
///
///   await JwtRefreshPolicy.ensureFreshSession(
///     auth: SupabaseAuthShim(),
///   );
class SupabaseAuthShim implements JwtAuthShim {
  SupabaseAuthShim([GoTrueClient? client])
      : _auth = client ?? Supabase.instance.client.auth;

  final GoTrueClient _auth;

  @override
  int? get currentSessionExpiresAt => _auth.currentSession?.expiresAt;

  @override
  Future<void> refreshSession() async {
    try {
      await _auth.refreshSession();
    } catch (e) {
      throw JwtRefreshException(
        'refreshSession() failed — re-login required',
        e,
      );
    }
  }
}

/// Pre-stream JWT refresh policy.
abstract final class JwtRefreshPolicy {
  /// Default safety threshold — refresh if less than this many seconds
  /// of TTL remain. 10 min covers the longest realistic Sonnet stream.
  static const int defaultMinLifetimeSec = 600;

  /// Pure decision: should we refresh?
  ///
  /// Returns true iff:
  ///   • [expiresAtSec] is null (no session at all), OR
  ///   • the remaining lifetime is less than or equal to [minLifetimeSec].
  ///
  /// `<=` (not `<`) so a token sitting exactly at the threshold is
  /// rotated — eliminates the "exactly threshold expires mid-stream" race.
  static bool needsRefresh({
    required int? expiresAtSec,
    required int nowSec,
    int minLifetimeSec = defaultMinLifetimeSec,
  }) {
    if (expiresAtSec == null) return true;
    final remaining = expiresAtSec - nowSec;
    return remaining <= minLifetimeSec;
  }

  /// Ensure the in-memory session has at least [minLifetimeSec] of TTL,
  /// refreshing if necessary. Skips the refresh if the token has plenty
  /// of life left, so the happy path adds zero overhead.
  ///
  /// Throws [JwtRefreshException] if the refresh itself fails so the
  /// caller can surface a re-login prompt instead of silently 401ing
  /// mid-stream.
  static Future<void> ensureFreshSession({
    required JwtAuthShim auth,
    int minLifetimeSec = defaultMinLifetimeSec,
    DateTime Function()? clock,
  }) async {
    final now = (clock ?? DateTime.now)();
    final nowSec = now.millisecondsSinceEpoch ~/ 1000;
    final expiresAtSec = auth.currentSessionExpiresAt;

    if (!needsRefresh(
      expiresAtSec: expiresAtSec,
      nowSec: nowSec,
      minLifetimeSec: minLifetimeSec,
    )) {
      return;
    }

    await auth.refreshSession();
  }
}
