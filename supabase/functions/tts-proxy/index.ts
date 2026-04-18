// tts-proxy Edge Function
// -----------------------------------------------------------------------------
// ElevenLabs TTS proxy. Billable (~$0.18/1000 chars); JWT-auth + rate-limit
// required, same as whisper-stt.
//
// v24.2 hardening (OMEGA-5): JWT, 10 req/min/user, CORS advocat.ee only,
// 5 KB text cap (existing).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const ELEVENLABS_API_KEY = Deno.env.get("ELEVENLABS_API_KEY");

// Rachel voice — warm, professional female.
const DEFAULT_VOICE_ID = "21m00Tcm4TlvDq8ikWAM";

// ElevenLabs multilingual_v2 language codes.
const SUPPORTED_LANGS = new Set([
  "en", "ru", "de", "fr", "es", "it", "pl", "pt", "nl",
  "sv", "tr", "ar", "hi", "ja", "ko", "zh", "id", "fil",
]);

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  if (!ELEVENLABS_API_KEY) {
    return jsonError("TTS not configured", 503);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "tts-proxy",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    const { text, voice_id, language } = await req.json();

    if (!text || typeof text !== "string" || text.length > 5000) {
      return jsonError("Invalid text (required, max 5000 chars)", 400);
    }

    const voiceId =
      (typeof voice_id === "string" && voice_id) || DEFAULT_VOICE_ID;
    const langCode =
      language && typeof language === "string" && SUPPORTED_LANGS.has(language)
        ? language
        : undefined;

    const body: Record<string, unknown> = {
      text,
      model_id: "eleven_multilingual_v2",
      voice_settings: {
        stability: 0.65,
        similarity_boost: 0.85,
        style: 0.15,
      },
    };
    if (langCode) body.language_code = langCode;

    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "xi-api-key": ELEVENLABS_API_KEY,
        },
        body: JSON.stringify(body),
      },
    );

    if (!response.ok) {
      const error = await response.text();
      return jsonError(error, response.status);
    }

    const audioBuffer = await response.arrayBuffer();
    return new Response(audioBuffer, {
      headers: { ...corsHeaders, "Content-Type": "audio/mpeg" },
    });
  } catch (error) {
    return jsonError("Internal error", 500, { details: String(error) });
  }
});
