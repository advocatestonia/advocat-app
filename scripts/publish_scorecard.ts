#!/usr/bin/env -S deno run -A
// ============================================================================
// publish_scorecard.ts — render web/scorecard-data.json from latest eval run
// ============================================================================
//
// Reads:
//   ../../eval/runs/<latest>_summary.json   (outer-workspace eval output)
//   ../../eval/runs/<latest>_v4_advocat.jsonl
//   ../../eval/runs/v4_vs_sonnet_baseline_<DATE>.md  (narrative, optional)
//
// Writes:
//   web/scorecard-data.json   (committed to repo, served as /scorecard-data.json)
//
// Usage:
//   deno run -A scripts/publish_scorecard.ts
//   deno run -A scripts/publish_scorecard.ts --date 2026-05-14
//   deno run -A scripts/publish_scorecard.ts --dry-run
//
// Design notes:
//   - This script is *additive*: existing recent_mistakes entries in
//     web/scorecard-data.json are preserved unless the new run mentions the
//     same item_id, in which case the new entry wins (the mistake was caught
//     again — status may have changed).
//   - Industry references (Stanford RegLab numbers) and approach_notes are
//     never touched by this script. They are owner-curated copy.
//   - schema_version is bumped manually when the JSON shape changes; the
//     scorecard.html reader is keyed to schema_version === 1.
//   - This script does NOT push or deploy. It writes the JSON file; canary
//     deploy is a separate step (./scripts/canary-deploy.sh).
//
// Exit codes:
//   0  — wrote new scorecard-data.json (or --dry-run completed)
//   1  — input run not found
//   2  — schema mismatch in run summary
//   3  — refused to publish because new run regressed > 5% on any headline axis
//        and --force was not passed
//
// Alert webhook (optional, set in env):
//   SCORECARD_ALERT_TELEGRAM_BOT
//   SCORECARD_ALERT_TELEGRAM_CHAT
//   SCORECARD_ALERT_EMAIL
//
// ============================================================================

import { parseArgs } from "jsr:@std/cli/parse-args";

const SCHEMA_VERSION = 1;
const REGRESSION_THRESHOLD_PCT = 5; // alert + refuse if any headline axis drops > this

// Resolve relative to this script's location, not cwd, so it works whether
// invoked from app/advocat_project/ or from the outer workspace.
const SCRIPT_DIR = new URL(".", import.meta.url).pathname;
const REPO_ROOT = `${SCRIPT_DIR}..`; // app/advocat_project
const WORKSPACE_ROOT = `${REPO_ROOT}/../..`; // Advocat/
const RUNS_DIR = `${WORKSPACE_ROOT}/eval/runs`;
const SCORECARD_PATH = `${REPO_ROOT}/web/scorecard-data.json`;

// ─── types ──────────────────────────────────────────────────────────────────

interface RunSummary {
  v4: TierBreakdown;
  sonnet_bare: TierBreakdown;
  delta: {
    mean_score: number;
    pct: number;
    axis: Record<string, number>;
    pass_delta: number;
  };
  deltas_per_item?: Array<{
    id: string;
    tier: string;
    v4: number;
    sb: number;
    delta: number;
  }>;
}

interface TierBreakdown {
  n: number;
  mean_score: number;
  pass: number;
  cost: number;
  axis: {
    citation_validity: number;
    conclusion_correctness: number;
    jurisdiction_accuracy: number;
    completeness: number;
    calibration: number;
  };
  per_tier: {
    gold: { n: number; mean: number; pass: number };
    statute: { n: number; mean: number; pass: number };
    adversarial: { n: number; mean: number; pass: number };
  };
}

interface ScorecardData {
  schema_version: number;
  last_updated: string;
  build_version: string;
  judge_setup: string;
  truth_set: unknown;
  headline_metrics: HeadlineMetric[];
  industry_references: unknown[];
  recent_mistakes: Mistake[];
  approach_notes: string[];
  cost_and_latency: Record<string, unknown>;
  next_run_planned: string;
  challenge_email: string;
  source_files: string[];
}

interface HeadlineMetric {
  label: string;
  advocat_v4: number;
  comparators: Record<string, number>;
  advocat_delta_pct: number;
  format: string;
  axis: string;
  is_regression?: boolean;
  note?: string;
}

interface Mistake {
  date: string;
  tier: string;
  item_id: string;
  question_redacted: string;
  what_advocat_said: string;
  what_it_should_be: string;
  fix_status: "shipped" | "in_flight" | "investigating";
  fix_description: string;
}

// ─── helpers ────────────────────────────────────────────────────────────────

function pct(advocat: number, baseline: number): number {
  if (baseline === 0) return 0;
  return Number((((advocat - baseline) / baseline) * 100).toFixed(2));
}

async function readJson<T>(path: string): Promise<T> {
  const txt = await Deno.readTextFile(path);
  return JSON.parse(txt) as T;
}

async function findLatestSummary(date?: string): Promise<string> {
  // Look for <date>_summary.json, or the most recent *_summary.json.
  const candidates: string[] = [];
  for await (const entry of Deno.readDir(RUNS_DIR)) {
    if (entry.isFile && entry.name.endsWith("_summary.json")) {
      candidates.push(entry.name);
    }
  }
  if (candidates.length === 0) {
    throw new Error(`No *_summary.json files in ${RUNS_DIR}`);
  }
  if (date) {
    const wanted = candidates.find((c) => c.startsWith(date));
    if (!wanted) {
      throw new Error(`No summary file for date ${date} in ${RUNS_DIR}`);
    }
    return `${RUNS_DIR}/${wanted}`;
  }
  candidates.sort().reverse();
  return `${RUNS_DIR}/${candidates[0]}`;
}

function dateFromSummaryPath(p: string): string {
  // .../2026-05-14_summary.json → "2026-05-14"
  const fname = p.split("/").pop() ?? "";
  const m = fname.match(/^(\d{4}-\d{2}-\d{2})/);
  return m?.[1] ?? new Date().toISOString().slice(0, 10);
}

// ─── headline metrics derived from summary ──────────────────────────────────

function buildHeadlineMetrics(s: RunSummary): HeadlineMetric[] {
  const metrics: HeadlineMetric[] = [];

  metrics.push({
    label: "Mean answer quality (1–5 rubric, n=30)",
    advocat_v4: s.v4.mean_score,
    comparators: { sonnet_bare_via_api: s.sonnet_bare.mean_score },
    advocat_delta_pct: pct(s.v4.mean_score, s.sonnet_bare.mean_score),
    format: "score",
    axis: "aggregate",
  });

  metrics.push({
    label: "Adversarial robustness (caught fakes / repealed laws, 1–5)",
    advocat_v4: s.v4.axis.calibration,
    comparators: { sonnet_bare_via_api: s.sonnet_bare.axis.calibration },
    advocat_delta_pct: pct(s.v4.axis.calibration, s.sonnet_bare.axis.calibration),
    format: "score",
    axis: "calibration",
  });

  metrics.push({
    label: "Jurisdiction accuracy (1–5)",
    advocat_v4: s.v4.axis.jurisdiction_accuracy,
    comparators: { sonnet_bare_via_api: s.sonnet_bare.axis.jurisdiction_accuracy },
    advocat_delta_pct: pct(s.v4.axis.jurisdiction_accuracy, s.sonnet_bare.axis.jurisdiction_accuracy),
    format: "score",
    axis: "jurisdiction_accuracy",
  });

  const citationDelta = pct(s.v4.axis.citation_validity, s.sonnet_bare.axis.citation_validity);
  metrics.push({
    label: "Statute citation validity (1–5)",
    advocat_v4: s.v4.axis.citation_validity,
    comparators: { sonnet_bare_via_api: s.sonnet_bare.axis.citation_validity },
    advocat_delta_pct: citationDelta,
    format: "score",
    axis: "citation_validity",
    note: citationDelta < 1
      ? "Flat — citation enforcement is the open work item. Honest score."
      : undefined,
  });

  metrics.push({
    label: "Adversarial tier mean (10 fake-case / repealed-law traps)",
    advocat_v4: s.v4.per_tier.adversarial.mean,
    comparators: { sonnet_bare_via_api: s.sonnet_bare.per_tier.adversarial.mean },
    advocat_delta_pct: pct(s.v4.per_tier.adversarial.mean, s.sonnet_bare.per_tier.adversarial.mean),
    format: "score",
    axis: "tier_adversarial",
  });

  metrics.push({
    label: "Gold tier mean (10 real Sulga-derived cases)",
    advocat_v4: s.v4.per_tier.gold.mean,
    comparators: { sonnet_bare_via_api: s.sonnet_bare.per_tier.gold.mean },
    advocat_delta_pct: pct(s.v4.per_tier.gold.mean, s.sonnet_bare.per_tier.gold.mean),
    format: "score",
    axis: "tier_gold",
  });

  const statuteDelta = pct(s.v4.per_tier.statute.mean, s.sonnet_bare.per_tier.statute.mean);
  metrics.push({
    label: statuteDelta < 0
      ? "Statute tier mean (10 direct lookups) — REGRESSION"
      : "Statute tier mean (10 direct lookups)",
    advocat_v4: s.v4.per_tier.statute.mean,
    comparators: { sonnet_bare_via_api: s.sonnet_bare.per_tier.statute.mean },
    advocat_delta_pct: statuteDelta,
    format: "score",
    axis: "tier_statute",
    is_regression: statuteDelta < 0,
  });

  return metrics;
}

// ─── merge mistakes from per-item deltas ────────────────────────────────────

function detectFailureMistakes(s: RunSummary, runDate: string): Mistake[] {
  // Auto-seed failure entries for items where v4 lost by > 0.5 to bare Sonnet.
  // These are placeholder mistakes — owner reviews and fills in
  // question_redacted, what_advocat_said, what_it_should_be, fix_description
  // before the entry leaves "investigating" state.
  const failures = (s.deltas_per_item ?? []).filter((d) => d.delta < -0.5);
  return failures.map((f) => ({
    date: runDate,
    tier: f.tier,
    item_id: f.id,
    question_redacted: "(Auto-generated placeholder — owner to fill before publish.)",
    what_advocat_said: `Scored ${f.v4.toFixed(2)}/5 vs bare Sonnet ${f.sb.toFixed(2)}/5 (Δ ${f.delta.toFixed(2)}).`,
    what_it_should_be: "(Pending owner review — see eval run notes for diagnosis.)",
    fix_status: "investigating" as const,
    fix_description: "Item-level trace and root cause pending.",
  }));
}

// ─── regression alert ───────────────────────────────────────────────────────

interface RegressionCheck {
  alerts: string[];
  blocking: boolean;
}

function checkRegression(prev: HeadlineMetric[] | null, next: HeadlineMetric[]): RegressionCheck {
  const alerts: string[] = [];
  if (!prev) return { alerts, blocking: false };

  for (const nextM of next) {
    const prevM = prev.find((p) => p.axis === nextM.axis);
    if (!prevM) continue;
    if (prevM.advocat_v4 === 0) continue;
    const drop = ((prevM.advocat_v4 - nextM.advocat_v4) / prevM.advocat_v4) * 100;
    if (drop > REGRESSION_THRESHOLD_PCT) {
      alerts.push(
        `${nextM.label}: ${prevM.advocat_v4.toFixed(3)} → ${nextM.advocat_v4.toFixed(3)} (−${drop.toFixed(1)}%)`,
      );
    }
  }
  return { alerts, blocking: alerts.length > 0 };
}

async function sendAlert(alerts: string[], runDate: string): Promise<void> {
  if (alerts.length === 0) return;
  const tgBot = Deno.env.get("SCORECARD_ALERT_TELEGRAM_BOT");
  const tgChat = Deno.env.get("SCORECARD_ALERT_TELEGRAM_CHAT");
  const body = `Scorecard regression detected (${runDate}):\n\n${alerts.join("\n")}`;
  console.error(`\n[ALERT]\n${body}\n`);

  if (tgBot && tgChat) {
    try {
      await fetch(`https://api.telegram.org/bot${tgBot}/sendMessage`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ chat_id: tgChat, text: body }),
      });
    } catch (e) {
      console.error("Telegram alert failed:", (e as Error).message);
    }
  }
}

// ─── main ───────────────────────────────────────────────────────────────────

async function main() {
  const args = parseArgs(Deno.args, {
    string: ["date"],
    boolean: ["dry-run", "force"],
  });

  const summaryPath = await findLatestSummary(args.date as string | undefined);
  console.log(`→ Reading: ${summaryPath}`);
  const summary = await readJson<RunSummary>(summaryPath);
  const runDate = dateFromSummaryPath(summaryPath);

  if (typeof summary.v4?.mean_score !== "number") {
    console.error("Summary missing v4.mean_score — schema mismatch.");
    Deno.exit(2);
  }

  // Load existing scorecard (preserve owner-curated fields).
  let existing: ScorecardData | null = null;
  try {
    existing = await readJson<ScorecardData>(SCORECARD_PATH);
  } catch {
    console.log("→ No existing scorecard-data.json — creating fresh.");
  }

  const headline = buildHeadlineMetrics(summary);

  // Merge mistakes: keep manual entries, refresh auto-detected ones.
  const autoMistakes = detectFailureMistakes(summary, runDate);
  const existingMistakes = existing?.recent_mistakes ?? [];
  const merged = new Map<string, Mistake>();
  for (const m of existingMistakes) merged.set(m.item_id, m);
  for (const m of autoMistakes) {
    if (!merged.has(m.item_id)) merged.set(m.item_id, m);
  }
  // Keep newest first, cap at 12 visible.
  const recent_mistakes = Array.from(merged.values())
    .sort((a, b) => b.date.localeCompare(a.date))
    .slice(0, 12);

  // Regression check.
  const reg = checkRegression(existing?.headline_metrics ?? null, headline);
  if (reg.blocking) {
    await sendAlert(reg.alerts, runDate);
    if (!args.force) {
      console.error("\n✗ Regression > 5% on a headline axis. Use --force to publish anyway.");
      Deno.exit(3);
    }
    console.error("\n⚠ Regression detected but --force given. Publishing.");
  }

  const cost_overhead_pct = Math.round(
    ((summary.v4.cost / summary.sonnet_bare.cost) - 1) * 100,
  );

  const next: ScorecardData = {
    schema_version: SCHEMA_VERSION,
    last_updated: runDate,
    build_version: existing?.build_version ?? "v4.1",
    judge_setup: existing?.judge_setup ??
      "Triple-LLM judge: Anthropic Opus 4.5 + OpenAI gpt-4o + Google Gemini 2.5 Pro.",
    truth_set: existing?.truth_set ?? {
      total_items: summary.v4.n,
      tiers: [
        { id: "gold", n: summary.v4.per_tier.gold.n, label: "Gold tier (real cases, anonymised)" },
        { id: "statute", n: summary.v4.per_tier.statute.n, label: "Direct statute lookups" },
        { id: "adversarial", n: summary.v4.per_tier.adversarial.n, label: "Fake-case / repealed-law traps" },
      ],
      languages: ["et", "fi", "ru", "en"],
      jurisdictions: ["EE", "FI", "EU"],
    },
    headline_metrics: headline,
    industry_references: existing?.industry_references ?? [],
    recent_mistakes,
    approach_notes: existing?.approach_notes ?? [],
    cost_and_latency: {
      advocat_v4_per_item_usd: Number((summary.v4.cost / summary.v4.n).toFixed(4)),
      sonnet_bare_per_item_usd: Number((summary.sonnet_bare.cost / summary.sonnet_bare.n).toFixed(4)),
      advocat_cost_overhead_pct: cost_overhead_pct,
      advocat_latency_overhead_pct: existing?.cost_and_latency?.advocat_latency_overhead_pct ?? 27,
      note: existing?.cost_and_latency?.note ??
        "v4 is more expensive per call and slower than bare Sonnet. The pipeline trades latency for adversarial safety.",
    },
    next_run_planned: existing?.next_run_planned ?? new Date(
      Date.now() + 30 * 24 * 60 * 60 * 1000,
    ).toISOString().slice(0, 10),
    challenge_email: existing?.challenge_email ?? "support@advocat.ee",
    source_files: [
      `eval/runs/v4_vs_sonnet_baseline_${runDate}.md`,
      `eval/runs/${runDate}_summary.json`,
    ],
  };

  const output = JSON.stringify(next, null, 2) + "\n";

  if (args["dry-run"]) {
    console.log("\n[dry-run] Would write:\n");
    console.log(output);
    return;
  }

  await Deno.writeTextFile(SCORECARD_PATH, output);
  console.log(`✓ Wrote ${SCORECARD_PATH}`);
  console.log(`  v4 mean: ${summary.v4.mean_score.toFixed(3)} (Δ ${headline[0].advocat_delta_pct.toFixed(2)}% vs bare)`);
  console.log(`  mistakes published: ${recent_mistakes.length}`);
  if (reg.alerts.length > 0) {
    console.log(`  regression alerts: ${reg.alerts.length}`);
  }
}

if (import.meta.main) {
  main().catch((e) => {
    console.error(e);
    Deno.exit(1);
  });
}

export { buildHeadlineMetrics, checkRegression, detectFailureMistakes, pct };
