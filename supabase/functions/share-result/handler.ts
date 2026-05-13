// share-result/handler.ts — pure business logic for the "Share this analysis"
// feature. Split from index.ts so tests can inject fakes for the DB layer and
// the redactor without standing up a real Supabase + Anthropic stack.
//
// Flow (POST):
//   1. Validate { source_type, source_id } — both required.
//   2. Verify the caller owns source_id in the table dictated by source_type:
//        contract_review    → public.contract_reviews
//        legal_advice       → public.case_messages   (chat AI replies)
//        deadline_analysis  → public.case_deadlines  (radar entries)
//   3. Pull the raw analysis text for that row.
//   4. Run redactForSharing — two-stage scrub + structured envelope.
//   5. Generate an 8-char nanoid slug (retry on UNIQUE collision).
//   6. Insert into public.shared_results.
//   7. Return { share_url, slug, preview }.
//
// GET (by slug):
//   1. Load the row WHERE share_slug = $1 AND is_public AND expires_at > now()
//   2. Increment view_count (best-effort; failure does not block the response)
//   3. Return marketing-safe columns ONLY (never user_id, source_id, etc.)
// -----------------------------------------------------------------------------

import {
  redactForSharing,
  type ShareableSourceType,
  generateSlug,
  type RedactionEnvelope,
} from "../_shared/redactor.ts";

// ─── Public contracts ───────────────────────────────────────────────────────

export type SourceType = ShareableSourceType;

export interface CreateShareRequest {
  source_type: SourceType;
  source_id: string;
}

/** Marketing-safe public view of a share. Never includes user_id, source_id,
 *  or raw analysis text. */
export interface PublicShareView {
  slug: string;
  title: string;
  insight_summary: string;
  jurisdiction: string | null;
  case_type: string | null;
  source_type: SourceType;
  bullets: string[];
  risks: string[];
  statute_refs: string[];
  monetary_amounts: string[];
  og_image_url: string | null;
  view_count: number;
  created_at: string;
  expires_at: string;
}

export interface CreateShareSuccess {
  kind: "success";
  status: 200;
  body: {
    slug: string;
    share_url: string;
    preview: PublicShareView;
  };
}

export interface CreateShareError {
  kind: "error";
  status: 400 | 401 | 403 | 404 | 500;
  body: { error: string; reason?: string };
}

export type CreateShareResult = CreateShareSuccess | CreateShareError;

// ─── Validation ─────────────────────────────────────────────────────────────

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const VALID_SOURCES: ReadonlySet<SourceType> = new Set([
  "contract_review",
  "legal_advice",
  "deadline_analysis",
]);

export function validateCreateRequest(raw: unknown): {
  ok: true;
  value: CreateShareRequest;
} | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") {
    return { ok: false, error: "Body must be an object" };
  }
  const r = raw as Record<string, unknown>;
  const st = r.source_type;
  if (typeof st !== "string" || !VALID_SOURCES.has(st as SourceType)) {
    return { ok: false, error: "source_type must be one of: contract_review, legal_advice, deadline_analysis" };
  }
  const id = r.source_id;
  if (typeof id !== "string" || !UUID_RE.test(id)) {
    return { ok: false, error: "source_id must be a UUID string" };
  }
  return {
    ok: true,
    value: { source_type: st as SourceType, source_id: id },
  };
}

// ─── DB binding (interface only — implementation lives in index.ts) ────────

/** Snapshot of a source row sufficient for redaction. The handler does
 *  NOT care which table it came from. */
export interface SourceSnapshot {
  /** Concatenated analysis text — what we feed to the redactor. */
  rawText: string;
  /** Owner — must match the caller for the create flow to proceed. */
  ownerId: string;
}

export interface ShareDbClient {
  /** Look up the source row. Returns null when not found. */
  fetchSource(
    sourceType: SourceType,
    sourceId: string,
  ): Promise<SourceSnapshot | null>;

  /** Insert a new share row. Returns the persisted slug on success.
   *  Implementations MUST retry on unique-slug collision (the handler
   *  passes a freshly-generated slug per attempt). */
  insertShare(row: {
    user_id: string;
    share_slug: string;
    source_type: SourceType;
    source_id: string;
    title: string;
    insight_summary: string;
    jurisdiction: string | null;
    case_type: string | null;
    redacted_content: RedactionEnvelope["redacted_content"];
    og_image_url: string | null;
  }): Promise<{ id: string; created_at: string; expires_at: string }>;

  /** Idempotent: increment view_count on read. Best-effort; failures are
   *  swallowed. */
  bumpViewCount(slug: string): Promise<void>;

  /** Read a public, non-expired share. Returns null on miss. */
  fetchPublicShare(slug: string): Promise<PublicShareView | null>;
}

// ─── Redactor binding ──────────────────────────────────────────────────────

export type RedactorFn = (opts: {
  rawText: string;
  sourceType: SourceType;
}) => Promise<RedactionEnvelope>;

// ─── Create flow ───────────────────────────────────────────────────────────

export interface RunCreateOpts {
  userId: string;
  request: CreateShareRequest;
  db: ShareDbClient;
  redactor: RedactorFn;
  /** Base URL for the public share page. Default: 'https://advocat.ee'. */
  publicBaseUrl?: string;
  /** Override for tests — generates the slug. Default: [generateSlug]. */
  slugGen?: () => string;
}

const SLUG_RETRY_LIMIT = 5;

export async function runCreateShare(
  opts: RunCreateOpts,
): Promise<CreateShareResult> {
  // 1. Ownership check.
  const src = await opts.db.fetchSource(
    opts.request.source_type,
    opts.request.source_id,
  );
  if (!src) {
    return {
      kind: "error",
      status: 404,
      body: { error: "Source not found", reason: "no_source" },
    };
  }
  if (src.ownerId !== opts.userId) {
    return {
      kind: "error",
      status: 403,
      body: { error: "You do not own this source", reason: "not_owner" },
    };
  }
  if (!src.rawText || src.rawText.trim().length === 0) {
    return {
      kind: "error",
      status: 400,
      body: {
        error: "Source has no analysis text to share",
        reason: "empty_source",
      },
    };
  }

  // 2. Redact.
  let envelope: RedactionEnvelope;
  try {
    envelope = await opts.redactor({
      rawText: src.rawText,
      sourceType: opts.request.source_type,
    });
  } catch (e) {
    return {
      kind: "error",
      status: 500,
      body: {
        error: `Redaction failed: ${String(e).slice(0, 120)}`,
        reason: "redact_failed",
      },
    };
  }

  // 3. Insert with slug-collision retry.
  const slugFactory = opts.slugGen ?? (() => generateSlug(8));
  let lastErr: unknown = null;
  let inserted: { id: string; created_at: string; expires_at: string } | null =
    null;
  let slug = "";
  for (let attempt = 0; attempt < SLUG_RETRY_LIMIT; attempt++) {
    slug = slugFactory();
    try {
      inserted = await opts.db.insertShare({
        user_id: opts.userId,
        share_slug: slug,
        source_type: opts.request.source_type,
        source_id: opts.request.source_id,
        title: envelope.title,
        insight_summary: envelope.insight_summary,
        jurisdiction: envelope.jurisdiction,
        case_type: envelope.case_type,
        redacted_content: envelope.redacted_content,
        og_image_url: null, // OG image is generated asynchronously
      });
      break;
    } catch (e) {
      lastErr = e;
      // Continue and try a new slug.
    }
  }
  if (!inserted) {
    return {
      kind: "error",
      status: 500,
      body: {
        error: `Insert failed after ${SLUG_RETRY_LIMIT} retries: ${
          String(lastErr).slice(0, 120)
        }`,
        reason: "insert_failed",
      },
    };
  }

  // 4. Build the public response.
  const baseUrl = opts.publicBaseUrl ?? "https://advocat.ee";
  const preview: PublicShareView = {
    slug,
    title: envelope.title,
    insight_summary: envelope.insight_summary,
    jurisdiction: envelope.jurisdiction,
    case_type: envelope.case_type,
    source_type: opts.request.source_type,
    bullets: envelope.redacted_content.bullets,
    risks: envelope.redacted_content.risks,
    statute_refs: envelope.redacted_content.statute_refs,
    monetary_amounts: envelope.redacted_content.monetary_amounts,
    og_image_url: null,
    view_count: 0,
    created_at: inserted.created_at,
    expires_at: inserted.expires_at,
  };

  return {
    kind: "success",
    status: 200,
    body: {
      slug,
      share_url: `${baseUrl}/s/${slug}`,
      preview,
    },
  };
}

// ─── Read flow ─────────────────────────────────────────────────────────────

export interface RunReadOpts {
  slug: string;
  db: ShareDbClient;
}

export type ReadShareResult =
  | { kind: "success"; status: 200; body: PublicShareView }
  | { kind: "error"; status: 404; body: { error: string } };

/** Validate slug shape before touching the DB. 8 URL-safe chars from the
 *  redactor's alphabet. */
export function isValidSlug(s: unknown): s is string {
  return typeof s === "string" && /^[0-9A-Za-z]{8}$/.test(s);
}

export async function runReadShare(opts: RunReadOpts): Promise<ReadShareResult> {
  if (!isValidSlug(opts.slug)) {
    return {
      kind: "error",
      status: 404,
      body: { error: "Share not found" },
    };
  }
  const view = await opts.db.fetchPublicShare(opts.slug);
  if (!view) {
    return {
      kind: "error",
      status: 404,
      body: { error: "Share not found" },
    };
  }
  // Best-effort view-count bump. Don't block the response on failure.
  try {
    await opts.db.bumpViewCount(opts.slug);
  } catch (_) {
    // swallow
  }
  return { kind: "success", status: 200, body: view };
}
