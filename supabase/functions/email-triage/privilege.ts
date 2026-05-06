// email-triage/privilege.ts
// -----------------------------------------------------------------------------
// Pre-model privilege classifier — Rule 16 + Rule 16.bis (own_counsel_advisory)
// per OPERATOR_PROMPT §6 correction.
//
// We classify the inbound BEFORE the Sonnet call and inject the result into
// `<context>` as `own_counsel_advisory_for_this_thread: {{IS_OWN_COUNSEL_BOOL}}`
// so the model can apply Rule 16.bis. The model still emits the final
// `<privilege_check>` value — we use the pre-classifier only to decide
// whether to UNBLOCK the body for processing (Jokela-pattern fix).
//
// `MEMORY_BLOCK.own_counsel_emails` is the per-user whitelist. Only senders
// in that list bypass the otherwise-aggressive Rule 16 multi-signal filter.
// Editable from the UI ("this is my lawyer, process") — not from inbound
// content.
// -----------------------------------------------------------------------------

export interface PrivilegePreClass {
  is_own_counsel: boolean;
  is_likely_privileged: boolean;
  matched_signals: string[];
}

export interface PrivilegePreClassInput {
  sender_email: string;
  sender_name?: string | null;
  body_plaintext?: string | null;
  reply_to?: string | null;
  privileged_domains: string[]; // build-time + per-user concat
  own_counsel_emails: string[]; // MEMORY_BLOCK.own_counsel_emails
}

const PRIVILEGE_BODY_MARKERS = [
  "ASIANAJOSALAISUUS",
  "PRIVILEGED & CONFIDENTIAL",
  "ATTORNEY-CLIENT PRIVILEGED",
  "ADVOKAADI KUTSESALADUS",
  "AVOCAT — CONFIDENTIEL",
];

/**
 * Pure classifier. Returns `is_own_counsel=true` ONLY when the sender (or
 * Reply-To) appears in `own_counsel_emails`. Returns
 * `is_likely_privileged=true` when ANY of the multi-signal hits fire.
 */
export function classifyPrivilege(
  input: PrivilegePreClassInput,
): PrivilegePreClass {
  const sender = (input.sender_email ?? "").toLowerCase().trim();
  const replyTo = (input.reply_to ?? "").toLowerCase().trim();
  const domain = sender.split("@").pop() ?? "";
  const ownCounsel = new Set(
    input.own_counsel_emails.map((s) => s.toLowerCase().trim()),
  );

  const signals: string[] = [];

  // 1. Own-counsel allowlist (highest precedence — bypasses block path).
  const isOwnCounsel = ownCounsel.has(sender) ||
    (replyTo.length > 0 && ownCounsel.has(replyTo));
  if (isOwnCounsel) {
    signals.push("own_counsel_allowlist");
  }

  // 2. Domain match (Rule 16(a)).
  for (const d of input.privileged_domains) {
    const lower = d.toLowerCase();
    if (!lower) continue;
    if (lower.startsWith(".") && domain.endsWith(lower)) {
      signals.push(`privileged_domain_suffix:${lower}`);
    } else if (domain === lower || domain.endsWith(`.${lower}`)) {
      signals.push(`privileged_domain_match:${lower}`);
    } else if (sender.includes(lower)) {
      signals.push(`privileged_domain_substr:${lower}`);
    }
  }

  // 3. Body markers (Rule 16(b)).
  if (input.body_plaintext) {
    const upper = input.body_plaintext.toUpperCase();
    for (const marker of PRIVILEGE_BODY_MARKERS) {
      if (upper.includes(marker)) {
        signals.push(`privilege_marker:${marker}`);
      }
    }
  }

  // For purpose of pre-classification, we treat "any signal beyond
  // own_counsel_allowlist" as "likely privileged".
  const otherSignals = signals.filter((s) => s !== "own_counsel_allowlist");
  return {
    is_own_counsel: isOwnCounsel,
    is_likely_privileged: otherSignals.length > 0 && !isOwnCounsel,
    matched_signals: signals,
  };
}
