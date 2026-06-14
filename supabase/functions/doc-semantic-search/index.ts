// doc-semantic-search Edge Function
// -----------------------------------------------------------------------------
// Feature #4 — semantic search over the caller's OWN documents.
//
// Wire format:
//   POST /functions/v1/doc-semantic-search
//   Authorization: Bearer <user JWT>
//   {
//     "query":        "where was the deposit mentioned",   // required, >=2 chars
//     "match_count":  8,                                    // optional 1..25
//     "threshold":    0.2,                                  // optional 0..0.99
//     "org_id":       "<uuid>",                             // optional scope
//     "source_kind":  "case_document"|"vault_document",     // optional scope
//     "source_id":    "<uuid>"                              // optional scope
//   }
//
//   200 { query, count, results: [{ chunk_id, source_kind, source_id,
//         doc_title, chunk_index, snippet, similarity, highlight }] }
//   400 bad body | 401 unauthorized | 429 rate limited | 502 embed failed
//
// RLS isolation: the match RPC is invoked with a USER-SCOPED client (the
// caller's JWT forwarded as the client Authorization header), so auth.uid()
// inside match_user_doc_chunks resolves to the caller. The RPC re-applies the
// owner/org filter, so results can ONLY ever contain the caller's own (or
// their org's) chunks. The shared law corpus lives in a different table and is
// never touched here.
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
import { type MatchRow, type SearchDeps, searchDocuments } from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

/** Build deps for one request. The match RPC runs under the caller's JWT so
 *  RLS / auth.uid() applies. */
function depsForRequest(authHeader: string): SearchDeps {
  // User-scoped client: forwards the caller's JWT, so auth.uid() inside the
  // SECURITY DEFINER RPC is the caller. anon key + RLS is the right baseline.
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  return {
    embed(texts: string[]) {
      return embedTexts(texts, OPENAI_API_KEY);
    },
    async match(args): Promise<MatchRow[]> {
      const { data, error } = await userClient.rpc("match_user_doc_chunks", {
        query_embedding: args.embedding,
        match_count: args.matchCount,
        match_threshold: args.threshold,
        p_org_id: args.orgId,
        p_source_kind: args.sourceKind,
        p_source_id: args.sourceId,
      });
      if (error) throw new Error(`match_user_doc_chunks: ${error.message}`);
      return (data ?? []) as MatchRow[];
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

  // Search embeds one short query per call; 60/min/user is plenty.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "doc-semantic-search",
    maxPerMinute: 60,
  });
  if (gate.kind === "deny") return gate.response;

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) return jsonError("Unauthorized", 401);

  let body: unknown;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Request body must be valid JSON", 400);
  }

  try {
    const result = await searchDocuments(body, depsForRequest(authHeader));
    if (result.status === 200) return jsonOk(result.body, 200);
    return jsonError(
      String(result.body.error ?? "error"),
      result.status,
      result.body
    );
  } catch (e) {
    console.error(`[doc-semantic-search] ${String(e)}`);
    return jsonError("Search failed", 500);
  }
});
