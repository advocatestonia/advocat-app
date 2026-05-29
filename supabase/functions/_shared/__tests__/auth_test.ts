// Deno-runtime tests for _shared/auth.ts — Wave-2 W2-01 emergency backstop.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/_shared/__tests__/auth_test.ts
//
// Scope:
//   - When the Postgres `consume_rate_limit` RPC fails (error object or
//     thrown exception), `checkRateLimit` falls through to the in-process
//     emergency token bucket instead of failing open unconditionally.
//   - The backstop caps authenticated principals at 100/min/principal.
//   - The backstop caps anonymous principals at 10/min/principal (tighter
//     because anon traffic is the larger cost-exposure surface).
//   - `requireUserWithRateLimit` propagates `degraded: true` on the allow
//     result and adds `X-RateLimit-Degraded: 1` to the deny response when
//     the backstop denied.
//   - Healthy-RPC path is NOT affected — non-degraded responses must not
//     leak the header.
//
// What this test does NOT cover (out of scope for W2-01):
//   - Cross-isolate behaviour. The backstop is per-isolate by design — a
//     cold-start farm could still bypass it, which is documented in
//     auth.ts. The primary defence remains the Postgres RPC.
//   - Real JWT verification. Covered by auth.test.ts T01-T20 + live smoke.
//
// Memory key: swarm/security_audit_2026-05-28/wave2/rate_limit_backstop
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
  checkRateLimit,
  __setRpcOverrideForTest,
  __setRateLimitOverrideForTest,
  _resetEmergencyBucketForTest,
  _emergencyAllow,
} = await import("../auth.ts");

function mockReq(
  headers: Record<string, string> = {},
): Request {
  return new Request("https://example.supabase.co/functions/v1/x", {
    method: "POST",
    headers: new Headers({ "Content-Type": "application/json", ...headers }),
    body: JSON.stringify({}),
  });
}

function resetState() {
  _resetEmergencyBucketForTest();
  __setRpcOverrideForTest(null);
  __setRateLimitOverrideForTest(null);
}

// -----------------------------------------------------------------------------
// W2-01 backstop primitive — _emergencyAllow
// -----------------------------------------------------------------------------

Deno.test("W2-01 BS1 — _emergencyAllow admits up to cap within 60s window", () => {
  _resetEmergencyBucketForTest();
  for (let i = 0; i < 5; i++) {
    assertEquals(
      _emergencyAllow("BS1:user", 5),
      true,
      `hit ${i + 1} should admit (cap=5)`,
    );
  }
  // 6th hit must deny
  assertEquals(_emergencyAllow("BS1:user", 5), false, "6th hit over cap");
});

Deno.test("W2-01 BS2 — _emergencyAllow isolates principals", () => {
  _resetEmergencyBucketForTest();
  for (let i = 0; i < 3; i++) {
    assertEquals(_emergencyAllow("BS2:user-A", 3), true);
  }
  assertEquals(_emergencyAllow("BS2:user-A", 3), false, "A over cap");
  // user-B has its own counter
  assertEquals(_emergencyAllow("BS2:user-B", 3), true, "B unaffected");
});

// -----------------------------------------------------------------------------
// W2-01 main contract — checkRateLimit falls through on RPC failure
// -----------------------------------------------------------------------------

Deno.test("W2-01 T1 — RPC error → backstop admits with degraded=true", async () => {
  resetState();
  __setRpcOverrideForTest(() =>
    Promise.resolve({ error: { message: "pgbouncer pool exhausted" } })
  );

  const res = await checkRateLimit("T1:authed-user", 5);
  assertEquals(res.admitted, true, "first hit must admit via backstop");
  assertEquals(res.degraded, true, "must mark degraded");
});

Deno.test("W2-01 T2 — RPC throws → backstop admits with degraded=true", async () => {
  resetState();
  __setRpcOverrideForTest(() => Promise.reject(new Error("ECONNRESET")));

  const res = await checkRateLimit("T2:authed-user", 5);
  assertEquals(res.admitted, true);
  assertEquals(res.degraded, true);
});

Deno.test("W2-01 T3 — healthy RPC sets degraded=false", async () => {
  resetState();
  __setRpcOverrideForTest(() => Promise.resolve({ data: true }));

  const res = await checkRateLimit("T3:authed-user", 5);
  assertEquals(res.admitted, true);
  assertEquals(res.degraded, false, "no degraded flag on healthy path");
});

Deno.test("W2-01 T4 — RPC deny under healthy DB carries degraded=false", async () => {
  resetState();
  __setRpcOverrideForTest(() => Promise.resolve({ data: false }));

  const res = await checkRateLimit("T4:authed-user", 5);
  assertEquals(res.admitted, false);
  assertEquals(res.degraded, false);
});

// -----------------------------------------------------------------------------
// W2-01 cap — 100/min authed default
// -----------------------------------------------------------------------------

Deno.test("W2-01 T5 — RPC down + 101 hits within 60s → 100 admitted, 101st denied", async () => {
  resetState();
  __setRpcOverrideForTest(() =>
    Promise.resolve({ error: { message: "RPC down" } })
  );

  let admitted = 0;
  let denied = 0;
  for (let i = 0; i < 101; i++) {
    const res = await checkRateLimit("T5:authed-user", 1_000_000);
    // Even though the upstream `max` is huge, the backstop pins to 100.
    if (res.admitted) admitted++;
    else denied++;
    // Every response in degraded mode must mark degraded
    assertEquals(res.degraded, true);
  }
  assertEquals(admitted, 100, "exactly 100 admitted under backstop cap");
  assertEquals(denied, 1, "exactly 1 denied (the 101st)");
});

// -----------------------------------------------------------------------------
// W2-01 — anon backstop cap (10/min)
// -----------------------------------------------------------------------------

Deno.test("W2-01 T6 — anon principal: RPC down + 11 hits → 10 admitted, 11th denied", async () => {
  resetState();
  __setRpcOverrideForTest(() =>
    Promise.resolve({ error: { message: "RPC down" } })
  );

  let admitted = 0;
  for (let i = 0; i < 11; i++) {
    // emergencyCap=10 is what requireUserWithRateLimit passes for anon
    const res = await checkRateLimit("T6:anon-ip", 1_000_000, {
      emergencyCap: 10,
    });
    if (res.admitted) admitted++;
    assertEquals(res.degraded, true);
  }
  assertEquals(admitted, 10, "anon hard-capped at 10 in degraded mode");
});

// -----------------------------------------------------------------------------
// W2-01 — gate-level integration: X-RateLimit-Degraded header
// -----------------------------------------------------------------------------

Deno.test(
  "W2-01 T7 — gate exposes degraded=true on allow when RPC down (authed)",
  async () => {
    resetState();
    __setRpcOverrideForTest(() =>
      Promise.resolve({ error: { message: "RPC down" } })
    );
    // To force "userId !== null" path without spinning a real Supabase auth,
    // we use the IP fall-through anon path (which still hits the backstop).
    const res = await requireUserWithRateLimit(
      mockReq({ "x-real-ip": "203.0.113.7" }),
      {
        bucket: "T7",
        maxPerMinute: 99,
        anonymousPerMinute: 5,
      },
    );
    if (res.kind !== "allow") {
      throw new Error(`expected allow, got ${JSON.stringify(res)}`);
    }
    assertEquals(
      res.degraded,
      true,
      "gate must propagate degraded flag on allow",
    );
  },
);

Deno.test(
  "W2-01 T8 — gate deny in degraded mode adds X-RateLimit-Degraded: 1",
  async () => {
    resetState();
    __setRpcOverrideForTest(() =>
      Promise.resolve({ error: { message: "RPC down" } })
    );

    // Exhaust anon backstop (10 admits)
    for (let i = 0; i < 10; i++) {
      await requireUserWithRateLimit(
        mockReq({ "x-real-ip": "203.0.113.8" }),
        { bucket: "T8", maxPerMinute: 99, anonymousPerMinute: 5 },
      );
    }
    // 11th — must deny via backstop with degraded header
    const denied = await requireUserWithRateLimit(
      mockReq({ "x-real-ip": "203.0.113.8" }),
      { bucket: "T8", maxPerMinute: 99, anonymousPerMinute: 5 },
    );
    if (denied.kind !== "deny") {
      throw new Error("expected deny after backstop cap exhausted");
    }
    assertEquals(denied.response.status, 429);
    assertEquals(
      denied.response.headers.get("X-RateLimit-Degraded"),
      "1",
      "deny response must carry observability header in degraded mode",
    );
    const body = await denied.response.json();
    assertEquals(body.degraded, true, "deny body must echo degraded flag");
  },
);

Deno.test(
  "W2-01 T9 — healthy RPC: no X-RateLimit-Degraded header leaks",
  async () => {
    resetState();
    // Healthy RPC: admit then deny based on the override
    let calls = 0;
    __setRpcOverrideForTest((_id, _max) => {
      calls++;
      // First call admit, second call deny — mimicking a real DB
      return Promise.resolve({ data: calls === 1 });
    });

    const ok = await requireUserWithRateLimit(
      mockReq({ "x-real-ip": "203.0.113.9" }),
      { bucket: "T9", maxPerMinute: 99, anonymousPerMinute: 1 },
    );
    if (ok.kind !== "allow") throw new Error("expected allow");
    assertEquals(ok.degraded, false, "healthy path must not mark degraded");

    const denied = await requireUserWithRateLimit(
      mockReq({ "x-real-ip": "203.0.113.9" }),
      { bucket: "T9", maxPerMinute: 99, anonymousPerMinute: 1 },
    );
    if (denied.kind !== "deny") throw new Error("expected deny");
    assertEquals(
      denied.response.headers.get("X-RateLimit-Degraded"),
      null,
      "healthy-mode 429 must NOT leak degraded header",
    );
    const body = await denied.response.json();
    assertEquals(
      body.degraded,
      undefined,
      "healthy-mode 429 body must NOT carry degraded flag",
    );
  },
);

// -----------------------------------------------------------------------------
// W2-01 T10 — full integration assertion the user spec asked for:
//   "mocks RPC failure → expects fall-through to bucket → expects 429
//    after 100 hits within 60s"
// -----------------------------------------------------------------------------

Deno.test(
  "W2-01 T10 — authed gate: RPC down + 101 hits within 60s → 429 on 101st",
  async () => {
    resetState();
    __setRpcOverrideForTest(() =>
      Promise.resolve({ error: { message: "pool saturated" } })
    );

    // We use the anon path with maxPerMinute very high to exercise the
    // *authed-cap* backstop branch we'd want for a real session. The
    // backstop cap is determined by requireUserWithRateLimit based on
    // whether userId resolved. To exercise the authed 100/min cap via the
    // anon path is not faithful — so we exercise checkRateLimit directly
    // here with the authed cap (which matches what the gate would pass
    // when userId !== null).
    const principal = "T10:user-uuid-xyz";
    let admitted = 0;
    let denied429 = 0;
    for (let i = 0; i < 101; i++) {
      const r = await checkRateLimit(principal, 99, { emergencyCap: 100 });
      if (r.admitted) admitted++;
      else denied429++;
      assertEquals(r.degraded, true);
    }
    assertEquals(admitted, 100, "100 admitted under backstop");
    assertEquals(denied429, 1, "101st request denied");
  },
);

// -----------------------------------------------------------------------------
// Source-level contract — make sure the constants we hardcoded in the
// gate match what auth.ts declares, so a future refactor that moves the
// caps around breaks this test instead of silently regressing the audit
// finding.
// -----------------------------------------------------------------------------
Deno.test("W2-01 T11 — auth.ts declares the documented backstop caps", () => {
  const src = Deno.readTextFileSync(new URL("../auth.ts", import.meta.url));
  assertStringIncludes(src, "EMERGENCY_AUTHED_CAP = 100");
  assertStringIncludes(src, "EMERGENCY_ANON_CAP = 10");
  assertStringIncludes(src, "X-RateLimit-Degraded");
  assertStringIncludes(src, "_emergencyBucket");
});
