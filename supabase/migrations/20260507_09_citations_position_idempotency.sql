-- =============================================================================
-- Phase 2 Pkg 2 closeout — chat_message_citations idempotency + position.
--
-- Migration _08 shipped the table without a `position` column. That's fine
-- for the inline-render contract (Flutter uses `created_at asc` order via
-- the message_citations RPC), BUT it leaves the writer with no way to
-- safely upsert: if the proxy retries a turn (network blip, redrive,
-- etc.) we'd insert duplicates of every citation row.
--
-- Closeout adds:
--   1. `position` column — first-occurrence index of the marker in the
--      reply, 0-based. Verifier already emits citations in that order.
--   2. UNIQUE (message_id, position) — the writer can now upsert with
--      `onConflict: 'message_id,position', ignoreDuplicates: true` so a
--      retried POST is a no-op.
--
-- Backfill: existing rows get position = 0 (no retry has happened yet
-- since _08 only landed in the same session as _09; in dev/CI the table
-- is empty). The dedup unique index won't blow up because each existing
-- row is the only row for its message_id.
--
-- Idempotent: the column add and index creation are both `if not exists`.
-- =============================================================================

alter table public.chat_message_citations
    add column if not exists position int;

-- Backfill any rows shipped between _08 and _09 to satisfy the not-null
-- constraint about to be applied. In practice the table is empty when this
-- migration runs (both ship the same day), so this is defensive only.
update public.chat_message_citations
   set position = 0
 where position is null;

alter table public.chat_message_citations
    alter column position set not null;

alter table public.chat_message_citations
    alter column position set default 0;

-- Sanity check on the column. Position is the verifier's first-occurrence
-- index — 0-based, monotonically increasing per message_id.
do $$
begin
    if not exists (
        select 1
          from pg_constraint
         where conname = 'chat_message_citations_position_nonneg'
    ) then
        alter table public.chat_message_citations
            add constraint chat_message_citations_position_nonneg
            check (position >= 0);
    end if;
end
$$;

-- The idempotency anchor. Unique pair lets the writer use:
--   .upsert(rows, { onConflict: 'message_id,position', ignoreDuplicates: true })
-- so a retried turn (same UUID, same N markers) skips already-written rows
-- without raising. Distinct from the existing message_idx (which is an FK
-- lookup index, NOT a uniqueness constraint).
create unique index if not exists chat_message_citations_message_position_uidx
    on public.chat_message_citations (message_id, position);

-- PGRST schema cache reload — make the new column reachable after
-- `db push` (memory: reference_pitfalls_chat_infra).
notify pgrst, 'reload schema';
