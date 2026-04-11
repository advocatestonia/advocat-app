import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const ELEVENLABS_API_KEY = Deno.env.get("ELEVENLABS_API_KEY");

// Rachel voice - warm, professional female voice
const DEFAULT_VOICE_ID = "21m00Tcm4TlvDq8ikWAM";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://advocat.ee",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey, x-client-info",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { text, voice_id, language } = await req.json();

    if (!text || text.length > 5000) {
      return new Response(JSON.stringify({ error: "Invalid text" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const voiceId = voice_id || DEFAULT_VOICE_ID;

    // ElevenLabs supported language codes (multilingual_v2)
    const supportedLangs = new Set([
      "en", "ru", "de", "fr", "es", "it", "pl", "pt", "nl",
      "sv", "tr", "ar", "hi", "ja", "ko", "zh", "id", "fil",
    ]);
    // For unsupported languages (like Estonian), let the model auto-detect from text
    const langCode = language && supportedLangs.has(language) ? language : undefined;

    const body: Record<string, unknown> = {
      text,
      model_id: "eleven_multilingual_v2",
      voice_settings: {
        stability: 0.65,
        similarity_boost: 0.85,
        style: 0.15,
      },
    };
    if (langCode) {
      body.language_code = langCode;
    }

    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "xi-api-key": ELEVENLABS_API_KEY!,
        },
        body: JSON.stringify(body),
      }
    );

    if (!response.ok) {
      const error = await response.text();
      return new Response(JSON.stringify({ error }), {
        status: response.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Return audio as mp3
    const audioBuffer = await response.arrayBuffer();
    return new Response(audioBuffer, {
      headers: {
        ...corsHeaders,
        "Content-Type": "audio/mpeg",
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
