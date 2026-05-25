# Consilium Phase 1 — Prod Verification (5-min manual check)

**Date:** 2026-05-25
**Build:** 94ddafa on advocat.ee
**Env flag:** `CONSILIUM_LAWYER_ROUTER_ENABLED=true` (set on okgnkucgwsytsondrjye)
**Audience:** Owner (manual SSE / UI confirmation that automated checks cannot cover)

Companion to the longer `consilium_phase1_smoke_runbook.md`. This file is
the 5-minute "is it live?" check.

---

## Automated checks already passing

- Anon traffic does NOT trigger consilium (curl smoke against
  https://okgnkucgwsytsondrjye.supabase.co/functions/v1/claude-proxy
  returns single-LLM JSON, no `consilium_start` SSE frame).
- `_shared/consilium_lawyer_bridge.ts` deployed (file present in prod tree).
- `claude-proxy/index.ts` imports the bridge (line 87) and gates it behind
  `isLawyerRouterEnabled()` (line 945).
- Server-side guard `if (plannerMode && !body.stream && !isAnon)` is
  present at line 866 — anon callers are blocked before they can reach
  the consilium runner.

What the owner still has to verify manually:
- An **authenticated** Pro session actually emits `consilium_start` +
  `role_opinion` SSE frames with lawyer-department role names.
- The Flutter UI renders the multi-role panel.

---

## 3 steps (5 minutes)

### 1. Login as Pro

Open https://advocat.ee/app.html in a normal (non-incognito) window and
sign in with a Pro account.

### 2. Send the canary query

Paste exactly:

```
Mind on käännytetud Soomest EU-kansalaisena, mitä teen?
```

### 3. Open DevTools → Network → claude-proxy → EventStream

Watch for, in order:

1. One `consilium_start` frame containing `roles` with **5+ entries**
   and role names that include at least `senior-asianajaja` or
   `immigration-lawyer` (Phase 1 lawyer-department roster — not the
   legacy `Процессуалист` generic names).
2. **N** `role_opinion` frames — one per role — each with non-empty
   `opinion` text and a `position` value
   (`push` / `settle` / `investigate`).
3. `synthesis_start`, then many `delta` frames with answer text.
4. One terminal `done` or `consilium_done` frame.

In parallel the UI should show the lawyer panel with N cards
materialising, then the synthesis streaming in below.

---

## Pass / fail

- **PASS** = all four SSE event types observed AND role names match the
  lawyer department roster (`senior-asianajaja`, `immigration-lawyer`,
  `strategist`, `litigator`, `researcher`, etc.).
- **PARTIAL PASS** = SSE fires but role names are generic
  (`Процессуалист`, `Материальный юрист`, …) → bridge selected zero
  agents and fell through to legacy runner. Owner files P1, leaves the
  flag ON since the consilium itself still works.
- **FAIL** = no `consilium_start` frame, OR `role_opinion` opinions are
  empty, OR the request 500s. Owner flips
  `CONSILIUM_LAWYER_ROUTER_ENABLED=false` and pings on-call.

---

## Rollback (30 s)

In Supabase → Project Settings → Edge Functions → Secrets:
set `CONSILIUM_LAWYER_ROUTER_ENABLED=false`. Next cold start (≤30 s)
returns to legacy 6-role roster.
