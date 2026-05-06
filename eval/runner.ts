#!/usr/bin/env -S deno run -A
// Advocat Email Agent — Pkg 8 eval runner (scaffold).
//
// Purpose: regression-check the email-triage edge function across prompt
// versions (v1.1-final ↔ v1.2.1-final) using the 5 Sulga test seeds 23–27
// from track_A_v1.2_prompt.md §5.
//
// SCOPE & STATUS
//   * This is scaffolding. It runs end-to-end with TODO markers wherever a
//     production-grade implementation requires staging-DB writes or
//     semantic comparison beyond regex. See README.md "Caveats".
//   * Sister suite: `Advocat/scripts/eval/run-eval.ts` covers chat answer
//     quality (judge-model rubric). This runner covers email-triage block
//     extraction. They are complementary, not duplicative.
//
// USAGE
//   deno run --allow-net --allow-env --allow-read --allow-write \
//     eval/runner.ts \
//     --prompt-version v1.2.1-final \
//     --fixture all                  # or --fixture sulga_test_23_HAO_paatos
//
// ENV
//   SUPABASE_URL                    e.g. https://<staging-project>.supabase.co
//   SUPABASE_ANON_KEY               for invoking edge fn
//   SUPABASE_SERVICE_ROLE_KEY       (TODO) — needed to insert fixture threads
//                                   into staging DB, since email-triage edge
//                                   fn pulls thread by thread_id from DB.
//   EMAIL_AGENT_PROMPT_VERSION      passed to edge fn via header — backend
//                                   selector reads this to flip prompt.
//                                   Owner: must be set in Supabase secrets.
//   ANTHROPIC_API_KEY               (TODO) — for advanced semantic-diff
//                                   judge step.
//
// OUTPUT
//   eval/results/<fixture>.<version>.json with: blocks, latency, expected-met.
//   eval/results/ is gitignored.

import { parseArgs } from "jsr:@std/cli/parse-args";
import { walk } from "jsr:@std/fs/walk";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const PROMPT_VERSION = Deno.env.get("EMAIL_AGENT_PROMPT_VERSION") ?? "";

const HERE = new URL(".", import.meta.url).pathname;
const FIXTURES_DIR = `${HERE}fixtures`;
const EXPECTED_DIR = `${HERE}expected`;
const RESULTS_DIR = `${HERE}results`;

interface Fixture {
  _test_id: string;
  _source_spec: string;
  _purpose: string;
  thread: {
    thread_id: string;
    messages: Array<{
      from: string;
      to: string;
      subject: string;
      date: string;
      body: string;
    }>;
  };
  headers: Record<string, unknown>;
  attachments_metadata: Array<Record<string, unknown>>;
  active_case_overlay: Record<string, unknown>;
  user_question: string;
  _eval_intent: string;
}

interface ExpectationCheck {
  name: string;
  pattern: RegExp;
  required: boolean;
}

interface RunResult {
  fixture: string;
  prompt_version: string;
  ts: string;
  latency_ms: number;
  edge_fn_status: number | null;
  blocks: Record<string, string>;
  expected_met: Array<{ check: string; pass: boolean; required: boolean }>;
  pass: boolean;
  error?: string;
}

// ─── Expected-output expectations ──────────────────────────────────────────
//
// Heuristic regex set per fixture. Derived from expected/<fixture>.md PASS
// criteria. NOT a full semantic diff — owner: see TODO(semantic) below.

const EXPECTATIONS: Record<string, ExpectationCheck[]> = {
  sulga_test_23_HAO_paatos: [
    { name: "appeal_route forum=KHO", pattern: /forum:\s*KHO/i, required: true },
    { name: "deadline 30 days", pattern: /deadline_days:\s*30|30\s*(päivän|days)/i, required: true },
    { name: "saantitodistus service basis", pattern: /saantitodistus/i, required: true },
    { name: "KHO valituslupa action", pattern: /KHO\s+valituslupa/i, required: true },
    { name: "no HAO-addressed restoration draft", pattern: /Helsingin hallinto-oikeudelle.*§\s*114/is, required: false },
    { name: "deadline anchor 2026-06", pattern: /2026-06-0[2-9]|2026-06-1[0-5]/i, required: true },
  ],
  sulga_test_24_posti_dimitri: [
    { name: "tracking number RS846423104FI", pattern: /RS846423104FI/i, required: true },
    { name: "all 3 dates present", pattern: /22\.4\.2026[\s\S]*29\.4\.2026[\s\S]*6\.5\.2026|2026-04-22[\s\S]*2026-04-29[\s\S]*2026-05-06/i, required: true },
    { name: "HOL § 114 cited", pattern: /HOL\s*§\s*114|§\s*114|hallintolainkäyttölaki.*114/i, required: true },
    { name: "Charter Art 41 angle", pattern: /Charter\s*Art\.?\s*41|perusoikeuskirja.*41|EU.*41/i, required: true },
    { name: "name_transliteration memory update", pattern: /name_transliteration[\s\S]{0,200}Dimitri/i, required: true },
  ],
  sulga_test_25_kaannytys_lang: [
    { name: "HL § 26 cited", pattern: /HL\s*§\s*26|hallintolaki\s*§?\s*26/i, required: true },
    { name: "Direktiivi 2004/38 Art 30", pattern: /(Direktiivi|directive)\s*2004\/38.*30/i, required: true },
    { name: "ECHR 6.3", pattern: /(ECHR|EIS|euroopan ihmisoikeussopimus)\s*6\.?3/i, required: true },
    { name: "language_defect memory update", pattern: /language_defect[\s\S]{0,200}EN/i, required: true },
    { name: "no full RU translation of päätös", pattern: /Käännös venäjäksi:[\s\S]{200,}|Перевод на русский:[\s\S]{200,}/i, required: false },
  ],
  sulga_test_26_identity_stack: [
    { name: "pattern flag emitted", pattern: /pattern_of_administrative_incompetence[\s\S]{0,80}true/i, required: true },
    { name: "all 3 error types listed", pattern: /Neuvostoliitto[\s\S]*allekirjoitus|Neuvostoliitto[\s\S]*signature/i, required: true },
    { name: "Dimitri error referenced", pattern: /Dimitri/i, required: true },
    { name: "UlkL § 196 erityisen painava syy", pattern: /(UlkL|Ulkomaalaislaki)\s*§?\s*196[\s\S]{0,400}erityisen painava syy|erityisen painava syy[\s\S]{0,400}(UlkL|Ulkomaalaislaki)\s*§?\s*196/i, required: true },
    { name: "Õiguskansler or EU Ombudsman track", pattern: /Õiguskansler|oikeuskansler|EU\s*Ombudsman|Euroopan\s*oikeusasiamies/i, required: true },
  ],
  sulga_test_27_poytakirja_parsed: [
    { name: "35a Engvist admission captured", pattern: /counterparty_admission_engvist|kaadettua maahan/i, required: true },
    { name: "35b ETL 4:1 asymmetric medical", pattern: /(ETL\s*4[:.]?1|etl_4_1)[\s\S]{0,400}(asymmetric|epätasapaino|asymmetri)/i, required: true },
    { name: "35c pending obligation expired", pattern: /pending_obligation[\s\S]{0,400}2026-01-13|2026-01-13[\s\S]{0,200}(expired|umpeutunut|ei toimitettu)/i, required: true },
    { name: "35d Soinila kuulustelu gap", pattern: /KUULUSTELU_MISSING.*Soinila|Soinila[\s\S]{0,200}kuulustelu[\s\S]{0,200}(puutu|missing)/i, required: true },
    { name: "35f SALASSA + ETL 4:15", pattern: /SALASSA[\s\S]{0,400}ETL\s*4[:.]?15|ETL\s*4[:.]?15[\s\S]{0,400}(SALASSA|asianosaisjulkisuus)/i, required: true },
  ],
};

// ─── fixture loading ───────────────────────────────────────────────────────

async function listFixtures(): Promise<string[]> {
  const out: string[] = [];
  for await (const e of walk(FIXTURES_DIR, { exts: [".json"] })) {
    if (e.isFile) out.push(e.name.replace(/\.json$/, ""));
  }
  return out.sort();
}

async function loadFixture(name: string): Promise<Fixture> {
  const txt = await Deno.readTextFile(`${FIXTURES_DIR}/${name}.json`);
  return JSON.parse(txt) as Fixture;
}

// ─── edge-fn invocation ────────────────────────────────────────────────────
//
// PROBLEM: The email-triage edge fn (supabase/functions/email-triage/index.ts)
// expects { thread_id } and pulls the thread row from Supabase DB. There is
// no synchronous "evaluate this raw thread payload" entry point.
//
// TWO STRATEGIES (owner picks one):
//
//   (A) STAGING-DB-INSERT: insert fixture as a row into
//       email_inbox_threads on staging using SERVICE_ROLE_KEY, then call
//       edge fn with that thread_id. Cleanup row after. Works against real
//       deployed prompt selector. RECOMMENDED for a real eval pass.
//
//   (B) PURE-LOGIC-CALL: import triage_logic.runTriage() from edge fn
//       source and pass MinimalTriageDeps stubs. Works locally without
//       Supabase. Does NOT exercise prompt-version selector deployed in
//       env. Faster but less faithful.
//
// This scaffold STUBS strategy (A). Owner: implement properly post-deploy.

async function callEmailTriage(
  fixture: Fixture,
): Promise<{ status: number; body: string; latency_ms: number }> {
  const t0 = performance.now();

  // TODO(staging-insert): see strategy (A) above.
  //   1. Use SUPABASE_SERVICE_ROLE_KEY to INSERT INTO email_inbox_threads
  //      (id, user_id, gmail_thread_id, last_message_at, raw_messages_jsonb,
  //       status='pending').
  //   2. POST to ${SUPABASE_URL}/functions/v1/email-triage
  //      with bearer (anon or service role per setup), body { thread_id }.
  //      EMAIL_AGENT_PROMPT_VERSION must already be set in Supabase secrets.
  //   3. Wait for response (synchronous in current impl).
  //   4. Read back triage row from email_triage_results by thread_id.
  //   5. DELETE FROM email_inbox_threads WHERE id = $thread_id.
  //
  // For now: return stub so the scaffold runs end-to-end without a staging DB.

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.warn(`[stub] ${fixture._test_id}: SUPABASE_URL or SUPABASE_ANON_KEY missing — returning empty stub`);
  }

  const body = JSON.stringify({
    _stub: true,
    _fixture_id: fixture._test_id,
    _note:
      "TODO(owner): implement staging-DB-insert + email-triage call. See runner.ts strategy (A).",
    blocks: {
      triage: "",
      draft: "",
      send_recommendation: "hold_for_user_review",
      memory_update: "",
      user_brief: "",
      appeal_route: "",
      actions_required: "",
    },
  });

  const latency_ms = Math.round(performance.now() - t0);
  return { status: 200, body, latency_ms };
}

// ─── block extraction ──────────────────────────────────────────────────────
//
// Output contract per email_agent_prompt v1.1/v1.2: text blocks delimited by
// XML-style tags <triage>...</triage>, <draft>...</draft>, etc.
// parse_blocks.ts in supabase/functions/email-triage/ does this canonically;
// we re-implement simply here for the eval.

function extractBlocks(raw: string): Record<string, string> {
  // If raw is JSON envelope from stub, also flatten its blocks key.
  let outerBody = raw;
  try {
    const j = JSON.parse(raw);
    if (typeof j === "object" && j && j.blocks) {
      return j.blocks as Record<string, string>;
    }
    if (typeof j === "object" && j && typeof j.text === "string") {
      outerBody = j.text;
    }
  } catch {
    // not JSON — treat as raw text
  }

  const blocks: Record<string, string> = {};
  const tagRe = /<(triage|draft|send_recommendation|memory_update|user_brief|appeal_route|actions_required|privilege_check|conflict_check)>([\s\S]*?)<\/\1>/g;
  let m: RegExpExecArray | null;
  while ((m = tagRe.exec(outerBody)) !== null) {
    blocks[m[1]] = m[2].trim();
  }
  return blocks;
}

// ─── expectation diffing ───────────────────────────────────────────────────

function diffExpected(
  fixture: string,
  blocks: Record<string, string>,
): Array<{ check: string; pass: boolean; required: boolean }> {
  const checks = EXPECTATIONS[fixture] ?? [];
  const allText = Object.values(blocks).join("\n\n");

  return checks.map((c) => ({
    check: c.name,
    required: c.required,
    pass: c.pattern.test(allText),
  }));
}

// TODO(semantic): The current diff is regex-only. A more faithful comparator
// would call a Sonnet judge with expected.md + candidate output and ask
// "which PASS criteria from this rubric are met?" — see workspace-level
// scripts/eval/run-eval.ts for a judge-with-swap pattern. Wire that as
// optional --semantic flag.

// ─── main ──────────────────────────────────────────────────────────────────

async function runOne(name: string, version: string): Promise<RunResult> {
  const fixture = await loadFixture(name);
  const ts = new Date().toISOString();

  try {
    const r = await callEmailTriage(fixture);
    const blocks = extractBlocks(r.body);
    const expected_met = diffExpected(name, blocks);

    const requiredFails = expected_met.filter((e) => e.required && !e.pass).length;
    const pass = requiredFails === 0 && Object.keys(blocks).length > 0;

    return {
      fixture: name,
      prompt_version: version,
      ts,
      latency_ms: r.latency_ms,
      edge_fn_status: r.status,
      blocks,
      expected_met,
      pass,
    };
  } catch (e) {
    return {
      fixture: name,
      prompt_version: version,
      ts,
      latency_ms: 0,
      edge_fn_status: null,
      blocks: {},
      expected_met: [],
      pass: false,
      error: (e as Error).message,
    };
  }
}

async function main() {
  const args = parseArgs(Deno.args, {
    string: ["prompt-version", "fixture"],
    default: { fixture: "all" },
  });

  const version = (args["prompt-version"] as string | undefined) ??
    PROMPT_VERSION ?? "v1.2.1-final";

  const fixtures = args.fixture === "all"
    ? await listFixtures()
    : [args.fixture as string];

  await Deno.mkdir(RESULTS_DIR, { recursive: true });

  const results: RunResult[] = [];
  for (const name of fixtures) {
    const r = await runOne(name, version);
    results.push(r);

    const file = `${RESULTS_DIR}/${name}.${version}.json`;
    await Deno.writeTextFile(file, JSON.stringify(r, null, 2));

    const requiredFails = r.expected_met.filter((e) => e.required && !e.pass);
    const tag = r.pass ? "PASS" : (r.error ? "ERROR" : "FAIL");
    console.log(
      `${tag} ${name} (${version}) — ${r.expected_met.filter((e) => e.pass).length}/${r.expected_met.length} checks` +
        (requiredFails.length > 0
          ? ` — missing: ${requiredFails.map((f) => f.check).join("; ")}`
          : ""),
    );
  }

  const failed = results.filter((r) => !r.pass).length;
  console.log(`\nSummary: ${results.length - failed}/${results.length} fixtures pass for ${version}`);

  // Stub run never "passes" because callEmailTriage returns no real blocks.
  // Owner: once strategy (A) wired, this exit code becomes meaningful.
  Deno.exit(failed > 0 ? 1 : 0);
}

if (import.meta.main) {
  main().catch((e) => {
    console.error(e);
    Deno.exit(1);
  });
}
