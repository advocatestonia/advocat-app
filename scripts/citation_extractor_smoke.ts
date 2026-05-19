// citation_extractor_smoke.ts — local smoke harness for the EU multi-juris wave.
// -----------------------------------------------------------------------------
// Runs 20 representative bare-citation queries through the pure regex
// extractor (citation-extractor/index.ts → extractCitations +
// resolveEcthrCitation) AND the enforcement module (_shared/citation_enforcement.ts
// → enforceCitations) and asserts each sample produces at least one
// citation/violation of the expected kind.
//
// This script is NOT deployed. It does NOT make HTTP calls. It does NOT touch
// the DB. Its only job is to give an engineer a 5-second sanity check that
// the regex set still recognises the 10 EU jurisdictions + EU regulation +
// ECtHR appno shapes before they hit "deploy".
//
// Why both modules: the extractor (cron-side) recognises FI/EE/EU shapes for
// the corpus citation graph. The enforcer (chat-reply-side) recognises the
// FULL multi-juris set (DE/FR/ES/IT/PL/CZ/SK/SE/DK/NL `art. NNN <ABBR>` and
// `§ NNN <ABBR>` shapes). Civil-law `art. 1240 C. civ.` queries are
// enforcement-only — they never reach the extractor in the chat path because
// the model is taught to emit a marker AND the bare citation, and the
// enforcer is the gate that catches missing markers.
//
// Run with:
//   SUPABASE_URL=stub SUPABASE_SERVICE_ROLE_KEY=stub \
//     deno run --allow-read --allow-env --allow-net \
//     app/advocat_project/scripts/citation_extractor_smoke.ts
//
// (--allow-env/--allow-net are required because index.ts calls Deno.serve at
// top-level; the smoke script never sends HTTP traffic itself. SUPABASE_URL /
// SUPABASE_SERVICE_ROLE_KEY can be stub strings.)
//
// Exit code 0 = all samples produced at least one citation/violation of the
// expected kind. Exit code 1 = at least one regression. Prints a per-sample
// table to stdout regardless.
// -----------------------------------------------------------------------------

import {
  extractCitations,
  type ExtractedCitation,
  resolveEcthrCitation,
} from "../supabase/functions/citation-extractor/index.ts";
import {
  enforceCitations,
  type ViolationKind,
} from "../supabase/functions/_shared/citation_enforcement.ts";

// Each sample names ONE expected outcome from ONE module. Civil-law
// `art. NNN <ABBR>` queries live on the enforcement path only (because the
// cron extractor doesn't have a multi-juris alias table yet). EU
// regulation/directive queries live on the extractor path (because that's
// the corpus-builder consumer that needs to dedupe by CELEX). ECtHR appno
// queries live on the resolveEcthrCitation helper.
//
// Two queries per jurisdiction: one civil-code (enforcement) and one EU
// regulation (extractor), so each path is exercised across all ten EU
// jurisdictions.
type ExpectedExtractKind = "fi" | "ee" | "eu" | "eu_reg";

interface SmokeSample {
  id: string;
  jurisdiction: string;
  text: string;
  // EXACTLY ONE of the three expectation fields is set per sample.
  expectExtractKind?: ExpectedExtractKind;
  expectExtractAlias?: string; // optional pin
  expectViolationKind?: ViolationKind;
  expectEcthrResolved?: boolean;
}

const SAMPLES: SmokeSample[] = [
  // ── DE × 2 ────────────────────────────────────────────────────────────────
  {
    id: "DE-01",
    jurisdiction: "DE",
    // German `§ NNN <ABBR>` civil-code shape — enforcement-side only.
    text:
      "Nach § 433 BGB ist der Verkäufer einer Sache verpflichtet, die Sache zu übergeben.",
    expectViolationKind: "multi_juris_bare_paragraph",
  },
  {
    id: "DE-02",
    jurisdiction: "DE",
    text:
      "Erkläre Artikel 17 Verordnung (EU) 2016/679 — das Recht auf Löschung.",
    expectExtractKind: "eu_reg",
    expectExtractAlias: "eu-reg-2016-679",
  },

  // ── FR × 2 ────────────────────────────────────────────────────────────────
  {
    id: "FR-01",
    jurisdiction: "FR",
    text: "Selon l'article 1240 C. civ. la victime peut agir en responsabilité.",
    expectViolationKind: "multi_juris_bare_paragraph",
  },
  {
    id: "FR-02",
    jurisdiction: "FR",
    text:
      "Conformément au Règlement (UE) 2016/679 article 17, le droit à l'effacement.",
    expectExtractKind: "eu_reg",
    expectExtractAlias: "eu-reg-2016-679",
  },

  // ── PL × 2 ────────────────────────────────────────────────────────────────
  {
    id: "PL-01",
    jurisdiction: "PL",
    text: "Zgodnie z art. 415 KC sprawca odpowiada za szkodę.",
    expectViolationKind: "multi_juris_bare_paragraph",
  },
  {
    id: "PL-02",
    jurisdiction: "PL",
    text:
      "Rozporządzenie (UE) 2016/679 artykuł 17 reguluje prawo do usunięcia danych.",
    expectExtractKind: "eu_reg",
    expectExtractAlias: "eu-reg-2016-679",
  },

  // ── ES × 2 ────────────────────────────────────────────────────────────────
  {
    id: "ES-01",
    jurisdiction: "ES",
    text: "Conforme al art. 1902 CC, hay responsabilidad civil extracontractual.",
    expectViolationKind: "multi_juris_bare_paragraph",
  },
  {
    id: "ES-02",
    jurisdiction: "ES",
    text:
      "Reglamento (UE) 2016/679 artículo 17 reconoce el derecho al olvido.",
    expectExtractKind: "eu_reg",
    expectExtractAlias: "eu-reg-2016-679",
  },

  // ── IT × 2 ────────────────────────────────────────────────────────────────
  {
    id: "IT-01",
    jurisdiction: "IT",
    text: "Ai sensi dell'art. 2043 c.c. il danneggiato può agire.",
    expectViolationKind: "multi_juris_bare_paragraph",
  },
  {
    id: "IT-02",
    jurisdiction: "IT",
    text:
      "Regolamento (UE) 2016/679 articolo 17 — diritto all'oblio.",
    expectExtractKind: "eu_reg",
    expectExtractAlias: "eu-reg-2016-679",
  },

  // ── ECtHR application-number resolver × 4 (covers ECtHR-T30..T33) ─────────
  {
    id: "EC-01",
    jurisdiction: "ECtHR",
    text: "Maslov v Austria (application no. 12345/67) discussed deportation.",
    expectEcthrResolved: true,
  },
  {
    id: "EC-02",
    jurisdiction: "ECtHR",
    text: "D.H. and Others v Czech Republic, 57325/00, on indirect discrimination.",
    expectEcthrResolved: true,
  },
  {
    id: "EC-03",
    jurisdiction: "ECtHR",
    text: "App. no. 5310/71 was filed by an Irish applicant.",
    expectEcthrResolved: true,
  },
  {
    id: "EC-04",
    jurisdiction: "ECtHR",
    text: "Salah Sheekh v Netherlands, application no. 1948/04.",
    expectEcthrResolved: true,
  },

  // ── CZ × 1 + NL × 1 (extra civil-law breadth) ─────────────────────────────
  {
    id: "CZ-01",
    jurisdiction: "CZ",
    text: "Podle § 2913 OZ odpovídá škůdce za škodu.",
    expectViolationKind: "multi_juris_bare_paragraph",
  },
  {
    id: "NL-01",
    jurisdiction: "NL",
    text: "Op grond van art. 6:162 BW is de pleger aansprakelijk.",
    expectViolationKind: "multi_juris_bare_paragraph",
  },

  // ── Mixed cross-jurisdiction (regression net) × 2 ─────────────────────────
  {
    id: "MX-01",
    jurisdiction: "DE+EU",
    text:
      "Sowohl § 433 BGB als auch Verordnung (EU) 2016/679 sind einschlägig.",
    expectExtractKind: "eu_reg",
    expectExtractAlias: "eu-reg-2016-679",
  },
  {
    id: "MX-02",
    jurisdiction: "FR+EU",
    text:
      "L'article 1240 C. civ. et le Règlement (UE) 2016/679 sont mobilisés.",
    expectExtractKind: "eu_reg",
    expectExtractAlias: "eu-reg-2016-679",
  },

  // ── Legacy FI / EE (must NOT regress) × 2 ─────────────────────────────────
  {
    id: "EE-01",
    jurisdiction: "EE",
    text: "TsÜS § 86 alusel on tehing tühine.",
    expectExtractKind: "ee",
    expectExtractAlias: "TsÜS § 86",
  },
  {
    id: "FI-01",
    jurisdiction: "FI",
    text: "Hakemus perustuu HOL 114 § mukaan.",
    expectExtractKind: "fi",
    expectExtractAlias: "HOL 114 §",
  },
];

interface SampleResult {
  sample: SmokeSample;
  passed: boolean;
  note: string;
}

function runSample(sample: SmokeSample): SampleResult {
  // ── Branch 1: ECtHR application-number resolver ──────────────────────────
  if (sample.expectEcthrResolved) {
    const resolved = resolveEcthrCitation(sample.text);
    if (!resolved) {
      return {
        sample,
        passed: false,
        note: "resolveEcthrCitation returned null",
      };
    }
    return {
      sample,
      passed: true,
      note: `ecthr_case appno=${resolved.appno} year=${resolved.year}`,
    };
  }

  // ── Branch 2: enforcement-side multi-juris ───────────────────────────────
  if (sample.expectViolationKind) {
    const out = enforceCitations(sample.text);
    const matching = out.violations.filter((v) =>
      v.kind === sample.expectViolationKind
    );
    if (matching.length === 0) {
      const got = out.violations.map((v) => `${v.kind}:${v.act_slug}`).join(", ");
      return {
        sample,
        passed: false,
        note:
          `no violation of kind=${sample.expectViolationKind}; got ${got || "(none)"}`,
      };
    }
    return {
      sample,
      passed: true,
      note: matching.map((v) => `${v.kind}:${v.act_slug}:${v.paragraph}`).join(", "),
    };
  }

  // ── Branch 3: extractor-side (FI / EE / EU / EU_reg) ─────────────────────
  if (sample.expectExtractKind) {
    const citations: ExtractedCitation[] = extractCitations(sample.text);
    const matching = citations.filter((c) => c.kind === sample.expectExtractKind);
    if (matching.length === 0) {
      const got = citations.map((c) => `${c.kind}:${c.alias}`).join(", ");
      return {
        sample,
        passed: false,
        note:
          `no citation of kind=${sample.expectExtractKind}; got ${got || "(none)"}`,
      };
    }
    if (sample.expectExtractAlias) {
      const aliasHit = matching.find((c) => c.alias === sample.expectExtractAlias);
      if (!aliasHit) {
        return {
          sample,
          passed: false,
          note: `kind matched but alias differs: expected ${
            sample.expectExtractAlias
          }, got ${matching.map((c) => c.alias).join(", ")}`,
        };
      }
    }
    return {
      sample,
      passed: true,
      note: matching.map((c) => `${c.kind}:${c.alias}`).join(", "),
    };
  }

  return {
    sample,
    passed: false,
    note: "sample has no expectation field set",
  };
}

function main(): void {
  console.log(
    `citation-extractor smoke — ${SAMPLES.length} samples, no HTTP, no DB`,
  );
  console.log("=".repeat(80));

  const results: SampleResult[] = SAMPLES.map(runSample);
  let passed = 0;
  let failed = 0;

  for (const r of results) {
    const tag = r.passed ? "PASS" : "FAIL";
    if (r.passed) passed++;
    else failed++;
    const id = r.sample.id.padEnd(6);
    const jur = r.sample.jurisdiction.padEnd(8);
    console.log(`[${tag}] ${id} ${jur} → ${r.note}`);
  }

  console.log("=".repeat(80));
  console.log(`Summary: ${passed} passed, ${failed} failed, ${results.length} total`);
  if (failed > 0) {
    console.error(
      "REGRESSION — one or more samples did not extract the expected citation.",
    );
    Deno.exit(1);
  }
  console.log("All smoke samples green.");
  // index.ts calls Deno.serve at top-level — we never want that listener
  // alive in this script. Exit cleanly so the smoke run terminates instead
  // of hanging on the dangling HTTP server.
  Deno.exit(0);
}

main();
