// google-tts/__tests__/google_tts_test.ts
// -----------------------------------------------------------------------------
// Regression for the language-code resolver (voice.languageCode in the body).
// google-tts has NO URL/path injection surface (endpoint is host-pinned, only
// the server-side GOOGLE_TTS_API_KEY is in the query, and language/gender flow
// into the JSON body only). These tests lock the lang→languageCode routing so
// the voice map keeps resolving to a valid Google code.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/google-tts/__tests__/google_tts_test.ts
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { resolveLangCode } from "../lang.ts";

Deno.test("LANG-01 — explicit regional overrides", () => {
  assertEquals(resolveLangCode("en"), "en-US");
  assertEquals(resolveLangCode("ar"), "ar-XA");
  assertEquals(resolveLangCode("uk"), "uk-UA");
  assertEquals(resolveLangCode("sv"), "sv-SE");
  assertEquals(resolveLangCode("et"), "et-EE");
});

Deno.test("LANG-02 — generic 2-letter tags become lang-LANG", () => {
  assertEquals(resolveLangCode("ru"), "ru-RU");
  assertEquals(resolveLangCode("de"), "de-DE");
  assertEquals(resolveLangCode("fi"), "fi-FI");
  assertEquals(resolveLangCode("pl"), "pl-PL");
});

Deno.test("LANG-03 — already-regional codes pass through", () => {
  assertEquals(resolveLangCode("pt-BR"), "pt-BR");
  assertEquals(resolveLangCode("zh-CN"), "zh-CN");
});
