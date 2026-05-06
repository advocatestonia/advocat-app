// law-lookup Edge Function
// -----------------------------------------------------------------------------
// Phase 2 Pkg 1+2 — Exact-paragraph statute lookup. Thin wrapper around the
// `public.lookup_statute(p_act_slug, p_paragraph, p_jurisdiction)` RPC. Used
// by the `lookup_statute` Claude tool when the user names a specific § —
// embedding search is wasteful when the act+paragraph are already known.
//
// Wire format (locked by lib/services/law_lookup_client.dart):
//   POST /functions/v1/law-lookup
//   Bearer <SUPABASE_ANON_KEY | user JWT>
//   { "act":          string,                       -- e.g. "KarS", "HMS"
//     "paragraph":    string,                       -- e.g. "121", "40 lg 3"
//     "jurisdiction": "EE" | "FI" | "EU" }          -- default "EE"
//
//   200 OK
//   { "statute":
//        null
//        | {
//            "id": string,
//            "act_slug": string,
//            "act_name": string,
//            "paragraph": string,
//            "title": string|null,
//            "body": string,
//            "source_url": string|null,
//            "version_date": string|null,
//            "jurisdiction": string
//          }
//   }
//
// Graceful-degradation contract:
//   • Statute not in corpus / RLS blocks / RPC error → 200 + `{statute: null}`.
//     The tool layer treats null as "not in our bundled corpus" and asks the
//     model to fall back to web_search or admit ignorance — never 500.
//   • Real client errors (missing act/paragraph, unsupported jurisdiction)
//     return 4xx — those are misuse, not transient failures.
//
// Auth: anon Bearer is sufficient (corpus is public law text). Rate-limit
// matches the law-search anon-friendly pattern: 30/min auth, 30/min anon
// (lookup is cheap — no embedding, no Anthropic call — so we can be more
// generous than law-search's 10/min anon cap).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const SUPPORTED_JURISDICTIONS = new Set(["EE", "FI", "EU"]);
const DEFAULT_JURISDICTION = "EE";

const RATE_LIMIT_PER_MINUTE = 60;
const ANON_RATE_LIMIT_PER_MINUTE = 30;

// Hard size guards — protect against pathological payloads that bypass the
// client. A real act_slug is <= 16 chars; paragraph identifiers like
// "§ 40 lg 3" stay below 64.
const MAX_ACT_LEN = 64;
const MAX_PARAGRAPH_LEN = 128;

interface RequestBody {
  act?: unknown;
  paragraph?: unknown;
  jurisdiction?: unknown;
}

interface RpcStatute {
  id: string;
  act_slug: string;
  act_name: string;
  paragraph: string;
  title: string | null;
  body: string;
  source_url: string | null;
  version_date: string | null;
  jurisdiction: string;
}

function nullStatute(): Response {
  return new Response(
    JSON.stringify({ statute: null }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // ── 1. Auth + rate limit ────────────────────────────────────────────────
  const gate = await requireUserWithRateLimit(req, {
    bucket: "law-lookup",
    maxPerMinute: RATE_LIMIT_PER_MINUTE,
    anonymousPerMinute: ANON_RATE_LIMIT_PER_MINUTE,
  });
  if (gate.kind === "deny") return gate.response;

  // ── 2. Parse + validate body ────────────────────────────────────────────
  let body: RequestBody;
  try {
    body = await req.json() as RequestBody;
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  const act = typeof body.act === "string" ? body.act.trim() : "";
  if (!act) {
    return jsonError("Missing or empty 'act'", 400);
  }
  if (act.length > MAX_ACT_LEN) {
    return jsonError(`'act' too long (max ${MAX_ACT_LEN} chars)`, 400);
  }

  const paragraph = typeof body.paragraph === "string" ? body.paragraph.trim() : "";
  if (!paragraph) {
    return jsonError("Missing or empty 'paragraph'", 400);
  }
  if (paragraph.length > MAX_PARAGRAPH_LEN) {
    return jsonError(`'paragraph' too long (max ${MAX_PARAGRAPH_LEN} chars)`, 400);
  }

  let jurisdiction = DEFAULT_JURISDICTION;
  if (body.jurisdiction !== undefined && body.jurisdiction !== null) {
    if (typeof body.jurisdiction !== "string") {
      return jsonError("Invalid 'jurisdiction' (must be a string)", 400);
    }
    const candidate = body.jurisdiction.trim().toUpperCase();
    if (!SUPPORTED_JURISDICTIONS.has(candidate)) {
      return jsonError(
        `Invalid 'jurisdiction' (expected one of ${
          [...SUPPORTED_JURISDICTIONS].join(", ")
        })`,
        400,
      );
    }
    jurisdiction = candidate;
  }

  // ── 3. RPC call ──────────────────────────────────────────────────────────
  // Missing service-role config is a server-side bug, not a client error;
  // we degrade to {statute: null} so chat continues rather than 5xx.
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.warn("law-lookup: SUPABASE_URL / SERVICE_ROLE_KEY not configured");
    return nullStatute();
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await supabase.rpc("lookup_statute", {
      p_act_slug: act,
      p_paragraph: paragraph,
      p_jurisdiction: jurisdiction,
    });
    if (error) {
      // RPC missing or DB-level error — graceful null. Logged for ops.
      console.warn(`law-lookup: RPC error — ${error.message}`);
      return nullStatute();
    }

    const rows = Array.isArray(data) ? data as RpcStatute[] : [];
    if (rows.length === 0) {
      // Standard "not in corpus" path — partial unique index ensures at
      // most one match anyway, so [0] is the only meaningful row.
      return nullStatute();
    }

    const r = rows[0];
    const statute = {
      id: r.id,
      act_slug: r.act_slug,
      act_name: r.act_name,
      paragraph: r.paragraph,
      title: r.title ?? null,
      body: r.body,
      source_url: r.source_url ?? null,
      version_date: r.version_date ?? null,
      jurisdiction: r.jurisdiction,
    };

    return new Response(
      JSON.stringify({ statute }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.warn(`law-lookup: RPC threw — ${String(err)}`);
    return nullStatute();
  }
});
