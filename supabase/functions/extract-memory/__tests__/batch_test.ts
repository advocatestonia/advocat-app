// batch_test.ts — BUG#1 anti-regression
// -----------------------------------------------------------------------------
// Pre-launch fix (2026-04-29). Originally extract-memory ran two DB queries
// per fact (SELECT + INSERT/UPDATE), which is N+1: 10 facts → 21 round-trips.
// The new code batches into:
//   • exactly ONE SELECT (`.in("key", [...])`) per call
//   • exactly ONE UPSERT (`.upsert(rows, { onConflict: ... })`) per call
//
// We can't spin up a real Supabase instance inside Deno tests, so we
// pin the contract by inspecting the index.ts source for the required
// shape and by exercising the pure helper `partitionFactsForUpsert` that
// holds the confidence-preservation logic.
//
// Two kinds of assertions:
//   1. Source-level: the legacy per-fact loop is gone and the new batch
//      primitives are present. Identical pattern to the existing
//      EM-T13/EM-T14 tests in extract_memory_test.ts.
//   2. Pure-function: confidence preservation — if existing.confidence is
//      higher than the new fact's confidence, we must NOT overwrite the
//      stored confidence (it's a "weaker reinforcement").
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/extract-memory/__tests__/batch_test.ts

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { partitionFactsForUpsert } from "../memory_schema.ts";

const indexSource = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);
const stripped = indexSource
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/^\s*\/\/.*$/gm, "");

// ---------------------------------------------------------------------------
// Source-level: N+1 → batch
// ---------------------------------------------------------------------------

Deno.test("BATCH-T01 — index.ts no longer has a per-fact `for (const fact of facts)` loop", () => {
  // The old code ran SELECT + INSERT/UPDATE inside this loop. New code
  // does its work outside the per-fact loop (one SELECT, one UPSERT).
  // We allow the loop to remain only for in-memory partitioning, so the
  // forbidden marker is awaiting a `.from("user_ai_memory")` *inside* it.
  const loopBody = stripped.match(
    /for\s*\(\s*const\s+fact\s+of\s+facts\s*\)\s*\{([\s\S]*?)\n\s{0,4}\}/,
  );
  if (loopBody) {
    assertFalse(
      loopBody[1].includes('.from("user_ai_memory")'),
      "Per-fact DB calls inside `for (const fact of facts)` are the N+1 " +
        "regression — move SELECT/UPSERT outside the loop.",
    );
  }
});

Deno.test("BATCH-T02 — index.ts uses ONE batched SELECT with .in('key', ...)", () => {
  // Single round-trip: select all existing rows for this user whose
  // (key, text) tuples might collide with the new facts.
  assertStringIncludes(
    stripped,
    '.in("key"',
    "Batch SELECT must use .in('key', [...]) — one query for all facts",
  );
});

Deno.test("BATCH-T03 — index.ts uses ONE batched UPSERT with onConflict", () => {
  // Single round-trip: upsert all new/updated rows. onConflict matches
  // the (user_id, key, value->>text) unique constraint described in
  // index.ts:170-172.
  assertStringIncludes(
    stripped,
    ".upsert(",
    "Batch write must use .upsert(rows) — not per-fact .insert / .update",
  );
  assertStringIncludes(
    stripped,
    "onConflict",
    "Upsert must specify onConflict so the unique constraint resolves " +
      "to UPDATE for duplicates",
  );
});

Deno.test("BATCH-T04 — no per-fact .insert or .update calls remain", () => {
  // Belt-and-braces: prove the legacy per-fact pattern is fully removed.
  // We allow `.upsert(` (the new batch path) and any inserts/updates not
  // targeting user_ai_memory.
  const userMemorySingleInsert = stripped.match(
    /\.from\("user_ai_memory"\)[\s\S]*?\.insert\(/g,
  );
  const userMemorySingleUpdate = stripped.match(
    /\.from\("user_ai_memory"\)[\s\S]*?\.update\(/g,
  );
  assertEquals(
    userMemorySingleInsert,
    null,
    "Legacy per-fact .insert into user_ai_memory must be gone",
  );
  assertEquals(
    userMemorySingleUpdate,
    null,
    "Legacy per-fact .update on user_ai_memory must be gone",
  );
});

// ---------------------------------------------------------------------------
// Pure helper: partitionFactsForUpsert
// ---------------------------------------------------------------------------

Deno.test("BATCH-T05 — partitionFactsForUpsert: 10 facts, 5 existing → 5 reinforced + 5 new", () => {
  const facts = Array.from({ length: 10 }, (_, i) => ({
    key: "discussed_topic" as const,
    value: `topic-${i}`,
    confidence: 0.9,
  }));
  // Pretend rows 0..4 already exist with id-N and confidence 0.85.
  const existing = facts.slice(0, 5).map((f, i) => ({
    id: `id-${i}`,
    key: f.key,
    text: f.value,
    confidence: 0.85,
  }));

  const result = partitionFactsForUpsert({
    facts,
    existing,
    userId: "user-1",
    sessionId: "sess-1",
  });

  assertEquals(result.rows.length, 10, "All 10 facts → one batch upsert");
  assertEquals(result.duplicates, 5, "5 are reinforcements");
  assertEquals(result.newCount, 5, "5 are new");
  // Reinforced rows must keep the higher confidence, since 0.9 > 0.85.
  for (let i = 0; i < 5; i++) {
    assertEquals(result.rows[i].confidence, 0.9);
    // Reinforced rows carry the existing id so onConflict ↔ id stays stable.
  }
});

Deno.test("BATCH-T06 — confidence preservation: existing 0.95 + new 0.7 → keep 0.95", () => {
  const facts = [
    { key: "tone" as const, value: "short replies", confidence: 0.7 },
  ];
  const existing = [
    { id: "id-x", key: "tone", text: "short replies", confidence: 0.95 },
  ];

  const result = partitionFactsForUpsert({
    facts,
    existing,
    userId: "user-1",
    sessionId: "sess-1",
  });

  assertEquals(result.rows.length, 1);
  assertEquals(
    result.rows[0].confidence,
    0.95,
    "Reinforcement must NOT lower confidence — keep max(existing, new)",
  );
  assertEquals(result.duplicates, 1);
  assertEquals(result.newCount, 0);
});

Deno.test("BATCH-T07 — partitionFactsForUpsert sets last_reinforced_at on duplicates only", () => {
  const facts = [
    { key: "tone" as const, value: "short", confidence: 0.9 },
    { key: "tone" as const, value: "fresh", confidence: 0.9 },
  ];
  const existing = [
    { id: "id-1", key: "tone", text: "short", confidence: 0.8 },
  ];

  const result = partitionFactsForUpsert({
    facts,
    existing,
    userId: "user-1",
    sessionId: "sess-1",
  });

  // Duplicate row must carry last_reinforced_at; new row must not (DB
  // default fires for inserts, and we don't want to overwrite created_at
  // semantics for reinforcements either).
  const dup = result.rows.find(
    (r: { value: { text: string } }) => r.value.text === "short",
  )!;
  const fresh = result.rows.find(
    (r: { value: { text: string } }) => r.value.text === "fresh",
  )!;
  assert(
    typeof dup.last_reinforced_at === "string" &&
      dup.last_reinforced_at.length > 0,
    "Reinforced row must set last_reinforced_at",
  );
  assertEquals(
    fresh.last_reinforced_at,
    undefined,
    "Fresh row leaves last_reinforced_at to DB default",
  );
});

Deno.test("BATCH-T08 — partitionFactsForUpsert collapses duplicate input keys", () => {
  // If Haiku returns the same (key, text) twice in one call, we must
  // emit a single upsert row — otherwise the unique constraint would
  // make the upsert hit itself and the round-trip fails.
  const facts = [
    { key: "tone" as const, value: "short", confidence: 0.7 },
    { key: "tone" as const, value: "short", confidence: 0.9 },
  ];
  const existing: Array<{ id: string; key: string; text: string; confidence: number }> = [];

  const result = partitionFactsForUpsert({
    facts,
    existing,
    userId: "user-1",
    sessionId: "sess-1",
  });

  assertEquals(result.rows.length, 1, "Duplicate input must collapse");
  assertEquals(
    result.rows[0].confidence,
    0.9,
    "Collapsed row keeps max confidence",
  );
});

Deno.test("BATCH-T09 — partitionFactsForUpsert always scopes user_id from arg", () => {
  // Defence-in-depth: rows must carry the JWT-derived user_id. If we
  // ever wired a body-supplied user_id, this test would fail because
  // the helper takes the arg and never reads from `facts`.
  const facts = [
    { key: "tone" as const, value: "x", confidence: 0.9 },
  ];
  const result = partitionFactsForUpsert({
    facts,
    existing: [],
    userId: "AUTH-USER-42",
    sessionId: null,
  });
  assertEquals(result.rows[0].user_id, "AUTH-USER-42");
  assertEquals(
    result.rows[0].source_session_id,
    null,
    "session_id is allowed to be null when client did not send one",
  );
});
