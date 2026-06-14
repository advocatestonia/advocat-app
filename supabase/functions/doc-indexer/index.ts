// doc-indexer Edge Function
// -----------------------------------------------------------------------------
// Feature #4 — index ONE of the caller's documents for semantic search.
//
// Wire format:
//   POST /functions/v1/doc-indexer
//   Authorization: Bearer <user JWT>
//   { "source_kind": "case_document" | "vault_document", "source_id": "<uuid>" }
//
//   200 { indexed, tokens, cost_usd, source_kind, source_id }
//   400 bad body | 401 unauthorized | 404 not found/owned | 429 rate limited
//
// Indexing is ON DEMAND (one doc per call) to keep embedding spend bounded.
// Re-indexing the same document is idempotent (delete-then-insert by source).
//
// Auth: user JWT via requireUserWithRateLimit. The source row is then loaded
// with the SERVICE-ROLE client BUT filtered on user_id = caller, so a caller
// can only ever index a document they own. Chunks are written with the source
// row's user_id/org_id so RLS on user_doc_chunks lines up with the source's
// own access model.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { embedTexts } from "../_shared/doc_chunker.ts";
import {
  type ChunkInsert,
  indexDocument,
  type IndexerDeps,
  type SourceDoc,
  type SourceKind,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/** Build the live data layer. */
function realDeps(): IndexerDeps {
  return {
    async loadSource(
      kind: SourceKind,
      sourceId: string,
      callerId: string
    ): Promise<SourceDoc | null> {
      if (kind === "case_document") {
        // case_documents has NO org_id column → always personal.
        const { data, error } = await admin
          .from("case_documents")
          .select("id, user_id, filename, parsed_text")
          .eq("id", sourceId)
          .eq("user_id", callerId)
          .maybeSingle();
        if (error || !data) return null;
        return {
          sourceId: data.id as string,
          userId: data.user_id as string,
          orgId: null,
          title: (data.filename as string) ?? null,
          text: (data.parsed_text as string) ?? "",
        };
      }
      // vault_document → public.documents (has org_id, ocr_text).
      const { data, error } = await admin
        .from("documents")
        .select("id, user_id, org_id, file_name, ocr_text")
        .eq("id", sourceId)
        .eq("user_id", callerId)
        .maybeSingle();
      if (error || !data) return null;
      return {
        sourceId: data.id as string,
        userId: data.user_id as string,
        orgId: (data.org_id as string | null) ?? null,
        title: (data.file_name as string) ?? null,
        text: (data.ocr_text as string) ?? "",
      };
    },

    async deleteChunks(kind: SourceKind, sourceId: string): Promise<void> {
      const { error } = await admin
        .from("user_doc_chunks")
        .delete()
        .eq("source_kind", kind)
        .eq("source_id", sourceId);
      if (error) throw new Error(`deleteChunks: ${error.message}`);
    },

    async insertChunks(rows: ChunkInsert[]): Promise<void> {
      if (rows.length === 0) return;
      const { error } = await admin.from("user_doc_chunks").insert(rows);
      if (error) throw new Error(`insertChunks: ${error.message}`);
    },

    embed(texts: string[]) {
      return embedTexts(texts, OPENAI_API_KEY);
    },
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Indexing burns OpenAI tokens; cap at 20/min/user.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "doc-indexer",
    maxPerMinute: 20,
  });
  if (gate.kind === "deny") return gate.response;

  let body: unknown;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Request body must be valid JSON", 400);
  }

  try {
    const result = await indexDocument(body, gate.user.id, realDeps());
    if (result.status === 200) return jsonOk(result.body, 200);
    return jsonError(
      String(result.body.error ?? "error"),
      result.status,
      result.body
    );
  } catch (e) {
    console.error(`[doc-indexer] ${String(e)}`);
    return jsonError("Indexing failed", 500);
  }
});
