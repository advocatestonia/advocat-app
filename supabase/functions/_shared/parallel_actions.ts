// parallel_actions.ts
// -----------------------------------------------------------------------------
// Parallel Actions Panel — shared extractor that turns a consilium synthesis
// (or any other triage output text) into a list of `ProposedAction` rows the
// inbox UI can render as a single grouped card.
//
// Pattern source (Sulga case, 2026-05-25):
//   The 5-lawyer consilium for Migri/Jokela recommended TWO emails in
//   parallel — one reply to Jokela (HOL §122 soft-return) and one new
//   asiakirjapyyntö to poliisi kirjaamo (JulkL 14§, 2vk deadline). The
//   UI needs to show both in one card so the user approves them with a
//   single tap.
//
// Design constraints (per the parent agent's brief):
//   * DO NOT touch consilium core architecture. This file is additive.
//   * Default to a SINGLE action so existing single-draft triage flows
//     keep working unchanged. The legacy `draft_body` field still drives
//     idx=0 when no `<proposed_actions>` block is present.
//   * Each action must carry enough to dispatch via `email-send`:
//     to_addr, subject, body, language, citations, optional gate_token,
//     and a 1-2 sentence rationale shown in the UI mini preview.
//
// Wire format (synthesis emits XML-flavoured plain text — same family
// as the rest of the email-triage block protocol):
//
//   <proposed_actions>
//     <action idx="0" kind="email_reply" lang="fi">
//       <to>jokela@migri.fi</to>
//       <cc></cc>
//       <subject>Vastaus 12.5.2026 viestiin</subject>
//       <rationale>Soft-return per HOL §122; declines käännytys
//                  without admitting wrong identity claim.</rationale>
//       <citations>[[ref:fi-hol:122]], [[ref:eu-echr:6.3]]</citations>
//       <body>
//         Hyvä Jokela, …
//       </body>
//     </action>
//     <action idx="1" kind="email_new" lang="fi">
//       <to>kirjaamo.helsinki@poliisi.fi</to>
//       <subject>Asiakirjapyyntö (JulkL 14§)</subject>
//       <rationale>2vk deadline; requests Eckerö Line + police ticket
//                  records that prove käännytys on 5.12.2025.</rationale>
//       <citations>[[ref:fi-julkl:14]]</citations>
//       <body>
//         Pyydän julkisuuslain 14§:n nojalla seuraavat asiakirjat …
//       </body>
//     </action>
//   </proposed_actions>
//
// The block is optional. When absent, `extractProposedActions` returns
// a single-element array built from the supplied legacy draft fields,
// so callers can always treat the result as length >= 1.
//
// Pure module — no Deno globals, no Supabase imports. Importable from
// either the email-triage edge fn (triage_logic.ts) or future cron
// fanout jobs.
// -----------------------------------------------------------------------------

export type ProposedActionKind = "email_reply" | "email_new";

export interface ProposedAction {
  /** 0..N-1. Stable ordering; persistence + UI both rely on it. */
  idx: number;
  /** "email_reply" replies in-thread; "email_new" creates a new thread. */
  kind: ProposedActionKind;
  /** Single primary recipient. The UI shows this as the mini-card target. */
  to_addr: string;
  /** Optional cc list. Often empty. */
  cc: string[];
  /** Subject line — for replies the consilium may emit "Re: …". */
  subject: string;
  /** Plaintext body — the only format the send-email edge fn accepts today. */
  body: string;
  /** ISO language code, e.g. "fi", "et", "ru", "en". */
  language: string;
  /** [[ref:slug:para]] markers preserved verbatim, comma-joined. */
  citations: string[];
  /** 1-2 sentence "why this action" for the UI preview. Trimmed to 200 chars. */
  rationale: string;
  /** Optional HMAC gate token. NULL when policy_gate did not pass. */
  gate_token: unknown | null;
}

/** Input shape accepted by `extractProposedActions`. */
export interface ExtractInput {
  /** Raw consilium synthesis (or any other model output). May be empty. */
  synthesis: string;
  /** Legacy single-draft fallback. Used when no `<proposed_actions>` block
   *  is found in the synthesis. Mirrors the existing email_triage_results
   *  draft_* columns. */
  legacyDraft?: {
    to_addr?: string;
    cc?: string[];
    subject?: string;
    body?: string;
    language?: string;
    citations?: string[];
    rationale?: string;
    gate_token?: unknown | null;
  };
}

// =============================================================================
// Block extraction (permissive XML-ish)
// =============================================================================

const MAX_RATIONALE_LEN = 200;
const MAX_BODY_LEN = 100_000;
const MAX_SUBJECT_LEN = 500;
const MAX_ACTIONS = 8; // hard cap to keep the UI sensible

/** Find a single `<TAG>…</TAG>` body; returns null when missing. Tolerant of
 *  attributes on the opening tag. */
function extractInner(text: string, tag: string): {
  body: string;
  attrs: Record<string, string>;
} | null {
  const re = new RegExp(`<${tag}\\b([^>]*)>([\\s\\S]*?)</${tag}>`, "i");
  const m = re.exec(text);
  if (!m) return null;
  const attrs: Record<string, string> = {};
  const attrRe = /([a-zA-Z_][\w-]*)\s*=\s*"([^"]*)"/g;
  let am: RegExpExecArray | null;
  while ((am = attrRe.exec(m[1] ?? "")) != null) {
    attrs[am[1]] = am[2];
  }
  return { body: (m[2] ?? "").trim(), attrs };
}

/** Find ALL `<action>…</action>` children inside a parent body, preserving
 *  document order. */
function extractAllActions(parentBody: string): Array<{
  body: string;
  attrs: Record<string, string>;
}> {
  const out: Array<{ body: string; attrs: Record<string, string> }> = [];
  const re = /<action\b([^>]*)>([\s\S]*?)<\/action>/gi;
  let m: RegExpExecArray | null;
  while ((m = re.exec(parentBody)) != null) {
    const attrs: Record<string, string> = {};
    const attrRe = /([a-zA-Z_][\w-]*)\s*=\s*"([^"]*)"/g;
    let am: RegExpExecArray | null;
    while ((am = attrRe.exec(m[1] ?? "")) != null) {
      attrs[am[1]] = am[2];
    }
    out.push({ body: (m[2] ?? "").trim(), attrs });
  }
  return out;
}

function cap(s: string, max: number): string {
  if (s.length <= max) return s;
  return s.slice(0, max).trim();
}

function parseCitationList(raw: string | null | undefined): string[] {
  if (!raw) return [];
  // Keep [[ref:slug:para]] markers verbatim. Tolerant of separators —
  // commas, semicolons, or newlines.
  const matches = raw.match(/\[\[ref:[^\]]+\]\]/g);
  if (!matches) return [];
  return matches;
}

function parseKind(raw: string | undefined): ProposedActionKind {
  const v = (raw ?? "").trim().toLowerCase();
  if (v === "email_new" || v === "new" || v === "email-new") return "email_new";
  // Default to reply — consilium synthesises reply-shaped drafts by default.
  return "email_reply";
}

function parseCcList(raw: string | null): string[] {
  if (!raw) return [];
  return raw
    .split(/[,;\n]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

// =============================================================================
// Public API
// =============================================================================

/**
 * Extract a list of ProposedAction rows from the synthesis text.
 *
 * Returns a non-empty array. When no `<proposed_actions>` block is found
 * but the caller supplied a `legacyDraft`, a single-element array is
 * synthesised so the persistence layer can always write the same shape.
 *
 * When BOTH the synthesis lacks a `<proposed_actions>` block AND the
 * legacy draft is empty (no `to_addr` AND no `body`), an empty array is
 * returned and the caller should skip writing `proposed_actions` (the
 * triage row still persists; the inbox UI falls back to the no-draft
 * code path).
 */
export function extractProposedActions(input: ExtractInput): ProposedAction[] {
  const synthesis = input.synthesis ?? "";

  // 1. Try the explicit `<proposed_actions>` block first.
  const block = extractInner(synthesis, "proposed_actions");
  if (block) {
    const rawActions = extractAllActions(block.body);
    const parsed: ProposedAction[] = [];
    let nextIdx = 0;
    for (const a of rawActions) {
      if (parsed.length >= MAX_ACTIONS) break;
      const idxAttr = parseInt(a.attrs["idx"] ?? "", 10);
      const idx = Number.isFinite(idxAttr) && idxAttr >= 0
        ? idxAttr
        : nextIdx;
      nextIdx = Math.max(nextIdx, idx + 1);
      const kind = parseKind(a.attrs["kind"]);
      const language = (a.attrs["lang"] ?? a.attrs["language"] ?? "en").trim()
        || "en";
      const to = extractInner(a.body, "to")?.body ?? "";
      const cc = parseCcList(extractInner(a.body, "cc")?.body ?? null);
      const subject = extractInner(a.body, "subject")?.body ?? "";
      const body = extractInner(a.body, "body")?.body ?? "";
      const rationale = extractInner(a.body, "rationale")?.body ?? "";
      const citations = parseCitationList(
        extractInner(a.body, "citations")?.body ?? null,
      );
      // Skip junk entries that have neither recipient nor body. A single
      // blank `<action/>` from a hallucinating model shouldn't pollute the
      // UI grid.
      if (to.length === 0 && body.length === 0) continue;
      parsed.push({
        idx,
        kind,
        to_addr: to,
        cc,
        subject: cap(subject, MAX_SUBJECT_LEN),
        body: cap(body, MAX_BODY_LEN),
        language,
        citations,
        rationale: cap(rationale, MAX_RATIONALE_LEN),
        gate_token: null,
      });
    }
    if (parsed.length > 0) {
      // Re-normalise idx so they are 0..N-1 contiguous regardless of what
      // the model emitted. The persisted ordering must match array index
      // to keep the UI selection logic simple.
      return parsed.map((a, i) => ({ ...a, idx: i }));
    }
    // Fell through — block present but empty. Continue to legacy fallback.
  }

  // 2. Legacy single-draft fallback.
  const ld = input.legacyDraft;
  if (
    ld && ((ld.to_addr ?? "").length > 0 || (ld.body ?? "").length > 0)
  ) {
    return [
      {
        idx: 0,
        kind: "email_reply",
        to_addr: ld.to_addr ?? "",
        cc: ld.cc ?? [],
        subject: cap(ld.subject ?? "", MAX_SUBJECT_LEN),
        body: cap(ld.body ?? "", MAX_BODY_LEN),
        language: (ld.language ?? "en").trim() || "en",
        citations: ld.citations ?? [],
        rationale: cap(ld.rationale ?? "", MAX_RATIONALE_LEN),
        gate_token: ld.gate_token ?? null,
      },
    ];
  }

  // 3. Nothing to render.
  return [];
}

/**
 * Serialise a list of ProposedActions to the JSONB shape persisted in
 * `email_triage_results.proposed_actions`. Pure mapper — no I/O.
 *
 * The DB column is `jsonb`, so we just return the plain JS object and
 * let the supabase client stringify on insert.
 */
export function serialiseProposedActions(
  actions: ProposedAction[],
): Array<Record<string, unknown>> {
  return actions.map((a) => ({
    idx: a.idx,
    kind: a.kind,
    to_addr: a.to_addr,
    cc: a.cc,
    subject: a.subject,
    body: a.body,
    language: a.language,
    citations: a.citations,
    rationale: a.rationale,
    gate_token: a.gate_token,
  }));
}

/** Inverse of `serialiseProposedActions` — useful for tests and for the
 *  `email-send` edge function's action_idx lookup path. */
export function deserialiseProposedActions(
  raw: unknown,
): ProposedAction[] {
  if (!Array.isArray(raw)) return [];
  const out: ProposedAction[] = [];
  for (let i = 0; i < raw.length && i < MAX_ACTIONS; i++) {
    const r = raw[i];
    if (!r || typeof r !== "object") continue;
    const rec = r as Record<string, unknown>;
    const idxRaw = rec["idx"];
    const idx = typeof idxRaw === "number" && Number.isFinite(idxRaw)
      ? idxRaw
      : i;
    const kind = parseKind(rec["kind"] as string | undefined);
    const cc = Array.isArray(rec["cc"])
      ? (rec["cc"] as unknown[])
          .filter((x): x is string => typeof x === "string")
      : [];
    const citations = Array.isArray(rec["citations"])
      ? (rec["citations"] as unknown[])
          .filter((x): x is string => typeof x === "string")
      : [];
    out.push({
      idx,
      kind,
      to_addr: typeof rec["to_addr"] === "string"
        ? (rec["to_addr"] as string)
        : "",
      cc,
      subject: typeof rec["subject"] === "string"
        ? (rec["subject"] as string)
        : "",
      body: typeof rec["body"] === "string" ? (rec["body"] as string) : "",
      language: typeof rec["language"] === "string"
        ? (rec["language"] as string)
        : "en",
      citations,
      rationale: typeof rec["rationale"] === "string"
        ? (rec["rationale"] as string)
        : "",
      gate_token: rec["gate_token"] ?? null,
    });
  }
  return out;
}
