// draft-export-docx/index.ts — HTTP shim for Markdown → DOCX export.
// -----------------------------------------------------------------------------
// Pkg 7 Drafting Studio MVP — server-side DOCX export so the Flutter web
// bundle stays small. Returns base64 bytes; the client decodes and triggers
// a download via Blob.
//
// POST /functions/v1/draft-export-docx
// Body: { content_markdown, title? }
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { runDocxExport } from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // 60/min — DOCX export is CPU-light but should not be hammered.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "draft-export-docx",
    maxPerMinute: 60,
  });
  if (gate.kind === "deny") return gate.response;

  let body: unknown;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Request body must be valid JSON", 400);
  }

  const result = runDocxExport(body);
  if (result.kind === "success") {
    // ── B2B signal: docx_export (2026-05-26) ────────────────────────────
    // Fire-and-forget AFTER a successful export. Idempotent on the 1-hour
    // window inside the b2b-signal edge fn / record_b2b_signal RPC, but
    // we ALSO short-circuit here on missing service-role env to keep
    // local dev / tests insulated.
    const userId = gate.user.id;
    const isAnon = userId.startsWith("anon:");
    if (!isAnon && SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY) {
      // Background fire-and-forget — never await; never throw.
      (async () => {
        try {
          await fetch(`${SUPABASE_URL}/rest/v1/rpc/record_b2b_signal`, {
            method: "POST",
            headers: {
              "apikey": SUPABASE_SERVICE_ROLE_KEY,
              "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              p_user_id: userId,
              p_signal_type: "docx_export",
              p_score: 25,
              p_payload: {
                source: "draft-export-docx",
                byte_length: result.body.byte_length,
              },
            }),
          });
        } catch (e) {
          console.warn(
            `draft-export-docx: b2b signal failed: ${String(e).slice(0, 150)}`,
          );
        }
      })();
    }
    return jsonOk(result.body, result.status);
  }
  return jsonError(result.body.error, result.status);
});
