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
    return jsonOk(result.body, result.status);
  }
  return jsonError(result.body.error, result.status);
});
