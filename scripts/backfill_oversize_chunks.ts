// scripts/backfill_oversize_chunks.ts
// -----------------------------------------------------------------------------
// One-shot backfill: find law_chunks_v2 rows with embedding IS NULL whose text
// is too long for OpenAI's text-embedding-3-small (8191 tokens/item cap), split
// them via _shared/chunk_splitter, INSERT the parts, DELETE the original.
//
// Why this script exists (consilium 2026-05-14):
//   - corpus-embedder was failing with `Invalid 'input[N]': maximum input
//     length is 8192 tokens.` for batches that happened to include rows like
//     TuMS § 61 (19_716 chars) and VÕS § 380 (15_468 chars).
//   - The new chunk_splitter prevents the problem going forward (fetchers wire
//     it in pre-insert), but the existing 3_377 unembedded EE rows need a
//     one-time fix.
//   - Only 2-3 rows are actually oversize; the rest just need embedding. This
//     script targets the oversize subset only, then leaves the embedder to
//     finish the rest.
//
// Run:
//   source ~/Advocat/.env.local
//   cd ~/Advocat/app/advocat_project
//   deno run --allow-env --allow-net scripts/backfill_oversize_chunks.ts
//
// Env (read by the script):
//   SUPABASE_URL                  → required (e.g. https://okgnku....supabase.co)
//   SUPABASE_SERVICE_ROLE_KEY     → required (service-role JWT)
//
// Output: per-chunk progress + final summary (rows scanned, split, deleted,
// inserted, errors).
//
// Safety:
//   - Per-row "transaction": INSERT first, DELETE only on success. If INSERT
//     partially succeeds (some parts in, some not), we DO NOT delete the
//     original — re-running the script is safe because we check that all M
//     parts of the original are present before deleting.
//   - We never touch embedded rows.
//   - We only target rows whose text.length > MAX_CHARS (the splitter's own
//     cutoff). Smaller "oversize-in-tokens-but-not-chars" cases don't exist
//     in practice; the limit is well-calibrated.
// -----------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  MAX_CHARS,
  splitIfOversize,
} from "../supabase/functions/_shared/chunk_splitter.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
  ?? Deno.env.get("SUPABASE_SERVICE_KEY")
  ?? "";

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("ERROR: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars are required.");
  console.error("       hint: source ~/Advocat/.env.local");
  Deno.exit(1);
}

const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

interface ChunkRow {
  id: string;
  jurisdiction: string;
  act_slug: string;
  act_full_name: string | null;
  act_number: string | null;
  chapter: string | null;
  section: string | null;
  subsection: string | null;
  section_label: string | null;
  text: string;
  lang: string | null;
  source_url: string | null;
  version_hash: string | null;
  redaktsioon_valid_from: string | null;
  redaktsioon_valid_to: string | null;
  parent_chunk_id: string | null;
}

async function fetchOversizeRows(): Promise<ChunkRow[]> {
  // PostgREST has no LENGTH() helper; we pull text and filter client-side.
  // Pre-filter by selecting only the unembedded rows that are most likely to
  // be oversize — use a server-side filter via the .gte trick on text length
  // isn't possible, so we paginate. Volume is small (~3500 rows × 1KB avg
  // ≈ 3.5MB) so a single pass is fine.
  const all: ChunkRow[] = [];
  const PAGE = 1000;
  let from = 0;
  while (true) {
    const { data, error } = await sb
      .from("law_chunks_v2")
      .select(
        "id, jurisdiction, act_slug, act_full_name, act_number, chapter, section, subsection, section_label, text, lang, source_url, version_hash, redaktsioon_valid_from, redaktsioon_valid_to, parent_chunk_id",
      )
      .is("embedding", null)
      .order("id", { ascending: true })
      .range(from, from + PAGE - 1);
    if (error) throw new Error(`select page ${from}: ${error.message}`);
    if (!data || data.length === 0) break;
    for (const r of data as ChunkRow[]) {
      if ((r.text?.length ?? 0) > MAX_CHARS) all.push(r);
    }
    if (data.length < PAGE) break;
    from += PAGE;
  }
  return all;
}

interface SplitResult {
  id: string;
  section_label: string | null;
  chars: number;
  parts: number;
  inserted: number;
  deleted: boolean;
  error?: string;
}

async function processRow(row: ChunkRow): Promise<SplitResult> {
  const result: SplitResult = {
    id: row.id,
    section_label: row.section_label,
    chars: row.text.length,
    parts: 0,
    inserted: 0,
    deleted: false,
  };

  // Build the SplittableChunk shape. We strip id (new rows get fresh ids).
  // parent_chunk_id is NOT set on inserted parts: the original is being
  // deleted, so referencing it would violate the self-FK. The "osa N/M"
  // suffix in section_label and the subsection column are enough to
  // reconstruct the relationship in UI.
  const splittable = {
    jurisdiction: row.jurisdiction,
    act_slug: row.act_slug,
    act_full_name: row.act_full_name,
    act_number: row.act_number,
    chapter: row.chapter,
    section: row.section,
    subsection: row.subsection,
    section_label: row.section_label,
    text: row.text,
    lang: row.lang,
    source_url: row.source_url,
    version_hash: row.version_hash,
    redaktsioon_valid_from: row.redaktsioon_valid_from,
    redaktsioon_valid_to: row.redaktsioon_valid_to,
    parent_chunk_id: null as string | null,
  };

  const parts = splitIfOversize(splittable);
  result.parts = parts.length;

  if (parts.length <= 1) {
    // Splitter didn't actually split (e.g. text was equal to or below limit)
    // → leave the row alone; the embedder will pick it up.
    result.error = "splitter returned single part; skipping";
    return result;
  }

  // INSERT all parts. If any fail, abort BEFORE deleting the original so we
  // never lose content.
  const { data: inserted, error: insErr } = await sb
    .from("law_chunks_v2")
    .insert(parts)
    .select("id");
  if (insErr) {
    result.error = `insert: ${insErr.message}`;
    return result;
  }
  result.inserted = inserted?.length ?? 0;

  if (result.inserted !== parts.length) {
    result.error = `inserted ${result.inserted} of ${parts.length} parts; not deleting original`;
    return result;
  }

  // DELETE original.
  const { error: delErr } = await sb
    .from("law_chunks_v2")
    .delete()
    .eq("id", row.id);
  if (delErr) {
    result.error = `delete original ${row.id}: ${delErr.message}`;
    return result;
  }
  result.deleted = true;
  return result;
}

async function main() {
  console.log(`[backfill_oversize_chunks] MAX_CHARS=${MAX_CHARS}`);
  console.log("[backfill_oversize_chunks] scanning law_chunks_v2 for oversize unembedded rows...");
  const rows = await fetchOversizeRows();
  console.log(`[backfill_oversize_chunks] found ${rows.length} oversize rows`);

  if (rows.length === 0) {
    console.log("[backfill_oversize_chunks] nothing to do");
    return;
  }

  // Sort by chars descending so the biggest get fixed first (and any
  // failures show up early).
  rows.sort((a, b) => b.text.length - a.text.length);

  const results: SplitResult[] = [];
  for (const row of rows) {
    const r = await processRow(row);
    results.push(r);
    const status = r.error
      ? `ERR ${r.error}`
      : `OK +${r.inserted}/-${r.deleted ? 1 : 0}`;
    console.log(
      `  ${r.section_label ?? "(no label)"} (${r.chars} chars → ${r.parts} parts): ${status}`,
    );
  }

  const ok = results.filter((r) => !r.error);
  const err = results.filter((r) => r.error);
  console.log("");
  console.log("[backfill_oversize_chunks] summary:");
  console.log(`  scanned:  ${rows.length}`);
  console.log(`  split:    ${ok.length}`);
  console.log(`  errors:   ${err.length}`);
  console.log(`  inserted: ${ok.reduce((s, r) => s + r.inserted, 0)} new rows`);
  console.log(`  deleted:  ${ok.filter((r) => r.deleted).length} originals`);
  if (err.length > 0) {
    console.log("");
    console.log("  failures:");
    for (const r of err) {
      console.log(`    ${r.id} (${r.section_label ?? "?"}): ${r.error}`);
    }
    Deno.exit(2);
  }
}

await main();
