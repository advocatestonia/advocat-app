// Deno tests for deadline-radar-tick — Phase 2 Pkg 9.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/deadline-radar-tick/__tests__/deadline_radar_tick_test.ts
//
// Pure-function tests for thresholds + quiet-hours + cron-secret gate.
// HTTP-level integration coverage is in the migration contract test.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { checkCronSecret } from "../auth_gate.ts";
import {
  deliveryDecision,
  isCritical,
  isInQuietHours,
  thresholdsForDelta,
  userLocalHour,
  type Threshold,
} from "../thresholds.ts";

// =============================================================================
// 1. cron-secret gate
// =============================================================================

Deno.test("DRT-T01 — gate: missing env secret → 500", () => {
  const r = checkCronSecret("anything", undefined);
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 500);
});

Deno.test("DRT-T02 — gate: missing header → 401", () => {
  const r = checkCronSecret(null, "real-secret");
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 401);
});

Deno.test("DRT-T03 — gate: wrong header → 401", () => {
  const r = checkCronSecret("wrong", "real-secret");
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 401);
});

Deno.test("DRT-T04 — gate: matching secret → allow", () => {
  const r = checkCronSecret("real-secret", "real-secret");
  assertEquals(r.kind, "allow");
});

// =============================================================================
// 2. thresholdsForDelta — bounded windows
// =============================================================================

Deno.test("DRT-T10 — 30d threshold matches around 28-30 days", () => {
  // 28d = 28*86400 = 2,419,200 sec.
  const matches = thresholdsForDelta(28 * 86400);
  assert(matches.includes("30d" as Threshold));
});

Deno.test("DRT-T11 — 7d threshold matches around 6 days", () => {
  const matches = thresholdsForDelta(6 * 86400);
  assert(matches.includes("7d" as Threshold));
});

Deno.test("DRT-T12 — 3d threshold matches around 60h", () => {
  const matches = thresholdsForDelta(60 * 3600);
  assert(matches.includes("3d" as Threshold));
});

Deno.test("DRT-T13 — 1d threshold matches around 24h", () => {
  const matches = thresholdsForDelta(24 * 3600);
  assert(matches.includes("1d" as Threshold));
});

Deno.test("DRT-T14 — morning_of threshold matches around 4h", () => {
  const matches = thresholdsForDelta(4 * 3600);
  assert(matches.includes("morning_of" as Threshold));
});

Deno.test("DRT-T15 — far-future delta (60d) matches no threshold", () => {
  assertEquals(thresholdsForDelta(60 * 86400).length, 0);
});

Deno.test("DRT-T16 — past delta (-2h) matches no threshold (sweep handles it)", () => {
  assertEquals(thresholdsForDelta(-2 * 3600).length, 0);
});

Deno.test("DRT-T17 — between-windows delta matches no threshold (10 days)", () => {
  // 10d sits between 7d window (≤7d) and 30d window (>27d). No match.
  assertEquals(thresholdsForDelta(10 * 86400).length, 0);
});

// =============================================================================
// 3. isCritical
// =============================================================================

Deno.test("DRT-T20 — 30d/7d are non-critical", () => {
  assertFalse(isCritical("30d"));
  assertFalse(isCritical("7d"));
});

Deno.test("DRT-T21 — 3d/1d/morning_of are critical", () => {
  assert(isCritical("3d"));
  assert(isCritical("1d"));
  assert(isCritical("morning_of"));
});

// =============================================================================
// 4. quiet hours
// =============================================================================

Deno.test("DRT-T30 — userLocalHour resolves Helsinki TZ", () => {
  // 2026-05-06 12:00:00 UTC = 15:00 Helsinki (UTC+3 in DST May).
  const utcNoon = new Date("2026-05-06T12:00:00Z");
  const h = userLocalHour(utcNoon, "Europe/Helsinki");
  // Helsinki summer time is UTC+3.
  assertEquals(h, 15);
});

Deno.test("DRT-T31 — userLocalHour resolves Tallinn TZ (same as Helsinki)", () => {
  const utcNoon = new Date("2026-05-06T12:00:00Z");
  const h = userLocalHour(utcNoon, "Europe/Tallinn");
  assertEquals(h, 15);
});

Deno.test("DRT-T32 — quiet hours: 22:00 Helsinki is quiet", () => {
  // 22:00 Helsinki (DST) = 19:00 UTC.
  const utc = new Date("2026-05-06T19:00:00Z");
  assert(isInQuietHours(utc, "Europe/Helsinki"));
});

Deno.test("DRT-T33 — quiet hours: 03:00 Helsinki is quiet", () => {
  // 03:00 Helsinki (DST) = 00:00 UTC.
  const utc = new Date("2026-05-06T00:00:00Z");
  assert(isInQuietHours(utc, "Europe/Helsinki"));
});

Deno.test("DRT-T34 — quiet hours: 12:00 Helsinki is NOT quiet", () => {
  const utc = new Date("2026-05-06T09:00:00Z");
  assertFalse(isInQuietHours(utc, "Europe/Helsinki"));
});

Deno.test("DRT-T35 — quiet hours: 08:00 Helsinki is NOT quiet (boundary)", () => {
  // 08:00 Helsinki (DST) = 05:00 UTC.
  const utc = new Date("2026-05-06T05:00:00Z");
  assertFalse(isInQuietHours(utc, "Europe/Helsinki"));
});

Deno.test("DRT-T36 — quiet hours: 21:00 Helsinki IS quiet (boundary)", () => {
  // 21:00 Helsinki (DST) = 18:00 UTC.
  const utc = new Date("2026-05-06T18:00:00Z");
  assert(isInQuietHours(utc, "Europe/Helsinki"));
});

// =============================================================================
// 5. deliveryDecision (architect §6 — quiet hours + critical bypass)
// =============================================================================

Deno.test("DRT-T40 — non-critical 7d at 22:00 Helsinki defers", () => {
  const utc = new Date("2026-05-06T19:00:00Z");
  assertEquals(deliveryDecision("7d", utc, "Europe/Helsinki"), "defer");
});

Deno.test("DRT-T41 — critical 1d at 22:00 Helsinki sends (bypass)", () => {
  const utc = new Date("2026-05-06T19:00:00Z");
  assertEquals(deliveryDecision("1d", utc, "Europe/Helsinki"), "send");
});

Deno.test("DRT-T42 — non-critical 30d at 12:00 Helsinki sends", () => {
  const utc = new Date("2026-05-06T09:00:00Z");
  assertEquals(deliveryDecision("30d", utc, "Europe/Helsinki"), "send");
});

Deno.test("DRT-T43 — critical morning_of at 03:00 Helsinki sends (bypass)", () => {
  const utc = new Date("2026-05-06T00:00:00Z");
  assertEquals(deliveryDecision("morning_of", utc, "Europe/Helsinki"), "send");
});
