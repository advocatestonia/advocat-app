// claude-proxy/__tests__/agent_loop_client_tool_passthrough_test.ts
// -----------------------------------------------------------------------------
// Regression lock for the 2026-07-02 fix: "two agent tool universes collide".
//
// Context (see MEMORY.md / audit): the Flutter client advertises ~30
// "do things in the app" tools (create_deadline, navigate_to,
// change_language, create_case, …) via ToolDefinitions.allTools
// (lib/services/tool_definitions.dart), on top of the 8 SERVER tools this
// edge function actually executes (list_inbox, read_thread_full,
// run_pdf_parser, run_consilium, send_email, draft_email_with_attachments,
// generate_pdf, legal_lookup — see tool_handlers.ts ASSISTANT_TOOLS).
//
// Before the fix, index.ts's agent loop always called executeToolCalls on
// every tool_use batch Anthropic returned. When the model called a
// CLIENT-only tool (e.g. create_deadline), executeSingleTool's `default:`
// case answered with `{is_error:true, content:"Unknown tool: create_deadline"}`.
// The model read that as a real failure — the app-action never ran, no
// approval card appeared, and the loop either retried or apologised in text.
//
// The fix adds `isServerTool` / `SERVER_TOOL_NAMES` (tool_handlers.ts,
// derived from ASSISTANT_TOOLS so the two can never drift) and uses it in
// index.ts's loop: BEFORE calling executeToolCalls on a tool_use batch, if
// ANY block names a non-server tool, the loop stops and returns the raw
// Anthropic response verbatim (content[] + stop_reason="tool_use") as plain
// JSON — the exact shape lib/services/claude_service.dart's `_callApi`
// (used by `sendMessageWithTools`) already parses, and the exact shape
// lib/services/agentic_loop.dart's `runAgenticLoop` while-loop already
// consumes via its own `stop_reason === 'tool_use'` branch (verified by
// reading agentic_loop.dart:183-241 — it dispatches non-approval tools via
// `executeTool` immediately and pauses write tools for the existing
// Approve/Decline UI). No client-side change was required.
//
// This file locks two properties at the unit level (index.ts cannot be
// imported directly for HTTP-level testing — it calls Deno.serve() at
// module load, same constraint documented in agent_loop_e2e_sulga_test.ts):
//
//   T1 — isServerTool / SERVER_TOOL_NAMES correctly classify every tool
//        name from both universes (regression lock on the classification
//        table itself, so an edit to either tool list is caught here).
//   T2 — replaying index.ts's EXACT decision expression
//        (`toolBlocks.find((b) => !isServerTool(b.name))`) against a
//        response containing ONLY a client-only tool_use block returns
//        that block (→ pass-through, not executed, not "Unknown tool").
//   T3 — same expression against a response containing ONLY a server
//        tool_use block returns undefined (→ falls through to
//        executeToolCalls exactly as before — regression guard that the
//        existing 8 server tools keep executing normally).
//   T4 — mixed batch (1 server + 1 client tool in the same response) is
//        treated as pass-through (finds the client tool), matching the
//        "halt on first non-executable tool" doc comment in index.ts.
//   T5 — executeToolCalls itself is UNCHANGED for a real server tool name
//        (legal_lookup) — still dispatches instead of "Unknown tool".
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// tool_handlers.ts reads SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY into module
// constants at import time (see tool_handlers_test.ts for the same pattern).
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

const { ASSISTANT_TOOLS, SERVER_TOOL_NAMES, isServerTool, executeToolCalls } =
  await import("../tool_handlers.ts");

// Minimal tool_use block shape — matches what extractToolUseBlocks() in
// tool_handlers.ts produces from a real Anthropic response.
interface FakeToolUseBlock {
  type: "tool_use";
  id: string;
  name: string;
  input: Record<string, unknown>;
}

/**
 * Replays index.ts's exact client-tool pass-through predicate
 * (`toolBlocks.find((b) => !isServerTool(b.name))`) without needing to
 * import index.ts (which calls Deno.serve() at module load and cannot be
 * unit-imported — same constraint as agent_loop_e2e_sulga_test.ts).
 */
function findClientOnlyBlock(
  toolBlocks: FakeToolUseBlock[]
): FakeToolUseBlock | undefined {
  return toolBlocks.find((b) => !isServerTool(b.name));
}

// =============================================================================
// T1 — SERVER_TOOL_NAMES / isServerTool classification table
// =============================================================================

Deno.test(
  "SERVER_TOOL_NAMES: contains exactly the 8 ASSISTANT_TOOLS names",
  () => {
    const expected = [
      "list_inbox",
      "read_thread_full",
      "run_pdf_parser",
      "run_consilium",
      "draft_email_with_attachments",
      "send_email",
      "generate_pdf",
      "legal_lookup",
    ];
    assertEquals(SERVER_TOOL_NAMES.size, expected.length);
    for (const name of expected) {
      assert(
        SERVER_TOOL_NAMES.has(name),
        `expected SERVER_TOOL_NAMES to contain ${name}`
      );
    }
    // Derived directly from ASSISTANT_TOOLS — must never drift.
    assertEquals(SERVER_TOOL_NAMES.size, ASSISTANT_TOOLS.length);
    for (const tool of ASSISTANT_TOOLS) {
      assert(SERVER_TOOL_NAMES.has(tool.name));
    }
  }
);

Deno.test("isServerTool: true for every real server tool", () => {
  for (const tool of ASSISTANT_TOOLS) {
    assert(isServerTool(tool.name), `${tool.name} should be a server tool`);
  }
});

Deno.test("isServerTool: false for client-only app-action tools", () => {
  // Sample of client-only tools from lib/services/tool_definitions.dart
  // that were previously swallowed as "Unknown tool" — the exact bug this
  // fix closes.
  const clientOnlyTools = [
    "create_deadline",
    "navigate_to",
    "change_language",
    "create_case",
    "update_case",
    "find_lawyer",
    "check_company",
    "check_vehicle",
    "translate_text",
    "open_camera",
    "draft_email",
    "get_deadlines",
    "get_case_status",
    "get_user_profile",
    "approve_send_draft", // client-side name; server knows it only via WRITE_TOOLS bookkeeping, never executes it
  ];
  for (const name of clientOnlyTools) {
    assert(
      !isServerTool(name),
      `${name} must NOT be classified as a server tool`
    );
  }
});

Deno.test("isServerTool: false for a garbage/unknown name", () => {
  assert(!isServerTool("totally_made_up_tool_xyz"));
});

// =============================================================================
// T2 — client-only tool_use batch → pass-through candidate found
// =============================================================================

Deno.test(
  "agent loop predicate: response with ONLY a client tool_use is flagged for pass-through",
  () => {
    const toolBlocks: FakeToolUseBlock[] = [
      {
        type: "tool_use",
        id: "tu_1",
        name: "create_deadline",
        input: { title: "File appeal", due_date: "2026-08-01" },
      },
    ];
    const found = findClientOnlyBlock(toolBlocks);
    assert(found !== undefined, "create_deadline must trigger pass-through");
    assertEquals(found!.name, "create_deadline");
  }
);

Deno.test(
  "agent loop predicate: navigate_to and change_language also trigger pass-through",
  () => {
    for (const name of ["navigate_to", "change_language"]) {
      const toolBlocks: FakeToolUseBlock[] = [
        { type: "tool_use", id: "tu_1", name, input: {} },
      ];
      const found = findClientOnlyBlock(toolBlocks);
      assertEquals(found?.name, name);
    }
  }
);

// =============================================================================
// T3 — server-only tool_use batch → NO pass-through (existing behaviour kept)
// =============================================================================

Deno.test(
  "agent loop predicate: response with ONLY a server tool_use is NOT flagged (falls through to executeToolCalls as before)",
  () => {
    const toolBlocks: FakeToolUseBlock[] = [
      {
        type: "tool_use",
        id: "tu_1",
        name: "legal_lookup",
        input: { query: "GDPR right of erasure", jurisdiction: "eu" },
      },
    ];
    const found = findClientOnlyBlock(toolBlocks);
    assertEquals(
      found,
      undefined,
      "legal_lookup is a server tool — must not pass through"
    );
  }
);

Deno.test(
  "agent loop predicate: all 8 server tools individually pass through unflagged",
  () => {
    for (const tool of ASSISTANT_TOOLS) {
      const toolBlocks: FakeToolUseBlock[] = [
        { type: "tool_use", id: "tu_1", name: tool.name, input: {} },
      ];
      assertEquals(
        findClientOnlyBlock(toolBlocks),
        undefined,
        `${tool.name} must not be flagged for client pass-through`
      );
    }
  }
);

// =============================================================================
// T4 — mixed batch (server + client tool together) → pass-through wins
// =============================================================================

Deno.test(
  "agent loop predicate: mixed batch (server + client tool) is flagged — halts on the non-executable one",
  () => {
    const toolBlocks: FakeToolUseBlock[] = [
      {
        type: "tool_use",
        id: "tu_1",
        name: "legal_lookup",
        input: { query: "HOL restoration deadlines", jurisdiction: "fi" },
      },
      {
        type: "tool_use",
        id: "tu_2",
        name: "create_deadline",
        input: { title: "Restoration deadline", due_date: "2026-09-01" },
      },
    ];
    const found = findClientOnlyBlock(toolBlocks);
    assert(found !== undefined);
    assertEquals(found!.name, "create_deadline");
  }
);

// =============================================================================
// T5 — executeToolCalls unchanged: server tools still dispatch, not "Unknown"
// =============================================================================

Deno.test(
  "executeToolCalls: legal_lookup (server tool) does NOT return Unknown tool",
  async () => {
    const results = await executeToolCalls(
      [
        {
          type: "tool_use",
          id: "tu_1",
          name: "legal_lookup",
          input: {
            query: "GDPR right of erasure exceptions",
            jurisdiction: "eu",
          },
        },
      ],
      "Bearer test-jwt",
      "user-123"
    );
    assertEquals(results.length, 1);
    // Whatever legal_lookup's real outcome is (network/DB dependent in this
    // unit context), it must NOT be the "Unknown tool" default-case error —
    // that would mean the server tool dispatch table regressed.
    const content = String(results[0].content ?? "");
    assertEquals(
      content.startsWith("Unknown tool:"),
      false,
      "legal_lookup must be dispatched, not treated as an unknown tool"
    );
  }
);

Deno.test(
  "executeToolCalls: a genuinely unknown name still returns Unknown tool (defense in depth preserved)",
  async () => {
    const results = await executeToolCalls(
      [
        {
          type: "tool_use",
          id: "tu_1",
          name: "create_deadline",
          input: {},
        },
      ],
      "Bearer test-jwt",
      "user-123"
    );
    assertEquals(results.length, 1);
    assertEquals(results[0].is_error, true);
    assert(
      String(results[0].content).startsWith("Unknown tool:"),
      "executeSingleTool's default case is unchanged — index.ts is now " +
        "responsible for never routing client tools here in production"
    );
  }
);
