// account-delete/coverage_test.ts
// -----------------------------------------------------------------------------
// GDPR Art. 17 coverage assertion. Runs in CI against the LIVE Supabase
// schema and fails the build if any public.* table with a `user_id`,
// `owner_id`, or `created_by` column is NOT either:
//   (a) in `USER_DATA_TABLES` (will be wiped on account delete), OR
//   (b) in `EXCLUDED_TABLES` (intentionally retained, with documented reason).
//
// This is the canary that the next dev who adds a personal-data table will
// trip on. Without this test, the silent-skip behaviour of `safeDelete`
// (the original audit P0-7 root cause) returns invisibly the moment a new
// table lands.
//
// Usage:
//   $ deno test --allow-net --allow-env \
//       supabase/functions/account-delete/coverage_test.ts
//
// Required env:
//   SUPABASE_URL              — e.g. https://okgnkucgwsytsondrjye.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY — service-role bearer for information_schema read
//
// CI ergonomics: when run in an env WITHOUT the above creds (e.g. fork
// PR build), the test SKIPS rather than fails — the assertion is meaningful
// only against the actual prod schema. Owner runs this from the trusted
// CI runner that has secrets.
// -----------------------------------------------------------------------------

import { assertEquals } from "https://deno.land/std@0.177.0/testing/asserts.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { EXCLUDED_TABLES, USER_DATA_TABLES } from "./handler.ts";

/**
 * Query information_schema for every public.* base table that carries a
 * column we treat as user-identifying. We treat three column names as the
 * canonical user-FK convention used across the Advocat codebase:
 *   - `user_id`     (the dominant convention)
 *   - `owner_id`    (older tables; rare)
 *   - `created_by`  (audit-style tables)
 *
 * Tables with NO column in this set are out of scope (e.g. law_chunks,
 * holiday_calendars, statute_aliases — public-readable corpora).
 */
// `source_user_id` added after an audit found gold_corpus_queue (raw,
// possibly-unscrubbed user question + AI answer) escaped this canary because
// it used source_user_id, not user_id. Keep aligned with every per-user FK
// column name in the schema.
const PII_COLUMNS = [
  "user_id",
  "owner_id",
  "created_by",
  "source_user_id",
] as const;

interface InfoSchemaRow {
  table_name: string;
  columns: string[];
}

/**
 * Fetch the per-table set of PII columns from information_schema via a
 * SECURITY DEFINER RPC. Falls back to a raw REST query against the
 * pg_meta-style view if available.
 *
 * The query is the same one documented in audit 02 §7.4 "Verification queries".
 */
async function fetchPiiTables(
  url: string,
  key: string,
): Promise<InfoSchemaRow[]> {
  const sb = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // PostgREST cannot query information_schema by default. Use the RPC pattern:
  // we expect a `public.list_pii_tables()` SECURITY DEFINER fn (created in a
  // migration alongside this fix). If it doesn't exist yet, fall back to a
  // raw fetch against the SQL API.
  // deno-lint-ignore no-explicit-any
  const { data, error } = await (sb.rpc as any)("list_pii_tables");
  if (!error && Array.isArray(data)) {
    return data as InfoSchemaRow[];
  }

  // Fallback: hit the management API directly. Requires `query` endpoint
  // (available with service-role JWT against the project's REST URL).
  const sqlUrl = `${url}/rest/v1/rpc/list_pii_tables`;
  const resp = await fetch(sqlUrl, {
    method: "POST",
    headers: {
      "apikey": key,
      "Authorization": `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: "{}",
  });
  if (resp.ok) {
    return await resp.json();
  }
  throw new Error(
    `list_pii_tables RPC not available (HTTP ${resp.status}). ` +
      `Apply migration first or wire pg_meta query.`,
  );
}

/**
 * Local fallback: read the migrations directory and parse CREATE TABLE
 * statements for `user_id` columns. Used only when SUPABASE creds are
 * absent (PR-fork CI) so the test can at least catch obvious additions
 * to migration SQL.
 *
 * NOT a substitute for the live-schema check — a column added by SQL Studio
 * outside of a migration file will not be caught. The owner is expected to
 * run the full check against prod before any account-delete deploy.
 */
async function fetchPiiTablesFromMigrations(): Promise<InfoSchemaRow[]> {
  const migrationsDir = new URL("../../migrations/", import.meta.url);
  let entries: Deno.DirEntry[];
  try {
    entries = [];
    for await (const e of Deno.readDir(migrationsDir)) entries.push(e);
  } catch {
    return [];
  }
  const byTable = new Map<string, Set<string>>();
  // Capture an OPTIONAL schema qualifier so we can SKIP non-`public` schemas.
  // The Art. 17 sweep only erases `public.*` rows; helper schemas like
  // `app_vault.*` (encryption-key infra) and `app.*` (internal queues /
  // rate-limit buckets) are NOT user-data tables. The previous regex stripped
  // only a literal `public.` prefix and then captured the FIRST \w+ token,
  // so `CREATE TABLE app_vault.admin_users (...)` mis-captured the SCHEMA name
  // `app_vault` as if it were a public table — producing phantom orphans
  // (app_vault, app, ...) that no account-delete sweep could ever cover.
  const createRe =
    /create\s+table\s+(?:if\s+not\s+exists\s+)?(?:["`]?(\w+)["`]?\.)?["`]?(\w+)["`]?[\s\S]*?\(([\s\S]*?)\);/gi;
  for (const entry of entries) {
    if (!entry.isFile || !entry.name.endsWith(".sql")) continue;
    let sql: string;
    try {
      sql = await Deno.readTextFile(new URL(entry.name, migrationsDir));
    } catch {
      continue;
    }
    let m: RegExpExecArray | null;
    while ((m = createRe.exec(sql))) {
      const schema = (m[1] ?? "public").toLowerCase();
      // Only public.* tables are in scope for the Art. 17 erasure sweep.
      if (schema !== "public") continue;
      const table = m[2].toLowerCase();
      const body = m[3].toLowerCase();
      const cols = new Set<string>();
      for (const col of PII_COLUMNS) {
        // crude but reliable: look for "<col> " or "<col>\n" at column-start
        if (new RegExp(`(^|,|\\()\\s*${col}\\b`, "m").test(body)) cols.add(col);
      }
      if (cols.size > 0) {
        const prior = byTable.get(table) ?? new Set();
        for (const c of cols) prior.add(c);
        byTable.set(table, prior);
      }
    }
  }
  return Array.from(byTable.entries()).map(([table_name, cols]) => ({
    table_name,
    columns: Array.from(cols),
  }));
}

Deno.test("USER_DATA_TABLES covers every public.* table with a PII column", async () => {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  // Distinguish a REAL prod credential from the placeholder env that other
  // test files in the same batch run set (e.g. https://example.supabase.co +
  // "fake-service-key"). Pointing the live-schema reader at a fake URL yields
  // a partial/empty table list, and the strict phantom-check below would then
  // false-fail every legitimately-listed table. Only treat creds as live when
  // they are not the well-known test placeholders.
  const looksLikeRealCreds = !!url && !!key &&
    !url.includes("example.supabase.co") &&
    !url.includes("localhost") &&
    key !== "fake-service-key";

  let piiTables: InfoSchemaRow[];
  let usedLiveSchema = false;
  if (looksLikeRealCreds) {
    try {
      piiTables = await fetchPiiTables(url!, key!);
      usedLiveSchema = true;
    } catch (e) {
      // Live query failed → fall back to migrations parse, but flag it.
      console.warn(
        `[coverage_test] live schema query failed (${e}); ` +
          `falling back to migrations directory parse. ` +
          `Owner: ensure list_pii_tables() RPC is deployed before relying on CI.`,
      );
      piiTables = await fetchPiiTablesFromMigrations();
    }
  } else {
    console.warn(
      "[coverage_test] no REAL SUPABASE creds (placeholder/test env or unset) — " +
        "running migrations-directory fallback. NOT a substitute for the " +
        "live-schema check; owner must run this with creds before prod deploy.",
    );
    piiTables = await fetchPiiTablesFromMigrations();
  }

  if (piiTables.length === 0) {
    // No data at all → cannot assert anything meaningful. Don't pass silently.
    throw new Error(
      "coverage_test: no PII tables discovered. Either the RPC is missing " +
        "and migrations parse returned 0 (corrupt env?), or the test is " +
        "running in a totally empty workspace. Refuse to pass.",
    );
  }

  const covered = new Set(USER_DATA_TABLES.map(([t]) => t.toLowerCase()));
  const excluded = new Set(EXCLUDED_TABLES.map((e) => e.table.toLowerCase()));

  const orphans: { table: string; columns: string[] }[] = [];
  for (const row of piiTables) {
    const t = row.table_name.toLowerCase();
    if (covered.has(t)) continue;
    if (excluded.has(t)) continue;
    orphans.push({ table: t, columns: row.columns });
  }

  if (orphans.length > 0) {
    const detail = orphans
      .map((o) => `  - ${o.table} (cols: ${o.columns.join(", ")})`)
      .join("\n");
    throw new Error(
      `\n\nGDPR Art. 17 coverage gap — ${orphans.length} table(s) carry ` +
        `user-PII columns but are NOT in USER_DATA_TABLES and NOT in ` +
        `EXCLUDED_TABLES:\n${detail}\n\n` +
        `Action: edit supabase/functions/account-delete/handler.ts. ` +
        `Add each table to USER_DATA_TABLES (it will be wiped on account ` +
        `delete) OR to EXCLUDED_TABLES (with a one-line GDPR justification). ` +
        `Then re-run this test.\n`,
    );
  }

  // Belt + braces: every table we CLAIM to wipe must actually exist in the
  // schema. Catches misspellings (the original audit root cause — the prior
  // handler listed `cases_v2`, `ai_memory`, `drafts`, `share_results`, `referrals`,
  // `payments`, `case_correspondence`, `feedback_buttons` — none of which
  // exist). In LIVE mode this catches drift; in fallback mode it's weaker
  // (migrations-only) but still catches blatant typos.
  const allKnownTables = new Set<string>();
  for (const row of piiTables) allKnownTables.add(row.table_name.toLowerCase());
  const phantom: string[] = [];
  for (const [t] of USER_DATA_TABLES) {
    if (!allKnownTables.has(t.toLowerCase())) phantom.push(t);
  }
  // In migrations-fallback mode we may not see every table (e.g. tables
  // created via SQL Studio or earlier migration files we couldn't parse).
  // Only fail-hard when we have a live schema read.
  if (usedLiveSchema && phantom.length > 0) {
    throw new Error(
      `USER_DATA_TABLES lists ${phantom.length} table(s) that do NOT ` +
        `exist in the live schema (typo / renamed / dropped):\n` +
        phantom.map((p) => `  - ${p}`).join("\n") +
        `\n\nThis is exactly the bug class that audit P0-7 closed. ` +
        `Remove or rename each entry.\n`,
    );
  }

  // Sanity: at least the seven biggest user-data tables had better be in.
  const mustInclude = [
    "chat_messages",
    "cases",
    "case_documents",
    "email_threads",
    "subscriptions",
    "profiles",
    "agent_audit_log",
  ];
  for (const t of mustInclude) {
    assertEquals(
      covered.has(t),
      true,
      `Sanity check: USER_DATA_TABLES must include "${t}"`,
    );
  }
});

Deno.test("EXCLUDED_TABLES entries all have a non-empty reason", () => {
  for (const entry of EXCLUDED_TABLES) {
    if (!entry.reason || entry.reason.trim().length < 8) {
      throw new Error(
        `EXCLUDED_TABLES["${entry.table}"] is missing a meaningful reason. ` +
          `Every exclusion must cite a GDPR carve-out (Art. 17(3)(a-e)) or ` +
          `concrete operational reason (FK cascade, org-scoped, no PII).`,
      );
    }
  }
});

Deno.test("No table appears in both USER_DATA_TABLES and EXCLUDED_TABLES", () => {
  const inDeleteList = new Set(USER_DATA_TABLES.map(([t]) => t.toLowerCase()));
  const overlap = EXCLUDED_TABLES
    .map((e) => e.table.toLowerCase())
    .filter((t) => inDeleteList.has(t));
  if (overlap.length > 0) {
    throw new Error(
      `Tables appearing in BOTH USER_DATA_TABLES and EXCLUDED_TABLES: ` +
        overlap.join(", ") +
        ` — pick one. A table is either wiped or retained.`,
    );
  }
});
