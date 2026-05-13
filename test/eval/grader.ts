// Advocat.ee chat-quality eval — LLM-judge grader.
//
// Calls Claude Sonnet 4.6 to evaluate a candidate answer against a Question's
// expected criteria. Returns per-criterion pass/fail plus weighted 0-100 score.
//
// Cost (Sonnet 4.6 list price as of build a745faa):
//   * Input  ~1500 tokens @ $3/M  = $0.0045 per call
//   * Output ~800 tokens  @ $15/M = $0.012 per call
//   * Total ~ $0.016 per graded question.
//   * 30 questions  ≈ $0.50 per full run.
//   * 100 questions ≈ $1.60 per full run.
// (The README quotes a conservative $0.05/q which over-estimates by ~3x.)
//
// The judge returns strict JSON; we parse defensively.

import type {
  CriterionResult,
  GraderResult,
  Question,
} from "./types.ts";

const JUDGE_MODEL = "claude-sonnet-4-6";
const JUDGE_MAX_TOKENS = 2048;

/** System prompt for the judge — kept inline so a single-file run works. */
const JUDGE_SYSTEM = `You are a strict but fair grader of legal-assistant answers.

You will receive:
  1. A user question (typically in Estonian),
  2. The candidate answer the assistant produced,
  3. Expected-answer criteria authored by Estonian-licensed lawyers
     (Dmitri Sulga / Sofia Sulga, advocat.ee), including:
       - must_mention_laws:   short legal-act codes the answer SHOULD cite
                              (e.g. TLS, VÕS, PKS, KodS, KarS).
       - must_include:        concepts/phrases that MUST appear (judge
                              SEMANTICALLY — paraphrase is fine, exact wording
                              is not required).
       - must_not_include:    anti-patterns that disqualify the answer.
       - tone:                stylistic guidance.
       - min_word_count / max_word_count: soft length bounds.

YOUR JOB: For every item across all four lists, output one criterion result:
  { "criterion": <string copy of item>, "type": <type>, "pass": <bool>,
    "evidence": <<=200 chars quoting/paraphrasing the answer> }

For must_mention_laws:
  - PASS if the act code appears in the answer at least once (case-insensitive
    substring match is acceptable for the code itself; the surrounding context
    must look like an actual citation, not a stray word).

For must_include:
  - PASS if the answer conveys the concept in substance. Estonian paraphrase
    is fine. Reject if the answer obviously omits or contradicts.

For must_not_include:
  - PASS if the anti-pattern is ABSENT (i.e. PASS means the answer is clean).
  - FAIL if the anti-pattern appears.

For tone:
  - One criterion result with type="tone". PASS if the answer's register
    matches the description.

For length:
  - One criterion result with type="length". PASS if word_count is within
    [min_word_count, max_word_count]. Otherwise FAIL with evidence
    "word_count=N, expected [min..max]".

OUTPUT FORMAT — STRICT JSON, no code fences:
{
  "criteria": [
    { "criterion": "...", "type": "must_mention_laws", "pass": true,
      "evidence": "..." },
    ...
  ],
  "notes": "<optional 1-2 sentence overall comment>"
}

Be honest. Do not inflate scores. If the answer is empty / off-topic / in the
wrong language, mark almost everything as FAIL.`;

interface JudgeRawOutput {
  criteria: CriterionResult[];
  notes?: string;
}

/** Strip surrounding ```json fences if the model emitted them anyway. */
function stripFences(s: string): string {
  return s
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/```\s*$/i, "")
    .trim();
}

/** Word count — splits on whitespace; close enough for ET/EN/RU. */
export function wordCount(text: string): number {
  return text.trim().split(/\s+/).filter(Boolean).length;
}

/** Weight per criterion type — sums to 1.0. */
const WEIGHTS = {
  must_mention_laws: 0.30,
  must_include: 0.40,
  must_not_include: 0.20,
  tone: 0.05,
  length: 0.05,
} as const;

/**
 * Compute weighted 0-100 score from criteria array.
 *
 * Each TYPE contributes its weight, proportional to in-type pass rate.
 * Example: 4 of 5 `must_include` pass → 0.40 * (4/5) = 0.32 → 32 points.
 */
export function scoreFromCriteria(criteria: CriterionResult[]): number {
  const byType: Record<string, { total: number; pass: number }> = {};
  for (const c of criteria) {
    const t = c.type;
    byType[t] ??= { total: 0, pass: 0 };
    byType[t].total += 1;
    if (c.pass) byType[t].pass += 1;
  }

  let score = 0;
  for (const [type, weight] of Object.entries(WEIGHTS)) {
    const b = byType[type];
    if (!b || b.total === 0) {
      // No criterion of this type in the question → distribute weight evenly:
      // award full weight (we don't penalise questions that don't constrain
      // every dimension).
      score += weight;
    } else {
      score += weight * (b.pass / b.total);
    }
  }
  return Math.round(score * 1000) / 10; // one decimal place, 0-100
}

/** Build the user-payload JSON the judge sees. */
function buildUserPayload(q: Question, candidate: string, wc: number): string {
  return JSON.stringify(
    {
      question_id: q.id,
      category: q.category,
      language: q.language,
      user_question: q.question,
      candidate_answer: candidate,
      candidate_word_count: wc,
      expected: q.expected,
    },
    null,
    2,
  );
}

/**
 * Call the Anthropic Messages API as judge.
 * Owner: provide ANTHROPIC_API_KEY in env.
 */
export async function gradeAnswer(
  q: Question,
  candidate: string,
  opts: {
    anthropicApiKey: string;
    judgeModel?: string;
    passThreshold?: number;
  },
): Promise<GraderResult> {
  const wc = wordCount(candidate);

  if (!opts.anthropicApiKey) {
    throw new Error("gradeAnswer: ANTHROPIC_API_KEY missing");
  }

  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": opts.anthropicApiKey,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: opts.judgeModel ?? JUDGE_MODEL,
      max_tokens: JUDGE_MAX_TOKENS,
      system: JUDGE_SYSTEM,
      messages: [
        { role: "user", content: buildUserPayload(q, candidate, wc) },
      ],
    }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(
      `judge API ${resp.status} for q=${q.id}: ${errText.slice(0, 400)}`,
    );
  }

  const json = await resp.json() as {
    content?: Array<{ type: string; text?: string }>;
  };
  const rawText: string = json.content?.[0]?.text ?? "{}";
  const cleaned = stripFences(rawText);

  let parsed: JudgeRawOutput;
  try {
    parsed = JSON.parse(cleaned) as JudgeRawOutput;
  } catch {
    throw new Error(
      `judge returned non-JSON for q=${q.id}: ${cleaned.slice(0, 200)}`,
    );
  }

  // Defensive: if the judge omitted `length` or `tone`, synthesise them so
  // the weighting math doesn't silently advantage incomplete grades.
  const criteria = [...(parsed.criteria ?? [])];
  if (!criteria.some((c) => c.type === "length")) {
    const inRange = wc >= q.expected.min_word_count &&
      wc <= q.expected.max_word_count;
    criteria.push({
      criterion: `length in [${q.expected.min_word_count}..${q.expected.max_word_count}]`,
      type: "length",
      pass: inRange,
      evidence: `word_count=${wc}`,
    });
  }
  if (!criteria.some((c) => c.type === "tone")) {
    criteria.push({
      criterion: q.expected.tone,
      type: "tone",
      pass: true, // benefit of the doubt — judge didn't flag
      evidence: "tone criterion not graded by judge; defaulted to pass",
    });
  }

  const score = scoreFromCriteria(criteria);
  const threshold = opts.passThreshold ?? 70;

  return {
    score,
    pass: score >= threshold,
    criteria,
    word_count: wc,
    notes: parsed.notes,
    raw: rawText,
  };
}
