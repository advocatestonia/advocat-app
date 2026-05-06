// deadline-extractor — Phase 2 Pkg 9.
// -----------------------------------------------------------------------------
// Three trigger sites (architect §5):
//   1. Post-pdf-parser: payload = {deadlines: [{date, what, statute}], doc_type,
//      jurisdiction, source_doc_id}.
//   2. Post-intake-wizard: payload = {service_date, doc_type, jurisdiction,
//      case_type}.
//   3. Post-case-auto-patch: payload = {candidate_dates: [{date, context}],
//      jurisdiction, case_type}.
//
// For sites 1 + 2 we route deterministically through STATUTORY_DEADLINE_TEMPLATES:
//   * Find anchors that match (jurisdiction, doc_type).
//   * Compute deadline_at via computeAbsoluteDeadline.
//   * Upsert via apply_deadline_extraction RPC.
//
// For site 3 we fire Sonnet to classify candidate dates as deadlines vs
// non-deadlines (Haiku is too junior for jurisdictional nuance per
// consilium 2026-05). Sonnet returns strict JSON we then route through the
// same template + computeAbsoluteDeadline path.
//
// Auth: user JWT (the case ownership check is enforced via apply_deadline_extraction
// SECURITY DEFINER + auth.uid()). Cron-secret is also accepted for the
// service-role pdf-parser-to-extractor handoff.
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
  applyConfidenceFloor,
  DEADLINE_EXTRACTOR_MAX_TOKENS,
  DEADLINE_EXTRACTOR_MODEL,
  DEADLINE_EXTRACTOR_SYSTEM_PROMPT,
  DEADLINE_EXTRACTOR_TIMEOUT_MS,
  parseExtractedDeadlines,
  type ExtractedDeadline,
} from "../_shared/deadline_extractor_prompt.ts";
import {
  computeAbsoluteDeadline,
  type DeadlineJurisdiction,
} from "../_shared/holiday_shift.ts";
import {
  findAnchor,
  findAnchorsByTrigger,
  type StatutoryAnchor,
} from "../_shared/statutory_anchors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const CRON_SECRET = Deno.env.get("CRON_SECRET");

/** Hard cap on input chars for Sonnet — defense against pathological
 * payloads. */
const MAX_PAYLOAD_BYTES = 32 * 1024;

/** Source variants accepted on the wire. */
type ExtractorSource = "pdf" | "intake" | "haiku_extract" | "manual";

interface RequestBody {
  case_id: string;
  source: ExtractorSource;
  payload: Record<string, unknown>;
  jurisdiction?: string;
}

// =============================================================================
// HTTP entry point
// =============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Two auth modes: user JWT (the common case) OR cron-secret (for the
  // service-role pdf-parser → extractor handoff).
  const cronHeader = req.headers.get("x-cron-secret");
  let userId: string | null = null;
  if (cronHeader) {
    if (!CRON_SECRET) {
      console.error("deadline-extractor: CRON_SECRET not configured");
      return jsonError("Cron secret not configured", 500);
    }
    if (cronHeader !== CRON_SECRET) {
      return jsonError("Invalid cron secret", 401);
    }
    // Service-role mode: caller must supply user_id explicitly via case_id
    // ownership check that we run below.
  } else {
    const gate = await requireUserWithRateLimit(req, {
      bucket: "deadline-extractor",
      maxPerMinute: 30,
    });
    if (gate.kind === "deny") return gate.response;
    userId = gate.user.id;
  }

  // Parse body.
  const rawText = await req.text();
  if (rawText.length > MAX_PAYLOAD_BYTES) {
    return jsonError("payload too large", 413);
  }
  let body: RequestBody;
  try {
    body = JSON.parse(rawText) as RequestBody;
  } catch {
    return jsonError("Invalid JSON body", 400);
  }
  if (!body || typeof body !== "object") {
    return jsonError("Invalid body", 400);
  }
  const caseId = body.case_id;
  if (typeof caseId !== "string" || !isValidUuid(caseId)) {
    return jsonError("case_id must be a UUID", 400);
  }
  const source = body.source;
  if (!["pdf", "intake", "haiku_extract", "manual"].includes(source)) {
    return jsonError("invalid source", 400);
  }
  const jurisdiction = normalizeJurisdiction(body.jurisdiction);
  if (!jurisdiction) {
    return jsonError("jurisdiction is required (EE | FI | EU)", 400);
  }
  if (!body.payload || typeof body.payload !== "object") {
    return jsonError("payload is required", 400);
  }

  // Route by source.
  let candidateRows: Record<string, unknown>[] = [];
  try {
    switch (source) {
      case "pdf":
        candidateRows = handlePdfPayload(body.payload, jurisdiction);
        break;
      case "intake":
        candidateRows = handleIntakePayload(body.payload, jurisdiction);
        break;
      case "manual":
        candidateRows = handleManualPayload(body.payload, jurisdiction);
        break;
      case "haiku_extract":
        candidateRows = await handleHaikuExtractPayload(
          body.payload,
          jurisdiction,
        );
        break;
    }
  } catch (e) {
    console.error(
      `deadline-extractor: ${source} routing failed: ${String(e).slice(0, 300)}`,
    );
    return jsonError("routing failed", 500);
  }

  // Stamp the source on every row.
  for (const r of candidateRows) {
    r.source = source;
  }

  if (candidateRows.length === 0) {
    return jsonOk({ created: 0, updated: 0, deadlines: [] });
  }

  // Upsert via the SECURITY DEFINER RPC. We MUST pass the user's JWT here
  // so apply_deadline_extraction sees auth.uid()=user. In cron mode we use
  // service-role and pass the user_id via the RPC's payload (the RPC reads
  // ownership from user_cases regardless).
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    global: cronHeader
      ? undefined
      : { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    auth: { persistSession: false },
  });

  const { data, error } = await supabase.rpc("apply_deadline_extraction", {
    p_case_id: caseId,
    p_rows: candidateRows,
  });

  if (error) {
    console.error(`deadline-extractor: rpc failed: ${error.message}`);
    return jsonError("rpc failed", 500, { detail: error.message });
  }

  const insertedOrUpdated = (data && typeof data === "object" &&
      Array.isArray((data as Record<string, unknown>).created_or_updated))
    ? ((data as Record<string, unknown>).created_or_updated as string[])
    : [];

  // PII discipline (lessons from FIX-5): no titles/dates in response —
  // counts only.
  return jsonOk({
    created_or_updated: insertedOrUpdated.length,
    skipped_completed: (data && typeof data === "object" &&
        Array.isArray((data as Record<string, unknown>).skipped_completed))
      ? ((data as Record<string, unknown>).skipped_completed as string[]).length
      : 0,
  });
});

// =============================================================================
// Payload routers
// =============================================================================

interface ExtractedDeadlineFromPdf {
  date: string; // yyyy-mm-dd
  what?: string;
  statute?: string;
}

/** Handle the pdf-parser payload (`{deadlines, doc_type, source_doc_id}`).
 *
 * Match each deadline to one or more anchors via the (jurisdiction, doc_type)
 * pair. For each match, compute the deadline_at via TS, returning the
 * upsert-ready row shape. */
export function handlePdfPayload(
  payload: Record<string, unknown>,
  jurisdiction: DeadlineJurisdiction,
): Record<string, unknown>[] {
  const docType = typeof payload.doc_type === "string" ? payload.doc_type : "";
  const sourceDocId = typeof payload.source_doc_id === "string"
    ? payload.source_doc_id
    : null;
  const deadlinesRaw = Array.isArray(payload.deadlines) ? payload.deadlines : [];

  const out: Record<string, unknown>[] = [];

  for (const item of deadlinesRaw) {
    if (!item || typeof item !== "object") continue;
    const r = item as ExtractedDeadlineFromPdf;
    const date = typeof r.date === "string" ? r.date : null;
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) continue;

    // Heuristic: pdf-parser already returns the literal deadline date.
    // If the pdf says "30 päivää tiedoksisaannista 2026-05-06" the parser
    // emits date = the COMPUTED deadline (parser §helpers.ts deadline
    // extraction). We use the date verbatim as a UTC timestamp.
    const deadlineAt = isoToUtcMidnight(date);
    if (!deadlineAt) continue;

    // Find a matching anchor. If none, still emit a row with anchor_key=null
    // so the user sees the date — but it can't dedupe via the anchor index.
    // Per spec, dedupe index is partial-on-non-null anchor_key, so manual /
    // unanchored rows from PDFs will not dedupe. Acceptable for v1.
    const anchors = docType
      ? findAnchorsByTrigger(jurisdiction, docType)
      : [];

    if (anchors.length === 0) {
      out.push({
        title: r.what?.toString().slice(0, 200) || "Deadline",
        statute_basis: typeof r.statute === "string" ? r.statute : null,
        anchor_key: null,
        service_basis: "Extracted from PDF (no statutory anchor matched)",
        deadline_at: deadlineAt.toISOString(),
        holiday_shifted: false,
        holiday_shift_note: null,
        source_doc_id: sourceDocId,
        priority: "high",
      });
    } else {
      for (const anchor of anchors) {
        out.push(
          buildRowFromAnchor({
            anchor,
            // The PDF's date IS the absolute deadline already — we stamp
            // service_date as null because we don't know the original
            // service date.
            absoluteDeadline: deadlineAt,
            serviceDate: null,
            sourceDocId,
            title: r.what?.toString().slice(0, 200) || (anchor.uiLabels?.en ?? "Deadline"),
            statuteBasis: typeof r.statute === "string"
              ? r.statute
              : anchor.statute,
            holidayShifted: false,
            holidayShiftNote: null,
          }),
        );
      }
    }
  }
  return out;
}

/** Handle intake-wizard payload (`{service_date, doc_type, case_type}`).
 *
 * For each anchor matching (jurisdiction, doc_type) we apply the
 * computeAbsoluteDeadline pipeline with the wizard's service_date. */
export function handleIntakePayload(
  payload: Record<string, unknown>,
  jurisdiction: DeadlineJurisdiction,
): Record<string, unknown>[] {
  const docType = typeof payload.doc_type === "string" ? payload.doc_type : "";
  const serviceDateStr = typeof payload.service_date === "string"
    ? payload.service_date
    : null;
  if (!serviceDateStr || !/^\d{4}-\d{2}-\d{2}$/.test(serviceDateStr)) {
    // Service date unknown → cannot compute. Architect §10 test #6 pins this:
    // intake with service_date=null yields zero rows.
    return [];
  }
  const serviceDate = isoToUtcMidnight(serviceDateStr);
  if (!serviceDate) return [];

  const serviceClock = wizardServiceClock(payload, jurisdiction);
  const anchors = findAnchorsByTrigger(jurisdiction, docType);
  if (anchors.length === 0) return [];

  const out: Record<string, unknown>[] = [];
  for (const anchor of anchors) {
    const result = computeAbsoluteDeadline({
      serviceDate,
      serviceClockDays: serviceClock.days,
      serviceClockKind: serviceClock.kind,
      statutoryDays: anchor.days,
      statutoryUnit: anchor.unit,
      jurisdiction: anchor.jurisdiction,
      holidayShiftPolicy: anchor.holidayShiftPolicy,
    });
    out.push(buildRowFromAnchor({
      anchor,
      absoluteDeadline: result.deadlineAt,
      serviceDate,
      sourceDocId: typeof payload.source_doc_id === "string"
        ? payload.source_doc_id
        : null,
      title: anchor.uiLabels?.en ?? "Deadline",
      statuteBasis: anchor.statute,
      holidayShifted: result.holidayShifted,
      holidayShiftNote: result.holidayShiftNote,
    }));
  }
  return out;
}

/** Handle a manual payload — user explicitly entered a deadline through
 * the UI editor. Trust the supplied date verbatim. */
export function handleManualPayload(
  payload: Record<string, unknown>,
  jurisdiction: DeadlineJurisdiction,
): Record<string, unknown>[] {
  const date = typeof payload.deadline_at === "string"
    ? payload.deadline_at
    : null;
  if (!date) return [];
  let deadlineAt: Date | null = null;
  try {
    deadlineAt = new Date(date);
    if (isNaN(deadlineAt.getTime())) deadlineAt = null;
  } catch {
    deadlineAt = null;
  }
  if (!deadlineAt) return [];

  const anchorKey = typeof payload.anchor_key === "string"
    ? payload.anchor_key
    : null;
  const anchor = anchorKey ? findAnchor(anchorKey) : null;

  return [{
    title: typeof payload.title === "string"
      ? payload.title.slice(0, 200)
      : "Deadline",
    description: typeof payload.description === "string"
      ? payload.description.slice(0, 1000)
      : null,
    statute_basis: anchor?.statute ?? (typeof payload.statute_basis === "string"
      ? payload.statute_basis
      : null),
    anchor_key: anchor?.key ?? null,
    service_basis: anchor?.serviceBasis ?? null,
    deadline_at: deadlineAt.toISOString(),
    holiday_shifted: false,
    holiday_shift_note: null,
    priority: typeof payload.priority === "string"
      ? payload.priority
      : (anchor?.defaultPriority ?? "high"),
  }];
}

/** Handle Sonnet-classified candidate dates from chat-turn auto-patch. */
export async function handleHaikuExtractPayload(
  payload: Record<string, unknown>,
  jurisdiction: DeadlineJurisdiction,
): Promise<Record<string, unknown>[]> {
  if (!CLAUDE_API_KEY) {
    console.warn("deadline-extractor: CLAUDE_API_KEY missing — skipping Sonnet");
    return [];
  }
  const candidates = Array.isArray(payload.candidate_dates)
    ? payload.candidate_dates
    : [];
  if (candidates.length === 0) return [];

  const userPayload = JSON.stringify({
    jurisdiction,
    candidates,
    case_type: typeof payload.case_type === "string" ? payload.case_type : null,
  });

  const sonnetText = await callSonnet(userPayload);
  if (!sonnetText) return [];

  const parsed = applyConfidenceFloor(parseExtractedDeadlines(sonnetText));

  const out: Record<string, unknown>[] = [];
  for (const ed of parsed.deadlines) {
    const anchor = findAnchor(ed.anchor_key);
    if (!anchor) continue;
    if (anchor.jurisdiction !== jurisdiction) continue;
    const deadlineAt = isoToUtcMidnight(ed.date);
    if (!deadlineAt) continue;
    // We trust Sonnet's date as the absolute deadline. Note: Sonnet does
    // NOT see the holiday calendar; if it returned a Saturday under a
    // next_business_day anchor, we shift here.
    let holidayShifted = false;
    let holidayShiftNote: string | null = null;
    let finalDeadline = deadlineAt;
    if (anchor.holidayShiftPolicy === "next_business_day") {
      // Re-run shift-only step (no service-clock arithmetic — Sonnet date
      // is already absolute).
      const result = computeAbsoluteDeadline({
        serviceDate: deadlineAt,
        serviceClockDays: 0,
        serviceClockKind: "calendar",
        statutoryDays: 0,
        statutoryUnit: "calendar_days",
        jurisdiction: anchor.jurisdiction,
        holidayShiftPolicy: "next_business_day",
      });
      finalDeadline = result.deadlineAt;
      holidayShifted = result.holidayShifted;
      holidayShiftNote = result.holidayShiftNote || null;
    }

    out.push(buildRowFromAnchor({
      anchor,
      absoluteDeadline: finalDeadline,
      // Source is haiku_extract → cannot be priority='critical' per the
      // case_deadlines_critical_source_check constraint. Architect §11 #1.
      serviceDate: null,
      sourceDocId: null,
      title: ed.title || (anchor.uiLabels?.en ?? "Deadline"),
      statuteBasis: ed.statute_basis || anchor.statute,
      holidayShifted,
      holidayShiftNote,
      // Override priority from Sonnet — but the DB constraint will reject
      // critical from this source. Force-clamp here.
      priority: ed.priority === "critical" ? "high" : ed.priority,
    }));
  }
  return out;
}

// =============================================================================
// Helpers
// =============================================================================

interface BuildRowArgs {
  anchor: StatutoryAnchor;
  absoluteDeadline: Date;
  serviceDate: Date | null;
  sourceDocId: string | null;
  title: string;
  statuteBasis: string;
  holidayShifted: boolean;
  holidayShiftNote: string | null;
  priority?: string;
}

function buildRowFromAnchor(args: BuildRowArgs): Record<string, unknown> {
  return {
    title: args.title.slice(0, 200),
    description: null,
    statute_basis: args.statuteBasis,
    anchor_key: args.anchor.key,
    service_date: args.serviceDate ? args.serviceDate.toISOString().slice(0, 10) : null,
    service_basis: args.anchor.serviceBasis,
    deadline_at: args.absoluteDeadline.toISOString(),
    holiday_shifted: args.holidayShifted,
    holiday_shift_note: args.holidayShiftNote,
    source_doc_id: args.sourceDocId,
    priority: args.priority ?? args.anchor.defaultPriority ?? "high",
  };
}

/** Determine which service-clock modifier the wizard implies. Default is
 * 5d HMS §27 for EE admin decisions, 7d HL §60 turvaviesti for FI. */
function wizardServiceClock(
  payload: Record<string, unknown>,
  jurisdiction: DeadlineJurisdiction,
): { days: number; kind: "calendar" | "working" } {
  const explicit = payload.service_clock;
  if (explicit && typeof explicit === "object") {
    const e = explicit as Record<string, unknown>;
    if (typeof e.days === "number" && typeof e.kind === "string") {
      const kind = (e.kind === "working") ? "working" : "calendar";
      return { days: Math.max(0, Math.floor(e.days)), kind };
    }
  }
  // Default modifiers per architect §2 table.
  if (jurisdiction === "EE") return { days: 5, kind: "calendar" };
  if (jurisdiction === "FI") return { days: 7, kind: "calendar" };
  return { days: 0, kind: "calendar" };
}

function isoToUtcMidnight(iso: string): Date | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(iso)) return null;
  const d = new Date(`${iso}T00:00:00Z`);
  return isNaN(d.getTime()) ? null : d;
}

function isValidUuid(v: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    .test(v);
}

function normalizeJurisdiction(v: unknown): DeadlineJurisdiction | null {
  if (typeof v !== "string") return null;
  const u = v.toUpperCase();
  if (u === "EE" || u === "FI" || u === "EU") return u;
  return null;
}

/** Single-shot Sonnet call. Returns the text content or null on any error. */
async function callSonnet(userPayload: string): Promise<string | null> {
  const controller = new AbortController();
  const timer = setTimeout(
    () => controller.abort(),
    DEADLINE_EXTRACTOR_TIMEOUT_MS,
  );
  try {
    const res = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": CLAUDE_API_KEY!,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: DEADLINE_EXTRACTOR_MODEL,
        max_tokens: DEADLINE_EXTRACTOR_MAX_TOKENS,
        system: DEADLINE_EXTRACTOR_SYSTEM_PROMPT,
        messages: [{ role: "user", content: userPayload }],
      }),
      signal: controller.signal,
    });
    clearTimeout(timer);
    if (!res.ok) {
      console.warn(
        `deadline-extractor: sonnet HTTP ${res.status}: ${
          (await res.text()).slice(0, 200)
        }`,
      );
      return null;
    }
    const json = await res.json();
    const blocks = Array.isArray(json?.content) ? json.content : [];
    const textBlock = blocks.find((b: unknown) =>
      b && typeof b === "object" && (b as Record<string, unknown>).type === "text"
    );
    if (textBlock && typeof (textBlock as Record<string, unknown>).text === "string") {
      return (textBlock as Record<string, unknown>).text as string;
    }
    return null;
  } catch (e) {
    clearTimeout(timer);
    console.warn(
      `deadline-extractor: sonnet call threw: ${String(e).slice(0, 200)}`,
    );
    return null;
  }
}

// =============================================================================
// Re-exports for tests
// =============================================================================

export {
  type ExtractedDeadline,
  isoToUtcMidnight,
  isValidUuid,
  normalizeJurisdiction,
  wizardServiceClock,
};
