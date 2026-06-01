// hallucination-eval-runner/__tests__/hallucination_eval_runner_test.ts
// -----------------------------------------------------------------------------
// Regression-lock for the citation-analysis core in cites.ts. The false-cite
// rate (the headline eval metric) is computed entirely from extractCites +
// citationCovered, and FIX-WAVE 12 showed how a silent break upstream once
// invalidated a whole eval number — so the deterministic math is worth locking.
//
//   * extractCites — §-style FI/EE, prefixed (§ HOL 11:2), Article-style EU, dedup.
//   * sectionFromChunk — strips §, pulls trailing section number.
//   * citationCovered — covered via specific_statute OR via returned_chunks.
//   * timingSafeEqualStr — equal / differ / length-mismatch (no early-out leak).
//
// Run:
//   deno test --allow-read \
//     supabase/functions/hallucination-eval-runner/__tests__/hallucination_eval_runner_test.ts
// -----------------------------------------------------------------------------

import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  citationCovered,
  extractCites,
  type LookupLike,
  sectionFromChunk,
  timingSafeEqualStr,
} from "../cites.ts";

// ─── extractCites ─────────────────────────────────────────────────────────────

Deno.test("EXC-01 — plain §-number cite (FI/EE)", () => {
  const cites = extractCites("Sovelletaan § 114 ja § 88 perusteella.");
  const sections = cites.map((c) => c.section).sort();
  assertEquals(sections, ["114", "88"]);
});

Deno.test("EXC-02 — prefixed §-cite (§ HOL 11:2) wins over bare", () => {
  const cites = extractCites("Katso § HOL 11:2 tarkemmin.");
  // The prefixed pattern runs first; "HOL 11:2" is captured as one cite.
  assert(cites.some((c) => c.section === "HOL 11:2"));
});

Deno.test("EXC-03 — colon section like § 11:2", () => {
  const cites = extractCites("Oikeudenkäymiskaaren § 11:2 mukaan.");
  assert(cites.some((c) => c.section === "11:2"));
});

Deno.test("EXC-04 — Article-style EU cite (case-insensitive, art. + Article)", () => {
  const cites = extractCites("See Article 17 and art. 6(1) GDPR.");
  const sections = cites.map((c) => c.section).sort();
  assertEquals(sections, ["17", "6(1)"]);
});

Deno.test("EXC-05 — dedup repeated section", () => {
  const cites = extractCites("§ 17 ... again § 17 ... and Article 17.");
  // "§ 17" dedupes to one; "Article 17" shares the same lowercased key "17".
  assertEquals(cites.filter((c) => c.section === "17").length, 1);
});

Deno.test("EXC-06 — no false positive on bare numbers / no marker", () => {
  assertEquals(extractCites("There are 17 reasons and 6 factors.").length, 0);
});

// ─── sectionFromChunk ─────────────────────────────────────────────────────────

Deno.test("SFC-01 — null / empty ⇒ empty string", () => {
  assertEquals(sectionFromChunk(null), "");
  assertEquals(sectionFromChunk(""), "");
});

Deno.test("SFC-02 — strips § and pulls trailing section", () => {
  assertEquals(sectionFromChunk("§ 114"), "114");
  assertEquals(sectionFromChunk("HOL § 11:2"), "11:2");
});

// ─── citationCovered (the false-cite core) ────────────────────────────────────

const lk = (
  specific: string | undefined,
  labels: Array<string | null>,
): LookupLike => ({
  input: { specific_statute: specific },
  returned_chunks: labels.map((section_label) => ({ section_label })),
});

Deno.test("COV-01 — covered via specific_statute substring", () => {
  const cite = { raw: "§ 114", section: "114", context: "" };
  assert(citationCovered(cite, [lk("HOL §114", [])]));
});

Deno.test("COV-02 — covered via returned_chunks section_label", () => {
  const cite = { raw: "§ 88", section: "88", context: "" };
  assert(citationCovered(cite, [lk(undefined, ["§ 88"])]));
});

Deno.test("COV-03 — covered via colon-suffix match (label ends with :num)", () => {
  const cite = { raw: "§ 2", section: "2", context: "" };
  assert(citationCovered(cite, [lk(undefined, ["11:2"])]));
});

Deno.test("COV-04 — UNcovered ⇒ false-cite (nothing matches)", () => {
  const cite = { raw: "§ 999", section: "999", context: "" };
  assert(!citationCovered(cite, [lk("HOL §114", ["§ 88", "11:2"])]));
});

Deno.test("COV-05 — empty lookups ⇒ never covered", () => {
  const cite = { raw: "§ 17", section: "17", context: "" };
  assert(!citationCovered(cite, []));
});

// ─── timingSafeEqualStr ───────────────────────────────────────────────────────

Deno.test("TSE-01 — equal strings ⇒ true", () => {
  assert(timingSafeEqualStr("super-secret-123", "super-secret-123"));
});

Deno.test("TSE-02 — same length, differ ⇒ false", () => {
  assert(!timingSafeEqualStr("super-secret-123", "super-secret-124"));
});

Deno.test("TSE-03 — length mismatch ⇒ false (no throw)", () => {
  assert(!timingSafeEqualStr("short", "much-longer-secret"));
  assert(!timingSafeEqualStr("", "x"));
  assert(timingSafeEqualStr("", ""));
});
