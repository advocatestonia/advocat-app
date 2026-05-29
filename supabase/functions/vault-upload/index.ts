// vault-upload/index.ts — HTTP shim for Vault encryption hand-off.
// -----------------------------------------------------------------------------
// POST /functions/v1/vault-upload
//   Body: { file_name, storage_path, mime_type, file_size_bytes?, tag_id?, case_id? }
//   Returns: { document_id, encrypted: true }
//
// GET  /functions/v1/vault-upload?tag_id=<uuid>
//   Returns: { documents: [...] }
//
// Auth: JWT required (no anonymous). Rate-limit: 30/min POST, 60/min GET.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { runVaultList, runVaultUpload, type SupabaseLike } from "./handler.ts";
import { withSentry } from "../_shared/sentry.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

// CORS for GET as well as POST (the shared header only allows POST,OPTIONS).
const vaultCors: Record<string, string> = {
  ...corsHeaders,
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function vaultJsonError(msg: string, status: number, extra: Record<string, unknown> = {}) {
  return new Response(JSON.stringify({ error: msg, ...extra }), {
    status,
    headers: { ...vaultCors, "Content-Type": "application/json" },
  });
}
function vaultJsonOk(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...vaultCors, "Content-Type": "application/json" },
  });
}

serve(withSentry("vault-upload", async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: vaultCors });
  }
  if (req.method !== "POST" && req.method !== "GET") {
    return jsonError("Method not allowed", 405);
  }

  const isUpload = req.method === "POST";

  const gate = await requireUserWithRateLimit(req, {
    bucket: isUpload ? "vault-upload" : "vault-list",
    maxPerMinute: isUpload ? 30 : 60,
  });
  if (gate.kind === "deny") return gate.response;

  // Anonymous users can't reach the vault.
  if (gate.user.id.startsWith("anon:")) {
    return vaultJsonError("Vault requires authenticated session", 401);
  }

  const userId = gate.user.id;

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return vaultJsonError("Vault backend not configured", 503);
  }

  // SECURITY/CORRECTNESS: forward the caller's JWT so `auth.uid()` resolves
  // inside the SECURITY DEFINER RPCs and RLS policies, instead of a bare
  // service-role client (auth.uid() = NULL).
  //   * The list path calls vault_search_documents, which scopes solely by
  //     `auth.uid()` (it takes NO user param). Under service-role that is
  //     NULL → the fn early-returns empty → the Vault list was DEAD in prod.
  //   * The upload path's documents INSERT is gated by RLS
  //     `WITH CHECK (user_id = auth.uid())`, and vault_encrypt_text's owner
  //     guard requires `auth.uid() = p_user_id`. A JWT client (auth.uid() ==
  //     userId) satisfies both, and now RLS is enforced on the tag insert
  //     too instead of bypassed.
  const authHeader = req.headers.get("Authorization") ?? "";
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  }) as unknown as SupabaseLike;

  if (isUpload) {
    let body: unknown;
    try {
      body = await req.json();
    } catch {
      return vaultJsonError("Body must be valid JSON", 400);
    }
    const result = await runVaultUpload(body, { supabase: client, userId });
    return result.kind === "success"
      ? vaultJsonOk(result.body, result.status)
      : vaultJsonError(result.body.error, result.status);
  }

  // GET → list
  const url = new URL(req.url);
  const tagId = url.searchParams.get("tag_id") ?? undefined;
  const result = await runVaultList({ tagId }, { supabase: client, userId });
  return result.kind === "success"
    ? vaultJsonOk(result.body, result.status)
    : vaultJsonError(result.body.error, result.status);
}));

// Avoid unused-import flagging when tests import handler directly:
export { runVaultList, runVaultUpload } from "./handler.ts";
export { jsonOk, jsonError };
