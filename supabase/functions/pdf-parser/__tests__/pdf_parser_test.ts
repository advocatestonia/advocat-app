// Deno tests for Pkg 2 — pdf-parser Edge Function.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/pdf-parser/__tests__/pdf_parser_test.ts
//
// Spec: memory: project_handoff_smart_lawyer.md "Рабочий пакет 2 — Полный
// PDF-парсинг".
//   * Identity-marker pinning (system_prompt_guard whitelist).
//   * Pure-function tests for `_shared/pdf_extractor_prompt.ts` (parser +
//     summary builder + language detector).
//   * Body-validator tests for `pdf-parser/index.ts` (auth/path checks).
//   * Source-contract tests for `pdf-parser/index.ts` (RPC name, fields,
//     Vision/Sonnet config pinned).
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildParsedSummary,
  detectPageLang,
  emptyExtraction,
  PDF_EXTRACTOR_IDENTITY_MARKER,
  PDF_EXTRACTOR_MAX_TOKENS,
  PDF_EXTRACTOR_MODEL,
  PDF_EXTRACTOR_SYSTEM_PROMPT,
  PDF_EXTRACTOR_TIMEOUT_MS,
  PDF_MAX_PAGES,
  PDF_MAX_VISION_PAGES,
  PDF_SCAN_THRESHOLD_CHARS,
  parseExtractedDoc,
} from "../../_shared/pdf_extractor_prompt.ts";
import { ADVOCAT_IDENTITY_MARKERS } from "../../claude-proxy/system_prompt_guard.ts";
import {
  extractedToKeyExtractions,
  parseAndValidateBody,
  stitchPages,
} from "../helpers.ts";

// =============================================================================
// 1. Identity marker
// =============================================================================

Deno.test("PDFP-T01 — identity marker is whitelisted by system_prompt_guard", () => {
  assert(
    ADVOCAT_IDENTITY_MARKERS.includes(PDF_EXTRACTOR_IDENTITY_MARKER),
    `PDF_EXTRACTOR_IDENTITY_MARKER (${PDF_EXTRACTOR_IDENTITY_MARKER}) is ` +
      `not in ADVOCAT_IDENTITY_MARKERS — system_prompt_guard would 400 ` +
      `the Sonnet call`,
  );
});

Deno.test("PDFP-T02 — system prompt starts with the identity marker", () => {
  assert(
    PDF_EXTRACTOR_SYSTEM_PROMPT.startsWith(PDF_EXTRACTOR_IDENTITY_MARKER),
    "System prompt must lead with the identity marker so guard accepts it",
  );
});

Deno.test("PDFP-T03 — system prompt names every required JSON field", () => {
  const required = [
    "doc_type",
    "doc_date",
    "parties",
    "case_numbers",
    "key_facts",
    "diagnoses_if_medical",
    "monetary_amounts",
    "deadlines",
  ];
  for (const k of required) {
    assertStringIncludes(PDF_EXTRACTOR_SYSTEM_PROMPT, k);
  }
});

Deno.test("PDFP-T04 — Sonnet config: model + max_tokens + timeout pinned", () => {
  assertEquals(PDF_EXTRACTOR_MODEL, "claude-sonnet-4-6");
  assertEquals(PDF_EXTRACTOR_MAX_TOKENS, 2_000);
  assertEquals(PDF_EXTRACTOR_TIMEOUT_MS, 120_000);
});

Deno.test("PDFP-T05 — page caps pinned (regression guard)", () => {
  assertEquals(PDF_MAX_PAGES, 100);
  assertEquals(PDF_MAX_VISION_PAGES, 25);
  assertEquals(PDF_SCAN_THRESHOLD_CHARS, 50);
});

// =============================================================================
// 2. parseExtractedDoc — defensive JSON parsing
// =============================================================================

Deno.test("PDFP-T10 — parses a happy-path extraction", () => {
  const raw = JSON.stringify({
    doc_type: "police_report",
    doc_date: "2026-04-12",
    parties: [
      { name: "Sofia Sulga", role: "victim" },
      { name: "Helsingin poliisi", role: "investigator" },
    ],
    case_numbers: [{ authority: "PPA", number: "5500/R/75170/25" }],
    key_facts: ["Assault near central station", "Victim PTSD diagnosed"],
    diagnoses_if_medical: [],
    monetary_amounts: [{ amount: 19000, currency: "EUR", what: "compensation request" }],
    deadlines: [{ date: "2026-05-12", what: "appeal", statute: "HKMS § 46" }],
  });
  const p = parseExtractedDoc(raw);
  assert(p !== null, "should parse");
  assertEquals(p!.doc_type, "police_report");
  assertEquals(p!.doc_date, "2026-04-12");
  assertEquals(p!.parties.length, 2);
  assertEquals(p!.case_numbers[0].number, "5500/R/75170/25");
  assertEquals(p!.monetary_amounts[0].amount, 19000);
  assertEquals(p!.monetary_amounts[0].currency, "EUR");
  assertEquals(p!.deadlines[0].date, "2026-05-12");
});

Deno.test("PDFP-T11 — invalid JSON returns null", () => {
  assertEquals(parseExtractedDoc("definitely-not-json"), null);
  assertEquals(parseExtractedDoc(""), null);
  assertEquals(parseExtractedDoc("{ unterminated"), null);
});

Deno.test("PDFP-T12 — top-level array returns null", () => {
  assertEquals(parseExtractedDoc("[]"), null);
});

Deno.test("PDFP-T13 — non-string raw returns null", () => {
  assertEquals(parseExtractedDoc(null), null);
  assertEquals(parseExtractedDoc(undefined), null);
  assertEquals(parseExtractedDoc(123), null);
  assertEquals(parseExtractedDoc({}), null);
});

Deno.test("PDFP-T14 — strips ```json fence Sonnet occasionally adds", () => {
  const raw = "```json\n" + JSON.stringify({
    doc_type: "court_decision",
    doc_date: null,
    parties: [],
    case_numbers: [],
    key_facts: ["X"],
    diagnoses_if_medical: [],
    monetary_amounts: [],
    deadlines: [],
  }) + "\n```";
  const p = parseExtractedDoc(raw);
  assert(p !== null);
  assertEquals(p!.doc_type, "court_decision");
});

Deno.test("PDFP-T15 — unknown doc_type collapses to 'other'", () => {
  const raw = JSON.stringify({
    doc_type: "spaceship_manual",
    doc_date: null,
    parties: [],
    case_numbers: [],
    key_facts: [],
    diagnoses_if_medical: [],
    monetary_amounts: [],
    deadlines: [],
  });
  const p = parseExtractedDoc(raw);
  assert(p !== null);
  assertEquals(p!.doc_type, "other");
});

Deno.test("PDFP-T16 — partial doc_date is dropped (must be YYYY-MM-DD)", () => {
  const raw = JSON.stringify({
    doc_type: "other",
    doc_date: "2026",
    parties: [],
    case_numbers: [],
    key_facts: [],
    diagnoses_if_medical: [],
    monetary_amounts: [],
    deadlines: [],
  });
  const p = parseExtractedDoc(raw);
  assertEquals(p!.doc_date, null);
});

Deno.test("PDFP-T17 — money rows without numeric amount are skipped", () => {
  const raw = JSON.stringify({
    doc_type: "other",
    doc_date: null,
    parties: [],
    case_numbers: [],
    key_facts: [],
    diagnoses_if_medical: [],
    monetary_amounts: [
      { amount: 100, currency: "eur", what: "fine" },
      { amount: "not-a-number", currency: "EUR", what: "bad" },
      { currency: "USD", what: "missing amount" },
    ],
    deadlines: [],
  });
  const p = parseExtractedDoc(raw);
  assertEquals(p!.monetary_amounts.length, 1);
  assertEquals(p!.monetary_amounts[0].currency, "EUR"); // upper-cased
});

Deno.test("PDFP-T18 — diagnoses without ICD or description are skipped", () => {
  const raw = JSON.stringify({
    doc_type: "medical",
    doc_date: null,
    parties: [],
    case_numbers: [],
    key_facts: [],
    diagnoses_if_medical: [
      { icd_code: "F43.1", description: "PTSD", severity: "moderate" },
      { severity: "severe" }, // skipped
      {}, // skipped
    ],
    monetary_amounts: [],
    deadlines: [],
  });
  const p = parseExtractedDoc(raw);
  assertEquals(p!.diagnoses_if_medical.length, 1);
  assertEquals(p!.diagnoses_if_medical[0].icd_code, "F43.1");
});

// =============================================================================
// 3. emptyExtraction
// =============================================================================

Deno.test("PDFP-T20 — emptyExtraction has valid shape", () => {
  const e = emptyExtraction();
  assertEquals(e.doc_type, "other");
  assertEquals(e.doc_date, null);
  assertEquals(e.parties, []);
  assertEquals(e.case_numbers, []);
  assertEquals(e.key_facts, []);
  assertEquals(e.diagnoses_if_medical, []);
  assertEquals(e.monetary_amounts, []);
  assertEquals(e.deadlines, []);
});

// =============================================================================
// 4. buildParsedSummary
// =============================================================================

Deno.test("PDFP-T30 — summary contains head + extracted facts", () => {
  const e = emptyExtraction();
  e.doc_type = "police_report";
  e.doc_date = "2026-04-12";
  e.parties = [{ name: "Sofia Sulga", role: "victim" }];
  e.case_numbers = [{ authority: "PPA", number: "5500/R/75170/25" }];
  e.key_facts = ["Assault report"];
  const head = "Esitutkintapöytäkirja Helsingin poliisilaitos 12.04.2026...";
  const sum = buildParsedSummary(e, head);
  assertStringIncludes(sum, "Esitutkintapöytäkirja");
  assertStringIncludes(sum, "type=police_report");
  assertStringIncludes(sum, "date=2026-04-12");
  assertStringIncludes(sum, "victim: Sofia Sulga");
  assertStringIncludes(sum, "PPA 5500/R/75170/25");
});

Deno.test("PDFP-T31 — summary respects maxChars cap", () => {
  const e = emptyExtraction();
  const head = "X".repeat(10000);
  const sum = buildParsedSummary(e, head, 1000);
  assert(sum.length <= 1000);
});

// =============================================================================
// 5. detectPageLang — heuristic lang classifier
// =============================================================================

Deno.test("PDFP-T40 — Russian text is classified as ru", () => {
  assertEquals(
    detectPageLang("Постановление о возбуждении уголовного дела"),
    "ru",
  );
});

Deno.test("PDFP-T41 — Estonian text with õ is classified as et", () => {
  assertEquals(
    detectPageLang("Käesolevaga tehakse teile teatavaks õiguslik otsus"),
    "et",
  );
});

Deno.test("PDFP-T42 — Finnish text without õ is classified as fi", () => {
  assertEquals(
    detectPageLang(
      "Esitutkintapöytäkirja Helsingin poliisilaitos. " +
        "Asianomistaja täytti lomakkeen.",
    ),
    "fi",
  );
});

Deno.test("PDFP-T43 — plain Latin text is en", () => {
  assertEquals(
    detectPageLang("This decision was issued by the District Court of London"),
    "en",
  );
});

Deno.test("PDFP-T44 — empty input is 'other'", () => {
  assertEquals(detectPageLang(""), "other");
});

Deno.test("PDFP-T45 — Ukrainian markers (ї,є,і,ґ) classified as uk", () => {
  assertEquals(
    detectPageLang("Виконання обов’язку щодо відшкодування шкоди є необхідним"),
    "uk",
  );
});

// =============================================================================
// 6. parseAndValidateBody (HTTP body validator)
// =============================================================================

const UID_A = "11111111-1111-1111-1111-111111111111";
const UID_B = "22222222-2222-2222-2222-222222222222";
const CASE_A = "33333333-3333-3333-3333-333333333333";

Deno.test("PDFP-T50 — happy path: case_id present, path scoped to caller", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/${CASE_A}/protocol.pdf`,
      case_id: CASE_A,
      mime_type: "application/pdf",
      filename: "protocol.pdf",
    },
    UID_A,
  );
  assertEquals(r.case_id, CASE_A);
  assertEquals(r.storage_path, `${UID_A}/${CASE_A}/protocol.pdf`);
  assertEquals(r.filename, "protocol.pdf");
});

Deno.test("PDFP-T51 — case_id null is allowed (general upload)", () => {
  const r = parseAndValidateBody(
    {
      storage_path: `${UID_A}/general/x.pdf`,
      case_id: null,
      mime_type: "application/pdf",
      filename: "x.pdf",
    },
    UID_A,
  );
  assertEquals(r.case_id, null);
});

Deno.test("PDFP-T52 — path scoped to ANOTHER user is rejected", () => {
  assertThrows(
    () =>
      parseAndValidateBody(
        {
          storage_path: `${UID_B}/${CASE_A}/protocol.pdf`,
          case_id: CASE_A,
          mime_type: "application/pdf",
          filename: "x.pdf",
        },
        UID_A,
      ),
    Error,
    "must start with the caller's user_id",
  );
});

Deno.test("PDFP-T53 — path traversal is rejected", () => {
  assertThrows(
    () =>
      parseAndValidateBody(
        {
          storage_path: `${UID_A}/../${UID_B}/x.pdf`,
          mime_type: "application/pdf",
          filename: "x.pdf",
        },
        UID_A,
      ),
    Error,
    "must not contain ..",
  );
});

Deno.test("PDFP-T54 — non-PDF mime is rejected", () => {
  assertThrows(
    () =>
      parseAndValidateBody(
        {
          storage_path: `${UID_A}/general/x.docx`,
          mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          filename: "x.docx",
        },
        UID_A,
      ),
    Error,
    "Only application/pdf",
  );
});

Deno.test("PDFP-T55 — non-UUID case_id is rejected", () => {
  assertThrows(
    () =>
      parseAndValidateBody(
        {
          storage_path: `${UID_A}/general/x.pdf`,
          case_id: "not-a-uuid",
          mime_type: "application/pdf",
          filename: "x.pdf",
        },
        UID_A,
      ),
    Error,
    "case_id must be a UUID",
  );
});

Deno.test("PDFP-T56 — missing required fields rejected", () => {
  assertThrows(
    () => parseAndValidateBody({}, UID_A),
    Error,
    "storage_path is required",
  );
  assertThrows(
    () =>
      parseAndValidateBody(
        { storage_path: `${UID_A}/x/x.pdf` },
        UID_A,
      ),
    Error,
    "mime_type is required",
  );
  assertThrows(
    () =>
      parseAndValidateBody(
        { storage_path: `${UID_A}/x/x.pdf`, mime_type: "application/pdf" },
        UID_A,
      ),
    Error,
    "filename is required",
  );
});

Deno.test("PDFP-T57 — overlong filename rejected", () => {
  assertThrows(
    () =>
      parseAndValidateBody(
        {
          storage_path: `${UID_A}/general/x.pdf`,
          mime_type: "application/pdf",
          filename: "x".repeat(300),
        },
        UID_A,
      ),
    Error,
    "filename too long",
  );
});

// =============================================================================
// 7. stitchPages — page-marker layout
// =============================================================================

Deno.test("PDFP-T60 — stitched output has --- PAGE N --- markers", () => {
  const stitched = stitchPages([
    { page: 1, text: "Hello", source: "text" },
    { page: 2, text: "World", source: "vision" },
  ]);
  assertStringIncludes(stitched, "--- PAGE 1 ---");
  assertStringIncludes(stitched, "--- PAGE 2 ---");
  assertStringIncludes(stitched, "Hello");
  assertStringIncludes(stitched, "World");
});

Deno.test("PDFP-T61 — empty pages are skipped (not blank-marker noise)", () => {
  const stitched = stitchPages([
    { page: 1, text: "Hello", source: "text" },
    { page: 2, text: "", source: "empty" },
    { page: 3, text: "World", source: "text" },
  ]);
  assertStringIncludes(stitched, "--- PAGE 1 ---");
  assertStringIncludes(stitched, "--- PAGE 3 ---");
  assertFalse(
    stitched.includes("--- PAGE 2 ---"),
    "empty page must not produce a marker",
  );
});

// =============================================================================
// 8. extractedToKeyExtractions — exact jsonb shape (used by Pkg 1.B injection)
// =============================================================================

Deno.test("PDFP-T70 — key_extractions includes pages_lang + every field", () => {
  const e = emptyExtraction();
  e.doc_type = "medical";
  e.parties = [{ name: "Dr. House", role: "doctor" }];
  const out = extractedToKeyExtractions(e, ["et", "fi", "ru"]);
  assertEquals(out.doc_type, "medical");
  assertEquals(
    (out.parties as Array<{ name: string }>)[0].name,
    "Dr. House",
  );
  assertEquals(out.pages_lang, ["et", "fi", "ru"]);
  for (const k of [
    "doc_type",
    "doc_date",
    "parties",
    "case_numbers",
    "key_facts",
    "diagnoses_if_medical",
    "monetary_amounts",
    "deadlines",
    "pages_lang",
  ]) {
    assert(k in out, `missing key in key_extractions: ${k}`);
  }
});

// =============================================================================
// 9. Source-code contracts — index.ts must keep the integration stable.
// =============================================================================

const INDEX_PATH = new URL("../index.ts", import.meta.url);

Deno.test("PDFP-T80 — index.ts wires JWT + rate-limit gate", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, "requireUserWithRateLimit");
  assertStringIncludes(src, 'bucket: "pdf-parser"');
  assertStringIncludes(src, "maxPerMinute: 6");
});

Deno.test("PDFP-T81 — index.ts uses correct Storage bucket + Vision/Sonnet/embed models", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, '"case-documents"');
  assertStringIncludes(src, "claude-haiku-4-5-20251001"); // Vision
  assertStringIncludes(src, "PDF_EXTRACTOR_MODEL"); // Sonnet via shared const
  assertStringIncludes(src, '"text-embedding-3-small"');
});

Deno.test("PDFP-T82 — index.ts pulls extraction config from shared module", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, '"../_shared/pdf_extractor_prompt.ts"');
  assertStringIncludes(src, "PDF_EXTRACTOR_SYSTEM_PROMPT");
  assertStringIncludes(src, "parseExtractedDoc");
});

Deno.test("PDFP-T83 — index.ts blocks oversize PDFs (50 MB cap)", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, "MAX_PDF_BYTES");
  assertStringIncludes(src, "50 * 1024 * 1024");
});

Deno.test("PDFP-T84 — index.ts returns too_long / scan_too_long / unreadable shapes", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, '"too_long"');
  assertStringIncludes(src, '"scan_too_long"');
  assertStringIncludes(src, '"unreadable"');
});

Deno.test("PDFP-T85 — index.ts upserts on (case_id, filename) key", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, '.eq("case_id", args.caseId)');
  assertStringIncludes(src, '.eq("filename", args.filename)');
  assertStringIncludes(src, '"case_documents"');
});

Deno.test("PDFP-T86 — index.ts ships the embedding column when persisting", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, "embedding: args.embedding");
  assertStringIncludes(src, "EMBEDDING_DIM");
  assertStringIncludes(src, "1536");
});

// =============================================================================
// 10. v2 — partyIsUserAttorney (analyst consilium false-positive fix)
// =============================================================================
//
// v1 fired the attorney_role_in_doc signal on ANY party row whose `role`
// matched /attorney|advokaat|asianajaja/i. This produced false positives
// when a court filing or police report names the COUNTERPARTY's lawyer.
// v2 tightens the detector — see partyIsUserAttorney in pdf-parser/index.ts.
//
// We import directly from index.ts. The function is pure (no I/O) so we
// don't trigger the Deno.serve listener.

// Imported from helpers.ts (NOT index.ts) so we don't boot the serve()
// listener at test-load time and don't need --allow-net.
import {
  DOC_BURST_DAILY_THRESHOLD,
  partyIsUserAttorney,
} from "../helpers.ts";

Deno.test("PDFP-T90 — partyIsUserAttorney: explicit is_user_party=true fires", () => {
  assert(
    partyIsUserAttorney(
      { name: "Anna Tamm", role: "attorney", is_user_party: true },
      null, // email irrelevant when explicit flag is set
    ),
  );
});

Deno.test("PDFP-T91 — partyIsUserAttorney: counterparty attorney does NOT fire (v1 regression)", () => {
  // v1 bug: this fired the signal. The user uploaded a court filing
  // naming the OTHER side's attorney; not a B2B intent indicator.
  assertFalse(
    partyIsUserAttorney(
      { name: "Maria Kovacic", role: "attorney" },
      "client@gmail.com",
    ),
  );
});

Deno.test("PDFP-T92 — partyIsUserAttorney: email-domain match in name fires", () => {
  // Signing block: "John Doe (john@law-firm.ee), attorney" — domain
  // match in the party name surfaces the caller.
  assert(
    partyIsUserAttorney(
      { name: "John Doe (john@law-firm.ee)", role: "attorney" },
      "john@law-firm.ee",
    ),
  );
});

Deno.test("PDFP-T93 — partyIsUserAttorney: non-attorney role never fires", () => {
  // Even with is_user_party=true, a non-attorney role must not fire.
  assertFalse(
    partyIsUserAttorney(
      { name: "Anna", role: "victim", is_user_party: true },
      null,
    ),
  );
  assertFalse(
    partyIsUserAttorney(
      { name: "Anna", role: "plaintiff", is_user_party: true },
      null,
    ),
  );
});

Deno.test("PDFP-T94 — partyIsUserAttorney: Finnish + Estonian role keywords accepted", () => {
  assert(
    partyIsUserAttorney(
      { name: "X", role: "asianajaja", is_user_party: true },
      null,
    ),
  );
  assert(
    partyIsUserAttorney(
      { name: "X", role: "advokaat", is_user_party: true },
      null,
    ),
  );
});

Deno.test("PDFP-T95 — partyIsUserAttorney: missing email + missing flag → false", () => {
  // The only way to fire without is_user_party is via email-domain
  // match. With no email, we must return false to avoid v1 false-pos.
  assertFalse(
    partyIsUserAttorney(
      { name: "Someone", role: "attorney" },
      null,
    ),
  );
  assertFalse(
    partyIsUserAttorney(
      { name: "Someone", role: "attorney" },
      undefined,
    ),
  );
});

Deno.test("PDFP-T96 — partyIsUserAttorney: malformed email is rejected safely", () => {
  // No @ → no domain → strict-flag-only mode applies.
  assertFalse(
    partyIsUserAttorney(
      { name: "Someone (someone@law.ee)", role: "attorney" },
      "no-at-sign-here",
    ),
  );
});

Deno.test("PDFP-T97 — v2: DOC_BURST_DAILY_THRESHOLD bumped from 3 to 5", () => {
  // The analyst consilium asked for 5+ docs/day (instead of 3+) to drop
  // false positives from curious browsers. Lock the threshold in.
  assertEquals(DOC_BURST_DAILY_THRESHOLD, 5);
});

Deno.test("PDFP-T98 — index.ts records doc_burst with v2 score 25", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  // We pass score: 25 (down from 30 in v1) explicitly so the row in
  // b2b_signals matches DEFAULT_SCORES.doc_burst_3plus_day.
  assertStringIncludes(src, 'p_signal_type: "doc_burst_3plus_day"');
  assertStringIncludes(src, "p_score: 25");
});

Deno.test("PDFP-T99 — index.ts records attorney_role with v2 score 40", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  assertStringIncludes(src, 'p_signal_type: "attorney_role_in_doc"');
  assertStringIncludes(src, "p_score: 40");
});
