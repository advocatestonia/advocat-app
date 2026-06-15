// demand-letter/index.ts — HTTP shim for Feature #2 (Demand-Letter Generator).
// -----------------------------------------------------------------------------
// Given the 5-step wizard inputs (claim type, parties, amount/basis, deadline,
// jurisdiction, language) it composes a formal pre-court demand letter
// (FI maksuvaatimus / EE nõudekiri) and persists it to `demand_letters`.
//
// The CLIENT then renders the returned markdown to PDF via the existing
// `pdf-generator` function (same as the Legal Template Library does for
// DOCX/PDF), and may hand it to the e-mail agent. This function deliberately
// does NOT auto-send and does NOT call the PDF worker itself — composition +
// persistence only.
//
// Endpoint:
//   POST /functions/v1/demand-letter
//   Body: {
//     claim_type: "deposit_return"|"unpaid_wage"|"fine_dispute"|"generic_claim",
//     jurisdiction: "FI"|"EE",
//     lang: "fi"|"et"|"ru"|"en",
//     sender:    { name, address? },   // optional — falls back to profile
//     recipient: { name, address? },
//     amount?, currency?, basis, deadline, reference?,
//     case_id?,                        // optional — auto-fills sender/reference
//     letter_id?                       // when updating an existing draft
//   }
//   Auth: Bearer <user_jwt> required (no anonymous traffic).
//   Returns: { letter_id, markdown, subject, norms, validation }
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { isClaimType, isJurisdiction } from "./presets.ts";
import {
  autoSender,
  buildLetter,
  type CaseRow,
  isLetterLang,
  type LetterInput,
  type Party,
  type ProfileRow,
  validateLetterInput,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/** Cap free-text fields so one request can't store a huge blob. */
const MAX_FIELD = 5000;

/** Reads a Party from raw JSON, trimming + length-capping. Returns null when no name. */
function readParty(raw: unknown): Party | null {
  if (raw == null || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const name = typeof o.name === "string" ? o.name.trim().slice(0, 300) : "";
  if (!name) return null;
  const address =
    typeof o.address === "string" ? o.address.trim().slice(0, MAX_FIELD) : null;
  return { name, address };
}

/** Coerces a raw value to a trimmed, capped string (or undefined). */
function readStr(v: unknown, max = MAX_FIELD): string | undefined {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  return t ? t.slice(0, max) : undefined;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Auth + a modest per-user rate limit. Composition is cheap (no LLM call) but
  // we still cap how fast one user can generate/persist letters.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "demand-letter",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Request body must be valid JSON", 400);
  }

  // ── Validate enums up front. ──────────────────────────────────────────────
  if (!isClaimType(body.claim_type)) {
    return jsonError("claim_type is invalid", 400);
  }
  if (!isJurisdiction(body.jurisdiction)) {
    return jsonError("jurisdiction must be FI or EE", 400);
  }
  if (!isLetterLang(body.lang)) {
    return jsonError("lang must be one of fi/et/ru/en", 400);
  }
  const claimType = body.claim_type;
  const jurisdiction = body.jurisdiction;
  const lang = body.lang;

  // ── Auto-fill sender + reference from profile / case. ─────────────────────
  const { data: profData } = await supabaseAdmin
    .from("profiles")
    .select("full_name, email")
    .eq("id", userId)
    .maybeSingle();
  const profile = (profData ?? null) as ProfileRow | null;

  let caseRow: CaseRow | null = null;
  const caseId = readStr(body.case_id, 64);
  if (caseId) {
    if (!UUID_RE.test(caseId)) {
      return jsonError("case_id must be a uuid", 400);
    }
    const { data: caseData } = await supabaseAdmin
      .from("cases")
      .select("title, court_case_number, user_id")
      .eq("id", caseId)
      .eq("user_id", userId) // ownership — fail closed
      .maybeSingle();
    if (caseData) caseRow = caseData as CaseRow;
    // Missing/foreign case → ignored silently (no existence leak).
  }

  const auto = autoSender({ profile, caseRow });

  // User-supplied parties override the auto sender; recipient is always user-set.
  const sender = readParty(body.sender) ?? auto.sender;
  const recipient = readParty(body.recipient);
  if (!recipient) {
    return jsonError("recipient.name is required", 400);
  }

  const input: LetterInput = {
    claimType,
    jurisdiction,
    lang,
    sender,
    recipient,
    amount: readStr(body.amount, 64) ?? null,
    currency: readStr(body.currency, 8) ?? "EUR",
    basis: readStr(body.basis, MAX_FIELD) ?? "",
    deadline: readStr(body.deadline, 128) ?? "",
    reference: readStr(body.reference, 128) ?? auto.reference,
    todayIso: new Date().toISOString().slice(0, 10),
  };

  const validation = validateLetterInput(input);
  if (validation.length > 0) {
    return jsonError("Validation failed", 422, { validation });
  }

  const letter = buildLetter(input);

  // ── Persist (insert new draft or update an existing one the user owns). ───
  const letterId = readStr(body.letter_id, 64);
  const row = {
    user_id: userId,
    case_id: caseId ?? null,
    claim_type: claimType,
    jurisdiction,
    lang,
    recipient_name: recipient.name,
    amount: input.amount,
    currency: input.currency,
    subject: letter.subject,
    body_markdown: letter.markdown,
    status: "draft" as const,
    updated_at: new Date().toISOString(),
  };

  let savedId: string | null = null;
  if (letterId) {
    if (!UUID_RE.test(letterId)) {
      return jsonError("letter_id must be a uuid", 400);
    }
    const { data, error } = await supabaseAdmin
      .from("demand_letters")
      .update(row)
      .eq("id", letterId)
      .eq("user_id", userId) // ownership — fail closed
      .select("id")
      .maybeSingle();
    if (error) {
      console.error("demand-letter update error", error);
      return jsonError("Failed to save letter", 500);
    }
    savedId = (data as { id: string } | null)?.id ?? null;
    if (!savedId) {
      return jsonError("Letter not found", 404);
    }
  } else {
    const { data, error } = await supabaseAdmin
      .from("demand_letters")
      .insert(row)
      .select("id")
      .single();
    if (error) {
      console.error("demand-letter insert error", error);
      return jsonError("Failed to save letter", 500);
    }
    savedId = (data as { id: string }).id;
  }

  return jsonOk({
    letter_id: savedId,
    markdown: letter.markdown,
    subject: letter.subject,
    norms: letter.norms,
    validation: [],
  });
});
