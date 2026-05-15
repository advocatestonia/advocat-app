// Deno tests for cases-coordinator edge function.
//
// Source-text contract assertions only (we don't boot the serve() handler).
// The real integration tests live in services/cases-fetcher/scripts/smoke.js
// (Node side) + the end-to-end drain run that wrote KHO:2024:28 et al. into
// case_chunks during deploy.
//
// Run from supabase/functions/cases-coordinator/ with:
//   deno test --allow-env --allow-read

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const indexSrc = await Deno.readTextFile(new URL("../index.ts", import.meta.url));

// ── Wire format / contract tests ────────────────────────────────────────────

Deno.test("index.ts — POST body shape (worker_id + max_jobs + source)", () => {
  for (const f of ["worker_id", "max_jobs", "source"]) {
    assertStringIncludes(indexSrc, `body.${f}`, `must read body.${f}`);
  }
});

Deno.test("index.ts — CRON_SECRET auth (x-cron-secret OR Bearer)", () => {
  assertStringIncludes(indexSrc, "CRON_SECRET");
  assertStringIncludes(indexSrc, "x-cron-secret");
  assertStringIncludes(indexSrc, "authorization");
});

Deno.test("index.ts — requires SERVICE_ROLE + CASES_FETCHER_URL/_SECRET", () => {
  assertStringIncludes(indexSrc, "SUPABASE_SERVICE_ROLE_KEY");
  assertStringIncludes(indexSrc, "CASES_FETCHER_URL");
  assertStringIncludes(indexSrc, "CASES_FETCHER_SECRET");
});

Deno.test("index.ts — accepts kko, kho, riigikohus + any", () => {
  for (const s of ['"kko"', '"kho"', '"riigikohus"', '"any"']) {
    assertStringIncludes(indexSrc, s, `must reference source value ${s}`);
  }
});

Deno.test("index.ts — only writes to case_chunks target_table", () => {
  assertStringIncludes(indexSrc, '"case_chunks"');
  // Should NOT touch law_chunks_v2 (that's finlex-fetcher's job)
  assert(!indexSrc.includes('"law_chunks_v2"'), "should not write to law_chunks_v2");
});

Deno.test("index.ts — handles both legacy (case_year/case_number nums) and new (year/number) payloads", () => {
  assertStringIncludes(indexSrc, "case_year");
  assertStringIncludes(indexSrc, "p.year");
  assertStringIncludes(indexSrc, "p.number");
});

Deno.test("index.ts — Riigikohus payload uses case_number string", () => {
  assertStringIncludes(indexSrc, '"riigikohus"');
  // Pattern match on case_number string indicates Riigikohus detection
  assertStringIncludes(indexSrc, "case_number");
});

Deno.test("index.ts — idempotency: DELETE before INSERT into case_chunks", () => {
  // Must wipe rows for the case before inserting fresh paragraphs so
  // re-running a job doesn't duplicate.
  assertStringIncludes(indexSrc, '.from("case_chunks")');
  assertStringIncludes(indexSrc, ".delete()");
});

Deno.test("index.ts — text_type whitelist matches case_chunks check constraint", () => {
  // case_chunks.text_type CHECK constraint: facts, ratio, obiter, dispositive
  for (const t of ['"facts"', '"ratio"', '"obiter"', '"dispositive"']) {
    assertStringIncludes(indexSrc, t);
  }
});

Deno.test("index.ts — lease via UPDATE with worker_id + locked_until", () => {
  assertStringIncludes(indexSrc, "worker_id");
  assertStringIncludes(indexSrc, "locked_until");
  assertStringIncludes(indexSrc, 'status: "fetching"');
});

Deno.test("index.ts — re-queues failed 'Finlex AKN-LD3' rows from finlex-fetcher", () => {
  // The 80 historical case rows were marked 'failed' by finlex-fetcher with
  // a last_error starting "Finlex AKN-LD3". This coordinator must pick them
  // back up.
  assertStringIncludes(indexSrc, "Finlex AKN-LD3");
});

Deno.test("index.ts — jurisdiction = ee for Riigikohus, fi for KKO/KHO", () => {
  assertStringIncludes(indexSrc, '"ee"');
  assertStringIncludes(indexSrc, '"fi"');
  assertStringIncludes(indexSrc, "Riigikohus");
});

Deno.test("index.ts — paragraph length floor (filter UI chrome)", () => {
  // We filter out paragraphs shorter than 20 chars to drop breadcrumbs etc.
  assert(/text\.length\s*[><]=?\s*20/.test(indexSrc), "must enforce minimum paragraph length");
});

Deno.test("seed_sulga.sql — 20 hand-curated cases with notes", () => {
  const seedSrc = Deno.readTextFileSync(new URL("../seed_sulga.sql", import.meta.url));
  // Spot-check Sulga-relevant cases
  assertStringIncludes(seedSrc, "KHO:2018:142");      // HOL §114 pattern
  assertStringIncludes(seedSrc, "KKO:2023:67");       // asianomistaja
  assertStringIncludes(seedSrc, "3-2-1-145-16");      // Riigikohus tagasivõitmine
  assertStringIncludes(seedSrc, "ON CONFLICT");       // idempotent
});

Deno.test("index.ts — fetcher timeout > server scrape timeout (60s + headroom)", () => {
  // services/cases-fetcher/server.js has REQUEST_TIMEOUT_MS=60000 default.
  // The coordinator must wait longer or it'll abort live scrapes.
  const m = indexSrc.match(/FETCHER_TIMEOUT_MS\s*=\s*(\d+(_\d+)?)/);
  assert(m, "must set FETCHER_TIMEOUT_MS");
  const ms = parseInt(m[1].replace(/_/g, ""), 10);
  assert(ms >= 60000, `FETCHER_TIMEOUT_MS=${ms} should be >= 60000 (server.js timeout)`);
});
