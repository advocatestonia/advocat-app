// Deno tests for winback-send/winback_logic.ts
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/winback-send/__tests__/winback_logic_test.ts

import {
  assert,
  assertEquals,
  assertExists,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  classifyStep,
  daysInactive,
  processCandidates,
  promoCodeFor,
  unsubUrl,
} from "../winback_logic.ts";
import { renderWinback } from "../../_shared/retention_templates.ts";

const T0 = new Date("2026-05-14T10:00:00Z");

Deno.test("WB-T01 — daysInactive: 3 days ago = 3", () => {
  const d = daysInactive("2026-05-11T10:00:00Z", T0);
  assertEquals(d, 3);
});

Deno.test("WB-T02 — daysInactive: 14 days ago = 14", () => {
  const d = daysInactive("2026-04-30T10:00:00Z", T0);
  assertEquals(d, 14);
});

Deno.test("WB-T10 — classifyStep: valid steps", () => {
  assertEquals(classifyStep("d3"), "d3");
  assertEquals(classifyStep("d7"), "d7");
  assertEquals(classifyStep("d14"), "d14");
});

Deno.test("WB-T11 — classifyStep: invalid returns null", () => {
  assertEquals(classifyStep("d30"), null);
  assertEquals(classifyStep(null), null);
  assertEquals(classifyStep(undefined), null);
  assertEquals(classifyStep(""), null);
});

Deno.test("WB-T20 — promoCodeFor: deterministic per user", () => {
  const a1 = promoCodeFor("user-abc-123");
  const a2 = promoCodeFor("user-abc-123");
  assertEquals(a1, a2);
});

Deno.test("WB-T21 — promoCodeFor: different users → different codes", () => {
  const a = promoCodeFor("user-1");
  const b = promoCodeFor("user-2");
  assertNotEquals(a, b);
});

Deno.test("WB-T22 — promoCodeFor: format ADV-XXXXXX", () => {
  const c = promoCodeFor("u1");
  assert(c.startsWith("ADV-"));
  assertEquals(c.length, 10);
  // No 0/O/1/I/L
  assert(!/[01OIL]/.test(c.slice(4)));
});

Deno.test("WB-T30 — processCandidates: maps step and promo correctly", () => {
  const out = processCandidates(
    [
      {
        user_id: "u-d3",
        email: "a@x.com",
        full_name: "Alpha",
        preferred_language: "en",
        last_active_at: "2026-05-11T10:00:00Z",
        target_step: "d3",
        winback_sent_count: 0,
      },
      {
        user_id: "u-d14",
        email: "b@x.com",
        full_name: "Beta",
        preferred_language: "ru",
        last_active_at: "2026-04-25T10:00:00Z",
        target_step: "d14",
        winback_sent_count: 2,
      },
    ],
    T0,
  );
  assertEquals(out.length, 2);
  assertEquals(out[0].step, "d3");
  assertEquals(out[0].promoCode, undefined);
  assertEquals(out[1].step, "d14");
  assertExists(out[1].promoCode);
});

Deno.test("WB-T31 — processCandidates: skips at-or-above cap", () => {
  const out = processCandidates(
    [
      {
        user_id: "u",
        email: "a@x.com",
        full_name: "A",
        preferred_language: "en",
        last_active_at: "2026-05-11T10:00:00Z",
        target_step: "d3",
        winback_sent_count: 3, // already sent 3 — cap is 3
      },
    ],
    T0,
  );
  assertEquals(out.length, 0);
});

Deno.test("WB-T32 — processCandidates: drops invalid steps silently", () => {
  const out = processCandidates(
    [
      {
        user_id: "u",
        email: "a@x.com",
        full_name: "A",
        preferred_language: "en",
        last_active_at: "2026-05-11T10:00:00Z",
        target_step: "d99",
        winback_sent_count: 0,
      },
    ],
    T0,
  );
  assertEquals(out.length, 0);
});

Deno.test("WB-T40 — unsubUrl: builds proper URL", () => {
  const u = unsubUrl("https://advocat.ee/app", "abc-token", "winback");
  assertEquals(u, "https://advocat.ee/app/u/abc-token?k=winback");
});

Deno.test("WB-T50 — renderWinback d3: subject + body + CTA", () => {
  const r = renderWinback(
    {
      fullName: "Dmitri Sulga",
      email: "test@example.com",
      lang: "en",
      daysInactive: 3,
      appUrl: "https://advocat.ee/app",
      unsubscribeUrl: "https://advocat.ee/app/u/abc?k=winback",
    },
    "d3",
  );
  assert(r.subject.toLowerCase().includes("contract"));
  assert(r.html.includes("Dmitri"));
  assert(r.html.includes("https://advocat.ee/app"));
  assert(r.text.includes("Dmitri"));
});

Deno.test("WB-T51 — renderWinback d14: includes promo code", () => {
  const r = renderWinback(
    {
      fullName: "Sofia",
      email: "s@x.com",
      lang: "en",
      daysInactive: 14,
      appUrl: "https://advocat.ee/app",
      unsubscribeUrl: "https://advocat.ee/app/u/abc?k=winback",
      promoCode: "ADV-ABC123",
    },
    "d14",
  );
  assert(r.html.includes("ADV-ABC123"));
  assert(r.text.includes("ADV-ABC123"));
});

Deno.test("WB-T52 — renderWinback: localises (ET)", () => {
  const r = renderWinback(
    {
      fullName: "Sofia",
      email: "s@x.com",
      lang: "et",
      daysInactive: 7,
      appUrl: "https://advocat.ee/app",
      unsubscribeUrl: "u",
    },
    "d7",
  );
  assert(r.subject.toLowerCase().includes("näidis"));
});

Deno.test("WB-T53 — renderWinback: escapes XSS in name", () => {
  const r = renderWinback(
    {
      fullName: "<script>alert(1)</script>",
      email: "s@x.com",
      lang: "en",
      daysInactive: 3,
      appUrl: "https://advocat.ee/app",
      unsubscribeUrl: "u",
    },
    "d3",
  );
  assert(!r.html.includes("<script>"));
});

Deno.test("WB-T60 — renderWinback: includes unsubscribe link", () => {
  const r = renderWinback(
    {
      fullName: "Sofia",
      email: "s@x.com",
      lang: "en",
      daysInactive: 3,
      appUrl: "https://advocat.ee/app",
      unsubscribeUrl: "https://advocat.ee/app/u/abc?k=winback",
    },
    "d3",
  );
  assert(r.html.includes("https://advocat.ee/app/u/abc?k=winback"));
  assert(r.text.includes("https://advocat.ee/app/u/abc?k=winback"));
});

Deno.test("WB-T61 — renderWinback: all 3 steps render in all 4 langs", () => {
  for (const step of ["d3", "d7", "d14"] as const) {
    for (const lang of ["en", "et", "ru", "fi"] as const) {
      const r = renderWinback(
        {
          fullName: "Test",
          email: "t@x.com",
          lang,
          daysInactive: 3,
          appUrl: "https://advocat.ee/app",
          unsubscribeUrl: "u",
          promoCode: "ADV-TEST",
        },
        step,
      );
      assert(r.subject.length > 0, `subject empty for ${step}/${lang}`);
      assert(r.html.includes("Advocat"), `Advocat missing for ${step}/${lang}`);
      assert(r.text.length > 50, `text too short for ${step}/${lang}`);
    }
  }
});
