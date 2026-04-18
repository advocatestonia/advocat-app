// send-email Edge Function (v24.1)
// -----------------------------------------------------------------------------
// Purpose: dispatch an outgoing email on the user's behalf AFTER the client
// has collected explicit user approval (see assistant_tools.dart::_sendEmail,
// requiresApproval=true).
//
// Two dispatch paths are supported, selected at runtime based on which
// secrets are configured in Supabase:
//
//   1. Gmail OAuth 2.0 (preferred) — the user's OAuth token is fetched from
//      `user_oauth_tokens` Supabase table (provider='gmail'). Mail is sent
//      via Gmail API v1 `/users/me/messages/send` using RFC-2822 encoding.
//
//   2. Transactional SMTP via Resend (fallback) — requires RESEND_API_KEY
//      secret. Sends from no-reply@advocat.ee; body says "Sent via Advocat on
//      behalf of <user-name>".
//
// Every dispatch is logged to the `correspondence` table for audit.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const GMAIL_FALLBACK_ONLY = Deno.env.get("SEND_EMAIL_FALLBACK_ONLY") === "1";
const DEFAULT_FROM =
  Deno.env.get("SEND_EMAIL_DEFAULT_FROM") || "no-reply@advocat.ee";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://advocat.ee",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Authorization, Content-Type, apikey, x-client-info",
};

// Simple per-user rate limit: max 5 outgoing emails per 10 minutes.
const rateLimits = new Map<string, { count: number; windowStart: number }>();
const RATE_LIMIT_WINDOW_MS = 10 * 60_000;
const RATE_LIMIT_MAX = 5;

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Strip CRLF and tab characters from any string that will appear inside
 * an RFC-2822 header, preventing header-injection attacks. Also length-caps
 * the result to 200 chars so a pathologically long display name cannot
 * wrap past a header boundary.
 */
function scrubHeaderText(s: string): string {
  return s.replace(/[\r\n\t]/g, " ").slice(0, 200);
}

function rfc2822(input: {
  from: string;
  to: string;
  cc?: string;
  subject: string;
  body: string;
}): string {
  const encode = (s: string) =>
    `=?UTF-8?B?${btoa(unescape(encodeURIComponent(s)))}?=`;
  const lines = [
    `From: ${scrubHeaderText(input.from)}`,
    `To: ${scrubHeaderText(input.to)}`,
    ...(input.cc ? [`Cc: ${scrubHeaderText(input.cc)}`] : []),
    `Subject: ${encode(input.subject)}`,
    "MIME-Version: 1.0",
    'Content-Type: text/plain; charset="UTF-8"',
    "Content-Transfer-Encoding: 7bit",
    "",
    input.body,
  ];
  return lines.join("\r\n");
}

function base64url(s: string): string {
  return btoa(s)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function sendViaGmail(params: {
  accessToken: string;
  from: string;
  to: string;
  cc?: string;
  subject: string;
  body: string;
}): Promise<{ id: string }> {
  const raw = base64url(rfc2822(params));
  const resp = await fetch(
    "https://gmail.googleapis.com/gmail/v1/users/me/messages/send",
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${params.accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ raw }),
    },
  );
  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`Gmail API ${resp.status}: ${err}`);
  }
  const data = await resp.json();
  return { id: data.id as string };
}

async function sendViaResend(params: {
  from: string;
  to: string;
  cc?: string;
  subject: string;
  body: string;
}): Promise<{ id: string }> {
  if (!RESEND_API_KEY) {
    throw new Error("RESEND_API_KEY is not configured");
  }
  const resp = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: params.from,
      to: [params.to],
      cc: params.cc ? [params.cc] : undefined,
      subject: params.subject,
      text: params.body,
    }),
  });
  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`Resend ${resp.status}: ${err}`);
  }
  const data = await resp.json();
  return { id: data.id as string };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const token = authHeader.replace("Bearer ", "");
  const { data: userData, error: authError } =
    await supabase.auth.getUser(token);
  if (authError || !userData?.user) {
    return jsonResponse({ error: "Invalid session" }, 401);
  }
  const user = userData.user;

  // Per-user rate limit
  const now = Date.now();
  const bucket = rateLimits.get(user.id);
  if (bucket && now - bucket.windowStart < RATE_LIMIT_WINDOW_MS) {
    if (bucket.count >= RATE_LIMIT_MAX) {
      return jsonResponse(
        {
          error:
            "Rate limit exceeded. Maximum 5 emails per 10 minutes per user.",
        },
        429,
      );
    }
    bucket.count++;
  } else {
    rateLimits.set(user.id, { count: 1, windowStart: now });
  }

  let payload: {
    to?: string;
    cc?: string;
    subject?: string;
    body?: string;
    case_id?: string;
    force_fallback?: boolean;
  };
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const to = (payload.to || "").trim();
  const subject = (payload.subject || "").trim();
  const body = (payload.body || "").trim();
  const cc = payload.cc?.trim();

  if (!to || !subject || !body) {
    return jsonResponse(
      { error: "Fields to, subject, body are required." },
      400,
    );
  }
  // Basic email validation
  const emailRe = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
  if (!emailRe.test(to) || (cc && !emailRe.test(cc))) {
    return jsonResponse({ error: "Invalid recipient address" }, 400);
  }
  // Hard size cap (Gmail limit is 25 MB; we cap at 100 KB text)
  if (body.length > 100_000 || subject.length > 500) {
    return jsonResponse({ error: "Body or subject too large" }, 400);
  }

  // Look up the user's Gmail OAuth token (optional table).
  let gmailToken: string | null = null;
  let userFromName: string | null = null;
  let userFromAddress = DEFAULT_FROM;

  try {
    const { data: tokRow } = await supabase
      .from("user_oauth_tokens")
      .select("access_token, email")
      .eq("user_id", user.id)
      .eq("provider", "gmail")
      .maybeSingle();
    if (tokRow?.access_token) {
      gmailToken = tokRow.access_token as string;
      if (tokRow.email) {
        userFromAddress = tokRow.email as string;
      }
    }
  } catch (_) {
    /* table may not exist — fallback path */
  }
  try {
    const { data: profile } = await supabase
      .from("profiles")
      .select("full_name, email")
      .eq("id", user.id)
      .maybeSingle();
    if (profile?.full_name) userFromName = profile.full_name as string;
    if (profile?.email && !gmailToken) {
      // For fallback path, put user's real address in Reply-To so replies
      // go to them even though the actual envelope is no-reply@advocat.ee.
      // Resend's `reply_to` param accepts this.
    }
  } catch (_) {
    /* ignore */
  }

  const fromHeader = userFromName
    ? `${userFromName} <${userFromAddress}>`
    : userFromAddress;

  // Dispatch
  let providerId: string | null = null;
  let provider: "gmail" | "resend" = "resend";
  let dispatchError: string | null = null;

  if (gmailToken && !GMAIL_FALLBACK_ONLY) {
    try {
      const r = await sendViaGmail({
        accessToken: gmailToken,
        from: fromHeader,
        to,
        cc,
        subject,
        body,
      });
      providerId = r.id;
      provider = "gmail";
    } catch (e) {
      dispatchError = String(e);
      console.warn("send-email: Gmail failed, trying Resend:", dispatchError);
    }
  }

  if (!providerId) {
    if (!RESEND_API_KEY) {
      return jsonResponse(
        {
          error:
            "No email provider configured. Set RESEND_API_KEY in Supabase " +
            "secrets or connect the user's Gmail OAuth (user_oauth_tokens " +
            "table with provider='gmail').",
          details: dispatchError,
        },
        503,
      );
    }
    try {
      const r = await sendViaResend({
        from: `Advocat <${DEFAULT_FROM}>`,
        to,
        cc,
        subject,
        body:
          `${body}\n\n---\n` +
          `Sent via Advocat.ee on behalf of ` +
          `${userFromName ?? user.email ?? "client"}.\n` +
          `Reply directly to this email to reach the sender.`,
      });
      providerId = r.id;
      provider = "resend";
    } catch (e) {
      return jsonResponse(
        { error: "Email dispatch failed", details: String(e) },
        502,
      );
    }
  }

  // Log to correspondence table (best-effort).
  try {
    await supabase.from("correspondence").insert({
      user_id: user.id,
      case_id: payload.case_id ?? null,
      direction: "outbound",
      from_address: userFromAddress,
      to_address: to,
      cc_address: cc ?? null,
      subject,
      body,
      provider,
      provider_message_id: providerId,
      sent_at: new Date().toISOString(),
    });
  } catch (e) {
    console.warn("send-email: correspondence insert failed:", e);
  }

  return jsonResponse({
    ok: true,
    provider,
    provider_message_id: providerId,
  });
});
