// winback-send/index.ts
// -----------------------------------------------------------------------------
// Retention Loop 3 — win-back emails at day 3 / 7 / 14 inactive.
//
// Trigger: pg_cron daily 10:00 Europe/Tallinn, via POST with header
// `x-cron-secret: $CRON_SECRET`.
//
// Behaviour:
//   * Calls public.winback_candidates(p_max_rows := 500).
//   * For each row: picks the step (d3/d7/d14), renders the template
//     (renderWinback), sends via Resend, stamps email_events + calls
//     public.record_winback_sent(...).
//   * Hard cap: 3 winbacks per user lifetime (enforced by RPC + counter).
//   * Idempotent: a UNIQUE index on (user_id, kind, date) in
//     email_events prevents double-sends within 24 h.
//
// DRY_RUN mode: if WINBACK_DRY_RUN=1, no email is sent and no DB write
// happens. Used by owner to inspect the candidate set before going live.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { checkCronSecret } from "../deadline-radar-tick/auth_gate.ts";
import { renderWinback } from "../_shared/retention_templates.ts";
import type { Lang } from "../_shared/retention_templates.ts";
import {
  type CandidateRow,
  processCandidates,
  unsubUrl,
} from "./winback_logic.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const APP_BASE_URL = Deno.env.get("APP_BASE_URL") || "https://advocat.ee/app";
const WINBACK_FROM = Deno.env.get("WINBACK_FROM_ADDRESS") ||
  "Advocat <hello@advocat.ee>";
const BATCH_LIMIT = parseInt(Deno.env.get("WINBACK_BATCH_LIMIT") ?? "200", 10);
const DRY_RUN = Deno.env.get("WINBACK_DRY_RUN") === "1";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return jsonResp({ error: "Method not allowed" }, 405);
  }

  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") return jsonResp(gate.body, gate.status);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const now = new Date();

  let body: { preview_user_id?: string; dry_run?: boolean } = {};
  try {
    if (req.headers.get("content-length") !== "0") {
      body = await req.json();
    }
  } catch (_) {
    body = {};
  }

  // ── Preview mode (single user) ─────────────────────────────────────────
  if (body.preview_user_id) {
    const previews = await previewSingle(supabase, body.preview_user_id, now);
    return jsonResp({ preview: true, ...previews });
  }

  const dryRun = DRY_RUN || body.dry_run === true;

  const { data: rows, error } = await supabase.rpc("winback_candidates", {
    p_max_rows: BATCH_LIMIT,
  });
  if (error) {
    return jsonResp({ error: "candidates_rpc_failed", detail: error.message }, 500);
  }

  const processed = processCandidates((rows ?? []) as CandidateRow[], now);

  let sent = 0;
  let errors = 0;
  let skipped = 0;

  for (const c of processed) {
    // Dedupe: 24-hour window of the same kind
    const kind = `winback_${c.step}` as const;
    const { data: dup } = await supabase
      .from("email_events")
      .select("id")
      .eq("user_id", c.userId)
      .eq("kind", kind)
      .gte(
        "sent_at",
        new Date(now.getTime() - 23 * 60 * 60 * 1000).toISOString(),
      )
      .limit(1);
    if (dup && dup.length > 0) {
      skipped++;
      continue;
    }

    // Ensure prefs row exists
    const { data: prefs } = await supabase
      .from("notification_preferences")
      .select("unsubscribe_token, email_winback_enabled, all_email_disabled")
      .eq("user_id", c.userId)
      .maybeSingle();

    if (
      prefs && (prefs.all_email_disabled || !prefs.email_winback_enabled)
    ) {
      skipped++;
      continue;
    }

    let unsubToken: string | null = prefs?.unsubscribe_token ?? null;
    if (!unsubToken) {
      const { data: created } = await supabase
        .from("notification_preferences")
        .insert({ user_id: c.userId })
        .select("unsubscribe_token")
        .single();
      unsubToken = created?.unsubscribe_token ?? null;
    }

    const lang = pickLang(c.preferredLang);
    const rendered = renderWinback(
      {
        fullName: c.fullName,
        email: c.email,
        lang,
        daysInactive: c.daysInactive,
        appUrl: APP_BASE_URL,
        unsubscribeUrl: unsubUrl(APP_BASE_URL, unsubToken ?? "0", "winback"),
        promoCode: c.promoCode,
      },
      c.step,
    );

    if (dryRun) {
      sent++;
      continue;
    }

    const send = await sendEmail(
      c.email,
      rendered.subject,
      rendered.html,
      rendered.text,
    );
    if (!send.ok) {
      errors++;
      await supabase.from("email_events").insert({
        user_id: c.userId,
        kind,
        recipient_email: c.email,
        subject: rendered.subject,
        body_excerpt: rendered.text.slice(0, 500),
        provider: "resend",
        error: send.error,
      });
      continue;
    }

    await supabase.from("email_events").insert({
      user_id: c.userId,
      kind,
      recipient_email: c.email,
      subject: rendered.subject,
      body_excerpt: rendered.text.slice(0, 500),
      provider: "resend",
      provider_message_id: send.messageId,
    });
    await supabase.rpc("record_winback_sent", {
      p_user_id: c.userId,
      p_step: c.step,
    });
    sent++;
  }

  return jsonResp({
    processed: processed.length,
    sent,
    errors,
    skipped,
    dry_run: dryRun,
  });
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

function pickLang(code: string | null | undefined): Lang {
  const c = (code ?? "").toLowerCase().slice(0, 2);
  if (c === "et" || c === "ee") return "et";
  if (c === "ru") return "ru";
  if (c === "fi") return "fi";
  return "en";
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
        from: WINBACK_FROM,
        to: [to],
        subject: subject.slice(0, 250),
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

async function previewSingle(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  now: Date,
) {
  const { data: u } = await supabase
    .from("users")
    .select("id, email, full_name, preferred_language")
    .eq("id", userId)
    .maybeSingle();
  if (!u?.email) return { error: "user_not_found" };

  const { data: e } = await supabase
    .from("user_engagement")
    .select("last_active_at, winback_sent_count")
    .eq("user_id", userId)
    .maybeSingle();

  const lastActiveAt = e?.last_active_at ?? new Date(0).toISOString();
  const candidate: CandidateRow = {
    user_id: userId,
    email: u.email,
    full_name: u.full_name ?? "",
    preferred_language: u.preferred_language ?? "en",
    last_active_at: lastActiveAt,
    target_step: "d3", // for preview, render the d3 template
    winback_sent_count: e?.winback_sent_count ?? 0,
  };

  const previews: Record<string, unknown> = {};
  for (const step of ["d3", "d7", "d14"] as const) {
    const processed = processCandidates(
      [{ ...candidate, target_step: step }],
      now,
    );
    if (processed.length === 0) {
      previews[step] = { rendered: false };
      continue;
    }
    const c = processed[0];
    const rendered = renderWinback(
      {
        fullName: c.fullName,
        email: c.email,
        lang: pickLang(c.preferredLang),
        daysInactive: c.daysInactive,
        appUrl: APP_BASE_URL,
        unsubscribeUrl: unsubUrl(APP_BASE_URL, "00000000-preview", "winback"),
        promoCode: c.promoCode,
      },
      step,
    );
    previews[step] = {
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
    };
  }
  return previews;
}
