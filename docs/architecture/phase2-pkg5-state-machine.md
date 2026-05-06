# Phase 2 Pkg 5 — Conversation State Machine

**Status:** shipping (2026-05-06).
**Owner of brief:** `data/handoff_phase2_advanced.md` Pkg 5 — «где мы в кейсе: intake / strategy / draft / wait».
**Depends on:** Pkg 1 (`user_cases` schema, `load_active_case` RPC, `case-auto-patch` Haiku extractor), Pkg 3 (intake wizard exit signal), Pkg 9 (`case_deadlines` for `wait`-phase nudges), Email D4 (triage results flip phase on inbound).
**Coordinates with:** Pkg 4 (Case Workspace consumes `phaseBadge`), Pkg 6 (Planner consumes phase context in system prompt).

---

## 1. Goal

Today the chat is stateless across sessions per case. The user comes back a week later, has to re-explain what was last discussed, and the assistant has no anchor for "what should we do next?" beyond the raw `user_cases` JSONB facts.

Pkg 5 introduces a **conversation state machine per case** with five explicit phases:

| Phase | Meaning | Drives |
|---|---|---|
| `intake` | Gathering facts (jurisdiction, parties, dates, case_numbers). | Pkg 3 intake wizard, "complete your file" CTA on the workspace Overview tab. |
| `strategy` | Assistant proposes legal strategy — forum selection, evidence prioritisation, deadline mapping. | Phase-aware system prompt focuses model on triage/options, not draft mechanics. |
| `draft` | Actively producing pleadings/letters with the user. | Draft-mode system prompt, draft tool affordances surfaced. |
| `wait` | Waiting on an external event (court reply, opposing counsel, document arrival). Inactive but tracked. | `agent_intentions` nudges when a `case_deadlines` row inside this case crosses a 3-day window; resume prompt on cold start. |
| `closed` | Case archived. | Read-only mode; no auto-transitions. |

The phase is **case-scoped** (one row in `user_cases` = one phase value). General-chat mode (no active case) has no phase.

---

## 2. State enum + transition table

**Phase enum:** `intake`, `strategy`, `draft`, `wait`, `closed` — pinned by a CHECK constraint on the column. Default `'intake'`.

**Transitions** (server-side auto + client-side manual override):

| From | To | Trigger | Source |
|---|---|---|---|
| `intake` | `strategy` | User has answered min facts: `case_numbers` non-empty AND `parties` non-empty AND at least one `key_dates` entry. | Pkg 3 intake wizard exit (writes phase directly) OR `case-auto-patch` after a Haiku turn that fills the missing field. |
| `strategy` | `draft` | User clicks "Draft this letter" in chat OR assistant proposes a draft + user accepts ("yes draft it", "OK"). | Manual via `case_phase_service.dart` (UI button) OR `case-auto-patch` detects an explicit user-accept utterance. |
| `draft` | `wait` | User sends a letter via Email Agent (D4 outbound) OR explicitly says "I delivered it" / "отправил" / "saadetud". | `case-auto-patch` regex on user message OR Email Agent send-success hook. |
| `wait` | `strategy` | Inbound Gmail thread triaged as `requires_action` for this case OR a deadline inside this case has <=3 days remaining. | Email triage D4 (triage_status='requires_action' → flip) OR `agent-intentions-cron` nudge. |
| any | `closed` | User taps "Archive" / "Close case" in workspace. | Manual via `case_phase_service.dart`. |
| `closed` | any | Disallowed by default — user must reopen via `unarchive` (out of scope, Pkg 4). | — |

**Idempotency rule:** transitions are no-ops when `phase` is already the target. The auto-patch path always reads the current phase before writing, never blindly stomps.

**Backwards compat:** existing `user_cases` rows default `phase='intake'` on migration. Rows with non-empty `case_numbers` array auto-promote to `strategy` in the same migration step (one-shot), so a Sulga-class case that already has 5500/R/75170/25 doesn't sit awkwardly in `intake`.

---

## 3. Schema

### Migration `20260507_15_case_phase.sql` (slot 15, after parallel `_14_email_user_settings.sql`)

```sql
alter table public.user_cases
    add column if not exists phase            text,
    add column if not exists phase_entered_at timestamptz,
    add column if not exists phase_metadata   jsonb;

-- One-shot backfill: existing rows go to 'strategy' if they already have
-- a case_number on file (past intake), otherwise 'intake'.
update public.user_cases
   set phase = case
                 when jsonb_array_length(case_numbers) > 0 then 'strategy'
                 else 'intake'
               end,
       phase_entered_at = coalesce(phase_entered_at, created_at, now()),
       phase_metadata   = coalesce(phase_metadata, '{}'::jsonb)
 where phase is null;

alter table public.user_cases
    alter column phase set default 'intake',
    alter column phase set not null,
    alter column phase_entered_at set not null,
    alter column phase_metadata set not null,
    alter column phase_metadata set default '{}'::jsonb,
    add constraint user_cases_phase_chk
        check (phase in ('intake','strategy','draft','wait','closed'));

create index if not exists user_cases_phase_idx
    on public.user_cases (user_id, phase) where status = 'active';

-- RPC: set_case_phase(p_case_id, p_phase, p_metadata) — idempotent,
-- security invoker, RLS-bound. No-op when current phase already matches.
create or replace function public.set_case_phase(...)
```

The CHECK constraint name is `user_cases_phase_chk` — referenced by the contract test.

### Why no separate `case_phases_history` table

Out of scope: each transition just stomps the row. Audit trail is already present in `audit_log` (Pkg 0) for sensitive ops; phase changes are mundane state changes and don't justify a parallel ledger. If we ever need history, `phase_metadata jsonb` can carry a small ring buffer.

---

## 4. Auto-transition rules in `case-auto-patch`

The Haiku extractor (Pkg 1.C) already runs after every assistant turn on a case-aware chat. We extend it MINIMALLY — one additional optional field in the patch JSON:

```jsonc
{
  // … existing fields …
  "phase_transition": null | {
    "to": "intake" | "strategy" | "draft" | "wait",
    "reason": "<short rationale, <=120 chars>"
  }
}
```

Rules taught to Haiku in the system prompt extension:

- `intake → strategy`: when the snapshot already has `case_numbers` non-empty AND parties non-empty AND ≥1 `key_dates`, AND the user message or AI reply indicates "we're moving to strategy" (NOT every turn — the model only emits this if it's a clear transition).
- `strategy → draft`: user explicitly accepts a draft proposal ("yes draft it", "OK сделай", "jah, koosta", "let's draft") — Haiku flags it.
- `draft → wait`: user says they sent / delivered the document ("отправил", "saatsin", "I sent it", "delivered").
- Never emit `closed` from auto-patch — closure is always manual.
- Never demote (no `strategy → intake`) from auto-patch — only the user can manually back up.

The `case-auto-patch` index.ts then calls `set_case_phase` RPC if `phase_transition` is non-null AND the snapshot's current phase differs.

This pattern keeps the `case_patch_prompt.ts` parser module pure — no new I/O, just one optional field. The RPC call lives in `case-auto-patch/index.ts` after the JSONB merge.

---

## 5. Manual override

`CasePhaseService.setPhase(caseId, phase)` — Riverpod-exposed Dart service that calls `set_case_phase` RPC directly, bypassing Haiku. UI surfaces this as:

- "Mark as draft / Wait / Close case" actions on the workspace Overview tab (Pkg 4).
- Implicit on Pkg 3 intake-wizard final step: writes `phase='strategy'` server-side after the Sonnet greeting completes.

The service:

```dart
abstract class CasePhaseService {
  Future<CasePhaseTransition> setPhase(String caseId, CasePhase phase, {Map<String,dynamic>? metadata});
}
```

Auto-invalidates `caseByIdProvider` and `casesListProvider` so the UI re-renders the badge.

---

## 6. Phase-aware system prompt

`SystemPrompts.buildChatPrompt` gains a new optional parameter `casePhase: CasePhase?` and the rendered prompt includes a phase block AFTER the memory block, BEFORE the legal KB. Contract pinned by tests.

**One-line example of the injected block (`strategy` phase):**

```
# CASE PHASE — STRATEGY
You are in the STRATEGY phase for this case (entered ${phaseEnteredAt}). Focus on: forum selection, evidence prioritisation, deadline mapping. Do NOT draft full pleadings yet — propose options and trade-offs first.
```

Per-phase guidance copy lives in a private const map in `system_prompts.dart` (`_phaseGuidance`). Languages: model-agnostic English (the existing prompt is English).

When `casePhase` is null (general chat / no active case), no phase block is injected (backwards compatible with all existing call sites).

`SystemPrompts.injectPhaseContext(existingPrompt, phase, phaseEnteredAt)` is exposed as a **standalone helper** for the claude-proxy edge function path — same pattern as `injectLawContext` for RAG, so the proxy can fold it in without rebuilding the whole prompt.

---

## 7. UI

### 7.1 Phase badge widget — `phase_badge.dart`

Pure stateless widget rendering `[icon] PHASE_NAME` with phase-coloured chip. Used by:
- Pkg 4 workspace Overview tab (top-right of header).
- Active-case chip in chat composer (replaces just the title — chip becomes `📁 Title · STRATEGY`).
- Cases list row trailing element.

Localised labels via `AppLocalizations.casePhase{Intake|Strategy|Draft|Wait|Closed}`. Falls back to the raw enum name when l10n missing.

### 7.2 Resume prompt — `case_resume_banner.dart`

When the user opens a case chat and the previous session ended >24h ago (computed from latest `case_chat_sessions.ended_at` for this case) AND the case has a non-trivial phase (`strategy|draft|wait`), show a top banner:

> Last time we were in **strategy**. You were going to upload the medical certificate. Did you?

Banner copy is built from `(phase, phase_metadata.last_action_summary, time_elapsed_label)`. Dismissible. Stored dismissals via SharedPreferences key `advocat.case_resume_dismissed.<caseId>.<phaseEnteredAt epoch>` — re-shows on next phase entry.

### 7.3 Indicator chip in active-case area

Existing `ActiveCaseChip` (`active_case_chip.dart`) gets a phase suffix — a small `· STRATEGY` chip after the title, same colour as the badge. No new widget, just a 1-line edit in the chip.

---

## 8. agent_intentions integration

When the auto-patch flips a case to `wait` AND a `case_deadlines` row for that case has `due_at <= now() + 3 days`, `case-auto-patch` writes (via service-role) an `agent_intentions` row:

```jsonc
{
  intent_type: "remind_deadline",
  case_id: "<uuid as text>",
  target_id: "<deadline.id>",
  next_check_at: "<min(deadline.due_at - 24h, now() + 1h)>",
  conversation_context: { summary: "case in wait, deadline <label> in <N>d", locale: "ru" }
}
```

The existing `agent-intentions-cron` (D7-wired) picks it up and pushes a notification, which on user resume drives the `wait → strategy` flip via the resume banner ("got the response — let's plan the next move").

Email D4 triage already calls into `agent-intentions-cron`; on a `requires_action` triage we additionally trigger `set_case_phase(case_id, 'strategy')` server-side if the thread is mapped to a case (mapping is the email_threads.case_id column added in D2, FK currently optional — a no-op for unmapped threads).

---

## 9. Test plan (10 tests minimum)

| ID | Layer | What it pins |
|---|---|---|
| CPS-T01 | migration | `phase`, `phase_entered_at`, `phase_metadata` exist; CHECK includes 5 values; default `'intake'`. |
| CPS-T02 | migration | Backfill: rows with non-empty `case_numbers` get `phase='strategy'`; empty get `'intake'`. |
| CPS-T03 | shared/case_phase | `parseCasePhase` round-trips all 5 enum values; unknown → null. |
| CPS-T04 | shared/case_phase | `nextAutoPhase(snapshot, currentPhase, signals)` returns correct transition for each rule (5 transitions × at least 1 happy + 1 negative). |
| CPS-T05 | system_prompts | When `casePhase` provided, prompt contains `# CASE PHASE — <NAME>` block; sits AFTER memory block, BEFORE `# LEGAL KNOWLEDGE BASE`. |
| CPS-T06 | system_prompts | When `casePhase` is null, no `CASE PHASE` header anywhere; existing call-sites unchanged. |
| CPS-T07 | system_prompts | `injectPhaseContext(existingPrompt, phase, enteredAt)` standalone helper produces a single new block; idempotent on re-injection (no double block). |
| CPS-T08 | service (Dart) | `CasePhaseService.setPhase` calls RPC with right args; updates active case state; invalidates providers. |
| CPS-T09 | edge fn | `case-auto-patch` calls `set_case_phase` when Haiku output carries valid `phase_transition`; skips when transition is to current phase. |
| CPS-T10 | widget | `PhaseBadge` renders correct color + l10n label per phase. |

**Total target:** +30 tests.

---

## 10. Out of scope (explicitly)

- Phase history / audit trail beyond `phase_entered_at`.
- Reopening closed cases (Pkg 4 owns archive UI).
- Multiple concurrent phases (a case is in exactly one).
- Cross-case phase coordination (each case is independent).
- Localising the phase guidance text in the system prompt — model is English-prompt-driven; user-facing labels are localised, prompt is not.
