// google-tts Edge Function
// -----------------------------------------------------------------------------
// Google Text-to-Speech proxy. Billable (~$16/million chars — WaveNet/Chirp3).
// v24.2 hardening: JWT required, 10 req/min/user, CORS advocat.ee only.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const GOOGLE_TTS_API_KEY = Deno.env.get("GOOGLE_TTS_API_KEY");

// Gemini 3.1 Flash TTS (released 2026-04-15). Higher quality + expressive
// controls (audio tags like [warmth], [determination]) vs Chirp3-HD.
// GA for: en-US, en-GB, ru-RU, fi-FI, de-DE, fr-FR, es-ES, ar-XA, it-IT, pt-BR, sv-SE, pl-PL.
// Preview (unstable SLA): et-EE, lv-LV, lt-LT, uk-UA, nl-NL, tr-TR, ro-RO.
// We route preview languages to Chirp3-HD for reliability.
const GEMINI_TTS_MODEL = "gemini-3.1-flash-tts-preview";
const GEMINI_GA_LANGS = new Set([
  "en", "ru", "fi", "de", "fr", "es", "ar", "it", "pt", "sv", "pl",
]);
// Allow emergency rollback via Supabase secret: USE_GEMINI_TTS=off
const USE_GEMINI_TTS = Deno.env.get("USE_GEMINI_TTS") !== "off";

// Language to voice mapping — best available voice per language
// Uses Chirp3-HD > Wavenet > Standard (in order of quality)
const VOICE_MAP_FEMALE: Record<string, { name: string; gender: string }> = {
  et: { name: "et-EE-Chirp3-HD-Kore", gender: "FEMALE" },
  ru: { name: "ru-RU-Chirp3-HD-Leda", gender: "FEMALE" },
  en: { name: "en-US-Chirp3-HD-Leda", gender: "FEMALE" },
  fi: { name: "fi-FI-Chirp3-HD-Kore", gender: "FEMALE" },
  de: { name: "de-DE-Chirp3-HD-Leda", gender: "FEMALE" },
  fr: { name: "fr-FR-Chirp3-HD-Leda", gender: "FEMALE" },
  es: { name: "es-ES-Chirp3-HD-Leda", gender: "FEMALE" },
  it: { name: "it-IT-Wavenet-A", gender: "FEMALE" },
  sv: { name: "sv-SE-Wavenet-A", gender: "FEMALE" },
  pl: { name: "pl-PL-Wavenet-A", gender: "FEMALE" },
  uk: { name: "uk-UA-Standard-A", gender: "FEMALE" },
  tr: { name: "tr-TR-Wavenet-A", gender: "FEMALE" },
  ar: { name: "ar-XA-Chirp3-HD-Leda", gender: "FEMALE" },
  lv: { name: "lv-LV-Standard-A", gender: "FEMALE" },
  lt: { name: "lt-LT-Standard-A", gender: "FEMALE" },
  ro: { name: "ro-RO-Wavenet-A", gender: "FEMALE" },
  nl: { name: "nl-NL-Wavenet-A", gender: "FEMALE" },
  pt: { name: "pt-PT-Wavenet-A", gender: "FEMALE" },
};

const VOICE_MAP_MALE: Record<string, { name: string; gender: string }> = {
  et: { name: "et-EE-Chirp3-HD-Puck", gender: "MALE" },
  ru: { name: "ru-RU-Chirp3-HD-Puck", gender: "MALE" },
  en: { name: "en-US-Neural2-D", gender: "MALE" },
  fi: { name: "fi-FI-Wavenet-B", gender: "MALE" },
  de: { name: "de-DE-Wavenet-B", gender: "MALE" },
  fr: { name: "fr-FR-Wavenet-B", gender: "MALE" },
  es: { name: "es-ES-Wavenet-B", gender: "MALE" },
  it: { name: "it-IT-Wavenet-C", gender: "MALE" },
  sv: { name: "sv-SE-Wavenet-C", gender: "MALE" },
  pl: { name: "pl-PL-Wavenet-B", gender: "MALE" },
  uk: { name: "uk-UA-Standard-B", gender: "MALE" },
  tr: { name: "tr-TR-Wavenet-B", gender: "MALE" },
  ar: { name: "ar-XA-Wavenet-B", gender: "MALE" },
  lv: { name: "lv-LV-Standard-B", gender: "MALE" },
  lt: { name: "lt-LT-Standard-B", gender: "MALE" },
  ro: { name: "ro-RO-Wavenet-B", gender: "MALE" },
  nl: { name: "nl-NL-Wavenet-B", gender: "MALE" },
  pt: { name: "pt-PT-Wavenet-B", gender: "MALE" },
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  if (!GOOGLE_TTS_API_KEY) {
    return jsonError("google-tts not configured", 503);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "google-tts",
    maxPerMinute: 10,
    // Demo users (no JWT) get limited TTS so voices work in demo mode.
    anonymousPerMinute: 5,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    const { text, language, gender } = await req.json();

    if (!text || typeof text !== "string" || text.length > 5000) {
      return jsonError("Invalid text (required, max 5000 chars)", 400);
    }

    const lang = typeof language === "string" && language ? language : "et";
    const langCode = lang.length === 2 ? `${lang}-${lang.toUpperCase()}` : lang;

    const langCodeMap: Record<string, string> = {
      en: "en-US",
      ar: "ar-XA",
      uk: "uk-UA",
      sv: "sv-SE",
      et: "et-EE",
    };
    const finalLangCode = langCodeMap[lang] || langCode;

    const isMale = gender === "male";
    const voiceMap = isMale ? VOICE_MAP_MALE : VOICE_MAP_FEMALE;
    const fallbackGender = isMale ? "MALE" : "FEMALE";
    const fallbackSuffix = isMale ? "B" : "A";
    const voice = voiceMap[lang] ||
      {
        name: `${finalLangCode}-Standard-${fallbackSuffix}`,
        gender: fallbackGender,
      };

    // Decide which model: Gemini 3.1 for GA languages, Chirp3-HD for preview ones.
    const useGemini = USE_GEMINI_TTS && GEMINI_GA_LANGS.has(lang);

    // Strip expressive audio tags like [warmth] [thoughtful] when we fall back
    // to Chirp3-HD — that model would read "bracket warmth bracket" literally.
    // Gemini 3.1 Flash TTS parses them natively.
    const EXPRESSIVE_TAGS = /\[(warmth|thoughtful|determination|sigh|reassuring|whispers|laughs|excitement|enthusiasm|shouts|sarcastic|calm|confident|empathetic|serious|gentle|firm|curious|hopeful|concerned)\]\s*/gi;
    const cleanText = useGemini ? text : text.replace(EXPRESSIVE_TAGS, "");

    const requestBody = useGemini
      ? {
          input: { text: cleanText },
          voice: {
            languageCode: finalLangCode,
            name: voice.name,
            // Gemini uses model_name + voice name; voice name re-used (Kore/Leda/Puck
            // map 1:1 with Gemini's prebuilt voice list of the same names).
            model_name: GEMINI_TTS_MODEL,
          },
          audioConfig: {
            audioEncoding: "MP3",
            speakingRate: 1.0,
            pitch: 0,
            sampleRateHertz: 24000,
          },
        }
      : {
          input: { text: cleanText },
          voice: {
            languageCode: finalLangCode,
            name: voice.name,
            ssmlGender: voice.gender,
          },
          audioConfig: {
            audioEncoding: "MP3",
            speakingRate: 1.0,
            pitch: 0,
            sampleRateHertz: 24000,
          },
        };

    // Gemini 3.1 Flash TTS is only on the global endpoint.
    const endpoint = useGemini
      ? `https://texttospeech.googleapis.com/v1beta1/text:synthesize?key=${GOOGLE_TTS_API_KEY}`
      : `https://texttospeech.googleapis.com/v1/text:synthesize?key=${GOOGLE_TTS_API_KEY}`;

    let response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(requestBody),
    });

    // If Gemini fails (e.g. preview outage, quota, bad request), auto-fallback
    // to stable Chirp3-HD so the user still hears a voice.
    if (useGemini && !response.ok) {
      console.warn(
        `Gemini TTS failed (${response.status}), falling back to Chirp3-HD for ${lang}`,
      );
      // Strip tags before fallback — Chirp3-HD can't parse them.
      const strippedText = text.replace(EXPRESSIVE_TAGS, "");
      response = await fetch(
        `https://texttospeech.googleapis.com/v1/text:synthesize?key=${GOOGLE_TTS_API_KEY}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            input: { text: strippedText },
            voice: {
              languageCode: finalLangCode,
              name: voice.name,
              ssmlGender: voice.gender,
            },
            audioConfig: {
              audioEncoding: "MP3",
              speakingRate: 1.0,
              pitch: 0,
              sampleRateHertz: 24000,
            },
          }),
        },
      );
    }

    if (!response.ok) {
      // Do NOT echo the raw Google API error body to the client — it can
      // carry project IDs, quota detail, and other internal hints. Log it
      // server-side (truncated) and return a generic message.
      const detail = await response.text();
      console.error("Google TTS error:", response.status, detail.slice(0, 200));
      return jsonError("Speech synthesis failed", 502);
    }

    const data = await response.json();
    const audioContent = data.audioContent;
    if (!audioContent) {
      return jsonError("No audio returned", 500);
    }

    const binaryString = atob(audioContent);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }

    return new Response(bytes, {
      headers: { ...corsHeaders, "Content-Type": "audio/mpeg" },
    });
  } catch (error) {
    console.error("google-tts error:", error);
    return jsonError("Internal error", 500);
  }
});
