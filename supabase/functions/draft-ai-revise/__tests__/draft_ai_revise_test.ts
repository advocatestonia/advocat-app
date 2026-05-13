// Deno tests for draft-ai-revise (Pkg 7 Drafting Studio MVP).
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/draft-ai-revise/__tests__/draft_ai_revise_test.ts
//
// Scope: pins the handler contract against fake Anthropic + DB clients.
// 13 cases covering validation, ownership, success, malformed JSON, fenced
// JSON, empty content, anthropic error, instruction defaulting, context
// truncation, change-list pass-through, prompt language clause, language
// hint absent, and explanation pass-through.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCaller,
  type AnthropicResponse,
  buildReviseSystemPrompt,
  buildReviseUserMessage,
  type DraftDbClient,
  MAX_CONTEXT_CHARS,
  MAX_SELECTED_CHARS,
  parseReviseJson,
  runDraftRevise,
} from "../handler.ts";

// ─── Fakes ──────────────────────────────────────────────────────────────────

class FakeDb implements DraftDbClient {
  constructor(public ownerMap: Record<string, string> = {}) {}
  // deno-lint-ignore require-await
  async isOwner(draftId: string, userId: string): Promise<boolean> {
    return this.ownerMap[draftId] === userId;
  }
}

function fakeAnthropic(returns: AnthropicResponse): AnthropicCaller {
  return async () => await Promise.resolve(returns);
}

function fakeAnthropicError(msg: string): AnthropicCaller {
  return () => {
    throw new Error(msg);
  };
}

function aiText(body: string): AnthropicResponse {
  return { content: [{ type: "text", text: body }] };
}

const UUID = "00000000-0000-4000-8000-000000000001";
const UUID_B = "00000000-0000-4000-8000-000000000002";
const USER = "user-1";

// ─── 1. Rejects non-UUID draft_id ───────────────────────────────────────────

Deno.test("rejects non-UUID draft_id with 400", async () => {
  const res = await runDraftRevise(
    { draft_id: "not-a-uuid", selected_text: "hello" },
    USER,
    {
      db: new FakeDb({ [UUID]: USER }),
      callAnthropic: fakeAnthropic(aiText("ignored")),
    },
  );
  assertEquals(res.kind, "error");
  assertEquals(res.status, 400);
});

// ─── 2. Rejects empty selected_text ─────────────────────────────────────────

Deno.test("rejects empty selected_text with 400", async () => {
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: "   " },
    USER,
    {
      db: new FakeDb({ [UUID]: USER }),
      callAnthropic: fakeAnthropic(aiText("ignored")),
    },
  );
  assertEquals(res.kind, "error");
  assertEquals(res.status, 400);
});

// ─── 3. Rejects selected_text > cap ─────────────────────────────────────────

Deno.test("rejects selected_text exceeding MAX_SELECTED_CHARS", async () => {
  const big = "x".repeat(MAX_SELECTED_CHARS + 1);
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: big },
    USER,
    {
      db: new FakeDb({ [UUID]: USER }),
      callAnthropic: fakeAnthropic(aiText("ignored")),
    },
  );
  assertEquals(res.kind, "error");
  assertEquals(res.status, 400);
});

// ─── 4. 403 when caller is not the owner ────────────────────────────────────

Deno.test("returns 403 when user does not own the draft", async () => {
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: "hello" },
    USER,
    {
      db: new FakeDb({ [UUID]: "someone-else" }),
      callAnthropic: fakeAnthropic(aiText("ignored")),
    },
  );
  assertEquals(res.kind, "error");
  assertEquals(res.status, 403);
});

// ─── 5. Happy path: plain JSON response ─────────────────────────────────────

Deno.test("happy path returns revised_text + explanation + changes_made", async () => {
  const aiResp = aiText(JSON.stringify({
    revised_text: "Hello, World.",
    explanation: "Capitalised greeting; added period.",
    changes_made: ["Capitalised 'Hello'", "Added trailing period"],
  }));
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: "hello world" },
    USER,
    {
      db: new FakeDb({ [UUID]: USER }),
      callAnthropic: fakeAnthropic(aiResp),
    },
  );
  assertEquals(res.kind, "success");
  if (res.kind !== "success") return;
  assertEquals(res.status, 200);
  assertEquals(res.body.revised_text, "Hello, World.");
  assertEquals(res.body.changes_made.length, 2);
  assertEquals(res.body.explanation, "Capitalised greeting; added period.");
});

// ─── 6. JSON wrapped in ```json fence is still parsed ───────────────────────

Deno.test("parses fenced JSON response", async () => {
  const fenced = "```json\n" + JSON.stringify({
    revised_text: "Revised.",
    explanation: "n/a",
    changes_made: [],
  }) + "\n```";
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: "old" },
    USER,
    {
      db: new FakeDb({ [UUID]: USER }),
      callAnthropic: fakeAnthropic(aiText(fenced)),
    },
  );
  assertEquals(res.kind, "success");
  if (res.kind === "success") {
    assertEquals(res.body.revised_text, "Revised.");
  }
});

// ─── 7. Empty Anthropic response → 502 ──────────────────────────────────────

Deno.test("empty Anthropic content → 502", async () => {
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: "hello" },
    USER,
    {
      db: new FakeDb({ [UUID]: USER }),
      callAnthropic: fakeAnthropic({ content: [] }),
    },
  );
  assertEquals(res.kind, "error");
  assertEquals(res.status, 502);
});

// ─── 8. Malformed JSON in Anthropic response → 502 ──────────────────────────

Deno.test("malformed JSON in Anthropic response → 502", async () => {
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: "hello" },
    USER,
    {
      db: new FakeDb({ [UUID]: USER }),
      callAnthropic: fakeAnthropic(aiText("definitely not json")),
    },
  );
  assertEquals(res.kind, "error");
  assertEquals(res.status, 502);
});

// ─── 9. Anthropic error → 503 ───────────────────────────────────────────────

Deno.test("Anthropic throw → 503", async () => {
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: "hello" },
    USER,
    {
      db: new FakeDb({ [UUID]: USER }),
      callAnthropic: fakeAnthropicError("backend down"),
    },
  );
  assertEquals(res.kind, "error");
  assertEquals(res.status, 503);
});

// ─── 10. Language hint appears in system prompt ─────────────────────────────

Deno.test("buildReviseSystemPrompt includes language clause when hint given", () => {
  const p = buildReviseSystemPrompt({ language: "et" });
  assert(p.includes('"et"'));
  assert(p.includes("Respond in the same language"));
});

Deno.test("buildReviseSystemPrompt falls back when no language hint", () => {
  const p = buildReviseSystemPrompt({});
  assert(p.includes("Respond in the same language as the selected text"));
});

// ─── 11. User message includes instruction default when none given ─────────

Deno.test("buildReviseUserMessage falls back to default instruction", () => {
  const m = buildReviseUserMessage({
    draft_id: UUID,
    selected_text: "x",
  });
  assert(m.includes("Improve clarity and legal precision"));
});

// ─── 12. Context is truncated to MAX_CONTEXT_CHARS ──────────────────────────

Deno.test("context is truncated to MAX_CONTEXT_CHARS in user message", () => {
  const huge = "c".repeat(MAX_CONTEXT_CHARS * 2);
  const m = buildReviseUserMessage({
    draft_id: UUID,
    selected_text: "sel",
    context: huge,
  });
  // The context section appears between "Surrounding context" and the next
  // "---". Count how many 'c' chars end up there — should be ≤ cap.
  const ctxStart = m.indexOf("Surrounding context");
  assert(ctxStart > 0);
  const after = m.slice(ctxStart);
  const cMatches = after.match(/c+/);
  assertExists(cMatches);
  assert(
    cMatches![0].length <= MAX_CONTEXT_CHARS,
    `expected ≤ ${MAX_CONTEXT_CHARS} c's, got ${cMatches![0].length}`,
  );
});

// ─── 13. parseReviseJson tolerates leading/trailing prose ───────────────────

Deno.test("parseReviseJson handles stray prose before/after JSON", () => {
  const raw =
    'Here you go:\n{"revised_text":"X","explanation":"","changes_made":[]}\nThanks!';
  const parsed = parseReviseJson(raw);
  assertExists(parsed);
  assertEquals(parsed!.revised_text, "X");
});

// ─── 14. parseReviseJson rejects object without revised_text ────────────────

Deno.test("parseReviseJson rejects object missing revised_text", () => {
  const raw = '{"explanation":"hi","changes_made":[]}';
  assertEquals(parseReviseJson(raw), null);
});

// ─── 15. parseReviseJson handles nested braces in revised_text ──────────────

Deno.test("parseReviseJson handles nested braces in body content", () => {
  const raw = JSON.stringify({
    revised_text: "Object {foo: bar} stays intact.",
    explanation: "",
    changes_made: [],
  });
  const parsed = parseReviseJson(raw);
  assertExists(parsed);
  assertEquals(parsed!.revised_text, "Object {foo: bar} stays intact.");
});

// ─── 16. Different user on same draft → 403 (cross-user isolation) ─────────

Deno.test("different user on existing draft → 403", async () => {
  const res = await runDraftRevise(
    { draft_id: UUID, selected_text: "hello" },
    "intruder",
    {
      db: new FakeDb({ [UUID]: USER, [UUID_B]: "other-owner" }),
      callAnthropic: fakeAnthropic(aiText('{"revised_text":"x","explanation":"","changes_made":[]}')),
    },
  );
  assertEquals(res.kind, "error");
  assertEquals(res.status, 403);
});
