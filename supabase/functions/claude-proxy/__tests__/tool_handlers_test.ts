// claude-proxy/__tests__/tool_handlers_test.ts
// TDD coverage for tool_handlers.ts (send_email + generate_pdf).
//
// Tests are unit-level and do NOT make real network calls.
// External fetches are intercepted via globalThis.fetch mocking.
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.177.0/testing/asserts.ts";
import {
  ASSISTANT_TOOLS,
  executeToolCalls,
  extractToolUseBlocks,
  isToolUseBlock,
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
