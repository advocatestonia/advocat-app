// jwt_refresh_test.dart
//
// BUG#3 anti-regression (2026-04-29 pre-launch). The streaming Claude path
// previously took the JWT as it was at `_callApi` start and never refreshed
// it. Sonnet streams can run 30-90s; if the access token's TTL was below
// that, the proxy would 401 mid-stream and the user saw a truncated reply.
//
// The fix is a pre-stream refresh:
//   1. Read `currentSession.expiresAt` (Unix seconds).
//   2. If absent, or if the remaining lifetime is < a safety threshold
//      (default 600s = 10 min), call `auth.refreshSession()` BEFORE we open
//      the SSE pipe.
//   3. Otherwise skip — the overhead would be wasted.
//   4. If the refresh fails, surface a typed exception so the chat layer
//      can route the user to login (no silent truncation).
//
// We test the pure decision logic via `JwtRefreshPolicy.needsRefresh`,
// which is callable without booting Supabase. The integration is exercised
// by `JwtRefreshPolicy.ensureFreshSession` against a tiny mock auth shim.
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/jwt_refresh_policy.dart';

class _FakeSession {
  _FakeSession(this.expiresAt);
  final int? expiresAt; // Unix seconds — null when Supabase didn't populate.
}

class _FakeAuth implements JwtAuthShim {
  _FakeAuth({this.session, this.refreshShouldFail = false});

  _FakeSession? session;
  bool refreshShouldFail;
  int refreshCount = 0;

  @override
  int? get currentSessionExpiresAt => session?.expiresAt;

  @override
  Future<void> refreshSession() async {
    refreshCount++;
    if (refreshShouldFail) {
      throw const JwtRefreshException('refresh failed');
    }
    // Pretend the refresh extended the session by 1 hour.
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    session = _FakeSession(nowSec + 3600);
  }
}

void main() {
  group('JwtRefreshPolicy.needsRefresh — pure decision', () {
    test('null session → needs refresh', () {
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: null,
          nowSec: 1000000,
          minLifetimeSec: 600,
        ),
        isTrue,
      );
    });

    test('expires in 30s → needs refresh', () {
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now + 30,
          nowSec: now,
          minLifetimeSec: 600,
        ),
        isTrue,
      );
    });

    test('expires in 599s → needs refresh (below threshold)', () {
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now + 599,
          nowSec: now,
          minLifetimeSec: 600,
        ),
        isTrue,
      );
    });

    test('expires in 600s → on threshold → needs refresh', () {
      // Strictly less-than-or-equal so a token sitting exactly at the
      // threshold gets refreshed (edge of safety).
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now + 600,
          nowSec: now,
          minLifetimeSec: 600,
        ),
        isTrue,
      );
    });

    test('expires in 601s → no refresh', () {
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now + 601,
          nowSec: now,
          minLifetimeSec: 600,
        ),
        isFalse,
      );
    });

    test('expires in 1 hour → no refresh', () {
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now + 3600,
          nowSec: now,
          minLifetimeSec: 600,
        ),
        isFalse,
      );
    });

    test('already expired → needs refresh (negative lifetime)', () {
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now - 100,
          nowSec: now,
          minLifetimeSec: 600,
        ),
        isTrue,
      );
    });
  });

  group('JwtRefreshPolicy.ensureFreshSession — integration with mock auth', () {
    test('expires_in < 600s → refreshSession called once', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final auth = _FakeAuth(session: _FakeSession(nowSec + 120));

      await JwtRefreshPolicy.ensureFreshSession(auth: auth);

      expect(auth.refreshCount, 1);
      // Session got the +1h bump.
      expect(auth.session!.expiresAt! - nowSec, greaterThan(3000));
    });

    test('expires_in > 3600s → refreshSession NOT called', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final auth = _FakeAuth(session: _FakeSession(nowSec + 7200));

      await JwtRefreshPolicy.ensureFreshSession(auth: auth);

      expect(auth.refreshCount, 0,
          reason: 'No refresh when token has plenty of TTL left');
    });

    test('null session → refreshSession called once', () async {
      final auth = _FakeAuth(session: null);

      await JwtRefreshPolicy.ensureFreshSession(auth: auth);

      expect(auth.refreshCount, 1);
    });

    test('refresh failure surfaces typed exception', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final auth = _FakeAuth(
        session: _FakeSession(nowSec + 60),
        refreshShouldFail: true,
      );

      await expectLater(
        JwtRefreshPolicy.ensureFreshSession(auth: auth),
        throwsA(isA<JwtRefreshException>()),
      );
      expect(auth.refreshCount, 1);
    });

    test('custom minLifetimeSec=300 honoured', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Token has 400s left — above 300s custom threshold, no refresh.
      final auth = _FakeAuth(session: _FakeSession(nowSec + 400));

      await JwtRefreshPolicy.ensureFreshSession(
        auth: auth,
        minLifetimeSec: 300,
      );

      expect(auth.refreshCount, 0);
    });
  });
}
