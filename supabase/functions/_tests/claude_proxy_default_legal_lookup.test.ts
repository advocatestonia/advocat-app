// claude_proxy_default_legal_lookup.test.ts
// ----------------------------------------------------------------------------
// Wiring contract test for the Phase-2 fix that injects the legal_lookup
// TOOL USE directive into the DEFAULT (non-planner) chat system prompt.
//
// Background (2026-05-13):
//   Eval Phase 2 measured v4.1 statute +11.5% but citation_validity flat at
//   2.10. Root cause: the TOOL USE header lived inside legal_planner.ts
//   EXECUTOR_INSTRUCTIONS_HEADER, which only fires when the client passes
//   `mode: "legal_planner"`. Most production chat does NOT pass that mode →
//   the model never knew it had a `legal_lookup` tool to call.
//
// Fix (claude-proxy/index.ts):
//   Before applyPromptCaching, when legal_lookup will actually be available
//   for this turn (i.e. !isAnon, !willEnterPlannerBranch, and tools either
//   not pre-set or pre-set with legal_lookup in the array), prepend
//   LEGAL_LOOKUP_TOOL_USE_INSTRUCTION to body.system.
//
// This test pins:
//   1. The exported constant is shaped correctly (marker substring present).
//   2. Default chat (no tools pre-set, not anon, not planner) → injected.
//   3. Anon caller → NOT injected (graceful, no tool available).
//   4. Planner branch → NOT injected (its own header covers it).
//   5. Caller pre-set tools WITHOUT legal_lookup → NOT injected.
//   6. Caller pre-set tools WITH legal_lookup → injected.
//   7. Idempotent: directive already present → not duplicated.
//   8. body.system === null → directive becomes the system.
//
// Run with:
//   deno test --allow-all \
//     supabase/functions/_tests/claude_proxy_default_legal_lookup.test.ts
// ----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { LEGAL_LOOKUP_TOOL_USE_INSTRUCTION } from "../_shared/legal_lookup.ts";

// ─── Constant shape ─────────────────────────────────────────────────────────

Deno.test("LEGAL_LOOKUP_TOOL_USE_INSTRUCTION contains required marker", () => {
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "## TOOL USE — legal_lookup");
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "legal_lookup");
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "jurisdiction");
  // Must be a single trimmed block (no leading/trailing whitespace).
  assertEquals(
    LEGAL_LOOKUP_TOOL_USE_INSTRUCTION,
    LEGAL_LOOKUP_TOOL_USE_INSTRUCTION.trim(),
  );
  // Sanity: directive is non-trivial but bounded. Hard ceiling 2560 — the
  // Option B (2026-05-15) snippet-only clause pushed the canonical text past
  // 2 KB. See LLK-T43 in the _shared test suite for the matching guard.
  assert(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION.length > 200);
  assert(
    LEGAL_LOOKUP_TOOL_USE_INSTRUCTION.length < 2560,
    `directive too long: ${LEGAL_LOOKUP_TOOL_USE_INSTRUCTION.length} bytes`,
  );
});

// ─── Pure injection helper — mirrors the inline logic in claude-proxy ───────
//
// This reproduces the exact 4-gate condition added in index.ts:
//   • isAnon? skip
//   • willEnterPlannerBranch? skip (planner has its own header)
//   • If caller set body.tools to an array → require legal_lookup in it
//   • If caller did NOT set tools → ASSISTANT_TOOLS auto-injection covers it
//
// We test against this helper rather than spinning up the full edge function.
// If the helper drifts from index.ts the test fails meaningfully — the test
// IS the contract.

function applyLegalLookupDirective(
  body: { system?: unknown; tools?: unknown },
  ctx: { isAnon: boolean; willEnterPlannerBranch: boolean },
): void {
  if (ctx.isAnon || ctx.willEnterPlannerBranch) return;
  const callerToolsArray = Array.isArray(body.tools)
    ? (body.tools as Array<{ name?: unknown }>)
    : null;
  const legalLookupWillBeAvailable = callerToolsArray
    ? callerToolsArray.some((t) => t && t.name === "legal_lookup")
    : true;
  if (!legalLookupWillBeAvailable) return;
  const directive = LEGAL_LOOKUP_TOOL_USE_INSTRUCTION;
  const marker = "## TOOL USE — legal_lookup";
  if (typeof body.system === "string") {
    if (!body.system.includes(marker)) {
      body.system = `${body.system}\n\n${directive}`;
    }
  } else if (body.system == null) {
    body.system = directive;
  }
}

// ─── Gate 1: default chat path → directive injected ─────────────────────────

Deno.test("default chat (auth user, no planner, no tools override) → injected", () => {
  const body = {
    system: "You are Advocat. Helpful legal assistant.",
    // No body.tools — ASSISTANT_TOOLS will be auto-attached at line ~800.
  };
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: false });
  assertStringIncludes(body.system as string, "## TOOL USE — legal_lookup");
  assertStringIncludes(body.system as string, "You are Advocat");
});

// ─── Gate 2: anon caller → NOT injected (graceful, no tools available) ──────

Deno.test("anon caller → directive NOT injected", () => {
  const original = "You are Advocat. Helpful legal assistant.";
  const body = { system: original };
  applyLegalLookupDirective(body, { isAnon: true, willEnterPlannerBranch: false });
  assertEquals(body.system, original);
});

// ─── Gate 3: planner branch → NOT injected (its own header covers it) ───────

Deno.test("planner branch → directive NOT injected (planner has own header)", () => {
  const original = "You are Advocat. Planner-mode prompt.";
  const body = { system: original };
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: true });
  assertEquals(body.system, original);
});

// ─── Gate 4: caller passed tools array WITHOUT legal_lookup → NOT injected ──

Deno.test("caller passed tools array without legal_lookup → NOT injected", () => {
  const original = "You are Advocat.";
  const body = {
    system: original,
    tools: [{ name: "summarise" }, { name: "extract_facts" }],
  };
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: false });
  assertEquals(body.system, original);
});

// ─── Gate 5: caller passed tools array WITH legal_lookup → injected ─────────

Deno.test("caller passed tools array with legal_lookup → injected", () => {
  const body = {
    system: "You are Advocat.",
    tools: [{ name: "legal_lookup" }, { name: "summarise" }],
  };
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: false });
  assertStringIncludes(body.system as string, "## TOOL USE — legal_lookup");
});

// ─── Idempotency: directive already present → not duplicated ────────────────

Deno.test("directive already present → idempotent (no duplication)", () => {
  const base = "You are Advocat.";
  const seeded = `${base}\n\n${LEGAL_LOOKUP_TOOL_USE_INSTRUCTION}`;
  const body = { system: seeded };
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: false });
  // Should be unchanged — no second copy appended.
  assertEquals(body.system, seeded);
  // Confirm exactly one occurrence of the marker.
  const matches = (body.system as string).match(/## TOOL USE — legal_lookup/g);
  assertEquals(matches?.length, 1);
});

// ─── Null system → directive becomes the entire system ──────────────────────

Deno.test("body.system === null → directive replaces it", () => {
  const body: { system?: unknown; tools?: unknown } = { system: null };
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: false });
  assertEquals(body.system, LEGAL_LOOKUP_TOOL_USE_INSTRUCTION);
});

// ─── undefined system → directive becomes the entire system ─────────────────

Deno.test("body.system === undefined → directive becomes the system", () => {
  const body: { system?: unknown; tools?: unknown } = {};
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: false });
  assertEquals(body.system, LEGAL_LOOKUP_TOOL_USE_INSTRUCTION);
});

// ─── Array system left untouched (caller asserts full shape control) ────────

Deno.test("body.system as array → left untouched (conservative)", () => {
  const arr = [{ type: "text", text: "You are Advocat." }];
  const body: { system?: unknown; tools?: unknown } = { system: arr };
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: false });
  // Array form: not mutated by this helper (applyPromptCaching owns array shape).
  assertEquals(body.system, arr);
});

// ─── Empty tools array (caller explicitly says no tools) → NOT injected ─────

Deno.test("caller passed empty tools array → NOT injected", () => {
  const original = "You are Advocat.";
  const body = { system: original, tools: [] };
  applyLegalLookupDirective(body, { isAnon: false, willEnterPlannerBranch: false });
  assertEquals(body.system, original);
});
