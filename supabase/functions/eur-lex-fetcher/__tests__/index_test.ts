// Deno tests for eur-lex-fetcher/index.ts (pure helpers only)
// -----------------------------------------------------------------------------
// Full worker-loop tests would need a Supabase + EUR-Lex test harness; we
// cover the auth gate and small pure helpers here. End-to-end coverage is
// the manual smoke check after deploy.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { checkCronSecret, hashShort } from "../index.ts";

// =============================================================================
// cron-secret gate (mirrors deadline-radar-tick contract)
// =============================================================================

Deno.test("EL-X01 — gate: missing env secret → 500", () => {
  const r = checkCronSecret("anything", undefined);
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 500);
});

Deno.test("EL-X02 — gate: missing header → 401", () => {
  const r = checkCronSecret(null, "real-secret");
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 401);
});

Deno.test("EL-X03 — gate: wrong header → 401", () => {
  const r = checkCronSecret("wrong", "real-secret");
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 401);
});

Deno.test("EL-X04 — gate: matching secret → allow", () => {
  const r = checkCronSecret("real-secret", "real-secret");
  assertEquals(r.kind, "allow");
});

// =============================================================================
// hashShort — version_hash helper
// =============================================================================

Deno.test("EL-X10 — hashShort is deterministic", () => {
  const a = hashShort("Article 7 — Right of residence");
  const b = hashShort("Article 7 — Right of residence");
  assertEquals(a, b);
});

Deno.test("EL-X11 — hashShort differs across different inputs", () => {
  const a = hashShort("Article 7");
  const b = hashShort("Article 8");
  assert(a !== b);
});

Deno.test("EL-X12 — hashShort returns ≤12 hex chars", () => {
  const h = hashShort("any input string here");
  assert(h.length <= 12);
  assert(/^[0-9a-f]+$/.test(h));
});
