// google-tts language-code resolver
// -----------------------------------------------------------------------------
// Maps a short language tag (e.g. "en", "et") to the Google TTS BCP-47-ish
// languageCode placed in the request JSON body (voice.languageCode). For most
// 2-letter tags this is `${lang}-${LANG}` (et → et-EE); a handful need an
// explicit regional code (en → en-US, ar → ar-XA, etc.). Tags that are already
// regional (length != 2) pass through unchanged.
//
// This value goes into the JSON body, NOT a URL, so it is not an SSRF surface —
// the resolver exists to keep the voice-map routing correct. Own module so the
// test can import it without booting serve().
// -----------------------------------------------------------------------------

const REGIONAL_OVERRIDES: Record<string, string> = {
  en: "en-US",
  ar: "ar-XA",
  uk: "uk-UA",
  sv: "sv-SE",
  et: "et-EE",
};

export function resolveLangCode(lang: string): string {
  if (REGIONAL_OVERRIDES[lang]) return REGIONAL_OVERRIDES[lang];
  return lang.length === 2 ? `${lang}-${lang.toUpperCase()}` : lang;
}
