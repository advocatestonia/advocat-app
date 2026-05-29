-- 2026-05-29 — Data-integrity fix: subscriptions.user_id UNIQUE
-- ---------------------------------------------------------------------------
-- The stripe-webhook function upserts the per-user subscription row with
--   .upsert({ user_id, status, tier, ... }, { onConflict: "user_id" })
-- at supabase/functions/stripe-webhook/index.ts:519 (checkout.completed) and
-- :661 (invoice.paid extend). PostgREST translates onConflict into a SQL
-- ON CONFLICT (user_id) clause, which Postgres rejects with 42P10
-- ("no unique or exclusion constraint matching the ON CONFLICT specification")
-- unless user_id carries a UNIQUE/PK. The table only had PRIMARY KEY (id) +
-- FK(user_id) + CHECK(messages_used_count >= 0) — no UNIQUE on user_id —
-- so those upserts were latently broken, and absent the constraint a
-- concurrent insert could create two subscription rows for one user, making
-- check-ai-quota's tier read non-deterministic.
--
-- The app's contract is one subscription row per user. This adds the missing
-- UNIQUE so the upsert resolves correctly and duplicates are impossible.
-- Verified on prod (2026-05-29) that no user currently has >1 row, so the
-- constraint installs without a conflict.

alter table public.subscriptions
  add constraint subscriptions_user_id_key unique (user_id);
