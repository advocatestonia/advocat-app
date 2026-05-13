#!/usr/bin/env -S deno run -A
// Advocat.ee chat-quality eval — runner.
//
// Loads questions/*.json, calls advocat.ee chat (claude-proxy) for each,
// grades the response via grader.ts (Claude Sonnet 4.6 judge), writes
// results/<date>-<model>.json, and prints a summary.
//
// USAGE
//   # Full run vs default Haiku candidate:
//   deno run --allow-all test/eval/runner.ts --model=haiku
//
//   # Sonnet run, then diff against latest haiku run:
//   deno run --allow-all test/eval/runner.ts --model=sonnet
//   deno run --allow-all test/eval/runner.ts --compare results/2026-05-13-haiku.json results/2026-05-13-sonnet.json
//
//   # Single category:
//   deno run --allow-all test/eval/runner.ts --model=sonnet --category=employment
//
//   # Single question:
//   deno run --allow-all test/eval/runner.ts --question=emp-001
//
//   # Dry run — load questions, validate schemas, print plan, no API calls:
//   deno run --allow-all test/eval/runner.ts --dry-run
//
// ENV
//   ANTHROPIC_API_KEY            required (for judge)
//   SUPABASE_ANON_KEY            recommended (candidate calls; demo-tier cap)
//   SUPABASE_SERVICE_ROLE_KEY    optional   (full token budget; bypass demo cap)
//   ADVOCAT_SUPABASE_URL         default https://okgnkucgwsytsondrjye.supabase.co
//   ADVOCAT_CANDIDATE_MODEL      default per --model flag, overrides everything
//
// COST PER FULL RUN (30 questions, build a745faa, May 2026 list prices)
//   * Candidate calls — depend on model:
//       Haiku  ≈ 30 × $0.005 = $0.15
//       Sonnet ≈ 30 × $0.030 = $0.90
//   * Judge — Sonnet 4.6 ≈ 30 × $0.016 = $0.50
//   * TOTAL: Haiku  ≈ $0.65, Sonnet ≈ $1.40 per full eval run.
// (Owner-facing README quotes a conservative $5 per 100-question full run.)

import { parseArgs } from "jsr:@std/cli/parse-args";
import { walk } from "jsr:@std/fs/walk";
import { gradeAnswer, wordCount } from "./grader.ts";
import type {
  Category,
  Difficulty,
  Question,
  RunRow,
  RunSummary,
} from "./types.ts";

// ─── config ────────────────────────────────────────────────────────────────

const ADVOCAT_SUPABASE_URL = Deno.env.get("ADVOCAT_SUPABASE_URL") ??
  "https://okgnkucgwsytsondrjye.supabase.co";
const CLAUDE_PROXY_URL = `${ADVOCAT_SUPABASE_URL}/functions/v1/claude-proxy`;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const ADVOCAT_BEARER = SUPABASE_SERVICE_ROLE_KEY || SUPABASE_ANON_KEY;

const HERE = new URL(".", import.meta.url).pathname;
const QUESTIONS_DIR = `${HERE}questions`;
const RESULTS_DIR = `${HERE}results`;

const MODEL_ALIASES: Record<string, string> = {
  haiku: "claude-haiku-4-5",
  "haiku-4-5": "claude-haiku-4-5",
  sonnet: "claude-sonnet-4-20250514",
  "sonnet-4": "claude-sonnet-4-20250514",
  "sonnet-4-6": "claude-sonnet-4-6",
};

function resolveModel(flag: string | undefined): string {
  const override = Deno.env.get("ADVOCAT_CANDIDATE_MODEL");
  if (override) return override;
  if (!flag) return MODEL_ALIASES.haiku;
  return MODEL_ALIASES[flag] ?? flag;
}

// ─── question loading + validation ─────────────────────────────────────────

async function loadAllQuestions(): Promise<Question[]> {
  const all: Question[] = [];
  for await (const e of walk(QUESTIONS_DIR, { exts: [".json"] })) {
    if (!e.isFile) continue;
    const txt = await Deno.readTextFile(e.path);
    const arr = JSON.parse(txt) as Question[];
    if (!Array.isArray(arr)) {
      throw new Error(`Expected array in ${e.path}, got ${typeof arr}`);
    }
    for (const q of arr) validateQuestion(q, e.path);
    all.push(...arr);
  }
  // Deterministic order: by id.
  return all.sort((a, b) => a.id.localeCompare(b.id));
}

function validateQuestion(q: Question, source: string): void {
  if (!q.id) throw new Error(`Missing id in ${source}`);
  if (!q.category) throw new Error(`Missing category for ${q.id}`);
  if (!q.question) throw new Error(`Missing question text for ${q.id}`);
  if (!q.expected) throw new Error(`Missing expected for ${q.id}`);
  const e = q.expected;
  if (!Array.isArray(e.must_mention_laws)) {
    throw new Error(`must_mention_laws not array: ${q.id}`);
  }
  if (!Array.isArray(e.must_include)) {
    throw new Error(`must_include not array: ${q.id}`);
  }
  if (!Array.isArray(e.must_not_include)) {
    throw new Error(`must_not_include not array: ${q.id}`);
  }
  if (typeof e.min_word_count !== "number" || e.min_word_count < 0) {
    throw new Error(`bad min_word_count: ${q.id}`);
  }
  if (typeof e.max_word_count !== "number" || e.max_word_count <= 0) {
    throw new Error(`bad max_word_count: ${q.id}`);
  }
  if (e.min_word_count >= e.max_word_count) {
    throw new Error(`min >= max word count: ${q.id}`);
  }
}

// ─── candidate (advocat.ee chat) ───────────────────────────────────────────

interface CandidateResponse {
  text: string;
  latency_ms: number;
}

async function callCandidate(
  q: Question,
  model: string,
): Promise<CandidateResponse> {
  const t0 = performance.now();

  if (!ADVOCAT_BEARER) {
    throw new Error(
      "callCandidate: SUPABASE_ANON_KEY or SUPABASE_SERVICE_ROLE_KEY required",
    );
  }

  const reqBody = {
    messages: [{ role: "user", content: q.question }],
    model,
    stream: false,
  };

  const resp = await fetch(CLAUDE_PROXY_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "authorization": `Bearer ${ADVOCAT_BEARER}`,
    },
    body: JSON.stringify(reqBody),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(
      `claude-proxy ${resp.status} for q=${q.id}: ${errText.slice(0, 400)}`,
    );
  }

  const json = await resp.json() as {
    content?: Array<{ type: string; text?: string }>;
    text?: string;
    error?: unknown;
  };

  let text = "";
  if (Array.isArray(json.content)) {
    text = json.content
      .filter((b) => b.type === "text")
      .map((b) => b.text ?? "")
      .join("\n")
      .trim();
  } else if (typeof json.text === "string") {
    text = json.text;
  } else {
    text = JSON.stringify(json);
  }

  return { text, latency_ms: Math.round(performance.now() - t0) };
}

// ─── per-question pipeline ─────────────────────────────────────────────────

async function runOne(q: Question, model: string): Promise<RunRow> {
  const ts = new Date().toISOString();
  try {
    const cand = await callCandidate(q, model);
    const grader = await gradeAnswer(q, cand.text, {
      anthropicApiKey: ANTHROPIC_API_KEY,
    });
    return {
      question_id: q.id,
      category: q.category,
      difficulty: q.difficulty,
      language: q.language,
      question: q.question,
      candidate_answer: cand.text,
      candidate_latency_ms: cand.latency_ms,
      candidate_model: model,
      grader,
      ts,
    };
  } catch (e) {
    return {
      question_id: q.id,
      category: q.category,
      difficulty: q.difficulty,
      language: q.language,
      question: q.question,
      candidate_answer: "",
      candidate_latency_ms: 0,
      candidate_model: model,
      grader: {
        score: 0,
        pass: false,
        criteria: [],
        word_count: 0,
      },
      ts,
      error: (e as Error).message,
    };
  }
}

// ─── summary aggregation ───────────────────────────────────────────────────

function summarise(rows: RunRow[], model: string, runId: string): RunSummary {
  const passed = rows.filter((r) => !r.error && r.grader.pass).length;
  const errored = rows.filter((r) => !!r.error).length;
  const failed = rows.length - passed - errored;
  const nonErrored = rows.filter((r) => !r.error);
  const meanScore = nonErrored.length === 0
    ? 0
    : nonErrored.reduce((s, r) => s + r.grader.score, 0) / nonErrored.length;

  const cats: Category[] = [
    "employment",
    "housing",
    "family",
    "deportation",
    "consumer",
    "contract",
  ];
  const per_category = {} as RunSummary["per_category"];
  for (const c of cats) {
    const ofCat = rows.filter((r) => r.category === c);
    const ofCatScored = ofCat.filter((r) => !r.error);
    per_category[c] = {
      total: ofCat.length,
      passed: ofCat.filter((r) => !r.error && r.grader.pass).length,
      mean_score: ofCatScored.length === 0
        ? 0
        : ofCatScored.reduce((s, r) => s + r.grader.score, 0) /
          ofCatScored.length,
    };
  }

  const diffs: Difficulty[] = ["easy", "medium", "hard"];
  const per_difficulty = {} as RunSummary["per_difficulty"];
  for (const d of diffs) {
    const ofDiff = rows.filter((r) => r.difficulty === d);
    const ofDiffScored = ofDiff.filter((r) => !r.error);
    per_difficulty[d] = {
      total: ofDiff.length,
      passed: ofDiff.filter((r) => !r.error && r.grader.pass).length,
      mean_score: ofDiffScored.length === 0
        ? 0
        : ofDiffScored.reduce((s, r) => s + r.grader.score, 0) /
          ofDiffScored.length,
    };
  }

  return {
    run_id: runId,
    ts: new Date().toISOString(),
    model,
    api_endpoint: CLAUDE_PROXY_URL,
    total_questions: rows.length,
    passed,
    failed,
    errored,
    pass_rate: rows.length === 0 ? 0 : passed / rows.length,
    mean_score: meanScore,
    per_category,
    per_difficulty,
    rows,
  };
}

function printSummary(s: RunSummary): void {
  console.log("\n=== Advocat.ee eval summary ===");
  console.log(`Run:   ${s.run_id}`);
  console.log(`Model: ${s.model}`);
  console.log(
    `Pass:  ${s.passed}/${s.total_questions} ` +
      `(${(s.pass_rate * 100).toFixed(1)}%)  mean=${s.mean_score.toFixed(1)}/100`,
  );
  if (s.errored > 0) console.log(`Errors: ${s.errored}`);
  console.log("\nBy category:");
  for (const [k, v] of Object.entries(s.per_category)) {
    if (v.total === 0) continue;
    console.log(
      `  ${k.padEnd(12)}  ${v.passed}/${v.total}  mean=${v.mean_score.toFixed(1)}`,
    );
  }
  console.log("\nBy difficulty:");
  for (const [k, v] of Object.entries(s.per_difficulty)) {
    if (v.total === 0) continue;
    console.log(
      `  ${k.padEnd(8)}  ${v.passed}/${v.total}  mean=${v.mean_score.toFixed(1)}`,
    );
  }
}

// ─── comparison mode ───────────────────────────────────────────────────────

async function compareTwo(pathA: string, pathB: string): Promise<void> {
  const a = JSON.parse(await Deno.readTextFile(pathA)) as RunSummary;
  const b = JSON.parse(await Deno.readTextFile(pathB)) as RunSummary;

  console.log(`\n=== Compare: ${a.model} vs ${b.model} ===`);
  console.log(
    `${a.model}: ${a.passed}/${a.total_questions} ` +
      `(${(a.pass_rate * 100).toFixed(1)}%)  mean=${a.mean_score.toFixed(1)}`,
  );
  console.log(
    `${b.model}: ${b.passed}/${b.total_questions} ` +
      `(${(b.pass_rate * 100).toFixed(1)}%)  mean=${b.mean_score.toFixed(1)}`,
  );

  const byId = new Map(a.rows.map((r) => [r.question_id, r]));
  const regressions: Array<{ id: string; a: number; b: number }> = [];
  const improvements: Array<{ id: string; a: number; b: number }> = [];

  for (const rB of b.rows) {
    const rA = byId.get(rB.question_id);
    if (!rA) continue;
    if (rB.grader.score < rA.grader.score - 5) {
      regressions.push({
        id: rB.question_id,
        a: rA.grader.score,
        b: rB.grader.score,
      });
    } else if (rB.grader.score > rA.grader.score + 5) {
      improvements.push({
        id: rB.question_id,
        a: rA.grader.score,
        b: rB.grader.score,
      });
    }
  }

  console.log(`\nRegressions (${a.model} → ${b.model}, drop >5pts):`);
  for (const r of regressions) {
    console.log(`  ${r.id}: ${r.a} → ${r.b}`);
  }
  console.log(`\nImprovements (${a.model} → ${b.model}, gain >5pts):`);
  for (const r of improvements) {
    console.log(`  ${r.id}: ${r.a} → ${r.b}`);
  }
}

// ─── main ──────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = parseArgs(Deno.args, {
    string: ["model", "category", "question", "compare"],
    boolean: ["dry-run", "help"],
    alias: { h: "help" },
  });

  if (args.help) {
    console.log(`Advocat.ee eval runner

  --model=<haiku|sonnet|sonnet-4-6>    candidate model (default: haiku)
  --category=<cat>                      run only one category
  --question=<id>                       run only one question (e.g. emp-001)
  --dry-run                             load + validate questions, no API calls
  --compare <fileA> <fileB>             diff two result files

Env:
  ANTHROPIC_API_KEY (required for judge)
  SUPABASE_ANON_KEY or SUPABASE_SERVICE_ROLE_KEY (required for candidate)`);
    Deno.exit(0);
  }

  if (args.compare) {
    // --compare requires two positionals after the flag.
    const positional = (args._ ?? []) as string[];
    const a = args.compare;
    const b = positional[0];
    if (!a || !b) {
      console.error("Usage: --compare <fileA> <fileB>");
      Deno.exit(2);
    }
    await compareTwo(a, b);
    return;
  }

  const allQuestions = await loadAllQuestions();
  let selected = allQuestions;
  if (args.category) {
    selected = selected.filter((q) => q.category === args.category);
  }
  if (args.question) {
    selected = selected.filter((q) => q.id === args.question);
  }
  if (selected.length === 0) {
    console.error("No questions selected");
    Deno.exit(2);
  }

  const model = resolveModel(args.model);

  console.log(
    `Loaded ${allQuestions.length} questions; running ${selected.length} ` +
      `against model="${model}"`,
  );
  if (args["dry-run"]) {
    console.log("Dry-run — exiting without API calls.");
    for (const q of selected) {
      console.log(`  ${q.id}  [${q.category}/${q.difficulty}]  ${q.question.slice(0, 80)}`);
    }
    return;
  }

  if (!ANTHROPIC_API_KEY) {
    console.error("ANTHROPIC_API_KEY required for judge");
    Deno.exit(2);
  }
  if (!ADVOCAT_BEARER) {
    console.error(
      "SUPABASE_ANON_KEY or SUPABASE_SERVICE_ROLE_KEY required for candidate",
    );
    Deno.exit(2);
  }

  await Deno.mkdir(RESULTS_DIR, { recursive: true });

  const runId = `${new Date().toISOString().slice(0, 10)}-${args.model ?? "haiku"}`;
  const rows: RunRow[] = [];
  for (const q of selected) {
    const row = await runOne(q, model);
    rows.push(row);
    const tag = row.error ? "ERROR" : (row.grader.pass ? "PASS " : "FAIL ");
    const score = row.error ? "  -" : row.grader.score.toFixed(0).padStart(3);
    const wc = row.error ? "  -" : `${wordCount(row.candidate_answer)}w`;
    console.log(
      `${tag} ${row.question_id}  ${score}/100  ${wc.padStart(5)}  ` +
        (row.error ? row.error : ""),
    );
  }

  const summary = summarise(rows, model, runId);
  const outPath = `${RESULTS_DIR}/${runId}.json`;
  await Deno.writeTextFile(outPath, JSON.stringify(summary, null, 2));
  console.log(`\nWrote ${outPath}`);

  printSummary(summary);

  Deno.exit(summary.failed + summary.errored > 0 ? 1 : 0);
}

if (import.meta.main) {
  main().catch((e) => {
    console.error(e);
    Deno.exit(1);
  });
}
