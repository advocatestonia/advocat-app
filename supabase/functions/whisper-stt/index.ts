// whisper-stt Edge Function
// -----------------------------------------------------------------------------
// OpenAI Whisper speech-to-text. Billable (~$0.006/min at time of writing);
// JWT-auth + per-user rate-limit enforced so anonymous scrapers cannot
// drain the OpenAI budget. See _shared/auth.ts.
//
// v24.2 hardening (OMEGA-5):
//   - Authorization: Bearer <JWT> required; session verified against Supabase auth.
//   - 10 requests/minute per authenticated user.
//   - CORS whitelist: advocat.ee only.
//   - 20 MB base64 payload cap (~25 min of webm-opus 8kbps).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const MAX_AUDIO_B64 = 20 * 1024 * 1024; // 20 MB of base64

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

  const gate = await requireUserWithRateLimit(req, {
    bucket: "whisper-stt",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    const { audio_base64, language } = await req.json();

    if (!audio_base64 || typeof audio_base64 !== "string") {
      return jsonError("audio_base64 required", 400);
    }
    if (audio_base64.length > MAX_AUDIO_B64) {
      return jsonError("Audio too large (max 20MB base64)", 413);
    }

    // Decode base64 to binary
    const binaryString = atob(audio_base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }

    // Create form data for Whisper API
    const formData = new FormData();
    formData.append(
      "file",
      new Blob([bytes], { type: "audio/webm" }),
      "audio.webm",
    );
    formData.append("model", "whisper-1");
    if (language && typeof language === "string") {
      formData.append("language", language);
    }
    formData.append("response_format", "text");

    const response = await fetch(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
        body: formData,
      },
    );

    if (!response.ok) {
      const error = await response.text();
      return jsonError(error, response.status);
    }

    const text = await response.text();
    return new Response(JSON.stringify({ text: text.trim() }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return jsonError("Internal error", 500, { details: String(error) });
  }
});
