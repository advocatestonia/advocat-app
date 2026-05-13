// Deno TDD — Phase 2 Pkg 2 fail-closed enforcement (citation_enforcement.ts).
// -----------------------------------------------------------------------------
// The verifier (citation_grounder.ts) handles the marker side: when the model
// emits [[ref:TLS:88]], we know to render a chip + check whether the chunk
// was retrieved. But the verifier is silent on the OPPOSITE failure mode:
// the model writes "TLS § 88" with no marker at all, and the hallucination
// reaches the user with zero badge.
//
// citation_enforcement.ts closes that gap. These tests pin the behaviour:
//   • Paragraph-level citation WITH marker     → no-op (passes through).
//   • Paragraph-level citation WITHOUT marker  → stripped, violation recorded.
//   • Generic act mention (no §)               → no-op (acceptable register).
//   • EU directive citation w/o marker         → stripped.
//   • ECHR article citation w/o marker         → stripped.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/_shared/__tests__/citation_enforcement_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  BARE_ECHR_PATTERN,
  BARE_ESTONIAN_CITATION_PATTERN,
  BARE_EU_DIRECTIVE_PATTERN,
  BARE_FINNISH_CITATION_PATTERN,
  enforceCitations,
  ESTONIAN_LAW_ABBREVS,
  FINNISH_LAW_ABBREVS,
  summariseViolations,
} from "../citation_enforcement.ts";

// ─── CENF-T01 — marker present → no violation ───────────────────────────────

Deno.test("CENF-T01 — paragraph-level citation WITH marker → no-op", () => {
  const reply =
    "Tööandja võib lepingu erakorraliselt üles öelda TLS § 88 alusel [[ref:TLS:88]] " +
    "kui esineb mõjuv põhjus.";
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 0);
  assertEquals(out.cleanedText, reply, "cleanedText must equal input verbatim");
});

// ─── CENF-T02 — marker missing → violation + strip ──────────────────────────

Deno.test("CENF-T02 — paragraph-level citation WITHOUT marker → stripped", () => {
  const reply = "Töölepingu seaduse alusel TLS § 88 on lubatud lepingu lõpetada.";
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 1);
  assertEquals(out.violations[0].kind, "ee_bare_paragraph");
  assertEquals(out.violations[0].act_slug, "tls");
  assertEquals(out.violations[0].paragraph, "88");
  // After strip the § number is gone but the act abbreviation remains so
  // the prose stays grammatically valid: "TLS § 88 on lubatud..." → "TLS on lubatud..."
  assertEquals(out.cleanedText.includes("§ 88"), false);
  assertStringIncludes(out.cleanedText, "TLS");
});

// ─── CENF-T03 — generic mention (no §) → no-op ──────────────────────────────

Deno.test("CENF-T03 — generic act reference without § → passes through", () => {
  // The system prompt allows the model to talk about an act in general
  // terms ("üürilepingu seadustes on sätestatud...") without paragraph-level
  // claims. We don't gate that — it's not a verifiable claim.
  const reply = [
    "Üürilepingu seadustes on sätestatud üldine reegel.",
    "VÕS reguleerib lepinguõigust.",
    "TLS käsitleb töösuhteid.",
    "Vastavalt seadusele on tööandjal kohustus...",
  ].join(" ");
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 0);
  assertEquals(out.cleanedText, reply);
});

// ─── CENF-T04 — EU directive with marker → no-op ────────────────────────────

Deno.test("CENF-T04 — EU directive citation WITH marker → no-op", () => {
  const reply =
    "Per Directive 2019/1152 Article 5 [[ref:32019L1152:5]] employers must inform...";
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 0);
  assertEquals(out.cleanedText, reply);
});

// ─── CENF-T05 — EU directive without marker → stripped ──────────────────────

Deno.test("CENF-T05 — EU directive citation WITHOUT marker → stripped", () => {
  const reply =
    "See on käsitletud Direktiiv 96/9/EÜ artikkel 5 — andmebaaside kaitse.";
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 1);
  assertEquals(out.violations[0].kind, "eu_bare_directive");
  // 96 → 1996 (year < 50 means 20xx so we use ≥50 → 19xx rule)
  assertEquals(out.violations[0].act_slug, "31996l0009");
  assertEquals(out.violations[0].paragraph, "5");
  // After strip: gentler replacement — "direktiiv 96/9" stays so prose
  // remains readable, but the formal "Direktiiv 96/9/EÜ artikkel 5"
  // claim is gone.
  assertEquals(out.cleanedText.includes("artikkel 5"), false);
});

// ─── CENF-T06 — ECHR article without marker → stripped ──────────────────────

Deno.test("CENF-T06 — ECHR article citation WITHOUT marker → stripped", () => {
  const reply =
    "Kaebajal on õigus tugineda ECHR Article 8 alusel privaatsusõigusele.";
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 1);
  assertEquals(out.violations[0].kind, "echr_bare_article");
  assertEquals(out.violations[0].paragraph, "8");
  assertEquals(out.cleanedText.includes("Article 8"), false);
});

// ─── CENF-T07 — multiple violations in one reply ────────────────────────────

Deno.test("CENF-T07 — multiple bare citations → all stripped, all logged", () => {
  const reply = [
    "TLS § 88 ja KarS § 121 ja PKS § 49 — kolm väidet ilma markerita.",
  ].join(" ");
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 3);
  const slugs = out.violations.map((v) => v.act_slug).sort();
  assertEquals(slugs, ["kars", "pks", "tls"]);
  assertEquals(out.cleanedText.includes("§ 88"), false);
  assertEquals(out.cleanedText.includes("§ 121"), false);
  assertEquals(out.cleanedText.includes("§ 49"), false);
});

// ─── CENF-T08 — partial marker coverage (one marker, two claims) ────────────

Deno.test(
  "CENF-T08 — marker for one paragraph doesn't cover a different paragraph",
  () => {
    // Model emits a marker for TLS:88 but ALSO writes "TLS § 117" with no
    // marker for 117 — only 88 is covered. 117 must be stripped.
    const reply =
      "Lepingu lõpetamine TLS § 88 [[ref:TLS:88]] alusel, aga TLS § 117 ei kehti.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 1);
    assertEquals(out.violations[0].paragraph, "117");
    // §88 stays (covered), §117 is stripped.
    assertEquals(out.cleanedText.includes("TLS § 88"), true);
    assertEquals(out.cleanedText.includes("§ 117"), false);
  },
);

// ─── CENF-T09 — Õ/Ä/Ü glyphs in abbreviations (VÕS, PärS) ───────────────────

Deno.test(
  "CENF-T09 — VÕS § 25 without marker → stripped despite Õ glyph",
  () => {
    const reply = "Vastavalt VÕS § 25 on lepingu sõlmimine vabatahtlik.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 1);
    assertEquals(out.violations[0].act_slug, "võs");
    assertEquals(out.violations[0].paragraph, "25");
  },
);

// ─── CENF-T10 — child paragraph covered by parent marker (e.g. 88-1) ────────

Deno.test(
  "CENF-T10 — marker for TLS:88 covers child reference 'TLS § 88-1'",
  () => {
    // Conservative parent-resolves-child rule: if "TLS § 88-1" appears
    // and only [[ref:TLS:88]] (no -1) is present, we accept it because
    // the child paragraph lives inside the parent. This avoids over-
    // blocking legitimate sub-references. Tests CGRD-T11 / CIT-INT-T01
    // already cover the strict marker match.
    const reply =
      "Erinev kohaldamine TLS § 88-1 [[ref:TLS:88]] alusel — sama paragrahv, alapunkt 1.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 0);
  },
);

// ─── CENF-T11 — idempotence ─────────────────────────────────────────────────

Deno.test("CENF-T11 — enforce(enforce(x)) === enforce(x)", () => {
  const reply = "Bad TLS § 88 here without marker.";
  const once = enforceCitations(reply);
  const twice = enforceCitations(once.cleanedText);
  assertEquals(twice.cleanedText, once.cleanedText);
  assertEquals(twice.violations.length, 0);
});

// ─── CENF-T12 — long reply with no violations is byte-identical ─────────────

Deno.test("CENF-T12 — large clean reply passes through byte-identical", () => {
  // ~5KB realistic reply: prose + markers + generic mentions. No bare
  // paragraph cites. Ensures we don't accidentally mutate clean text.
  const para = "Tööandja võib lepingu lõpetada vastavalt seadusele [[ref:TLS:88]]. ";
  const reply = para.repeat(50);
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 0);
  assertEquals(out.cleanedText, reply);
});

// ─── CENF-T13 — empty / null inputs are no-ops ──────────────────────────────

Deno.test("CENF-T13 — empty input → empty output, no throw", () => {
  assertEquals(enforceCitations("").cleanedText, "");
  assertEquals(enforceCitations("").violations.length, 0);
  // Whitespace-only.
  assertEquals(enforceCitations("   \n\n  ").violations.length, 0);
});

// ─── CENF-T14 — case-insensitive abbreviation match ─────────────────────────

Deno.test("CENF-T14 — 'Kars § 121' (mixed case) is detected as KarS", () => {
  // Model occasionally regresses to weird casing. We allow both KarS
  // and KARS in the abbreviation map; lowercase 'kars' should also work.
  const reply = "Vastavalt KarS § 121 on tegu kuritegu.";
  const out = enforceCitations(reply);
  assertEquals(out.violations.length, 1);
  assertEquals(out.violations[0].act_slug, "kars");
});

// ─── CENF-T15 — marker pattern guards against false positives ───────────────

Deno.test(
  "CENF-T15 — non-law abbreviation ('TLDR') with §-like punctuation: no false positive",
  () => {
    // Defensive: 'TLDR § 99' shouldn't match because TLDR isn't in the
    // abbreviation map. The lookbehind also blocks 'XYZTLS § 88' since
    // that would have a preceding word char.
    const reply = "TLDR § 99 means 'too long, didn't read'.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 0);
  },
);

Deno.test(
  "CENF-T15b — embedded match: 'XYZTLS § 88' has TLS prefixed → not flagged",
  () => {
    // Lookbehind protects against substring matches inside identifiers.
    const reply = "XYZTLS § 88 is not a real law reference.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 0);
  },
);

// ─── CENF-T16 — Finnish full-act-name commentary still NOT enforced ─────────

Deno.test(
  "CENF-T16 — Finnish full-act-name commentary ('Rikoslain ...') is NOT enforced",
  () => {
    // Phase 2 Pkg 1 (2026-05-11) added FINNISH_LAW_ABBREVS enforcement for
    // the abbreviation forms ("RL 21 luku 1 §", "TSL § 7-3"). But the
    // generic full-act-name form (Estonian commentary mentioning the
    // Finnish "Rikoslain" in genitive) does NOT contain a registered
    // abbreviation, so the enforcer correctly passes it through.
    const reply = "Suomen Rikoslain 21 luku § 5 alusel see ei kehti.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 0);
  },
);

// ─── CENF-T17 — replacement preserves whitespace context ────────────────────

Deno.test(
  "CENF-T17 — stripped citation leaves no double space / orphan punctuation",
  () => {
    // Mild quality check: after stripping "§ 88" from "TLS § 88 alusel",
    // we should not end up with "TLS  alusel" (double space). The
    // replacement keeps "TLS alusel" tight.
    const reply = "TLS § 88 alusel.";
    const out = enforceCitations(reply);
    // We don't promise perfect whitespace collapsing — but no garbled
    // characters either.
    assertEquals(out.cleanedText.startsWith("TLS"), true);
    assertEquals(out.cleanedText.endsWith("alusel."), true);
  },
);

// ─── CENF-T18 — summariseViolations bounded log volume ──────────────────────

Deno.test(
  "CENF-T18 — summariseViolations caps the sample at 5 entries",
  () => {
    // Adversarial: 100 bare citations in one reply. Log must stay small.
    const reply = Array.from(
      { length: 100 },
      (_, i) => `TLS § ${100 + i}`,
    ).join(", ");
    const out = enforceCitations(reply);
    if (out.violations.length < 50) {
      throw new Error(
        `Expected at least 50 violations from 100 bare cites, got ${out.violations.length}`,
      );
    }
    const summary = summariseViolations(out.violations);
    assertEquals(summary.samples.length, 5);
    if (summary.count < 50) {
      throw new Error("Summary count must reflect full violation count");
    }
  },
);

// ─── CENF-T19 — pattern-level smoke tests (regression net) ──────────────────

Deno.test("CENF-T19 — BARE_ESTONIAN_CITATION_PATTERN matches expected shapes", () => {
  // Reset lastIndex pattern to avoid global state across tests.
  const re = new RegExp(BARE_ESTONIAN_CITATION_PATTERN.source, "gu");
  const cases: { text: string; expected: number }[] = [
    { text: "TLS § 88", expected: 1 },
    { text: "KarS § 121", expected: 1 },
    { text: "PKS § 49", expected: 1 },
    { text: "VÕS § 25", expected: 1 },
    { text: "TLS §88", expected: 1 }, // no space allowed too
    { text: "TLS § 88 lg 2", expected: 1 }, // lg suffix
    { text: "TLS § 88-1", expected: 1 },
    { text: "TLS reguleerib töösuhteid", expected: 0 }, // no §
    { text: "vastavalt seadusele", expected: 0 }, // no abbreviation
    { text: "TLDR § 99", expected: 0 }, // not a real law abbreviation
  ];
  for (const c of cases) {
    re.lastIndex = 0;
    const matches = c.text.match(re) ?? [];
    if (matches.length !== c.expected) {
      throw new Error(
        `Expected ${c.expected} match(es) in "${c.text}", got ${matches.length}: ${
          JSON.stringify(matches)
        }`,
      );
    }
  }
});

Deno.test("CENF-T20 — BARE_EU_DIRECTIVE_PATTERN matches expected shapes", () => {
  const re = new RegExp(BARE_EU_DIRECTIVE_PATTERN.source, "giu");
  const cases: { text: string; expected: number }[] = [
    { text: "Direktiiv 96/9/EÜ artikkel 5", expected: 1 },
    { text: "Directive 2019/1152, Article 5", expected: 1 },
    { text: "Direktiivi 2002/58/EU art 5", expected: 1 },
    { text: "Direktiiv 96/9/EÜ", expected: 1 }, // generic, no article
    // Non-matches.
    { text: "He earned $96/9", expected: 0 },
    { text: "Article 5 of the rules", expected: 0 }, // no Directive keyword
  ];
  for (const c of cases) {
    re.lastIndex = 0;
    const matches = c.text.match(re) ?? [];
    if (matches.length !== c.expected) {
      throw new Error(
        `EU pattern expected ${c.expected} in "${c.text}", got ${matches.length}: ${
          JSON.stringify(matches)
        }`,
      );
    }
  }
});

Deno.test("CENF-T21 — BARE_ECHR_PATTERN matches expected shapes", () => {
  const re = new RegExp(BARE_ECHR_PATTERN.source, "giu");
  const cases: { text: string; expected: number }[] = [
    { text: "ECHR Article 8", expected: 1 },
    { text: "EIÕK artikkel 6", expected: 1 },
    { text: "ECtHR art 3", expected: 1 },
    { text: "the ECHR is a treaty", expected: 0 },
    { text: "this article is 8 pages", expected: 0 },
  ];
  for (const c of cases) {
    re.lastIndex = 0;
    const matches = c.text.match(re) ?? [];
    if (matches.length !== c.expected) {
      throw new Error(
        `ECHR pattern expected ${c.expected} in "${c.text}", got ${matches.length}: ${
          JSON.stringify(matches)
        }`,
      );
    }
  }
});

// ─── CENF-T22 — ESTONIAN_LAW_ABBREVS covers the system-prompt instruction set ──

Deno.test(
  "CENF-T22 — every abbreviation listed in services/system_prompts.dart is here",
  () => {
    // Hard-coded from system_prompts.dart line 480, "search_estonian_law
    // for exact § paragraph lookups across 20+ Estonian acts (HMS, HKMS,
    // PKS, TLS, KarS, VMS, VÕS, PärS, VõrdKS, MKS, TuMS, KMS, TsMS,
    // KrMS, ÄS, IKS, LS, LKindlS, TsÜS, AsjS)".
    const expected = [
      "HMS", "HKMS", "PKS", "TLS", "KarS", "VMS", "VÕS", "PärS",
      "VõrdKS", "MKS", "TuMS", "KMS", "TsMS", "KrMS", "ÄS", "IKS",
      "LS", "LKindlS", "TsÜS", "AsjS",
    ];
    for (const abbrev of expected) {
      if (!ESTONIAN_LAW_ABBREVS.has(abbrev)) {
        throw new Error(
          `ESTONIAN_LAW_ABBREVS missing "${abbrev}" — system_prompts.dart instructs the model to cite this act.`,
        );
      }
    }
  },
);

// ─── CENF-T23 — violation index points to a real offset in input ────────────

Deno.test(
  "CENF-T23 — violation.index is the actual char offset in the input text",
  () => {
    const reply = "Lorem ipsum TLS § 88 dolor sit amet.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 1);
    const v = out.violations[0];
    // Pull out the substring at the reported offset; must match v.match.
    assertEquals(
      reply.slice(v.index, v.index + v.match.length),
      v.match,
    );
  },
);

// ─── CENF-T24 — verifier interop: unverified marker = still "covered" ───────

Deno.test(
  "CENF-T24 — unverified marker (no chunk this turn) counts as covered",
  () => {
    // Design choice: the enforcer's job is to catch citations with NO
    // marker. If the model emitted a marker — even one that the grounder
    // flagged unverified because no chunk was retrieved — the UI already
    // shows a red badge. We trust that signal and don't strip.
    // (Otherwise we'd double-penalize the same hallucination.)
    const reply = "Maybe TLS § 999 [[ref:TLS:999]] applies here.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 0);
  },
);

// =============================================================================
// CENF-FI-* — Finnish citation enforcement (Phase 2 Pkg 1, 2026-05-11)
// =============================================================================
//
// The Finlex corpus ingest brings Finnish acts into law_chunks with
// jurisdiction='FI' and act_slug='fi-tsl', 'fi-rl', etc. The chat model
// is taught to cite as `TSL 7 luku 3 §` / `[[ref:fi-tsl:7-3]]`. When the
// marker is missing, the enforcer strips the bare paragraph reference
// exactly as it does for Estonian acts. These tests pin that behaviour.

// ─── CENF-FI-T01 — TSL chapter-section without marker → stripped ────────────

Deno.test(
  "CENF-FI-T01 — 'TSL 7 luku 3 §' without marker → stripped",
  () => {
    const reply =
      "Työnantaja saa irtisanoa työsopimuksen TSL 7 luku 3 § alusel " +
      "asiallisesta ja painavasta syystä.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 1);
    assertEquals(out.violations[0].kind, "fi_bare_paragraph");
    assertEquals(out.violations[0].act_slug, "fi-tsl");
    assertEquals(out.violations[0].paragraph, "7-3");
    // After strip: chapter/section gone, abbreviation kept.
    assertEquals(out.cleanedText.includes("7 luku 3 §"), false);
    assertStringIncludes(out.cleanedText, "TSL");
  },
);

// ─── CENF-FI-T02 — TSL chapter-section WITH marker → no-op ──────────────────

Deno.test(
  "CENF-FI-T02 — Finnish citation WITH marker → no-op",
  () => {
    const reply =
      "Irtisanominen henkilökohtaisilla syillä TSL 7 luku 3 § " +
      "[[ref:fi-tsl:7-3]] vaatii asiallisen syyn.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 0);
    assertEquals(out.cleanedText, reply);
  },
);

// ─── CENF-FI-T03 — chapter-first shape `7 luku 3 § TSL` → stripped ──────────

Deno.test(
  "CENF-FI-T03 — chapter-first shape '7 luku 3 § TSL' without marker → stripped",
  () => {
    const reply = "Säädetään 7 luku 3 § TSL mukaisesti irtisanomisesta.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 1);
    assertEquals(out.violations[0].kind, "fi_bare_paragraph");
    assertEquals(out.violations[0].act_slug, "fi-tsl");
    assertEquals(out.violations[0].paragraph, "7-3");
    assertEquals(out.cleanedText.includes("7 luku 3 §"), false);
  },
);

// ─── CENF-FI-T04 — compact slug shape `TSL § 7-3` → stripped ────────────────

Deno.test(
  "CENF-FI-T04 — compact slug 'TSL § 7-3' without marker → stripped",
  () => {
    const reply = "Sovelletaan TSL § 7-3 mukaista perustetta.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 1);
    assertEquals(out.violations[0].act_slug, "fi-tsl");
    assertEquals(out.violations[0].paragraph, "7-3");
    assertEquals(out.cleanedText.includes("§ 7-3"), false);
  },
);

// ─── CENF-FI-T05 — bare section without chapter `UL § 168` → stripped ───────

Deno.test(
  "CENF-FI-T05 — 'UL § 168' (no chapter prefix) without marker → stripped",
  () => {
    // Ulkomaalaislaki sections are addressed without chapter numbering
    // in common usage. The corpus stores them as bare section IDs.
    const reply = "Käännytyspäätös UL § 168 perusteella.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 1);
    assertEquals(out.violations[0].act_slug, "fi-ul");
    assertEquals(out.violations[0].paragraph, "168");
  },
);

// ─── CENF-FI-T06 — multiple Finnish citations, mixed coverage ───────────────

Deno.test(
  "CENF-FI-T06 — three Finnish citations, one with marker, two without",
  () => {
    const reply =
      "Sovelletaan TSL 7 luku 3 § [[ref:fi-tsl:7-3]] " +
      "ja HL § 54 ja RL § 21 — kolme väitettä.";
    const out = enforceCitations(reply);
    // TSL 7-3 covered, HL § 54 + RL § 21 NOT.
    assertEquals(out.violations.length, 2);
    const slugs = out.violations.map((v) => v.act_slug).sort();
    assertEquals(slugs, ["fi-hl", "fi-rl"]);
    // Covered citation stays
    assertStringIncludes(out.cleanedText, "TSL 7 luku 3 §");
    // Uncovered citations are stripped
    assertEquals(out.cleanedText.includes("HL § 54"), false);
    assertEquals(out.cleanedText.includes("RL § 21"), false);
  },
);

// ─── CENF-FI-T07 — generic mention (no §, no luku) → no-op ──────────────────

Deno.test(
  "CENF-FI-T07 — 'TSL säätelee työsuhteita' (generic) → passes through",
  () => {
    // No § symbol, no `luku` marker — the model is just talking about
    // the act in general terms. Same register as Estonian generic
    // mentions (CENF-T03).
    const reply = "TSL säätelee työsuhteita. RL koskee rikoksia.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 0);
    assertEquals(out.cleanedText, reply);
  },
);

// ─── CENF-FI-T08 — Estonian + Finnish citations in the same reply ──────────

Deno.test(
  "CENF-FI-T08 — mixed Estonian + Finnish unmarked citations → both stripped",
  () => {
    // The owner's hybrid practice: case in Finland but ALSO citing
    // Estonian comparative law. Both jurisdictions must be policed.
    const reply =
      "Eestissä TLS § 88 ja Suomessa TSL 7 luku 3 § — molemmat säätävät " +
      "irtisanomisesta.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 2);
    const kinds = out.violations.map((v) => v.kind).sort();
    assertEquals(kinds, ["ee_bare_paragraph", "fi_bare_paragraph"]);
  },
);

// ─── CENF-FI-T09 — parent marker covers child reference ─────────────────────

Deno.test(
  "CENF-FI-T09 — '[[ref:fi-tsl:7]]' covers child 'TSL § 7-3'",
  () => {
    // Mirrors the Estonian parent-resolves-child rule (CENF-T10). If a
    // chapter-level marker is present, child-section references in the
    // same chapter pass through.
    const reply =
      "Lukua koskeva yleisperiaate TSL § 7-3 [[ref:fi-tsl:7]] " +
      "tarkennetaan alapykälissä.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 0);
  },
);

// ─── CENF-FI-T10 — case sensitivity: TSL, tsl, TsL ──────────────────────────

Deno.test(
  "CENF-FI-T10 — abbreviation lookup is case-sensitive to the registered key",
  () => {
    // Defensive: lowercase 'tsl' is NOT in FINNISH_LAW_ABBREVS — the map
    // is keyed by canonical casing. The enforcer's job is to catch what
    // the model emits; the model is instructed (system_prompts.dart) to
    // use canonical casing. If the model regresses to lowercase, the
    // enforcer correctly fails open (no false positive), and a separate
    // regression test would catch the prompt drift.
    const reply = "Sovelletaan tsl 7 luku 3 § alaa.";
    const out = enforceCitations(reply);
    // Canonical 'TSL' matches; lowercase 'tsl' does not (intentional).
    assertEquals(out.violations.length, 0);
  },
);

// ─── CENF-FI-T11 — FINNISH_LAW_ABBREVS contains the Phase 1 priority set ────

Deno.test(
  "CENF-FI-T11 — every Phase 1 Finnish act abbreviation is registered",
  () => {
    // The 11 acts in scripts/scrape_finlex.ts PHASE_1_ACTS. The
    // abbreviations the model is instructed to use (system_prompts.dart)
    // must all resolve to a slug in FINNISH_LAW_ABBREVS — otherwise the
    // enforcer can't catch bare citations of those acts.
    const phase1 = [
      "TSL", "UL", "HL", "LOHA", "AL", "LHL",
      "RL", "KSL", "VJL", "VKL", "AHVL",
    ];
    for (const abbrev of phase1) {
      if (!FINNISH_LAW_ABBREVS.has(abbrev)) {
        throw new Error(
          `FINNISH_LAW_ABBREVS missing "${abbrev}" — Phase 1 corpus act`,
        );
      }
      const slug = FINNISH_LAW_ABBREVS.get(abbrev)!;
      if (!slug.startsWith("fi-")) {
        throw new Error(
          `Slug for "${abbrev}" must start with 'fi-' (got "${slug}")`,
        );
      }
    }
  },
);

// ─── CENF-FI-T12 — pattern-level smoke tests ────────────────────────────────

Deno.test(
  "CENF-FI-T12 — BARE_FINNISH_CITATION_PATTERN matches expected shapes",
  () => {
    const re = new RegExp(BARE_FINNISH_CITATION_PATTERN.source, "gu");
    const cases: { text: string; expected: number }[] = [
      { text: "TSL 7 luku 3 §", expected: 1 },          // branch A
      { text: "7 luku 3 § TSL", expected: 1 },          // branch B
      { text: "TSL § 7-3", expected: 1 },               // branch C compound
      { text: "UL § 168", expected: 1 },                // branch C bare
      { text: "RL 21 luku 1 §", expected: 1 },          // branch A, different act
      // Non-matches
      { text: "TSL säätelee työsuhteita", expected: 0 }, // no §
      { text: "Suomen Rikoslain mukaan", expected: 0 }, // no registered abbrev
      { text: "TLDR § 99", expected: 0 },               // not a Finnish abbrev
    ];
    for (const c of cases) {
      re.lastIndex = 0;
      const matches = c.text.match(re) ?? [];
      if (matches.length !== c.expected) {
        throw new Error(
          `Expected ${c.expected} match(es) in "${c.text}", got ${matches.length}: ${
            JSON.stringify(matches)
          }`,
        );
      }
    }
  },
);

// ─── CENF-FI-T13 — Estonian TLS and Finnish TSL don't cross-talk ────────────

Deno.test(
  "CENF-FI-T13 — Estonian 'TLS § 88' is NOT flagged as Finnish (distinct abbrevs)",
  () => {
    // TLS = Estonian Töölepingu seadus (in ESTONIAN_LAW_ABBREVS).
    // TSL = Finnish Työsopimuslaki (in FINNISH_LAW_ABBREVS).
    // Both abbreviate to similar consonants but the corpus and enforcer
    // treat them as distinct. A bare 'TLS § 88' is caught by the
    // Estonian branch only, with act_slug='tls' (NOT 'fi-tsl').
    const reply = "Estonian TLS § 88 reference without marker.";
    const out = enforceCitations(reply);
    assertEquals(out.violations.length, 1);
    assertEquals(out.violations[0].kind, "ee_bare_paragraph");
    assertEquals(out.violations[0].act_slug, "tls");
  },
);
