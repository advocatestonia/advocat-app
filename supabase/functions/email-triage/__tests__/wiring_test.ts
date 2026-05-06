// wiring_test.ts — Deno tests for the carry-over wiring in email-triage.
// -----------------------------------------------------------------------------
// Covers Tasks 1, 2, 3, and 5 of the carry-over directive:
//
//   Task 1 — loadMemoryBlockReal(): builds the MemoryBlock from real
//            sources (user_settings + user_ai_memory + recent owner
//            feedback). Soft-fails to a stable empty shape on error.
//
//   Task 2 — loadLawSearchReal(): invokes the existing `law-search`
//            edge fn, returns up to 5 chunks. Soft-fails to `[]` on
//            ANY error (no RAG availability dependency).
//
//   Task 3 — appendCaseEventReal(): appends `inbound_classified` to
//            `user_cases.timeline` jsonb with idempotency on
//            (case_id, type, ref_email_id, occurred_at).
//
//   Task 5 — applyMemoryUpdatesReal(): writes `own_counsel_email`
//            entries to `user_settings.own_counsel_emails` with
//            confidence-gating + dedupe.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/email-triage/__tests__/wiring_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  appendCaseEventReal,
  applyMemoryUpdatesReal,
  loadLawSearchReal,
  loadMemoryBlockReal,
  maybeTransitionWaitToStrategyOnInbound,
} from "../wiring.ts";
import type { MemoryUpdate } from "../parse_blocks.ts";

// =============================================================================
// Shared Supabase test double — a chainable query builder with seeded data
// =============================================================================

interface SeedShape {
  user_settings?: Record<string, {
    own_counsel_emails?: string[];
    dead_address_corrections?: Record<string, string>;
  }>;
  user_ai_memory?: Array<{
    user_id: string;
    key: string;
    value: { text: string; confidence?: number };
    confidence: number;
  }>;
  email_triage_results?: Array<{
    user_id: string;
    created_at: string;
    user_action: string | null;
    draft_subject?: string;
    draft_to?: string[];
  }>;
  user_cases?: Array<{
    id: string;
    user_id: string;
    timeline: unknown[];
  }>;
}

interface CapturedWrites {
  user_settings_updates: Array<{ user_id: string; row: Record<string, unknown> }>;
  user_settings_inserts: Array<Record<string, unknown>>;
  user_cases_updates: Array<{ id: string; user_id: string; timeline: unknown[] }>;
  function_invocations: Array<{ name: string; body: unknown }>;
}

// deno-lint-ignore no-explicit-any
function makeFakeSupabase(seed: SeedShape, captured: CapturedWrites): any {
  return {
    from(table: string) {
      return new FakeQuery(table, seed, captured);
    },
    functions: {
      invoke(name: string, options: { body: unknown }) {
        captured.function_invocations.push({ name, body: options.body });
        return Promise.resolve({
          data: { chunks: [], usage: { tokens: 0 } },
          error: null,
        });
      },
    },
  };
}

class FakeQuery {
  // deno-lint-ignore no-explicit-any
  private filters: Array<{ kind: string; key: string; value: any }> = [];
  private orderKey: string | null = null;
  private orderAsc = true;
  private limitN: number | null = null;
  private updateRow: Record<string, unknown> | null = null;
  private insertRow: Record<string, unknown> | null = null;
  private selectCols: string | null = null;
  private mode: "select" | "update" | "insert" = "select";

  constructor(
    private table: string,
    private seed: SeedShape,
    private captured: CapturedWrites,
  ) {}

  select(cols: string) {
    this.selectCols = cols;
    this.mode = "select";
    return this;
  }
  update(row: Record<string, unknown>) {
    this.updateRow = row;
    this.mode = "update";
    return this;
  }
  insert(row: Record<string, unknown>) {
    this.insertRow = row;
    this.mode = "insert";
    return this;
  }
  // deno-lint-ignore no-explicit-any
  eq(key: string, value: any) {
    this.filters.push({ kind: "eq", key, value });
    return this;
  }
  // deno-lint-ignore no-explicit-any
  in(key: string, values: any[]) {
    this.filters.push({ kind: "in", key, value: values });
    return this;
  }
  // deno-lint-ignore no-explicit-any
  gte(key: string, value: any) {
    this.filters.push({ kind: "gte", key, value });
    return this;
  }
  // deno-lint-ignore no-explicit-any
  not(key: string, _op: string, value: any) {
    this.filters.push({ kind: "not_null", key, value });
    return this;
  }
  order(key: string, opts: { ascending: boolean }) {
    this.orderKey = key;
    this.orderAsc = opts.ascending;
    return this;
  }
  limit(n: number) {
    this.limitN = n;
    return this;
  }

  maybeSingle() {
    return Promise.resolve(this._exec(true));
  }

  // Make the builder thenable so `await sb.from(...).update(...).eq(...)` works.
  // deno-lint-ignore no-explicit-any
  then(onFulfilled: (value: any) => any, onRejected?: (e: unknown) => any) {
    try {
      return Promise.resolve(this._exec(false)).then(onFulfilled, onRejected);
    } catch (e) {
      return Promise.reject(e).then(onFulfilled, onRejected);
    }
  }

  // deno-lint-ignore no-explicit-any
  private _exec(single: boolean): any {
    if (this.mode === "update") {
      if (this.table === "user_cases") {
        const row = this._matchRow();
        if (row) {
          this.captured.user_cases_updates.push({
            id: row.id as string,
            user_id: row.user_id as string,
            timeline: this.updateRow!.timeline as unknown[],
          });
        }
        return { data: null, error: null };
      }
      if (this.table === "user_settings") {
        const row = this._matchRow();
        const userId = (row?.user_id as string | undefined) ??
          this.filters.find((f) => f.key === "user_id")?.value;
        this.captured.user_settings_updates.push({
          user_id: userId as string,
          row: this.updateRow!,
        });
        return { data: null, error: null };
      }
      return { data: null, error: null };
    }
    if (this.mode === "insert") {
      if (this.table === "user_settings") {
        this.captured.user_settings_inserts.push(this.insertRow!);
      }
      return { data: this.insertRow, error: null };
    }
    // SELECT
    const rows = this._allRowsForTable();
    let filtered = rows.filter((row) =>
      this.filters.every((f) => {
        if (f.kind === "eq") return row[f.key] === f.value;
        if (f.kind === "in") return (f.value as unknown[]).includes(row[f.key]);
        if (f.kind === "gte") return String(row[f.key] ?? "") >= String(f.value);
        if (f.kind === "not_null") return row[f.key] != null;
        return true;
      })
    );
    if (this.orderKey) {
      filtered = filtered.slice().sort((a, b) => {
        const av = a[this.orderKey!] as string | number;
        const bv = b[this.orderKey!] as string | number;
        if (av === bv) return 0;
        return (av < bv ? -1 : 1) * (this.orderAsc ? 1 : -1);
      });
    }
    if (this.limitN != null) filtered = filtered.slice(0, this.limitN);
    if (single) {
      return { data: filtered[0] ?? null, error: null };
    }
    return { data: filtered, error: null };
  }

  private _allRowsForTable(): Array<Record<string, unknown>> {
    if (this.table === "user_settings") {
      return Object.entries(this.seed.user_settings ?? {})
        .map(([uid, v]) => ({ user_id: uid, ...v }));
    }
    if (this.table === "user_ai_memory") {
      return (this.seed.user_ai_memory ?? []).map((r) => ({ ...r }));
    }
    if (this.table === "email_triage_results") {
      return (this.seed.email_triage_results ?? []).map((r) => ({ ...r }));
    }
    if (this.table === "user_cases") {
      return (this.seed.user_cases ?? []).map((r) => ({ ...r }));
    }
    return [];
  }

  private _matchRow(): Record<string, unknown> | undefined {
    const rows = this._allRowsForTable();
    return rows.find((row) =>
      this.filters.every((f) => f.kind !== "eq" || row[f.key] === f.value)
    );
  }
}

function emptyCaptured(): CapturedWrites {
  return {
    user_settings_updates: [],
    user_settings_inserts: [],
    user_cases_updates: [],
    function_invocations: [],
  };
}

// =============================================================================
// Task 1 — loadMemoryBlockReal
// =============================================================================

Deno.test("loadMemoryBlockReal — assembles full block from real sources", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({
    user_settings: {
      "user-1": {
        own_counsel_emails: ["jokela@oikeus.fi", "Backup@Counsel.Ee"],
        dead_address_corrections: {
          "kirjaamo@oikeusapu.fi": "kirjaamo@oikapu.fi",
        },
      },
    },
    user_ai_memory: [
      {
        user_id: "user-1",
        key: "name",
        value: { text: "Dmitri Sulga" },
        confidence: 0.95,
      },
      {
        user_id: "user-1",
        key: "known_party",
        value: { text: "Attorney Jokela (own counsel)" },
        confidence: 0.9,
      },
      {
        user_id: "user-1",
        key: "known_party",
        value: { text: "Officer Tolonen (Police HQ)" },
        confidence: 0.8,
      },
    ],
    email_triage_results: [
      {
        user_id: "user-1",
        created_at: new Date(Date.now() - 2 * 24 * 3600 * 1000).toISOString(),
        user_action: "sent",
        draft_to: ["kirjaamo@valtiokonttori.fi"],
        draft_subject: "Re: dnro 12345",
      },
      {
        user_id: "user-1",
        created_at: new Date(Date.now() - 4 * 24 * 3600 * 1000).toISOString(),
        user_action: "edited",
        draft_to: ["jokela@oikeus.fi"],
      },
    ],
  }, captured);

  const block = await loadMemoryBlockReal(sb, "user-1");

  assertEquals(block.own_counsel_emails?.length, 2);
  assert(block.own_counsel_emails!.includes("jokela@oikeus.fi"));
  assert(block.own_counsel_emails!.includes("backup@counsel.ee"));

  assertEquals(block.dead_addresses?.length, 1);
  assertEquals(block.dead_addresses?.[0].from, "kirjaamo@oikeusapu.fi");
  assertEquals(block.dead_addresses?.[0].to, "kirjaamo@oikapu.fi");

  assertEquals(block.identity_markers?.["name"], "Dmitri Sulga");

  assertEquals(block.known_privileged_individuals?.length, 1);
  assert(
    block.known_privileged_individuals![0].toLowerCase().includes("jokela"),
  );

  assertExists(block.recent_owner_feedback);
  assert(block.recent_owner_feedback!.includes("sent"));
  assert(block.recent_owner_feedback!.includes("kirjaamo@valtiokonttori.fi"));
});

Deno.test("loadMemoryBlockReal — empty/no user returns stable empty shape", async () => {
  const sb = makeFakeSupabase({}, emptyCaptured());
  const block = await loadMemoryBlockReal(sb, "");
  assertEquals(block.own_counsel_emails, []);
  assertEquals(block.dead_addresses, []);
  assertEquals(block.identity_markers, {});
  assertEquals(block.recent_owner_feedback, undefined);
});

Deno.test("loadMemoryBlockReal — supabase throw soft-fails to empty", async () => {
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    from() {
      throw new Error("simulated DB outage");
    },
  };
  const block = await loadMemoryBlockReal(sb, "user-1");
  assertEquals(block.own_counsel_emails, []);
  assertEquals(block.dead_addresses, []);
  assertEquals(block.identity_markers, {});
});

// =============================================================================
// Task 2 — loadLawSearchReal
// =============================================================================

Deno.test("loadLawSearchReal — invokes law-search with trimmed query, returns chunks", async () => {
  const captured = emptyCaptured();
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    functions: {
      invoke(name: string, opts: { body: unknown }) {
        captured.function_invocations.push({ name, body: opts.body });
        return Promise.resolve({
          data: {
            chunks: [
              {
                id: "c1", act_slug: "kars", paragraph: "199",
                title: "Vargus", body: "x".repeat(2000),
                source_url: "https://riigiteataja.ee/kars-199",
                similarity: 0.82,
              },
              {
                id: "c2", act_slug: "kars", paragraph: "200",
                title: "Röövimine", body: "y", source_url: null,
                similarity: 0.75,
              },
            ],
            usage: { tokens: 42 },
          },
          error: null,
        });
      },
    },
  };

  const out = await loadLawSearchReal(sb, "  vargus 199  ");
  assert(Array.isArray(out));
  assertEquals((out as unknown[]).length, 2);
  const first = (out as Array<Record<string, unknown>>)[0];
  assertEquals((first.body as string).length, 800);
  assertEquals(first.act_slug, "kars");
  assertEquals(captured.function_invocations.length, 1);
  const body = captured.function_invocations[0].body as Record<string, unknown>;
  assertEquals(body.query, "vargus 199");
  assertEquals(body.lang, "et");
  assertEquals(body.match_count, 5);
});

Deno.test("loadLawSearchReal — empty query short-circuits to []", async () => {
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    functions: { invoke() { throw new Error("should not be called"); } },
  };
  const out = await loadLawSearchReal(sb, "   ");
  assertEquals(out, []);
});

Deno.test("loadLawSearchReal — soft-fails to [] on edge fn error", async () => {
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    functions: {
      invoke() {
        return Promise.resolve({
          data: null,
          error: { message: "law-search timeout" },
        });
      },
    },
  };
  const out = await loadLawSearchReal(sb, "vargus");
  assertEquals(out, []);
});

Deno.test("loadLawSearchReal — soft-fails to [] on thrown exception", async () => {
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    functions: { invoke() { throw new Error("network down"); } },
  };
  const out = await loadLawSearchReal(sb, "appeal window");
  assertEquals(out, []);
});

// =============================================================================
// Task 3 — appendCaseEventReal
// =============================================================================

Deno.test("appendCaseEventReal — appends inbound_classified to timeline", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({
    user_cases: [
      { id: "case-1", user_id: "user-1", timeline: [] },
    ],
  }, captured);

  await appendCaseEventReal(sb, {
    user_id: "user-1",
    case_id: "case-1",
    type: "inbound_classified",
    payload: {
      thread_id: "thread-99",
      summary: "Receipt confirmed",
      inbound: "acknowledgement",
      tracks: ["korvausvaatimus"],
      deadlines: [],
    },
  });

  assertEquals(captured.user_cases_updates.length, 1);
  const update = captured.user_cases_updates[0];
  assertEquals(update.id, "case-1");
  assertEquals(update.timeline.length, 1);
  const entry = update.timeline[0] as Record<string, unknown>;
  assertEquals(entry.type, "inbound_classified");
  assertEquals(entry.thread_id, "thread-99");
  assertEquals(entry.ref_email_id, "thread-99");
  assertEquals(entry.summary, "Receipt confirmed");
  assertExists(entry.occurred_at);
  assertExists(entry.metadata);
});

Deno.test("appendCaseEventReal — null case_id is a no-op", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({}, captured);
  await appendCaseEventReal(sb, {
    user_id: "user-1",
    case_id: null,
    type: "inbound_classified",
    payload: { thread_id: "thread-99" },
  });
  assertEquals(captured.user_cases_updates.length, 0);
});

Deno.test("appendCaseEventReal — idempotent on (case_id, type, ref_email_id, day)", async () => {
  const captured = emptyCaptured();
  const today = new Date().toISOString();
  const seed = {
    user_cases: [{
      id: "case-1",
      user_id: "user-1",
      timeline: [
        {
          type: "inbound_classified",
          ref_email_id: "thread-99",
          occurred_at: today,
          ts: today,
        },
      ],
    }],
  };
  const sb = makeFakeSupabase(seed, captured);

  await appendCaseEventReal(sb, {
    user_id: "user-1",
    case_id: "case-1",
    type: "inbound_classified",
    payload: { thread_id: "thread-99", summary: "dup" },
  });

  assertEquals(captured.user_cases_updates.length, 0);
});

Deno.test("appendCaseEventReal — DB throw is swallowed", async () => {
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    from() { throw new Error("DB down"); },
  };
  await appendCaseEventReal(sb, {
    user_id: "user-1",
    case_id: "case-1",
    type: "inbound_classified",
    payload: { thread_id: "t1" },
  });
});

// =============================================================================
// Task 5 — applyMemoryUpdatesReal
// =============================================================================

Deno.test("applyMemoryUpdatesReal — high-confidence own_counsel_email writes back", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({
    user_settings: {
      "user-1": {
        own_counsel_emails: ["existing@counsel.fi"],
      },
    },
  }, captured);

  const updates: MemoryUpdate[] = [
    {
      key: "own_counsel_email",
      value: "Jokela@Oikeus.Fi",
      reason: "thread confirms own counsel",
      confidence: "high",
      source_layer: "thread",
      expires_at: null,
    },
  ];

  await applyMemoryUpdatesReal(sb, "user-1", updates);

  assertEquals(captured.user_settings_updates.length, 1);
  const updated = captured.user_settings_updates[0]
    .row.own_counsel_emails as string[];
  assert(updated.includes("existing@counsel.fi"));
  assert(updated.includes("jokela@oikeus.fi"));
});

Deno.test("applyMemoryUpdatesReal — low-confidence ignored", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({}, captured);
  const updates: MemoryUpdate[] = [
    {
      key: "own_counsel_email",
      value: "stranger@example.com",
      reason: "guess",
      confidence: "low",
      source_layer: "thread",
      expires_at: null,
    },
  ];
  await applyMemoryUpdatesReal(sb, "user-1", updates);
  assertEquals(captured.user_settings_updates.length, 0);
  assertEquals(captured.user_settings_inserts.length, 0);
});

Deno.test("applyMemoryUpdatesReal — non-counsel keys ignored", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({}, captured);
  const updates: MemoryUpdate[] = [
    {
      key: "discussed_topic",
      value: "deportation appeal",
      reason: "thread",
      confidence: "high",
      source_layer: "thread",
      expires_at: null,
    },
  ];
  await applyMemoryUpdatesReal(sb, "user-1", updates);
  assertEquals(captured.user_settings_updates.length, 0);
  assertEquals(captured.user_settings_inserts.length, 0);
});

Deno.test("applyMemoryUpdatesReal — invalid email shape rejected", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({}, captured);
  const updates: MemoryUpdate[] = [
    {
      key: "own_counsel_email",
      value: "not-an-email",
      reason: "x",
      confidence: "high",
      source_layer: "thread",
      expires_at: null,
    },
  ];
  await applyMemoryUpdatesReal(sb, "user-1", updates);
  assertEquals(captured.user_settings_updates.length, 0);
  assertEquals(captured.user_settings_inserts.length, 0);
});

Deno.test("applyMemoryUpdatesReal — inserts row when none exists", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({}, captured);
  const updates: MemoryUpdate[] = [
    {
      key: "confirmed_attorney_email",
      value: "new@advokaat.ee",
      reason: "explicit confirmation",
      confidence: "medium",
      source_layer: "thread",
      expires_at: null,
    },
  ];
  await applyMemoryUpdatesReal(sb, "user-1", updates);
  assertEquals(captured.user_settings_updates.length, 0);
  assertEquals(captured.user_settings_inserts.length, 1);
  const inserted = captured.user_settings_inserts[0];
  assertEquals(inserted.user_id, "user-1");
  assertEquals(
    (inserted.own_counsel_emails as string[])[0],
    "new@advokaat.ee",
  );
});

Deno.test("applyMemoryUpdatesReal — duplicate already in list is no-op", async () => {
  const captured = emptyCaptured();
  const sb = makeFakeSupabase({
    user_settings: {
      "user-1": { own_counsel_emails: ["jokela@oikeus.fi"] },
    },
  }, captured);
  const updates: MemoryUpdate[] = [
    {
      key: "own_counsel_email",
      value: "Jokela@oikeus.fi",
      reason: "rediscovery",
      confidence: "high",
      source_layer: "thread",
      expires_at: null,
    },
  ];
  await applyMemoryUpdatesReal(sb, "user-1", updates);
  assertEquals(captured.user_settings_updates.length, 0);
  assertEquals(captured.user_settings_inserts.length, 0);
});

Deno.test("applyMemoryUpdatesReal — DB throw is swallowed", async () => {
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    from() { throw new Error("simulated"); },
  };
  const updates: MemoryUpdate[] = [
    {
      key: "own_counsel_email",
      value: "x@y.fi",
      reason: "",
      confidence: "high",
      source_layer: "thread",
      expires_at: null,
    },
  ];
  await applyMemoryUpdatesReal(sb, "user-1", updates);
});

// =============================================================================
// Phase 2 Pkg 5 — maybeTransitionWaitToStrategyOnInbound
// =============================================================================
// Spec: docs/architecture/phase2-pkg5-state-machine.md §8.
//
// Fake Supabase here is purpose-built — the existing FakeQuery shared
// above doesn't track `phase`, doesn't support `.rpc()`, and the Pkg 5
// hook is the only call-site that needs both. We keep both fakes side
// by side rather than retro-fitting the existing one to avoid breaking
// the carry-over tests above.

interface PhaseFakeShape {
  cases: Record<string, { phase: string | null }>;
  rpcResult?: { data?: unknown; error?: { message: string } | null };
  rpcThrow?: Error;
  caseSelectThrow?: Error;
}

interface PhaseFakeCaptures {
  rpc_calls: Array<{ name: string; args: Record<string, unknown> }>;
}

// deno-lint-ignore no-explicit-any
function makePhaseFakeSb(
  shape: PhaseFakeShape,
  captures: PhaseFakeCaptures,
): any {
  return {
    from(table: string) {
      if (table !== "user_cases") {
        throw new Error(`unexpected table in phase fake: ${table}`);
      }
      let id: string | null = null;
      const builder = {
        select(_cols: string) {
          return builder;
        },
        // deno-lint-ignore no-explicit-any
        eq(key: string, value: any) {
          if (key === "id") id = value as string;
          return builder;
        },
        maybeSingle() {
          if (shape.caseSelectThrow) throw shape.caseSelectThrow;
          if (id === null || !shape.cases[id]) {
            return Promise.resolve({ data: null, error: null });
          }
          return Promise.resolve({
            data: { phase: shape.cases[id].phase },
            error: null,
          });
        },
      };
      return builder;
    },
    // deno-lint-ignore no-explicit-any
    rpc(name: string, args: Record<string, unknown>) {
      captures.rpc_calls.push({ name, args });
      if (shape.rpcThrow) {
        return Promise.reject(shape.rpcThrow);
      }
      const r = shape.rpcResult ?? { data: null, error: null };
      return Promise.resolve(r);
    },
  };
}

Deno.test("Pkg5/CPS-T-EMAIL-01 — wait + HIGH severity flips to strategy", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
    rpcResult: {
      data: {
        changed: true,
        from: "wait",
        to: "strategy",
        phase_entered_at: new Date().toISOString(),
      },
      error: null,
    },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "HIGH",
    triage_id: "triage-99",
    thread_id: "thread-1",
  });

  assertExists(out);
  assertEquals(out!.changed, true);
  assertEquals(out!.from, "wait");
  assertEquals(out!.to, "strategy");

  // Verify RPC payload — set_case_phase, with metadata source markers.
  assertEquals(captures.rpc_calls.length, 1);
  const call = captures.rpc_calls[0];
  assertEquals(call.name, "set_case_phase");
  assertEquals(call.args.p_case_id, "case-1");
  assertEquals(call.args.p_phase, "strategy");
  const meta = call.args.p_metadata as Record<string, unknown>;
  assertEquals(meta.source, "email-triage");
  assertEquals(meta.severity, "HIGH");
  assertEquals(meta.triage_id, "triage-99");
});

Deno.test("Pkg5/CPS-T-EMAIL-02 — CRITICAL severity also flips", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
    rpcResult: {
      data: { changed: true, from: "wait", to: "strategy" },
      error: null,
    },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "CRITICAL",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out?.changed, true);
  assertEquals(captures.rpc_calls.length, 1);
});

Deno.test("Pkg5/CPS-T-EMAIL-03 — MEDIUM severity is a no-op", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "MEDIUM",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-04 — LOW severity is a no-op", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "LOW",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-05 — null case_id is a no-op (unmapped thread)", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({ cases: {} }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: null,
    severity: "HIGH",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-06 — case in strategy stays put (no double-flip)", async () => {
  // The hook ONLY flips wait → strategy. Other phases — strategy,
  // draft, intake — must be left alone so we don't yank a user out
  // of mid-letter draft work because of an inbound notification.
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "strategy" } },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "HIGH",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-07 — case in draft stays put", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "draft" } },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "HIGH",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-08 — closed case is never auto-resurrected", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "closed" } },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "CRITICAL",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-09 — missing case row soft-fails to null", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({ cases: {} }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "nonexistent-case",
    severity: "HIGH",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-10 — RPC error is swallowed (returns null)", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
    rpcResult: { data: null, error: { message: "RLS reject" } },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "HIGH",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  // RPC was attempted (verified the trigger fired) but error was swallowed.
  assertEquals(captures.rpc_calls.length, 1);
});

Deno.test("Pkg5/CPS-T-EMAIL-11 — RPC throw is swallowed", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
    rpcThrow: new Error("network down"),
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "HIGH",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
});

Deno.test("Pkg5/CPS-T-EMAIL-12 — case-select throw soft-fails", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
    caseSelectThrow: new Error("read failed"),
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "HIGH",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-13 — null severity is a no-op", async () => {
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: null,
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out, null);
  assertEquals(captures.rpc_calls.length, 0);
});

Deno.test("Pkg5/CPS-T-EMAIL-14 — lowercase severity is normalised", async () => {
  // Defensive: callers may pass severity in any case. The helper
  // upper-cases before the gate check.
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
    rpcResult: {
      data: { changed: true, from: "wait", to: "strategy" },
      error: null,
    },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "high",
    triage_id: "t",
    thread_id: "th",
  });
  assertEquals(out?.changed, true);
  assertEquals(captures.rpc_calls.length, 1);
});

Deno.test("Pkg5/CPS-T-EMAIL-15 — RPC reports noop, helper returns changed:false", async () => {
  // Idempotency contract: if the RPC says noop (race with another tab
  // already flipped the case), helper returns changed:false but doesn't
  // throw. Caller sees no transition in the response payload.
  const captures: PhaseFakeCaptures = { rpc_calls: [] };
  const sb = makePhaseFakeSb({
    cases: { "case-1": { phase: "wait" } },
    rpcResult: {
      data: { changed: false, reason: "noop", phase: "strategy" },
      error: null,
    },
  }, captures);

  const out = await maybeTransitionWaitToStrategyOnInbound(sb, {
    case_id: "case-1",
    severity: "HIGH",
    triage_id: "t",
    thread_id: "th",
  });
  assertExists(out);
  assertEquals(out!.changed, false);
});
