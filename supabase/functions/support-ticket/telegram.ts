// supabase/functions/support-ticket/telegram.ts
// -----------------------------------------------------------------------------
// Pure helpers for the Telegram side of the support-ticket edge function.
//
// Kept in its own module so:
//   * the main handler stays small and readable
//   * the MarkdownV2 escape rules can be exercised in unit tests without
//     having to boot a Supabase client or hit the network
//   * a future support-ticket-retry cron can re-import sendTelegram / buildMessage
//
// Telegram MarkdownV2 rules:
//   https://core.telegram.org/bots/api#markdownv2-style
//
// EVERY character in the set `_*[]()~`>#+-=|{}.!\` MUST be backslash-escaped
// when used as literal text inside a MarkdownV2 message. Missing a single
// one will make Telegram return 400 "can't parse entities".
// -----------------------------------------------------------------------------

/** Characters that must be backslash-escaped inside MarkdownV2 text. */
const MD_V2 = /[_*\[\]()~`>#+\-=|{}.!\\]/g;

/**
 * Escape a string for safe inclusion in a Telegram MarkdownV2 message body.
 * Always pass user-supplied content through this before concatenating it
 * into the message; never trust messages, emails, or page URLs to be safe.
 */
export function escapeMarkdownV2(s: string | null | undefined): string {
  if (s === null || s === undefined) return "";
  return String(s).replace(MD_V2, "\\$&");
}

export interface BuildMessageInput {
  ticketId: string;
  category: string;
  contactChannel: string;
  email: string | null;
  userId: string | null;
  pageUrl: string;
  language: string;
  appVersion: string;
  message: string;
  /** Optional admin/ticket URL — appended as a MarkdownV2 inline link. */
  adminUrl?: string | null;
  // ── B2B inquiry extras ────────────────────────────────────────────────
  /** True when category === 'b2b_inquiry'; prepends `[B2B LEAD]` to title. */
  b2bLead?: boolean;
  /** Optional firm name from the modal (e.g. "Sirel & Partners"). */
  firmName?: string;
  /** Optional team size bucket from the modal (e.g. "5-20"). */
  teamSize?: string;
  /** Optional practices the firm focuses on (free-text or comma-joined list). */
  practices?: string;
}

/**
 * Build the MarkdownV2-formatted Telegram message body for a new ticket.
 * Returns a single string ready to drop into the Bot API `text` field.
 *
 * Each user-supplied substring is independently escaped to keep the
 * structural Markdown intact while preventing injection of bold/italic/etc.
 *
 * v2 (2026-05-25) — regulatory carve-out for B2B leads
 * ----------------------------------------------------
 * Telegram is a US-hosted commercial messenger and routing PII (name,
 * email, firm name) through it for the purposes of B2B lead capture sits
 * uncomfortably against GDPR Art. 5/6/28 (lawful basis + processor
 * choice). The 6-expert analyst consilium flagged this as RED.
 *
 * For B2B leads we still send a Telegram NOTIFICATION so the founders
 * know to triage, but we strip every PII bit: no email, no firm name,
 * no team size, no practices, no quoted message body. The full payload
 * is delivered separately to aiplacest@gmail.com via `sendB2bLeadEmail`
 * (Resend, EU-region API + processor under DPA).
 *
 * For regular (non-B2B) tickets nothing changes.
 */
export function buildTelegramMessage(input: BuildMessageInput): string {
  // B2B leads: notification-only mode. Tell the founders an inquiry has
  // arrived and where to find the details, but never ship PII through
  // Telegram. The `ticketId` short prefix is non-identifying; the admin
  // URL is gated behind founder auth.
  if (input.b2bLead) {
    const shortId = escapeMarkdownV2(input.ticketId.slice(0, 8));
    const lines: string[] = [
      `🟢 *\\[B2B LEAD\\] New inquiry*`,
      ``,
      `A new B2B lead has arrived\\.`,
      `Ticket: \`${shortId}\``,
      `Check email \\(aiplacest@gmail\\.com\\) for full details\\.`,
    ];
    if (input.adminUrl && input.adminUrl.length > 0) {
      const label = escapeMarkdownV2(`Open ticket #${input.ticketId.slice(0, 6)}`);
      const safeUrl = input.adminUrl.replace(/[)\\]/g, "");
      lines.push(``, `[${label}](${safeUrl})`);
    }
    return lines.join("\n");
  }

  const userLine = input.userId
    ? `${escapeMarkdownV2(input.email ?? "user")} (authenticated)`
    : input.email
    ? `${escapeMarkdownV2(input.email)} (anonymous)`
    : "anonymous";

  // Quote the user's message line-by-line: every line gets the `>` prefix.
  // Telegram's MarkdownV2 quote block is `>line\n>line2`.
  const quoted = escapeMarkdownV2(input.message)
    .split("\n")
    .map((l) => `>${l}`)
    .join("\n");

  const title = `🆘 *New Support Ticket*`;

  const lines: string[] = [
    title,
    ``,
    `*Category:* ${escapeMarkdownV2(input.category)}`,
    `*Channel:* ${escapeMarkdownV2(input.contactChannel)}`,
    `*User:* ${userLine}`,
    `*Page:* ${escapeMarkdownV2(input.pageUrl)}`,
    `*Language:* ${escapeMarkdownV2(input.language)}`,
    `*App version:* ${escapeMarkdownV2(input.appVersion)}`,
  ];

  lines.push(``, `*Message:*`, quoted);

  if (input.adminUrl && input.adminUrl.length > 0) {
    // The label text inside `[...]` also needs MarkdownV2 escaping.
    const shortId = input.ticketId.slice(0, 6);
    const label = escapeMarkdownV2(`Open ticket #${shortId}`);
    // URL inside `(...)` must escape `)` and `\` only — keep things simple by
    // refusing URLs that contain those characters (extremely unusual).
    const safeUrl = input.adminUrl.replace(/[)\\]/g, "");
    lines.push(``, `[${label}](${safeUrl})`);
  }

  return lines.join("\n");
}

// =============================================================================
// B2B lead email — full-fidelity delivery to founder inbox (v2 2026-05-25)
// =============================================================================
//
// Replaces Telegram as the carrier for B2B-lead PII. Posts a plain-text
// email via Resend (existing infrastructure — see send-email/index.ts for
// the same provider integration). Resend's free tier covers 100 emails/
// day which is comfortably above expected B2B-lead volume in launch month.
//
// The function NEVER throws on transport failure — the caller logs the
// error and the ticket row still has the full payload for offline triage.

export interface B2bLeadEmailInput {
  ticketId: string;
  email: string | null;
  firmName: string;
  teamSize: string;
  practices: string;
  message: string;
  pageUrl: string;
  language: string;
  ipAddress: string | null;
}

/**
 * Build the plain-text body for the B2B lead notification email. Pure
 * helper so unit tests can pin the wording without a network call.
 */
export function buildB2bLeadEmailBody(input: B2bLeadEmailInput): string {
  const lines: string[] = [
    "A new B2B lead has arrived via Advocat.",
    "",
    `Ticket ID:   ${input.ticketId}`,
    `Firm:        ${input.firmName || "(not provided)"}`,
    `Team size:   ${input.teamSize || "(not provided)"}`,
    `Practices:   ${input.practices || "(not provided)"}`,
    `Email:       ${input.email ?? "(not provided)"}`,
    `Language:    ${input.language}`,
    `Page:        ${input.pageUrl}`,
    `IP address:  ${input.ipAddress ?? "(not provided)"}`,
    `Received:    ${new Date().toISOString()}`,
    "",
    "Message:",
    input.message || "(empty)",
    "",
    "— Advocat support-ticket pipeline",
  ];
  return lines.join("\n");
}

/**
 * Build the subject line: `[B2B LEAD] <firm_name> — <team_size> lawyers`.
 * Handles missing firm/team gracefully so subject is never empty.
 */
export function buildB2bLeadEmailSubject(input: B2bLeadEmailInput): string {
  const firm = input.firmName && input.firmName.length > 0
    ? input.firmName
    : "(unknown firm)";
  const team = input.teamSize && input.teamSize.length > 0
    ? `${input.teamSize} lawyers`
    : "team size unknown";
  return `[B2B LEAD] ${firm} — ${team}`;
}

/**
 * Send a B2B-lead email via Resend. Returns true iff the API accepted
 * the request (HTTP 2xx). Returns false (with a console.warn) on any
 * non-2xx, missing API key, or thrown error.
 *
 * Implementation note: Resend's REST endpoint is `POST /emails` with a
 * Bearer token. We use the same `no-reply@advocat.ee` sender already
 * registered for `send-email/index.ts`.
 */
export async function sendB2bLeadEmail(args: {
  apiKey: string;
  from: string;
  to: string;
  subject: string;
  body: string;
}): Promise<boolean> {
  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${args.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: args.from,
        to: [args.to],
        subject: args.subject,
        text: args.body,
      }),
    });
    if (!res.ok) {
      const snippet = (await res.text().catch(() => "<no body>")).slice(0, 300);
      console.warn(`[support-ticket] resend ${res.status}: ${snippet}`);
      return false;
    }
    return true;
  } catch (e) {
    console.warn(
      `[support-ticket] resend threw: ${String(e).slice(0, 300)}`,
    );
    return false;
  }
}

/**
 * Send a MarkdownV2 message to a Telegram chat via the Bot API.
 * Throws on non-2xx so the caller can record the error string for triage.
 */
export async function sendTelegram(
  token: string,
  chatId: string,
  text: string,
): Promise<void> {
  const url = `https://api.telegram.org/bot${token}/sendMessage`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      chat_id: chatId,
      text,
      parse_mode: "MarkdownV2",
      disable_web_page_preview: true,
    }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => "<no body>");
    throw new Error(`telegram ${res.status}: ${body.slice(0, 300)}`);
  }
}

/**
 * Strip CR/LF characters from arbitrary user-supplied text. Used to keep
 * page URLs / user agents / etc. on a single line so they cannot break
 * out of a header line in the formatted Telegram message.
 */
export function scrubLineBreaks(s: string): string {
  return s.replace(/[\r\n]+/g, " ").trim();
}

/**
 * Sanitise the raw message body before storing or forwarding it. Trims
 * surrounding whitespace and removes lone \r characters (normalises
 * Windows-style CRLF to LF). Length validation is done by the caller.
 */
export function sanitiseMessage(raw: string): string {
  return raw.replace(/\r\n?/g, "\n").trim();
}
