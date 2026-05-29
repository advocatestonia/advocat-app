// vault-rotate-master/index.ts — HTTP shim for two-phase master rotation.
// -----------------------------------------------------------------------------
// Wave-2 fix W2-08 (audit INFRA-04).
//
// Routes:
//   POST /functions/v1/vault-rotate-master/initiate
//     Body: { new_version, batch_size?, max_batches?, reason, allow_outside_window? }
//     Returns: { rotation_id, expires_at, oob_channel, message }
//
//   POST /functions/v1/vault-rotate-master/confirm
//     Body: { rotation_id, confirm_token }
//     Returns: { rotation_id, version_targeted, batches_run, rotated, skipped, errors, done }
//
// Auth model:
//   - Caller MUST present a valid Supabase user JWT.
//   - That user MUST appear in app_vault.admin_users with active=true.
//     (The ADMIN_USER_IDS env-var allowlist is GONE.)
//   - For /initiate, the master clock MUST be inside 09:00..18:00 Europe/Tallinn
//     OR body.allow_outside_window=true AND FORCE_ROTATE_REASON env matches
//     /^[A-Z0-9_]{8,64}$/ AND body.reason contains that env value.
//
// Rate limiting (defence-in-depth):
//   /initiate: 1/60s per admin via consume_rate_limit RPC under bucket
//   "vault-rotate-master-initiate". The existing 5/min envelope on
//   requireUserWithRateLimit covers /confirm.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  checkRateLimit,
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  type Deps,
  runConfirm,
  runInitiate,
  type SupabaseLike,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FORCE_ROTATE_REASON = Deno.env.get("FORCE_ROTATE_REASON") ?? "";
const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN") ?? "";
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const RESEND_FROM = Deno.env.get("RESEND_FROM") ?? "support@advocat.ee";

// ─── OOB sender: Telegram + Resend ─────────────────────────────────────────

async function sendTelegram(chatId: string, message: string): Promise<boolean> {
  if (!TELEGRAM_BOT_TOKEN) return false;
  try {
    const r = await fetch(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: chatId,
          text: message,
          disable_web_page_preview: true,
        }),
      },
    );
    if (!r.ok) {
      console.error(
        `[vault-rotate-master] telegram send failed status=${r.status} ` +
          `body=${await r.text().catch(() => "<unreadable>")}`,
      );
      return false;
    }
    return true;
  } catch (e) {
    console.error(`[vault-rotate-master] telegram threw: ${String(e)}`);
    return false;
  }
}

async function sendEmail(to: string, subject: string, body: string): Promise<boolean> {
  if (!RESEND_API_KEY) return false;
  try {
    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: RESEND_FROM,
        to: [to],
        subject,
        // Plain text — the token must remain copyable and not html-escaped.
        text: body,
      }),
    });
    if (!r.ok) {
      console.error(
        `[vault-rotate-master] resend send failed status=${r.status} ` +
          `body=${await r.text().catch(() => "<unreadable>")}`,
      );
      return false;
    }
    return true;
  } catch (e) {
    console.error(`[vault-rotate-master] resend threw: ${String(e)}`);
    return false;
  }
}

// ─── Crypto helpers (Deno WebCrypto) ───────────────────────────────────────

function bytesToHex(buf: ArrayBuffer | Uint8Array): string {
  const view = buf instanceof Uint8Array ? buf : new Uint8Array(buf);
  let out = "";
  for (let i = 0; i < view.length; i++) {
    const h = view[i].toString(16);
    out += h.length === 1 ? "0" + h : h;
  }
  return out;
}

async function randomToken(): Promise<string> {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return bytesToHex(bytes);
}

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return bytesToHex(digest);
}

// ─── Server ────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Route by trailing path segment so a single function deploy serves both.
  const url = new URL(req.url);
  const tail = url.pathname.split("/").filter(Boolean).pop() ?? "";
  if (tail !== "initiate" && tail !== "confirm") {
    return jsonError(
      "Use /initiate or /confirm. See docs/security_audit_2026-05-28/" +
        "fixes/wave2_vault_rotation_runbook.md",
      404,
    );
  }

  // JWT + rate-limit envelope. Both routes share the 5/min bucket; /initiate
  // adds a separate stricter 1/60s gate below.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "vault-rotate-master",
    maxPerMinute: 5,
  });
  if (gate.kind === "deny") return gate.response;

  if (gate.user.id.startsWith("anon:")) {
    return jsonError("Vault rotation requires authenticated admin session", 401);
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonError("Vault backend not configured", 503);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonError("Body must be valid JSON", 400);
  }

  const client = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  }) as unknown as SupabaseLike;

  const deps: Deps = {
    supabase: client,
    userId: gate.user.id,
    clock: { now: () => Date.now() },
    sender: { sendTelegram, sendEmail },
    forceRotateReason: FORCE_ROTATE_REASON,
    randomToken,
    sha256Hex,
  };

  // ── /initiate ────────────────────────────────────────────────────────────
  if (tail === "initiate") {
    // Per-admin 1/60s rate limit on /initiate to throttle OOB-channel spam.
    const stricter = await checkRateLimit(
      `vault-rotate-master-initiate:${gate.user.id}`,
      1,
    );
    if (!stricter.admitted) {
      return jsonError(
        "Initiate is limited to 1 per 60 seconds per admin.",
        429,
        { bucket: "vault-rotate-master-initiate", limit: 1, windowMs: 60_000 },
      );
    }

    const ctx = {
      ip: req.headers.get("x-real-ip") ?? undefined,
      userAgent: req.headers.get("user-agent") ?? undefined,
    };
    const result = await runInitiate(body, deps, ctx);
    return result.kind === "success"
      ? jsonOk(result.body, result.status)
      : jsonError(result.body.error, result.status);
  }

  // ── /confirm ─────────────────────────────────────────────────────────────
  const result = await runConfirm(body, deps);
  return result.kind === "success"
    ? jsonOk(result.body, result.status)
    : jsonError(result.body.error, result.status);
});

export { runConfirm, runInitiate } from "./handler.ts";
