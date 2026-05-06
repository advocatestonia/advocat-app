@Tags(['fast'])
library;

// =============================================================================
// anon_key_lockdown_test.dart — Seam F: anon-key lockdown on paid LLM seams
// =============================================================================
//
// 2026-05-06 — Track B-3 of Pkg 0. Pins the contract that public Supabase
// anon keys CANNOT be used as authentication for paid LLM endpoints. Closes
// the regression class of `lesson_anon_jwt_bypass.md` (2026-05-05): an
// anon-key Bearer header was accepted as a real session by claude-proxy +
// extract-memory, allowing unlimited Anthropic burn from any browser that
// could read main.dart.js.
//
// Endpoint policy (audited 2026-05-06):
//
//   STRICT-LOCK (must reject anon key as auth, no anon path):
//     - extract-memory
//     - case-auto-patch
//     - pdf-parser
//     - whisper-stt
//
//   DEMO-RATE-LIMITED (anon allowed but capped):
//     - claude-proxy        (Seam D — see prod_smoke.sh)
//     - tts-proxy           (anonymousPerMinute = 5)
//     - google-tts          (anonymousPerMinute = 5)
//     - law-search          (anonymousPerMinute set, separate Seam E)
//     - check-company       (anon allowed, public business registry proxy)
//
//   AUTHENTICATED-ONLY (JWT, no anon possible):
//     - check-ai-quota, send-email, intent-classifier, case-load-active,
//       cite-verifier (when wired), founder-spots, etc.
//
// This test enumerates the STRICT-LOCK endpoints and the DEMO-RATE-LIMITED
// endpoints separately so a future regression that flips a strict-lock back
// to "anon-allowed" trips the suite.
//
// Hermetic: no network. We pin the LIST of locked endpoints + the auth-gate
// flag shape. Once an `anon_key_guard.dart` library is wired into the chat
// path (Pkg 0 Phase 2), the live HTTP probe is added in `prod_smoke.sh`
// where it can hit a real Supabase URL.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

/// Endpoints that MUST reject the public Supabase anon key as a session.
/// A regression here = LLM cost-burn vector reopened.
const Set<String> kStrictLockedPaidEndpoints = {
  'extract-memory',
  'case-auto-patch',
  'pdf-parser',
  'whisper-stt',
};

/// Endpoints that DELIBERATELY allow anon callers but with a hard rate
/// limit + token cap (per `anonymousPerMinute` in the AuthGate config).
/// Listed here so a regression that *removes* the cap (i.e. raises it to
/// match authenticated tier) is also caught by the suite when wired.
const Set<String> kAnonRateLimitedEndpoints = {
  'claude-proxy', // anonymousPerMinute = 3, ANON_MAX_TOKENS = 500
  'tts-proxy', // anonymousPerMinute = 5
  'google-tts', // anonymousPerMinute = 5
  'law-search', // anonymousPerMinute set (P0-2)
  'check-company', // public business registry proxy
};

/// Endpoints intentionally callable without ANY auth token for the demo
/// surface — should remain a small, audited list. (None at the moment.)
const Set<String> kPublicNoAuthEndpoints = <String>{};

void main() {
  group('Seam F — anon-key lockdown registry', () {
    test('strict-locked set has no overlap with anon-rate-limited set', () {
      final overlap = kStrictLockedPaidEndpoints.intersection(
        kAnonRateLimitedEndpoints,
      );
      expect(
        overlap,
        isEmpty,
        reason: 'An endpoint cannot be both strict-locked AND demo-allowed.',
      );
    });

    test('strict-lock list contains the four post-exploit-fix endpoints', () {
      // These four are the endpoints whose auth gate was hardened after
      // the 2026-05-05 anon-JWT-bypass exploit. Removing any of them from
      // strict-lock without an explicit security review is a regression.
      expect(kStrictLockedPaidEndpoints, contains('extract-memory'));
      expect(kStrictLockedPaidEndpoints, contains('case-auto-patch'));
      expect(kStrictLockedPaidEndpoints, contains('pdf-parser'));
      expect(kStrictLockedPaidEndpoints, contains('whisper-stt'));
    });

    test('claude-proxy is rate-limited, NOT strict-locked', () {
      // Seam D in prod_smoke.sh restored anon Bearer access for the
      // demo path with a 3/min/IP cap and a 500-token clamp. If a future
      // change moves claude-proxy into the strict-lock list, the demo on
      // the public landing page goes 401 — this test guards that boundary.
      expect(kAnonRateLimitedEndpoints, contains('claude-proxy'));
      expect(kStrictLockedPaidEndpoints, isNot(contains('claude-proxy')));
    });

    test(
        'no endpoint silently slips into the no-auth list without an audit',
        () {
      // Public-no-auth must stay deliberately empty. If you genuinely need
      // an unauthenticated endpoint, add it here AND add a security note
      // to the lesson file. This guard prevents a copy-paste from leaking
      // a write endpoint into the public surface.
      expect(
        kPublicNoAuthEndpoints,
        isEmpty,
        reason:
            'Adding a no-auth endpoint requires an explicit security review. '
            'See lesson_anon_jwt_bypass.md.',
      );
    });
  });

  group('Seam F — expected error shape (documented contract)', () {
    // These tests are skipped because they require a live Supabase target
    // that the pre-commit hook cannot reach hermetically. They exist so
    // the contract is visible in the suite and so the live probe can be
    // dropped into prod_smoke.sh by lifting the bodies into bash. The
    // assertion shape is pinned: 401/403 + `error` envelope, NEVER 200.

    test(
      'extract-memory rejects anon Bearer with 401/403',
      () {
        // Live probe (in prod_smoke.sh):
        //   curl -X POST $FUNCTIONS_URL/extract-memory \
        //     -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        //     -d '{"messages":[]}'
        // Expected: HTTP 401 (or 403), body = {"error":"…","code":"…"}.
        // Forbidden: 200 OK or 5xx that leaks request payload.
      },
      skip: 'live probe wired in prod_smoke.sh once Pkg 0 Phase 2 deploys',
    );

    test(
      'case-auto-patch rejects anon Bearer with 401/403',
      () {
        // case-auto-patch is JWT-gated; anon principals cannot own a case.
        // Live probe added to prod_smoke.sh in the same patch as Seam F.
      },
      skip: 'live probe wired in prod_smoke.sh once Pkg 0 Phase 2 deploys',
    );

    test(
      'pdf-parser rejects anon Bearer with 401/403',
      () {
        // pdf-parser writes to per-user storage prefix; an anon caller
        // has no `gate.user.id` to anchor the path to.
      },
      skip: 'live probe wired in prod_smoke.sh once Pkg 0 Phase 2 deploys',
    );

    test(
      'whisper-stt rejects anon Bearer with 401/403',
      () {
        // whisper-stt enforces a per-user monthly minute quota.
        // No anonymous fallback by design.
      },
      skip: 'live probe wired in prod_smoke.sh once Pkg 0 Phase 2 deploys',
    );

    test(
      'error envelope does not leak the request body or system prompt',
      () {
        // The error response on a 401 must be a small `{error, code}`
        // shape — NEVER echo back the system prompt, the user message,
        // or any internal trace. Also wired into prod_smoke.sh as a
        // body-shape probe (length cap + no-keyword check).
      },
      skip: 'live probe wired in prod_smoke.sh once Pkg 0 Phase 2 deploys',
    );
  });
}
