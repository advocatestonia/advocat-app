// case-dossier-export/index.ts — HTTP shim for the Case Dossier Export.
// -----------------------------------------------------------------------------
// POST /functions/v1/case-dossier-export
// Body: { case_id: uuid, sections?: {timeline,deadlines,documents,aiSummary},
//         locale? }
// Returns: { download_url, storage_path, filename, document_id,
//            dossier_length }
//
// Auth: user JWT only (no anonymous). Rate limit: 4/min per user (each call
// fans out to pdf-generator, which is itself 2/min — so we stay conservative).
//
// IO wiring:
//   * fetchCaseData — reads user_cases / case_timeline_events / case_deadlines /
//     case_documents under the SERVICE-ROLE key but EVERY query is scoped to
//     (case_id, user_id), so a forged case_id returns no rows (header=null →
//     404). This mirrors pdf-generator.verifyCaseOwnership: ownership is
//     resolved authoritatively against user_cases.user_id == the JWT user id.
//   * callPdfGenerator — POSTs the assembled markdown to the existing
//     pdf-generator function, forwarding the caller's JWT so the downstream
//     ownership re-check + RLS + storage + case_documents insert all run under
//     the same identity. We DO NOT duplicate the HTML template or storage code.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  type CaseDossierData,
  type DeadlineRow,
  type DocumentRow,
  type PdfGeneratorResponse,
  runDossierExport,
  type TimelineEventRow,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// ── Limits — keep the aggregation bounded so one case can't blow the
//    markdown cap or the request time. ──────────────────────────────────────
const MAX_TIMELINE = 300;
const MAX_DEADLINES = 200;
const MAX_DOCUMENTS = 300;

// ─── REST helpers (service-role, but every query scoped to user_id) ──────────

const REST_HEADERS = {
  Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
  apikey: SUPABASE_SERVICE_ROLE_KEY,
  Accept: "application/json",
};

function toStringArray(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v
    .map((x) => (typeof x === "string" ? x : x == null ? "" : String(x)))
    .filter((s) => s.trim().length > 0);
}

async function getJson<T>(url: string): Promise<T> {
  const res = await fetch(url, { method: "GET", headers: REST_HEADERS });
  if (!res.ok) {
    const snippet = (await res.text()).slice(0, 200);
    throw new Error(`rest ${res.status}: ${snippet}`);
  }
  return (await res.json()) as T;
}

/** Fetch the case header — scoped to (id, user_id). Returns null when the
 *  case is not the caller's (or doesn't exist). */
async function fetchHeader(caseId: string, userId: string) {
  const cols =
    "id,title,jurisdiction,case_type,status,case_numbers,parties,authorities,summary,language,created_at";
  const url =
    `${SUPABASE_URL}/rest/v1/user_cases?id=eq.${caseId}` +
    `&user_id=eq.${userId}&select=${cols}&limit=1`;
  const rows = await getJson<Array<Record<string, unknown>>>(url);
  const r = rows[0];
  if (!r) return null;
  return {
    id: String(r.id),
    title: typeof r.title === "string" ? r.title : "(untitled)",
    jurisdiction: typeof r.jurisdiction === "string" ? r.jurisdiction : null,
    case_type: typeof r.case_type === "string" ? r.case_type : null,
    status: typeof r.status === "string" ? r.status : null,
    case_numbers: toStringArray(r.case_numbers),
    parties: toStringArray(r.parties),
    authorities: toStringArray(r.authorities),
    summary: typeof r.summary === "string" ? r.summary : null,
    language: typeof r.language === "string" ? r.language : null,
    created_at: typeof r.created_at === "string" ? r.created_at : null,
  };
}

async function fetchTimeline(
  caseId: string,
  userId: string
): Promise<TimelineEventRow[]> {
  const url =
    `${SUPABASE_URL}/rest/v1/case_timeline_events?case_id=eq.${caseId}` +
    `&user_id=eq.${userId}&select=event_type,title,summary,occurred_at` +
    `&order=occurred_at.asc&limit=${MAX_TIMELINE}`;
  const rows = await getJson<Array<Record<string, unknown>>>(url);
  return rows.map((r) => ({
    event_type: typeof r.event_type === "string" ? r.event_type : "",
    title: typeof r.title === "string" ? r.title : "",
    summary: typeof r.summary === "string" ? r.summary : null,
    occurred_at: typeof r.occurred_at === "string" ? r.occurred_at : null,
  }));
}

async function fetchDeadlines(
  caseId: string,
  userId: string
): Promise<DeadlineRow[]> {
  const cols =
    "title,description,statute_basis,deadline_at,status,priority,holiday_shifted";
  const url =
    `${SUPABASE_URL}/rest/v1/case_deadlines?case_id=eq.${caseId}` +
    `&user_id=eq.${userId}&select=${cols}` +
    `&order=deadline_at.asc&limit=${MAX_DEADLINES}`;
  const rows = await getJson<Array<Record<string, unknown>>>(url);
  return rows.map((r) => ({
    title: typeof r.title === "string" ? r.title : "",
    description: typeof r.description === "string" ? r.description : null,
    statute_basis: typeof r.statute_basis === "string" ? r.statute_basis : null,
    deadline_at: typeof r.deadline_at === "string" ? r.deadline_at : null,
    status: typeof r.status === "string" ? r.status : null,
    priority: typeof r.priority === "string" ? r.priority : null,
    holiday_shifted: r.holiday_shifted === true,
  }));
}

async function fetchDocuments(
  caseId: string,
  userId: string
): Promise<DocumentRow[]> {
  const url =
    `${SUPABASE_URL}/rest/v1/case_documents?case_id=eq.${caseId}` +
    `&user_id=eq.${userId}&select=filename,doc_type,doc_date,parsed_summary` +
    `&order=uploaded_at.asc&limit=${MAX_DOCUMENTS}`;
  const rows = await getJson<Array<Record<string, unknown>>>(url);
  return rows.map((r) => ({
    filename: typeof r.filename === "string" ? r.filename : "(file)",
    doc_type: typeof r.doc_type === "string" ? r.doc_type : null,
    doc_date: typeof r.doc_date === "string" ? r.doc_date : null,
    parsed_summary:
      typeof r.parsed_summary === "string" ? r.parsed_summary : null,
  }));
}

async function fetchCaseData(
  caseId: string,
  userId: string
): Promise<CaseDossierData> {
  const header = await fetchHeader(caseId, userId);
  if (!header) {
    return { header: null, timeline: [], deadlines: [], documents: [] };
  }
  // Header confirmed owned — fan out the child queries in parallel.
  const [timeline, deadlines, documents] = await Promise.all([
    fetchTimeline(caseId, userId),
    fetchDeadlines(caseId, userId),
    fetchDocuments(caseId, userId),
  ]);
  return { header, timeline, deadlines, documents };
}

/** Build a pdf-generator caller that forwards the user's JWT. The downstream
 *  function re-verifies case ownership and performs all storage / DB writes. */
function buildPdfGeneratorCaller(userJwt: string) {
  return async (payload: {
    title: string;
    body_markdown: string;
    doc_type: string;
    locale: string;
    case_id: string;
  }) => {
    const url = `${SUPABASE_URL}/functions/v1/pdf-generator`;
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${userJwt}`,
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });
    let parsed: unknown = null;
    try {
      parsed = await res.json();
    } catch (_e) {
      parsed = null;
    }
    if (res.ok && parsed && typeof parsed === "object") {
      const p = parsed as Record<string, unknown>;
      const body: PdfGeneratorResponse = {
        download_url: typeof p.download_url === "string" ? p.download_url : "",
        storage_path: typeof p.storage_path === "string" ? p.storage_path : "",
        filename: typeof p.filename === "string" ? p.filename : "dossier.html",
        document_id: typeof p.document_id === "string" ? p.document_id : null,
      };
      if (!body.download_url) {
        return {
          ok: false as const,
          status: 502,
          error: "pdf-generator returned no download_url",
        };
      }
      return { ok: true as const, body };
    }
    const errMsg =
      parsed &&
      typeof parsed === "object" &&
      typeof (parsed as Record<string, unknown>).error === "string"
        ? (parsed as Record<string, string>).error
        : `status ${res.status}`;
    return { ok: false as const, status: res.status, error: errMsg };
  };
}

// ─── HTTP entry point ────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // 4/min — each call fans out to pdf-generator (2/min). Conservative.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "case-dossier-export",
    maxPerMinute: 4,
  });
  if (gate.kind === "deny") return gate.response;

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonError("server_not_configured", 503);
  }

  // Forward the caller's JWT to pdf-generator so the downstream ownership
  // re-check + RLS run under the same identity.
  const authHeader = req.headers.get("Authorization") ?? "";
  const userJwt = authHeader.replace("Bearer ", "");

  let body: unknown;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Request body must be valid JSON", 400);
  }

  const result = await runDossierExport({
    body,
    userId: gate.user.id,
    fetchCaseData,
    callPdfGenerator: buildPdfGeneratorCaller(userJwt),
  });

  if (result.kind === "success") {
    // ── B2B signal: dossier_export (передаточный пакет = high B2B intent).
    //    Fire-and-forget AFTER success; mirrors draft-export-pdf's signal.
    const userId = gate.user.id;
    if (!userId.startsWith("anon:")) {
      (async () => {
        try {
          await fetch(`${SUPABASE_URL}/rest/v1/rpc/record_b2b_signal`, {
            method: "POST",
            headers: {
              apikey: SUPABASE_SERVICE_ROLE_KEY,
              Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              p_user_id: userId,
              p_signal_type: "pdf_export",
              p_score: 30,
              p_payload: {
                source: "case-dossier-export",
                dossier_length: result.body.dossier_length,
              },
            }),
          });
        } catch (e) {
          console.warn(
            `case-dossier-export: b2b signal failed: ${String(e).slice(0, 150)}`
          );
        }
      })();
    }
    return jsonOk(result.body, result.status);
  }
  return jsonError(result.body.error, result.status);
});
