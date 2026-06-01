// tts-proxy/__tests__/tts_proxy_test.ts
// -----------------------------------------------------------------------------
// Path-injection regression for the ElevenLabs voice id.
//
// voiceId flows into https://api.elevenlabs.io/v1/text-to-speech/${voiceId}.
// isValidVoiceId gates it: only 16–40 alphanumerics pass, so a "/", "?", "#"
// or ".." cannot inject extra path segments / query params against our billed
// API key. A rejected id falls back to DEFAULT_VOICE_ID in the handler.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/tts-proxy/__tests__/tts_proxy_test.ts
// -----------------------------------------------------------------------------

import { assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { isValidVoiceId } from "../validate.ts";

Deno.test("VOICE-01 — real ElevenLabs ids pass", () => {
  for (const ok of ["21m00Tcm4TlvDq8ikWAM", "AZnzlk1XvdvUeBnXmlld", "a".repeat(16), "Z9".padEnd(40, "x")]) {
    assert(isValidVoiceId(ok), `expected ${ok} valid`);
  }
});

Deno.test("VOICE-02 — path / query injection rejected", () => {
  for (
    const bad of [
      "../../../v1/voices",
      "21m00Tcm4TlvDq8ikWAM/../models",
      "21m00Tcm4TlvDq8ikWAM?optimize_streaming_latency=4",
      "21m00Tcm4TlvDq8ikWAM#frag",
      "voice.with.dots",
      "//api.evil.com",
      "21m00 Tcm4TlvDq8ikWAM",
    ]
  ) {
    assert(!isValidVoiceId(bad), `expected ${JSON.stringify(bad)} rejected`);
  }
});

Deno.test("VOICE-03 — length bounds (16–40) enforced", () => {
  assert(!isValidVoiceId("short")); // 5
  assert(!isValidVoiceId("a".repeat(15)));
  assert(!isValidVoiceId("a".repeat(41)));
});

Deno.test("VOICE-04 — non-string / empty rejected (no throw)", () => {
  for (const bad of [null, undefined, "", 12345, {}, []]) {
    assert(!isValidVoiceId(bad as unknown));
  }
});
