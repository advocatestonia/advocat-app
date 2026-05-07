-- =============================================================================
-- Law corpus — pgvector RAG store for Estonian + EU acts. P0-2 of legal-brain
-- rebuild (2026-05-06).
-- =============================================================================
-- Sister tasks:
--   P0-1 (corpus)   — commit f47897b: 30 ET acts + 5 EU directives in
--                     /data/corpus/{et,eu}/*.md (8345 chunks total).
--   P0-3 (client)   — commit ac66934: lib/services/law_search_client.dart POSTs
--                     to /functions/v1/law-search and gracefully no-ops on
--                     failure. Wire format owned by that client.
--
-- This migration creates:
--   1. `law_chunks` — one row per paragraph/article chunk, with a 1536-d
--      embedding column (text-embedding-3-small).
--   2. ivfflat cosine index on the embedding (lists=100 — owner-fixed,
--      not HNSW per P0-2 spec).
--   3. Two B-tree indexes for cheap lang/topic + act_slug filters.
--   4. `law_search` SQL function — cosine-similarity search filtered by
--      lang, returning top-N chunks above a similarity threshold.
--   5. Read-only RLS for anon — corpus is public law text, not user data.
--
-- After this migration, owner runs:
--   • supabase db push
--   • supabase functions deploy law-search
--   • python scripts/corpus/ingest_to_pgvector.py (with SUPABASE_DB_URL set)
-- =============================================================================

create extension if not exists vector;

-- ── law_chunks ────────────────────────────────────────────────────────────────
-- id format: "<act_slug_lower>-<paragraph_normalized>-<chunk_idx>"
--   e.g. "tls-§1-0", "32000l0078-art-2-0", "tls-§7-1-1" (overflow chunk).
-- The ingestion script computes ids deterministically so re-runs are
-- idempotent; combined with body_hash, embeds are skipped on no-change.
create table if not exists public.law_chunks (
    id              text primary key,
    act_slug        text not null,
    act_name        text not null,
    paragraph       text not null,
    title           text,
    body            text not null,
    lang            text not null check (lang in ('et','ru','en','eu_en','eu_et','eu_ru')),
    topic           text,
    version_date    date,
    source_url      text,
    embedding       vector(1536),
    token_count     int,
    body_hash       text,
    inserted_at     timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

-- ── Indexes ───────────────────────────────────────────────────────────────────
-- ivfflat with cosine distance. lists=100 is the spec value — do NOT change
-- without re-running ANALYZE and re-tuning. Index is built lazily; queries
-- before the first ingest still work (full scan over zero rows).
create index if not exists law_chunks_embedding_idx
    on public.law_chunks
    using ivfflat (embedding vector_cosine_ops)
    with (lists = 100);

-- Composite (lang, topic) for the chat layer's per-language top-up queries.
create index if not exists law_chunks_lang_topic_idx
    on public.law_chunks (lang, topic);

-- act_slug for "fetch all chunks of TLS" type queries (admin/debug).
create index if not exists law_chunks_act_slug_idx
    on public.law_chunks (act_slug);

-- ── law_search RPC ────────────────────────────────────────────────────────────
-- Cosine similarity = 1 - cosine_distance. Threshold filter happens BEFORE
-- the limit so we don't return below-threshold chunks just because the table
-- is sparse. Returns at most match_count rows ordered by similarity DESC.
create or replace function public.law_search(
    query_embedding      vector(1536),
    query_lang           text,
    match_count          int default 8,
    similarity_threshold float default 0.60
)
returns table (
    id          text,
    act_slug    text,
    act_name    text,
    paragraph   text,
    title       text,
    body        text,
    source_url  text,
    similarity  float
)
language sql stable as $$
    select
        c.id,
        c.act_slug,
        c.act_name,
        c.paragraph,
        c.title,
        c.body,
        c.source_url,
        1 - (c.embedding <=> query_embedding) as similarity
    from public.law_chunks c
    where c.lang = query_lang
      and 1 - (c.embedding <=> query_embedding) >= similarity_threshold
    order by c.embedding <=> query_embedding
    limit match_count;
$$;

-- ── RLS — public read, no writes ──────────────────────────────────────────────
-- Corpus is public law text. Inserts/updates flow through the ingestion
-- script which uses the service role and bypasses RLS, so we don't need
-- write policies here.
alter table public.law_chunks enable row level security;
drop policy if exists "law_chunks readable by anon" on public.law_chunks;
create policy "law_chunks readable by anon"
    on public.law_chunks
    for select
    using (true);
