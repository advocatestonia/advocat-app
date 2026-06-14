// template-fill/__tests__/template_fill_test.ts
// -----------------------------------------------------------------------------
// Unit tests for the pure fill logic. No DB / HTTP — just the substitution and
// auto-value mapping that the Legal Template Library relies on.
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildAutoValues,
  extractTokens,
  fillTemplate,
  UNRESOLVED_MARKER,
} from "../handler.ts";

Deno.test("extractTokens returns distinct tokens in first-seen order", () => {
  const body = "Hi {{full_name}}, ref {{case_number}}. Again {{full_name}}.";
  assertEquals(extractTokens(body), ["full_name", "case_number"]);
});

Deno.test("extractTokens handles whitespace inside braces", () => {
  assertEquals(extractTokens("{{  today  }}"), ["today"]);
});

Deno.test("fillTemplate substitutes resolved tokens", () => {
  const r = fillTemplate({
    body: "Dear {{recipient}}, I am {{full_name}}.",
    auto: { full_name: "Jane Doe" },
    fields: { recipient: "Police Board" },
  });
  assertEquals(r.filled, "Dear Police Board, I am Jane Doe.");
  assertEquals(r.resolved.sort(), ["full_name", "recipient"]);
  assertEquals(r.unresolved, []);
});

Deno.test("fillTemplate leaves a visible marker for unresolved tokens", () => {
  const r = fillTemplate({
    body: "Subject: {{subject}}",
    auto: {},
    fields: {},
  });
  assertEquals(r.filled, `Subject: ${UNRESOLVED_MARKER}`);
  assertEquals(r.unresolved, ["subject"]);
  assertEquals(r.resolved, []);
});

Deno.test("fillTemplate never leaves a raw {{token}} in output", () => {
  const r = fillTemplate({
    body: "{{a}} {{b}} {{c}}",
    auto: { a: "1" },
    fields: { b: "2" },
  });
  // c is unresolved → marker, but no literal braces survive.
  assertEquals(r.filled.includes("{{"), false);
  assertEquals(r.filled, `1 2 ${UNRESOLVED_MARKER}`);
});

Deno.test("user fields override auto values", () => {
  const r = fillTemplate({
    body: "{{full_name}}",
    auto: { full_name: "Auto Name" },
    fields: { full_name: "Override Name" },
  });
  assertEquals(r.filled, "Override Name");
});

Deno.test("empty/whitespace user field falls back to auto", () => {
  const r = fillTemplate({
    body: "{{full_name}}",
    auto: { full_name: "Auto Name" },
    fields: { full_name: "   " },
  });
  assertEquals(r.filled, "Auto Name");
});

Deno.test("null auto value renders as unresolved marker", () => {
  const r = fillTemplate({
    body: "{{migri_ref}}",
    auto: { migri_ref: null },
    fields: {},
  });
  assertEquals(r.filled, UNRESOLVED_MARKER);
  assertEquals(r.unresolved, ["migri_ref"]);
});

Deno.test("repeated token is filled in all positions", () => {
  const r = fillTemplate({
    body: "{{full_name}} ... signed {{full_name}}",
    auto: { full_name: "X" },
    fields: {},
  });
  assertEquals(r.filled, "X ... signed X");
  // Reported once in resolved.
  assertEquals(r.resolved, ["full_name"]);
});

Deno.test("buildAutoValues maps profile + case columns to tokens", () => {
  const auto = buildAutoValues({
    profile: { full_name: "Jane", email: "j@x.ee" },
    caseRow: {
      title: "My case",
      court_case_number: "5500/R",
      migri_reference_number: "M-1",
      nationality: "EE",
    },
    todayIso: "2026-06-14",
  });
  assertEquals(auto.full_name, "Jane");
  assertEquals(auto.email, "j@x.ee");
  assertEquals(auto.case_title, "My case");
  assertEquals(auto.case_number, "5500/R");
  assertEquals(auto.migri_ref, "M-1");
  assertEquals(auto.nationality, "EE");
  assertEquals(auto.today, "2026-06-14");
});

Deno.test("buildAutoValues tolerates missing profile and case", () => {
  const auto = buildAutoValues({
    profile: null,
    caseRow: null,
    todayIso: "2026-06-14",
  });
  assertEquals(auto.full_name, null);
  assertEquals(auto.case_number, null);
  assertEquals(auto.today, "2026-06-14");
});

Deno.test("end-to-end: real template body fills with auto+fields", () => {
  const body =
    "> **MALLI**\n\n# Kantelu\n\n**Päiväys:** {{today}}\n**Kantelija:** {{full_name}}\n**Viranomainen:** {{recipient}}\n\n{{description}}";
  const auto = buildAutoValues({
    profile: { full_name: "Dmitri Sulga", email: "d@x.ee" },
    caseRow: null,
    todayIso: "2026-06-14",
  });
  const r = fillTemplate({
    body,
    auto,
    fields: { recipient: "Poliisihallitus", description: "Facts here." },
  });
  assertEquals(r.filled.includes("{{"), false);
  assertEquals(r.filled.includes("Dmitri Sulga"), true);
  assertEquals(r.filled.includes("2026-06-14"), true);
  assertEquals(r.filled.includes("Poliisihallitus"), true);
  assertEquals(r.unresolved, []);
});
