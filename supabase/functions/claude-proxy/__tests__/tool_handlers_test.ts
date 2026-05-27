// claude-proxy/__tests__/tool_handlers_test.ts
// TDD coverage for tool_handlers.ts (send_email + generate_pdf).
//
// Tests are unit-level and do NOT make real network calls.
// External fetches are intercepted via globalThis.fetch mocking.
// -----------------------------------------------------------------------------

import { assert, assertEquals } from "https://deno.land/std@0.177.0/testing/asserts.ts";
import {
  ASSISTANT_TOOLS,
  adaptV2RowToLegacy,
  executeToolCalls,
  extractToolUseBlocks,
  isToolUseBlock,
  paragraphFromSectionLabel,
} from "../tool_handlers.ts";

// =============================================================================
// Helpers
// =============================================================================

type FetchHandler = (url: string, init?: RequestInit) => Promise<Response>;

/** Temporarily replaces globalThis.fetch with a stub, restores after the test. */
async function withFetch(
  stub: FetchHandler,
  fn: () => Promise<void>,
): Promise<void> {
  const original = globalThis.fetch;
  // deno-lint-ignore no-explicit-any
  (globalThis as any).fetch = stub;
  try {
    await fn();
  } finally {
    // deno-lint-ignore no-explicit-any
    (globalThis as any).fetch = original;
  }
}

function okJson(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// =============================================================================
// ASSISTANT_TOOLS schema shape
// =============================================================================

Deno.test("ASSISTANT_TOOLS: contains send_email and generate_pdf", () => {
  const names = ASSISTANT_TOOLS.map((t) => t.name);
  assertEquals(names.includes("send_email"), true);
  assertEquals(names.includes("generate_pdf"), true);
});

Deno.test("ASSISTANT_TOOLS: send_email requires confirmed", () => {
  const tool = ASSISTANT_TOOLS.find((t) => t.name === "send_email")!;
  assertEquals(
    (tool.input_schema.required as unknown as string[]).includes("confirmed"),
    true,
  );
});

Deno.test("ASSISTANT_TOOLS: generate_pdf has document_type enum", () => {
  const tool = ASSISTANT_TOOLS.find((t) => t.name === "generate_pdf")!;
  const dtProp = (tool.input_schema.properties as unknown as Record<string, {
    enum?: string[];
  }>).document_type;
  assertEquals(Array.isArray(dtProp?.enum), true);
  assertEquals(dtProp.enum!.includes("letter"), true);
});

// =============================================================================
// isToolUseBlock
// =============================================================================

Deno.test("isToolUseBlock: returns true for valid block", () => {
  assertEquals(
    isToolUseBlock({ type: "tool_use", id: "abc", name: "send_email", input: {} }),
    true,
  );
});

Deno.test("isToolUseBlock: returns false for text block", () => {
  assertEquals(
    isToolUseBlock({ type: "text", text: "hello" }),
    false,
  );
});

Deno.test("isToolUseBlock: returns false for null", () => {
  assertEquals(isToolUseBlock(null), false);
});

// =============================================================================
// extractToolUseBlocks
// =============================================================================

Deno.test("extractToolUseBlocks: extracts only tool_use blocks from content", () => {
  const content = [
    { type: "text", text: "I will send the email." },
    { type: "tool_use", id: "tu_1", name: "send_email", input: { to: "a@b.com", subject: "Hi", body: "Hello", confirmed: true } },
    { type: "tool_use", id: "tu_2", name: "generate_pdf", input: { title: "Letter", content: "# Hi", document_type: "letter" } },
  ];
  const blocks = extractToolUseBlocks(content);
  assertEquals(blocks.length, 2);
  assertEquals(blocks[0].name, "send_email");
  assertEquals(blocks[1].name, "generate_pdf");
});

Deno.test("extractToolUseBlocks: returns empty array for non-array input", () => {
  assertEquals(extractToolUseBlocks(null), []);
  assertEquals(extractToolUseBlocks("string"), []);
  assertEquals(extractToolUseBlocks(undefined), []);
});

// =============================================================================
// executeToolCalls — send_email
// =============================================================================

Deno.test("executeToolCalls/send_email: rejects when confirmed=false", async () => {
  // No fetch stub needed — should never call the network.
  const results = await executeToolCalls(
    [
      {
        type: "tool_use",
        id: "tu_1",
        name: "send_email",
        input: { to: "a@b.com", subject: "Hi", body: "Hello", confirmed: false },
      },
    ],
    "Bearer test-jwt",
    "user-123",
  );
  assertEquals(results.length, 1);
  assertEquals(results[0].is_error, true);
  assertEquals(
    results[0].content.includes("confirmation required"),
    true,
  );
});

Deno.test("executeToolCalls/send_email: rejects when confirmed missing", async () => {
  const results = await executeToolCalls(
    [
      {
        type: "tool_use",
        id: "tu_2",
        name: "send_email",
        // confirmed intentionally omitted
        input: { to: "a@b.com", subject: "Hi", body: "Hello" },
      },
    ],
    "Bearer test-jwt",
    "user-123",
  );
  assertEquals(results[0].is_error, true);
});

Deno.test("executeToolCalls/send_email: calls send-email function and returns success", async () => {
  let capturedUrl = "";
  let capturedBody: unknown = null;

  await withFetch(async (url, init) => {
    capturedUrl = url;
    capturedBody = JSON.parse(init?.body as string);
    return okJson({ ok: true, provider: "gmail_user", provider_message_id: "msg_999" });
  }, async () => {
    const results = await executeToolCalls(
      [
        {
          type: "tool_use",
          id: "tu_3",
          name: "send_email",
          input: {
            to: "lawyer@example.com",
            subject: "Case update",
            body: "Dear counsel,\n\nRegarding the matter...",
            confirmed: true,
          },
        },
      ],
      "Bearer real-jwt",
      "user-abc",
    );
    assertEquals(results.length, 1);
    assertEquals(results[0].is_error, undefined);
    assertEquals(results[0].content.includes("sent successfully"), true);
    assertEquals(results[0].content.includes("gmail_user"), true);
  });

  // Verify the correct endpoint was called with the right payload.
  assertEquals(capturedUrl.includes("/functions/v1/send-email"), true);
  assertEquals((capturedBody as { to: string }).to, "lawyer@example.com");
  assertEquals((capturedBody as { subject: string }).subject, "Case update");
});

Deno.test("executeToolCalls/send_email: propagates send-email HTTP error", async () => {
  await withFetch(async (_url, _init) => {
    return new Response(
      JSON.stringify({ error: "Rate limit exceeded." }),
      { status: 429, headers: { "Content-Type": "application/json" } },
    );
  }, async () => {
    const results = await executeToolCalls(
      [
        {
          type: "tool_use",
          id: "tu_err",
          name: "send_email",
          input: { to: "x@y.com", subject: "S", body: "B", confirmed: true },
        },
      ],
      "Bearer jwt",
      "user-1",
    );
    assertEquals(results[0].is_error, true);
    assertEquals(results[0].content.includes("429"), true);
  });
});

// =============================================================================
// executeToolCalls — generate_pdf
// =============================================================================

Deno.test("executeToolCalls/generate_pdf: uploads HTML and returns signed URL", async () => {
  const fetchCalls: Array<{ url: string; method: string }> = [];

  await withFetch(async (url, init) => {
    fetchCalls.push({ url, method: init?.method ?? "GET" });

    if (url.includes("/storage/v1/object/case-documents")) {
      // Upload call
      return okJson({ Key: "case-documents/user-xyz/generated/doc.html" });
    }
    if (url.includes("/storage/v1/object/sign")) {
      // Sign call
      return okJson({ signedURL: "/storage/v1/object/sign/case-documents/user-xyz/generated/doc.html?token=abc123" });
    }
    return okJson({});
  }, async () => {
    const results = await executeToolCalls(
      [
        {
          type: "tool_use",
          id: "tu_pdf",
          name: "generate_pdf",
          input: {
            title: "Formal Complaint",
            content:
              "## Background\n\nThis complaint is filed against...\n\n**Key facts:**\n- Fact one\n- Fact two",
            document_type: "complaint",
          },
        },
      ],
      "Bearer jwt",
      "user-xyz",
    );

    assertEquals(results.length, 1);
    assertEquals(results[0].is_error, undefined);
    assertEquals(results[0].content.includes("generated successfully"), true);
    assertEquals(results[0].content.includes("Download URL"), true);
  });

  // Two storage calls expected: upload + sign
  const storageCalls = fetchCalls.filter((c) =>
    c.url.includes("/storage/v1/")
  );
  assertEquals(storageCalls.length >= 2, true);
});

Deno.test("executeToolCalls/generate_pdf: rejects empty content", async () => {
  const results = await executeToolCalls(
    [
      {
        type: "tool_use",
        id: "tu_empty",
        name: "generate_pdf",
        input: { title: "Empty", content: "", document_type: "letter" },
      },
    ],
    "Bearer jwt",
    "user-1",
  );
  assertEquals(results[0].is_error, true);
  assertEquals(results[0].content.includes("content is required"), true);
});

Deno.test("executeToolCalls/generate_pdf: returns error message on upload failure", async () => {
  await withFetch(async (url, _init) => {
    if (url.includes("/storage/v1/object/case-documents")) {
      return new Response("Unauthorized", { status: 403 });
    }
    return okJson({});
  }, async () => {
    const results = await executeToolCalls(
      [
        {
          type: "tool_use",
          id: "tu_fail",
          name: "generate_pdf",
          input: { title: "Letter", content: "# Hello", document_type: "letter" },
        },
      ],
      "Bearer jwt",
      "user-1",
    );
    assertEquals(results[0].is_error, true);
    assertEquals(results[0].content.includes("403"), true);
  });
});

// =============================================================================
// executeToolCalls — unknown tool
// =============================================================================

Deno.test("executeToolCalls: returns error for unknown tool name", async () => {
  const results = await executeToolCalls(
    [
      {
        type: "tool_use",
        id: "tu_unknown",
        name: "teleport",
        input: {},
      },
    ],
    "Bearer jwt",
    "user-1",
  );
  assertEquals(results[0].is_error, true);
  assertEquals(results[0].content.includes("Unknown tool"), true);
});

// =============================================================================
// executeToolCalls — parallel execution (multiple blocks)
// =============================================================================

Deno.test("executeToolCalls: executes multiple tool blocks and returns all results", async () => {
  const fetchOrder: string[] = [];

  await withFetch(async (url, init) => {
    if (url.includes("/functions/v1/send-email")) {
      fetchOrder.push("send-email");
      return okJson({ ok: true, provider: "resend_fallback", provider_message_id: "r1" });
    }
    if (url.includes("/storage/v1/object/case-documents")) {
      fetchOrder.push("storage-upload");
      return okJson({ Key: "path" });
    }
    if (url.includes("/storage/v1/object/sign")) {
      fetchOrder.push("storage-sign");
      return okJson({ signedURL: "https://example.com/signed" });
    }
    return okJson({});
  }, async () => {
    const results = await executeToolCalls(
      [
        {
          type: "tool_use",
          id: "tu_a",
          name: "send_email",
          input: { to: "a@b.com", subject: "S", body: "B", confirmed: true },
        },
        {
          type: "tool_use",
          id: "tu_b",
          name: "generate_pdf",
          input: { title: "T", content: "# Hello", document_type: "summary" },
        },
      ],
      "Bearer jwt",
      "user-1",
    );

    assertEquals(results.length, 2);
    assertEquals(results[0].tool_use_id, "tu_a");
    assertEquals(results[1].tool_use_id, "tu_b");
    assertEquals(results[0].is_error, undefined);
    assertEquals(results[1].is_error, undefined);
  });
});

// =============================================================================
// law_search_v2 row adapter — 2026-05-13 launch P0 fix
// =============================================================================
//
// The legal_lookup tool was reading the legacy `law_search` RPC (EE-only,
// 6584 stale rows). We swapped it to `law_search_v2` (15 295 rows: FI/EE/EU)
// and added an adapter that maps the v2 row shape back to the legacy
// LawSearchRpcRow consumed by _shared/legal_lookup.ts. These tests pin the
// adapter so future migrations cannot silently break the conversion.

Deno.test("paragraphFromSectionLabel: FI 'HOL 1:114 §' → '114'", () => {
  assertEquals(paragraphFromSectionLabel("HOL 1:114 §"), "114");
});

Deno.test("paragraphFromSectionLabel: FI 'PL 10:114 §' (chapter:section) → '114'", () => {
  assertEquals(paragraphFromSectionLabel("PL 10:114 §"), "114");
});

Deno.test("paragraphFromSectionLabel: EE 'KarS § 114' → '114'", () => {
  assertEquals(paragraphFromSectionLabel("KarS § 114"), "114");
});

Deno.test("paragraphFromSectionLabel: EE superscript suffix 'AÕS § 114¹' → '114¹'", () => {
  assertEquals(paragraphFromSectionLabel("AÕS § 114¹"), "114¹");
});

Deno.test("paragraphFromSectionLabel: EU EN 'Article 39' → '39'", () => {
  assertEquals(paragraphFromSectionLabel("Article 39"), "39");
});

Deno.test("paragraphFromSectionLabel: EU ET 'Artikkel 28' → '28'", () => {
  assertEquals(paragraphFromSectionLabel("Artikkel 28"), "28");
});

Deno.test("paragraphFromSectionLabel: EU FI '39 artikla' → '39'", () => {
  assertEquals(paragraphFromSectionLabel("39 artikla"), "39");
});

Deno.test("paragraphFromSectionLabel: empty string → ''", () => {
  assertEquals(paragraphFromSectionLabel(""), "");
});

Deno.test("adaptV2RowToLegacy: maps v2 → legacy shape with all fields", () => {
  const v2Row = {
    id: "11111111-2222-3333-4444-555555555555",
    act_slug: "fi-hol",
    section_label: "HOL 13:114 §",
    text: "Menetetyn määräajan palauttaminen — sample body.",
    similarity: 0.82,
    source_url: "https://www.finlex.fi/fi/laki/ajantasa/2003/20030434",
    license: "CC-BY-NC-4.0",
    display_policy: "snippet_only",
  };
  const legacy = adaptV2RowToLegacy(v2Row);
  assertEquals(legacy.id, "11111111-2222-3333-4444-555555555555");
  assertEquals(legacy.act_slug, "fi-hol");
  assertEquals(legacy.paragraph, "114");
  assertEquals(legacy.title, "HOL 13:114 §");
  assertEquals(legacy.body, "Menetetyn määräajan palauttaminen — sample body.");
  assertEquals(legacy.source_url, "https://www.finlex.fi/fi/laki/ajantasa/2003/20030434");
  assertEquals(legacy.similarity, 0.82);
  assertEquals(legacy.license, "CC-BY-NC-4.0");
  assertEquals(legacy.display_policy, "snippet_only");
  // jurisdiction / act_name are null in v2 — the verifier and formatter
  // tolerate this; they only need (act_slug, paragraph) as the anchor key.
  assertEquals(legacy.jurisdiction, null);
  assertEquals(legacy.act_name, null);
});

Deno.test("adaptV2RowToLegacy: missing optional fields default safely", () => {
  // Simulate a row with nullable columns absent (license/display_policy
  // pre-dating the 2026-05-15 license migration on the v2 RPC return).
  const v2Row = {
    id: "abc",
    act_slug: "ee-kars",
    section_label: "KarS § 114",
    text: "body",
    similarity: 0.5,
    source_url: null,
    license: null,
    display_policy: null,
  };
  const legacy = adaptV2RowToLegacy(v2Row);
  assertEquals(legacy.paragraph, "114");
  assertEquals(legacy.source_url, null);
  assertEquals(legacy.license, null);
  assertEquals(legacy.display_policy, null);
});

// =============================================================================
// Day 1-2 (2026-05-27) — agent-loop READ tools schema integrity
// =============================================================================

Deno.test("ASSISTANT_TOOLS: includes 4 new READ tools for agent loop", () => {
  const names = ASSISTANT_TOOLS.map((t) => t.name);
  // All 4 day-1-2 tools present
  assert(names.includes("list_inbox"), "list_inbox missing");
  assert(names.includes("read_thread_full"), "read_thread_full missing");
  assert(names.includes("run_pdf_parser"), "run_pdf_parser missing");
  assert(names.includes("run_consilium"), "run_consilium missing");
  // Pre-existing tools still there
  assert(names.includes("send_email"), "send_email regression");
  assert(names.includes("generate_pdf"), "generate_pdf regression");
  assert(names.includes("legal_lookup"), "legal_lookup regression");
});

Deno.test("ASSISTANT_TOOLS: list_inbox has expected optional fields", () => {
  const tool = ASSISTANT_TOOLS.find((t) => t.name === "list_inbox")!;
  // No required fields — all params optional with sensible defaults
  assertEquals(tool.input_schema.required, []);
  const props = tool.input_schema.properties as Record<
    string,
    Record<string, unknown>
  >;
  assert("limit" in props, "limit param missing");
  assert("only_unread" in props, "only_unread param missing");
  assert("severity_min" in props, "severity_min param missing");
  // Severity enum locked
  assertEquals(
    props.severity_min.enum,
    ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
  );
});

Deno.test("ASSISTANT_TOOLS: read_thread_full requires thread_id", () => {
  const tool = ASSISTANT_TOOLS.find((t) => t.name === "read_thread_full")!;
  assertEquals(tool.input_schema.required, ["thread_id"]);
});

Deno.test("ASSISTANT_TOOLS: run_pdf_parser requires attachment_id", () => {
  const tool = ASSISTANT_TOOLS.find((t) => t.name === "run_pdf_parser")!;
  assertEquals(tool.input_schema.required, ["attachment_id"]);
});

Deno.test("ASSISTANT_TOOLS: run_consilium requires question only", () => {
  const tool = ASSISTANT_TOOLS.find((t) => t.name === "run_consilium")!;
  assertEquals(tool.input_schema.required, ["question"]);
  const props = tool.input_schema.properties as Record<
    string,
    Record<string, unknown>
  >;
  assert("case_context" in props, "case_context should be optional param");
});

Deno.test("executeToolCalls: unknown tool returns is_error", async () => {
  const results = await executeToolCalls(
    [
      {
        type: "tool_use",
        id: "tu-x",
        name: "nonexistent_tool",
        input: {},
      },
    ],
    "Bearer test",
    "user-x",
  );
  assertEquals(results.length, 1);
  assertEquals(results[0].is_error, true);
  assert((results[0].content as string).startsWith("Unknown tool:"));
});
