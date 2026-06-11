// Deno tests for tier_resolver — server-side plan-tier lookup (Wave-1,
// 2026-06-11).
// -----------------------------------------------------------------------------
// Deployed-bug pin: the router keyed RoutingSignals.userTier off
// body.user_tier, which no client sends — every paying user routed as "free"
// and never got the premium model (and the field was spoofable). The tier is
// now resolved server-side from public.subscriptions / public.profiles.
//
// Run with:
//   deno test --allow-read --allow-net \
//     supabase/functions/claude-proxy/__tests__/tier_resolver_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  mapSubscriptionTier,
  resolveUserTier,
  TIER_LOOKUP_TIMEOUT_MS,
} from "../tier_resolver.ts";

const OPTS = {
  supabaseUrl: "https://example.supabase.co",
  serviceRoleKey: "service-role-test-key",
  userId: "11111111-2222-3333-4444-555555555555",
};

/** Build a fetch stub that answers /subscriptions and /profiles with the
 *  given rows and records every request for assertions. */
function fakeFetch(rows: {
  subscriptions?: unknown;
  profiles?: unknown;
  status?: number;
}): { fetchImpl: typeof fetch; calls: string[] } {
  const calls: string[] = [];
  const fetchImpl = ((input: Request | URL | string) => {
    const url = String(input);
    calls.push(url);
    const body = url.includes("/rest/v1/subscriptions")
      ? rows.subscriptions ?? []
      : rows.profiles ?? [];
    return Promise.resolve(
      new Response(JSON.stringify(body), {
        status: rows.status ?? 200,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }) as typeof fetch;
  return { fetchImpl, calls };
}

const FUTURE = new Date(Date.now() + 7 * 24 * 3600_000).toISOString();
const PAST = new Date(Date.now() - 7 * 24 * 3600_000).toISOString();

// ---- mapSubscriptionTier ----------------------------------------------------

Deno.test("TR-01 — mapSubscriptionTier maps Stripe plan names", () => {
  assertEquals(mapSubscriptionTier("premium"), "pro");
  assertEquals(mapSubscriptionTier("pro"), "pro");
  assertEquals(mapSubscriptionTier("representation"), "pro");
  assertEquals(mapSubscriptionTier("PREMIUM "), "pro"); // case/space tolerant
  assertEquals(mapSubscriptionTier("basic"), "counsel");
  assertEquals(mapSubscriptionTier("counsel"), "counsel");
  // Unknown paid value → cheaper paid tier, never free (a row only exists
  // for payers).
  assertEquals(mapSubscriptionTier("mystery-plan"), "counsel");
});

// ---- resolveUserTier — subscriptions path -----------------------------------

Deno.test("TR-02 — active premium subscription row → pro", async () => {
  const { fetchImpl, calls } = fakeFetch({
    subscriptions: [
      { status: "active", tier: "premium", current_period_end: FUTURE },
    ],
  });
  const tier = await resolveUserTier({ ...OPTS, fetchImpl });
  assertEquals(tier, "pro");
  // Lookup is keyed on the AUTHENTICATED user id — never a client claim.
  assert(calls[0].includes(`user_id=eq.${OPTS.userId}`));
  // Profiles fallback not needed when the sub row answers.
  assertEquals(calls.length, 1);
});

Deno.test("TR-03 — active basic (Counsel) subscription → counsel", async () => {
  const { fetchImpl } = fakeFetch({
    subscriptions: [
      { status: "active", tier: "basic", current_period_end: FUTURE },
    ],
  });
  assertEquals(await resolveUserTier({ ...OPTS, fetchImpl }), "counsel");
});

Deno.test("TR-04 — trialing subscription counts as paid", async () => {
  const { fetchImpl } = fakeFetch({
    subscriptions: [
      { status: "trialing", tier: "premium", current_period_end: FUTURE },
    ],
  });
  assertEquals(await resolveUserTier({ ...OPTS, fetchImpl }), "pro");
});

Deno.test(
  "TR-05 — lapsed 'active' row is NOT paid (falls to profiles)",
  async () => {
    // Mirrors check-ai-quota detectPlan: a stale active row whose
    // current_period_end passed (cancel webhook never arrived) must not
    // grant the premium model.
    const { fetchImpl, calls } = fakeFetch({
      subscriptions: [
        { status: "active", tier: "premium", current_period_end: PAST },
      ],
      profiles: [{ is_pro: false, subscription_tier: null }],
    });
    assertEquals(await resolveUserTier({ ...OPTS, fetchImpl }), "free");
    assertEquals(calls.length, 2); // fell through to profiles
  },
);

// ---- resolveUserTier — profiles fallback (Apple IAP / legacy) ---------------

Deno.test("TR-06 — no sub row, profiles is_pro=true → pro", async () => {
  const { fetchImpl } = fakeFetch({
    subscriptions: [],
    profiles: [{ is_pro: true, subscription_tier: null }],
  });
  assertEquals(await resolveUserTier({ ...OPTS, fetchImpl }), "pro");
});

Deno.test(
  "TR-07 — profiles is_pro=true with explicit basic tier → counsel",
  async () => {
    const { fetchImpl } = fakeFetch({
      subscriptions: [],
      profiles: [{ is_pro: true, subscription_tier: "basic" }],
    });
    assertEquals(await resolveUserTier({ ...OPTS, fetchImpl }), "counsel");
  },
);

Deno.test("TR-08 — no rows anywhere → free", async () => {
  const { fetchImpl } = fakeFetch({ subscriptions: [], profiles: [] });
  assertEquals(await resolveUserTier({ ...OPTS, fetchImpl }), "free");
});

// ---- resolveUserTier — fail-direction (always "free", never throw) ----------

Deno.test(
  "TR-09 — PostgREST 500 → free (fail-closed for routing cost)",
  async () => {
    const { fetchImpl } = fakeFetch({ status: 500 });
    assertEquals(await resolveUserTier({ ...OPTS, fetchImpl }), "free");
  },
);

Deno.test("TR-10 — fetch throws → free, never propagates", async () => {
  const fetchImpl =
    (() =>
      Promise.reject(new Error("network down"))) as unknown as typeof fetch;
  assertEquals(await resolveUserTier({ ...OPTS, fetchImpl }), "free");
});

Deno.test("TR-11 — slow lookup aborts at timeout → free", async () => {
  assert(TIER_LOOKUP_TIMEOUT_MS <= 5_000); // never let chat stall on this
  const fetchImpl =
    ((_input: unknown, init?: RequestInit) =>
      new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener(
          "abort",
          () => reject(new DOMException("aborted", "AbortError")),
        );
      })) as typeof fetch;
  const tier = await resolveUserTier({ ...OPTS, fetchImpl, timeoutMs: 50 });
  assertEquals(tier, "free");
});

Deno.test(
  "TR-12 — missing config/userId → free without any fetch",
  async () => {
    const { fetchImpl, calls } = fakeFetch({});
    assertEquals(
      await resolveUserTier({ ...OPTS, userId: "", fetchImpl }),
      "free",
    );
    assertEquals(
      await resolveUserTier({ ...OPTS, supabaseUrl: "", fetchImpl }),
      "free",
    );
    assertEquals(calls.length, 0);
  },
);

Deno.test(
  "TR-13 — lookup authenticates with the service-role key",
  async () => {
    let authHeader = "";
    const fetchImpl = ((input: Request | URL | string, init?: RequestInit) => {
      authHeader = String(
        (init?.headers as Record<string, string>)?.Authorization ?? "",
      );
      void input;
      return Promise.resolve(
        new Response("[]", {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      );
    }) as typeof fetch;
    await resolveUserTier({ ...OPTS, fetchImpl });
    assertEquals(authHeader, `Bearer ${OPTS.serviceRoleKey}`);
  },
);

// ---- index.ts wiring regression (static source checks) ----------------------
//
// index.ts can't be imported in tests (top-level serve()). These source-level
// pins follow the same static-parsing pattern used elsewhere in the repo and
// guard the two Wave-1 call sites against regressions.

const INDEX_SRC = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);

Deno.test(
  "TR-14 — index.ts strips client tier claims and resolves server-side",
  () => {
    // Client body.user_tier / body.tier must be deleted (ignored AND never
    // forwarded to Anthropic) …
    assert(INDEX_SRC.includes(".user_tier;"));
    assert(
      /delete \(body as \{ user_tier\?: unknown \}\)\.user_tier;/.test(
        INDEX_SRC,
      ),
    );
    assert(/delete \(body as \{ tier\?: unknown \}\)\.tier;/.test(INDEX_SRC));
    // … the old client-trust path must be gone …
    assert(!INDEX_SRC.includes("bodyTierRaw"));
    // … and the tier must come from resolveUserTier keyed on the
    // authenticated gate.user.id.
    assert(INDEX_SRC.includes("await resolveUserTier({"));
    assert(/resolveUserTier\(\{[^}]*userId: gate\.user\.id/s.test(INDEX_SRC));
  },
);

Deno.test(
  "TR-15 — index.ts reconciles thinking with the FINAL routed model",
  () => {
    // applyModelThinkingCompat(body) must run AFTER the signal router assigns
    // body.model — otherwise an Opus turn ships budget_tokens and 400s.
    const assignIdx = INDEX_SRC.indexOf("body.model = routedModelId;");
    const compatIdx = INDEX_SRC.indexOf("applyModelThinkingCompat(body);");
    assert(assignIdx > -1, "router model assignment missing");
    assert(compatIdx > -1, "applyModelThinkingCompat call missing");
    assert(compatIdx > assignIdx, "compat must run after routing");
  },
);
