// draft-export-pdf/index.ts — HTTP shim for Markdown → PDF export.
// -----------------------------------------------------------------------------
// Pkg 7 Drafting Studio MVP — Track 1A. Sibling of draft-export-docx: same
// auth, rate-limit, and B2B-signal scaffolding; the body is rendered by the
// existing Typst worker behind CONTRACT_PDF_WORKER_URL / CONTRACT_PDF_WORKER_SECRET
// (we reuse the same worker — it's already deployed and contract-review
// proves the wiring).
//
// POST /functions/v1/draft-export-pdf
// Body: { content_markdown, title? }
// Returns: { pdf_base64, filename, byte_length, mime }
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  type PdfWorkerCaller,
  runPdfExport,
  type TypstWorkerRequest,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";

// Reuse the contract-review Typst worker — same binary, same auth scheme.
// Falls back gracefully to 503 worker_not_configured when missing (local
// dev / smoke env).
const PDF_WORKER_URL = Deno.env.get("CONTRACT_PDF_WORKER_URL") ?? "";
const PDF_WORKER_SECRET = Deno.env.get("CONTRACT_PDF_WORKER_SECRET") ?? "";

function buildPdfWorkerCaller(): PdfWorkerCaller {
  if (!PDF_WORKER_URL || !PDF_WORKER_SECRET) return null;
  return async (payload: TypstWorkerRequest): Promise<Uint8Array> => {
    const res = await fetch(PDF_WORKER_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${PDF_WORKER_SECRET}`,
      },
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`pdf worker ${res.status}: ${err.slice(0, 200)}`);
    }
    const buf = await res.arrayBuffer();
    return new Uint8Array(buf);
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // 60/min — PDF export hits an external worker but stays light enough to
  // share the DOCX bucket cadence.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "draft-export-pdf",
    maxPerMinute: 60,
  });
  if (gate.kind === "deny") return gate.response;

  let body: unknown;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Request body must be valid JSON", 400);
  }

  const result = await runPdfExport({
    body,
    pdfWorker: buildPdfWorkerCaller(),
  });

  if (result.kind === "success") {
    // ── B2B signal: pdf_export (2026-05-27) ─────────────────────────────
    // Fire-and-forget AFTER a successful export. Mirrors the DOCX
    // signal — same score, same idempotency window inside the RPC.
    const userId = gate.user.id;
    const isAnon = userId.startsWith("anon:");
    if (!isAnon && SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY) {
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
              p_signal_type: "pdf_export",
              p_score: 25,
              p_payload: {
                source: "draft-export-pdf",
                byte_length: result.body.byte_length,
              },
            }),
          });
        } catch (e) {
          console.warn(
            `draft-export-pdf: b2b signal failed: ${String(e).slice(0, 150)}`,
          );
        }
      })();
    }
    return jsonOk(result.body, result.status);
  }
  return jsonError(result.body.error, result.status);
});
