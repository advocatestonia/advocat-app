// _tests/b2b_signal_migration_test.ts
// -----------------------------------------------------------------------------
// Migration contract tests for `20260525223000_b2b_signals.sql`.
//
// These tests do NOT spin up Postgres — they parse the migration SQL and
// assert that:
//
//   * Every column, RPC, RLS policy, and index the b2b-signal pipeline
//     depends on is declared.
//   * Idempotent guards (`if not exists`, `create or replace`) cover every
//     creation, so re-running the migration is safe.
//   * The threshold constant (100) and signal-score defaults match what
//     the edge fn / wire-up sites expect.
//
// If anyone edits the migration in a way that drops a column or changes the
// RPC signature, the corresponding test below fires before the change
// reaches production — a fast feedback loop without a live DB.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/_tests/b2b_signal_migration_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  B2B_MODAL_THRESHOLD,
  DEFAULT_SCORES,
  SIGNAL_TYPES,
} from "../b2b-signal/signals.ts";

const MIGRATION_PATH = new URL(
  "../../migrations/20260525223000_b2b_signals.sql",
  import.meta.url,
);

const sql = await Deno.readTextFile(MIGRATION_PATH);

// ─── Columns on public.profiles ──────────────────────────────────────────

Deno.test("MIG-T01 — adds b2b_score column", () => {
  assertStringIncludes(
    sql,
    "add column if not exists b2b_score          integer not null default 0",
  );
});

Deno.test("MIG-T02 — adds b2b_modal_pending column", () => {
  assertStringIncludes(
    sql,
    "add column if not exists b2b_modal_pending  boolean not null default false",
  );
});

Deno.test("MIG-T03 — adds b2b_modal_shown_at column", () => {
  assertStringIncludes(
    sql,
    "add column if not exists b2b_modal_shown_at timestamptz",
  );
});

Deno.test("MIG-T04 — adds email_domain column", () => {
  assertStringIncludes(sql, "add column if not exists email_domain       text");
});

Deno.test("MIG-T05 — email_domain trigger is created", () => {
  assertStringIncludes(sql, "profiles_email_domain_sync");
  assertStringIncludes(sql, "before insert or update of email on public.profiles");
});

// ─── b2b_signals table ──────────────────────────────────────────────────

Deno.test("MIG-T06 — b2b_signals table is created with the right shape", () => {
  assertStringIncludes(sql, "create table if not exists public.b2b_signals");
  assertStringIncludes(sql, "user_id      uuid not null references auth.users(id)");
  assertStringIncludes(sql, "signal_type  text not null");
  assertStringIncludes(sql, "score        integer not null default 0");
  assertStringIncludes(sql, "payload      jsonb");
  assertStringIncludes(sql, "occurred_at  timestamptz not null default now()");
});

Deno.test("MIG-T07 — composite index on (user_id, occurred_at desc) exists", () => {
  assertStringIncludes(
    sql,
    "create index if not exists idx_b2b_signals_user_occurred\n  on public.b2b_signals (user_id, occurred_at desc)",
  );
});

Deno.test("MIG-T08 — score check constraint clamps to [0, 1000]", () => {
  assertStringIncludes(sql, "b2b_signals_score_range_chk");
  assertStringIncludes(sql, "check (score between 0 and 1000)");
});

// ─── RLS ────────────────────────────────────────────────────────────────

Deno.test("MIG-T09 — RLS is enabled and a select-own policy exists", () => {
  assertStringIncludes(sql, "alter table public.b2b_signals enable row level security");
  assertStringIncludes(sql, "b2b_signals_select_own");
  assertStringIncludes(sql, "auth.uid() = user_id");
});

Deno.test("MIG-T10 — no insert/update/delete policy for non-service callers", () => {
  // The migration should NOT grant insert/update/delete via RLS policy.
  // If anyone adds one we want a test to fail so they explicitly review.
  const forbidden = [
    /create policy [a-z_]+ on public\.b2b_signals\s+for insert/i,
    /create policy [a-z_]+ on public\.b2b_signals\s+for update/i,
    /create policy [a-z_]+ on public\.b2b_signals\s+for delete/i,
  ];
  for (const re of forbidden) {
    assert(!re.test(sql), `unexpected RLS write policy: ${re}`);
  }
});

// ─── RPCs ───────────────────────────────────────────────────────────────

Deno.test("MIG-T11 — compute_b2b_score RPC is declared", () => {
  assertStringIncludes(
    sql,
    "create or replace function public.compute_b2b_score(p_user_id uuid)",
  );
  assertStringIncludes(sql, "interval '30 days'");
});

Deno.test("MIG-T12 — record_b2b_signal RPC is declared with the expected signature", () => {
  assertStringIncludes(
    sql,
    "create or replace function public.record_b2b_signal(",
  );
  assertStringIncludes(sql, "p_user_id     uuid");
  assertStringIncludes(sql, "p_signal_type text");
  assertStringIncludes(sql, "p_score       integer");
  assertStringIncludes(sql, "p_payload     jsonb");
  assertStringIncludes(sql, "security definer");
});

Deno.test("MIG-T13 — record_b2b_signal flips modal_pending only when score crosses 100 AND not previously shown", () => {
  // The migration's threshold MUST equal B2B_MODAL_THRESHOLD from signals.ts.
  assertStringIncludes(sql, "v_new_score >= 100");
  assertStringIncludes(sql, "b2b_modal_shown_at is null");
});

Deno.test("MIG-T14 — record_b2b_signal RPC is granted to service_role only", () => {
  assertStringIncludes(
    sql,
    "revoke all on function public.record_b2b_signal(uuid, text, integer, jsonb) from public",
  );
  assertStringIncludes(
    sql,
    "grant execute on function public.record_b2b_signal(uuid, text, integer, jsonb) to service_role",
  );
});

// ─── Idempotency ─────────────────────────────────────────────────────────

Deno.test("MIG-T15 — every CREATE is idempotent (re-run safe)", () => {
  // Crude but effective check: every `create table` / `create index` /
  // `create policy` / `create function` clause in the file must include
  // either "if not exists" or "or replace" (or be wrapped in a guarded
  // DO $$ block).
  // We split on top-level statements then check each.
  const lines = sql.split("\n");
  let buf = "";
  for (const line of lines) {
    if (line.trim().startsWith("--") || line.trim() === "") continue;
    buf += " " + line.trim();
    if (line.trim().endsWith(";")) {
      const stmt = buf.trim().toLowerCase();
      buf = "";
      if (stmt.startsWith("create table ")) {
        assert(
          stmt.includes("if not exists"),
          `non-idempotent: ${stmt.slice(0, 120)}`,
        );
      }
      if (stmt.startsWith("create index ")) {
        assert(
          stmt.includes("if not exists"),
          `non-idempotent: ${stmt.slice(0, 120)}`,
        );
      }
      if (stmt.startsWith("create function ")) {
        // The migration uses `create or replace function`, not bare
        // `create function`. Catching the latter here.
        assert(false, `should be create-or-replace: ${stmt.slice(0, 120)}`);
      }
      if (stmt.startsWith("create policy ")) {
        // Every CREATE POLICY is preceded by a DROP POLICY IF EXISTS — we
        // check that pattern below in a dedicated test.
      }
    }
  }
});

Deno.test("MIG-T16 — every CREATE POLICY is preceded by a DROP POLICY IF EXISTS", () => {
  // Captures the `drop policy if exists X on Y; create policy X on Y ...`
  // idempotency idiom. If somebody adds a bare CREATE POLICY we catch it.
  const createPolicyMatches = [...sql.matchAll(/create policy (\w+)\s+on\s+(public\.\w+)/gi)];
  for (const m of createPolicyMatches) {
    const polName = m[1];
    const table = m[2];
    const dropRe = new RegExp(
      `drop policy if exists ${polName}\\s+on\\s+${table.replace(".", "\\.")}`,
      "i",
    );
    assert(
      dropRe.test(sql),
      `expected idempotent drop-then-create for policy ${polName}`,
    );
  }
});

// ─── Cross-module constants ─────────────────────────────────────────────

Deno.test("CONST-T01 — signals.ts threshold matches v2 migration's hard-coded 110", () => {
  // v2 calibration (2026-05-25, post 6-expert consilium): the effective
  // threshold lives in the v2 compound-trigger migration
  // `20260525234500_b2b_v2_compound_trigger.sql` as `v_threshold := 110`.
  // The v1 migration's `>= 100` predicate has been superseded by the
  // CREATE OR REPLACE in the v2 migration. signals.ts MUST mirror v2.
  // If one moves the other MUST.
  const V2_MIGRATION_PATH = new URL(
    "../../migrations/20260525234500_b2b_v2_compound_trigger.sql",
    import.meta.url,
  );
  const v2Sql = Deno.readTextFileSync(V2_MIGRATION_PATH);
  assertStringIncludes(
    v2Sql,
    "v_threshold        constant integer := 110",
  );
  assert(
    (B2B_MODAL_THRESHOLD as number) === 110,
    "B2B_MODAL_THRESHOLD must equal the v2 migration's hard-coded threshold (110)",
  );
});

Deno.test("CONST-T02 — DEFAULT_SCORES domain entry does NOT single-handedly trip threshold (v2)", () => {
  // v2 calibration: domain alone (60) must NOT trip the modal — this was
  // the headline UX bug fix from the 6-expert consilium (signup-time
  // false positives before the user had done anything in-app). The v2
  // compound trigger additionally requires ≥1 non-domain signal type,
  // but at minimum the raw score must not already cross the threshold.
  assert(
    DEFAULT_SCORES.law_firm_email_domain < B2B_MODAL_THRESHOLD,
    "law_firm_email_domain score must be < threshold so domain-only signup does NOT flip the modal (v2 design)",
  );
});

Deno.test("CONST-T03 — every SIGNAL_TYPES member has a DEFAULT_SCORES entry", () => {
  for (const t of SIGNAL_TYPES) {
    assert(
      typeof DEFAULT_SCORES[t] === "number",
      `${t} is missing from DEFAULT_SCORES`,
    );
  }
});
