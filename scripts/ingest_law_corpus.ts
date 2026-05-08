#!/usr/bin/env -S deno run --allow-read --allow-net --allow-env
/**
 * ingest_law_corpus.ts
 *
 * Reads Estonian law corpus JSON files from assets/legal/estonia/,
 * generates OpenAI embeddings (text-embedding-3-small), and upserts
 * into the Supabase `law_chunks` table via REST API.
 *
 * Idempotent: skips paragraphs where body_hash already matches.
 * Processes in batches of 20 paragraphs to respect OpenAI rate limits.
 *
 * Usage:
 *   OPENAI_API_KEY=sk-... deno run --allow-read --allow-net --allow-env scripts/ingest_law_corpus.ts
 *
 * Optional env overrides:
 *   SUPABASE_URL            (default: https://okgnkucgwsytsondrjye.supabase.co)
 *   SUPABASE_SERVICE_ROLE_KEY
 *   CORPUS_DIR              (default: assets/legal/estonia)
 *   BATCH_SIZE              (default: 20)
 *   DRY_RUN=1               (skip Supabase writes, just count chunks)
 */

// ── Config ────────────────────────────────────────────────────────────────────

const SUPABASE_URL =
  Deno.env.get("SUPABASE_URL") ??
  "https://okgnkucgwsytsondrjye.supabase.co";

const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const CORPUS_DIR =
  Deno.env.get("CORPUS_DIR") ?? "assets/legal/estonia";

const BATCH_SIZE = parseInt(Deno.env.get("BATCH_SIZE") ?? "20", 10);
const DRY_RUN = Deno.env.get("DRY_RUN") === "1";

const OPENAI_EMBED_URL = "https://api.openai.com/v1/embeddings";
const OPENAI_MODEL = "text-embedding-3-small";
const SUPABASE_TABLE = `${SUPABASE_URL}/rest/v1/law_chunks`;

// ── Types ─────────────────────────────────────────────────────────────────────

interface Section {
  paragraph: string;
  title?: string;
  body: string;
  repealed?: boolean;
}

interface LawFile {
  act?: string;
  name?: string;
  name_en?: string;
  source?: string;
  sections?: Section[];
  [key: string]: unknown;
}

interface LawChunk {
  id: string;
  act_slug: string;
  act_name: string;
  paragraph: string;
  title: string | null;
  body: string;
  lang: string;
  jurisdiction: string;
  source_url: string | null;
  body_hash: string;
  embedding: number[];
  token_count: number;
  /** Set to the start of this ingest run so the citation grounder can detect
   *  corpus staleness (threshold: 90 days). */
  corpus_refreshed_at: string;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/** SHA-256 hex digest of a string (Web Crypto, available in Deno). */
async function sha256(text: string): Promise<string> {
  const buf = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Normalise a paragraph label for use in a row ID.
 *  "§ 14" → "§14", "Art. 2" → "art-2", strips spaces/dots.
 */
function normaliseParagraph(para: string): string {
  return para
    .toLowerCase()
    .replace(/\.\s*/g, "-")
    .replace(/\s+/g, "")
    .replace(/[^a-z0-9§\-]/g, "");
}

/** Build a deterministic row ID from slug + paragraph (chunk 0 always). */
function buildId(actSlug: string, paragraph: string): string {
  return `${actSlug.toLowerCase()}-${normaliseParagraph(paragraph)}-0`;
}

/** Fetch embeddings for a batch of texts from OpenAI, with retry on 429. */
async function fetchEmbeddings(
  inputs: string[],
): Promise<Array<{ embedding: number[]; tokens: number }>> {
  for (let attempt = 0; attempt < 5; attempt++) {
    const resp = await fetch(OPENAI_EMBED_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        input: inputs,
        encoding_format: "float",
      }),
    });

    if (resp.status === 429) {
      const retryAfter = parseInt(resp.headers.get("retry-after") ?? "15", 10);
      const wait = (retryAfter + 2) * 1000;
      Deno.stdout.writeSync(new TextEncoder().encode(`\n  [rate limit] waiting ${retryAfter + 2}s...`));
      await new Promise((r) => setTimeout(r, wait));
      continue;
    }

    if (!resp.ok) {
      const detail = await resp.text().catch(() => "");
      throw new Error(`OpenAI embeddings ${resp.status}: ${detail.slice(0, 400)}`);
    }

  const data = (await resp.json()) as {
    data: Array<{ index: number; embedding: number[] }>;
    usage: { total_tokens: number; prompt_tokens: number };
  };

  // data.data is ordered by index
    const sorted = [...data.data].sort((a, b) => a.index - b.index);
    const tokensPerItem = Math.ceil(
      (data.usage?.total_tokens ?? 0) / inputs.length,
    );

    return sorted.map((item) => ({
      embedding: item.embedding,
      tokens: tokensPerItem,
    }));
  }
  throw new Error("OpenAI embeddings: exceeded retry limit (5 attempts)");
}

/** Upsert a batch of chunks into Supabase via REST (on-conflict replace). */
async function upsertChunks(chunks: LawChunk[]): Promise<void> {
  if (DRY_RUN) return;

  const resp = await fetch(SUPABASE_TABLE, {
    method: "POST",
    headers: {
      apikey: SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
      Prefer: "resolution=merge-duplicates",
    },
    body: JSON.stringify(chunks),
  });

  if (!resp.ok) {
    const detail = await resp.text().catch(() => "");
    throw new Error(`Supabase upsert ${resp.status}: ${detail.slice(0, 400)}`);
  }
}

/** Fetch existing body_hashes for a set of IDs to enable skip-if-unchanged. */
async function fetchExistingHashes(
  ids: string[],
): Promise<Map<string, string>> {
  if (DRY_RUN || ids.length === 0) return new Map();

  // Supabase REST: GET /rest/v1/law_chunks?id=in.(id1,id2,...)&select=id,body_hash
  const idList = ids.map((id) => `"${id}"`).join(",");
  const url =
    `${SUPABASE_TABLE}?id=in.(${idList})&select=id,body_hash`;

  const resp = await fetch(url, {
    headers: {
      apikey: SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
    },
  });

  if (!resp.ok) {
    console.warn(`  [warn] Could not fetch existing hashes (${resp.status}), will upsert all`);
    return new Map();
  }

  const rows = (await resp.json()) as Array<{ id: string; body_hash: string }>;
  return new Map(rows.map((r) => [r.id, r.body_hash]));
}

// ── Main ──────────────────────────────────────────────────────────────────────

/** ISO timestamp captured once at process start; stamped onto every upserted
 *  row as corpus_refreshed_at so the citation grounder knows when the corpus
 *  was last refreshed. */
const RUN_STARTED_AT = new Date().toISOString();

if (!OPENAI_API_KEY && !DRY_RUN) {
  console.error(
    "ERROR: OPENAI_API_KEY is not set.\n" +
      "  Run: OPENAI_API_KEY=sk-... deno run --allow-read --allow-net --allow-env scripts/ingest_law_corpus.ts",
  );
  Deno.exit(1);
}

/** Fake embeddings for dry-run (1536 zeros). */
function fakeBatch(count: number): Array<{ embedding: number[]; tokens: number }> {
  return Array.from({ length: count }, () => ({ embedding: new Array(1536).fill(0), tokens: 42 }));
}

console.log(`Advocat Law Corpus Ingestion`);
console.log(`  Corpus dir : ${CORPUS_DIR}`);
console.log(`  Supabase   : ${SUPABASE_URL}`);
console.log(`  Batch size : ${BATCH_SIZE}`);
console.log(`  Dry run    : ${DRY_RUN}`);
console.log();

// 1. Enumerate files
const files: string[] = [];
for await (const entry of Deno.readDir(CORPUS_DIR)) {
  if (entry.isFile && entry.name.endsWith(".json")) {
    files.push(`${CORPUS_DIR}/${entry.name}`);
  }
}
files.sort();
console.log(`Found ${files.length} JSON files`);

// 2. Parse all paragraphs into raw records (before embedding)
interface RawChunk {
  id: string;
  actSlug: string;
  actName: string;
  paragraph: string;
  title: string | null;
  body: string;
  lang: string;
  sourceUrl: string | null;
}

const rawChunks: RawChunk[] = [];

for (const fpath of files) {
  const text = await Deno.readTextFile(fpath);
  const data: LawFile = JSON.parse(text);

  if (!data.sections || data.sections.length === 0) {
    console.log(`  skip ${fpath.split("/").pop()} (no sections)`);
    continue;
  }

  const actSlug = (data.act ?? fpath.split("/").pop()!.replace(".json", ""))
    .toLowerCase();
  const actName = data.name ?? actSlug;
  const sourceUrl = (data.source as string | undefined) ?? null;

  let skipped = 0;
  for (const section of data.sections) {
    if (!section.body || section.body.trim() === "") {
      skipped++;
      continue;
    }
    if (section.repealed === true) {
      skipped++;
      continue;
    }

    rawChunks.push({
      id: buildId(actSlug, section.paragraph),
      actSlug,
      actName,
      paragraph: section.paragraph,
      title: section.title ?? null,
      body: section.body.trim(),
      lang: "et",
      sourceUrl,
    });
  }

  const loaded = data.sections.length - skipped;
  console.log(
    `  loaded ${fpath.split("/").pop()}: ${loaded} paragraphs (${skipped} skipped)`,
  );
}

console.log(`\nTotal paragraphs to process: ${rawChunks.length}`);

// 3. Process in batches
let inserted = 0;
let skippedUnchanged = 0;
let totalTokens = 0;
const errors: string[] = [];

for (let i = 0; i < rawChunks.length; i += BATCH_SIZE) {
  const batch = rawChunks.slice(i, i + BATCH_SIZE);
  const batchNum = Math.floor(i / BATCH_SIZE) + 1;
  const totalBatches = Math.ceil(rawChunks.length / BATCH_SIZE);

  Deno.stdout.writeSync(
    new TextEncoder().encode(
      `\rBatch ${batchNum}/${totalBatches} (chunks ${i + 1}-${Math.min(i + BATCH_SIZE, rawChunks.length)})... `,
    ),
  );

  try {
    // 3a. Compute body hashes for this batch
    const hashes = await Promise.all(batch.map((c) => sha256(c.body)));

    // 3b. Check which IDs already exist with matching hash
    const ids = batch.map((c) => c.id);
    const existingHashes = await fetchExistingHashes(ids);

    const toEmbed: number[] = []; // indices into batch that need embedding
    for (let j = 0; j < batch.length; j++) {
      const existingHash = existingHashes.get(batch[j].id);
      if (existingHash && existingHash === hashes[j]) {
        skippedUnchanged++;
      } else {
        toEmbed.push(j);
      }
    }

    if (toEmbed.length === 0) {
      continue; // all unchanged
    }

    // 3c. Fetch embeddings only for changed chunks
    const texts = toEmbed.map((j) => {
      // Concatenate title + body for richer embedding context
      const chunk = batch[j];
      return chunk.title
        ? `${chunk.paragraph} ${chunk.title}\n${chunk.body}`
        : `${chunk.paragraph}\n${chunk.body}`;
    });

    const embedResults = DRY_RUN ? fakeBatch(texts.length) : await fetchEmbeddings(texts);
    totalTokens += embedResults.reduce((s, r) => s + r.tokens, 0);

    // 3d. Build LawChunk records
    const chunksToUpsert: LawChunk[] = [];
    for (let k = 0; k < toEmbed.length; k++) {
      const j = toEmbed[k];
      const raw = batch[j];
      const { embedding, tokens } = embedResults[k];

      chunksToUpsert.push({
        id: raw.id,
        act_slug: raw.actSlug,
        act_name: raw.actName,
        paragraph: raw.paragraph,
        title: raw.title,
        body: raw.body,
        lang: raw.lang,
        jurisdiction: "EE",
        source_url: raw.sourceUrl,
        body_hash: hashes[j],
        embedding,
        token_count: tokens,
        corpus_refreshed_at: RUN_STARTED_AT,
      });
    }

    // 3e. Upsert
    await upsertChunks(chunksToUpsert);
    inserted += chunksToUpsert.length;
  } catch (err) {
    const msg = `Batch ${batchNum} failed: ${err instanceof Error ? err.message : String(err)}`;
    errors.push(msg);
    console.error(`\n  ERROR: ${msg}`);
  }
}

// 4. Summary
console.log("\n");
console.log("═".repeat(50));
console.log("Ingestion complete");
console.log(`  Inserted / updated : ${inserted}`);
console.log(`  Skipped (unchanged): ${skippedUnchanged}`);
console.log(`  Total chunks seen  : ${rawChunks.length}`);
console.log(`  Tokens used        : ${totalTokens.toLocaleString()}`);
if (DRY_RUN) console.log("  [DRY RUN — no writes]");
if (errors.length > 0) {
  console.log(`  Errors             : ${errors.length}`);
  for (const e of errors) console.log(`    - ${e}`);
  Deno.exit(1);
}
console.log("═".repeat(50));
