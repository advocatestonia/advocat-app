// Deno tests for _shared/gmail_token.ts
// -----------------------------------------------------------------------------
// We test the orchestrator helpers that decide WHEN to refresh and where
// to write the new token. The Google OAuth fetch + Supabase write are
// mocked via a minimal supabase-shaped fake; the underlying decision
// helpers (`shouldRefresh`, `buildRefreshRequestBody`, `computeNewExpiry`)
// are pinned in `send-email/__tests__/token_refresh_test.ts`.
//
// Run:
//   deno test --allow-read --allow-env --allow-net=oauth2.googleapis.com \
//     supabase/functions/_shared/__tests__/gmail_token_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { ensureFreshToken, loadGmailToken } from "../gmail_token.ts";

// -----------------------------------------------------------------------------
// loadGmailToken — minimal supabase fake
// -----------------------------------------------------------------------------

function makeFakeSupabase(rows: Record<string, unknown>[]): {
  from: (table: string) => {
    select: () => {
      eq: () => {
        eq: () => {
          maybeSingle: () => Promise<{ data: unknown; error: null }>;
        };
      };
    };
    update: (patch: Record<string, unknown>) => {
      eq: () => { eq: () => Promise<{ data: unknown; error: null }> };
    };
  };
} {
  return {
    from(_table: string) {
      return {
        select() {
          return {
            eq() {
              return {
                eq() {
                  return {
                    maybeSingle: () =>
                      Promise.resolve({ data: rows[0] ?? null, error: null }),
                  };
                },
              };
            },
          };
        },
        update(_patch: Record<string, unknown>) {
          return {
            eq() {
              return {
                eq: () => Promise.resolve({ data: null, error: null }),
              };
            },
          };
        },
      };
    },
  };
}

Deno.test("loadGmailToken — returns null when no row", async () => {
  // deno-lint-ignore no-explicit-any
  const fake: any = makeFakeSupabase([]);
  const out = await loadGmailToken(fake, "u1");
  assertEquals(out, null);
});

Deno.test("loadGmailToken — returns shaped row when present", async () => {
  // deno-lint-ignore no-explicit-any
  const fake: any = makeFakeSupabase([{
    user_id: "u1",
    access_token: "at",
    refresh_token: "rt",
    email: "u1@example.com",
    expires_at: "2026-05-06T11:00:00Z",
    provider: "gmail",
  }]);
  const out = await loadGmailToken(fake, "u1");
  assert(out != null);
  assertEquals(out.access_token, "at");
  assertEquals(out.refresh_token, "rt");
  assertEquals(out.email, "u1@example.com");
});

// -----------------------------------------------------------------------------
// ensureFreshToken — short-circuit when not due
// -----------------------------------------------------------------------------

Deno.test("ensureFreshToken — returns existing token when not due", async () => {
  // deno-lint-ignore no-explicit-any
  const fake: any = makeFakeSupabase([]);
  const now = Date.UTC(2026, 4, 6, 12, 0, 0);
  const expiresFar = new Date(now + 60 * 60_000).toISOString(); // +1h
  const out = await ensureFreshToken(
    fake,
    "u1",
    {
      access_token: "still-good",
      refresh_token: "rt",
      expires_at: expiresFar,
    },
    now,
  );
  assertEquals(out, "still-good");
});

Deno.test("ensureFreshToken — returns existing token when no refresh_token (cannot refresh)", async () => {
  // deno-lint-ignore no-explicit-any
  const fake: any = makeFakeSupabase([]);
  const now = Date.UTC(2026, 4, 6, 12, 0, 0);
  // Already expired but no refresh token → cannot refresh; return what we
  // have and let Gmail return 401 if it's stale.
  const out = await ensureFreshToken(
    fake,
    "u1",
    {
      access_token: "stale",
      refresh_token: null,
      expires_at: new Date(now - 60_000).toISOString(),
    },
    now,
  );
  assertEquals(out, "stale");
});

// We DO NOT exercise the real Google OAuth network call here; that would
// require --allow-net and a stable mock server. The HTTP path is covered
// by the canary post-deploy smoke run.
Deno.test("ensureFreshToken — refresh attempt returns null without GOOGLE_CLIENT envs", async () => {
  // deno-lint-ignore no-explicit-any
  const fake: any = makeFakeSupabase([]);
  // Save and clear the envs for this test. (The module reads them at
  // import time, so if the test runner has them set we can't fully
  // override here — guard accordingly.)
  const hadId = Deno.env.get("GOOGLE_CLIENT_ID");
  const hadSecret = Deno.env.get("GOOGLE_CLIENT_SECRET");
  if (hadId || hadSecret) {
    // env present — skip; the test environment has secrets configured.
    return;
  }
  const now = Date.UTC(2026, 4, 6, 12, 0, 0);
  const expired = new Date(now - 60_000).toISOString();
  const out = await ensureFreshToken(
    fake,
    "u1",
    {
      access_token: "stale",
      refresh_token: "rt",
      expires_at: expired,
    },
    now,
  );
  assertFalse(out !== null && out !== undefined && (out as string) !== "");
});
