// weekly-digest-send/index.ts
// -----------------------------------------------------------------------------
// Retention Loop 1 — weekly digest email.
//
// Trigger: pg_cron (or external scheduler) Monday 08:00 Europe/Tallinn,
// via POST with header `x-cron-secret: $CRON_SECRET`.
//
// Behaviour:
//   * Calls public.digest_candidates(p_max_rows := 1000)
//   * For each candidate user: fetches active cases + deadlines + advice
//     digest entries since last_digest_sent_at, builds DigestData, renders
//     HTML via _shared/retention_templates, sends via Resend (transactional
//     channel), stamps email_events + record_digest_sent.
//   * Per-tick safety cap: BATCH_LIMIT (default 200). Spillover users land
//     in next tick (cron runs every 5 min during the Mon 08:00 window).
//
// Manual smoke (single-user):
//   POST /weekly-digest-send  with body { "preview_user_id": "<uuid>" }
//   and header `x-cron-secret`. Returns the rendered subject + html.
//   Email IS NOT actually sent in preview mode.
//
// PII discipline:
//   * Only the recipient's own email + name + their own case data is in
//     the rendered body. Nothing crosses user boundaries.
//   * The response payload is counts only.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { checkCronSecret } from "../deadline-radar-tick/auth_gate.ts";
import { renderDigest } from "../_shared/retention_templates.ts";
import { buildDigestData, safeSubject } from "./digest_logic.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const APP_BASE_URL = Deno.env.get("APP_BASE_URL") || "https://advocat.ee/app";
const DIGEST_FROM = Deno.env.get("DIGEST_FROM_ADDRESS") || "Advocat <hello@advocat.ee>";
const BATCH_LIMIT = parseInt(Deno.env.get("DIGEST_BATCH_LIMIT") ?? "200", 10);
const DRY_RUN = Deno.env.get("DIGEST_DRY_RUN") === "1";

interface DigestSendResult {
  processed: number;
  sent: number;
  skipped_no_email: number;
  skipped_no_cases: number;
  errors: number;
  previewed?: number;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return jsonResp({ error: "Method not allowed" }, 405);
  }

  // Preview mode is gated on the SAME cron secret — there's no public
  // endpoint that returns rendered email content.
  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") return jsonResp(gate.body, gate.status);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  let body: { preview_user_id?: string } = {};
  try {
    if (req.headers.get("content-length") !== "0") {
      body = await req.json();
    }
  } catch (_) {
    body = {};
  }

  // ── Preview path ─────────────────────────────────────────────────────────
  if (body.preview_user_id) {
    const rendered = await renderForUser(supabase, body.preview_user_id);
    if (!rendered) {
      return jsonResp(
        { error: "preview_failed", user_id: body.preview_user_id },
        404,
      );
    }
    return jsonResp({
      preview: true,
      user_id: body.preview_user_id,
      subject: rendered.email.subject,
      html: rendered.email.html,
      text: rendered.email.text,
    });
  }

  // ── Batch path ───────────────────────────────────────────────────────────
  const { data: candidates, error: candErr } = await supabase.rpc(
    "digest_candidates",
    { p_max_rows: BATCH_LIMIT },
  );
  if (candErr) {
    return jsonResp(
      { error: "candidates_rpc_failed", detail: candErr.message },
      500,
    );
  }

  const result: DigestSendResult = {
    processed: 0,
    sent: 0,
    skipped_no_email: 0,
    skipped_no_cases: 0,
    errors: 0,
  };

  for (const row of (candidates ?? []) as Array<{
    user_id: string;
    email: string;
    full_name: string;
    preferred_language: string;
    last_digest_sent_at: string | null;
    active_case_count: number;
  }>) {
    result.processed++;
    if (!row.email) {
      result.skipped_no_email++;
      continue;
    }
    if ((row.active_case_count ?? 0) === 0) {
      result.skipped_no_cases++;
      continue;
    }
    try {
      const rendered = await renderForUser(supabase, row.user_id, row);
      if (!rendered) {
        result.errors++;
        continue;
      }
      // De-dupe: a UNIQUE index in the migration prevents two weekly_digest
      // rows for the same user on the same day. Hitting the unique
      // constraint is a no-op — we treat it as "already sent" and skip.
      const { data: existing } = await supabase
        .from("email_events")
        .select("id")
        .eq("user_id", row.user_id)
        .eq("kind", "weekly_digest")
        .gte("sent_at", new Date(Date.now() - 23 * 60 * 60 * 1000).toISOString())
        .limit(1);
      if (existing && existing.length > 0) {
        continue;
      }

      if (!DRY_RUN) {
        const sendRes = await sendEmail(
          row.email,
          rendered.email.subject,
          rendered.email.html,
          rendered.email.text,
        );
        if (!sendRes.ok) {
          result.errors++;
          await supabase.from("email_events").insert({
            user_id: row.user_id,
            kind: "weekly_digest",
            recipient_email: row.email,
            subject: rendered.email.subject,
            body_excerpt: rendered.email.text.slice(0, 500),
            provider: "resend",
            error: sendRes.error,
          });
          continue;
        }
        await supabase.from("email_events").insert({
          user_id: row.user_id,
          kind: "weekly_digest",
          recipient_email: row.email,
          subject: rendered.email.subject,
          body_excerpt: rendered.email.text.slice(0, 500),
          provider: "resend",
          provider_message_id: sendRes.messageId,
        });
        await supabase.rpc("record_digest_sent", { p_user_id: row.user_id });
      }
      result.sent++;
    } catch (e) {
      console.error(
        `weekly-digest: user ${row.user_id} failed: ${String(e).slice(0, 200)}`,
      );
      result.errors++;
    }
  }

  return jsonResp(result);
});

// =============================================================================
// Helpers
// =============================================================================

function jsonResp(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

interface SendResult {
  ok: boolean;
  messageId?: string;
  error?: string;
}

async function sendEmail(
  to: string,
  subject: string,
  html: string,
  text: string,
): Promise<SendResult> {
  if (!RESEND_API_KEY) {
    return { ok: false, error: "resend_not_configured" };
  }
  let resp: Response;
  try {
    resp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: DIGEST_FROM,
        to: [to],
        subject: safeSubject(subject),
        html,
        text,
      }),
    });
  } catch (e) {
    return { ok: false, error: `fetch_failed:${String(e).slice(0, 100)}` };
  }
  if (!resp.ok) {
    const t = await resp.text();
    return { ok: false, error: `resend_${resp.status}:${t.slice(0, 200)}` };
  }
  const data = await resp.json();
  return { ok: true, messageId: data.id as string };
}

interface RenderResult {
  email: { subject: string; html: string; text: string };
}

async function renderForUser(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  prefetched?: {
    email: string;
    full_name: string;
    preferred_language: string;
    last_digest_sent_at: string | null;
  },
): Promise<RenderResult | null> {
  let userRow = prefetched;
  if (!userRow) {
    const { data: u } = await supabase
      .from("users")
      .select("id, email, full_name, preferred_language")
      .eq("id", userId)
      .maybeSingle();
    if (!u?.email) return null;
    const { data: eng } = await supabase
      .from("user_engagement")
      .select("last_digest_sent_at")
      .eq("user_id", userId)
      .maybeSingle();
    userRow = {
      email: u.email,
      full_name: u.full_name ?? "",
      preferred_language: u.preferred_language ?? "en",
      last_digest_sent_at: eng?.last_digest_sent_at ?? null,
    };
  }

  const { data: prefs } = await supabase
    .from("notification_preferences")
    .select("unsubscribe_token")
    .eq("user_id", userId)
    .maybeSingle();

  // Lazy-create prefs row if missing so unsubscribe link always works.
  let unsubToken: string | null = prefs?.unsubscribe_token ?? null;
  if (!unsubToken) {
    const { data: created } = await supabase
      .from("notification_preferences")
      .insert({ user_id: userId })
      .select("unsubscribe_token")
      .single();
    unsubToken = created?.unsubscribe_token ?? null;
  }

  // Active cases + their advice_digest
  const { data: cases } = await supabase
    .from("user_cases")
    .select("id, title, status, advice_digest")
    .eq("user_id", userId)
    .eq("status", "active");

  if (!cases || cases.length === 0) return null;

  const caseIds = cases.map((c: { id: string }) => c.id);

  // Active deadlines for those cases (next 35d window — let logic filter)
  const { data: deadlines } = await supabase
    .from("case_deadlines")
    .select("title, deadline_at, status, case_id")
    .in("case_id", caseIds)
    .in("status", ["active", "missed"]);

  const allDeadlines = (deadlines ?? []).map((d: {
    title: string;
    deadline_at: string;
    status: string;
    case_id: string;
  }) => ({
    title: d.title,
    deadline_at: d.deadline_at,
    status: d.status,
    case_id: d.case_id,
    case_title: cases.find((c: { id: string }) => c.id === d.case_id)?.title ?? "",
  }));

  const digestData = buildDigestData(
    {
      fullName: userRow.full_name,
      email: userRow.email,
      preferredLang: userRow.preferred_language,
      activeCases: cases.map((c: {
        id: string;
        title: string;
        status: string;
        advice_digest: unknown;
      }) => ({
        id: c.id,
        title: c.title,
        status: c.status,
        advice_digest: Array.isArray(c.advice_digest)
          ? (c.advice_digest as Array<{ created_at: string; summary: string }>)
          : [],
      })),
      allDeadlines,
      lastDigestSentAt: userRow.last_digest_sent_at,
      appBaseUrl: APP_BASE_URL,
      unsubscribeToken: unsubToken ?? "0",
    },
    new Date(),
  );

  const email = renderDigest(digestData);
  return { email };
}
