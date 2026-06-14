// Deno tests for case-dossier-export (Case Dossier Export feature).
// -----------------------------------------------------------------------------
// Exercises the pure dossier-assembly + orchestration logic. The case-data
// fetcher and the pdf-generator caller are injected stubs, so no network /
// Supabase access is required.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/case-dossier-export/__tests__/case_dossier_export_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildDossierMarkdown,
  type CaseDossierData,
  type CaseHeader,
  fmtDate,
  mdEscape,
  type PdfGeneratorResponse,
  resolveSections,
  runDossierExport,
  validateDossierRequest,
} from "../handler.ts";

const UUID = "11111111-2222-3333-4444-555555555555";

function header(overrides: Partial<CaseHeader> = {}): CaseHeader {
  return {
    id: UUID,
    title: "Migri deportation appeal",
    jurisdiction: "FI",
    case_type: "immigration",
    status: "active",
    case_numbers: ["5500/R/75170/25"],
    parties: ["Sulga", "Migri"],
    authorities: ["KHO"],
    summary: "Appeal against deportation order.",
    language: "en",
    created_at: "2026-01-01T00:00:00.000Z",
    ...overrides,
  };
}

function fullData(overrides: Partial<CaseDossierData> = {}): CaseDossierData {
  return {
    header: header(),
    timeline: [
      {
        event_type: "email_in",
        title: "Decision received",
        summary: "Migri issued the order.",
        occurred_at: "2026-02-10T08:00:00.000Z",
      },
      {
        event_type: "deadline_set",
        title: "Appeal window opened",
        summary: null,
        occurred_at: "2026-01-05T08:00:00.000Z",
      },
    ],
    deadlines: [
      {
        title: "File KHO appeal",
        description: "Submit valituslupahakemus.",
        statute_basis: "HKMS §46",
        deadline_at: "2026-06-05T00:00:00.000Z",
        status: "active",
        priority: "critical",
        holiday_shifted: true,
      },
    ],
    documents: [
      {
        filename: "decision.pdf",
        doc_type: "court_decision",
        doc_date: "2026-02-10",
        parsed_summary: "The deportation order.",
      },
    ],
    ...overrides,
  };
}

const ALL_ON = {
  timeline: true,
  deadlines: true,
  documents: true,
  aiSummary: true,
};

// ─── Validation ─────────────────────────────────────────────────────────────

Deno.test("validateDossierRequest rejects non-object body", () => {
  const v = validateDossierRequest("nope");
  assert(!("ok" in v));
  if (!("ok" in v)) assertEquals(v.status, 400);
});

Deno.test("validateDossierRequest rejects missing/invalid case_id", () => {
  assert(!("ok" in validateDossierRequest({})));
  assert(!("ok" in validateDossierRequest({ case_id: "not-a-uuid" })));
});

Deno.test("validateDossierRequest accepts UUID + parses sections", () => {
  const v = validateDossierRequest({
    case_id: UUID,
    sections: { timeline: false, deadlines: true },
    locale: "et",
  });
  assert("ok" in v && v.ok);
  if ("ok" in v && v.ok) {
    assertEquals(v.req.case_id, UUID);
    assertEquals(v.req.sections?.timeline, false);
    assertEquals(v.req.sections?.deadlines, true);
    assertEquals(v.req.locale, "et");
  }
});

Deno.test("resolveSections defaults everything ON", () => {
  assertEquals(resolveSections(undefined), ALL_ON);
  assertEquals(resolveSections({ timeline: false }), {
    timeline: false,
    deadlines: true,
    documents: true,
    aiSummary: true,
  });
});

// ─── Markdown helpers ────────────────────────────────────────────────────────

Deno.test("mdEscape neutralises markdown control characters", () => {
  const out = mdEscape("# Heading * _emph_ [link]");
  // No UN-escaped heading marker survives (every # is preceded by a backslash).
  assert(!/(^|[^\\])#/.test(out));
  assertStringIncludes(out, "\\#");
  assertStringIncludes(out, "\\*");
  assertStringIncludes(out, "\\[");
});

Deno.test("mdEscape folds newlines into spaces", () => {
  assertEquals(mdEscape("a\nb\r\nc"), "a b c");
});

Deno.test("fmtDate formats ISO and passes through garbage", () => {
  assertEquals(fmtDate("2026-06-05T00:00:00.000Z"), "2026-06-05");
  assertEquals(fmtDate(null), "—");
  assertEquals(fmtDate("not-a-date"), "not-a-date");
});

// ─── Dossier assembly ────────────────────────────────────────────────────────

Deno.test("buildDossierMarkdown includes all sections when toggled on", () => {
  const { markdown, title } = buildDossierMarkdown(fullData(), ALL_ON, "en");
  assertStringIncludes(title, "Migri deportation appeal");
  assertStringIncludes(markdown, "## Case Facts");
  assertStringIncludes(markdown, "## AI Summary");
  assertStringIncludes(markdown, "## Chronology");
  assertStringIncludes(markdown, "## Deadlines");
  assertStringIncludes(markdown, "## Documents");
  // Header facts.
  assertStringIncludes(markdown, "5500/R/75170/25");
  assertStringIncludes(markdown, "Sulga; Migri");
  // Deadline meta.
  assertStringIncludes(markdown, "HKMS §46");
  assertStringIncludes(markdown, "holiday-shifted");
  // Document.
  assertStringIncludes(markdown, "decision.pdf");
});

Deno.test("buildDossierMarkdown sorts timeline ascending by date", () => {
  const { markdown } = buildDossierMarkdown(fullData(), ALL_ON, "en");
  const opened = markdown.indexOf("Appeal window opened");
  const received = markdown.indexOf("Decision received");
  assert(opened !== -1 && received !== -1);
  // 2026-01-05 should appear before 2026-02-10.
  assert(opened < received);
});

Deno.test("buildDossierMarkdown omits sections toggled off", () => {
  const { markdown } = buildDossierMarkdown(
    fullData(),
    {
      timeline: false,
      deadlines: false,
      documents: false,
      aiSummary: false,
    },
    "en"
  );
  assertStringIncludes(markdown, "## Case Facts");
  assert(!markdown.includes("## Chronology"));
  assert(!markdown.includes("## Deadlines"));
  assert(!markdown.includes("## Documents"));
  assert(!markdown.includes("## AI Summary"));
});

Deno.test("buildDossierMarkdown shows empty-state when sections empty", () => {
  const data = fullData({ timeline: [], deadlines: [], documents: [] });
  const { markdown } = buildDossierMarkdown(data, ALL_ON, "en");
  assertStringIncludes(markdown, "None recorded.");
});

Deno.test(
  "buildDossierMarkdown localises labels (et) but keeps content",
  () => {
    const { markdown, title } = buildDossierMarkdown(fullData(), ALL_ON, "et");
    assertStringIncludes(title, "Toimik:");
    assertStringIncludes(markdown, "## Asjaolud");
    assertStringIncludes(markdown, "## Kronoloogia");
    // Verbatim content unchanged.
    assertStringIncludes(markdown, "decision.pdf");
  }
);

Deno.test(
  "buildDossierMarkdown falls back to case language when no locale",
  () => {
    const data = fullData({ header: header({ language: "fi" }) });
    const { title } = buildDossierMarkdown(data, ALL_ON, undefined);
    assertStringIncludes(title, "Asiakirjavihko:");
  }
);

Deno.test("buildDossierMarkdown caps oversized markdown", () => {
  const bigSummary = "x".repeat(200_000);
  const data = fullData({ header: header({ summary: bigSummary }) });
  const { markdown } = buildDossierMarkdown(data, ALL_ON, "en");
  assert(markdown.length <= 99_100);
  assertStringIncludes(markdown, "(truncated)");
});

Deno.test("buildDossierMarkdown escapes injected headings in content", () => {
  const data = fullData({
    header: header({ summary: "## Fake heading inside summary" }),
  });
  const { markdown } = buildDossierMarkdown(data, ALL_ON, "en");
  // The injected "## " must be escaped so it can't become a real heading.
  assertStringIncludes(markdown, "\\#\\# Fake heading");
});

// ─── Orchestrator ────────────────────────────────────────────────────────────

const okPdf: PdfGeneratorResponse = {
  download_url: "https://example.com/signed",
  storage_path: "user/generated/dossier.html",
  filename: "case_dossier.html",
  document_id: "doc-123",
};

Deno.test("runDossierExport returns 404 when case not owned", async () => {
  const res = await runDossierExport({
    body: { case_id: UUID },
    userId: "user-1",
    fetchCaseData: () =>
      Promise.resolve({
        header: null,
        timeline: [],
        deadlines: [],
        documents: [],
      }),
    callPdfGenerator: () => Promise.resolve({ ok: true, body: okPdf }),
  });
  assertEquals(res.status, 404);
});

Deno.test("runDossierExport 400 on invalid body (no pdf call)", async () => {
  let called = false;
  const res = await runDossierExport({
    body: { case_id: "bad" },
    userId: "user-1",
    fetchCaseData: () => {
      called = true;
      return Promise.resolve(fullData());
    },
    callPdfGenerator: () => Promise.resolve({ ok: true, body: okPdf }),
  });
  assertEquals(res.status, 400);
  assert(!called, "fetcher must not run on validation failure");
});

Deno.test(
  "runDossierExport happy path passes markdown to pdf-generator",
  async () => {
    const captured: {
      value: {
        body_markdown: string;
        doc_type: string;
        case_id: string;
      } | null;
    } = { value: null };
    const res = await runDossierExport({
      body: { case_id: UUID, locale: "en" },
      userId: "user-1",
      fetchCaseData: () => Promise.resolve(fullData()),
      callPdfGenerator: (p) => {
        captured.value = p;
        return Promise.resolve({ ok: true, body: okPdf });
      },
    });
    assertEquals(res.status, 200);
    if (res.kind === "success") {
      assertEquals(res.body.download_url, okPdf.download_url);
      assertEquals(res.body.document_id, "doc-123");
      assert(res.body.dossier_length > 0);
    }
    assert(captured.value !== null);
    assertEquals(captured.value!.doc_type, "case_dossier");
    assertEquals(captured.value!.case_id, UUID);
    assertStringIncludes(captured.value!.body_markdown, "## Chronology");
  }
);

Deno.test("runDossierExport surfaces pdf-generator 403 as 403", async () => {
  const res = await runDossierExport({
    body: { case_id: UUID },
    userId: "user-1",
    fetchCaseData: () => Promise.resolve(fullData()),
    callPdfGenerator: () =>
      Promise.resolve({ ok: false, status: 403, error: "Case not owned" }),
  });
  assertEquals(res.status, 403);
});

Deno.test(
  "runDossierExport maps other pdf-generator errors to 502",
  async () => {
    const res = await runDossierExport({
      body: { case_id: UUID },
      userId: "user-1",
      fetchCaseData: () => Promise.resolve(fullData()),
      callPdfGenerator: () =>
        Promise.resolve({ ok: false, status: 500, error: "boom" }),
    });
    assertEquals(res.status, 502);
  }
);

Deno.test("runDossierExport maps fetcher throw to 500", async () => {
  const res = await runDossierExport({
    body: { case_id: UUID },
    userId: "user-1",
    fetchCaseData: () => Promise.reject(new Error("db down")),
    callPdfGenerator: () => Promise.resolve({ ok: true, body: okPdf }),
  });
  assertEquals(res.status, 500);
});

Deno.test("runDossierExport maps pdf caller throw to 502", async () => {
  const res = await runDossierExport({
    body: { case_id: UUID },
    userId: "user-1",
    fetchCaseData: () => Promise.resolve(fullData()),
    callPdfGenerator: () => Promise.reject(new Error("network")),
  });
  assertEquals(res.status, 502);
});
