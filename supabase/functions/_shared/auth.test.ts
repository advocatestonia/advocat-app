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
  // IP 1.1.1.1 exhausted
  for (let i = 0; i < 2; i++) {
    await requireUserWithRateLimit(
      mockReq({ "x-forwarded-for": "1.1.1.1" }),
      { bucket: "t06", maxPerMinute: 10, anonymousPerMinute: 2 },
    );
  }
  const ip1Denied = await requireUserWithRateLimit(
    mockReq({ "x-forwarded-for": "1.1.1.1" }),
    { bucket: "t06", maxPerMinute: 10, anonymousPerMinute: 2 },
  );
  assertEquals(ip1Denied.kind, "deny");

  // Different IP — fine
  const ip2 = await requireUserWithRateLimit(
    mockReq({ "x-forwarded-for": "2.2.2.2" }),
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

Deno.test("T13 — whisper-stt enforces MAX_AUDIO_B64 at 20 MB", () => {
  const src = Deno.readTextFileSync(
    new URL("../whisper-stt/index.ts", import.meta.url),
  );
  assertStringIncludes(src, "20 * 1024 * 1024");
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
  const src = Deno.readTextFileSync(
    new URL("../stripe-webhook/index.ts", import.meta.url),
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

Deno.test("T18 — claude-proxy still has user rate-limit (not regressed)", () => {
  const src = Deno.readTextFileSync(
    new URL("../claude-proxy/index.ts", import.meta.url),
  );
  assertStringIncludes(src, "RATE_LIMIT_MAX");
  assertStringIncludes(src, "supabase.auth.getUser");
});
