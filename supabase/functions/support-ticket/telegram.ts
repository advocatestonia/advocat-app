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
 */
export function buildTelegramMessage(input: BuildMessageInput): string {
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

  // Title — B2B inquiries get a high-signal `[B2B LEAD]` prefix so the
  // Telegram group can triage them differently from regular support.
  const title = input.b2bLead
    ? `🟢 *\\[B2B LEAD\\] New Support Ticket*`
    : `🆘 *New Support Ticket*`;

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

  // B2B-only firm details. Render compactly, only when populated, before
  // the message body so the Telegram preview shows them above the fold.
  if (input.b2bLead) {
    if (input.firmName && input.firmName.length > 0) {
      lines.push(`*Firm:* ${escapeMarkdownV2(input.firmName)}`);
    }
    if (input.teamSize && input.teamSize.length > 0) {
      lines.push(`*Team size:* ${escapeMarkdownV2(input.teamSize)}`);
    }
    if (input.practices && input.practices.length > 0) {
      lines.push(`*Practices:* ${escapeMarkdownV2(input.practices)}`);
    }
  }

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
