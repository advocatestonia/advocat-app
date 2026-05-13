// share_result.test.ts — share-result handler unit tests.
// ----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/share_result.test.ts
//
// Coverage (10 cases):
//   S01  validateCreateRequest rejects missing source_type           → error
//   S02  validateCreateRequest rejects bad source_type slug          → error
//   S03  validateCreateRequest rejects non-UUID source_id            → error
//   S04  validateCreateRequest accepts well-formed request           → ok
//   S05  runCreateShare returns 404 when source not found
//   S06  runCreateShare returns 403 when caller is not owner
//   S07  runCreateShare returns 400 when source has empty text
//   S08  runCreateShare happy path → 200, slug embedded in URL, preview shape
//   S09  runCreateShare retries on slug-collision and eventually succeeds
//   S10  runCreateShare bubbles redactor failure as 500
//   S11  runReadShare returns 404 for malformed slug (skips DB)
//   S12  runReadShare returns 404 on miss
//   S13  runReadShare happy path → bumps view_count, returns marketing view
// ----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Env stubs.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

import {
  isValidSlug,
  type PublicShareView,
  runCreateShare,
  runReadShare,
  type ShareDbClient,
  type SourceSnapshot,
  type SourceType,
  validateCreateRequest,
} from "../share-result/handler.ts";
import type { RedactionEnvelope } from "../_shared/redactor.ts";

const UUID = "11111111-1111-1111-1111-111111111111";
const USER = "user-abc-123";
const OTHER_USER = "user-def-456";

function fakeRedactor(
  override?: Partial<RedactionEnvelope>,
): (opts: { rawText: string; sourceType: SourceType }) => Promise<RedactionEnvelope> {
  return async () => ({
    title: "Sample share",
    insight_summary: "Sample insight",
    jurisdiction: "EE",
    case_type: "dealer_agreement",
    redacted_content: {
      bullets: ["b1", "b2"],
      risks: ["r1"],
      statute_refs: ["VÕS § 199"],
      monetary_amounts: ["~€15,000"],
    },
    regex_replacements: {},
    ...override,
  });
}

interface FakeDbState {
  sources: Map<string, SourceSnapshot>;
  shares: Map<string, {
    user_id: string;
    share_slug: string;
    source_type: SourceType;
    title: string;
    insight_summary: string;
    jurisdiction: string | null;
    case_type: string | null;
    redacted_content: RedactionEnvelope["redacted_content"];
    view_count: number;
    is_public: boolean;
    expires_at_ms: number;
    created_at: string;
  }>;
  /** Track view-count bumps for assertions. */
  bumpedSlugs: string[];
  /** Inject N initial slug collisions on insertShare to exercise the retry. */
  forcedCollisions: number;
}

function newDb(): { db: ShareDbClient; state: FakeDbState } {
  const state: FakeDbState = {
    sources: new Map(),
    shares: new Map(),
    bumpedSlugs: [],
    forcedCollisions: 0,
  };
  const nowIso = "2026-05-14T10:00:00.000Z";
  const ninetyDaysMs = 90 * 24 * 60 * 60_000;

  const db: ShareDbClient = {
    async fetchSource(_st, id) {
      return state.sources.get(id) ?? null;
    },
    async insertShare(row) {
      if (state.forcedCollisions > 0) {
        state.forcedCollisions--;
        throw new Error("duplicate key value violates unique constraint");
      }
      if (state.shares.has(row.share_slug)) {
        throw new Error("duplicate key value violates unique constraint");
      }
      state.shares.set(row.share_slug, {
        user_id: row.user_id,
        share_slug: row.share_slug,
        source_type: row.source_type,
        title: row.title,
        insight_summary: row.insight_summary,
        jurisdiction: row.jurisdiction,
        case_type: row.case_type,
        redacted_content: row.redacted_content,
        view_count: 0,
        is_public: true,
        expires_at_ms: Date.now() + ninetyDaysMs,
        created_at: nowIso,
      });
      return {
        id: `id-${row.share_slug}`,
        created_at: nowIso,
        expires_at: new Date(Date.now() + ninetyDaysMs).toISOString(),
      };
    },
    async bumpViewCount(slug) {
      state.bumpedSlugs.push(slug);
      const row = state.shares.get(slug);
      if (row) row.view_count++;
    },
    async fetchPublicShare(slug): Promise<PublicShareView | null> {
      const r = state.shares.get(slug);
      if (!r || !r.is_public || r.expires_at_ms <= Date.now()) return null;
      return {
        slug: r.share_slug,
        title: r.title,
        insight_summary: r.insight_summary,
        jurisdiction: r.jurisdiction,
        case_type: r.case_type,
        source_type: r.source_type,
        bullets: r.redacted_content.bullets,
        risks: r.redacted_content.risks,
        statute_refs: r.redacted_content.statute_refs,
        monetary_amounts: r.redacted_content.monetary_amounts,
        og_image_url: null,
        view_count: r.view_count,
        created_at: r.created_at,
        expires_at: new Date(r.expires_at_ms).toISOString(),
      };
    },
  };
  return { db, state };
}

// ─── S01-S04: request validation ───────────────────────────────────────────

Deno.test("S01: validateCreateRequest rejects missing source_type", () => {
  const v = validateCreateRequest({ source_id: UUID });
  assert(!v.ok);
});

Deno.test("S02: validateCreateRequest rejects bad source_type slug", () => {
  const v = validateCreateRequest({
    source_type: "deportation",
    source_id: UUID,
  });
  assert(!v.ok);
});

Deno.test("S03: validateCreateRequest rejects non-UUID source_id", () => {
  const v = validateCreateRequest({
    source_type: "contract_review",
    source_id: "not-a-uuid",
  });
  assert(!v.ok);
});

Deno.test("S04: validateCreateRequest accepts well-formed request", () => {
  const v = validateCreateRequest({
    source_type: "contract_review",
    source_id: UUID,
  });
  assert(v.ok);
  if (v.ok) {
    assertEquals(v.value.source_type, "contract_review");
    assertEquals(v.value.source_id, UUID);
  }
});

// ─── S05-S10: create flow ──────────────────────────────────────────────────

Deno.test("S05: runCreateShare returns 404 when source is missing", async () => {
  const { db } = newDb();
  const result = await runCreateShare({
    userId: USER,
    request: { source_type: "contract_review", source_id: UUID },
    db,
    redactor: fakeRedactor(),
  });
  assertEquals(result.kind, "error");
  assertEquals(result.status, 404);
});

Deno.test("S06: runCreateShare returns 403 when caller is not the owner", async () => {
  const { db, state } = newDb();
  state.sources.set(UUID, { ownerId: OTHER_USER, rawText: "x" });
  const result = await runCreateShare({
    userId: USER,
    request: { source_type: "contract_review", source_id: UUID },
    db,
    redactor: fakeRedactor(),
  });
  assertEquals(result.status, 403);
});

Deno.test("S07: runCreateShare returns 400 on empty source text", async () => {
  const { db, state } = newDb();
  state.sources.set(UUID, { ownerId: USER, rawText: "   " });
  const result = await runCreateShare({
    userId: USER,
    request: { source_type: "contract_review", source_id: UUID },
    db,
    redactor: fakeRedactor(),
  });
  assertEquals(result.status, 400);
});

Deno.test("S08: runCreateShare happy path — 200 + slug URL + preview shape", async () => {
  const { db, state } = newDb();
  state.sources.set(UUID, {
    ownerId: USER,
    rawText: "Long analysis text".repeat(50),
  });
  const result = await runCreateShare({
    userId: USER,
    request: { source_type: "contract_review", source_id: UUID },
    db,
    redactor: fakeRedactor(),
    publicBaseUrl: "https://test.example.com",
  });
  assertEquals(result.kind, "success");
  if (result.kind !== "success") return;
  assertEquals(result.status, 200);
  // 8-char URL-safe slug.
  assert(/^[0-9A-Za-z]{8}$/.test(result.body.slug));
  assertStringIncludes(result.body.share_url, "https://test.example.com/s/");
  assertStringIncludes(result.body.share_url, result.body.slug);
  assertEquals(result.body.preview.title, "Sample share");
  assertEquals(result.body.preview.bullets.length, 2);
  assertEquals(result.body.preview.jurisdiction, "EE");
});

Deno.test("S09: runCreateShare retries on slug collision", async () => {
  const { db, state } = newDb();
  state.sources.set(UUID, { ownerId: USER, rawText: "non-empty" });
  // Force first two attempts to "collide".
  state.forcedCollisions = 2;
  const result = await runCreateShare({
    userId: USER,
    request: { source_type: "contract_review", source_id: UUID },
    db,
    redactor: fakeRedactor(),
  });
  assertEquals(result.kind, "success");
  assertEquals(state.forcedCollisions, 0, "should have used both forced collisions");
});

Deno.test("S10: runCreateShare bubbles redactor failure as 500", async () => {
  const { db, state } = newDb();
  state.sources.set(UUID, { ownerId: USER, rawText: "non-empty" });
  const result = await runCreateShare({
    userId: USER,
    request: { source_type: "contract_review", source_id: UUID },
    db,
    redactor: async () => {
      throw new Error("Haiku unavailable");
    },
  });
  assertEquals(result.kind, "error");
  assertEquals(result.status, 500);
});

// ─── S11-S13: read flow ────────────────────────────────────────────────────

Deno.test("S11: runReadShare 404s on malformed slug (skips DB)", async () => {
  const { db, state } = newDb();
  const result = await runReadShare({ slug: "../etc/passwd", db });
  assertEquals(result.kind, "error");
  assertEquals(result.status, 404);
  assertEquals(state.bumpedSlugs.length, 0, "DB must not be touched for bad slug");
});

Deno.test("S12: runReadShare 404s on miss", async () => {
  const { db } = newDb();
  const result = await runReadShare({ slug: "abcd1234", db });
  assertEquals(result.kind, "error");
  assertEquals(result.status, 404);
});

Deno.test("S13: runReadShare happy path — bumps view + returns marketing view", async () => {
  const { db, state } = newDb();
  // Prime the DB by going through the create flow once.
  state.sources.set(UUID, { ownerId: USER, rawText: "rich text" });
  const create = await runCreateShare({
    userId: USER,
    request: { source_type: "contract_review", source_id: UUID },
    db,
    redactor: fakeRedactor(),
  });
  if (create.kind !== "success") throw new Error("setup failed");
  const slug = create.body.slug;

  const read = await runReadShare({ slug, db });
  assertEquals(read.kind, "success");
  if (read.kind !== "success") return;
  assertEquals(read.body.slug, slug);
  assertEquals(state.bumpedSlugs, [slug]);
  // The response reflects the count BEFORE the bump (so first read shows 0).
  assertEquals(read.body.view_count, 0);
  // After the first read the underlying row has been bumped to 1 — the
  // second read therefore reports 1 and bumps to 2.
  const readAgain = await runReadShare({ slug, db });
  if (readAgain.kind !== "success") throw new Error("readAgain failed");
  assertEquals(readAgain.body.view_count, 1);
  assertEquals(state.bumpedSlugs.length, 2);
});

// ─── Slug shape helper ─────────────────────────────────────────────────────

Deno.test("isValidSlug — accepts 8 URL-safe chars, rejects everything else", () => {
  assert(isValidSlug("abcd1234"));
  assert(isValidSlug("AaBbCc99"));
  assert(!isValidSlug("short"));
  assert(!isValidSlug("toolongtobevalid"));
  assert(!isValidSlug("has space"));
  assert(!isValidSlug("../etc/p"));
  assert(!isValidSlug(123));
  assert(!isValidSlug(null));
});
