// doc-indexer/handler.ts
// -----------------------------------------------------------------------------
// Pure(ish) handler logic for the doc-indexer edge function, separated from the
// HTTP/serve wiring so it can be unit-tested with injected DB + embed deps.
//
// doc-indexer indexes ONE document on demand:
//   1. Load the source row (case_documents OR vault `documents`) — verifying
//      it belongs to the authenticated user.
//   2. Pull its already-extracted plain text (parsed_text / ocr_text).
//   3. Chunk it (overlapping windows) + embed each chunk.
//   4. Delete-then-insert chunks for that source into user_doc_chunks so a
//      re-index is idempotent.
//
// We never re-OCR/re-parse here — text extraction is pdf-parser's job and the
// text is already persisted on the source row. This keeps doc-indexer cheap
// and avoids duplicating the parse pipeline.
// -----------------------------------------------------------------------------

import {
  chunkDocument,
  EMBED_BATCH_SIZE,
  embedCostUsd,
  type EmbedResult,
} from "../_shared/doc_chunker.ts";

export type SourceKind = "case_document" | "vault_document";

export interface SourceDoc {
  sourceId: string;
  userId: string;
  orgId: string | null;
  title: string | null;
  text: string;
}

/** Injected data layer — keeps the handler testable. */
export interface IndexerDeps {
  /** Load the source row, scoped to the caller. Returns null if not found or
   *  not owned by the caller. */
  loadSource(
    kind: SourceKind,
    sourceId: string,
    callerId: string
  ): Promise<SourceDoc | null>;
  /** Delete all existing chunks for a source (for clean re-index). */
  deleteChunks(kind: SourceKind, sourceId: string): Promise<void>;
  /** Bulk-insert chunk rows. */
  insertChunks(rows: ChunkInsert[]): Promise<void>;
  /** Embed a batch of texts. */
  embed(texts: string[]): Promise<EmbedResult>;
}

export interface ChunkInsert {
  user_id: string;
  org_id: string | null;
  source_kind: SourceKind;
  source_id: string;
  doc_title: string | null;
  chunk_index: number;
  text: string;
  char_start: number;
  char_end: number;
  embedding: number[];
}

export interface IndexResult {
  status: number;
  body: Record<string, unknown>;
}

const MAX_DOC_CHARS = 1_500_000; // ~500 pages of text — refuse pathological docs.

function isUuid(s: unknown): s is string {
  return (
    typeof s === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)
  );
}

/** Validate the request body. */
export function parseIndexRequest(
  body: unknown
):
  | { ok: true; kind: SourceKind; sourceId: string }
  | { ok: false; error: string } {
  if (typeof body !== "object" || body === null) {
    return { ok: false, error: "body must be a JSON object" };
  }
  const b = body as Record<string, unknown>;
  const kind = b.source_kind;
  if (kind !== "case_document" && kind !== "vault_document") {
    return {
      ok: false,
      error: "source_kind must be 'case_document' or 'vault_document'",
    };
  }
  if (!isUuid(b.source_id)) {
    return { ok: false, error: "source_id must be a UUID" };
  }
  return { ok: true, kind, sourceId: b.source_id };
}

/**
 * Core indexing routine. `callerId` is the authenticated user's id — used to
 * verify ownership before doing any embedding work.
 */
export async function indexDocument(
  body: unknown,
  callerId: string,
  deps: IndexerDeps
): Promise<IndexResult> {
  const parsed = parseIndexRequest(body);
  if (!parsed.ok) {
    return { status: 400, body: { error: parsed.error } };
  }

  const src = await deps.loadSource(parsed.kind, parsed.sourceId, callerId);
  if (src === null) {
    // 404 (not 403) so we don't leak existence of other tenants' docs.
    return { status: 404, body: { error: "document not found" } };
  }

  const text = (src.text ?? "").slice(0, MAX_DOC_CHARS);
  const chunks = chunkDocument(text);

  if (chunks.length === 0) {
    // Nothing to index (e.g. an image-only doc whose text wasn't extracted).
    // Clear any stale chunks so search never returns ghosts.
    await deps.deleteChunks(parsed.kind, parsed.sourceId);
    return {
      status: 200,
      body: {
        indexed: 0,
        reason: "no extractable text",
        source_kind: parsed.kind,
        source_id: parsed.sourceId,
      },
    };
  }

  // Embed in batches to respect OpenAI input caps and keep memory bounded.
  let totalTokens = 0;
  const rows: ChunkInsert[] = [];
  for (let i = 0; i < chunks.length; i += EMBED_BATCH_SIZE) {
    const batch = chunks.slice(i, i + EMBED_BATCH_SIZE);
    const { embeddings, tokens } = await deps.embed(batch.map((c) => c.text));
    totalTokens += tokens;
    for (let j = 0; j < batch.length; j++) {
      const c = batch[j];
      rows.push({
        user_id: src.userId,
        org_id: src.orgId,
        source_kind: parsed.kind,
        source_id: parsed.sourceId,
        doc_title: src.title,
        chunk_index: c.chunkIndex,
        text: c.text,
        char_start: c.charStart,
        char_end: c.charEnd,
        embedding: embeddings[j],
      });
    }
  }

  // Delete-then-insert = idempotent re-index.
  await deps.deleteChunks(parsed.kind, parsed.sourceId);
  await deps.insertChunks(rows);

  return {
    status: 200,
    body: {
      indexed: rows.length,
      tokens: totalTokens,
      cost_usd: Number(embedCostUsd(totalTokens).toFixed(6)),
      source_kind: parsed.kind,
      source_id: parsed.sourceId,
    },
  };
}
