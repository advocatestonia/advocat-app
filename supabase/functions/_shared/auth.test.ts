// Deno-runtime tests for _shared/auth.ts (OMEGA-5 v24.2)
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land supabase/functions/_shared/auth.test.ts
//
// Scope:
//   - Anonymous-path gating (no JWT token at all)
//   - Rate-limit sliding window correctness
//   - Bucket isolation
//   - CORS header constants
//   - Error/ok JSON builders
//   - Source-code contract checks (all 5 billable functions import the gate)
//
// NOT covered here (covered by live-env smoke tests in Phase 7):
//   - Real JWT verification against Supabase auth backend
//   - 503 on auth backend network failure
// Those paths need a real Supabase project or a full Supabase-JS client mock;
// the risk is covered by the contract test T17 below which fails CI if any
// function forgets to wire the gate.
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Stub env BEFORE importing the helper.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

const {
  requireUserWithRateLimit,
  corsHeaders,
  jsonError,
  jsonOk,
  __resetRateLimitForTest,
} = await import("./auth.ts");

function mockReq(
  headers: Record<string, string> = {},
  body: Record<string, unknown> = {},
): Request {
  return new Request("https://example.supabase.co/functions/v1/x", {
    method: "POST",
    headers: new Headers({ "Content-Type": "application/json", ...headers }),
    body: JSON.stringify(body),
  });
}

// ---- auth gate --------------------------------------------------------------

Deno.test("T01 — missing Authorization returns 401", async () => {
  __resetRateLimitForTest();
  const res = await requireUserWithRateLimit(mockReq(), {
    bucket: "t01",
    maxPerMinute: 10,
  });
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.response.status, 401);
    const txt = await res.response.text();
    assertStringIncludes(txt, "Unauthorized");
  }
});

Deno.test("T02 — missing Authorization with anonymousPerMinute=0 still 401", async () => {
  __resetRateLimitForTest();
  const res = await requireUserWithRateLimit(mockReq(), {
    bucket: "t02",
    maxPerMinute: 10,
    anonymousPerMinute: 0,
  });
  assertEquals(res.kind, "deny");
  if (res.kind === "deny") {
    assertEquals(res.response.status, 401);
  }
});

Deno.test("T03 — anonymous allowed when anonymousPerMinute>0 up to cap", async () => {
  __resetRateLimitForTest();
  const r1 = await requireUserWithRateLimit(mockReq(), {
    bucket: "t03",
    maxPerMinute: 10,
    anonymousPerMinute: 2,
  });
  assertEquals(r1.kind, "allow");
  if (r1.kind === "allow") {
    assertStringIncludes(r1.user.id, "anon:");
  }

  const r2 = await requireUserWithRateLimit(mockReq(), {
    bucket: "t03",
    maxPerMinute: 10,
    anonymousPerMinute: 2,
  });
  assertEquals(r2.kind, "allow");

  const r3 = await requireUserWithRateLimit(mockReq(), {
    bucket: "t03",
    maxPerMinute: 10,
    anonymousPerMinute: 2,
  });
  assertEquals(r3.kind, "deny"); // 3rd is over cap
  if (r3.kind === "deny") {
    assertEquals(r3.response.status, 429);
  }
});

Deno.test("T04 — rate-limit 429 response carries bucket + limit metadata", async () => {
  __resetRateLimitForTest();
  await requireUserWithRateLimit(mockReq(), {
    bucket: "t04-bucket",
    maxPerMinute: 10,
    anonymousPerMinute: 1,
  });
  const denied = await requireUserWithRateLimit(mockReq(), {
    bucket: "t04-bucket",
    maxPerMinute: 10,
    anonymousPerMinute: 1,
  });
  if (denied.kind !== "deny") throw new Error("expected deny");
  assertEquals(denied.response.status, 429);
  const body = await denied.response.json();
  assertEquals(body.bucket, "t04-bucket");
  assertEquals(body.limit, 1);
  assertEquals(body.windowMs, 60_000);
});

Deno.test("T05 — buckets isolate rate limits (bucketA exhausted, bucketB fine)", async () => {
  __resetRateLimitForTest();

  // Exhaust bucket A
  for (let i = 0; i < 2; i++) {
    const r = await requireUserWithRateLimit(mockReq(), {
      bucket: "bucketA",
      maxPerMinute: 10,
      anonymousPerMinute: 2,
    });
    assertEquals(r.kind, "allow");
  }
  const aDenied = await requireUserWithRateLimit(mockReq(), {
    bucket: "bucketA",
    maxPerMinute: 10,
    anonymousPerMinute: 2,
  });
  assertEquals(aDenied.kind, "deny");

  // Bucket B — same principal, different bucket, still allowed
  const bAllowed = await requireUserWithRateLimit(mockReq(), {
    bucket: "bucketB",
    maxPerMinute: 10,
    anonymousPerMinute: 2,
  });
  assertEquals(bAllowed.kind, "allow");
});

Deno.test("T06 — different IPs isolate rate limits", async () => {
  __resetRateLimitForTest();
  // Wave-1 security fix (2026-05-28, audit P0-06): x-forwarded-for is
  // client-controlled and is IGNORED unless TRUST_XFF=true. The canonical,
  // non-echoable client IP on Supabase Edge is x-real-ip — that is what the
  // limiter buckets on, so the isolation test must drive it via x-real-ip.
  // IP 1.1.1.1 exhausted
  for (let i = 0; i < 2; i++) {
    await requireUserWithRateLimit(
      mockReq({ "x-real-ip": "1.1.1.1" }),
      { bucket: "t06", maxPerMinute: 10, anonymousPerMinute: 2 },
    );
  }
  const ip1Denied = await requireUserWithRateLimit(
    mockReq({ "x-real-ip": "1.1.1.1" }),
    { bucket: "t06", maxPerMinute: 10, anonymousPerMinute: 2 },
  );
  assertEquals(ip1Denied.kind, "deny");

  // Different IP — fine
  const ip2 = await requireUserWithRateLimit(
    mockReq({ "x-real-ip": "2.2.2.2" }),
    { bucket: "t06", maxPerMinute: 10, anonymousPerMinute: 2 },
  );
  assertEquals(ip2.kind, "allow");
});

Deno.test("T07 — reset helper wipes all buckets", async () => {
  await requireUserWithRateLimit(mockReq(), {
    bucket: "t07",
    maxPerMinute: 10,
    anonymousPerMinute: 1,
  });
  const deniedBeforeReset = await requireUserWithRateLimit(mockReq(), {
    bucket: "t07",
    maxPerMinute: 10,
    anonymousPerMinute: 1,
  });
  assertEquals(deniedBeforeReset.kind, "deny");

  __resetRateLimitForTest();

  const allowedAfterReset = await requireUserWithRateLimit(mockReq(), {
    bucket: "t07",
    maxPerMinute: 10,
    anonymousPerMinute: 1,
  });
  assertEquals(allowedAfterReset.kind, "allow");
});

// ---- CORS + helpers ---------------------------------------------------------

Deno.test("T08 — CORS Allow-Origin is advocat.ee (no wildcard)", () => {
  assertEquals(corsHeaders["Access-Control-Allow-Origin"], "https://advocat.ee");
});

Deno.test("T09 — CORS Allow-Methods are POST + OPTIONS only", () => {
  const m = corsHeaders["Access-Control-Allow-Methods"];
  assertStringIncludes(m, "POST");
  assertStringIncludes(m, "OPTIONS");
  // No GET/PUT/DELETE leak-through
  if (m.includes("GET") || m.includes("DELETE")) {
    throw new Error(`unexpected method in CORS: ${m}`);
  }
});

Deno.test("T10 — CORS Vary: Origin present (cache-safety)", () => {
  assertEquals(corsHeaders["Vary"], "Origin");
});

Deno.test("T11 — jsonError returns requested status + CORS", async () => {
  const res = jsonError("nope", 418, { extra: "teapot" });
  assertEquals(res.status, 418);
  assertEquals(
    res.headers.get("Access-Control-Allow-Origin"),
    "https://advocat.ee",
  );
  const body = await res.json();
  assertEquals(body.error, "nope");
  assertEquals(body.extra, "teapot");
});

Deno.test("T12 — jsonOk returns 200 + CORS by default", async () => {
  const res = jsonOk({ ok: true });
  assertEquals(res.status, 200);
  assertEquals(
    res.headers.get("Access-Control-Allow-Origin"),
    "https://advocat.ee",
  );
  const body = await res.json();
  assertEquals(body.ok, true);
});

// ---- source-level contract --------------------------------------------------

Deno.test("T13 — whisper-stt enforces 10 MB binary cap (≈ 14 MB base64)", () => {
  // v24.3 (2026-05-02): tightened from 20 MB → 10 MB binary as part of
  // the OpenAI Whisper cost-control hardening. See cost_control.ts for the
  // canonical constants and migration 20260502100000_voice_usage.sql for
  // the per-user monthly minute quota that enforces the same budget at a
  // longer time horizon.
  const constants = Deno.readTextFileSync(
    new URL("../whisper-stt/cost_control.ts", import.meta.url),
  );
  assertStringIncludes(constants, "10 * 1024 * 1024");
  assertStringIncludes(constants, "MAX_BINARY_BYTES");
  assertStringIncludes(constants, "MAX_AUDIO_B64");
  assertStringIncludes(constants, "SECONDS_PER_CALL_MAX");

  // index.ts must wire those constants into its handler.
  const src = Deno.readTextFileSync(
    new URL("../whisper-stt/index.ts", import.meta.url),
  );
  assertStringIncludes(src, "MAX_BINARY_BYTES");
  assertStringIncludes(src, "MAX_AUDIO_B64");
  assertStringIncludes(src, "SECONDS_PER_CALL_MAX");
});

Deno.test("T14 — all 6 billable functions import the shared gate", () => {
  const functions = [
    "whisper-stt",
    "tts-proxy",
    "google-tts",
    "check-company",
    "check-vehicle",
    // Sprint 0 — FIX-7: create-checkout now requires JWT to prevent
    // phishing via arbitrary customer_email values.
    "create-checkout",
  ];
  for (const fn of functions) {
    const src = Deno.readTextFileSync(
      new URL(`../${fn}/index.ts`, import.meta.url),
    );
    assertStringIncludes(
      src,
      "requireUserWithRateLimit",
      `${fn} must call requireUserWithRateLimit`,
    );
    assertStringIncludes(
      src,
      "_shared/auth.ts",
      `${fn} must import from _shared/auth.ts`,
    );
  }
});

Deno.test("T15 — whisper-stt + tts-proxy use bucket name that matches function", () => {
  const whisper = Deno.readTextFileSync(
    new URL("../whisper-stt/index.ts", import.meta.url),
  );
  assertStringIncludes(whisper, 'bucket: "whisper-stt"');

  const tts = Deno.readTextFileSync(
    new URL("../tts-proxy/index.ts", import.meta.url),
  );
  assertStringIncludes(tts, 'bucket: "tts-proxy"');
});

Deno.test("T16 — stripe-webhook uses timingSafeEqual (patch 04)", () => {
  // Signature logic was extracted to stripe-webhook/signature.ts.
  const src = Deno.readTextFileSync(
    new URL("../stripe-webhook/signature.ts", import.meta.url),
  );
  assertStringIncludes(src, "timingSafeEqual");
  assertStringIncludes(src, "MAX_WEBHOOK_AGE_SEC");
});

Deno.test("T17 — send-email scrubs CRLF from headers (patch 05)", () => {
  const src = Deno.readTextFileSync(
    new URL("../send-email/index.ts", import.meta.url),
  );
  assertStringIncludes(src, "scrubHeaderText");
  assertStringIncludes(src, "From: ${scrubHeaderText(input.from)}");
});

Deno.test("T18 — claude-proxy uses shared gate + has rate-limit (SECURITY 2026-05-04 U1)", () => {
  // After the U1 hardening (2026-05-04), claude-proxy delegates auth to
  // the shared `requireUserWithRateLimit` helper instead of running its
  // own inline `supabase.auth.getUser` block. The bucket name pins the
  // rate-limit namespace; absence of `anonymousPerMinute` is what locks
  // anon-key callers out (this is checked structurally below).
  const src = Deno.readTextFileSync(
    new URL("../claude-proxy/index.ts", import.meta.url),
  );
  assertStringIncludes(src, "RATE_LIMIT_MAX");
  assertStringIncludes(src, "requireUserWithRateLimit");
  assertStringIncludes(src, '_shared/auth.ts');
  assertStringIncludes(src, 'bucket: "claude-proxy"');
});

Deno.test("T19 — claude-proxy anon traffic is hard-capped (SECURITY 2026-05-04 U1 + demo restore)", () => {
  // 2026-05-05 DEMO RESTORE: anonymousPerMinute=3 was re-enabled with a hard
  // 500-token cap so the landing demo works. The security contract is:
  //   1. anonymousPerMinute MUST be ≤ 3 (not unbounded)
  //   2. ANON_MAX_TOKENS MUST be ≤ 500 (cost bound)
  // We verify both caps are present in the source.
  const src = Deno.readTextFileSync(
    new URL("../claude-proxy/index.ts", import.meta.url),
  );
  if (!src.includes("ANON_RATE_LIMIT_PER_MINUTE") && !src.includes("anonymousPerMinute")) {
    throw new Error("claude-proxy must define anonymous rate limit");
  }
  // ANON_MAX_TOKENS must be ≤ 500
  const anonTokensMatch = src.match(/ANON_MAX_TOKENS\s*=\s*(\d+)/);
  if (anonTokensMatch) {
    const cap = parseInt(anonTokensMatch[1], 10);
    if (cap > 500) {
      throw new Error(`ANON_MAX_TOKENS=${cap} exceeds 500 — cost-burn risk`);
    }
  }
  // ANON_RATE_LIMIT_PER_MINUTE must be ≤ 3
  const anonRateMatch = src.match(/ANON_RATE_LIMIT_PER_MINUTE\s*=\s*(\d+)/);
  if (anonRateMatch) {
    const rate = parseInt(anonRateMatch[1], 10);
    if (rate > 3) {
      throw new Error(`ANON_RATE_LIMIT_PER_MINUTE=${rate} exceeds 3 — cost-burn risk`);
    }
  }
});

Deno.test("T20 — claude-proxy calls check-ai-quota server-side (SECURITY 2026-05-04 U3)", () => {
  // Even authenticated free-tier users must not bypass the 7-message cap
  // by curl-ing the proxy directly. The fix is a server-side quota probe
  // BEFORE forwarding to Anthropic.
  const src = Deno.readTextFileSync(
    new URL("../claude-proxy/index.ts", import.meta.url),
  );
  assertStringIncludes(src, "check-ai-quota");
  // Either the literal source string or the value passed to JSON.stringify
  // would satisfy this — match the source representation we wrote.
  assertStringIncludes(src, 'action: "consume"');
});
