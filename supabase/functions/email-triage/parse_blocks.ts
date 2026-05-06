// email-triage/parse_blocks.ts
// -----------------------------------------------------------------------------
// Parser for the v1.1-final structured output contract.
//
// 6 mandatory blocks:
//   <privilege_check>, <conflict_check>, <triage>, <user_brief>,
//   <send_recommendation>, plus <actions_required> (mandatory whenever
//   POSTURE != no_reply per §687).
//
// 5 optional blocks:
//   <appeal_route>, <attachments>, <draft language="..." addressed_to="...">,
//   <gdpr_basis>, <memory_update>.
//
// The model output is XML-flavoured plain text — NOT real XML. We use
// permissive regex extraction with conservative validation. The parser is
// pure — no I/O.
//
// Output shape mirrors the columns in `email_triage_results` (D2 migration)
// so persistence is a 1:1 row build with no glue.
// -----------------------------------------------------------------------------

import { PROMPT_VERSION } from "../_shared/email_agent_prompt.ts";

// =============================================================================
// Types
// =============================================================================

export type PrivilegeCheck =
  | "passed"
  | "blocked"
  | "suspicious_privileged"
  | "waiver_suspected"
  | "own_counsel_advisory";

export type ConflictCheck = "passed" | "flagged";

export type Posture = "reply_now" | "hold_for_user" | "no_reply";

export type SendRecommendation =
  | "auto_send_eligible"
  | "hold_for_user_review"
  | "archive";

export interface DeadlineEntry {
  iso_date: string;
  delta_days: number | null;
  description: string;
}

export interface ActionRequired {
  type: string;
  target: string;
  deadline: string;
  why: string;
}

export interface AttachmentEntry {
  filename: string;
  mime: string;
  size_bytes: number;
}

export interface AppealRoute {
  forum?: string;
  deadline_days?: number;
  prior_step?: string;
  authority_of_redress?: string;
  service_basis?: string;
}

export interface GdprBasisEntry {
  recipient: string;
  art_6_basis: string;
  art_9_basis: string;
  art_10_basis: string;
}

export interface MemoryUpdate {
  key: string;
  value: string;
  reason: string;
  confidence: "high" | "medium" | "low";
  source_layer: "thread" | "active_case" | "memory" | "rag";
  expires_at: string | null;
}

export interface DraftBlock {
  language: string;
  addressed_to: string;
  subject: string;
  body: string;
  to: string[];
  cc: string[];
}

export interface ParsedTriage {
  privilege_check: PrivilegeCheck;
  conflict_check: ConflictCheck;
  triage: {
    track: string[];
    inbound: string;
    key_facts: string[];
    deadlines: DeadlineEntry[];
    contradictions: string[];
    evidence_gaps: string[];
    posture: Posture;
    reasoning: string;
  };
  appeal_route: AppealRoute | null;
  attachments: AttachmentEntry[];
  draft: DraftBlock | null;
  gdpr_basis: GdprBasisEntry[];
  actions_required: ActionRequired[];
  user_brief: string;
  user_brief_language: string | null;
  memory_updates: MemoryUpdate[];
  send_recommendation: SendRecommendation;
  prompt_version: string;
}

export interface ParseError {
  ok: false;
  missing_blocks: string[];
  message: string;
  raw: string;
}

export type ParseResult =
  | { ok: true; parsed: ParsedTriage }
  | ParseError;

// =============================================================================
// Block extractor
// =============================================================================

/** Extract the FIRST occurrence of a block. Tolerant of attribute lists. */
function extractBlock(text: string, name: string): {
  body: string;
  attrs: Record<string, string>;
} | null {
  const open = new RegExp(
    `<${name}\\b([^>]*)>([\\s\\S]*?)</${name}>`,
    "i",
  );
  const m = open.exec(text);
  if (!m) return null;
  const attrText = m[1] ?? "";
  const body = (m[2] ?? "").trim();
  const attrs: Record<string, string> = {};
  const attrRe = /([a-zA-Z_][\w-]*)\s*=\s*"([^"]*)"/g;
  let am: RegExpExecArray | null;
  while ((am = attrRe.exec(attrText)) != null) {
    attrs[am[1]] = am[2];
  }
  return { body, attrs };
}

// =============================================================================
// Field-line helpers — model emits "FIELD: value" lines inside <triage>
// =============================================================================

function field(body: string, name: string): string | null {
  // Single-line first.
  const re = new RegExp(`^\\s*${name}\\s*:\\s*(.*?)\\s*$`, "im");
  const m = re.exec(body);
  if (!m) return null;
  return m[1].trim();
}

function multilineField(body: string, name: string): string | null {
  // Capture text from "NAME:" to the next "ALL_CAPS_FIELD:" line.
  const re = new RegExp(
    `^\\s*${name}\\s*:\\s*([\\s\\S]*?)(?=^\\s*[A-Z][A-Z _0-9]+\\s*:|\\z)`,
    "im",
  );
  const m = re.exec(body);
  if (!m) return null;
  return m[1].trim();
}

function bulletList(s: string | null): string[] {
  if (!s) return [];
  return s.split(/\r?\n/)
    .map((line) => line.replace(/^[-•]\s*/, "").trim())
    .filter((line) => line.length > 0 && line.toLowerCase() !== "none");
}

// =============================================================================
// Per-block parsers
// =============================================================================

function parsePrivilegeCheck(s: string): PrivilegeCheck | null {
  const v = s.trim().toLowerCase();
  if (
    v === "passed" || v === "blocked" || v === "suspicious_privileged" ||
    v === "waiver_suspected" || v === "own_counsel_advisory"
  ) return v as PrivilegeCheck;
  return null;
}

function parseConflictCheck(s: string): ConflictCheck | null {
  const v = s.trim().toLowerCase();
  if (v === "passed" || v === "flagged") return v;
  return null;
}

function parsePosture(s: string): Posture | null {
  const v = s.trim().toLowerCase();
  if (v === "reply_now" || v === "hold_for_user" || v === "no_reply") return v;
  return null;
}

function parseSendRecommendation(s: string): SendRecommendation | null {
  const v = s.trim().toLowerCase();
  if (
    v === "auto_send_eligible" || v === "hold_for_user_review" ||
    v === "archive"
  ) return v as SendRecommendation;
  return null;
}

function parseTriageBlock(body: string): ParsedTriage["triage"] | null {
  const trackRaw = field(body, "TRACK");
  const inbound = field(body, "INBOUND") ?? "";
  const postureRaw = field(body, "POSTURE");
  const reasoning = multilineField(body, "REASONING") ?? "";
  if (!postureRaw) return null;
  const posture = parsePosture(postureRaw);
  if (!posture) return null;

  const keyFacts = bulletList(multilineField(body, "KEY FACTS"));
  const deadlinesRaw = bulletList(multilineField(body, "DEADLINES"));
  const contradictionsRaw = multilineField(body, "CONTRADICTIONS") ?? "";
  const evidenceGapsRaw = multilineField(body, "EVIDENCE GAPS") ?? "";

  let track: string[] = [];
  if (trackRaw) {
    const m = /^\[(.*)\]$/s.exec(trackRaw.trim());
    track = (m ? m[1] : trackRaw)
      .split(",")
      .map((s) => s.trim())
      .filter((s) => s.length > 0 && s.toLowerCase() !== "none");
  }

  const deadlines: DeadlineEntry[] = deadlinesRaw.map((line) => {
    const isoMatch = /(\d{4}-\d{2}-\d{2})/.exec(line);
    const deltaMatch = /Δ\s*(\d+)/.exec(line);
    return {
      iso_date: isoMatch ? isoMatch[1] : "",
      delta_days: deltaMatch ? Number(deltaMatch[1]) : null,
      description: line,
    };
  });

  const contradictions = contradictionsRaw.toLowerCase() === "none"
    ? []
    : bulletList(contradictionsRaw).length > 0
      ? bulletList(contradictionsRaw)
      : [contradictionsRaw];
  const evidenceGaps = evidenceGapsRaw.toLowerCase() === "none"
    ? []
    : bulletList(evidenceGapsRaw).length > 0
      ? bulletList(evidenceGapsRaw)
      : [evidenceGapsRaw];

  return {
    track,
    inbound,
    key_facts: keyFacts,
    deadlines,
    contradictions,
    evidence_gaps: evidenceGaps,
    posture,
    reasoning,
  };
}

function parseAppealRoute(body: string): AppealRoute {
  return {
    forum: field(body, "forum") ?? undefined,
    deadline_days: (() => {
      const v = field(body, "deadline_days");
      if (!v) return undefined;
      const n = Number(v);
      return isFinite(n) ? n : undefined;
    })(),
    prior_step: field(body, "prior_step") ?? undefined,
    authority_of_redress: field(body, "authority_of_redress") ?? undefined,
    service_basis: field(body, "service_basis") ?? undefined,
  };
}

function parseAttachments(body: string): AttachmentEntry[] {
  // Format per spec:
  //   - filename: foo.pdf
  //     mime: application/pdf
  //     size_bytes: 12345
  const out: AttachmentEntry[] = [];
  const blocks = body.split(/^\s*-\s+/m).map((s) => s.trim()).filter(Boolean);
  for (const block of blocks) {
    const filename = field(block, "filename");
    const mime = field(block, "mime");
    const size = field(block, "size_bytes");
    if (!filename) continue;
    out.push({
      filename,
      mime: mime ?? "application/octet-stream",
      size_bytes: size && isFinite(Number(size)) ? Number(size) : 0,
    });
  }
  return out;
}

function parseDraftBlock(
  body: string,
  attrs: Record<string, string>,
): DraftBlock | null {
  const language = (attrs["language"] ?? "en").trim();
  const addressedTo = (attrs["addressed_to"] ?? "").trim();
  // Body is "Subject: ...\n\n<rest>". Tolerate "Subject:" possibly missing.
  const subjectMatch = /^\s*Subject:\s*(.+?)\s*\n([\s\S]*)$/m.exec(body);
  let subject = "";
  let bodyText = body;
  if (subjectMatch) {
    subject = subjectMatch[1].trim();
    bodyText = subjectMatch[2].trim();
  }
  // Recipient extraction from `addressed_to` attribute: support "Name <email>"
  // or comma-separated bare emails.
  const to: string[] = [];
  for (const tok of addressedTo.split(",")) {
    const m = /<([^>]+)>/.exec(tok) ?? /([^\s<>]+@[^\s<>]+)/.exec(tok);
    if (m) to.push(m[1].trim());
  }
  return {
    language,
    addressed_to: addressedTo,
    subject,
    body: bodyText,
    to,
    cc: [],
  };
}

function parseGdprBasis(body: string): GdprBasisEntry[] {
  const out: GdprBasisEntry[] = [];
  const blocks = body.split(/^\s*-\s+/m).map((s) => s.trim()).filter(Boolean);
  // The spec example shows a flat list (no leading "-"); also handle that
  // by treating the whole body as one entry if no leading dashes were found.
  const candidates = blocks.length > 0 ? blocks : [body];
  for (const block of candidates) {
    const recipient = field(block, "recipient");
    const a6 = field(block, "art_6_basis");
    if (!recipient || !a6) continue;
    out.push({
      recipient,
      art_6_basis: a6,
      art_9_basis: field(block, "art_9_basis") ?? "n/a",
      art_10_basis: field(block, "art_10_basis") ?? "n/a",
    });
  }
  return out;
}

function parseActionsRequired(body: string): ActionRequired[] {
  const out: ActionRequired[] = [];
  const blocks = body.split(/^\s*-\s+/m).map((s) => s.trim()).filter(Boolean);
  for (const block of blocks) {
    const type = field(block, "type") ?? "other";
    const target = field(block, "target") ?? "";
    const deadline = field(block, "deadline") ?? "";
    const why = field(block, "why") ?? "";
    if (target.length === 0 && deadline.length === 0 && why.length === 0) {
      continue;
    }
    out.push({ type, target, deadline, why });
  }
  return out;
}

function parseMemoryUpdate(body: string): MemoryUpdate[] {
  // <memory_update> body is JSON array per spec §688.
  try {
    const parsed = JSON.parse(body);
    if (!Array.isArray(parsed)) return [];
    const out: MemoryUpdate[] = [];
    for (const item of parsed) {
      if (!item || typeof item !== "object") continue;
      const key = String(item.key ?? "").trim();
      if (!key) continue;
      const conf = String(item.confidence ?? "low").toLowerCase();
      const layer = String(item.source_layer ?? "thread").toLowerCase();
      out.push({
        key,
        value: String(item.value ?? ""),
        reason: String(item.reason ?? ""),
        confidence: (conf === "high" || conf === "medium" || conf === "low")
          ? conf
          : "low",
        source_layer: (layer === "thread" || layer === "active_case" ||
            layer === "memory" || layer === "rag")
          ? layer as MemoryUpdate["source_layer"]
          : "thread",
        expires_at: item.expires_at == null ? null : String(item.expires_at),
      });
    }
    return out;
  } catch (_e) {
    return [];
  }
}

// =============================================================================
// Top-level parser
// =============================================================================

const MANDATORY_BLOCKS = [
  "privilege_check",
  "conflict_check",
  "triage",
  "user_brief",
  "send_recommendation",
] as const;

export function parseAgentBlocks(raw: string): ParseResult {
  if (typeof raw !== "string" || raw.length === 0) {
    return {
      ok: false,
      missing_blocks: [...MANDATORY_BLOCKS],
      message: "empty_output",
      raw: String(raw ?? ""),
    };
  }
  const missing: string[] = [];

  const privilegeRaw = extractBlock(raw, "privilege_check");
  const conflictRaw = extractBlock(raw, "conflict_check");
  const triageRaw = extractBlock(raw, "triage");
  const userBriefRaw = extractBlock(raw, "user_brief");
  const sendRecommendationRaw = extractBlock(raw, "send_recommendation");

  if (!privilegeRaw) missing.push("privilege_check");
  if (!conflictRaw) missing.push("conflict_check");
  if (!triageRaw) missing.push("triage");
  if (!userBriefRaw) missing.push("user_brief");
  if (!sendRecommendationRaw) missing.push("send_recommendation");

  if (missing.length > 0) {
    return {
      ok: false,
      missing_blocks: missing,
      message: `missing_mandatory_blocks: ${missing.join(",")}`,
      raw,
    };
  }

  const privilege = parsePrivilegeCheck(privilegeRaw!.body);
  const conflict = parseConflictCheck(conflictRaw!.body);
  const triage = parseTriageBlock(triageRaw!.body);
  const sendRec = parseSendRecommendation(sendRecommendationRaw!.body);
  if (!privilege || !conflict || !triage || !sendRec) {
    const bad: string[] = [];
    if (!privilege) bad.push("privilege_check_value");
    if (!conflict) bad.push("conflict_check_value");
    if (!triage) bad.push("triage_block_shape");
    if (!sendRec) bad.push("send_recommendation_value");
    return {
      ok: false,
      missing_blocks: bad,
      message: `bad_block_shape: ${bad.join(",")}`,
      raw,
    };
  }

  // Optional / conditional blocks
  const appealRouteRaw = extractBlock(raw, "appeal_route");
  const attachmentsRaw = extractBlock(raw, "attachments");
  const draftRaw = extractBlock(raw, "draft");
  const gdprRaw = extractBlock(raw, "gdpr_basis");
  const actionsRaw = extractBlock(raw, "actions_required");
  const memoryRaw = extractBlock(raw, "memory_update");

  const userBriefBody = userBriefRaw!.body;
  const userBriefLang =
    (userBriefRaw!.attrs["language"] ?? "").trim() || null;

  const parsed: ParsedTriage = {
    privilege_check: privilege,
    conflict_check: conflict,
    triage,
    appeal_route: appealRouteRaw ? parseAppealRoute(appealRouteRaw.body) : null,
    attachments: attachmentsRaw ? parseAttachments(attachmentsRaw.body) : [],
    draft: draftRaw ? parseDraftBlock(draftRaw.body, draftRaw.attrs) : null,
    gdpr_basis: gdprRaw ? parseGdprBasis(gdprRaw.body) : [],
    actions_required: actionsRaw ? parseActionsRequired(actionsRaw.body) : [],
    user_brief: userBriefBody,
    user_brief_language: userBriefLang,
    memory_updates: memoryRaw ? parseMemoryUpdate(memoryRaw.body) : [],
    send_recommendation: sendRec,
    prompt_version: PROMPT_VERSION,
  };

  return { ok: true, parsed };
}

// =============================================================================
// Severity computation (per OPERATOR_PROMPT §8 / §737)
// =============================================================================

export type Severity = "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";

/**
 * Map a parsed triage to the notification severity bucket. Mirrors the
 * pseudocode in OPERATOR_PROMPT §737:
 *   if any deadline.delta_days <= 2:           CRITICAL
 *   elif any deadline.delta_days <= 7:         HIGH
 *   elif any actions_required.type=='appear':  HIGH
 *   elif any deadline.delta_days <= 30:        MEDIUM
 *   elif posture == 'no_reply':                LOW
 *   else:                                      MEDIUM
 *
 * Plus hard escalations from §732:
 *   - conflict_check == 'flagged'         → CRITICAL
 *   - privilege_check == 'suspicious_priv'→ CRITICAL
 *   - injection / phishing in CONTRADICTIONS → CRITICAL
 *   - send_recommendation == 'archive'    → LOW (always)
 */
export function computeSeverity(p: ParsedTriage): Severity {
  if (p.send_recommendation === "archive") return "LOW";
  if (p.conflict_check === "flagged") return "CRITICAL";
  if (
    p.privilege_check === "suspicious_privileged" ||
    p.privilege_check === "waiver_suspected"
  ) return "CRITICAL";
  for (const c of p.triage.contradictions) {
    if (
      /injection_attempt_detected|phishing_indicators/i.test(c)
    ) return "CRITICAL";
  }

  const deltas = p.triage.deadlines
    .map((d) => d.delta_days)
    .filter((n): n is number => typeof n === "number" && isFinite(n));

  if (deltas.some((d) => d <= 2)) return "CRITICAL";
  if (deltas.some((d) => d <= 7)) return "HIGH";
  if (p.actions_required.some((a) => a.type === "appear")) return "HIGH";
  if (deltas.some((d) => d <= 30)) return "MEDIUM";
  if (p.triage.posture === "no_reply") return "LOW";
  return "MEDIUM";
}
