// verify-lawyer/__tests__/validate_test.ts
// -----------------------------------------------------------------------------
// Pure-function tests for the request validator. No network, no Supabase.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/verify-lawyer/__tests__/validate_test.ts
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { validateBody } from "../validate.ts";

// ─── Happy path ──────────────────────────────────────────────────────────

Deno.test("VAL-OK-01 — minimal valid payload (no URL)", () => {
  const out = validateBody({
    country: "EE",
    bar_id: "5421",
    name: "Dmitri Sulga",
    email: "dmitri@example.com",
  });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok") {
    assertEquals(out.body.country, "EE");
    assertEquals(out.body.barId, "5421");
    assertEquals(out.body.fullName, "Dmitri Sulga");
    assertEquals(out.body.email, "dmitri@example.com");
    assertEquals(out.body.practiceUrl, null);
  }
});

Deno.test("VAL-OK-02 — lowercases country, email; trims fields", () => {
  const out = validateBody({
    country: "fi",
    bar_id: "  12345 ",
    name: "  Matti Virtanen  ",
    email: "  Matti.Virtanen@FIRM.FI ",
    practice_url: "https://firm.fi/team/matti",
  });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok") {
    assertEquals(out.body.country, "FI");
    assertEquals(out.body.barId, "12345");
    assertEquals(out.body.fullName, "Matti Virtanen");
    assertEquals(out.body.email, "matti.virtanen@firm.fi");
    assertEquals(out.body.practiceUrl, "https://firm.fi/team/matti");
  }
});

// ─── Rejection paths ─────────────────────────────────────────────────────

Deno.test("VAL-FAIL-01 — unknown country → bad_country", () => {
  const out = validateBody({
    country: "DE",
    bar_id: "1",
    name: "A B",
    email: "a@b.co",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_country");
});

Deno.test("VAL-FAIL-02 — empty bar_id → bad_bar_id", () => {
  const out = validateBody({
    country: "EE",
    bar_id: "",
    name: "A B",
    email: "a@b.co",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_bar_id");
});

Deno.test("VAL-FAIL-03 — overlong bar_id (>64) → bad_bar_id", () => {
  const out = validateBody({
    country: "EE",
    bar_id: "x".repeat(65),
    name: "A B",
    email: "a@b.co",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_bar_id");
});

Deno.test("VAL-FAIL-04 — single short token name → bad_name", () => {
  const out = validateBody({
    country: "EE",
    bar_id: "5421",
    name: "JK",
    email: "a@b.co",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_name");
});

Deno.test("VAL-FAIL-05 — malformed email → bad_email", () => {
  const out = validateBody({
    country: "EE",
    bar_id: "5421",
    name: "Dmitri Sulga",
    email: "not-an-email",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_email");
});

Deno.test("VAL-FAIL-06 — practice_url without scheme → bad_url", () => {
  const out = validateBody({
    country: "EE",
    bar_id: "5421",
    name: "Dmitri Sulga",
    email: "a@b.co",
    practice_url: "advokaadid.ee/sulga",
  });
  assertEquals(out.kind, "error");
  if (out.kind === "error") assertEquals(out.payload.reason, "bad_url");
});

Deno.test("VAL-OK-03 — empty practice_url field is treated as null", () => {
  const out = validateBody({
    country: "EE",
    bar_id: "5421",
    name: "Dmitri Sulga",
    email: "a@b.co",
    practice_url: "   ",
  });
  assertEquals(out.kind, "ok");
  if (out.kind === "ok") assertEquals(out.body.practiceUrl, null);
});

Deno.test("VAL-FAIL-07 — non-string fields → bad_country first", () => {
  const out = validateBody({
    country: 42 as unknown,
    bar_id: null as unknown,
  });
  assertEquals(out.kind, "error");
});
