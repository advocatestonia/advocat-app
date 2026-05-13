// gold-scrubber/index.ts — nightly PII scrub pass over the gold corpus queue.
// ----------------------------------------------------------------------------
// Cron: 03:00 Tallinn (Europe/Tallinn) = 00:00 UTC winter / 01:00 UTC summer.
// Wire-up via Supabase Scheduled Triggers (not committed here — owner sets
// the schedule from the dashboard or via a separate migration).
//
// Auth: service-role only (matches admin-add-correction).
// Behaviour:
//   1. Fetch up to BATCH (default 100) rows where pii_scrubbed = false.
//   2. For each row, run twoStageScrub on user_question AND ai_answer.
//   3. UPDATE the row with the redacted text + pii_scrubbed=true.
//   4. On per-row failure, record scrub_error and leave pii_scrubbed=false
//      so the next run retries the row.
//   5. Return JSON summary: {processed, scrubbed, failed, totals}.
//
// Manual invocation (smoke / first-run):
//   curl -X POST https://<project>.supabase.co/functions/v1/gold-scrubber \
//     -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
// ----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";
import { twoStageScrub } from "../_shared/pii_scrubber.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ANTHROPIC_API_KEY = Deno.env.get("CLAUDE_API_KEY") ?? "";

const DEFAULT_BATCH = 100;
const SCRUBBER_VERSION = "regex-v1+haiku-4-5";

interface QueueRow {
  id: string;
  user_question: string;
  ai_answer: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST" && req.method !== "GET") {
    return jsonError("method not allowed", 405);
  }

  // ── Auth: service-role only ───────────────────────────────────────────────
  const auth = req.headers.get("authorization") ?? "";
  const expected = `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`;
  if (!SUPABASE_SERVICE_ROLE_KEY || auth !== expected) {
    return jsonError("service-role required", 401);
  }

  const url = new URL(req.url);
  const batch = clampInt(url.searchParams.get("batch"), 1, 500, DEFAULT_BATCH);

  // ── Fetch unscrubbed rows ─────────────────────────────────────────────────
  let rows: QueueRow[] = [];
  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/gold_corpus_queue` +
        `?select=id,user_question,ai_answer` +
        `&pii_scrubbed=eq.false` +
        `&order=created_at.asc` +
        `&limit=${batch}`,
      {
        headers: {
          apikey: SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
      },
    );
    if (!res.ok) {
      const err = await res.text();
      return jsonError(`fetch queue failed: ${err.slice(0, 200)}`, res.status);
    }
    rows = await res.json() as QueueRow[];
  } catch (e) {
    return jsonError(`queue fetch threw: ${String(e).slice(0, 200)}`, 500);
  }

  let scrubbed = 0;
  let failed = 0;
  const totals: Record<string, number> = {};

  for (const row of rows) {
    try {
      const q = await twoStageScrub({
        text: row.user_question ?? "",
        anthropicApiKey: ANTHROPIC_API_KEY,
      });
      const a = await twoStageScrub({
        text: row.ai_answer ?? "",
        anthropicApiKey: ANTHROPIC_API_KEY,
      });

      // Aggregate counts (regex-stage only — Haiku output is opaque).
      for (const [k, v] of Object.entries(q.replacements)) {
        totals[k] = (totals[k] ?? 0) + v;
      }
      for (const [k, v] of Object.entries(a.replacements)) {
        totals[k] = (totals[k] ?? 0) + v;
      }
      const rowReplacements: Record<string, number> = {};
      for (const [k, v] of Object.entries(q.replacements)) {
        rowReplacements[k] = (rowReplacements[k] ?? 0) + v;
      }
      for (const [k, v] of Object.entries(a.replacements)) {
        rowReplacements[k] = (rowReplacements[k] ?? 0) + v;
      }

      const upd = await fetch(
        `${SUPABASE_URL}/rest/v1/gold_corpus_queue?id=eq.${row.id}`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            apikey: SUPABASE_SERVICE_ROLE_KEY,
            Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
            Prefer: "return=minimal",
          },
          body: JSON.stringify({
            user_question: q.text,
            ai_answer: a.text,
            pii_scrubbed: true,
            scrub_attempted_at: new Date().toISOString(),
            scrub_error: null,
            pii_replacements: rowReplacements,
          }),
        },
      );
      if (!upd.ok) {
        const err = await upd.text();
        console.warn(`[gold-scrubber] update ${row.id} failed: ${err.slice(0, 200)}`);
        await recordScrubError(row.id, `update HTTP ${upd.status}`);
        failed++;
        continue;
      }
      scrubbed++;
    } catch (e) {
      const msg = String(e).slice(0, 200);
      console.warn(`[gold-scrubber] row ${row.id} threw: ${msg}`);
      await recordScrubError(row.id, msg);
      failed++;
    }
  }

  return jsonOk({
    ok: true,
    processed: rows.length,
    scrubbed,
    failed,
    totals,
    scrubber_version: SCRUBBER_VERSION,
  });
});

async function recordScrubError(rowId: string, error: string): Promise<void> {
  try {
    await fetch(
      `${SUPABASE_URL}/rest/v1/gold_corpus_queue?id=eq.${rowId}`,
      {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          Prefer: "return=minimal",
        },
        body: JSON.stringify({
          scrub_attempted_at: new Date().toISOString(),
          scrub_error: error,
        }),
      },
    );
  } catch {
    // best-effort
  }
}

function clampInt(
  raw: string | null,
  min: number,
  max: number,
  fallback: number,
): number {
  if (!raw) return fallback;
  const n = parseInt(raw, 10);
  if (!Number.isFinite(n)) return fallback;
  if (n < min) return min;
  if (n > max) return max;
  return n;
}
