// Deno tests for hudoc-fetcher/index.ts (auth gate only)
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import { checkCronSecret } from "../index.ts";

Deno.test("HU-X01 — gate: missing env secret → 500", () => {
  const r = checkCronSecret("anything", undefined);
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 500);
});

Deno.test("HU-X02 — gate: missing header → 401", () => {
  const r = checkCronSecret(null, "real-secret");
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 401);
});

Deno.test("HU-X03 — gate: wrong header → 401", () => {
  const r = checkCronSecret("wrong", "real-secret");
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 401);
});

Deno.test("HU-X04 — gate: matching secret → allow", () => {
  const r = checkCronSecret("real-secret", "real-secret");
  assertEquals(r.kind, "allow");
});
