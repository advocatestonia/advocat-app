// he-fetcher — Deno tests for the pure pieces (parser, normaliser, helpers,
// seed catalogue invariants). Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/he-fetcher/__tests__/he_fetcher_test.ts
//
// HTTP / Sonnet / OpenAI calls are NOT covered here — they need network
// + secrets. A future integration test should exercise ?mode=seed and
// ?mode=status against a staging Supabase project.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type ExtractedTravauxChunk,
  HE_FETCHER_MAX_INPUT_CHARS,
  HE_FETCHER_MAX_TOKENS,
  HE_FETCHER_MODEL,
  HE_FETCHER_SYSTEM_PROMPT,
  HE_FETCHER_TIMEOUT_MS,
  normaliseSectionRef,
  parseTravauxOutput,
} from "../extractor_prompt.ts";
import {
  ALL_SEEDS,
  EE_EELNOU_SEEDS,
  FI_HE_PRIORITY_SEEDS,
  FI_HE_SEEDS,
} from "../seed.ts";
import { bytesToBase64, htmlToText } from "../fetch_source.ts";
import { clampInt, parseCountRange, seedFromPayload } from "../index.ts";
import {
  HARD_MAX_PAGES,
  MAX_PDF_BYTES,
  PAGES_PER_SEGMENT,
  planAndStream,
  segmentBytesToBase64,
  splitPdfBytes,
} from "../pdf_splitter.ts";
import { PDFDocument } from "https://esm.sh/pdf-lib@1.17.1";

// =============================================================================
// 1. Model + budget pins
// =============================================================================
Deno.test("HEF-T01 — model is Sonnet (consilium requirement, not Haiku)", () => {
  assert(HE_FETCHER_MODEL.includes("sonnet"));
});

Deno.test("HEF-T02 — timeout is within 10s..300s", () => {
  // Claude native PDF support raises latency vs raw text input; 180s gives
  // headroom for 30+ page HE PDFs without exceeding Supabase's 5 min ceiling.
  assert(HE_FETCHER_TIMEOUT_MS >= 10_000);
  assert(HE_FETCHER_TIMEOUT_MS <= 300_000);
});

Deno.test("HEF-T03 — max tokens leaves headroom but bounds cost", () => {
  // 8K is enough for ~30 §§ × 1.5K each, well under the $5 budget.
  assert(HE_FETCHER_MAX_TOKENS >= 4_000);
  assert(HE_FETCHER_MAX_TOKENS <= 16_000);
});

Deno.test("HEF-T04 — system prompt mentions JSON array format", () => {
  assert(
    HE_FETCHER_SYSTEM_PROMPT.toLowerCase().includes("json array"),
    "system prompt must instruct strict JSON output",
  );
  assert(
    HE_FETCHER_SYSTEM_PROMPT.includes("section_ref"),
    "system prompt must name the section_ref field",
  );
});

Deno.test("HEF-T05 — input cap keeps prompt below Sonnet context", () => {
  // 350K chars ≈ 87K tokens, well under Sonnet's 200K context.
  assert(HE_FETCHER_MAX_INPUT_CHARS >= 100_000);
  assert(HE_FETCHER_MAX_INPUT_CHARS <= 500_000);
});

// =============================================================================
// 2. parseTravauxOutput — defensive parsing
// =============================================================================
Deno.test("HEF-P01 — parses canonical Sonnet output", () => {
  const raw = `[
    { "section_ref": "114", "text": "${"x".repeat(60)}" },
    { "section_ref": "114.1", "text": "${"y".repeat(60)}" }
  ]`;
  const out = parseTravauxOutput(raw);
  assertEquals(out.length, 2);
  assertEquals(out[0].section_ref, "114");
  assertEquals(out[1].section_ref, "114.1");
});

Deno.test("HEF-P02 — strips ```json fences Sonnet sometimes emits", () => {
  const raw = '```json\n[{"section_ref":"114","text":"' + "x".repeat(60) +
    '"}]\n```';
  const out = parseTravauxOutput(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].section_ref, "114");
});

Deno.test("HEF-P03 — drops chunks shorter than 50 chars", () => {
  const raw = `[
    { "section_ref": "114", "text": "too short" },
    { "section_ref": "115", "text": "${"y".repeat(100)}" }
  ]`;
  const out = parseTravauxOutput(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].section_ref, "115");
});

Deno.test("HEF-P04 — null section_ref preserved", () => {
  const raw = `[{ "section_ref": null, "text": "${"z".repeat(60)}" }]`;
  const out = parseTravauxOutput(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].section_ref, null);
});

Deno.test("HEF-P05 — malformed JSON returns []", () => {
  assertEquals(parseTravauxOutput("not json").length, 0);
  assertEquals(parseTravauxOutput("").length, 0);
  assertEquals(parseTravauxOutput("{not an array}").length, 0);
});

Deno.test("HEF-P06 — non-array top-level returns []", () => {
  assertEquals(
    parseTravauxOutput('{"section_ref":"114","text":"abc"}').length,
    0,
  );
});

// =============================================================================
// 3. normaliseSectionRef
// =============================================================================
Deno.test("HEF-N01 — strips § sign", () => {
  assertEquals(normaliseSectionRef("114 §"), "114");
  assertEquals(normaliseSectionRef("§ 114"), "114");
});

Deno.test("HEF-N02 — strips 'vp' suffix from HE refs", () => {
  assertEquals(normaliseSectionRef("114 vp"), "114");
});

Deno.test("HEF-N03 — preserves subsection notation", () => {
  assertEquals(normaliseSectionRef("114.1"), "114.1");
  assertEquals(normaliseSectionRef("12 a"), "12 a");
});

Deno.test("HEF-N04 — empty / whitespace returns null", () => {
  assertEquals(normaliseSectionRef(""), null);
  assertEquals(normaliseSectionRef("   "), null);
  assertEquals(normaliseSectionRef("§"), null);
});

Deno.test("HEF-N05 — caps absurd lengths at 40 chars", () => {
  const result = normaliseSectionRef("a".repeat(200));
  assert(result !== null);
  assert(result!.length <= 40);
});

// =============================================================================
// 4. Seed catalogue invariants
// =============================================================================
Deno.test("HEF-S01 — exactly 15 FI HE seeds (consilium spec)", () => {
  assertEquals(FI_HE_SEEDS.length, 15);
});

Deno.test("HEF-S02 — exactly 15 EE eelnõu seeds (consilium spec)", () => {
  assertEquals(EE_EELNOU_SEEDS.length, 15);
});

Deno.test("HEF-S03 — combined catalogue is 33 docs (30 original + 3 priority)", () => {
  // 15 FI HE + 15 EE eelnõu + 3 FI priority HE (consilium 2026-05-15) = 33
  assertEquals(ALL_SEEDS.length, 33);
});

Deno.test("HEF-S03b — 3 priority FI HE seeds added (HE 29/2018, HE 72/2002, HE 1/2016)", () => {
  // Fix #89 round 3 (2026-05-15): HE 226/2018 vp was the WRONG bill — that
  // Finlex URL resolves to a "turvallisuusverkosta" (security network)
  // amendment, not the OHO 808/2019 procedure law. The correct OHO travaux
  // is HE 29/2018 vp. See seed.ts header comment for verification chain.
  assertEquals(FI_HE_PRIORITY_SEEDS.length, 3);
  const docNumbers = new Set(FI_HE_PRIORITY_SEEDS.map((s) => s.doc_number));
  assert(docNumbers.has("HE 29/2018 vp"), "missing HE 29/2018 vp (OHO)");
  assert(docNumbers.has("HE 72/2002 vp"), "missing HE 72/2002 vp (Hallintolaki)");
  assert(docNumbers.has("HE 1/2016 vp"), "missing HE 1/2016 vp (UlkL)");
  // Regression guard: the wrong bill must NEVER be in the seed list again.
  assertFalse(
    docNumbers.has("HE 226/2018 vp"),
    "HE 226/2018 vp is the security-network bill, not OHO — must not appear",
  );
  // All three target Finlex (CC-BY licensed).
  for (const s of FI_HE_PRIORITY_SEEDS) {
    assert(s.url.includes("finlex.fi"), `priority seed not on Finlex: ${s.url}`);
    assertEquals(s.jurisdiction, "fi");
    assertEquals(s.doc_kind, "HE");
  }
  // OHO entry must point at the correct Finlex page.
  const ohoSeed = FI_HE_PRIORITY_SEEDS.find((s) => s.related_act_slug === "fi-oho");
  assert(ohoSeed, "fi-oho priority seed missing");
  assert(
    ohoSeed!.url.endsWith("/hallituksen-esitykset/2018/29"),
    `fi-oho seed url should be /hallituksen-esitykset/2018/29; got ${ohoSeed!.url}`,
  );
});

Deno.test("HEF-S04 — all source_ids unique (PK constraint relies on this)", () => {
  const seen = new Set<string>();
  for (const s of ALL_SEEDS) {
    assertFalse(seen.has(s.source_id), `duplicate source_id: ${s.source_id}`);
    seen.add(s.source_id);
  }
});

Deno.test("HEF-S05 — every FI seed has doc_kind=HE and jurisdiction=fi", () => {
  for (const s of FI_HE_SEEDS) {
    assertEquals(s.doc_kind, "HE");
    assertEquals(s.jurisdiction, "fi");
    // FI HE source: Finlex (primary) or eduskunta.fi (legacy).
    assert(
      s.url.includes("finlex.fi") || s.url.includes("eduskunta.fi"),
      `FI seed url not on a recognised host: ${s.url}`,
    );
  }
});

Deno.test("HEF-S06 — every EE seed is eelnõu/seletuskiri and jurisdiction=ee", () => {
  for (const s of EE_EELNOU_SEEDS) {
    assert(
      s.doc_kind === "eelnõu" || s.doc_kind === "seletuskiri",
      `unexpected doc_kind: ${s.doc_kind}`,
    );
    assertEquals(s.jurisdiction, "ee");
    // Primary host: Riigikogu eelnõude infosüsteem.
    // Exception: Põhiseadus 1992 predates Riigikogu IS — uses Riigi Teataja.
    assert(
      s.url.includes("riigikogu.ee") || s.url.includes("riigiteataja.ee"),
      `EE seed url not on a recognised host: ${s.url}`,
    );
  }
});

Deno.test("HEF-S07 — HOL §114 covered by HE 217/1995 vp (Sulga case)", () => {
  // The Legal Architect's spot-check is exactly this row.
  const holSeed = FI_HE_SEEDS.find((s) =>
    s.related_act_slug === "fi-hol" && s.doc_number.includes("217/1995")
  );
  assert(
    holSeed,
    "HOL must have a seed for HE 217/1995 vp — required for KHO §114 spot-check",
  );
  assertEquals(holSeed!.year, 1995);
});

Deno.test("HEF-S08 — act_slug values look like 'jurisdiction-statute'", () => {
  // Loose sanity check — catches typos like 'fi_hol' vs 'fi-hol'.
  for (const s of ALL_SEEDS) {
    const m = /^[a-z]{2}-[a-z0-9-]+$/.test(s.related_act_slug);
    assert(m, `bad act_slug: ${s.related_act_slug} (${s.source_id})`);
  }
});

Deno.test("HEF-S09 — year is plausible (1970..2030)", () => {
  // Vahingonkorvauslaki's original HE is from 1973 — widest realistic floor.
  for (const s of ALL_SEEDS) {
    assert(s.year >= 1970 && s.year <= 2030, `bad year: ${s.year}`);
  }
});

// =============================================================================
// 5. seedFromPayload — defensive payload reconstruction
// =============================================================================
Deno.test("HEF-PL01 — happy path reconstructs seed", () => {
  const seed = seedFromPayload(
    {
      id: "j1",
      source: "he",
      source_id: "fi-he-217-1995",
      target_table: "travaux",
      payload: null,
    },
    {
      url: "https://x",
      doc_kind: "HE",
      doc_number: "HE 217/1995 vp",
      title: "Hallintolainkäyttö",
      year: 1995,
      jurisdiction: "fi",
      related_act_slug: "fi-hol",
    },
  );
  assert(seed);
  assertEquals(seed!.doc_number, "HE 217/1995 vp");
});

Deno.test("HEF-PL02 — missing url returns null", () => {
  const seed = seedFromPayload(
    {
      id: "j1",
      source: "he",
      source_id: "x",
      target_table: "travaux",
      payload: null,
    },
    {
      doc_kind: "HE",
      doc_number: "HE 1/1995",
      jurisdiction: "fi",
      related_act_slug: "fi-hol",
    },
  );
  assertEquals(seed, null);
});

Deno.test("HEF-PL03 — invalid jurisdiction returns null", () => {
  const seed = seedFromPayload(
    {
      id: "j1",
      source: "he",
      source_id: "x",
      target_table: "travaux",
      payload: null,
    },
    {
      url: "https://x",
      doc_kind: "HE",
      doc_number: "x",
      jurisdiction: "us",
      related_act_slug: "fi-hol",
    },
  );
  assertEquals(seed, null);
});

Deno.test("HEF-PL04 — invalid doc_kind returns null", () => {
  const seed = seedFromPayload(
    {
      id: "j1",
      source: "he",
      source_id: "x",
      target_table: "travaux",
      payload: null,
    },
    {
      url: "https://x",
      doc_kind: "bogus",
      doc_number: "x",
      jurisdiction: "fi",
      related_act_slug: "fi-hol",
    },
  );
  assertEquals(seed, null);
});

// =============================================================================
// 6. clampInt
// =============================================================================
Deno.test("HEF-C01 — clampInt — null uses fallback", () => {
  assertEquals(clampInt(null, 1, 10, 3), 3);
});

Deno.test("HEF-C02 — clampInt — out-of-range clamps", () => {
  assertEquals(clampInt("0", 1, 10, 3), 1);
  assertEquals(clampInt("999", 1, 10, 3), 10);
});

Deno.test("HEF-C03 — clampInt — non-numeric falls back", () => {
  assertEquals(clampInt("xyz", 1, 10, 3), 3);
});

Deno.test("HEF-C04 — clampInt — happy path", () => {
  assertEquals(clampInt("5", 1, 10, 3), 5);
});

Deno.test("HEF-C05 — parseCountRange — canonical PostgREST shape", () => {
  assertEquals(parseCountRange("0-9/42"), 42);
  assertEquals(parseCountRange("*/0"), 0);
});

Deno.test("HEF-C06 — parseCountRange — null / malformed → 0", () => {
  assertEquals(parseCountRange(null), 0);
  assertEquals(parseCountRange("garbage"), 0);
  assertEquals(parseCountRange("0-9/"), 0);
});

// =============================================================================
// 7. htmlToText — Riigikogu eelnõu page sanity
// =============================================================================
Deno.test("HEF-H01 — strips script + style", () => {
  const html = "<p>kept</p><script>alert(1)</script><style>p{}</style>";
  const txt = htmlToText(html);
  assert(txt.includes("kept"));
  assertFalse(txt.includes("alert"));
  assertFalse(txt.includes("p{"));
});

Deno.test("HEF-H02 — decodes common entities", () => {
  const html = "<p>&nbsp;§&nbsp;114 &amp; §115</p>";
  const txt = htmlToText(html);
  assert(txt.includes("§ 114"));
  assert(txt.includes("&"));
});

Deno.test("HEF-H03 — preserves Estonian diacritics", () => {
  const html =
    "<p>§ 11. Eelnõu sisu ja võrdlev analüüs põhiseaduse alusel.</p>";
  const txt = htmlToText(html);
  assert(txt.includes("Eelnõu"));
  assert(txt.includes("võrdlev"));
  assert(txt.includes("analüüs"));
  assert(txt.includes("põhiseaduse"));
});

Deno.test("HEF-H04 — preserves Finnish diacritics", () => {
  const html =
    "<div>HE 217/1995 vp koskee menetetyn määräajan palauttamista hallintoasioissa.</div>";
  const txt = htmlToText(html);
  assert(txt.includes("määräajan"));
  assert(txt.includes("palauttamista"));
  assert(txt.includes("hallintoasioissa"));
});

Deno.test("HEF-H05 — block tags become newlines", () => {
  const html = "<p>a</p><p>b</p><p>c</p>";
  const txt = htmlToText(html);
  assert(txt.split(/\n/).filter((l) => l.trim().length > 0).length === 3);
});

// =============================================================================
// 7.5. bytesToBase64 — round-trip + chunked correctness
// =============================================================================
Deno.test("HEF-B01 — bytesToBase64 round-trip on small bytes", () => {
  const bytes = new Uint8Array([0x48, 0x65, 0x6c, 0x6c, 0x6f]); // "Hello"
  assertEquals(bytesToBase64(bytes), "SGVsbG8=");
});

Deno.test("HEF-B02 — bytesToBase64 handles >32KB (chunked path)", () => {
  // 100KB of repeating bytes — exercises the 32KB chunking loop.
  const n = 100 * 1024;
  const bytes = new Uint8Array(n);
  for (let i = 0; i < n; i++) bytes[i] = (i * 7) & 0xff;
  const b64 = bytesToBase64(bytes);
  // Decode via atob and compare lengths byte-for-byte.
  const decoded = atob(b64);
  assertEquals(decoded.length, n);
  // Spot-check a few bytes.
  assertEquals(decoded.charCodeAt(0), 0);
  assertEquals(decoded.charCodeAt(1), 7);
  assertEquals(decoded.charCodeAt(100), (100 * 7) & 0xff);
  assertEquals(decoded.charCodeAt(n - 1), ((n - 1) * 7) & 0xff);
});

Deno.test("HEF-B03 — bytesToBase64 empty input → empty string", () => {
  assertEquals(bytesToBase64(new Uint8Array(0)), "");
});

// =============================================================================
// 8. ExtractedTravauxChunk type smoke (compile-time, but assert at runtime)
// =============================================================================
Deno.test("HEF-X01 — ExtractedTravauxChunk shape", () => {
  const chunk: ExtractedTravauxChunk = {
    section_ref: "114",
    text: "x".repeat(200),
  };
  assertEquals(typeof chunk.section_ref, "string");
  assertEquals(typeof chunk.text, "string");
  // Round-trip through parser → still recognisable as ExtractedTravauxChunk.
  const json = JSON.stringify([chunk]);
  const parsed = parseTravauxOutput(json);
  assertEquals(parsed.length, 1);
  assertEquals(parsed[0].section_ref, "114");
  assertNotEquals(parsed[0].text.length, 0);
});

// =============================================================================
// 9. pdf_splitter — splitPdfBytes + helpers
// =============================================================================
//
// We build small in-memory PDFs (1, 90, 91, 200 pages) and verify splitting.
// pdf-lib runs in Deno cleanly via esm.sh — no native deps.
// -----------------------------------------------------------------------------

/** Build a synthetic PDF with N blank A4 pages. */
async function buildBlankPdf(pages: number): Promise<Uint8Array> {
  const doc = await PDFDocument.create();
  for (let i = 0; i < pages; i++) doc.addPage([595, 842]); // A4 in points
  return await doc.save({ useObjectStreams: true });
}

Deno.test("HEF-SPLIT01 — single-page PDF returns ONE segment, full bytes", async () => {
  const bytes = await buildBlankPdf(1);
  const out = await splitPdfBytes(bytes);
  assertEquals(out.total_pages, 1);
  assertEquals(out.segments.length, 1);
  assertEquals(out.segments[0].start_page, 1);
  assertEquals(out.segments[0].end_page, 1);
  // Single-segment fast path: same bytes passed through.
  assertEquals(out.segments[0].bytes, bytes);
});

Deno.test("HEF-SPLIT02 — PDF at PAGES_PER_SEGMENT stays single segment", async () => {
  const bytes = await buildBlankPdf(PAGES_PER_SEGMENT);
  const out = await splitPdfBytes(bytes);
  assertEquals(out.segments.length, 1);
  assertEquals(out.segments[0].end_page, PAGES_PER_SEGMENT);
});

Deno.test("HEF-SPLIT03 — PDF at PAGES_PER_SEGMENT+1 splits into 2 segments", async () => {
  const bytes = await buildBlankPdf(PAGES_PER_SEGMENT + 1);
  const out = await splitPdfBytes(bytes);
  assertEquals(out.total_pages, PAGES_PER_SEGMENT + 1);
  assertEquals(out.segments.length, 2);
  assertEquals(out.segments[0].start_page, 1);
  assertEquals(out.segments[0].end_page, PAGES_PER_SEGMENT);
  assertEquals(out.segments[1].start_page, PAGES_PER_SEGMENT + 1);
  assertEquals(out.segments[1].end_page, PAGES_PER_SEGMENT + 1);
});

Deno.test("HEF-SPLIT04 — splitting 200 pages into ceil(200/PAGES_PER_SEGMENT) segments", async () => {
  // 200 pages exercises the realistic HE 28/2003 ulkomaalaislaki case
  // (≈280p but 200 is enough to verify the loop boundary math).
  // Expected: ceil(200 / PAGES_PER_SEGMENT) segments. With current 50-page cap
  // that's 4 segments (50+50+50+50); at 90 it was 3 (90+90+20).
  const bytes = await buildBlankPdf(200);
  const out = await splitPdfBytes(bytes);
  assertEquals(out.total_pages, 200);
  assertEquals(out.segments.length, Math.ceil(200 / PAGES_PER_SEGMENT));
  // Each segment is a real PDF — verify by reloading.
  for (const seg of out.segments) {
    const reload = await PDFDocument.load(seg.bytes, { ignoreEncryption: true });
    assertEquals(reload.getPageCount(), seg.end_page - seg.start_page + 1);
  }
});

Deno.test("HEF-SPLIT05 — HARD_MAX_PAGES guard rejects absurdly long PDFs", async () => {
  // Build something just over the cap. We use a tiny page count (3) and
  // assert the helper rejects when totalPages > HARD_MAX_PAGES by stubbing
  // the assertion via a synthetic PDF of HARD_MAX_PAGES+1 pages.
  // (HARD_MAX_PAGES is 400 — building it takes a moment but pdf-lib handles it.)
  const bytes = await buildBlankPdf(HARD_MAX_PAGES + 1);
  try {
    await splitPdfBytes(bytes);
    throw new Error("expected splitPdfBytes to throw");
  } catch (e) {
    const msg = String(e);
    assert(msg.includes("HARD_MAX_PAGES") || msg.includes("too long"), msg);
  }
});

Deno.test("HEF-SPLIT06 — segmentBytesToBase64 round-trip", () => {
  const bytes = new Uint8Array([0x25, 0x50, 0x44, 0x46]); // "%PDF"
  assertEquals(segmentBytesToBase64(bytes), "JVBERg==");
});

Deno.test("HEF-SPLIT07 — invariants: PAGES_PER_SEGMENT ≤ 100 (Anthropic cap)", () => {
  // Anthropic's hard cap is 100 pages/document. We leave headroom.
  assert(PAGES_PER_SEGMENT > 0);
  assert(PAGES_PER_SEGMENT <= 100);
  assert(HARD_MAX_PAGES >= PAGES_PER_SEGMENT);
  assert(MAX_PDF_BYTES > 0);
});

Deno.test("HEF-SPLIT08 — corrupt bytes throw a useful error", async () => {
  const bytes = new TextEncoder().encode("not a pdf");
  try {
    await splitPdfBytes(bytes);
    throw new Error("expected throw");
  } catch (e) {
    const msg = String(e);
    assert(msg.includes("pdf-lib load failed") || msg.includes("load"), msg);
  }
});

// =============================================================================
// 9.5. pdf_splitter — streaming API (planAndStream) — Fix #89 round 3
// =============================================================================
Deno.test("HEF-STREAM01 — planAndStream single-segment PDF yields exactly 1", async () => {
  const bytes = await buildBlankPdf(PAGES_PER_SEGMENT);
  const { plan, iterator } = await planAndStream(bytes);
  assertEquals(plan.segment_count, 1);
  assertEquals(plan.total_pages, PAGES_PER_SEGMENT);
  const segs = [];
  for await (const s of iterator) segs.push(s);
  assertEquals(segs.length, 1);
  assertEquals(segs[0].start_page, 1);
  assertEquals(segs[0].end_page, PAGES_PER_SEGMENT);
  // Fast path passes the original bytes through unchanged.
  assertEquals(segs[0].bytes, bytes);
});

Deno.test("HEF-STREAM02 — planAndStream multi-segment yields N PDFs lazily", async () => {
  // 3-segment case mirrors HE 72/2002 vp (143 pages at 50-page cap).
  const totalPages = PAGES_PER_SEGMENT * 2 + 5;
  const bytes = await buildBlankPdf(totalPages);
  const { plan, iterator } = await planAndStream(bytes);
  assertEquals(plan.total_pages, totalPages);
  assertEquals(plan.segment_count, 3);
  let i = 0;
  let totalPagesYielded = 0;
  for await (const seg of iterator) {
    i++;
    const sub = await PDFDocument.load(seg.bytes, { ignoreEncryption: true });
    const subPages = sub.getPageCount();
    assertEquals(subPages, seg.end_page - seg.start_page + 1);
    totalPagesYielded += subPages;
    // Each yielded `seg` reference is the only handle to those bytes — the
    // caller can let it fall out of scope.
  }
  assertEquals(i, 3);
  assertEquals(totalPagesYielded, totalPages);
});

Deno.test("HEF-STREAM03 — planAndStream rejects HARD_MAX_PAGES overflow before iteration", async () => {
  // Verify the guard fires at plan() time (early failure), not on first yield.
  const bytes = await buildBlankPdf(HARD_MAX_PAGES + 1);
  try {
    await planAndStream(bytes);
    throw new Error("expected throw");
  } catch (e) {
    const msg = String(e);
    assert(msg.includes("HARD_MAX_PAGES") || msg.includes("too long"), msg);
  }
});
