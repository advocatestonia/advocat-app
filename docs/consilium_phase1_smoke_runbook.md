# Consilium Phase 1 — Manual Smoke Runbook

**Audience:** Owner / on-call after deploying claude-proxy + Flutter build that
land the Phase 1 consilium pipeline (lawyer_router → consilium_lawyer_bridge →
runConsilium with `role_opinion` SSE events).

**Date authored:** 2026-05-25
**Estimated time:** 10-15 minutes

---

## 0. Prerequisites

- [ ] `CONSILIUM_LAWYER_ROUTER_ENABLED=true` set in Supabase edge function env
      (default OFF; flip ON to actually exercise the new bridge).
- [ ] Production build deployed (canary or full).
- [ ] Pro account credentials available (anon path is exercised separately).
- [ ] Browser DevTools Network tab open and recording.

---

## 1. Happy path — Pro user, FI immigration query

1. Sign in as a Pro account on https://advocat.ee/app.html.
2. Open a fresh chat (no active case) and send:

   ```
   Mind on käännytetty Soomest, mida teha? KHO 5.6.2026 deadline.
   ```

3. **Watch the UI within 1-3 seconds:**
   - [ ] Header banner appears: "Лоера дума…" / "Lawyers reviewing your case…"
         (depending on locale).
   - [ ] 3-5 role cards materialise. Expected names include
         `senior-asianajaja` and `immigration-lawyer` plus `strategist`.
         (High-stakes branch also adds `researcher` + `litigator`.)
   - [ ] Each card shows a short opinion summary + position chip
         (Push / Settle / Investigate) + confidence badge if any.
   - [ ] Header progresses: "1 of N ready" → … → "N of N ready".
4. **Watch the synthesis:**
   - [ ] "Synthesizing recommendation…" sub-header appears.
   - [ ] Final answer text streams in, contains a probability range and a
         "Следующие шаги" / "Next steps" section.
5. **Watch the footer:**
   - [ ] "Consilium complete · N experts" footer appears.

---

## 2. Network tab — SSE event sequence

While step 1 is running, in DevTools → Network → click the
`claude-proxy` request → EventStream tab. You should see:

- [ ] Exactly **one** `consilium_start` event with `roles`, `roster`, `total`.
- [ ] **N** `role_done` events (one per lawyer in the roster).
- [ ] **N** `role_opinion` events, each carrying:
      `role_id`, `role_name` (or `payload` — see ⚠️ below), `opinion`,
      `position`, optional `confidence`, optional `key_citation`.
- [ ] One `synthesis_start`.
- [ ] Many `delta` events with `{type:"delta", text:"…"}`.
- [ ] Exactly **one** `done` or `consilium_done` terminator.

⚠️ **Known Phase 1 contract gap (TODO 1.1):** `consilium.ts` currently emits
`role_opinion` payload nested under a `payload` key:

```
{type: "role_opinion", payload: {role_id, role, opinion, position, …}}
```

The Flutter parser reads top-level keys. If the cards render but show empty
opinion text / no position chip, this is the cause. The Phase 1.1 patch must
either flatten the backend payload OR teach the parser to unwrap `payload`.
The Deno smoke test `smoke 2+3` and the Flutter test `Phase 1 backend
payload-nested shape is CURRENTLY not parsed` both pin this gap so it can't
regress silently.

---

## 3. Disagreement case (probability split)

1. In a fresh chat, send a question whose answer is genuinely uncertain:

   ```
   Можно ли подать обратно valituslupa в KHO после отказа? Шансы?
   ```

2. **Expected:**
   - [ ] Roster includes `senior-asianajaja` + `litigator` + `strategist`.
   - [ ] At least one role gives a low probability (e.g. 5-10%) AND at least
         one role advocates an alternative track at higher probability.
   - [ ] Footer shows "Experts disagree" banner OR
         `consilium_done.disagreement_detected=true` in network tab.

---

## 4. Edge case — anon user must NOT trigger consilium

1. Open an **incognito window**. Do NOT sign in.
2. Send the same FI immigration query as step 1.
3. **Expected:**
   - [ ] Response arrives as plain streaming text (single LLM call).
   - [ ] **No** `consilium_start` event in the SSE stream.
   - [ ] **No** role cards / lawyer panel appears in the UI.
   - [ ] Network tab shows the response header `X-Advocat-Mode` is absent or
         set to something other than `consilium`.

If consilium fires for an anon caller — **STOP**, file P0, and rollback. The
server-side guard `if (plannerMode && !body.stream && !isAnon)` in
`claude-proxy/index.ts` is broken.

---

## 5. Flag-off rollback drill

If Phase 1 misbehaves and you need to disable the lawyer-department bridge
without redeploying:

1. Set `CONSILIUM_LAWYER_ROUTER_ENABLED=false` in Supabase env.
2. Wait 30 seconds for the edge function to pick up the new env (cold start
   on the next request will re-read it).
3. Send the same query as step 1.
4. **Expected:** consilium still fires (legacy 6-role roster) but the
   department's 11-persona pool is NOT used. Trace string in
   `consilium_start.roster` will show generic names like `Процессуалист`
   instead of `senior-asianajaja`.

---

## 6. Spend tracker check (after 10-20 messages)

- [ ] Visit Supabase dashboard → `spend_tracker` table.
- [ ] Confirm consilium runs are billed under Sonnet (5 roles × ~600 tokens
      input + 1 synthesis call). Roughly $0.03-0.05 per consilium turn.
- [ ] Confirm no anon row has a consilium run (cross-check with step 4).

---

## Sign-off

- [ ] Steps 1-4 all green.
- [ ] No P0 / P1 issues observed.
- [ ] Spend in line with $0.05/turn target.

**Reviewer:** ___________________ **Date:** ___________________
