// support-ticket Edge Function
// -----------------------------------------------------------------------------
// Receives a single support ticket from the in-app SupportFab widget (or any
// authenticated/anonymous client), persists it to public.support_tickets,
// and best-effort notifies a Telegram group with Dmitri + Sofia.
//
// Design constraints:
//   * Visible on every screen, including landing/anon — anonymous submission
//     must work. Abuse is contained by the shared rate limiter (per-IP for
//     anon, per-user for authenticated).
//   * Telegram is a notification channel only. If TELEGRAM_BOT_TOKEN or
//     TELEGRAM_CHAT_ID is unset OR the API call fails, the ticket is still
//     persisted and the user still sees success.
//   * Honeypot: a hidden form field `_hp` must be empty. Bots that fill
//     every input field get an immediate 400 with no DB write.
//   * Anti-injection: every user-supplied string is length-capped, CRLFs
//     stripped, and MarkdownV2-escaped before reaching the Telegram message
//     body. See telegram.ts for the escape rules.
//
// CORS: advocat.ee only (inherited from _shared/auth.ts).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { checkAndRecordRateLimit } from "../_shared/rate_limit.ts";
import {
  buildB2bLeadEmailBody,
  buildB2bLeadEmailSubject,
  buildTelegramMessage,
  sanitiseMessage,
  scrubLineBreaks,
  sendB2bLeadEmail,
  sendTelegram,
} from "./telegram.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN") ?? "";
const TELEGRAM_CHAT_ID = Deno.env.get("TELEGRAM_CHAT_ID") ?? "";
const ADMIN_URL_BASE = Deno.env.get("ADVOCAT_ADMIN_TICKETS_URL") ??
  "https://advocat.ee/admin/tickets";
// v2 (2026-05-25): B2B leads are delivered to the founder inbox via
// Resend rather than (or in addition to) Telegram, per the regulatory
// analyst's RED finding on routing PII through US-hosted messengers.
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const B2B_LEAD_EMAIL_FROM =
  Deno.env.get("B2B_LEAD_EMAIL_FROM") ?? "no-reply@advocat.ee";
const B2B_LEAD_EMAIL_TO =
  Deno.env.get("B2B_LEAD_EMAIL_TO") ?? "aiplacest@gmail.com";

const VALID_CATEGORIES = new Set([
  "bug",
  "payment",
  "question",
  "feature",
  "other",
  // 2026-05-26 (B2B lead detection): the inbound modal in the Flutter app
  // dedicates a path for "Talk to Sales" from law-firm prospects. The
  // ticket payload re-uses the support-ticket pipeline (auth, validation,
  // Telegram dispatch) and is distinguished server-side by the `[B2B LEAD]`
  // Telegram prefix and the firm_name / team_size / practices fields.
  "b2b_inquiry",
]);
const VALID_CHANNELS = new Set(["in_app", "whatsapp", "email"]);
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const MESSAGE_MIN = 10;
const MESSAGE_MAX = 2000;

/**
 * Type guard for the request body. Everything is optional from the client's
 * perspective — the handler validates each field individually so we can
 * return precise error codes.
 */
interface RawBody {
  message?: unknown;
  category?: unknown;
  email?: unknown;
  contact_channel?: unknown;
  page_url?: unknown;
  app_version?: unknown;
  language?: unknown;
  // Honeypot — must be empty. Named `_hp` per design doc.
  _hp?: unknown;
  // ── B2B inquiry extras (only when category === 'b2b_inquiry') ─────────
  firm_name?: unknown;
  team_size?: unknown;
  practices?: unknown;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Rate limit gate — authenticated 10/min (well above the 10/day product
  // limit so we can still respond to the form even if the user retries),
  // anonymous 1/min by IP. The product-level daily quota is enforced in the
  // DB count below; this gate protects against burst-flood.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "support-ticket",
    maxPerMinute: 10,
    anonymousPerMinute: 1,
  });
  if (gate.kind === "deny") return gate.response;

  const principalId = gate.user.id;
  // Anonymous principals get IDs like `anon:<ip>`. We never write that
  // string into a uuid column — we leave user_id NULL instead.
  const isAuthenticated = !principalId.startsWith("anon:");
  const anonIp = principalId.startsWith("anon:")
    ? principalId.slice("anon:".length)
    : null;

  // Anon abuse burst gate (DB-backed sliding 60s window via shared util).
  // The per-minute soft gate in requireUserWithRateLimit is in-process and
  // can be bypassed by an attacker who burns cold starts.  The shared
  // hit_rate_limit RPC is authoritative across replicas.  Bucketed by IP
  // so each abuser only hurts themselves.  The 5/day enforcement happens
  // against the support_tickets row count below — this is just the burst
  // guard.
  if (!isAuthenticated && anonIp) {
    const anonBurst = await checkAndRecordRateLimit({
      bucket: "support_anon",
      principal: `support_anon:${anonIp}`,
      maxPerMinute: 5,
    });
    if (!anonBurst.allowed) {
      return jsonError("Too many submissions", 429, {
        reason: "rate_limited",
        retry_after_sec: 60,
      });
    }
  }

  // Parse body.
  let raw: RawBody;
  try {
    raw = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  // Honeypot: silent reject. Bots that POST every named field will fail here.
  // We return 400 with a generic shape — see test HP-T1.
  const hp = typeof raw._hp === "string" ? raw._hp : "";
  if (hp.length > 0) {
    return jsonError("Invalid submission", 400, { reason: "honeypot" });
  }

  // Validate message.
  const rawMessage = typeof raw.message === "string" ? raw.message : "";
  const message = sanitiseMessage(rawMessage);
  if (message.length < MESSAGE_MIN) {
    return jsonError("Message too short", 400, {
      reason: "too_short",
      min: MESSAGE_MIN,
    });
  }
  if (message.length > MESSAGE_MAX) {
    return jsonError("Message too long", 400, {
      reason: "too_long",
      max: MESSAGE_MAX,
    });
  }

  // Validate category (default to 'other' rather than rejecting unknowns).
  const category = typeof raw.category === "string" &&
      VALID_CATEGORIES.has(raw.category)
    ? raw.category
    : "other";

  // Validate channel (default 'in_app').
  const contactChannel = typeof raw.contact_channel === "string" &&
      VALID_CHANNELS.has(raw.contact_channel)
    ? raw.contact_channel
    : "in_app";

  // Validate email (optional).
  const emailRaw = typeof raw.email === "string"
    ? raw.email.trim().toLowerCase().slice(0, 254)
    : "";
  let email: string | null = null;
  if (emailRaw.length > 0) {
    if (!EMAIL_RE.test(emailRaw)) {
      return jsonError("Invalid email", 400, { reason: "bad_email" });
    }
    email = emailRaw;
  }

  // B2B inquiry metadata — only populated when category === 'b2b_inquiry'.
  // Length-capped to keep the Telegram header line readable. NULL-safe so
  // the Telegram builder can skip empty lines.
  const isB2bInquiry = category === "b2b_inquiry";
  const firmName = isB2bInquiry
    ? scrubLineBreaks(typeof raw.firm_name === "string" ? raw.firm_name : "")
        .slice(0, 120)
    : "";
  const teamSize = isB2bInquiry
    ? scrubLineBreaks(typeof raw.team_size === "string" ? raw.team_size : "")
        .slice(0, 40)
    : "";
  // `practices` may arrive as a string ("dispute, IP") or an array; normalise.
  let practices = "";
  if (isB2bInquiry) {
    if (typeof raw.practices === "string") {
      practices = scrubLineBreaks(raw.practices).slice(0, 240);
    } else if (Array.isArray(raw.practices)) {
      practices = scrubLineBreaks(
        raw.practices
          .filter((p): p is string => typeof p === "string")
          .map((p) => p.trim())
          .filter((p) => p.length > 0)
          .join(", "),
      ).slice(0, 240);
    }
  }

  // Capture metadata (length-capped, line-break-scrubbed).
  const pageUrl = scrubLineBreaks(
    typeof raw.page_url === "string" ? raw.page_url : "",
  ).slice(0, 1000);
  const appVersion = scrubLineBreaks(
    typeof raw.app_version === "string" ? raw.app_version : "unknown",
  ).slice(0, 64);
  const language = scrubLineBreaks(
    typeof raw.language === "string" ? raw.language : "en",
  ).slice(0, 8);
  const userAgent = scrubLineBreaks(req.headers.get("user-agent") ?? "").slice(
    0,
    500,
  );
  // SECURITY: use the gate's HARDENED client IP (x-real-ip preferred; XFF
  // honoured only under TRUST_XFF), NOT the raw spoofable x-forwarded-for
  // leftmost. The anon 5/24h cap below COUNTs by `anonIp` (this same hardened
  // value), so the stored ip_address MUST match it. If we wrote the spoofable
  // XFF here while counting by the hardened IP, an attacker could rotate the
  // XFF header to store every row under a different ip_address than the one
  // the cap query matches — defeating the daily cap entirely.
  const ipAddress = anonIp ??
    ((req.headers.get("x-real-ip") ?? "").trim() || null);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // Per-user daily cap (10 tickets / 24h) for authenticated users.
  // Anon callers get a stricter 5 tickets / 24h / IP cap below.
  if (isAuthenticated) {
    const since = new Date(Date.now() - 24 * 60 * 60_000).toISOString();
    const { count } = await supabase
      .from("support_tickets")
      .select("id", { count: "exact", head: true })
      .eq("user_id", principalId)
      .gte("created_at", since);
    if ((count ?? 0) >= 10) {
      return jsonError("Daily ticket limit reached", 429, {
        reason: "rate_limited",
        retry_after_sec: 86400,
      });
    }
  } else if (anonIp) {
    // Anon daily cap: 5 tickets / 24h / IP.  Counted against the
    // ip_address column, NULL-safe — anon rows always have user_id=NULL
    // and ip_address set from the HARDENED client IP (anonIp), which is the
    // same value this query matches on, so the cap cannot be sidestepped by
    // spoofing x-forwarded-for.
    const since = new Date(Date.now() - 24 * 60 * 60_000).toISOString();
    const { count } = await supabase
      .from("support_tickets")
      .select("id", { count: "exact", head: true })
      .is("user_id", null)
      .eq("ip_address", anonIp)
      .gte("created_at", since);
    if ((count ?? 0) >= 5) {
      return jsonError("Daily ticket limit reached", 429, {
        reason: "rate_limited",
        retry_after_sec: 86400,
      });
    }
  }

  // Insert the ticket.
  const { data: inserted, error: insErr } = await supabase
    .from("support_tickets")
    .insert({
      user_id: isAuthenticated ? principalId : null,
      email,
      category,
      message,
      contact_channel: contactChannel,
      user_agent: userAgent,
      page_url: pageUrl,
      app_version: appVersion,
      language,
      ip_address: ipAddress,
      // telegram_sent defaults to false; we update it below if delivery succeeds.
    })
    .select("id")
    .single();

  if (insErr || !inserted) {
    // Log internals server-side only; do not leak DB error text to the client.
    console.error("[support-ticket] insert failed:", insErr);
    return jsonError("Could not save ticket", 500, {
      reason: "db_failed",
    });
  }
  const ticketId = inserted.id as string;

  // Best-effort Telegram notify. If secrets are missing, we just log and
  // skip — the ticket is already safe in the DB.
  //
  // v2 (2026-05-25) — for B2B leads we still ping Telegram so the founders
  // know to triage, but the payload is PII-stripped (see telegram.ts).
  // The full PII payload is delivered separately by `sendB2bLeadEmail`
  // below to the founder inbox via Resend.
  let telegramSent = false;
  let telegramError: string | null = null;

  if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
    try {
      const text = buildTelegramMessage({
        ticketId,
        category,
        contactChannel,
        email,
        userId: isAuthenticated ? principalId : null,
        pageUrl,
        language,
        appVersion,
        message,
        adminUrl: `${ADMIN_URL_BASE}/${ticketId}`,
        // v2: B2B-lead flag triggers the PII-stripped notification body.
        // firmName/teamSize/practices are NO LONGER passed — they ride
        // exclusively in the Resend email below.
        b2bLead: isB2bInquiry,
      });
      await sendTelegram(TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, text);
      telegramSent = true;
    } catch (e) {
      telegramError = String(e).slice(0, 500);
      console.warn(`[support-ticket] telegram failed: ${telegramError}`);
    }

    // Persist Telegram delivery state. Don't fail the user request on
    // a follow-up write error — the row is already inserted.
    try {
      await supabase
        .from("support_tickets")
        .update({
          telegram_sent: telegramSent,
          telegram_error: telegramError,
        })
        .eq("id", ticketId);
    } catch (e) {
      console.warn("[support-ticket] telegram-state update failed:", e);
    }
  } else {
    console.log(
      `[support-ticket] telegram secrets not configured — ticket ${ticketId} saved without notify`,
    );
  }

  // ── B2B-lead full-fidelity email (v2 2026-05-25) ─────────────────────
  // Replaces Telegram as the carrier for PII. Fires only for
  // category=b2b_inquiry. Best-effort: a failed send does not affect the
  // client response (the ticket row already has the full payload).
  if (isB2bInquiry) {
    if (RESEND_API_KEY) {
      try {
        const leadEmailInput = {
          ticketId,
          email,
          firmName,
          teamSize,
          practices,
          message,
          pageUrl,
          language,
          ipAddress,
        };
        const ok = await sendB2bLeadEmail({
          apiKey: RESEND_API_KEY,
          from: B2B_LEAD_EMAIL_FROM,
          to: B2B_LEAD_EMAIL_TO,
          subject: buildB2bLeadEmailSubject(leadEmailInput),
          body: buildB2bLeadEmailBody(leadEmailInput),
        });
        if (!ok) {
          console.warn(
            `[support-ticket] B2B lead email send failed for ticket ${ticketId}`,
          );
        }
      } catch (e) {
        console.warn(
          `[support-ticket] B2B lead email threw: ${String(e).slice(0, 300)}`,
        );
      }
    } else {
      console.warn(
        `[support-ticket] RESEND_API_KEY not configured — B2B lead ${ticketId} ` +
          "saved without email (founders should triage via DB).",
      );
    }
  }

  return jsonOk({ ok: true, ticket_id: ticketId });
});
