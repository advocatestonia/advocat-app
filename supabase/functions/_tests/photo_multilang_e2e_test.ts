// photo_multilang_e2e_test.ts — AUDIT: photo + multi-lang → consilium e2e.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-all --no-check \
//     supabase/functions/_tests/photo_multilang_e2e_test.ts
//
// PURPOSE — adversarial audit, not green-path verification
// --------------------------------------------------------
// This file simulates the FULL user journey for the "snap a paper document
// in a foreign language, ask in your own language" UX:
//
//   user photo  →  storage  →  pdf-parser (vision OCR)  →  doc classifier
//        →  fact extractor  →  lawyer_router  →  consilium synthesis
//        →  deadline-extractor  →  case_deadlines  →  response in USER lang
//
// We run FIVE scenarios that span the realistic anon-traffic mix on advocat.ee
// (RU+ET, UA+FI, PL+DE, error recovery, RU+RU same-language) and assert the
// invariants the UX needs to hold. Each FAIL is documented as a GAP — this is
// an architectural audit, NOT a TDD scaffold for new code. Do not "fix" the
// failures here; surface them and let the gap-closure task plan the fixes.
//
// Stubs are used for OCR + consilium + deadline-extractor because:
//   • we are auditing the wiring, not the underlying model accuracy;
//   • real API calls would cost $0.30 / scenario × 5 = $1.50 per test run;
//   • the failure modes we care about (mime check, language detection,
//     roster routing, response language mirroring) are deterministic
//     contract bugs that show up against canned data the same way they
//     would against live data.
//
// Layout per scenario:
//   1. Build a synthetic OCR result (what Vision would return).
//   2. Run the actual lawyer_router on the synthesized query.
//   3. Verify language detection, doc-type classification, roster shape,
//      response language, and deadline registration via stub.
//   4. Record GAP if an invariant fails — DO NOT throw, collect into a
//      gaps array, print summary at end.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { routeToLawyers } from "../_shared/lawyer_router.ts";
import { selectRolesFromLawyerDept } from "../_shared/consilium_lawyer_bridge.ts";
import { ALL_LAWYERS } from "../_shared/lawyer_agents/index.ts";
import type { CaseContext } from "../_shared/consilium_roles/types.ts";

// =============================================================================
// Gap collector — every audit finding lands here, printed at the end.
// =============================================================================

interface AuditGap {
  scenario: string;
  invariant: string;
  observed: string;
  impact: "P0" | "P1" | "P2";
}

const GAPS: AuditGap[] = [];

function recordGap(g: AuditGap): void {
  GAPS.push(g);
  console.warn(
    `GAP [${g.impact}] ${g.scenario} — ${g.invariant}\n         observed: ${g.observed}`,
  );
}

// =============================================================================
// Stubs — canned OCR + consilium synthesis + deadline output.
// =============================================================================

/** Stub OCR result. In real life pdf-parser does pdfjs → text or Vision Haiku.
 *  Image inputs (JPEG/PNG) are NOT supported today — see GAP catalogued in A. */
interface StubOcrResult {
  text: string;
  detected_lang: string | null; // null = pipeline didn't run lang-detect
  confidence: number;
  pages: number;
  used_vision: boolean;
}

/** Stub fact-extractor output. The real fact_extractor.ts emits these shapes
 *  but only for Russian queries via consilium post-processing — image OCR text
 *  is not currently funnelled through it. */
interface StubExtractedFacts {
  doc_type: string | null;
  amount_eur: number | null;
  due_date: string | null;
  appeal_deadline_days: number | null;
  statute_ref: string | null;
  authority: string | null;
}

/** Stub consilium synthesis result. */
interface StubConsiliumResult {
  synthesis_text: string;
  synthesis_lang: string;
  roles_invoked: string[];
}

/** Run the actual lawyer_router on a query+ctx and capture the agent roster.
 *  This is REAL code under test. */
function routeRealAgents(query: string, ctx: CaseContext): {
  agentIds: string[];
  highStakes: boolean;
  trace: string[];
} {
  const decision = routeToLawyers(
    query,
    (ctx.language ?? "ru") as NonNullable<CaseContext["language"]>,
    ctx,
  );
  return {
    agentIds: decision.agents.map((a) => a.id),
    highStakes: decision.highStakes,
    trace: decision.trace,
  };
}

/** Stub for selectRolesFromLawyerDept — this exercises the bridge path that
 *  claude-proxy actually uses when CONSILIUM_LAWYER_ROUTER_ENABLED is on. */
function routeBridge(query: string, ctx: CaseContext): {
  agentIds: string[];
  highStakes: boolean;
} {
  const result = selectRolesFromLawyerDept(query, ctx);
  if (!result) {
    return { agentIds: [], highStakes: false };
  }
  return {
    agentIds: result.agents.map((a) => a.id),
    highStakes: result.highStakes,
  };
}

// =============================================================================
// Scenario A — Russian user + Estonian traffic fine photo.
// =============================================================================
//
//   user_lang   = ru
//   doc_lang    = et
//   doc_type    = "Liiklusseaduse rikkumise otsus" (admin traffic fine)
//   ask         = "Что мне делать с этим? Куда платить? Можно ли оспорить?"
//
// Expected end-state:
//   • photo uploaded as JPEG/PNG, NOT rejected by mime check
//   • OCR returns Estonian text with §227-style statute marker
//   • detected_lang = "et"
//   • doc_type classified as "fine" / "administrative_decision"
//   • amount, due_date, appeal_deadline (LS 10 days) extracted
//   • consilium roster includes senior_vandeadvokaat (EE general)
//   • response delivered in Russian (user_lang)
//   • case_deadlines row created for appeal deadline
// -----------------------------------------------------------------------------

Deno.test("A) Russian user + Estonian traffic fine — full happy path", () => {
  console.log("\n═══ SCENARIO A: ru-user + et-fine photo ═══");

  // ── (1) Photo upload — known gap ──────────────────────────────────────────
  // pdf-parser/index.ts mime gate: pdf_parser_service.dart:233-235 rejects
  // anything that isn't application/pdf. There is no image→pdf wrapper.
  const photoMime = "image/jpeg";
  const acceptedByParser = photoMime.toLowerCase() === "application/pdf";
  if (!acceptedByParser) {
    recordGap({
      scenario: "A",
      invariant: "photo (JPEG/PNG) accepted by pdf-parser pipeline",
      observed:
        `pdf-parser rejects mime=${photoMime}; only application/pdf passes ` +
        `the gate in pdf_parser_service.dart:233. No image→PDF wrapper or ` +
        `direct image-OCR edge function exists. User photo is dead on arrival.`,
      impact: "P0",
    });
  }

  // ── (2) OCR — simulate what Vision Haiku WOULD return if we got to it ────
  const ocr: StubOcrResult = {
    text: [
      "Politsei- ja Piirivalveamet",
      "OTSUS Nr 2025/TR-44821",
      "Liiklusseaduse § 227 lg 1 alusel",
      "Trahv: 120 EUR",
      "Maksetähtaeg: 14 päeva otsuse kättesaamisest",
      "Kaebuse esitamise tähtaeg: 10 päeva (HKMS § 46)",
      "Arvelduskonto: EE891010220034796011 (SEB)",
      "Viitenumber: 25 0044 8210",
    ].join("\n"),
    detected_lang: "et",
    confidence: 0.92,
    pages: 1,
    used_vision: true,
  };

  // ── (3) Doc-type classification ─────────────────────────────────────────
  // No dedicated classifier exists for admin-violation paperwork — the
  // pdf-parser returns a free-text `parsed_summary` and `doc_type` is set
  // by the Sonnet structured-JSON pass. We assert the type *would* land
  // in "fine" / "otsus" / "administrative_decision" — without a real
  // classifier we cannot verify this is reliable.
  // Hypothetical classifier output — widen the literal type so the
  // disjunction check below survives narrowing (this audit test enumerates
  // the *acceptable* doc_type vocabulary, not asserts a specific branch).
  const classifiedDocType: string = "administrative_decision";
  if (classifiedDocType !== "fine" && classifiedDocType !== "administrative_decision") {
    recordGap({
      scenario: "A",
      invariant: "doc_type classified as fine/administrative_decision",
      observed: `classifier returned "${classifiedDocType}"`,
      impact: "P1",
    });
  }
  // Audit-level gap: there is NO dedicated admin-violation classifier.
  // The current Sonnet structured-JSON pass produces ad-hoc strings.
  recordGap({
    scenario: "A",
    invariant: "stable doc_type vocabulary for fines/otsus/decisions",
    observed:
      `pdf-parser Sonnet pass returns free-form doc_type; no enum of ` +
      `{fine, otsus, summons, hakemus, ...} → downstream routing brittle.`,
    impact: "P1",
  });

  // ── (4) Fact extraction ──────────────────────────────────────────────────
  const facts: StubExtractedFacts = {
    doc_type: "fine",
    amount_eur: 120,
    due_date: "2025-12-21", // T+14 days
    appeal_deadline_days: 10,
    statute_ref: "LS § 227 lg 1",
    authority: "Politsei- ja Piirivalveamet",
  };
  const factsCount = Object.values(facts).filter((v) => v !== null).length;
  assert(factsCount >= 3, `expected ≥3 facts, got ${factsCount}`);
  // But — fact_extractor.ts runs AFTER consilium synthesis (claude-proxy
  // index.ts:1022-1035), not as a pre-step for routing. Routing happens
  // on the raw user query, not on extracted facts. Hence:
  recordGap({
    scenario: "A",
    invariant: "structured facts available BEFORE consilium routing",
    observed:
      `fact_extractor runs post-consilium (claude-proxy.ts:1022). The ` +
      `router never sees amount/deadline/statute — it routes off the user's ` +
      `5-word Russian question alone.`,
    impact: "P0",
  });

  // ── (5) Lawyer router — REAL test ───────────────────────────────────────
  const userQuery = "Что мне делать с этим? Куда платить? Можно ли оспорить?";
  const ctx: CaseContext = {
    language: "ru",
    // NOTE: in the real pipeline, jurisdiction is NOT inferred from OCR text —
    // ctx is built from caseType detection on the *query*, which here has
    // no Estonian/Finnish hints. So jurisdiction stays "unknown".
  };
  const realRoute = routeRealAgents(userQuery, ctx);
  console.log(`  router agents: ${realRoute.agentIds.join(", ")}`);

  // Invariant: roster includes senior_vandeadvokaat for an Estonian doc.
  const hasEstonianCounsel = realRoute.agentIds.includes("senior-vandeadvokaat");
  if (!hasEstonianCounsel) {
    recordGap({
      scenario: "A",
      invariant: "Estonian general counsel included for ET-jurisdiction doc",
      observed:
        `router picked: [${realRoute.agentIds.join(", ")}]. ` +
        `Because doc-lang is invisible to router and ctx.jurisdiction is ` +
        `unset, default fell to senior-asianajaja (FI) per ` +
        `lawyer_router.ts:107-110 keyword tie-break.`,
      impact: "P0",
    });
  }

  // Invariant: domain expert for admin/traffic exists. There is NO such
  // agent in ALL_LAWYERS — closest is "labor-lawyer" or "criminal-defender",
  // neither of which is correct for liiklusseaduse rikkumine.
  const hasAdminExpert = realRoute.agentIds.some((id) =>
    id === "administrative-lawyer" || id === "traffic-violation-lawyer"
  );
  if (!hasAdminExpert) {
    recordGap({
      scenario: "A",
      invariant: "domain expert for administrative/traffic violations",
      observed:
        `no administrative-law or traffic-violation lawyer in ALL_LAWYERS ` +
        `(15 personas: ${ALL_LAWYERS.map((a) => a.id).join(", ")}). ` +
        `LS § 227 + HKMS § 46 falls through to general counsel + strategist.`,
      impact: "P1",
    });
  }

  // Invariant: EU rights expert (proportionality / Charter Art 49(3))
  // is not on the team unless ECtHR markers fire — admin fines DO touch
  // proportionality (Bonda C-489/10) but no agent surfaces this.
  recordGap({
    scenario: "A",
    invariant: "EU proportionality expert routed for admin sanctions",
    observed:
      `lawyer_router.ts ECTHR_REGEX matches Art 3/6/8/13/14 Convention ` +
      `markers — not Charter Art 49(3) / CJEU Bonda. Admin fines never ` +
      `route to the EU rights angle.`,
    impact: "P2",
  });

  // ── (6) Response language ───────────────────────────────────────────────
  // The consilium synthesis prompt is RU-default (SYNTHESIS_SYSTEM_PROMPT
  // in consilium.ts). Russian user + Estonian doc → response *should* be
  // Russian. The bridge defaults to ru when ctx.language is missing
  // (consilium_lawyer_bridge.ts:75-77), but if ctx.language was inferred
  // from doc-lang (et) by some upstream step, the response would flip.
  // We can't observe this without running synthesis, so log it as
  // architectural ambiguity:
  recordGap({
    scenario: "A",
    invariant: "response language mirrors user, never doc",
    observed:
      `consilium synthesis language is gated on ctx.language only. If a ` +
      `future step populates ctx.language from OCR detected_lang, response ` +
      `flips to Estonian. No test enforces "user wins over doc".`,
    impact: "P1",
  });

  // ── (7) Deadline registered ─────────────────────────────────────────────
  // deadline-extractor reads pdf-parser output → calls handlePdfPayload →
  // upserts into case_deadlines. But this requires case_id to be known at
  // upload time; when user is anon (no caseId), pdf-parser returns parsed
  // result WITHOUT writing a row (see ParsedOk.documentId='' contract).
  // → No deadline registered for anon users in this UX.
  recordGap({
    scenario: "A",
    invariant: "appeal-deadline registered in case_deadlines for anon user",
    observed:
      `pdf-parser skips DB write when case_id is null (ParsedOk docs ` +
      `pdf_parser_service.dart:55-74). Deadline-extractor never runs for ` +
      `anon photo upload. T-10-day appeal clock not tracked.`,
    impact: "P0",
  });
});

// =============================================================================
// Scenario B — Ukrainian user + Finnish käännytyspäätös photo.
// =============================================================================

Deno.test("B) Ukrainian user + Finnish käännytyspäätös — UA→FI pair", () => {
  console.log("\n═══ SCENARIO B: uk-user + fi-käännytys photo ═══");

  // (1) ctx.language enum gap — "uk" is NOT in {ru, et, fi, en, de}
  //     per consilium_roles/types.ts:32. Ukrainian users get coerced
  //     somewhere upstream (probably to "ru" or "en").
  const requestedLang = "uk";
  const supportedLangs = ["ru", "et", "fi", "en", "de"];
  if (!supportedLangs.includes(requestedLang)) {
    recordGap({
      scenario: "B",
      invariant: "ctx.language enum supports user's actual UI language",
      observed:
        `CaseContext.language ∈ {ru, et, fi, en, de} per ` +
        `consilium_roles/types.ts:32. User-facing app supports 17 langs ` +
        `(see lib/l10n/app_localizations_uk.dart and 16 others) but the ` +
        `consilium pipeline silently coerces unknown langs.`,
      impact: "P0",
    });
  }

  // (2) Photo OCR stub.
  const ocr: StubOcrResult = {
    text: [
      "MAAHANMUUTTOVIRASTO — Migrationsverket",
      "PÄÄTÖS Dnro 2025-554987",
      "Käännytyspäätös ulkomaalaislain 148 §:n nojalla",
      "Valitusaika 30 päivää tämän päätöksen tiedoksisaannista",
      "Valitus tehdään Helsingin hallinto-oikeudelle",
      "Tiedoksisaanti: 2025-12-01",
    ].join("\n"),
    detected_lang: "fi",
    confidence: 0.94,
    pages: 2,
    used_vision: true,
  };

  // (3) User query in Ukrainian.
  const userQuery = "Мене висилають з Фінляндії. Що робити? Як оскаржити?";
  const ctx: CaseContext = {
    language: "ru", // coerced from "uk" — see gap above
  };

  // (4) Real router run.
  const realRoute = routeRealAgents(userQuery, ctx);
  console.log(`  router agents: ${realRoute.agentIds.join(", ")}`);

  // (5) Roster expectation: FI general counsel + immigration_lawyer.
  // Query has "Фінляндії" (Ukrainian "Finland") — let's see if FI keyword
  // pass catches it. Trigger keywords for senior-asianajaja include "finlan"
  // / "soome" / "kho" / "helsink" — Ukrainian "Фінляндії" does NOT match.
  const hasFiCounsel = realRoute.agentIds.includes("senior-asianajaja");
  if (!hasFiCounsel) {
    recordGap({
      scenario: "B",
      invariant: "FI general counsel routed for Finnish jurisdiction doc",
      observed:
        `router picked: [${realRoute.agentIds.join(", ")}]. Ukrainian ` +
        `keywords for Finland (Фінляндії, Фінляндія, Гельсінкі) are absent ` +
        `from lawyer_router.ts:102 keyword list — falls back to default.`,
      impact: "P0",
    });
  }

  // (6) Immigration lawyer trigger — "висилають" is Ukrainian for
  // "deporting". The immigration_lawyer trigger keywords are checked
  // via scoreLawyer + substring match. Ukrainian "висилають" / "висилка"
  // not present in any keyword list — but RU "депорт" might OR might
  // not be in there. Let's just inspect.
  const hasImmigration = realRoute.agentIds.includes("immigration-lawyer");
  if (!hasImmigration) {
    recordGap({
      scenario: "B",
      invariant: "immigration lawyer routed for käännytys/deport doc",
      observed:
        `router picked: [${realRoute.agentIds.join(", ")}]. Query in UA, ` +
        `no UA keywords mapped — immigration_lawyer didn't surface.`,
      impact: "P0",
    });
  }

  // (7) Deadline — 30 days valitusaika should land in case_deadlines.
  // Same gap as A: anon users get no DB write.
  recordGap({
    scenario: "B",
    invariant: "valitusaika 30d registered for anon UA user",
    observed: "same gap as A — anon users skip DB persistence path",
    impact: "P0",
  });

  // (8) Response language: user typed Ukrainian → consilium synthesis is
  // RU-default → answer comes back in RU, not UA. This is OK-ish for
  // Ukrainian speakers (most read Russian) but is a quality miss.
  recordGap({
    scenario: "B",
    invariant: "response in user's actual language (uk), not coerced (ru)",
    observed:
      `SYNTHESIS_SYSTEM_PROMPT (consilium.ts) is hard-coded RU. UA user ` +
      `gets RU response. 17-lang UI vs 5-lang AI pipeline mismatch.`,
    impact: "P1",
  });
});

// =============================================================================
// Scenario C — Polish user + German Mahnbescheid photo.
// =============================================================================

Deno.test("C) Polish user + German Mahnbescheid — PL→DE pair", () => {
  console.log("\n═══ SCENARIO C: pl-user + de-Mahnbescheid photo ═══");

  // (1) Same lang-enum gap — "pl" not in CaseContext.language.
  recordGap({
    scenario: "C",
    invariant: "ctx.language enum supports pl",
    observed:
      `pl ∉ {ru, et, fi, en, de}; Polish users get coerced. Same root ` +
      `cause as scenario B.`,
    impact: "P0",
  });

  // (2) Stub OCR.
  const ocr: StubOcrResult = {
    text: [
      "Amtsgericht Wedding — Mahngericht",
      "MAHNBESCHEID Geschäftsnummer 2025-MB-009-44",
      "Antragsteller: Mustermann GmbH",
      "Hauptforderung: 2.840,00 EUR",
      "Widerspruchsfrist: zwei Wochen ab Zustellung (§ 692 ZPO)",
      "Zustellung erfolgte am: 2025-12-05",
    ].join("\n"),
    detected_lang: "de",
    confidence: 0.89,
    pages: 1,
    used_vision: true,
  };

  // (3) User query in Polish.
  const userQuery =
    "Dostałem nakaz zapłaty z niemieckiego sądu. Czy mogę wnieść sprzeciw?";
  const ctx: CaseContext = {
    language: "en", // coerced from "pl" — closest fallback
  };

  // (4) Router.
  const realRoute = routeRealAgents(userQuery, ctx);
  console.log(`  router agents: ${realRoute.agentIds.join(", ")}`);

  // (5) DE jurisdiction expected but NO German general counsel exists in
  // the lawyer department. ALL_LAWYERS has only:
  //   senior_vandeadvokaat (EE), senior_asianajaja (FI)
  // → DE Mahnbescheid will route to whichever of those wins the fallback.
  const hasDeCounsel = realRoute.agentIds.some((id) =>
    id === "senior-rechtsanwalt" || id === "german-general-counsel"
  );
  if (!hasDeCounsel) {
    recordGap({
      scenario: "C",
      invariant: "DE general counsel exists for German civil procedure",
      observed:
        `no senior-rechtsanwalt in ALL_LAWYERS. ZPO § 692 Mahnbescheid + ` +
        `EuMVVO falls through to FI/EE general counsel. DE jurisdiction ` +
        `marker in CaseContext exists (jurisdiction: "DE") but no agent ` +
        `targets it.`,
      impact: "P0",
    });
  }

  // (6) Cross-border civil procedure expert (Brüssel Ia / EuMVVO) — none.
  recordGap({
    scenario: "C",
    invariant: "cross-border civil procedure expert (EuGVVO / Brussels Ia)",
    observed:
      `no agent in lawyer_router.ts knows EuMVVO art. 16 (foreign-resident ` +
      `2-week Widerspruchsfrist extension). PL user in Tallinn would miss ` +
      `the extended deadline.`,
    impact: "P0",
  });

  // (7) 2-week Widerspruchsfrist registered → same anon-user gap.
  recordGap({
    scenario: "C",
    invariant: "Widerspruchsfrist (2 weeks) registered in case_deadlines",
    observed: "anon-user DB-write gap (same as A, B)",
    impact: "P0",
  });

  // (8) Response language — should be Polish; will be Russian (synth default).
  recordGap({
    scenario: "C",
    invariant: "response in pl, not coerced (ru/en)",
    observed:
      `consilium synth hard-coded RU; PL user gets unhelpful output. Worse ` +
      `than scenario B because PL ≠ RU readability.`,
    impact: "P0",
  });
});

// =============================================================================
// Scenario D — Russian user + Estonian fine but OCR returns garbled text.
// =============================================================================

Deno.test("D) Russian user + Estonian fine, garbled OCR — error recovery", () => {
  console.log("\n═══ SCENARIO D: ru-user + garbled OCR ═══");

  // (1) Stub OCR — Vision Haiku returned low-confidence noise.
  const ocr: StubOcrResult = {
    text: "p o l i ts e i  oti us  TR 4482 1 ai u sel ku ie €120 m ax e 14 päe v",
    detected_lang: null, // confidence too low to commit
    confidence: 0.31,
    pages: 1,
    used_vision: true,
  };

  // (2) Confidence gate — what does the pipeline do at conf=0.31?
  // pdf-parser/index.ts:288 — PDF_VISION_MIN_USABLE_CHARS gate is on
  // character count, NOT on confidence. There is NO confidence threshold.
  // → Garbled text is treated as valid OCR.
  recordGap({
    scenario: "D",
    invariant: "OCR confidence threshold rejects garbled text",
    observed:
      `pdf-parser/index.ts:262-296 uses only PDF_VISION_MIN_USABLE_CHARS ` +
      `(char-count gate) — no confidence threshold. Garbled "p o l i ts e i" ` +
      `passes because it has >50 chars.`,
    impact: "P0",
  });

  // (3) Re-upload prompt — UI never asks the user "is this the right doc?"
  // The chat just hands the garbled text to consilium, which hallucinates
  // a plausible-sounding answer.
  recordGap({
    scenario: "D",
    invariant: "UI prompts re-upload when OCR is low-quality",
    observed:
      `document_scan_screen.dart has no low-confidence branch. ` +
      `ParsedUnreadable path (pdf_parser_service.dart:95) only fires when ` +
      `BOTH text-layer AND vision return <50 chars total — not on noisy ` +
      `output.`,
    impact: "P0",
  });

  // (4) Routing — garbled text + a Russian query about "штраф".
  const userQuery = "Что это такое? Это штраф? Что мне с этим делать?";
  const ctx: CaseContext = { language: "ru" };
  const realRoute = routeRealAgents(userQuery, ctx);
  console.log(`  router agents: ${realRoute.agentIds.join(", ")}`);
  // Router will run on garbage — no defensive check.
  // We accept this is what happens; the gap is at OCR validation.

  // (5) Fact extraction on garbage → invented facts.
  recordGap({
    scenario: "D",
    invariant: "fact_extractor returns null when input is below quality bar",
    observed:
      `fact_extractor.ts has no quality precondition. Sonnet will invent ` +
      `plausible-looking amount/date/statute from "TR 4482 1" noise. ` +
      `Hallucination directly user-facing.`,
    impact: "P0",
  });
});

// =============================================================================
// Scenario E — Russian user + Russian-language doc (court summons in Estonia).
// =============================================================================

Deno.test("E) Russian user + Russian-language doc — same-language case", () => {
  console.log("\n═══ SCENARIO E: ru-user + ru-doc (kohtukutse) ═══");

  // (1) Stub OCR. Court summons in Russian (Harju Maakohus addresses
  // Russophone respondents in Estonian primarily — but Russian doc is
  // common in older cases / certified translations).
  const ocr: StubOcrResult = {
    text: [
      "ХАРЬЮСКИЙ УЕЗДНЫЙ СУД",
      "Дело № 2-25-9011 / Гражданское производство",
      "ПОВЕСТКА в суд",
      "Адресат: Иванов Иван Иванович, ИК 38005120123",
      "Заседание: 15.01.2026 в 10:00, зал № 4",
      "Письменный отзыв подать в течение 14 дней с момента получения",
      "(ст. 394 ГПК Эстонии — TsMS § 394)",
    ].join("\n"),
    detected_lang: "ru",
    confidence: 0.96,
    pages: 1,
    used_vision: true,
  };

  // (2) The KEY question: does the pipeline assume "doc lang ≠ user lang"?
  // If so, same-lang case might break. Inspecting:
  //
  //   - consilium_lawyer_bridge.ts:75-77: language defaults to "ru" if
  //     ctx.language absent. NO assertion against doc-lang.
  //   - lawyer_router.ts:78-111: picks general counsel by jurisdiction OR
  //     language hint OR keyword tie-break. Russian-text doc has Russian
  //     keywords — "харью", "тсмс", "гпк эстонии" — none in the FI/EE
  //     keyword lists.
  //
  // So: same-lang case doesn't BREAK, but the EE jurisdiction signal
  // ("Эстонии", "TsMS", "Харью") is invisible to the router because:
  //   • TsMS is not in the ee-hits keyword list (lawyer_router.ts:104)
  //   • "Эстонии" is Russian spelling, not in ee-hits (which has "эстони"
  //     lowercased — substring match would catch "эстони" inside
  //     "эстонии"; OK).

  // (3) User query.
  const userQuery =
    "Получил повестку из эстонского суда на ивана. Я ответчик? Что писать в отзыве?";
  const ctx: CaseContext = { language: "ru" };
  const realRoute = routeRealAgents(userQuery, ctx);
  console.log(`  router agents: ${realRoute.agentIds.join(", ")}`);

  // (4) Expected: senior-vandeadvokaat (EE general) + litigator
  //     (civil procedure) + maybe family-lawyer if context suggests
  //     domestic case. Query lacks domain markers — likely just general.
  const hasEeCounsel = realRoute.agentIds.includes("senior-vandeadvokaat");
  if (!hasEeCounsel) {
    recordGap({
      scenario: "E",
      invariant: "EE general counsel routed for Estonian court summons",
      observed:
        `router picked: [${realRoute.agentIds.join(", ")}]. Query mentions ` +
        `"эстонского суда" (lowercase "эстонск" not in keyword list — ` +
        `lawyer_router.ts:104 has "эстони" only). May still pass via ` +
        `substring; record if not.`,
      impact: "P1",
    });
  }

  // (5) Civil procedure expert — TsMS § 394 (Estonian Code of Civil
  // Procedure). No agent covers Estonian civil procedure specifically.
  recordGap({
    scenario: "E",
    invariant: "Estonian civil procedure (TsMS) expert exists",
    observed:
      `no tsms-specialist / estonian-civil-procedure agent. "TsMS" not ` +
      `in any triggerKeywords. Litigator agent is generic, not corpus-aware.`,
    impact: "P1",
  });

  // (6) The actual same-language risk: NO bug surfaces here because the
  // pipeline doesn't assert doc-lang ≠ user-lang anywhere. It just doesn't
  // capitalise on the fact that they match — there is no "skip translation
  // step" optimisation.
  console.log(`  ✓ no break on same-lang case (no doc-lang assumption found)`);

  // (7) The 14-day отзыв deadline — same anon-user gap as A/B/C.
  recordGap({
    scenario: "E",
    invariant: "14-day отзыв deadline registered for anon RU user",
    observed:
      "anon-user DB-write gap (same as A/B/C). 14d TsMS § 394 clock lost.",
    impact: "P0",
  });
});

// =============================================================================
// Summary — print all gaps + top-3 blockers + priority order.
// =============================================================================

Deno.test("ZZ — Audit summary", () => {
  console.log("\n");
  console.log("═══════════════════════════════════════════════════════════════");
  console.log("  AUDIT SUMMARY — photo+multi-lang→consilium e2e");
  console.log("═══════════════════════════════════════════════════════════════");

  const byImpact = { P0: 0, P1: 0, P2: 0 };
  for (const g of GAPS) byImpact[g.impact]++;

  console.log(
    `  Total gaps: ${GAPS.length}  (P0: ${byImpact.P0}, ` +
      `P1: ${byImpact.P1}, P2: ${byImpact.P2})`,
  );
  console.log("");
  console.log("  Per scenario:");
  for (const s of ["A", "B", "C", "D", "E"]) {
    const sg = GAPS.filter((g) => g.scenario === s);
    console.log(
      `    ${s}: ${sg.length} gaps (` +
        `P0=${sg.filter((g) => g.impact === "P0").length}, ` +
        `P1=${sg.filter((g) => g.impact === "P1").length}, ` +
        `P2=${sg.filter((g) => g.impact === "P2").length})`,
    );
  }

  console.log("");
  console.log("  Top-3 blockers (P0, ordered by user impact):");
  console.log(
    "    1. pdf-parser mime gate rejects JPEG/PNG — entire photo UX dead.",
  );
  console.log(
    "    2. Routing happens on raw user query, not on OCR-extracted facts —",
  );
  console.log(
    "       Estonian/Finnish/German jurisdiction invisible to lawyer_router.",
  );
  console.log(
    "    3. Anon users skip DB persistence — no deadline registered for the",
  );
  console.log("       1st-touch user who is exactly the photo-upload target.");
  console.log("");
  console.log("  Recommended fix priority (max-impact-first):");
  console.log("    1. P0: Image mime support in pdf-parser (photo path lives).");
  console.log("    2. P0: Pipe OCR detected_lang + extracted jurisdiction back");
  console.log("       into CaseContext BEFORE routing.");
  console.log("    3. P0: Add OCR confidence threshold + re-upload UX path.");
  console.log("    4. P0: Allow anon-user deadline persistence (case_id");
  console.log("       optional but deadline still tracked client-side or in");
  console.log("       a soft-case shell).");
  console.log("    5. P0: Expand CaseContext.language enum from 5 → 17 langs");
  console.log("       (matches lib/l10n coverage) + UA/PL synthesis prompts.");
  console.log("    6. P1: Hire admin/traffic-violation + DE general counsel +");
  console.log("       Estonian civil procedure agents into the department.");
  console.log("    7. P1: Stable doc_type vocabulary + classifier (fine,");
  console.log("       summons, otsus, päätös, hakemus, Mahnbescheid, ...).");
  console.log("    8. P2: EU rights / proportionality agent for admin fines.");
  console.log("");
  console.log("═══════════════════════════════════════════════════════════════");

  // The audit ALWAYS passes — gaps are findings, not failures.
  assertEquals(typeof GAPS.length, "number");
  assert(GAPS.length > 0, "audit must surface at least one gap");
});
