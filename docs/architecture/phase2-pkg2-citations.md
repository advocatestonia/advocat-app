# Phase 2 Pkg 2 — Citations API + Grounding pipeline

**Status:** design (2026-05-06). Implementer agent picks this up next.
**Owner of brief:** `data/handoff_phase2_advanced.md` (Pkg 2 section).
**Depends on:** Pkg 1 (`law_chunks.in_force`/`jurisdiction`, `lookup_statute` RPC, P0-1/P0-2/P0-3 RAG corpus).
**Migration filename (next slot):** `20260507_08_message_citations.sql`.

---

## 1. Goal

Every load-bearing legal claim in an assistant reply MUST be grounded to a specific RAG chunk that was actually retrieved during that turn. The model emits inline markers, the proxy parses them post-hoc, matches each marker against the chunks injected into that same turn's system prompt, and returns a structured `citations[]` array alongside the reply. The Flutter chat renders markers as tappable chips, opens a bottom sheet with verbatim chunk text + Riigi Teataja link, and shows verified/unverified badges per message. No second LLM call. Failure mode: marker without retrieved chunk = `unverified` badge, never silent deletion.

---

## 2. Marker syntax

**Picked: `[[ref:TLS:88]]`** (double-bracket, colon-delimited, lowercase `ref:` keyword, then `act_slug:paragraph`, optional `:lang` suffix for EU directives e.g. `[[ref:32019L1152:5:en]]`).

**Why:**
- Regex-trivial: `\[\[ref:([A-Z0-9]+):([^:\]]+)(?::([a-z_]+))?\]\]` — one anchored regex, no false positives on prose.
- Visually distinct: nothing in Estonian/Finnish/Russian legal prose uses double-square-brackets, so collisions are zero. `[TLS §88]` collides — we already see human authors writing `[TLS §88]` in chat as quoted text.
- Markdown-safe: GitHub-flavored Markdown does not interpret `[[...]]` (it's wiki-link syntax, but our renderer is custom — we own the parser).
- Survives translation: the model preserves the literal `[[ref:...]]` token even when emitting Russian or Finnish prose around it; bracket-with-prose forms (`[§88 TLS]`) are tempting to translate ("§88 ТЛС").
- Trivial to compose chunk_id: `act_slug + paragraph` already maps 1:1 to `law_chunks.id` (e.g. `tls-§88-1`); the proxy can resolve marker → chunk_id → row in one pass.

**Rejected alternatives:**

- `[TLS §88]` — natural to read but (a) the model already emits this prose-style as a habit, so we can't distinguish "model citation" from "user quoting model" in chat history; (b) unicode `§` survives copy-paste poorly across pdf exports; (c) collides with how human lawyers write footnotes in drafted documents — Pkg 7 (Drafting Studio) will choke.
- `[§TLS:88]` — readable, regex-cheap, but the leading `§` makes the marker indistinguishable from a Russian-language prose citation `§88 закона...` — high false-positive rate on the verifier regex.

**Model instruction (added to `injectLawContext` directive block):**
> When you cite ANY paragraph from the RAG block above, append the marker `[[ref:ACT:PARAGRAPH]]` immediately after the claim. Use the `act_slug` and `paragraph` fields shown in the chunk header. One marker per cited paragraph. If you cannot ground a legal claim in the chunks above, write "не могу подтвердить точную норму" (or the user-language equivalent) — do NOT invent a marker.

---

## 3. claude-proxy contract changes

### Old response shape (today)

```json
{ "content": [{"type":"text","text":"..."}], "usage": {...}, "model": "..." }
```

(Anthropic raw, forwarded ~as-is.)

### New response shape (Pkg 2)

```json
{
  "content": [{"type":"text","text":"...with [[ref:TLS:88]] markers..."}],
  "usage": {...},
  "model": "...",
  "citations": [
    {
      "marker": "[[ref:TLS:88]]",
      "status": "verified",                       // 'verified' | 'unverified' | 'historical'
      "chunk_id": "tls-§88-1",                    // null if unverified
      "act_slug": "tls",
      "act_name": "Töölepingu seadus",
      "paragraph": "88",
      "title": "Tööandja erakorraline ülesütlemine",
      "snippet": "Tööandja võib töölepingu erakorraliselt ...", // ≤400 chars from body
      "source_url": "https://www.riigiteataja.ee/akt/tls",
      "in_force": true,
      "occurrences": 2                            // number of marker hits in reply
    }
  ]
}
```

### Pipeline order inside `claude-proxy/index.ts`

1. Existing auth + rate-limit + quota checks (unchanged).
2. Existing `injectLawContext(prompt, ragChunks)` — proxy already sees the chunks because the client passes them in `system` field assembled by `system_prompts.dart`. **NEW:** proxy stores the retrieved-chunk index server-side keyed by `request_id` so the verifier in step 5 doesn't need a re-fetch.
3. Anthropic API call (single shot, unchanged).
4. **NEW: grounding verifier** runs synchronously on the response text before returning to client. See §4.
5. Return augmented JSON.

**Latency budget:** verifier is pure regex + in-memory map lookup — target p95 < 5ms added. Confirmed by smoke: 8 markers × O(1) lookup is negligible vs the 3-15s Anthropic call.

**Caller contract:** `claude_service.dart` already attaches `lawChunks` via `injectLawContext` in `system_prompts.dart`. To make those chunks reachable by the verifier without parsing the system prompt back, we add a sidecar field to the request body:

```jsonc
// New request shape (additive, back-compat):
{
  "model": "...",
  "system": "...injected prompt with RAG block...",
  "messages": [...],
  "rag_context": {                // NEW — proxy uses for verification, never forwards to Anthropic
    "chunks": [
      {"id":"tls-§88-1","act_slug":"tls","paragraph":"88","act_name":"...","body":"...","source_url":"...","in_force":true}
    ]
  }
}
```

Proxy strips `rag_context` before forwarding to Anthropic. If `rag_context` absent → verifier still runs but every marker resolves `unverified` (legacy clients keep working — this is the back-compat seam).

---

## 4. Grounding verifier algorithm

```text
function verify(replyText, ragChunks):
  index := build_index(ragChunks)
    # key: lower(act_slug) + ":" + paragraph
    # value: chunk row
  citations := []
  seen := {}
  for marker_match in REGEX.findall(replyText):
    act, para, lang_suffix := normalize(marker_match)
    key := lower(act) + ":" + para
    if key in seen:
      seen[key].occurrences += 1
      continue
    chunk := index.get(key)
    if chunk is null:
      status := 'unverified'        # model cited a § that wasn't retrieved
    elif chunk.in_force is false:
      status := 'historical'        # cited but superseded version in corpus
    else:
      status := 'verified'
    citation := build_citation(marker_match, chunk, status)
    citations.append(citation)
    seen[key] := citation
  return citations
```

### Edge cases

| Case | Behaviour |
|---|---|
| Model cites verbatim chunk (TLS §88, retrieved) | `verified`, `chunk_id` set, full snippet from `chunk.body[:400]` |
| Model paraphrases retrieved chunk + cites correctly | Same as above — verifier is reference-level, not text-level. We do NOT do textual-similarity verification in v1 (see Risks). |
| Model cites § NOT retrieved (`[[ref:KarS:217]]` but only TLS chunks were in RAG) | `unverified`, `chunk_id=null`, snippet from local fallback `lookup_statute(act,para)` if available, else null. **Important:** verifier MAY call `lookup_statute` RPC for unverified markers as a "did the model hallucinate or just cite something we have but didn't retrieve" disambiguation — bounded at 5 lookups per response to cap latency. Result: `unverified-but-exists` collapsed under `unverified` in v1 (the chunk wasn't in the model's actual context, so we still flag it). |
| Model cites § retrieved but `in_force = false` | `historical` — UI shows amber badge "historical version, may be superseded". Should be rare since `law_search` filters `in_force = true`, but the EU directive flow can return historical. |
| Model emits markdown-style `[TLS §88]` instead of `[[ref:...]]` | NOT counted as a citation. Reply ships with empty `citations[]` for that claim. The Flutter UI's footer will display "0 citations" — visible signal to the model-prompt-tuner that few-shot is needed. We do NOT regex prose-style as fallback (collision rate too high). |
| Marker malformed (`[[ref:TLS]]` no paragraph) | Skipped silently in v1, logged at WARN for prompt-quality monitoring. |
| Same marker repeats (`[[ref:TLS:88]]` × 3 in reply) | Deduplicated to ONE citation entry with `occurrences = 3`. UI renders all three inline chips, but the bottom sheet opens once. |
| EU directive lang suffix (`[[ref:32019L1152:5:en]]`) | Lookup key is `32019l1152:5`; lang only used to pick which `eu_*` row's body to render in the snippet. |

### Why verifier runs in proxy, not client

- Server has authoritative chunks (already injected into prompt that turn). Client could spoof.
- Proxy is the only place all three signals (request, response, retrieved chunks) coexist for one turn.
- Adding it client-side would duplicate the regex + lookup table on every render.

---

## 5. DB schema — `chat_message_citations`

**Decision: persist.** Transient response-payload-only would be enough for the chat itself, but Pkg 7 (Drafting Studio) and Pkg 8 (eval suite) both need to score "what % of historical assistant replies were verified" without re-running verification. Persisting also lets Pkg 4 (Case Workspace) render citation density per case as a quality signal. Cost is one INSERT batch per assistant message — trivial.

### Migration `20260507_08_message_citations.sql`

```sql
-- =============================================================================
-- Phase 2 Pkg 2 — chat_message_citations
--   Per-marker grounding outcome attached to a chat_messages row. Written by
--   the claude-proxy verifier after each Anthropic round-trip. Read by:
--     • Flutter chat (renders chips + bottom sheet + verified/unverified badges)
--     • Pkg 8 eval suite (citation precision metric)
--     • Pkg 4 Case Workspace (per-case citation density)
--
-- Owned by the user who owns the chat_messages row (cascade delete via FK).
-- RLS: read-own-only. Writes via service-role (proxy) only — no INSERT policy.
-- =============================================================================

create table public.chat_message_citations (
    id              uuid primary key default gen_random_uuid(),
    message_id      uuid not null references public.chat_messages(id) on delete cascade,
    user_id         uuid not null references public.users(id) on delete cascade,
    case_id         uuid not null references public.cases(id) on delete cascade,

    marker          text not null,                    -- '[[ref:TLS:88]]'
    status          text not null check (status in ('verified', 'unverified', 'historical')),
    chunk_id        text references public.law_chunks(id) on delete set null,

    act_slug        text not null,
    paragraph       text not null,
    act_name        text,
    title           text,
    snippet         text,                             -- ≤400 chars; truncated body
    source_url      text,
    jurisdiction    text,
    in_force        boolean,                          -- snapshot at verification time
    occurrences     int not null default 1 check (occurrences > 0),

    created_at      timestamptz not null default now()
);

create index chat_message_citations_message_idx
    on public.chat_message_citations (message_id);
create index chat_message_citations_case_idx
    on public.chat_message_citations (case_id, created_at desc);
create index chat_message_citations_status_idx
    on public.chat_message_citations (status) where status <> 'verified';
    -- partial index — most rows are 'verified', the ones we filter for
    -- (eval / monitoring) are the unverified/historical minority.

alter table public.chat_message_citations enable row level security;

-- Read: owner only. Mirrors chat_messages_select_own.
create policy "chat_message_citations_select_own"
    on public.chat_message_citations
    for select
    using (auth.uid() = user_id);

-- Write: service-role only (claude-proxy). NO INSERT/UPDATE/DELETE policy
-- means anon + authenticated cannot write directly — only the verifier can.

-- Optional helper RPC for the Flutter side to fetch all citations for a
-- given message in one round-trip (vs filtering chat_message_citations
-- on the client). Owner-checked, security definer, explicit search_path,
-- auth.uid() null-guard per project convention.
create or replace function public.message_citations(p_message_id uuid)
returns setof public.chat_message_citations
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_owner uuid;
begin
    if auth.uid() is null then
        raise exception 'unauthorized' using errcode = '42501';
    end if;

    select user_id into v_owner
      from public.chat_messages
     where id = p_message_id;

    if v_owner is null or v_owner <> auth.uid() then
        raise exception 'forbidden' using errcode = '42501';
    end if;

    return query
        select *
          from public.chat_message_citations
         where message_id = p_message_id
         order by created_at asc;
end;
$$;

grant execute on function public.message_citations(uuid) to authenticated;
alter function public.message_citations(uuid) owner to postgres;

notify pgrst, 'reload schema';
```

**FK to `law_chunks(id)` is `on delete set null`** — corpus refreshes (monthly scheduled trigger per `reference_scheduled_triggers.md`) replace `law_chunks` rows; we don't want historical citations to cascade-delete. The snapshot fields (`act_slug`, `paragraph`, `snippet`, `source_url`, `in_force`) preserve the citation even if the chunk row is gone.

---

## 6. Flutter rendering contract

### JSON the proxy returns (already specified §3)

Flutter receives the augmented response, reads `response.citations`. The `claude-proxy` Dart client (`lib/services/claude_service.dart`) passes citations through to the chat repository, which persists them via the same INSERT path used for `chat_messages`. **Implementer note:** the proxy ALSO writes `chat_message_citations` server-side with service role, so the client INSERT is optional belt-and-suspenders — pick one path, prefer server-side to avoid race with offline queue.

### Widget spec (NOT building — spec only)

**1. Inline marker renderer** — `CitationMarkerSpan` (in `lib/features/chat/widgets/`)
- Input: assistant `content` string + `List<MessageCitation>`
- Behaviour: regex-replace `[[ref:ACT:PARA(:LANG)?]]` → `WidgetSpan` containing a `Chip(label: "ACT §PARA", onTap: ...)`. Chip color: green = verified, amber = historical, red = unverified.
- Edge: same marker appearing twice gets two chips both pointing to the same bottom sheet.

**2. Bottom sheet** — `CitationDetailSheet`
- Trigger: chip tap.
- Content (top→bottom):
  - `act_name` (heading, e.g. "Töölepingu seadus")
  - `§paragraph — title` (subhead)
  - In-force badge (green ✓ or amber "historical version")
  - `snippet` in blockquote
  - "Avada Riigi Teatajas →" button (deep link, see §7)
  - "Lisa märkus" (Pkg 5 hook — out of scope here, button stub OK)

**3. Per-message citations footer** — `MessageCitationsFooter`
- Collapsed by default, shows summary: `"3 verified · 1 unverified"`
- Expand → list of all citations with status badge + tap = open same bottom sheet.
- If `citations.isEmpty` AND message is assistant role AND message contains legal-looking content (heuristic: contains `§` OR matches `_legalishStems`) → small text "⚠ no grounded citations" — quality signal for the user.

### Rendering invariants

- Marker regex on the client MUST match the server regex exactly. Defined as a single Dart constant `kCitationMarkerPattern` in `lib/core/citations/marker.dart`, mirrored by a Deno constant in `_shared/citations/marker.ts`. Contract test (§8) parses the same string with both regexes and asserts equality.
- If `citations[].status === 'unverified'`, the chip MUST render but in red — NEVER hidden. Transparency over polish.

---

## 7. Riigi Teataja URL builder

**Convention:** corpus stores `act_slug` lowercase (`tls`, `kars`, `vols`, `hms`). `law_chunks.source_url` is already populated by the P0-1 scraper with the canonical RT URL. **Use that field first.** Builder only kicks in when `source_url` is null (legacy rows or EU directives).

**Builder spec** (in `lib/core/citations/riigi_teataja_url.dart` — Dart-side only, server doesn't need it):

```dart
String buildRiigiTeatajaUrl({
  required String actSlug,
  required String paragraph,
  required String jurisdiction,
  String? sourceUrl,      // prefer this if non-null
}) {
  if (sourceUrl != null && sourceUrl.isNotEmpty) {
    // Append §-anchor if not already present.
    return sourceUrl.contains('#') ? sourceUrl : '$sourceUrl#para$paragraph';
  }
  if (jurisdiction == 'EE') {
    // Riigi Teataja convention: latest in-force redirect lives at /akt/{slug}.
    // Anchor #para88 is supported by RT's own paragraph IDs.
    return 'https://www.riigiteataja.ee/akt/${actSlug.toLowerCase()}#para$paragraph';
  }
  if (jurisdiction == 'EU') {
    // CELEX-ID acts (32019L1152) live on EUR-Lex.
    return 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:${actSlug.toUpperCase()}';
  }
  if (jurisdiction == 'FI') {
    // Stub for Pkg 1's planned FI corpus expansion.
    return 'https://www.finlex.fi/fi/laki/ajantasa/?keyword=${actSlug.toLowerCase()}';
  }
  return 'https://www.riigiteataja.ee/akt/${actSlug.toLowerCase()}';
}
```

**Versioned-historical URL is OUT OF SCOPE.** When `status == 'historical'` we still link to the in-force version + show the amber badge with `version_date` from the snapshot. Building real version-pinned RT URLs needs the act's `?leiaKehtiv=Y&dateB=YYYYMMDD` form, which requires per-act ID resolution from RT's own URL scheme — Pkg 9 work, not this Pkg.

---

## 8. Test plan (3-5 contract + 3-5 widget/golden)

### Contract tests (Deno, in `supabase/functions/claude-proxy/__tests__/`)

1. `test_grounding_verifier_marker_match` — given a reply `"...TLS §88[[ref:TLS:88]] applies"` and a `rag_context.chunks` containing `tls-§88-1`, verifier returns `[{status:'verified', chunk_id:'tls-§88-1', occurrences:1}]`.
2. `test_grounding_verifier_unverified_marker` — reply contains `[[ref:KarS:999]]`, no matching chunk in `rag_context` → `status:'unverified', chunk_id:null`.
3. `test_grounding_verifier_dedup_occurrences` — same marker × 3 → one entry with `occurrences:3`.
4. `test_grounding_verifier_historical_chunk` — chunk in context has `in_force:false` → `status:'historical'`.
5. `test_grounding_verifier_strips_rag_context_before_anthropic` — request with `rag_context` field; Anthropic mock asserts the forwarded payload has no `rag_context` key.
6. `test_marker_regex_parity_dart_vs_deno` — load fixture `test/fixtures/citations/markers.txt` (~50 examples, valid + invalid + edge-case unicode), parse with both Dart `kCitationMarkerPattern` and Deno regex, assert identical match arrays. Lives as Dart test (since Deno can't run Dart) — Deno side parses via subprocess or shared JSON snapshot.

### Widget / golden tests (Flutter, in `test/features/chat/`)

1. `citation_marker_span_renders_chip_per_marker` — message with 2 distinct markers → 2 chips. Verify color matches status.
2. `citation_marker_span_dedupes_visually` — same marker × 3 → 3 chips visible, all chip taps open the same bottom sheet (assert sheet's `chunk_id` consistent).
3. `citation_detail_sheet_golden_verified` — golden test: `status='verified'`, fully populated citation → screenshot match.
4. `citation_detail_sheet_golden_unverified` — golden test: `status='unverified'`, `chunk_id:null` → red badge + no "Avada Riigi Teatajas" button (since no source URL).
5. `message_footer_warns_on_legal_content_without_citations` — message with `§` in body but `citations:[]` → footer shows "⚠ no grounded citations" string.

### Smoke seam (extends canary `prod_smoke.sh`)

- Add Seam F: POST a known query that should retrieve TLS §88, assert response contains `[[ref:TLS:88]]` AND citations array has at least one `verified`. False-positive risk: model occasionally rewords. Smoke uses a deterministic RAG fixture that injects a chunk + uses tool_choice forcing — keep the smoke happy-path narrow.

---

## 9. Risks (top 3)

1. **Model ignores marker syntax.** Sonnet 4.6 follows structured-output constraints well, but in long replies (>2k tokens) it drifts back to prose-style citations. Mitigation: (a) explicit one-shot example in `injectLawContext` showing a verbatim `[[ref:TLS:88]]` use; (b) Pkg 8 eval suite includes a "marker compliance" rubric — if eval drops below 90% marker emission rate, prompt is revised. **Fallback:** if marker rate <50%, ship a Haiku post-pass that adds markers — opt-in, not default (cost + latency hit, only triggered if a feature flag flips).

2. **Verifier latency on long replies with many markers.** A reply with 30 markers × 5 fallback `lookup_statute` RPC calls = 5 Postgres round-trips at ~10ms each = 50ms tail. Cap of 5 fallback lookups per response (configurable) bounds this. Headroom: full pipeline today is 3-15s, +50ms is noise. **Real risk** is the proxy holding response open synchronously — if anyone changes the proxy to streaming mode (Anthropic SSE), verifier needs to run on the post-stream concat, NOT per-event.

3. **Paraphrased-but-correct citations counted as unverified.** If model writes "по статье 88 закона о труде" without the marker even though the chunk WAS retrieved, we mark zero citations. False-negative. Acceptable in v1 because: (a) the model is instructed to always emit the marker; (b) over-counting (textual-similarity-based "soft verify") is dangerous — it lets the model dodge the structured-output rule. Pkg 8 will measure; if false-negative rate > 20%, v2 adds a Haiku judge as a separate pass (NOT inline — cost).

---

## 10. Out of scope for this Pkg

- **Versioned-historical RT URLs.** Bottom sheet shows in-force version + amber "historical" badge. True version-pinned URLs need RT's date-param scheme — Pkg 9.
- **Cross-reference expansion.** Markers like `[[ref:TLS:88]]` referring to "in conjunction with §90" stay as a single marker. Multi-§ syntax (e.g. `[[ref:TLS:88,90]]`) is v2.
- **EU directive paragraph anchors.** EU markers link to the directive landing page, not the article — EUR-Lex doesn't have stable per-article fragment IDs across translations.
- **Soft-verify by textual similarity.** Risk #3 above — explicit non-goal until eval data justifies it.
- **Citation editing by user.** User cannot mark a citation as "this is wrong" in this Pkg. Pkg 5/6 (Conversation State Machine + Self-critique) introduces feedback loops.
- **FI / RU jurisdictions.** Builder stubs them, but corpus is EE+EU only today — hitting an FI marker today returns `unverified` (no chunk) which is correct.
- **Anthropic's native Citations API.** The handoff brief mentions it as Layer 1 of three. We deliberately use our marker scheme instead because (a) it gives us the act-slug+paragraph join key directly; Anthropic Citations returns character spans into the document blocks which would require us to maintain a span→chunk_id map; (b) our approach works with any model in the future (Haiku, Opus, third-party) without depending on Anthropic-specific response shape. Native Citations API can be ADDED as a layer 1 if eval shows our marker compliance is too low to ship — design supports both since both feed the same `chat_message_citations` table.
