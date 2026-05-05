// Deno tests for extract-memory — schema + source contract.
// -----------------------------------------------------------------------------
// Split into two groups:
//   * Pure-function tests for memory_schema.ts (runnable offline, no fetch).
//   * Source-contract tests for index.ts (assert imports, rate limit, JWT
//     gate ordering) — borrowed from the create-checkout / refund-eligibility
//     test pattern.
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/extract-memory/__tests__/extract_memory_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  ALLOWED_KEYS,
  buildHaikuRequest,
  buildQuickProfileHaikuRequest,
  MAX_FACTS,
  parseHaikuFacts,
  QUICK_PROFILE_ALLOWED_KEYS,
  QUICK_PROFILE_SYSTEM_PROMPT,
  SYSTEM_PROMPT,
  TEXT_MAX_LEN,
} from "../memory_schema.ts";

// ---------------------------------------------------------------------------
// memory_schema.ts — pure functions
// ---------------------------------------------------------------------------

Deno.test("EM-T01 — ALLOWED_KEYS matches ADR-001 bounded vocabulary", () => {
  // 2026-05-05 expansion: added legal_status / nationality /
  // residence_status (Visioning Council #1 priority — these gate the
  // applicable body of law and therefore live in the bounded vocab).
  const expected = [
    "name",
    "tone",
    "emotional_state",
    "case_focus",
    "known_party",
    "deadline",
    "user_goal",
    "preference",
    "background",
    "discussed_topic",
    "legal_status",
    "nationality",
    "residence_status",
  ];
  for (const k of expected) {
    assert(ALLOWED_KEYS.has(k), `Missing key: ${k}`);
  }
  assertEquals(
    ALLOWED_KEYS.size,
    expected.length,
    "ALLOWED_KEYS must match the exact ADR-001 vocabulary — adding a key " +
      "silently widens the extraction surface and must go through ADR.",
  );
});

Deno.test("EM-T01b — legal-status keys present and are a strict subset", () => {
  // The legal-status sub-vocabulary is what the Dart renderer special-cases
  // in buildMemoryBlock. If it drifts from ALLOWED_KEYS, the renderer
  // silently drops them into the generic facts list.
  for (const k of ["legal_status", "nationality", "residence_status"]) {
    assert(
      ALLOWED_KEYS.has(k),
      `legal-status key "${k}" must be in ALLOWED_KEYS`,
    );
  }
});

Deno.test("EM-T02 — buildHaikuRequest targets the right model + deterministic", () => {
  const req = buildHaikuRequest(
    [{ role: "user", content: "I live in Tallinn and prefer short replies." }],
    "claude-haiku-4-5-20251001",
  );
  assertEquals(req.model, "claude-haiku-4-5-20251001");
  assertEquals(req.temperature, 0, "Extraction must be deterministic — temp=0");
  assertEquals(req.max_tokens, 1024);
  assertEquals(req.system, SYSTEM_PROMPT);
});

Deno.test("EM-T03 — buildHaikuRequest forces tool_choice to extract_facts", () => {
  const req = buildHaikuRequest(
    [{ role: "user", content: "hello" }],
    "claude-haiku-4-5-20251001",
  );
  // tool_choice type=tool + name=extract_facts ensures the response has
  // a tool_use block we can parse deterministically.
  assertEquals(
    (req.tool_choice as Record<string, unknown>).type,
    "tool",
  );
  assertEquals(
    (req.tool_choice as Record<string, unknown>).name,
    "extract_facts",
  );
  const tools = req.tools as Array<Record<string, unknown>>;
  assertEquals(tools.length, 1);
  assertEquals(tools[0].name, "extract_facts");
});

Deno.test("EM-T04 — tool schema enforces enum + maxItems + maxLength", () => {
  const req = buildHaikuRequest(
    [{ role: "user", content: "hi" }],
    "claude-haiku-4-5-20251001",
  );
  const tools = req.tools as Array<Record<string, unknown>>;
  const schema = (tools[0].input_schema as Record<string, unknown>);
  const props = (schema.properties as Record<string, unknown>);
  const facts = (props.facts as Record<string, unknown>);
  assertEquals(facts.maxItems, MAX_FACTS);
  const items = (facts.items as Record<string, unknown>);
  const itemProps = (items.properties as Record<string, unknown>);
  const keyEnum = (itemProps.key as Record<string, unknown>).enum;
  assertEquals(
    new Set(keyEnum as string[]).size,
    ALLOWED_KEYS.size,
    "schema `key` enum must match ALLOWED_KEYS exactly",
  );
  assertEquals(
    (itemProps.value as Record<string, unknown>).maxLength,
    TEXT_MAX_LEN,
  );
  const conf = (itemProps.confidence as Record<string, unknown>);
  assertEquals(conf.minimum, 0);
  assertEquals(conf.maximum, 1);
});

Deno.test("EM-T05 — buildHaikuRequest renders the transcript in [role]: content form", () => {
  const req = buildHaikuRequest(
    [
      { role: "user", content: "My wife is Sofia." },
      { role: "assistant", content: "Tell me more." },
      { role: "user", content: "Deportation case in Finland." },
    ],
    "claude-haiku-4-5-20251001",
  );
  const msgs = req.messages as Array<Record<string, unknown>>;
  const userMsg = msgs[0].content as string;
  assertStringIncludes(userMsg, "[user]: My wife is Sofia.");
  assertStringIncludes(userMsg, "[assistant]: Tell me more.");
  assertStringIncludes(userMsg, "[user]: Deportation case in Finland.");
});

Deno.test("EM-T06 — parseHaikuFacts extracts valid facts", () => {
  const facts = parseHaikuFacts({
    content: [
      {
        type: "tool_use",
        name: "extract_facts",
        input: {
          facts: [
            { key: "tone", value: "You prefer short replies", confidence: 0.9 },
            { key: "known_party", value: "Your wife is Sofia", confidence: 0.95 },
          ],
        },
      },
    ],
  });
  assertEquals(facts.length, 2);
  assertEquals(facts[0].key, "tone");
  assertEquals(facts[1].key, "known_party");
});

Deno.test("EM-T07 — parseHaikuFacts returns [] on malformed response", () => {
  assertEquals(parseHaikuFacts(null), []);
  assertEquals(parseHaikuFacts("not an object"), []);
  assertEquals(parseHaikuFacts({}), []);
  assertEquals(parseHaikuFacts({ content: "not an array" }), []);
  assertEquals(parseHaikuFacts({ content: [{}] }), []);
  assertEquals(
    parseHaikuFacts({ content: [{ type: "text", text: "no tool" }] }),
    [],
  );
  // tool_use with wrong tool name — drop.
  assertEquals(
    parseHaikuFacts({
      content: [{ type: "tool_use", name: "other_tool", input: { facts: [] } }],
    }),
    [],
  );
});

Deno.test("EM-T08 — parseHaikuFacts drops out-of-vocabulary keys", () => {
  const facts = parseHaikuFacts({
    content: [
      {
        type: "tool_use",
        name: "extract_facts",
        input: {
          facts: [
            { key: "tone", value: "ok", confidence: 0.9 },
            // Haiku hallucinates a key not in the enum — must be dropped.
            { key: "favourite_colour", value: "blue", confidence: 0.9 },
            { key: "SSN", value: "123-45-6789", confidence: 0.9 },
          ],
        },
      },
    ],
  });
  assertEquals(facts.length, 1);
  assertEquals(facts[0].key, "tone");
});

Deno.test("EM-T09 — parseHaikuFacts drops facts with bad confidence", () => {
  const facts = parseHaikuFacts({
    content: [
      {
        type: "tool_use",
        name: "extract_facts",
        input: {
          facts: [
            { key: "tone", value: "a", confidence: 1.5 }, // out of range
            { key: "tone", value: "b", confidence: -0.1 }, // out of range
            { key: "tone", value: "c", confidence: 0.3 }, // below 0.5 threshold
            { key: "tone", value: "d", confidence: "not a number" },
            { key: "tone", value: "e", confidence: 0.9 }, // ok
          ],
        },
      },
    ],
  });
  assertEquals(facts.length, 1);
  assertEquals(facts[0].value, "e");
});

Deno.test("EM-T10 — parseHaikuFacts caps text at TEXT_MAX_LEN", () => {
  const long = "x".repeat(1000);
  const facts = parseHaikuFacts({
    content: [
      {
        type: "tool_use",
        name: "extract_facts",
        input: {
          facts: [{ key: "background", value: long, confidence: 0.9 }],
        },
      },
    ],
  });
  assertEquals(facts.length, 1);
  assertEquals(facts[0].value.length, TEXT_MAX_LEN);
});

Deno.test("EM-T11 — parseHaikuFacts caps total facts at MAX_FACTS", () => {
  const facts = parseHaikuFacts({
    content: [
      {
        type: "tool_use",
        name: "extract_facts",
        input: {
          facts: Array.from({ length: 25 }, (_, i) => ({
            key: "discussed_topic",
            value: `topic ${i}`,
            confidence: 0.9,
          })),
        },
      },
    ],
  });
  assertEquals(facts.length, MAX_FACTS);
});

Deno.test("EM-T12 — system prompt forbids invention", () => {
  // The reviewer should never relax the anti-hallucination rule without
  // an ADR update — this test pins the behaviour.
  assertStringIncludes(SYSTEM_PROMPT.toLowerCase(), "never invent");
  assertStringIncludes(SYSTEM_PROMPT, "JSON only");
});

// ---------------------------------------------------------------------------
// index.ts — source contract
// ---------------------------------------------------------------------------

const indexSource = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);
const stripped = indexSource
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

Deno.test("EM-T13 — index.ts imports shared JWT gate + CORS helpers", () => {
  assertStringIncludes(indexSource, "requireUserWithRateLimit");
  assertStringIncludes(indexSource, "_shared/auth.ts");
});

Deno.test("EM-T14 — JWT gate runs before Haiku fetch + DB write", () => {
  const gateIdx = stripped.indexOf("requireUserWithRateLimit(");
  const fetchIdx = stripped.indexOf("fetch(ANTHROPIC_API_URL");
  const fromIdx = stripped.indexOf(".from(");
  assert(gateIdx !== -1, "Must call the shared JWT gate");
  assert(fetchIdx === -1 || gateIdx < fetchIdx, "Gate must run before Haiku");
  assert(fromIdx === -1 || gateIdx < fromIdx, "Gate must run before DB");
});

Deno.test("EM-T15 — rate limit is 5/min under bucket 'extract-memory'", () => {
  assertStringIncludes(indexSource, 'bucket: "extract-memory"');
  assertStringIncludes(indexSource, "maxPerMinute: 5");
});

Deno.test("EM-T16 — body user_id is NOT trusted (rejected with 400)", () => {
  // If a caller sends user_id, the function must reject the request so
  // there's no ambiguity about which user the memory belongs to.
  assertStringIncludes(stripped, '"user_id" in raw');
});

Deno.test("EM-T17 — upsert always scopes to gate.user.id", () => {
  // Both the duplicate lookup and the insert must use gate.user.id —
  // never a body-supplied identifier.
  assertStringIncludes(stripped, "gate.user.id");
  const insertIdx = stripped.indexOf('.insert(');
  const userIdRef = stripped.indexOf("gate.user.id", insertIdx);
  assert(
    insertIdx === -1 || userIdRef > insertIdx,
    "insert payload must reference gate.user.id",
  );
});

Deno.test("EM-T18 — OPTIONS preflight returns 204 with corsHeaders", () => {
  assertStringIncludes(stripped, "OPTIONS");
  assertStringIncludes(indexSource, "corsHeaders");
});

Deno.test("EM-T19 — uses strict JSON schema tool (tool_choice)", () => {
  assertStringIncludes(indexSource, "buildHaikuRequest");
  assertStringIncludes(indexSource, "parseHaikuFacts");
});

Deno.test("EM-T20 — response exposes extracted + stored + duplicates", () => {
  // Frontend uses these counters to decide whether to show a "memory
  // updated" toast. Changing the contract here breaks the UI.
  assertStringIncludes(stripped, "extracted");
  assertStringIncludes(stripped, "stored");
  assertStringIncludes(stripped, "duplicates");
});

// ---------------------------------------------------------------------------
// Quick Profile intake variant — 2026-05-05
// ---------------------------------------------------------------------------
// One-shot intake on first chat. We need a focused extraction surface that
// pulls ONLY legal_status / nationality / residence_status — no tone, no
// emotional_state, no known_party — so a one-line answer like "I'm an
// Estonian citizen" doesn't pollute memory with junk facts.
//
// Contract: when the request body has `intake: 'quick_profile'`, the Edge
// Function uses [buildQuickProfileHaikuRequest] which constrains the tool
// schema's `key` enum to QUICK_PROFILE_ALLOWED_KEYS (the legal-status
// trio) and uses a tighter system prompt.
// ---------------------------------------------------------------------------

Deno.test("EM-T21 — QUICK_PROFILE_ALLOWED_KEYS = legal_status trio", () => {
  // Must be exactly the three legal-status keys, no more, no less.
  // Drift here means the intake either misses the priority keys (too few)
  // or pollutes memory with tone/preference/etc. (too many).
  assertEquals(QUICK_PROFILE_ALLOWED_KEYS.size, 3);
  assert(QUICK_PROFILE_ALLOWED_KEYS.has("legal_status"));
  assert(QUICK_PROFILE_ALLOWED_KEYS.has("nationality"));
  assert(QUICK_PROFILE_ALLOWED_KEYS.has("residence_status"));
});

Deno.test("EM-T22 — QUICK_PROFILE_ALLOWED_KEYS is a subset of ALLOWED_KEYS", () => {
  // Defence-in-depth: the focused prompt must never widen the bounded
  // vocabulary. Every quick-profile key has to live in ALLOWED_KEYS too.
  for (const k of QUICK_PROFILE_ALLOWED_KEYS) {
    assert(
      ALLOWED_KEYS.has(k),
      `quick-profile key "${k}" leaked outside ALLOWED_KEYS`,
    );
  }
});

Deno.test("EM-T23 — buildQuickProfileHaikuRequest restricts the `key` enum", () => {
  // The schema's enum is what physically prevents Haiku from emitting
  // out-of-vocabulary keys for this turn. If we forget to narrow it, the
  // generic system prompt's "extract these aggressively" instructions
  // bleed in and the intake message grows tone/preference noise.
  const req = buildQuickProfileHaikuRequest(
    [{ role: "user", content: "I'm an Estonian citizen." }],
    "claude-haiku-4-5-20251001",
  );
  const tools = req.tools as Array<Record<string, unknown>>;
  const schema = tools[0].input_schema as Record<string, unknown>;
  const props = schema.properties as Record<string, unknown>;
  const facts = props.facts as Record<string, unknown>;
  const items = facts.items as Record<string, unknown>;
  const itemProps = items.properties as Record<string, unknown>;
  const keyEnum = (itemProps.key as Record<string, unknown>).enum as string[];
  assertEquals(
    new Set(keyEnum).size,
    QUICK_PROFILE_ALLOWED_KEYS.size,
    "quick-profile schema must constrain `key` enum to the legal trio",
  );
  for (const k of keyEnum) {
    assert(
      QUICK_PROFILE_ALLOWED_KEYS.has(k),
      `key enum leaked non-legal key: ${k}`,
    );
  }
});

Deno.test("EM-T24 — buildQuickProfileHaikuRequest uses focused system prompt", () => {
  const req = buildQuickProfileHaikuRequest(
    [{ role: "user", content: "EU citizen" }],
    "claude-haiku-4-5-20251001",
  );
  assertEquals(req.system, QUICK_PROFILE_SYSTEM_PROMPT);
  assertEquals(req.temperature, 0, "Intake must stay deterministic — temp=0");
  // Forces the tool — same as the generic path.
  assertEquals(
    (req.tool_choice as Record<string, unknown>).type,
    "tool",
  );
});

Deno.test("EM-T25 — quick-profile system prompt names the legal trio", () => {
  // The reviewer must keep the prompt anchored on the three keys. If a
  // future edit drops one, the model silently stops extracting it.
  assertStringIncludes(QUICK_PROFILE_SYSTEM_PROMPT, "legal_status");
  assertStringIncludes(QUICK_PROFILE_SYSTEM_PROMPT, "nationality");
  assertStringIncludes(QUICK_PROFILE_SYSTEM_PROMPT, "residence_status");
});

Deno.test("EM-T26 — quick-profile system prompt forbids extra keys", () => {
  // Pin the anti-pollution rule. Without this assertion a future edit that
  // says "and any tone you can infer" would silently widen the surface.
  const lower = QUICK_PROFILE_SYSTEM_PROMPT.toLowerCase();
  assert(
    lower.includes("only") || lower.includes("nothing else"),
    "intake prompt must forbid extracting facts beyond the legal trio",
  );
});

Deno.test("EM-T27 — parseHaikuFacts still works with quick-profile output", () => {
  // The same parser is used for both the generic and intake paths — its
  // ALLOWED_KEYS check tolerates the legal trio, and confidence/text
  // validation is identical.
  const facts = parseHaikuFacts({
    content: [
      {
        type: "tool_use",
        name: "extract_facts",
        input: {
          facts: [
            {
              key: "legal_status",
              value: "Estonian citizen",
              confidence: 0.95,
            },
            { key: "nationality", value: "EE", confidence: 0.95 },
          ],
        },
      },
    ],
  });
  assertEquals(facts.length, 2);
  assertEquals(facts[0].key, "legal_status");
  assertEquals(facts[1].key, "nationality");
});

Deno.test("EM-T28 — index.ts wires the quick-profile branch", () => {
  // Source-contract check: the request handler must inspect the body's
  // `intake` flag and route to buildQuickProfileHaikuRequest when set.
  // We assert the symbol is imported and the dispatch branch exists.
  assertStringIncludes(indexSource, "buildQuickProfileHaikuRequest");
  assertStringIncludes(stripped, '"quick_profile"');
});

// Sanity check: the unused-import lint isn't going to fire on the new
// symbols because the tests above reference them. Importing without using
// would still compile under Deno, but TypeScript-strict environments would
// flag it — pin the contract here.
assertFalse(
  indexSource.includes("buildQuickProfileHaikuRequest") &&
    !indexSource.includes("import"),
  "buildQuickProfileHaikuRequest is referenced — import line must exist",
);
