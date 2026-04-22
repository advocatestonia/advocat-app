# Root Cause: «голос переключается посреди ответа»

**Жалоба владельца (2026-04-22..23):** voice switches mid-response — "as if different people speak". Подозрение: на всех языках.

## Гипотезы и проверка

### H1. Sentence-level TTS всё ещё работает в non-streaming path

**Статус:** ⚠️ ЧАСТИЧНО. В `chat_screen.dart` после фикса `cd39315` во время streaming чанки больше НЕ нарезаются — они аккумулируются в `_sentenceBuffer` и в конце streaming вызывается `_speakSentence(fullText)`. НО:

- Метод `_speakSentence` по-прежнему существует (line 394) и внутри делает тот же `voice.speak(cleaned, langCode)` что и `_speakResponse`.
- В non-streaming fallback (`usedStreaming == false`, line 1008) вызывается `_speakResponse(responseText)` — уже с полным текстом.
- Tool-follow-up (line 952) вызывает `_speakResponse(followUp.message)`.

**Проблема не в splitting.** Но в коде живёт двойная машинерия (`_ttsQueue`, `_isSpeakingStreamed`, `_playNextFromQueue`, `_sentenceBuffer`), которую легко снова «включить» чуть-чуть поменяв streaming-цикл — это мина под будущие правки.

### H2. Pre-warm «dot» может сыграться поверх реального ответа

**Статус:** ⚠️ РЕАЛЬНО. `VoiceService.warmUp()` (line 640) делает `_speakWithGoogleTTS('.', langCode:'en')` и сразу `stopSpeaking()`. Проблема: на медленной сети проверка `if (ok)` + `stopSpeaking()` всё равно оставляет **уже запущенный** `_ttsPollTimer` и может начаться воспроизведение «точки» в момент, когда пользователь уже нажал send. Итог — короткий «другой голос» перед основным ответом. Это одна из двух настоящих причин mid-response voice change.

### H3. Engine fallback посреди одного ответа — смешивание ElevenLabs и Google

**Статус:** ❌ КРИТИЧНО. В `VoiceService.speak()` (line 660) реализована цепочка fallback **внутри одного вызова**:

```
preferElevenLabs: EL → Google → Browser
else:              Google → Google(retry) → EL → Browser
```

Каждая «пересадка» — новый fetch к другому движку с другим голосом. Если EL вернул 429 (rate-limit) на длинном ответе или timeout в середине (`fetch` висит > 30 сек на v3) — Dart-сторона НЕ ждёт реального проигрывания (`_speakWithElevenLabs` возвращает `true` сразу после старта плеера, аудио играется через `_pollElevenLabsSpeaking`). Но если сам `webTtsSpeakElevenLabs` отдал `false` (proxy 502/429), Dart идёт в Google — и пользователь слышит сначала часть ответа голосом Charlotte, а затем внезапно Chirp3-HD-Leda «добивает» остаток. Это и есть «разные люди посреди ответа».

**Вторая настоящая причина.** Fallback внутри одного ответа должен быть удалён / заменён на «или весь ответ EL, или весь ответ Google, никакого mid-way switch».

### H4. Queue-зомби (`_ttsQueue`)

**Статус:** ✅ уже не воспроизводится после `cd39315`, т.к. `_sentenceBuffer.write(chunk)` + единственный `_speakSentence(full)` в конце ничего не кладут в `_ttsQueue`. Но код `_playNextFromQueue` всё ещё существует и может активироваться если кто-то случайно сделает `_ttsQueue.add(...)`.

### H5. Google TTS стримит chunks?

**Статус:** ❌ не стримит. `webTtsSpeakGoogleTts` (`speech.js`) делает ОДИН fetch → `response.blob()` → `advocatPlayBlob(blob)`. Единый MP3, один голос. Для Google TTS mid-response switch невозможен.

### H6. ElevenLabs возвращает стрим?

**Статус:** ❌ нет. `advocatSpeakElevenLabsJson` также делает `response.blob()` и `advocatPlayBlob`. Одно непрерывное аудио.

### H7. При смене сообщения старое аудио не останавливается

**Статус:** ⚠️ Частично. `advocatStopAudio()` есть и вызывается из `stopSpeaking()`, но:

- Если пользователь отправил новое сообщение, пока TTS предыдущего ещё играет, `speak()` вызывается без `stopSpeaking()` наперёд.
- `advocatPlayBlob` вызывает `advocatStopAudio()` перед play (line 181) — **хорошо**, это защищает от наложения.
- Однако между `webTtsSpeakElevenLabs()` и `advocatPlayBlob()` проходит ~0.5-2 сек (fetch time). Если в этот промежуток прилетает ещё один `speak()` от нового сообщения, оба fetch'а завершатся и **оба** попытаются играть — второй отменит первый через `advocatStopAudio()` в `advocatPlayBlob`, но первый мог успеть сказать 100-200 мс. Эффект: «один голос сказал пол-слова и вступил другой».

Это третья причина, хотя и более редкая.

## Резюме: что реально ломает впечатление «единого голоса»

| # | Источник | Серьёзность | Фикс |
|---|----------|-------------|------|
| 1 | Engine fallback (EL→Google→Browser) внутри одного ответа | HIGH | `speak()` не делает mid-response switch — один движок на весь ответ; fallback только на **следующий** ответ (memoize last success). |
| 2 | WarmUp «точка» в момент первого реального speak | MED  | Правильно завершать poll timer и гарантировать `_isSpeaking=false` до того, как следующий `speak()` может стартовать. |
| 3 | Остатки sentence-level TTS (`_ttsQueue`, `_playNextFromQueue`, `_isSpeakingStreamed`, `_sentenceBuffer`, `_speakSentence`) | MED | Удалить. Оставить только `_speakResponse(fullText)` вызываемый один раз в конце streaming. |
| 4 | Race: новый speak до завершения fetch предыдущего | LOW | Добавить `voice.stopSpeaking()` перед каждым `speak()` в `_speakResponse` + `AbortController` для pending fetch. |

Контракт после фикса:

> **Один AI-ответ → один `speak()` → один fetch к TTS-proxy/google-tts → один audio blob → один голос от начала до конца.**
