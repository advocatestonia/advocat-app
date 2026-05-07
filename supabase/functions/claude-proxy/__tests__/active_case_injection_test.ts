// Deno tests for Pkg 1.B — Case Memory injection in claude-proxy.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/claude-proxy/__tests__/active_case_injection_test.ts
//
// Spec: memory: project_handoff_smart_lawyer.md "Как подмешиваем в промпт".
//   * `case_id` plumbing on the request body.
//   * Block format & section ordering.
//   * 30 KB progressive trim sequence.
//   * Insertion lands AFTER legal corpus / BEFORE OUTPUT FORMAT in the
//     existing Advocat system prompt.
//   * No-op when payload is null (RPC missed or RLS-blocked).
//   * Marker still satisfies system_prompt_guard whitelist after injection.
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  applyActiveCaseToBody,
  formatActiveCaseBlock,
  formatActiveCaseBlockWithCap,
  injectIntoSystemPrompt,
  isValidCaseId,
  MAX_ACTIVE_CASE_BYTES,
} from "../active_case_injection.ts";
import {
  ADVOCAT_IDENTITY_MARKERS,
  validateSystemPrompt,
} from "../system_prompt_guard.ts";

// ---- Reusable fixtures -----------------------------------------------------

const CANONICAL_PROMPT = [
  "# ROLE",
  "",
  "You are Advocat, an AI legal assistant for people in Europe.",
  "",
  "# RULES",
  "1. NEVER claim to be a lawyer.",
  "",
  "# WHAT WE KNOW ABOUT YOU",
  "User name: Sofia",
  "",
  "# LEGAL KNOWLEDGE BASE",
  "",
  "Estonian admin procedure: HMS § 26 — vaide esitamine 30 päeva jooksul.",
  "",
  "# OUTPUT FORMAT",
  "- write naturally",
].join("\n");

function basePayload() {
  return {
    case: {
      id: "550e8400-e29b-41d4-a716-446655440000",
      user_id: "user-1",
      title: "Sulga FI deportation appeal",
      jurisdiction: "FI",
      case_type: "immigration",
      status: "active",
      case_numbers: ["5500/R/75170/25", "12345/SAL/26"],
      parties: ["Dmitri Sulga (asianomistaja)", "Migri (vastaaja)"],
      key_dates: ["2026-01-04 — appeal deadline"],
      authorities: ["Helsingin hallinto-oikeus", "Migri"],
      timeline: [
        "2025-12-04 — käännyttämispäätös received",
        "2025-12-15 — meeting with lawyer",
        "2026-01-02 — draft appeal sent for review",
      ],
      open_questions: [
        "Is the deadline calendar or working days?",
      ],
      next_actions: [
        "File appeal with hallinto-oikeus by 2026-01-04",
      ],
      summary: "Käännyttämispäätös 04.12.2025; 30 päeva apellatsiooniks.",
      language: "ru",
    },
    recent_documents: [
      {
        id: "doc1",
        filename: "kaannyttamispaatos_2025-12-04.pdf",
        doc_type: "court_decision",
        doc_date: "2025-12-04",
        parsed_summary: "Migri käännyttämispäätös. Perustelut Ulkomaalaislaki 142 §.",
        uploaded_at: "2025-12-05T10:00:00Z",
      },
    ],
  };
}

// ---- isValidCaseId ---------------------------------------------------------

Deno.test("CM-T01 — isValidCaseId accepts UUID v4", () => {
  assertEquals(isValidCaseId("550e8400-e29b-41d4-a716-446655440000"), true);
});

Deno.test("CM-T02 — isValidCaseId rejects 'general'", () => {
  assertEquals(isValidCaseId("general"), false);
});

Deno.test("CM-T03 — isValidCaseId rejects empty / undefined / non-string", () => {
  assertEquals(isValidCaseId(""), false);
  assertEquals(isValidCaseId(undefined), false);
  assertEquals(isValidCaseId(null), false);
  assertEquals(isValidCaseId(42), false);
  assertEquals(isValidCaseId({ id: "550e8400-e29b-41d4-a716-446655440000" }), false);
});

// ---- formatActiveCaseBlock — section presence & order ----------------------

Deno.test("CM-T10 — block contains all canonical sections in order", () => {
  const out = formatActiveCaseBlock(basePayload(), "full");
  // Tag wrapper.
  assertStringIncludes(out, "<active_case>");
  assertStringIncludes(out, "</active_case>");
  // Required headers — preserve order by checking indexes monotonic.
  const order = [
    "Title:",
    "Jurisdiction:",
    "Status:",
    "Case numbers:",
    "Authorities:",
    "Parties:",
    "Timeline:",
    "Summary:",
    "Open questions:",
    "Next actions:",
    "Recent documents:",
  ];
  let lastIdx = -1;
  for (const head of order) {
    const idx = out.indexOf(head);
    if (idx < 0) throw new Error(`Section '${head}' missing`);
    if (idx <= lastIdx) {
      throw new Error(
        `Section order broken at '${head}' (idx=${idx}, last=${lastIdx})`,
      );
    }
    lastIdx = idx;
  }
});

Deno.test("CM-T11 — block surfaces case numbers & authorities verbatim", () => {
  const out = formatActiveCaseBlock(basePayload());
  assertStringIncludes(out, "5500/R/75170/25");
  assertStringIncludes(out, "Helsingin hallinto-oikeus");
});

Deno.test("CM-T12 — full level renders parsed_summary first line", () => {
  const out = formatActiveCaseBlock(basePayload(), "full");
  assertStringIncludes(out, "kaannyttamispaatos_2025-12-04.pdf");
  assertStringIncludes(out, "Migri käännyttämispäätös");
});

Deno.test("CM-T13 — no-doc-summaries level keeps filename, drops summary", () => {
  const out = formatActiveCaseBlock(basePayload(), "no-doc-summaries");
  assertStringIncludes(out, "kaannyttamispaatos_2025-12-04.pdf");
  // The summary text MUST NOT appear at this trim level.
  if (out.includes("Migri käännyttämispäätös")) {
    throw new Error("parsed_summary must be dropped at no-doc-summaries");
  }
});

Deno.test("CM-T14 — trimmed-timeline keeps last 10 events", () => {
  const p = basePayload();
  p.case.timeline = Array.from({ length: 20 }, (_, i) => `event-${i}`);
  const out = formatActiveCaseBlock(p, "trimmed-timeline");
  // First 10 dropped: event-0..event-9 absent. Last 10 kept: event-10..event-19.
  for (let i = 0; i < 10; i++) {
    if (out.includes(`event-${i}\n`) || out.endsWith(`event-${i}`)) {
      throw new Error(`event-${i} must be trimmed at trimmed-timeline`);
    }
  }
  assertStringIncludes(out, "event-19");
  assertStringIncludes(out, "event-10");
});

Deno.test("CM-T15 — minimal level keeps only summary/open_q/next_actions/case_numbers", () => {
  const out = formatActiveCaseBlock(basePayload(), "minimal");
  // Required at minimal:
  assertStringIncludes(out, "Title:");
  assertStringIncludes(out, "Jurisdiction:");
  assertStringIncludes(out, "Status:");
  assertStringIncludes(out, "Case numbers:");
  assertStringIncludes(out, "Summary:");
  assertStringIncludes(out, "Open questions:");
  assertStringIncludes(out, "Next actions:");
  // Stripped at minimal:
  for (const stripped of [
    "Authorities:",
    "Parties:",
    "Timeline:",
    "Recent documents:",
  ]) {
    if (out.includes(stripped)) {
      throw new Error(`'${stripped}' must be dropped at minimal level`);
    }
  }
});

// ---- formatActiveCaseBlockWithCap — progressive trim sequence --------------

Deno.test("CM-T20 — small case fits at full level", () => {
  const out = formatActiveCaseBlockWithCap(basePayload(), MAX_ACTIVE_CASE_BYTES);
  if (out === null) throw new Error("Small case must fit at full level");
  assertStringIncludes(out!, "Recent documents:");
});

Deno.test("CM-T21 — overflow drops parsed_summary first (step 1)", () => {
  const p = basePayload();
  // Inflate parsed_summary alone to push past 30 KB but leave structure
  // small enough that no-doc-summaries fits.
  p.recent_documents[0].parsed_summary = "X".repeat(35_000);
  const out = formatActiveCaseBlockWithCap(p, MAX_ACTIVE_CASE_BYTES);
  if (out === null) throw new Error("Trimmed result should fit");
  // Filename must survive.
  assertStringIncludes(out!, "kaannyttamispaatos_2025-12-04.pdf");
  // Summary X-runs must be gone (no 35 KB X's left).
  if (out!.includes("X".repeat(100))) {
    throw new Error("parsed_summary must be dropped at no-doc-summaries level");
  }
  // Other sections still present (didn't trim further than needed).
  assertStringIncludes(out!, "Timeline:");
});

Deno.test("CM-T22 — extreme overflow lands at minimal level", () => {
  // Use a SMALL byte cap so the trim path is forced down to minimal.
  // (Real-world case-memory rarely exceeds the 30 KB cap, so we exercise
  // the cap arithmetic here with a small synthetic budget.)
  const p = basePayload();
  // Inflate authorities/parties — even after trimming to last 5, each is
  // still >200 bytes, so trimmed-parties stays > 1500 bytes. Add a long
  // doc list so no-doc-summaries also stays heavy.
  p.case.parties = Array.from({ length: 50 }, (_, i) => "P".repeat(400) + i);
  p.case.authorities = Array.from({ length: 50 }, (_, i) => "A".repeat(400) + i);
  p.case.timeline = Array.from({ length: 50 }, (_, i) => "T".repeat(400) + i);
  p.recent_documents = Array.from({ length: 50 }, (_, i) => ({
    id: `test-doc-id-${i}`,
    filename: `doc${"X".repeat(80)}-${i}.pdf`,
    doc_type: "court_decision",
    parsed_summary: "S".repeat(800),
    doc_date: "2026-04-01",
    uploaded_at: "2026-04-01T00:00:00Z",
  }));
  // Tight 1500-byte cap forces minimal — none of the upper levels can fit.
  const out = formatActiveCaseBlockWithCap(p, 1500);
  if (out === null) throw new Error("Minimal level must always fit");
  // Minimal-level invariants.
  assertStringIncludes(out!, "Summary:");
  assertStringIncludes(out!, "Case numbers:");
  // No parties / timeline / docs at minimal.
  if (out!.includes("Parties:")) {
    throw new Error("minimal level must drop Parties");
  }
  if (out!.includes("Recent documents:")) {
    throw new Error("minimal level must drop Recent documents");
  }
  if (out!.includes("Timeline:")) {
    throw new Error("minimal level must drop Timeline");
  }
});

// ---- injectIntoSystemPrompt — placement & idempotency ----------------------

Deno.test("CM-T30 — injects BEFORE '# OUTPUT FORMAT' (after legal corpus)", () => {
  const block = formatActiveCaseBlock(basePayload(), "minimal");
  const injected = injectIntoSystemPrompt(CANONICAL_PROMPT, block);

  const acIdx = injected.indexOf("<active_case>");
  const lkbIdx = injected.indexOf("# LEGAL KNOWLEDGE BASE");
  const memIdx = injected.indexOf("# WHAT WE KNOW ABOUT YOU");
  const outIdx = injected.indexOf("# OUTPUT FORMAT");

  if (acIdx < 0) throw new Error("active_case must be present");
  if (acIdx <= lkbIdx) {
    throw new Error("active_case must land AFTER legal corpus");
  }
  if (acIdx <= memIdx) {
    throw new Error(
      "active_case must land AFTER memory section (memory is at top of " +
        "this canonical prompt — model already consumed it)",
    );
  }
  if (acIdx >= outIdx) {
    throw new Error("active_case must land BEFORE # OUTPUT FORMAT");
  }
});

Deno.test("CM-T31 — idempotent: repeat inject does not duplicate", () => {
  const block = formatActiveCaseBlock(basePayload(), "minimal");
  const once = injectIntoSystemPrompt(CANONICAL_PROMPT, block);
  const twice = injectIntoSystemPrompt(once, block);
  // Exactly one <active_case> opener.
  const matches = twice.match(/<active_case>/g) ?? [];
  assertEquals(matches.length, 1);
});

Deno.test("CM-T32 — guard whitelist still satisfied after injection", () => {
  const block = formatActiveCaseBlock(basePayload(), "minimal");
  const injected = injectIntoSystemPrompt(CANONICAL_PROMPT, block);
  const res = validateSystemPrompt(injected);
  assertEquals(res.kind, "allow");
});

Deno.test("CM-T33 — empty block returns prompt unchanged", () => {
  const out = injectIntoSystemPrompt(CANONICAL_PROMPT, "");
  assertEquals(out, CANONICAL_PROMPT);
});

Deno.test("CM-T34 — case-memory marker is whitelisted", () => {
  // Pre-whitelist for Pkg 1.D — the marker must appear in the guard list
  // even though today's chat path injects in the middle of the prompt.
  const has = ADVOCAT_IDENTITY_MARKERS.some((m) =>
    m.includes("case memory")
  );
  if (!has) {
    throw new Error("case-memory identity marker must be whitelisted");
  }
});

// ---- applyActiveCaseToBody — wire integration -----------------------------

Deno.test("CM-T40 — null payload no-ops (chat continues unaffected)", () => {
  const body = { system: CANONICAL_PROMPT, messages: [] };
  applyActiveCaseToBody(body, null);
  assertEquals(body.system, CANONICAL_PROMPT);
});

Deno.test("CM-T41 — payload.case=null no-ops", () => {
  const body = { system: CANONICAL_PROMPT };
  applyActiveCaseToBody(body, { case: null, recent_documents: [] });
  assertEquals(body.system, CANONICAL_PROMPT);
});

Deno.test("CM-T42 — string system gets <active_case> spliced in", () => {
  const body: { system: unknown } = { system: CANONICAL_PROMPT };
  applyActiveCaseToBody(body, basePayload());
  const sys = body.system as string;
  assertStringIncludes(sys, "<active_case>");
  assertStringIncludes(sys, "Sulga FI deportation appeal");
  // Guard still passes.
  assertEquals(validateSystemPrompt(sys).kind, "allow");
});

Deno.test("CM-T43 — array system splices into FIRST text block", () => {
  const body: { system: unknown } = {
    system: [
      { type: "text", text: CANONICAL_PROMPT, cache_control: { type: "ephemeral" } },
      { type: "text", text: "Dynamic context" },
    ],
  };
  applyActiveCaseToBody(body, basePayload());
  const arr = body.system as Array<{ text: string }>;
  assertStringIncludes(arr[0].text, "<active_case>");
  // Second block untouched.
  assertEquals(arr[1].text, "Dynamic context");
});

// ---- Source contract — index.ts wires it all together --------------------

Deno.test("CM-T50 — index.ts imports active_case_injection and reads case_id", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "active_case_injection.ts");
  assertStringIncludes(source, "loadActiveCase");
  assertStringIncludes(source, "applyActiveCaseToBody");
  assertStringIncludes(source, "case_id");
  // Case id strip BEFORE forwarding (Anthropic does not know `case_id`).
  assertStringIncludes(source, "delete body.case_id");
});

Deno.test("CM-T51 — non-UUID case_id returns 400", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // 400 path lives near the case_id branch.
  assertStringIncludes(source, "case_id must be a UUID");
});

Deno.test("CM-T52 — case-memory injection runs BEFORE the guard", async () => {
  // Order is load-bearing: the guard validates the FINAL system prompt
  // (after our splice). If the splice ran AFTER the guard, an injected
  // marker change couldn't be enforced at admission time.
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  const applyIdx = stripped.indexOf("applyActiveCaseToBody(");
  const guardIdx = stripped.indexOf("validateSystemPrompt(");
  if (applyIdx === -1 || guardIdx === -1) {
    throw new Error("Contract points missing from index.ts");
  }
  if (applyIdx >= guardIdx) {
    throw new Error(
      "Case-memory injection must run BEFORE the guard so the guard " +
        "validates the final system prompt the proxy will forward.",
    );
  }
});
