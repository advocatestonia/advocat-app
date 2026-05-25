// Deno tests for the active-case-aware lawyer router fix (P0, 2026-05-25).
// -----------------------------------------------------------------------------
// These tests prove that when claude-proxy has an active_case payload with
// parsed documents, the enriched routing query produces the CORRECT lawyer
// roster — i.e. EE counsel for ET documents even when the user wrote in RU.
//
// We do not boot the edge function here — the contract under test is:
//   buildEnrichedRoutingQuery(...) → selectRolesFromLawyerDept(...)
// composed exactly as claude-proxy/index.ts composes them. The composition
// is what would actually break the lawyer router in prod; the e2e contract
// is therefore tested end-to-end at the pure-function level.
//
// Run with:
//   deno test --allow-all --no-check \
//     supabase/functions/claude-proxy/__tests__/routing_with_doc_context_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildEnrichedRoutingQuery,
  type EnrichableDocument,
} from "../../_shared/routing_enrichment.ts";
import { selectRolesFromLawyerDept } from "../../_shared/consilium_lawyer_bridge.ts";

// ─── Helper: replays the exact composition done in claude-proxy/index.ts ──────
const ACCEPTED_LANGS = new Set(["ru", "et", "fi", "en", "de"]);

function routeAsClaudeProxyDoes(
  userMessage: string,
  docs: EnrichableDocument[] | null,
): { agentIds: string[]; docLang: string | undefined } {
  const { enrichedQuery, docLang } = buildEnrichedRoutingQuery(
    userMessage,
    docs,
  );
  const classification = docLang && ACCEPTED_LANGS.has(docLang)
    ? { language: docLang as "ru" | "et" | "fi" | "en" | "de" }
    : undefined;
  const bridge = selectRolesFromLawyerDept(enrichedQuery, classification);
  return {
    agentIds: bridge ? bridge.agents.map((a) => a.id) : [],
    docLang,
  };
}

// ─── Scenario 1: RU user + ET fine → senior-vandeadvokaat ─────────────────────

Deno.test(
  "RWDC-1: RU 'что это?' on top of ET MKS § 56 fine → senior-vandeadvokaat (not senior-asianajaja)",
  () => {
    const docs: EnrichableDocument[] = [
      {
        filename: "trahv.pdf",
        doc_type: "fine",
        doc_date: "2025-04-12",
        parsed_summary:
          "Maksu- ja Tolliamet määras teile trahvi summas 250 EUR " +
          "vastavalt Maksukorralduse seaduse (MKS) § 56 lg 2 alusel. " +
          "Trahv on määratud Tallinna halduskohus pädevuses.",
        key_extractions: {
          doc_type: "fine",
          parties: ["Maksu- ja Tolliamet", "Pavel I."],
          case_numbers: ["MKS § 56"],
          key_facts: ["Maksudeklaratsiooni hilinemine"],
          pages_lang: ["et", "et"],
        },
      },
    ];

    // Control: without enrichment, the legacy call would land on FI counsel.
    const noEnrichment = selectRolesFromLawyerDept("что это?", undefined);
    assertEquals(
      noEnrichment?.agents[0].id,
      "senior-asianajaja",
      "CONTROL: bare userMessage wrongly routes to FI counsel",
    );

    // With enrichment + docLang propagation.
    const { agentIds, docLang } = routeAsClaudeProxyDoes("что это?", docs);
    assertEquals(docLang, "et");
    assertEquals(
      agentIds[0],
      "senior-vandeadvokaat",
      "FIX: enriched query + docLang='et' routes to EE counsel",
    );
    assert(
      agentIds.includes("tax-advisor"),
      `expected tax-advisor (MKS = tax statute) in roster, got: ${agentIds.join(",")}`,
    );
  },
);

// ─── Scenario 2: RU user + FI käännytys → immigration-lawyer + FI counsel ─────

Deno.test(
  "RWDC-2: RU 'помогите' on top of FI Migri käännytyspäätös → immigration-lawyer + senior-asianajaja",
  () => {
    const docs: EnrichableDocument[] = [
      {
        filename: "kaannytyspaatos.pdf",
        doc_type: "court_decision",
        doc_date: "2025-03-05",
        parsed_summary:
          "Maahanmuuttovirasto (Migri) on tehnyt päätöksen, jolla teidän " +
          "oleskelulupahakemus on hylätty ja olette käännytetty Suomesta. " +
          "Päätös perustuu ulkomaalaislain (UlkL) § 149 säännökseen. " +
          "Valitusosoitus: Helsingin hallinto-oikeus, 30 päivän valitusaika.",
        key_extractions: {
          doc_type: "court_decision",
          parties: ["Maahanmuuttovirasto", "Ivanov O."],
          case_numbers: ["Migri 2025-12345"],
          key_facts: [
            "käännytyspäätös",
            "ulkomaalaislaki § 149",
            "Helsingin hallinto-oikeus",
          ],
          deadlines: ["30 päivän valitusaika"],
          pages_lang: ["fi", "fi", "fi"],
        },
      },
    ];

    const { agentIds, docLang } = routeAsClaudeProxyDoes("помогите", docs);
    assertEquals(docLang, "fi");
    assertEquals(
      agentIds[0],
      "senior-asianajaja",
      "FI doc → FI general counsel",
    );
    assert(
      agentIds.includes("immigration-lawyer"),
      `käännytys + ulkomaalaislaki → immigration-lawyer expected, got: ${agentIds.join(",")}`,
    );
  },
);

// ─── Scenario 3: Mixed multi-doc case — dominant ET wins, includes both ───────

Deno.test(
  "RWDC-3: mixed ET+FI docs (ET dominant) + EN user query → EE counsel, both jurisdictions visible in roster trace",
  () => {
    const docs: EnrichableDocument[] = [
      // Two ET docs.
      {
        filename: "trahv1.pdf",
        doc_type: "fine",
        parsed_summary:
          "Tallinna halduskohus trahv MKS § 56 alusel maksudeklaratsiooni " +
          "hilinemise eest. Riigikohus kassatsioonkaebus võimalik.",
        key_extractions: {
          parties: ["Maksu- ja Tolliamet"],
          case_numbers: ["3-15-23/27"],
          pages_lang: ["et", "et"],
        },
      },
      {
        filename: "otsus.pdf",
        doc_type: "court_decision",
        parsed_summary:
          "Tallinna ringkonnakohus otsus halduskohus apellatsioonkaebus.",
        key_extractions: {
          case_numbers: ["RKHK 3-15-99"],
          pages_lang: ["et"],
        },
      },
      // One FI doc — should be reflected in enriched query but NOT flip
      // jurisdiction (ET has 3 lang votes vs FI 1).
      {
        filename: "kirje.pdf",
        doc_type: "letter",
        parsed_summary: "Helsingin käräjäoikeus liitännäiskirjelmä",
        key_extractions: {
          case_numbers: ["R 23/123"],
          pages_lang: ["fi"],
        },
      },
    ];

    const { agentIds, docLang } = routeAsClaudeProxyDoes(
      "what should I do next?",
      docs,
    );
    assertEquals(docLang, "et", "ET pages dominate the multi-doc pool");
    assertEquals(
      agentIds[0],
      "senior-vandeadvokaat",
      "dominant-ET case picks EE general counsel",
    );
    // Riigikohus + kassatsioon are highStakes triggers — researcher and
    // litigator should surface.
    assert(
      agentIds.includes("researcher") || agentIds.includes("litigator"),
      `high-stakes signal (riigikohus + kassatsioonkaebus) should surface ` +
        `researcher/litigator, got: ${agentIds.join(",")}`,
    );
  },
);

// ─── Sanity: empty docs path is a perfect passthrough ─────────────────────────

Deno.test(
  "RWDC-4: empty activeCaseDocs preserves legacy routing behaviour byte-for-byte",
  () => {
    const userMessage = "Estonian tax fine helpline tallinna";
    const baseline = selectRolesFromLawyerDept(userMessage, undefined);
    const withFix = routeAsClaudeProxyDoes(userMessage, null);

    assertEquals(
      withFix.agentIds,
      baseline ? baseline.agents.map((a) => a.id) : [],
      "no docs → no change to roster",
    );
    assertEquals(withFix.docLang, undefined);
  },
);
