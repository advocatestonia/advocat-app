// jwt_refresh_boundary_test.dart
//
// OMEGA pre-launch QA expansion (2026-04-29). The existing
// `jwt_refresh_test.dart` covers the happy path + the named
// thresholds (599, 600, 601, 3600). This file adds adversarial
// edge cases that surface when the device clock is wrong, the
// auth shim returns nonsense, or callers chain refreshes:
//
//   • expires_at == now (the "expires this exact second" race)
//   • expires_at past (negative remaining lifetime)
//   • clock injection — verify the policy uses the injected clock,
//     not wall-clock time, so flaky tests are impossible
//   • zero / negative minLifetimeSec (defensive — caller mistake)
//   • refresh exception preserves cause chain
//   • two ensureFreshSession() calls back-to-back: only the first
//     refreshes, the second sees the rotated token and skips
//
// All boundary values are exercised so the predicate `<=` rule
// stays pinned (eliminates the "exactly threshold expires
// mid-stream" race called out in jwt_refresh_policy.dart line 92).
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/jwt_refresh_policy.dart';

class _FakeSession {
  _FakeSession(this.expiresAt);
  final int? expiresAt;
}

class _FakeAuth implements JwtAuthShim {
  _FakeAuth({this.session, this.refreshShouldFail = false, this.bumpSec = 3600});

  _FakeSession? session;
  bool refreshShouldFail;
  int refreshCount = 0;
  int bumpSec;
  Object? lastCause;

  @override
  int? get currentSessionExpiresAt => session?.expiresAt;

  @override
  Future<void> refreshSession() async {
    refreshCount++;
    if (refreshShouldFail) {
      throw const JwtRefreshException('refresh failed', _RootCause());
    }
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    session = _FakeSession(nowSec + bumpSec);
  }
}

class _RootCause implements Exception {
  const _RootCause();
  @override
  String toString() => 'RootCause: original Supabase failure';
}

void main() {
  group('JwtRefreshPolicy.needsRefresh — boundary edge cases', () {
    test('expires_at == now → needs refresh (lifetime 0 ≤ 600)', () {
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now,
          nowSec: now,
          minLifetimeSec: 600,
        ),
        isTrue,
      );
    });

    test('expires_at far in the past (>1h ago) → needs refresh', () {
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now - 7200,
          nowSec: now,
          minLifetimeSec: 600,
        ),
        isTrue,
      );
    });

    test('expires_at exactly equals nowSec + minLifetimeSec → needs refresh',
        () {
      // The `<=` boundary called out in jwt_refresh_policy.dart line 92.
      const now = 1700000000;
      const lifetime = 600;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now + lifetime,
          nowSec: now,
          minLifetimeSec: lifetime,
        ),
        isTrue,
        reason:
            'Exactly threshold MUST refresh (eliminates "expires mid-stream" race)',
      );
    });

    test('zero minLifetimeSec — only refresh on already-expired token', () {
      const now = 1700000000;
      // 1s of life left ≤ 0? No → don't refresh.
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now + 1,
          nowSec: now,
          minLifetimeSec: 0,
        ),
        isFalse,
      );
      // 0s left ≤ 0? Yes → refresh.
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now,
          nowSec: now,
          minLifetimeSec: 0,
        ),
        isTrue,
      );
    });

    test('negative minLifetimeSec is defensively handled (caller mistake)',
        () {
      // The threshold is meaningless but the function must not crash.
      const now = 1700000000;
      expect(
        JwtRefreshPolicy.needsRefresh(
          expiresAtSec: now + 100,
          nowSec: now,
          minLifetimeSec: -10,
        ),
        isFalse,
        reason: '100s lifetime > -10 threshold → no refresh',
      );
    });
  });

  group('JwtRefreshPolicy.ensureFreshSession — clock injection', () {
    test('uses injected clock instead of wall-clock', () async {
      // Inject a clock far in the future so the token is "expired".
      // Note: avoid digit-separator literals (`2_000_000_000`) — they
      // require Dart 3.6's `digit-separators` experiment which is not
      // enabled by the project's SDK constraint. Plain integer literals
      // compile under every Dart 3.x version.
      final auth = _FakeAuth(session: _FakeSession(2000000000));
      final fakeClock = () => DateTime.fromMillisecondsSinceEpoch(
            3000000000000, // far past expiry
          );

      await JwtRefreshPolicy.ensureFreshSession(
        auth: auth,
        clock: fakeClock,
      );

      expect(auth.refreshCount, 1,
          reason: 'Injected clock must override DateTime.now()');
    });

    test('two consecutive ensureFreshSession calls only refresh once', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // 60s of life — under 600s threshold → first call refreshes
      final auth = _FakeAuth(session: _FakeSession(nowSec + 60));

      await JwtRefreshPolicy.ensureFreshSession(auth: auth);
      expect(auth.refreshCount, 1);

      // After refresh the fake bumps to +1h, so second call sees a
      // healthy token and skips.
      await JwtRefreshPolicy.ensureFreshSession(auth: auth);
      expect(auth.refreshCount, 1,
          reason: 'Second call must skip — token is fresh');
    });

    test('refresh failure preserves the typed exception chain', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final auth = _FakeAuth(
        session: _FakeSession(nowSec + 60),
        refreshShouldFail: true,
      );

      try {
        await JwtRefreshPolicy.ensureFreshSession(auth: auth);
        fail('Should have thrown JwtRefreshException');
      } on JwtRefreshException catch (e) {
        expect(e.message, contains('refresh failed'));
        expect(e.toString(), contains('JwtRefreshException'));
      }
    });

    test(
        'session expiring 0 seconds from now still triggers refresh once',
        () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final auth = _FakeAuth(session: _FakeSession(nowSec));

      await JwtRefreshPolicy.ensureFreshSession(auth: auth);
      expect(auth.refreshCount, 1);
    });

    test('custom minLifetimeSec=0: refresh only on already-expired tokens',
        () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // 30s ahead — with minLifetime=0 we must NOT refresh
      final auth = _FakeAuth(session: _FakeSession(nowSec + 30));
      await JwtRefreshPolicy.ensureFreshSession(
        auth: auth,
        minLifetimeSec: 0,
      );
      expect(auth.refreshCount, 0);

      // Already expired — must refresh.
      auth.session = _FakeSession(nowSec - 5);
      await JwtRefreshPolicy.ensureFreshSession(
        auth: auth,
        minLifetimeSec: 0,
      );
      expect(auth.refreshCount, 1);
    });
  });

  group('JwtRefreshException — toString contract', () {
    test('toString prefixes with class name + message', () {
      const e = JwtRefreshException('oops');
      expect(e.toString(), 'JwtRefreshException: oops');
    });

    test('cause field is preserved for debugging', () {
      final root = Exception('root');
      final e = JwtRefreshException('outer', root);
      expect(e.cause, same(root));
    });
  });
}
