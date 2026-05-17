-- =====================================================================
-- Chunk text augmentation — Day2-B vabank (2026-05-17)
-- =====================================================================
-- Problem (measured 2026-05-16 hybrid_v2 baseline):
--   recall@3 strict (act + section) = 60% (12/20)
--   recall@3 act-only               = 90% (18/20)
--   ⇒ §-precision still bottlenecks 6 queries even after the v2 RPC
--      (per-act dedup + RRF k=20 + exact-§ boost) was deployed.
--
-- Day1-C diagnosed: "6 'right act, wrong §' failures need data-side fix:
--   chunk text augmentation prepending section_label so §-number gets
--   embedded".
--
-- Evidence (sampled 2026-05-17):
--   fi-hol §26 text starts with "Tulkitseminen ja kääntäminen ...".
--   The string "26" or "HOL 5:26 §" appears NOWHERE in the embedded text.
--   text-embedding-3-small therefore has no signal to surface this chunk
--   when query asks for "§26" or "HL § 26" — only semantic neighbours
--   (HOL 2:9, KIELIL 1:2, PL 2:17) get retrieved instead.
--
-- This migration adds a non-destructive STORED generated column:
--   chunk_text_augmented = section_label || ' — ' || text
--
-- The corpus-embedder will then re-embed all 15,970 rows reading from
-- this column instead of `text`. The original `text` column is unchanged;
-- only `embedding` is rewritten, and the prior vectors are backed up to
-- `embedding_v1_backup` first so we can swap back instantly if recall
-- regresses on any production query.
--
-- BM25 path is already augmented — `chunk_tsv` (migration 2026-05-15-080000)
-- puts section_label in weight A — so this change only touches the dense
-- retrieval channel.
--
-- Reversibility:
--   ALTER TABLE law_chunks_v2
--     DROP COLUMN chunk_text_augmented,
--     DROP COLUMN embedding_v1_backup;
--   UPDATE law_chunks_v2 SET embedding = embedding_v1_backup; -- via backup
--
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Backup column (1536-dim vector copy of current embedding)
-- ---------------------------------------------------------------------
-- We snapshot the CURRENT embedding to embedding_v1_backup. After this
-- migration runs successfully, the corpus-embedder re-embed-augmented
-- mode will overwrite `embedding` only; `embedding_v1_backup` survives.
ALTER TABLE public.law_chunks_v2
  ADD COLUMN IF NOT EXISTS embedding_v1_backup vector(1536);

-- One-shot copy. Idempotent — if backup already populated, the COALESCE
-- guard skips already-backed rows so re-running the migration is safe.
UPDATE public.law_chunks_v2
SET embedding_v1_backup = embedding
WHERE embedding IS NOT NULL
  AND embedding_v1_backup IS NULL;

-- ---------------------------------------------------------------------
-- 2. Augmented text column (STORED generated)
-- ---------------------------------------------------------------------
-- Prepend section_label so embedding model sees the §-number in the
-- first ~10 tokens (token 1-3 actually). text-embedding-3-small uses
-- BPE; "HOL 5:26 §" is ~5 tokens, well within positional-attention
-- weighting that favours sentence openings.
--
-- We use " — " (em dash with spaces) as the separator. Reasoning:
--   - distinct from any §-number, won't collide with substring boost
--   - clear visual break for any human inspecting the column
--   - same separator pattern is widely used in citation strings, so
--     the embedding model has seen "<citation> — <body>" before
--     during pre-training (Wikipedia legal articles etc.)
ALTER TABLE public.law_chunks_v2
  ADD COLUMN IF NOT EXISTS chunk_text_augmented text
  GENERATED ALWAYS AS (
    CASE
      WHEN section_label IS NOT NULL AND section_label != ''
        THEN section_label || ' — ' || coalesce(text, '')
      ELSE coalesce(text, '')
    END
  ) STORED;

-- ---------------------------------------------------------------------
-- 3. Sanity check — view a few sample augmented chunks
-- ---------------------------------------------------------------------
-- This DO block does nothing at runtime; it's a comment for whoever
-- runs `psql` to verify the augmentation looks right:
--
--   SELECT act_slug, section_label, left(chunk_text_augmented, 80)
--   FROM public.law_chunks_v2
--   WHERE act_slug IN ('fi-hol', 'fi-ulkl', 'fi-rol')
--     AND section_label IN ('HOL 5:26 §', 'ULKL 9:148 §', 'ROL 1:3 §');
--
-- Expected: each row's preview starts with "<section_label> — <text>".

COMMENT ON COLUMN public.law_chunks_v2.chunk_text_augmented IS
  'Generated column: section_label || " — " || text. Used by corpus-embedder re-embed-augmented mode to push §-number into the first tokens text-embedding-3-small sees, lifting §-precision in dense retrieval. Day2-B vabank (2026-05-17).';

COMMENT ON COLUMN public.law_chunks_v2.embedding_v1_backup IS
  'Snapshot of `embedding` taken 2026-05-17 before the augmented re-embed pass. Restore via UPDATE embedding = embedding_v1_backup if recall regresses. Day2-B vabank.';
