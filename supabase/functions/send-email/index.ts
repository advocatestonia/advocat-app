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
import { createClient } from "@supabase/supabase-js";
import {
  corsHeaders,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  buildRefreshRequestBody,
  computeNewExpiry,
  type GoogleRefreshResponse,
  shouldRefresh,
  type TokenRow,
} from "./token_refresh.ts";
import {
  APPROXIMATE_FOOTER_BYTES,
  AUTHORITY_RATE_LIMIT_24H,
  classifyRecipient,
  composeDisclosureFooter,
  type UserLocale,
} from "../_shared/outbound_compliance.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const GMAIL_FALLBACK_ONLY = Deno.env.get("SEND_EMAIL_FALLBACK_ONLY") === "1";
const DEFAULT_FROM =
  Deno.env.get("SEND_EMAIL_DEFAULT_FROM") || "support@advocat.ee";
const GOOGLE_CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID");
const GOOGLE_CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET");

// SECURITY (Wave-1 2026-05-28, audit P0-01/P0-02):
// The previous in-isolate `Map<string, ...>` rate limiter was reset on every
// Deno cold start, so an attacker who hit the function across N isolates
// got 5×N effective sends per 10-min window — Resend / Gmail abuse vector.
// The bare `supabase.auth.getUser(token)` also accepted any non-error
// response, missing the U1 role/aud check that catches forged JWTs.
//
// Both holes are now closed by `requireUserWithRateLimit` (postgres-backed
// limiter + role/aud check in _shared/auth.ts).  Cap of 1/min preserves the
// 5-per-10-min envelope of the legacy limiter.
const RATE_LIMIT_MAX_PER_MINUTE = 1;

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

// 15s upper bound on outbound provider calls. Without an explicit AbortSignal,
// a stuck provider would hang until Supabase's wall-clock cap (~150s) and burn
// the user's send-attempt.
const PROVIDER_FETCH_TIMEOUT_MS = 15_000;

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
      signal: AbortSignal.timeout(PROVIDER_FETCH_TIMEOUT_MS),
    },
  );
  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`Gmail API ${resp.status}: ${err}`);
  }
  const data = await resp.json();
  return { id: data.id as string };
}

/**
 * Refresh a Gmail access token via Google's OAuth endpoint and persist the
 * new token + expiry back to user_oauth_tokens. Returns the new access_token
 * on success, or null on failure (caller falls back to Resend).
 *
 * Side effect: updates public.user_oauth_tokens row keyed by (user_id, gmail).
 */
async function tryRefreshGmailToken(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  refreshToken: string,
): Promise<string | null> {
  if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    console.warn(
      "send-email: cannot refresh — GOOGLE_CLIENT_ID/SECRET not configured.",
    );
    return null;
  }
  let resp: Response;
  try {
    resp = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: buildRefreshRequestBody({
        clientId: GOOGLE_CLIENT_ID,
        clientSecret: GOOGLE_CLIENT_SECRET,
        refreshToken,
      }),
      signal: AbortSignal.timeout(10_000),
    });
  } catch (e) {
    console.warn("send-email: refresh fetch failed:", String(e));
    return null;
  }
  if (!resp.ok) {
    const body = await resp.text();
    console.warn(`send-email: refresh ${resp.status} — ${body}`);
    return null;
  }
  let data: GoogleRefreshResponse;
  try {
    data = await resp.json();
  } catch (e) {
    console.warn("send-email: refresh JSON parse failed:", String(e));
    return null;
  }
  if (!data.access_token) {
    console.warn("send-email: refresh response missing access_token", data);
    return null;
  }
  const newExpiresAt = computeNewExpiry(data, Date.now());
  try {
    await supabase
      .from("user_oauth_tokens")
      .update({
        access_token: data.access_token,
        expires_at: newExpiresAt,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", userId)
      .eq("provider", "gmail");
  } catch (e) {
    console.warn("send-email: failed to persist refreshed token:", String(e));
    // Token still works for this request even if persistence failed.
  }
  return data.access_token;
}

async function sendViaResend(params: {
  from: string;
  to: string;
  cc?: string;
  subject: string;
  body: string;
  replyTo?: string;
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
      reply_to: params.replyTo || undefined,
    }),
    signal: AbortSignal.timeout(PROVIDER_FETCH_TIMEOUT_MS),
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

  // SECURITY (Wave-1 2026-05-28, audit P0-01 + P0-02):
  // Single gate replaces the previous inline `getUser` (no role/aud check —
  // U1 regression class) AND the per-isolate `Map` rate limiter (cold-start
  // bypass).  `requireUserWithRateLimit` calls the postgres-backed
  // `consume_rate_limit` RPC + enforces `role/aud === "authenticated"`.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "send-email",
    maxPerMinute: RATE_LIMIT_MAX_PER_MINUTE,
  });
  if (gate.kind === "deny") return gate.response;
  const user = { id: gate.user.id, email: gate.user.email };

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  let payload: {
    to?: string;
    cc?: string;
    subject?: string;
    body?: string;
    case_id?: string;
    force_fallback?: boolean;
    // When true, omit the "Sent via Advocat.ee on behalf of …" footer on the
    // Resend fallback path. Used for case correspondence where the footer
    // wrongly signals to a recipient (e.g. the user's own lawyer) that a third
    // party is operating the mailbox. The user's real address still rides in
    // Reply-To, so the disclosure is preserved without the footer noise.
    suppress_footer?: boolean;
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

  // SECURITY (Wave-1 2026-05-28, audit P0-04 — IDOR on correspondence):
  // The previous handler accepted caller-supplied `case_id` and wrote it
  // straight into `correspondence.case_id` + passed it to
  // `record_case_event` with no ownership check. Free-tier attacker could
  // pollute another user's case timeline with fake outbound email events
  // — evidence-tampering on a legal platform.
  //
  // The case_id column references `public.cases` for `correspondence`, and
  // `record_case_event` (case_timeline_events) joins against
  // `public.user_cases`. We accept ownership in EITHER table since the
  // chat client / agent loop write to whichever is the active case for
  // the user.  Both lookups are scoped to `user_id = caller`.
  if (payload.case_id) {
    if (typeof payload.case_id !== "string") {
      return jsonResponse({ error: "case_id must be a string" }, 400);
    }
    let ownsCase = false;
    try {
      const [b2c, pkg2] = await Promise.all([
        supabase
          .from("cases")
          .select("id")
          .eq("id", payload.case_id)
          .eq("user_id", user.id)
          .maybeSingle(),
        supabase
          .from("user_cases")
          .select("id")
          .eq("id", payload.case_id)
          .eq("user_id", user.id)
          .maybeSingle(),
      ]);
      ownsCase = !!(b2c.data?.id) || !!(pkg2.data?.id);
    } catch (e) {
      console.warn(
        "send-email: case ownership lookup failed:",
        String(e).slice(0, 200),
      );
    }
    if (!ownsCase) {
      return jsonResponse(
        { error: "case_id not owned by caller" },
        403,
      );
    }
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
      .select("access_token, refresh_token, email, expires_at")
      .eq("user_id", user.id)
      .eq("provider", "gmail")
      .maybeSingle();
    if (tokRow?.access_token) {
      gmailToken = tokRow.access_token as string;
      if (tokRow.email) {
        userFromAddress = tokRow.email as string;
      }
      // Refresh proactively if the token is expired or expiring soon. We do
      // this BEFORE the Gmail API call so a slow refresh doesn't burn the
      // user's send-attempt with a 401 and make us look broken.
      const row: TokenRow = {
        access_token: tokRow.access_token as string,
        refresh_token: (tokRow.refresh_token as string | null) ?? null,
        expires_at: (tokRow.expires_at as string | null) ?? null,
      };
      if (shouldRefresh(row, Date.now())) {
        const refreshed = await tryRefreshGmailToken(
          supabase,
          user.id,
          row.refresh_token as string,
        );
        if (refreshed) {
          gmailToken = refreshed;
        } else {
          // Refresh failed — drop the token so we fall back to Resend rather
          // than calling Gmail with a known-stale bearer.
          gmailToken = null;
        }
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

  // ──────────────────────────────────────────────────────────────────────
  // WAVE-1 UPL COMPLIANCE (audit 08 §1.6 + 09 §P0-EE-2 + 05 F-004/F-006)
  // Coordination memory key: swarm/security_audit_2026-05-28/wave1/email_agent
  //
  // Classify the recipient. If non-standard, append the disclosure footer
  // BEFORE dispatch — the footer lives at ingress (here) rather than in
  // the model's output so prompt injection cannot suppress or rewrite it.
  // For fi_/ee_authority recipients we also apply:
  //   - 3 sends / 24h rate cap (audit 08 §9.2)
  //   - hard-reject if body+footer would exceed 100K body cap
  // Locale fetched from profiles.preferred_language; English fallback.
  // ──────────────────────────────────────────────────────────────────────
  const classification = classifyRecipient([to, ...(cc ? [cc] : [])]);
  let composedBody = body;

  if (classification.class === "denied") {
    return jsonResponse(
      {
        error: "recipient_denied_by_compliance",
        reasons: classification.reasons,
      },
      400,
    );
  }

  if (classification.class !== "standard") {
    // Resolve user locale for footer wording.
    let userLocale: UserLocale = "en";
    try {
      const { data: prefRow } = await supabase
        .from("profiles")
        .select("preferred_language")
        .eq("id", user.id)
        .maybeSingle();
      const raw = (prefRow?.preferred_language as string | null) ?? "en";
      const norm = raw.toLowerCase().slice(0, 2);
      if (norm === "fi" || norm === "et" || norm === "ru" || norm === "en") {
        userLocale = norm;
      }
    } catch (_) {
      /* fallback to en */
    }

    const footer = composeDisclosureFooter(
      userLocale,
      classification.class,
      userFromName ?? user.email ?? "—",
    );

    // Hard-reject if body+footer would breach the 100 KB cap (audit 08
    // §1.6.2 — "reject if disclosure footer would NOT fit"). We refuse
    // rather than silently truncate the body or the footer.
    if (body.length + footer.length > 100_000) {
      return jsonResponse(
        {
          error: "body_too_long_for_required_disclosure_footer",
          footer_bytes: footer.length,
          body_bytes: body.length,
          recipient_class: classification.class,
        },
        413,
      );
    }
    composedBody = body + footer;
  }

  if (
    classification.class === "fi_authority" ||
    classification.class === "ee_authority"
  ) {
    // 3-msg / 24h cap for authority recipients. Counts past outbound to
    // ANY recipient classified the same way. We query the correspondence
    // table; failures fail-open by design (one false positive per 24h
    // is preferable to blocking legitimate KHO-deadline-day traffic if
    // the DB blips), but log the gap so observability catches it.
    try {
      const since = new Date(Date.now() - 24 * 60 * 60 * 1_000).toISOString();
      const { data: past, error: pastErr } = await supabase
        .from("correspondence")
        .select("to_address, sent_at")
        .eq("user_id", user.id)
        .eq("direction", "outbound")
        .gte("sent_at", since)
        .limit(50);
      if (!pastErr && Array.isArray(past)) {
        let authorityCount = 0;
        for (const row of past) {
          const addr = (row.to_address as string | null) ?? "";
          if (!addr) continue;
          const cls = classifyRecipient([addr]);
          if (
            cls.class === "fi_authority" || cls.class === "ee_authority"
          ) {
            authorityCount++;
          }
        }
        if (authorityCount >= AUTHORITY_RATE_LIMIT_24H) {
          return jsonResponse(
            {
              error: "authority_rate_limit_24h_exceeded",
              recipient_class: classification.class,
              limit: AUTHORITY_RATE_LIMIT_24H,
              window_hours: 24,
            },
            429,
          );
        }
      }
    } catch (e) {
      console.warn(
        "send-email: authority rate-limit lookup failed (fail-open):",
        String(e).slice(0, 200),
      );
    }
    // Reference for downstream observers — keep APPROXIMATE_FOOTER_BYTES
    // out of the build-warning path even when unused.
    void APPROXIMATE_FOOTER_BYTES;
  }
  // Hand the composed body to the dispatcher.
  // ──────────────────────────────────────────────────────────────────────

  // Dispatch.
  //
  // The `provider` value below is what we write to the correspondence audit
  // log. We intentionally distinguish:
  //
  //   - "gmail_user"     — sent via the user's own Gmail OAuth token.
  //                        GDPR posture: Advocat is a *processor* (the user
  //                        is the controller of their own outbound mail).
  //   - "resend_fallback" — sent via Advocat's Resend account.
  //                        GDPR posture: Advocat is a *controller*. The user
  //                        is informed via the "Sent on behalf of" footer.
  //
  // This split is load-bearing for compliance: a future audit must be able
  // to tell which messages we processed for the user vs which we sent
  // ourselves.
  let providerId: string | null = null;
  let provider: "gmail_user" | "resend_fallback" = "resend_fallback";
  let dispatchError: string | null = null;

  if (gmailToken && !GMAIL_FALLBACK_ONLY) {
    try {
      const r = await sendViaGmail({
        accessToken: gmailToken,
        from: fromHeader,
        to,
        cc,
        subject,
        body: composedBody,
      });
      providerId = r.id;
      provider = "gmail_user";
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
      // Reply-To carries the user's real address so the recipient's reply
      // reaches the sender directly, not Advocat's no-reply mailbox. This is
      // the disclosure mechanism that lets us suppress the visible footer for
      // case correspondence without losing "who to reply to".
      const replyTo = userFromAddress !== DEFAULT_FROM
        ? userFromAddress
        : (user.email ?? undefined);
      const footer = payload.suppress_footer
        ? ""
        : `\n\n---\n` +
          `Sent via Advocat.ee on behalf of ` +
          `${userFromName ?? user.email ?? "client"}.\n` +
          `Reply directly to this email to reach the sender.`;
      const r = await sendViaResend({
        from: `Advocat <${DEFAULT_FROM}>`,
        to,
        cc,
        subject,
        body: `${composedBody}${footer}`,
        replyTo,
      });
      providerId = r.id;
      provider = "resend_fallback";
    } catch (e) {
      const msg = e instanceof Error ? e.message : "unknown";
      console.error("send-email: Resend failed:", msg.slice(0, 200));
      return jsonResponse(
        { error: "Email dispatch failed" },
        502,
      );
    }
  }

  // Log to correspondence table (best-effort).
  // We persist the COMPOSED body (incl. disclosure footer) so audit reflects
  // what was actually sent. The classification class is also stored as
  // metadata for downstream reporting / compliance dashboards.
  try {
    await supabase.from("correspondence").insert({
      user_id: user.id,
      case_id: payload.case_id ?? null,
      direction: "outbound",
      from_address: userFromAddress,
      to_address: to,
      cc_address: cc ?? null,
      subject,
      body: composedBody,
      provider,
      provider_message_id: providerId,
      sent_at: new Date().toISOString(),
    });
  } catch (e) {
    console.warn("send-email: correspondence insert failed:", e);
  }

  // Sidecar: append an `email_out` event to the case timeline so the
  // client-facing Case Timeline UI reflects the sent message. Only fires
  // when the request includes a case_id; chat-driven sends without a
  // bound case are skipped. Best-effort — failure must not break the
  // user-visible send-success response.
  if (payload.case_id) {
    try {
      await supabase.rpc("record_case_event", {
        p_case_id: payload.case_id,
        p_event_type: "email_out",
        p_title: subject.slice(0, 200),
        p_summary: `To: ${to}${cc ? ` · Cc: ${cc}` : ""}`,
        p_payload: {
          to,
          cc: cc ?? null,
          provider,
          provider_message_id: providerId,
          dedupe_key: providerId
            ? `email_out:${providerId}`
            : null,
        },
      });
    } catch (e) {
      console.warn("send-email: timeline event insert failed:", e);
    }
  }

  return jsonResponse({
    ok: true,
    provider,
    provider_message_id: providerId,
  });
});
