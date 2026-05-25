// Deno tests for routing_enrichment.ts
// -----------------------------------------------------------------------------
// Pure-module contract tests. No network, no env.
//
// Run with:
//   deno test --allow-all --no-check \
//     supabase/functions/_shared/__tests__/routing_enrichment_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildEnrichedRoutingQuery,
  type EnrichableDocument,
  MAX_BLOCK_CHARS,
  MAX_SUMMARY_CHARS,
  TOP_DOC_LIMIT,
} from "../routing_enrichment.ts";
import { routeToLawyers } from "../lawyer_router.ts";

// ─── 1. Empty / null cases — always passthrough ───────────────────────────────

Deno.test("RE-1: null docs → returns userMessage unchanged, docLang undefined", () => {
  const result = buildEnrichedRoutingQuery("что это?", null);
  assertEquals(result.enrichedQuery, "что это?");
  assertEquals(result.docLang, undefined);
});

Deno.test("RE-1b: empty array → returns userMessage unchanged", () => {
  const result = buildEnrichedRoutingQuery("explain please", []);
  assertEquals(result.enrichedQuery, "explain please");
  assertEquals(result.docLang, undefined);
});

Deno.test("RE-1c: docs with no extractable signal → passthrough but keep pages_lang", () => {
  // Doc has pages_lang but everything else is empty — block emits nothing
  // (we skip a doc when only the head line would render) but docLang still
  // tallies pages_lang.
  const docs: EnrichableDocument[] = [
    {
      filename: "scan.pdf",
      key_extractions: { pages_lang: ["et", "et"] },
    },
  ];
  const result = buildEnrichedRoutingQuery("?", docs);
  assertEquals(result.enrichedQuery, "?");
  assertEquals(result.docLang, "et");
});

// ─── 2. Single Estonian document — happy path ─────────────────────────────────

Deno.test("RE-2: single ET document → enriched query contains ET cite + doc_lang='et'", () => {
  const docs: EnrichableDocument[] = [
    {
      filename: "trahv.pdf",
      doc_type: "fine",
      doc_date: "2025-04-12",
      parsed_summary:
        "Maksu- ja Tolliamet määras trahvi vastavalt MKS § 56 lg 2 alusel summas 250 EUR.",
      key_extractions: {
        doc_type: "fine",
        parties: ["Maksu- ja Tolliamet", "Pavel I."],
        case_numbers: ["MKS § 56"],
        key_facts: ["Maksudeklaratsiooni hilinemine"],
        pages_lang: ["et", "et", "et"],
      },
    },
  ];
  const result = buildEnrichedRoutingQuery("что это?", docs);
  assertStringIncludes(result.enrichedQuery, "что это?");
  assertStringIncludes(result.enrichedQuery, "[Active document context]");
  assertStringIncludes(result.enrichedQuery, "MKS § 56");
  assertStringIncludes(result.enrichedQuery, "Maksu- ja Tolliamet");
  assertEquals(result.docLang, "et");
});

// ─── 3. Multi-doc, mixed languages ─────────────────────────────────────────────

Deno.test("RE-3: multi-doc with mixed langs → dominant lang + concat'd cites", () => {
  // Two ET docs + one FI doc → dominant = et.
  const docs: EnrichableDocument[] = [
    {
      filename: "trahv1.pdf",
      doc_type: "fine",
      parsed_summary: "MKS § 56 trahv Tallinna kohus",
      key_extractions: {
        case_numbers: ["MKS § 56"],
        pages_lang: ["et", "et"],
      },
    },
    {
      filename: "trahv2.pdf",
      doc_type: "decision",
      parsed_summary: "Riigikohtu otsus halduskohus",
      key_extractions: {
        case_numbers: ["3-15-23/27"],
        pages_lang: ["et"],
      },
    },
    {
      filename: "kirje.pdf",
      doc_type: "letter",
      parsed_summary: "Helsingin käräjäoikeus",
      key_extractions: {
        case_numbers: ["R 23/123"],
        pages_lang: ["fi"],
      },
    },
  ];
  const result = buildEnrichedRoutingQuery("помогите", docs);
  assertEquals(result.docLang, "et"); // ET 3 votes vs FI 1 vote
  assertStringIncludes(result.enrichedQuery, "MKS § 56");
  assertStringIncludes(result.enrichedQuery, "3-15-23/27");
  // FI doc still appears since blocks are concatenated up to MAX_BLOCK_CHARS.
  assertStringIncludes(result.enrichedQuery, "Helsingin");
});

// ─── 4. The P0 reproducer — RU user + ET fine → senior-vandeadvokaat ──────────

Deno.test(
  "RE-4: RU user + ET fine → enriched routing picks senior-vandeadvokaat (was senior-asianajaja before fix)",
  () => {
    const docs: EnrichableDocument[] = [
      {
        filename: "trahv.pdf",
        doc_type: "fine",
        parsed_summary:
          "Maksu- ja Tolliamet määras trahvi MKS § 56 alusel Tallinna haldus­kohus",
        key_extractions: {
          parties: ["Maksu- ja Tolliamet"],
          case_numbers: ["MKS § 56"],
          pages_lang: ["et", "et"],
        },
      },
    ];

    // BEFORE fix: routing on just "что это?" sees no FI/EE keyword → falls
    // through to the language hint (lang="ru"), then the keyword tally
    // (fiHits=0, eeHits=0), which defaults to senior-asianajaja.
    const beforeResult = routeToLawyers("что это?", "ru");
    const beforeGeneral = beforeResult.agents[0].id;
    assertEquals(
      beforeGeneral,
      "senior-asianajaja",
      "BEFORE: bare 'что это?' wrongly routes to FI counsel",
    );

    // AFTER fix: enriched query contains "tallinna" + "maksu- ja tolliamet"
    // (both lowercased they match EE keyword set: "tallinna" hits, "maksu-"
    // doesn't but "halduskohus" does).
    const { enrichedQuery, docLang } = buildEnrichedRoutingQuery(
      "что это?",
      docs,
    );
    assertEquals(docLang, "et");
    const afterResult = routeToLawyers("что это?", "ru", undefined);
    // Routing with just lang="ru" still wrong — confirm enrichment fixes it
    // when we instead pass the enriched text:
    const fixedResult = routeToLawyers(enrichedQuery, "ru");
    const afterGeneral = fixedResult.agents[0].id;
    assertEquals(
      afterGeneral,
      "senior-vandeadvokaat",
      "AFTER: enriched query routes to EE counsel because 'tallinna' / 'halduskohus' / 'eesti' surface in the doc context",
    );
    // Sanity — un-enriched call still wrong:
    assertEquals(afterResult.agents[0].id, "senior-asianajaja");
  },
);

// ─── 5. UA user + FI käännytys → immigration_lawyer + FI doc_lang ─────────────

Deno.test(
  "RE-5: UA user + FI käännytys document → routes to immigration-lawyer + senior-asianajaja",
  () => {
    const docs: EnrichableDocument[] = [
      {
        filename: "kaannytys.pdf",
        doc_type: "court_decision",
        parsed_summary:
          "Helsingin hallinto-oikeus käännytyspäätös ulkomaalaislaki Maahanmuuttovirasto Migri",
        key_extractions: {
          parties: ["Maahanmuuttovirasto", "Ivanov O."],
          case_numbers: ["KHO 2025:123"],
          key_facts: ["Karkotus käännytys ulkomaalaislaki § 149"],
          pages_lang: ["fi", "fi", "fi"],
        },
      },
    ];

    // BEFORE: bare UA "що це?" — no FI signal → defaults to vandeadvokaat
    // because Ukrainian has no FI/EE keyword in our list.
    // (Note: lawyer_router doesn't support 'uk', so we use 'ru' as the
    // best-available proxy — the lang parameter is typed as the
    // CaseContext language enum.)

    const { enrichedQuery, docLang } = buildEnrichedRoutingQuery(
      "що це?",
      docs,
    );
    assertEquals(docLang, "fi");

    // After enrichment, the regex/keyword scan sees "Migri" /
    // "ulkomaalaislaki" / "kho" / "kaannytys" / "Helsingin" — all FI
    // signals — and "käännytys" + "ulkomaalaislaki" match
    // immigration-lawyer trigger keywords too.
    const fixedResult = routeToLawyers(enrichedQuery, "ru");
    const ids = fixedResult.agents.map((a) => a.id);
    assertEquals(
      ids[0],
      "senior-asianajaja",
      "general counsel resolves to FI",
    );
    assert(
      ids.includes("immigration-lawyer"),
      `immigration-lawyer expected in roster, got: ${ids.join(",")}`,
    );
  },
);

// ─── 6. Caps & defence ────────────────────────────────────────────────────────

Deno.test("RE-6: case with 5+ docs → caps at TOP_DOC_LIMIT=3 to avoid prompt bloat", () => {
  const docs: EnrichableDocument[] = Array.from({ length: 7 }, (_, i) => ({
    filename: `doc${i}.pdf`,
    doc_type: "evidence",
    parsed_summary: `Tallinna ringkonnakohus doc ${i}`,
    key_extractions: {
      case_numbers: [`CASE-${i}`],
      pages_lang: ["et"],
    },
  }));
  const result = buildEnrichedRoutingQuery("?", docs);
  assertEquals(TOP_DOC_LIMIT, 3);
  assertStringIncludes(result.enrichedQuery, "CASE-0");
  assertStringIncludes(result.enrichedQuery, "CASE-1");
  assertStringIncludes(result.enrichedQuery, "CASE-2");
  // Doc 3+ MUST be absent.
  assert(
    !result.enrichedQuery.includes("CASE-3"),
    "TOP_DOC_LIMIT must clip docs beyond index 2",
  );
  assert(
    !result.enrichedQuery.includes("CASE-6"),
    "TOP_DOC_LIMIT must clip the tail",
  );
});

// ─── 7. Truncation guards ─────────────────────────────────────────────────────

Deno.test("RE-7: oversized parsed_summary truncated to MAX_SUMMARY_CHARS", () => {
  const longSummary = "A".repeat(5_000) + " riigikohus";
  const docs: EnrichableDocument[] = [
    {
      filename: "big.pdf",
      doc_type: "evidence",
      parsed_summary: longSummary,
      key_extractions: { pages_lang: ["et"] },
    },
  ];
  const result = buildEnrichedRoutingQuery("?", docs);
  // The whole block must be smaller than MAX_BLOCK_CHARS, and the summary
  // line specifically must be truncated.
  assert(
    result.enrichedQuery.length < MAX_BLOCK_CHARS + 100,
    "enrichedQuery exceeds the block cap budget",
  );
  // The truncation indicator should appear (we use "…").
  assertStringIncludes(result.enrichedQuery, "…");
  // The trailing 'riigikohus' was past the cap → must NOT survive.
  assert(
    !result.enrichedQuery.includes("riigikohus"),
    "summary tail must be dropped by truncation",
  );
  // MAX_SUMMARY_CHARS is the unit we trust:
  assertEquals(MAX_SUMMARY_CHARS, 500);
});

// ─── 8. Malformed payloads — never throws ─────────────────────────────────────

Deno.test("RE-8: malformed key_extractions does not throw, falls through safely", () => {
  const docs: EnrichableDocument[] = [
    // deno-lint-ignore no-explicit-any
    { filename: "weird.pdf", key_extractions: 42 as any },
    // deno-lint-ignore no-explicit-any
    { filename: "weird2.pdf", key_extractions: "not-json" as any },
    {
      filename: "ok.pdf",
      parsed_summary: "Tallinna halduskohus MKS § 56",
      key_extractions: { pages_lang: ["et"] },
    },
  ];
  const result = buildEnrichedRoutingQuery("hello", docs);
  // The malformed ones contribute nothing; the good one still renders.
  assertStringIncludes(result.enrichedQuery, "Tallinna halduskohus");
  assertEquals(result.docLang, "et");
});

// ─── 9. userMessage type guard ────────────────────────────────────────────────

Deno.test("RE-9: non-string userMessage handled safely", () => {
  // deno-lint-ignore no-explicit-any
  const result = buildEnrichedRoutingQuery(undefined as any, null);
  assertEquals(result.enrichedQuery, "");
  assertEquals(result.docLang, undefined);
});
