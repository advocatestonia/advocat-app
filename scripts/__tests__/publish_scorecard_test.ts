// Tests for publish_scorecard.ts pure helpers.
// Run: deno test --allow-read scripts/__tests__/publish_scorecard_test.ts

import { assertEquals, assertAlmostEquals } from "jsr:@std/assert";
import {
  buildHeadlineMetrics,
  checkRegression,
  detectFailureMistakes,
  pct,
} from "../publish_scorecard.ts";

const fixtureSummary = {
  v4: {
    n: 30,
    mean_score: 2.986,
    pass: 2,
    cost: 1.8775,
    axis: {
      citation_validity: 1.8,
      conclusion_correctness: 3.233,
      jurisdiction_accuracy: 3.867,
      completeness: 2.5,
      calibration: 4.467,
    },
    per_tier: {
      gold: { n: 10, mean: 3.258, pass: 1 },
      statute: { n: 10, mean: 3.142, pass: 0 },
      adversarial: { n: 10, mean: 2.558, pass: 1 },
    },
  },
  sonnet_bare: {
    n: 30,
    mean_score: 2.928,
    pass: 1,
    cost: 1.8024,
    axis: {
      citation_validity: 1.8,
      conclusion_correctness: 3.133,
      jurisdiction_accuracy: 3.733,
      completeness: 2.6,
      calibration: 4.3,
    },
    per_tier: {
      gold: { n: 10, mean: 3.185, pass: 0 },
      statute: { n: 10, mean: 3.271, pass: 0 },
      adversarial: { n: 10, mean: 2.328, pass: 1 },
    },
  },
  delta: {
    mean_score: 0.058,
    pct: 1.98,
    axis: {
      citation_validity: 0,
      conclusion_correctness: 0.1,
      jurisdiction_accuracy: 0.134,
      completeness: -0.1,
      calibration: 0.167,
    },
    pass_delta: 1,
  },
  deltas_per_item: [
    { id: "statute-010", tier: "statute", v4: 3.14, sb: 4.29, delta: -1.15 },
    { id: "adv-002", tier: "adversarial", v4: 3.43, sb: 1.71, delta: 1.72 },
    { id: "adv-001", tier: "adversarial", v4: 2.57, sb: 3.29, delta: -0.72 },
    { id: "gold-004", tier: "gold", v4: 2.86, sb: 3.43, delta: -0.57 },
  ],
};

Deno.test("pct: basic delta", () => {
  assertEquals(pct(2.986, 2.928), 1.98);
  assertEquals(pct(3.142, 3.271), -3.94);
  assertEquals(pct(1.8, 1.8), 0);
  assertEquals(pct(1, 0), 0); // divide-by-zero guard
});

Deno.test("buildHeadlineMetrics: produces 7 axes including statute regression flag", () => {
  const metrics = buildHeadlineMetrics(fixtureSummary);
  assertEquals(metrics.length, 7);

  const aggregate = metrics.find((m) => m.axis === "aggregate")!;
  assertEquals(aggregate.advocat_v4, 2.986);
  assertAlmostEquals(aggregate.advocat_delta_pct, 1.98, 0.05);

  const statute = metrics.find((m) => m.axis === "tier_statute")!;
  assertEquals(statute.is_regression, true);
  assertEquals(statute.label.includes("REGRESSION"), true);

  const citation = metrics.find((m) => m.axis === "citation_validity")!;
  assertEquals(citation.advocat_delta_pct, 0);
  assertEquals(typeof citation.note, "string"); // honest-flat note set
});

Deno.test("buildHeadlineMetrics: gold tier not flagged as regression when positive", () => {
  const metrics = buildHeadlineMetrics(fixtureSummary);
  const gold = metrics.find((m) => m.axis === "tier_gold")!;
  assertEquals(gold.is_regression, undefined);
  assertEquals(gold.advocat_delta_pct > 0, true);
});

Deno.test("detectFailureMistakes: only items with delta < -0.5", () => {
  const mistakes = detectFailureMistakes(fixtureSummary, "2026-05-14");
  // -1.15 (statute-010), -0.72 (adv-001), -0.57 (gold-004) → 3 entries
  assertEquals(mistakes.length, 3);
  assertEquals(mistakes.every((m) => m.fix_status === "investigating"), true);
  assertEquals(mistakes.every((m) => m.date === "2026-05-14"), true);

  // adv-002 is a v4 WIN (+1.72) — should not be in the failures list.
  assertEquals(mistakes.find((m) => m.item_id === "adv-002"), undefined);
});

Deno.test("checkRegression: > 5% drop on any axis triggers blocking alert", () => {
  const prev = [
    { label: "x", advocat_v4: 3.0, comparators: {}, advocat_delta_pct: 0, format: "score", axis: "test_axis" },
  ];
  const next = [
    { label: "x", advocat_v4: 2.7, comparators: {}, advocat_delta_pct: 0, format: "score", axis: "test_axis" }, // -10%
  ];
  const r = checkRegression(prev, next);
  assertEquals(r.blocking, true);
  assertEquals(r.alerts.length, 1);
});

Deno.test("checkRegression: < 5% drop is tolerated", () => {
  const prev = [
    { label: "x", advocat_v4: 3.0, comparators: {}, advocat_delta_pct: 0, format: "score", axis: "test_axis" },
  ];
  const next = [
    { label: "x", advocat_v4: 2.92, comparators: {}, advocat_delta_pct: 0, format: "score", axis: "test_axis" }, // -2.7%
  ];
  const r = checkRegression(prev, next);
  assertEquals(r.blocking, false);
  assertEquals(r.alerts.length, 0);
});

Deno.test("checkRegression: improvements never block", () => {
  const prev = [
    { label: "x", advocat_v4: 2.5, comparators: {}, advocat_delta_pct: 0, format: "score", axis: "test_axis" },
  ];
  const next = [
    { label: "x", advocat_v4: 3.5, comparators: {}, advocat_delta_pct: 0, format: "score", axis: "test_axis" },
  ];
  const r = checkRegression(prev, next);
  assertEquals(r.blocking, false);
});

Deno.test("checkRegression: no previous = no alerts", () => {
  const r = checkRegression(null, [
    { label: "x", advocat_v4: 2.5, comparators: {}, advocat_delta_pct: 0, format: "score", axis: "test_axis" },
  ]);
  assertEquals(r.blocking, false);
  assertEquals(r.alerts.length, 0);
});
