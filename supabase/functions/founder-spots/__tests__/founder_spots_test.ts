// Deno tests for founder-spots Edge Function.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/founder-spots/__tests__/founder_spots_test.ts
//
// These are pure-function + source-contract tests; the live integration
// (real DB count returning JSON) is covered by the post-deploy smoke curl.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildSpotsBody,
  FOUNDER_TOTAL,
  INTRO_TYPE,
} from "../index.ts";

const source = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);

Deno.test("FS-T01 — body shape: 0 taken returns full pool, not closed", () => {
  const body = buildSpotsBody(0);
  assertEquals(body, {
    taken: 0,
    remaining: 100,
    total: 100,
    closed: false,
  });
});

Deno.test("FS-T02 — body shape: 47 taken returns 53 remaining", () => {
  const body = buildSpotsBody(47);
  assertEquals(body.taken, 47);
  assertEquals(body.remaining, 53);
  assertEquals(body.closed, false);
});

Deno.test("FS-T03 — body shape: exactly 100 taken means closed", () => {
  const body = buildSpotsBody(100);
  assertEquals(body.taken, 100);
  assertEquals(body.remaining, 0);
  assertEquals(body.closed, true);
});

Deno.test("FS-T04 — body shape: overshoot (race) clamps remaining to 0", () => {
  // If a race lets us slip to 101 active founders, remaining must not go
  // negative — the public-facing counter clamps to ≥0.
  const body = buildSpotsBody(101);
  assertEquals(body.taken, 101);
  assertEquals(body.remaining, 0);
  assertEquals(body.closed, true);
});

Deno.test("FS-T05 — body shape: negative input is sanitised to 0", () => {
  const body = buildSpotsBody(-5);
  assertEquals(body.taken, 0);
  assertEquals(body.remaining, 100);
  assertEquals(body.closed, false);
});

Deno.test("FS-T06 — constants match the spec (100 total, early-access-100)", () => {
  assertEquals(FOUNDER_TOTAL, 100);
  assertEquals(INTRO_TYPE, "early-access-100");
});

Deno.test("FS-T07 — function is GET-only with explicit OPTIONS preflight", () => {
  // Source contract: rejects everything except GET / OPTIONS.
  assertStringIncludes(source, 'req.method === "OPTIONS"');
  assertStringIncludes(source, 'req.method !== "GET"');
});

Deno.test("FS-T08 — sets a Cache-Control max-age header on success", () => {
  // Without the cache header a Reddit hug-of-death takes down the DB.
  assertStringIncludes(source, "Cache-Control");
  assertStringIncludes(source, "max-age=60");
});

Deno.test("FS-T09 — CORS allows any origin (public counter, embeddable)", () => {
  assertStringIncludes(source, '"Access-Control-Allow-Origin": "*"');
});

Deno.test("FS-T10 — query filters by status active+trialing only", () => {
  // Counted as 'taken' when active or trialing; canceled/past_due/etc free
  // the slot. This MUST match the cap-check logic in create-checkout to
  // avoid drift between "cap reached" and "spots remaining".
  assertStringIncludes(source, '["active", "trialing"]');
  assertStringIncludes(source, '"intro_type"');
  assertStringIncludes(source, '"early-access-100"');
});

Deno.test("FS-T11 — count uses head:true for performance (no row materialisation)", () => {
  // PostgREST count with head:true returns just the count header — much
  // cheaper than fetching rows. Critical because this endpoint is hit by
  // every landing-page visitor.
  assertStringIncludes(source, "head: true");
  assertStringIncludes(source, '{ count: "exact"');
});

Deno.test("FS-T12 — fail-open path returns degraded=true with full pool", () => {
  // When the DB is unreachable we MUST NOT return 500 — the landing page
  // would block visitors from clicking checkout. We return a degraded but
  // still-valid response.
  assertStringIncludes(source, "degraded: true");
  assertStringIncludes(source, "max-age=10"); // shorter cache for degraded
});
