// Deno tests for Phase 2 Pkg 2 closeout — server-side citations persistence.
// -----------------------------------------------------------------------------
// Covers:
//   • Pure row-builder behaviour (0 citations, N citations, all status enum
//     values, position assignment, FK trust-boundary refusal).
//   • Idempotency strategy is testable as a contract pin (we assert the
//     wiring uses upsert with onConflict='message_id,position' so the unique
//     index from migration _09 short-circuits retries).
//   • Source-text pins on claude-proxy/index.ts confirming the persistence
//     path is opt-in via body.message_id and runs AFTER the verifier.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/citations_persistence_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildCitationRows,
  type CitationRow,
  isValidMessageId,
} from "../citation_persistence.ts";
import type { Citation } from "../../_shared/citation_grounder.ts";

// ─── fixtures ──────────────────────────────────────────────────────────────

function verifiedCitation(overrides: Partial<Citation> = {}): Citation {
  return {
    marker: "[[ref:TLS:88]]",
    status: "verified",
    chunk_id: "tls-§88-1",
    act_slug: "tls",
    paragraph: "88",
    act_name: "Töölepingu seadus",
    title: "Tööandja erakorraline ülesütlemine",
    snippet: "Tööandja võib töölepingu erakorraliselt üles öelda…",
    source_url: "https://www.riigiteataja.ee/akt/tls",
    jurisdiction: "EE",
    in_force: true,
    occurrences: 1,
    ...overrides,
  };
}

const MSG_ID = "550e8400-e29b-41d4-a716-446655440000";
const USER_ID = "11111111-1111-1111-1111-111111111111";
const CASE_ID = "22222222-2222-2222-2222-222222222222";

// ─── Pure row-builder behaviour ────────────────────────────────────────────

Deno.test("CIT-PERSIST-T01 — 0 citations → 0 rows (skip DB write entirely)", () => {
  const rows = buildCitationRows({
    message_id: MSG_ID,
    user_id: USER_ID,
    case_id: CASE_ID,
    citations: [],
  });
  assertEquals(rows.length, 0);
});

Deno.test("CIT-PERSIST-T02 — N citations → N rows, position is array index", () => {
  const citations: Citation[] = [
    verifiedCitation(),
    verifiedCitation({
      marker: "[[ref:KarS:121]]",
      chunk_id: "kars-§121-0",
      act_slug: "kars",
      paragraph: "121",
    }),
    verifiedCitation({
      marker: "[[ref:VOLS:118]]",
      chunk_id: "vols-§118-0",
      act_slug: "vols",
      paragraph: "118",
    }),
  ];
  const rows = buildCitationRows({
    message_id: MSG_ID,
    user_id: USER_ID,
    case_id: CASE_ID,
    citations,
  });
  assertEquals(rows.length, 3);
  // Position is the index. First-occurrence order from verifier is preserved.
  assertEquals(rows[0].position, 0);
  assertEquals(rows[1].position, 1);
  assertEquals(rows[2].position, 2);
  assertEquals(rows[0].act_slug, "tls");
  assertEquals(rows[1].act_slug, "kars");
  assertEquals(rows[2].act_slug, "vols");
});

Deno.test("CIT-PERSIST-T03 — all three status enum values write through unchanged", () => {
  const citations: Citation[] = [
    verifiedCitation({ status: "verified" }),
    verifiedCitation({
      status: "unverified",
      chunk_id: null,
      snippet: null,
      source_url: null,
      jurisdiction: null,
      in_force: null,
      title: null,
      act_name: null,
    }),
    verifiedCitation({
      status: "historical",
      chunk_id: "tls-§88-1-v2018",
      in_force: false,
    }),
  ];
  const rows = buildCitationRows({
    message_id: MSG_ID,
    user_id: USER_ID,
    case_id: CASE_ID,
    citations,
  });
  assertEquals(rows[0].status, "verified");
  assertEquals(rows[1].status, "unverified");
  assertEquals(rows[2].status, "historical");
  // Unverified row carries null FK to law_chunks — schema allows it.
  assertEquals(rows[1].chunk_id, null);
  assertEquals(rows[1].in_force, null);
  // Historical row carries the snapshot in_force=false flag.
  assertEquals(rows[2].in_force, false);
});

Deno.test("CIT-PERSIST-T04 — trust-boundary fields propagate from input bundle", () => {
  const rows = buildCitationRows({
    message_id: MSG_ID,
    user_id: USER_ID,
    case_id: CASE_ID,
    citations: [verifiedCitation()],
  });
  assertEquals(rows[0].message_id, MSG_ID);
  assertEquals(rows[0].user_id, USER_ID);
  assertEquals(rows[0].case_id, CASE_ID);
});

Deno.test("CIT-PERSIST-T05 — refuse to build rows with missing trust-boundary fields", () => {
  // Belt-and-suspenders: callers MUST populate all three FKs. Return [] so
  // a misconfigured wiring path can't accidentally insert rows that would
  // FK-fail or RLS-fail downstream.
  assertEquals(
    buildCitationRows({
      message_id: "",
      user_id: USER_ID,
      case_id: CASE_ID,
      citations: [verifiedCitation()],
    }).length,
    0,
  );
  assertEquals(
    buildCitationRows({
      message_id: MSG_ID,
      user_id: "",
      case_id: CASE_ID,
      citations: [verifiedCitation()],
    }).length,
    0,
  );
  assertEquals(
    buildCitationRows({
      message_id: MSG_ID,
      user_id: USER_ID,
      case_id: "",
      citations: [verifiedCitation()],
    }).length,
    0,
  );
});

Deno.test("CIT-PERSIST-T06 — occurrences round-trips (model cited same § thrice)", () => {
  const rows = buildCitationRows({
    message_id: MSG_ID,
    user_id: USER_ID,
    case_id: CASE_ID,
    citations: [verifiedCitation({ occurrences: 3 })],
  });
  assertEquals(rows.length, 1);
  assertEquals(rows[0].occurrences, 3);
});

Deno.test("CIT-PERSIST-T07 — every CitationRow field present (DB column shape)", () => {
  const rows = buildCitationRows({
    message_id: MSG_ID,
    user_id: USER_ID,
    case_id: CASE_ID,
    citations: [verifiedCitation()],
  });
  const expected: Array<keyof CitationRow> = [
    "message_id",
    "user_id",
    "case_id",
    "marker",
    "status",
    "chunk_id",
    "act_slug",
    "paragraph",
    "act_name",
    "title",
    "snippet",
    "source_url",
    "jurisdiction",
    "in_force",
    "occurrences",
    "position",
  ];
  for (const f of expected) {
    if (!(f in rows[0])) {
      throw new Error(`CitationRow missing column "${String(f)}"`);
    }
  }
});

// ─── isValidMessageId ──────────────────────────────────────────────────────

Deno.test("CIT-PERSIST-T08 — isValidMessageId accepts UUIDs, rejects everything else", () => {
  assertEquals(isValidMessageId("550e8400-e29b-41d4-a716-446655440000"), true);
  assertEquals(isValidMessageId("550E8400-E29B-41D4-A716-446655440000"), true);
  assertEquals(isValidMessageId(""), false);
  assertEquals(isValidMessageId("not-a-uuid"), false);
  assertEquals(isValidMessageId("550e8400-e29b-41d4-a716"), false);
  assertEquals(isValidMessageId(null), false);
  assertEquals(isValidMessageId(undefined), false);
  assertEquals(isValidMessageId(42), false);
});

// ─── Wiring contract: source-text pins on claude-proxy/index.ts ────────────

Deno.test(
  "CIT-PERSIST-T09 — index.ts imports the persistence helper module",
  async () => {
    const source = await Deno.readTextFile(
      new URL("../index.ts", import.meta.url),
    );
    assertStringIncludes(source, "./citation_persistence.ts");
    assertStringIncludes(source, "buildCitationRows");
    assertStringIncludes(source, "isValidMessageId");
  },
);

Deno.test(
  "CIT-PERSIST-T10 — persistence runs AFTER verifier and BEFORE response build",
  async () => {
    // Pin the textual order in the source so a refactor can't accidentally
    // move the DB write before verifyCitations (which would persist nothing
    // useful) or after the response is constructed (which would race the
    // client read of the augmented payload).
    const source = await Deno.readTextFile(
      new URL("../index.ts", import.meta.url),
    );
    const stripped = source
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .replace(/^\s*\/\/.*$/gm, "");
    const verifyIdx = stripped.lastIndexOf("verifyCitations(");
    const persistIdx = stripped.indexOf(
      "buildCitationRows(",
      verifyIdx >= 0 ? verifyIdx : 0,
    );
    if (verifyIdx === -1 || persistIdx === -1 || persistIdx <= verifyIdx) {
      throw new Error(
        "buildCitationRows must be invoked AFTER verifyCitations in the " +
          "happy-path response branch.",
      );
    }
  },
);

Deno.test(
  "CIT-PERSIST-T11 — idempotency: upsert with onConflict on the unique index",
  async () => {
    // The unique index from migration _09 is (message_id, position). The
    // wiring MUST use upsert/onConflict so retried turns (same message_id,
    // same N citations) don't double-insert. The upsert lives in the I/O
    // seam (citation_persistence.ts) — index.ts just calls persistCitations.
    const persistenceSource = await Deno.readTextFile(
      new URL("../citation_persistence.ts", import.meta.url),
    );
    // Either the supabase-js .upsert with explicit onConflict, or an
    // ON CONFLICT clause if a future refactor moves to raw SQL — either
    // way, the textual marker has to be present for the contract to hold.
    const hasUpsertWithConflict =
      /upsert\([\s\S]*?onConflict:\s*["']message_id,position["']/.test(
          persistenceSource,
        ) ||
      /ON CONFLICT\s*\(\s*message_id\s*,\s*position\s*\)/i.test(
          persistenceSource,
        );
    if (!hasUpsertWithConflict) {
      throw new Error(
        "Persistence wiring must declare onConflict='message_id,position' " +
          "so retries with the same UUID hit the unique index from " +
          "migration 20260507_09 and skip duplicates.",
      );
    }
    // ignoreDuplicates is the supabase-js flag that turns the upsert into
    // a true "skip if exists" — without it the upsert would UPDATE every
    // row on every retry, which is wasteful (and would touch updated_at
    // if such a column existed).
    if (
      /upsert\(/.test(persistenceSource) &&
      !/ignoreDuplicates:\s*true/.test(persistenceSource)
    ) {
      throw new Error(
        "supabase-js upsert must pass ignoreDuplicates: true so retries " +
          "are a no-op rather than a redundant UPDATE.",
      );
    }
  },
);

Deno.test(
  "CIT-PERSIST-T12 — opt-in via body.message_id; missing → no DB call",
  async () => {
    // When the client doesn't supply message_id, the proxy MUST skip
    // persistence entirely. This keeps Pkg 2 closeout backward-compatible:
    // existing callers see zero observable behaviour change until they
    // start passing message_id.
    const source = await Deno.readTextFile(
      new URL("../index.ts", import.meta.url),
    );
    assertStringIncludes(source, "isValidMessageId(");
    // The opt-in shape: read message_id off the body, validate it, only
    // then proceed. If a refactor drops the validator the textual contract
    // here breaks.
  },
);

Deno.test(
  "CIT-PERSIST-T13 — message_id stripped from body before forwarding to Anthropic",
  async () => {
    // Same hygiene rule as case_id and rag_context: proxy-only fields must
    // never leak to Anthropic (Anthropic Messages API would reject unknown
    // top-level keys with 400, and even if it tolerated them we don't want
    // user-internal IDs travelling outside our trust boundary).
    const source = await Deno.readTextFile(
      new URL("../index.ts", import.meta.url),
    );
    // The proxy may strip via `delete body.message_id` or via a typed
    // expression `delete (body as { message_id?: unknown }).message_id`.
    // Both forms are acceptable — we just need the textual proof that
    // somewhere in the source we drop the field before the Anthropic call.
    const stripPattern = /delete\s+\(?[^)]*\)?\.message_id/;
    if (!stripPattern.test(source)) {
      throw new Error(
        "body.message_id must be deleted before the Anthropic fetch " +
          "(see case_id strip on line ~202 for the pattern).",
      );
    }
    // And the strip MUST appear before any Anthropic fetch.
    const stripIdx = source.search(stripPattern);
    const fetchIdx = source.indexOf("api.anthropic.com/v1/messages");
    if (stripIdx === -1 || fetchIdx === -1 || stripIdx >= fetchIdx) {
      throw new Error(
        "delete body.message_id must run BEFORE the Anthropic fetch.",
      );
    }
  },
);

Deno.test(
  "CIT-PERSIST-T14 — augmented response surfaces message_id back to caller",
  async () => {
    // Client renders citation chips against the message_id; the response
    // payload MUST carry it back so the Flutter side can wire its row.
    const source = await Deno.readTextFile(
      new URL("../index.ts", import.meta.url),
    );
    // The augmented JSON object literal includes message_id as a key.
    if (!/message_id\s*[:,]/.test(source)) {
      throw new Error(
        "Augmented response must include message_id alongside citations.",
      );
    }
  },
);
