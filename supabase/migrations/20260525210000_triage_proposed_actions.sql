-- =====================================================================
-- Parallel Actions Panel — proposed_actions on email_triage_results.
--
-- Pattern source (2026-05-25): the Sulga case manual consilium emitted
-- TWO parallel email actions in a single synthesis (one reply to Jokela,
-- one asiakirjapyyntö to poliisi kirjaamo). We want the UI to surface
-- both in one card with a single "Approve All & Send" tap. The data
-- model already had one draft per triage row (draft_body / draft_to /
-- draft_subject); proposed_actions extends that to N >= 1 without
-- breaking the legacy single-draft path.
--
-- Column:
--   * proposed_actions JSONB NULL — array of structured actions. When
--     NULL or empty, the inbox UI falls back to the legacy single-draft
--     TriageCard. When length >= 1, the new ParallelActionsCard renders.
--     idx=0 is the canonical "primary" action (mirrors draft_*). When
--     populated alongside the legacy draft_* columns the UI prefers
--     proposed_actions[0] but the legacy fields stay readable for any
--     consumer that hasn't been updated yet (chat assistant tools,
--     `approve_send_draft` flow, etc).
--
-- Shape of each entry (consumer-visible):
--   {
--     "idx":        int,          -- 0..N-1, stable ordering
--     "kind":       text,         -- "email_reply" | "email_new"
--     "to_addr":    text,         -- single primary recipient
--     "cc":         text[],       -- optional
--     "subject":    text,
--     "body":       text,         -- plaintext for now
--     "language":   text,         -- ISO code for the draft language
--     "citations":  jsonb,        -- [[ref:slug:para]] markers preserved
--     "gate_token": jsonb,        -- per-action HMAC token (may be null
--                                 -- when policy_gate did not pass)
--     "rationale":  text          -- 1-2 sentence "why this action"
--   }
--
-- Legacy `draft_body` / `draft_to` / `draft_subject` / `draft_language`
-- stay populated for backwards compatibility with the assistant tools
-- contract (list_inbox / approve_send_draft) — the email-triage edge
-- function copies proposed_actions[0] into the legacy columns when it
-- emits a multi-action plan. This means existing API consumers see
-- exactly one draft and never break.
--
-- Idempotent: every DDL is `if not exists`.
-- =====================================================================

-- ── 1. proposed_actions column ────────────────────────────────────────
alter table public.email_triage_results
    add column if not exists proposed_actions jsonb;

-- ── 2. Index for the "has multiple actions" UI filter ─────────────────
-- Partial index: only rows where the parallel-actions UI applies. Most
-- triage rows are single-action and skipping them keeps the index tiny.
-- jsonb_array_length is immutable on a jsonb input, so the partial
-- predicate is index-eligible.
create index if not exists email_triage_proposed_actions_idx
    on public.email_triage_results (user_id, created_at desc)
    where proposed_actions is not null
      and jsonb_typeof(proposed_actions) = 'array'
      and jsonb_array_length(proposed_actions) > 1;

-- ── 3. PGRST schema cache reload ──────────────────────────────────────
-- Without this the email-triage edge function 400s with PGRST204 the
-- first time it tries to write proposed_actions.
notify pgrst, 'reload schema';
