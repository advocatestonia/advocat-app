// template-fill/index.ts — HTTP shim for the Legal Template Library.
// -----------------------------------------------------------------------------
// Feature #5. Given a template id + (optional) case id + user-supplied missing
// fields, it loads the template body and the signed-in user's profile/case row,
// substitutes the {{placeholder}} tokens (see handler.ts), and returns the
// filled markdown. The CLIENT then saves the result as a normal `user_drafts`
// row via the existing DraftService, so the PDF/DOCX export path is unchanged.
//
// Endpoint:
//   POST /functions/v1/template-fill
//   Body: { template_id, case_id?, fields? }
//     template_id : uuid OR slug of a legal_templates row
//     case_id     : optional uuid; when present, auto-fills case_number etc.
//     fields      : optional { token: value } map for required fields
//   Auth: Bearer <user_jwt> required (no anonymous traffic).
//   Returns: { filled, title, jurisdiction, locale, slug,
//              tokens, resolved, unresolved, required_fields }
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  buildAutoValues,
  type CaseRow,
  fillTemplate,
  type ProfileRow,
  type TemplateRow,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/** Cheap uuid v4 shape check so we can pick slug-vs-id lookup. */
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Auth + a modest per-user rate limit. Filling is cheap (no LLM call) but we
  // still don't want a script hammering the DB.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "template-fill",
    maxPerMinute: 60,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;

  let body: {
    template_id?: string;
    case_id?: string;
    fields?: Record<string, unknown>;
  };
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Request body must be valid JSON", 400);
  }

  const templateId = (body.template_id ?? "").trim();
  if (!templateId) {
    return jsonError("template_id is required", 400);
  }

  // ── Load the template (by uuid or slug). ──────────────────────────────────
  const column = UUID_RE.test(templateId) ? "id" : "slug";
  const { data: tplData, error: tplErr } = await supabaseAdmin
    .from("legal_templates")
    .select(
      "id, slug, title, jurisdiction, locale, body_markdown, required_fields"
    )
    .eq(column, templateId)
    .maybeSingle();
  if (tplErr) {
    console.error("template-fill template lookup error", tplErr);
    return jsonError("Template lookup failed", 500);
  }
  if (!tplData) {
    return jsonError("Template not found", 404);
  }
  const template = tplData as TemplateRow;

  // ── Load the user's profile (auto values). ────────────────────────────────
  const { data: profData } = await supabaseAdmin
    .from("profiles")
    .select("full_name, email")
    .eq("id", userId)
    .maybeSingle();
  const profile = (profData ?? null) as ProfileRow | null;

  // ── Optionally load a case the user owns (auto case_number / migri_ref). ──
  let caseRow: CaseRow | null = null;
  const caseId = (body.case_id ?? "").trim();
  if (caseId) {
    if (!UUID_RE.test(caseId)) {
      return jsonError("case_id must be a uuid", 400);
    }
    const { data: caseData, error: caseErr } = await supabaseAdmin
      .from("cases")
      .select(
        "title, court_case_number, migri_reference_number, nationality, user_id"
      )
      .eq("id", caseId)
      .eq("user_id", userId) // ownership check — fail closed via RLS-style filter
      .maybeSingle();
    if (caseErr) {
      console.error("template-fill case lookup error", caseErr);
      return jsonError("Case lookup failed", 500);
    }
    if (caseData) {
      caseRow = caseData as CaseRow;
    }
    // A missing/foreign case is silently ignored (auto fields stay blank) —
    // we never leak whether the id exists.
  }

  // ── Build the auto bag + sanitise user fields. ────────────────────────────
  const todayIso = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const auto = buildAutoValues({ profile, caseRow, todayIso });

  const fields: Record<string, string> = {};
  const rawFields = body.fields ?? {};
  for (const [k, v] of Object.entries(rawFields)) {
    // Only accept simple scalar values; coerce to string, cap length to keep
    // documents bounded.
    if (v == null) continue;
    if (
      typeof v === "string" ||
      typeof v === "number" ||
      typeof v === "boolean"
    ) {
      fields[k] = String(v).slice(0, 5000);
    }
  }

  const result = fillTemplate({
    body: template.body_markdown,
    auto,
    fields,
  });

  return jsonOk({
    filled: result.filled,
    title: template.title,
    slug: template.slug,
    jurisdiction: template.jurisdiction,
    locale: template.locale,
    tokens: result.tokens,
    resolved: result.resolved,
    unresolved: result.unresolved,
    required_fields: template.required_fields ?? [],
  });
});
