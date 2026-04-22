# TTS Routing Matrix — 17 локалей (audit 2026-04-21)

Источник правды:
- `lib/services/voice_service.dart` — `speak()` (line 660), `_preferElevenLabsFor` (line 84), `_ttsLocaleMap` (line 43)
- `supabase/functions/tts-proxy/index.ts` — `SUPPORTED_LANGS` (line 23)
- `supabase/functions/google-tts/index.ts` — `VOICE_MAP_*` (lines 30/51), `GEMINI_GA_LANGS` (line 22)

## Порядок решения в `speak(text, langCode)`

```
if (_shouldPreferElevenLabs(langCode) && _elevenLabsAvailable):
    try ElevenLabs (tts-proxy)
    on fail → try Google (google-tts) ← [!] здесь было смешивание голосов
    on fail → Browser SpeechSynthesis
else:
    try Google (google-tts)
    on fail → retry Google (500 ms)
    on fail → try ElevenLabs (tts-proxy) ← [!] смешивание
    on fail → Browser SpeechSynthesis
```

## Таблица: locale → engine (в v24.2.3)

| # | Lang | Primary engine           | Model / Voice (female)            | Fallback chain               | tts-proxy supports? | _ttsLocaleMap |
|---|------|--------------------------|-----------------------------------|------------------------------|---------------------|---------------|
| 1 | en   | ElevenLabs v3            | Charlotte `XB0fDUnXU5powFXDhCwa`  | Google Chirp3-HD-Leda → Browser | YES (en)         | en-US         |
| 2 | ru   | ElevenLabs v3            | Charlotte                         | Google Chirp3-HD-Leda → Browser | YES (ru)         | ru-RU         |
| 3 | uk   | ElevenLabs v3            | Charlotte                         | Google Standard-A → Browser     | NO (fallthru lang_code) | uk-UA     |
| 4 | et   | Google Chirp3-HD         | `et-EE-Chirp3-HD-Kore`            | Google retry → ElevenLabs → Browser | NO            | et-EE         |
| 5 | fi   | Google Gemini 3.1 Flash  | Voice Kore (via Gemini)           | Google Chirp3-HD → ElevenLabs → Browser | NO        | fi-FI         |
| 6 | de   | Google Gemini 3.1 Flash  | Voice Leda                        | Chirp3-HD → EL → Browser        | YES                 | de-DE         |
| 7 | fr   | Google Gemini 3.1 Flash  | Voice Leda                        | Chirp3-HD → EL → Browser        | YES                 | fr-FR         |
| 8 | es   | Google Gemini 3.1 Flash  | Voice Leda                        | Chirp3-HD → EL → Browser        | YES                 | es-ES         |
| 9 | it   | Google Gemini 3.1 Flash  | `it-IT-Wavenet-A`                 | Wavenet → EL → Browser          | YES                 | it-IT         |
|10 | pl   | Google Gemini 3.1 Flash  | `pl-PL-Wavenet-A`                 | Wavenet → EL → Browser          | YES                 | pl-PL         |
|11 | sv   | Google Gemini 3.1 Flash  | `sv-SE-Wavenet-A`                 | Wavenet → EL → Browser          | YES                 | sv-SE         |
|12 | ar   | Google Gemini 3.1 Flash  | `ar-XA-Chirp3-HD-Leda`            | Chirp3-HD → EL → Browser        | YES                 | ar-SA         |
|13 | ro   | Google Chirp3-HD-fallback| `ro-RO-Wavenet-A` (preview SLA)   | retry → EL → Browser            | NO                  | ro-RO         |
|14 | lt   | Google Chirp3-HD-fallback| `lt-LT-Standard-A` (preview SLA)  | retry → EL → Browser            | NO                  | lt-LT         |
|15 | lv   | Google Chirp3-HD-fallback| `lv-LV-Standard-A` (preview SLA)  | retry → EL → Browser            | NO                  | lv-LV         |
|16 | tr   | Google Chirp3-HD-fallback| `tr-TR-Wavenet-A` (preview SLA)   | retry → EL → Browser            | YES                 | tr-TR         |
|17 | fa   | Google (no voice map hit)| Fallback `fa-IR-Standard-A`       | retry → EL (NO support) → Browser | NO                | fa-IR         |

## Наблюдения

1. **`_preferElevenLabsFor = {'en','ru','uk'}` FROZEN** (owner choice 2026-04-21). `uk` идёт в tts-proxy, но `SUPPORTED_LANGS` не содержит `uk` → `language_code` отправляется как `undefined`, ElevenLabs multilingual всё равно отдаёт MP3 (язык авто-детектится по тексту).
2. **Estonian (`et`)** строго идёт на Chirp3-HD-Kore/Puck (`GEMINI_GA_LANGS` не содержит `et`) — как и требует контракт.
3. **`fa` (Persian)** — в `VOICE_MAP_FEMALE` его НЕТ, поэтому строка 115 даёт fallback `fa-IR-Standard-A`. ElevenLabs `SUPPORTED_LANGS` тоже не содержит `fa`, поэтому при Google-fail → browser SpeechSynthesis. Это покрытый, но хрупкий путь.
4. **`nl`, `pt`** — в `_ttsLocaleMap` отсутствуют (не входят в 17 локалей приложения), но в google-tts `VOICE_MAP` есть. Ок — не наша проблема.
5. **`_sttLocaleMap` и `_ttsLocaleMap`** покрывают ровно 17 локалей: en, fi, sv, de, fr, es, it, pl, ro, lt, lv, et, ru, uk, tr, ar, fa.

## Вывод

Routing сам по себе **корректен** и покрывает все 17 локалей. Каждая локаль имеет детерминированный primary engine и хотя бы 1 fallback. Изменения в роутинг НЕ требуются. Проблема владельца («разные голоса в одном ответе») лежит в **уровне выше** — в том, как chat_screen.dart вызывает `speak()`. См. `02-voice-switching-root-cause.md`.
