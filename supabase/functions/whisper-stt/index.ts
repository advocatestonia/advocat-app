// whisper-stt Edge Function
// -----------------------------------------------------------------------------
// OpenAI Whisper speech-to-text. Billable (~$0.006/min at time of writing);
// JWT-auth + per-user rate-limit + monthly minute quota enforced so anonymous
// scrapers cannot drain the OpenAI budget.
//
// v24.2 hardening (OMEGA-5):
//   - Authorization: Bearer <JWT> required; session verified against Supabase auth.
//   - 10 requests/minute per authenticated user.
//   - CORS whitelist: advocat.ee only.
//
// v24.3 hardening (cost protection — 2026-05-02):
//   - Hard 10 MB binary cap (≈ 14 MB base64) — rejected at 413.
//   - Hard 5-minute per-call duration cap — rejected at 413 after Whisper
//     returns the actual duration (verbose_json response).
//   - Per-user monthly minute quota:
//       free        →   0 min/month  (voice is a paid feature)
//       basic       → 300 min/month  (Counsel — 5 hours)
//       premium     → 1200 min/month (Representation — 20 hours)
//     Pre-flight check uses ESTIMATED minutes (based on payload size at a
//     conservative 64 kbps bitrate) to fail fast on obviously-too-large
//     uploads. After Whisper succeeds, the EXACT duration from verbose_json
//     is recorded against the user's voice_usage tally via the
//     add_voice_usage RPC (see migration 20260502100000_voice_usage.sql).
//
// Pure helpers + tier-quota constants live in ./cost_control.ts so unit
// tests can import them without booting the HTTP server.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  decodeBase64,
  detectVoiceTier,
  estimateSecondsFromBytes,
  MAX_AUDIO_B64,
  MAX_BINARY_BYTES,
  SECONDS_PER_CALL_MAX,
  TIER_MONTHLY_SECONDS,
} from "./cost_control.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  if (!OPENAI_API_KEY) {
    return jsonError("Whisper not configured", 503);
  }

  // 1) JWT + per-minute request-rate gate (pre-existing).
  const gate = await requireUserWithRateLimit(req, {
    bucket: "whisper-stt",
    maxPerMinute: 10,
    // No anonymous fallback — voice quota requires a real user row in the DB.
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;

  try {
    // 2) Parse + validate payload size BEFORE any expensive work.
    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return jsonError("Invalid JSON body", 400);
    }
    const audio_base64 = (body as Record<string, unknown>).audio_base64;
    const language = (body as Record<string, unknown>).language;

    if (!audio_base64 || typeof audio_base64 !== "string") {
      return jsonError("audio_base64 required", 400);
    }
    if (audio_base64.length > MAX_AUDIO_B64) {
      return jsonError(
        "Audio too large (max ~10 MB binary / 5 minutes)",
        413,
        { limitBytes: MAX_BINARY_BYTES },
      );
    }

    const bytes = decodeBase64(audio_base64);
    if (bytes.byteLength > MAX_BINARY_BYTES) {
      return jsonError(
        "Audio too large (max 10 MB binary)",
        413,
        { limitBytes: MAX_BINARY_BYTES, gotBytes: bytes.byteLength },
      );
    }

    // 3) Cheap upper-bound duration check before we burn an API call.
    // If the byte-based estimate already exceeds 5 min, we know the user
    // is sending a long file and we can refuse without paying OpenAI.
    const estimatedSeconds = estimateSecondsFromBytes(bytes.byteLength);
    if (estimatedSeconds > SECONDS_PER_CALL_MAX) {
      return jsonError(
        "Audio too long (max 5 minutes per call)",
        413,
        { maxSeconds: SECONDS_PER_CALL_MAX, estimatedSeconds },
      );
    }

    // 4) Quota pre-flight. Build a per-request supabase client that
    // forwards the caller's JWT so SECURITY DEFINER RPCs see auth.uid().
    const authHeader = req.headers.get("Authorization")!; // gate ensured presence
    const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const tier = await detectVoiceTier(sb, userId);
    const monthlyLimit = TIER_MONTHLY_SECONDS[tier];

    // Free tier: voice is a paid feature, reject up-front. Saves a DB read.
    if (monthlyLimit === 0) {
      return jsonError(
        "Voice transcription is a paid feature. Upgrade to Counsel or Representation.",
        402,
        { tier, monthlyLimitSeconds: 0 },
      );
    }

    const { data: usedSecondsRaw, error: usageErr } = await sb.rpc(
      "get_voice_usage",
    );
    if (usageErr) {
      // RPC missing or DB error — fail closed: do not call OpenAI without
      // knowing the user's current usage.
      return jsonError("Quota check failed", 503, {
        details: usageErr.message,
      });
    }
    const usedSeconds = (usedSecondsRaw as number) ?? 0;

    if (usedSeconds + estimatedSeconds > monthlyLimit) {
      return jsonError(
        "Monthly voice quota exceeded. Upgrade to Representation for more minutes.",
        402,
        {
          tier,
          monthlyLimitSeconds: monthlyLimit,
          usedSeconds,
          estimatedSeconds,
        },
      );
    }

    // 5) Call OpenAI Whisper. Use verbose_json so we get the precise
    // duration field for billing.
    const formData = new FormData();
    formData.append(
      "file",
      // Cast: Deno's lib.dom.d.ts narrows BlobPart to ArrayBuffer-backed
      // views; our Uint8Array is over ArrayBufferLike which is broader.
      // Functionally identical at runtime.
      new Blob([bytes as BlobPart], { type: "audio/webm" }),
      "audio.webm",
    );
    formData.append("model", "whisper-1");
    if (language && typeof language === "string") {
      formData.append("language", language);
    }
    formData.append("response_format", "verbose_json");

    const response = await fetch(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
        body: formData,
      },
    );

    if (!response.ok) {
      // Do NOT echo the raw OpenAI error body to the client — it can carry
      // request IDs, org/quota hints, and other internal detail. Log it
      // server-side (truncated) and return a generic message.
      const detail = await response.text();
      console.error(
        "whisper-stt: OpenAI transcription failed:",
        response.status,
        detail.slice(0, 200),
      );
      return jsonError("Transcription failed", 502);
    }

    const result = await response.json() as {
      text?: string;
      duration?: number; // seconds, float
    };
    const text = (result.text ?? "").trim();
    const exactSeconds = Math.max(
      0,
      Math.ceil(result.duration ?? estimatedSeconds),
    );

    // 6) Post-flight per-call duration check. Whisper happily transcribes
    // 30-minute files; we reject anything > 5 min after the fact AND do
    // not bill it against the user's quota (since the result is unusable
    // anyway). This branch is rare because the byte-based pre-flight
    // already filtered most over-length uploads.
    if (exactSeconds > SECONDS_PER_CALL_MAX) {
      return jsonError(
        "Audio too long (max 5 minutes per call)",
        413,
        { maxSeconds: SECONDS_PER_CALL_MAX, gotSeconds: exactSeconds },
      );
    }

    // 7) Record exact usage. The estimator is conservative (assumes
    // 64 kbps); real recordings can be lower bitrate, meaning MORE seconds
    // per byte than estimated. By writing exactSeconds (not estimatedSeconds)
    // we keep the tally honest. Failure to record is logged but not fatal —
    // the user gets their transcript. Worst case: small under-count for the
    // month.
    const newTotal = usedSeconds + exactSeconds;
    try {
      const { error: addErr } = await sb.rpc("add_voice_usage", {
        p_seconds: exactSeconds,
      });
      if (addErr) {
        console.error("voice_usage write failed", {
          userId,
          exactSeconds,
          error: addErr.message,
        });
      }
    } catch (e) {
      console.error("voice_usage RPC threw", { userId, error: String(e) });
    }

    return new Response(
      JSON.stringify({
        text,
        durationSeconds: exactSeconds,
        quota: {
          tier,
          usedSeconds: newTotal,
          monthlyLimitSeconds: monthlyLimit,
          remainingSeconds: Math.max(0, monthlyLimit - newTotal),
        },
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return jsonError("Internal error", 500, { details: String(error) });
  }
});
