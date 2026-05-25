-- =====================================================================
-- D6 — "Approve & Send" persistence columns on email_triage_results.
--
-- Adds the three columns the new `email-send` edge function writes to
-- when a user taps "Approve & Send" on a triage card:
--
--   * sent_at          — wall-clock timestamp of the successful Gmail
--                        API send. NULL until the send succeeds, so a
--                        partial-index lookup ("everything I have sent")
--                        is cheap.
--   * sent_message_id  — Gmail's `users.messages.send` response id (the
--                        new message id, NOT the thread id). Used for
--                        cross-checking with future Gmail inbox-sync
--                        ticks and for surfacing the dispatched message
--                        in the Outbox view (a later D-track task).
--   * gate_token       — full HMAC gate token issued by the email-triage
--                        pipeline (per `policy_gate.ts::issueGateToken`).
--                        Persisted at triage-time by the existing
--                        pipeline (Phase 1 emitted the token but did not
--                        persist it; D6 turns on persistence by giving
--                        the column a home). `email-send` re-verifies
--                        the token before calling Gmail.
--
-- Idempotency: every DDL is `if not exists`. Safe to re-run via
-- `supabase db push`.
--
-- We deliberately re-use the existing `user_action` enum slot (`sent`,
-- already in the CHECK constraint) to gate "already dispatched"
-- detection. `sent_at IS NOT NULL` is the load-bearing predicate; the
-- enum is a secondary breadcrumb for the chat assistant's `list_inbox`
-- card.
-- =====================================================================

-- ── 1. sent_at + sent_message_id columns ──────────────────────────────
alter table public.email_triage_results
    add column if not exists sent_at         timestamptz;

alter table public.email_triage_results
    add column if not exists sent_message_id text;

-- ── 2. gate_token column (full HMAC payload as jsonb) ─────────────────
-- Shape matches policy_gate.GateToken:
--   { draft_id: text, body_sha256: text, recipient_set: text,
--     issued_at: bigint, ttl_ms: int, hmac: hex }
alter table public.email_triage_results
    add column if not exists gate_token jsonb;

-- ── 3. Indexes — only what email-send actually queries ────────────────
-- Partial index for the "dispatched" view; rows without sent_at are by
-- far the majority and skipping them keeps the index tiny.
create index if not exists email_triage_sent_idx
    on public.email_triage_results (user_id, sent_at desc)
    where sent_at is not null;

-- ── 4. PGRST schema cache reload ──────────────────────────────────────
-- Without this the email-send edge function 400s with PGRST204 the
-- first time it tries to update sent_at / sent_message_id / gate_token.
notify pgrst, 'reload schema';
