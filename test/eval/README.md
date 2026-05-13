# Advocat.ee — Chat-Quality Eval Harness

**Purpose.** Without an automated quality bar we cannot tell whether a model
swap (Haiku → Sonnet), a system-prompt edit, or a RAG-tuning change helps or
hurts answer quality on real Estonian/EU legal questions. This harness is the
bar.

**What it is.** A curated set of Estonian-language legal questions across six
categories (employment / housing / family / deportation / consumer /
contract), each with expected-answer criteria authored by the founders
(Dmitri & Sofia Sulga). The runner calls advocat.ee chat (`claude-proxy`) for
each question and a Claude Sonnet 4.6 judge scores the response against the
criteria.

**This is the third eval system in the repo — they are complementary, not
duplicative.**

| Path                                         | Scope                                 | Format |
| -------------------------------------------- | ------------------------------------- | ------ |
| `eval/runner.ts`                             | Email-triage Pkg 8 fixtures           | JSON   |
| `scripts/eval/run-eval.ts` + `data/eval/`    | Single-case Sulga answers, judge-swap | YAML   |
| **this one** (`test/eval/`)                  | Broad ET legal chat quality           | JSON   |

---

## File layout

```
test/eval/
├── README.md                  this file
├── types.ts                   shared TypeScript types
├── grader.ts                  Sonnet-4.6 LLM judge
├── runner.ts                  loads questions, calls chat, scores, reports
├── questions/
│   ├── employment.json        5 starter questions  (TLS)
│   ├── housing.json           5 starter questions  (VÕS, KrtS)
│   ├── family.json            5 starter questions  (PKS, PKTS, LasteKS)
│   ├── deportation.json       5 starter questions  (VMS, KodS, VSS, HKMS)
│   ├── consumer.json          5 starter questions  (VÕS, TKS, TPS)
│   └── contract.json          5 starter questions  (VÕS, TsÜS, TsMS)
└── results/                   one JSON per run (gitignored — owner adds rule)
```

**Total starter questions: 30** (5 × 6 categories). Scale to 100 by adding
more questions to each file — no code change required.

---

## How to run

### One-time setup

```bash
export ANTHROPIC_API_KEY=sk-ant-...           # judge calls
export SUPABASE_ANON_KEY=eyJ...               # candidate calls (demo-tier OK)
# OR for unrestricted candidate calls (no 500-token cap):
export SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

### Dry-run (no API cost — sanity-check questions load + validate)

```bash
cd app/advocat_project
deno run --allow-all test/eval/runner.ts --dry-run
```

### Full run — Haiku candidate

```bash
deno run --allow-all test/eval/runner.ts --model=haiku
# → test/eval/results/2026-05-13-haiku.json
```

### Full run — Sonnet candidate

```bash
deno run --allow-all test/eval/runner.ts --model=sonnet
# → test/eval/results/2026-05-13-sonnet.json
```

### One category or one question

```bash
deno run --allow-all test/eval/runner.ts --model=sonnet --category=family
deno run --allow-all test/eval/runner.ts --question=emp-004
```

### Compare two runs (regressions / improvements)

```bash
deno run --allow-all test/eval/runner.ts \
  --compare test/eval/results/2026-05-13-haiku.json \
            test/eval/results/2026-05-13-sonnet.json
```

A score drop > 5 points is flagged as a regression; gain > 5 points as an
improvement.

---

## Cost per full run (30 questions, May 2026 list prices)

| Component       | Tokens (typical) | Price                                    |
| --------------- | ---------------- | ---------------------------------------- |
| Candidate Haiku | ~30 × 1500       | ≈ $0.15                                  |
| Candidate Sonnet| ~30 × 1500       | ≈ $0.90                                  |
| Judge Sonnet 4.6| ~30 × 2300       | ≈ $0.50                                  |
| **TOTAL Haiku** |                  | **≈ $0.65**                              |
| **TOTAL Sonnet**|                  | **≈ $1.40**                              |

For a 100-question suite, multiply by ~3.3 → $2-$5 per full run.
The original budget of $5 / 100 questions stands.

---

## Question schema

Each `questions/*.json` is an array of:

```jsonc
{
  "id": "emp-001",                      // <cat-prefix>-NNN
  "category": "employment",             // matches file name
  "language": "et",                     // et | ru | en | fi
  "question": "Tööandja vallandas...",  // verbatim user message
  "expected": {
    "must_mention_laws": ["TLS"],       // short act codes (TLS, VÕS, PKS...)
    "must_include": [                   // concepts — judge SEMANTICALLY
      "30-päevane vaidlustamise tähtaeg",
      "hüvitis vähemalt 3 kuu palka"
    ],
    "must_not_include": [               // anti-patterns
      "lubadus garanteeritud tulemusele",
      "väljamõeldud kohtulahend"
    ],
    "tone": "professionaalne, empaatiline",
    "min_word_count": 120,
    "max_word_count": 500
  },
  "difficulty": "medium",               // easy | medium | hard
  "tags": ["dismissal", "tls", "tvkomisjon"]
}
```

### Scoring weights (in `grader.ts`)

| Criterion type     | Weight |
| ------------------ | ------ |
| `must_mention_laws`| 30%    |
| `must_include`     | 40%    |
| `must_not_include` | 20%    |
| `tone`             |  5%    |
| `length`           |  5%    |

Each type contributes its weight × in-type pass rate. Question passes if
overall score ≥ 70/100.

---

## How to add a new question

1. Open the right category file in `questions/`.
2. Append a new object, incrementing `id` (e.g. `emp-006`).
3. Re-run `--dry-run` to validate schemas.
4. Run the question alone first: `--question=emp-006`.
5. Refine `expected.must_include` based on what a *good* answer looks like —
   judge feedback in `notes` and per-criterion `evidence` is your guide.

**Style guide for `must_include` items:**
- Short, concept-level (not full sentences).
- Cite the specific law section when relevant: `"30 päeva vaidlustamise tähtaeg (TLS § 89 lg 1)"`.
- Avoid wording the model is unlikely to copy verbatim — the judge interprets
  semantically, but extremely specific phrasings hurt recall.

**Style guide for `must_not_include`:**
- Anti-patterns, not topics. Good: `"lubadus garanteeritud tulemusele"`.
  Bad: `"family law content"`.

---

## How to interpret a results JSON

```jsonc
{
  "run_id": "2026-05-13-haiku",
  "model": "claude-haiku-4-5",
  "pass_rate": 0.73,
  "mean_score": 76.4,
  "per_category": {
    "employment": { "total": 5, "passed": 4, "mean_score": 81.2 },
    "deportation":{ "total": 5, "passed": 2, "mean_score": 62.8 }, // weakness!
    ...
  },
  "rows": [
    {
      "question_id": "dep-005",
      "candidate_answer": "...",
      "grader": {
        "score": 58,
        "pass": false,
        "criteria": [
          { "criterion": "VSS § 30 sissesõidukeelu lühendamine",
            "type": "must_include", "pass": false,
            "evidence": "answer mentions appeal but not VSS § 30 explicitly" }
        ],
        "notes": "Answer covers EIÕK art 8 well; misses Estonian-law specifics."
      }
    }
  ]
}
```

**Triage flow:**
1. `pass_rate < previous run`? → check `--compare`.
2. Category with `mean_score < 70`? → review those rows' `criteria` for
   systematic gaps (e.g. model never cites a specific law).
3. Per-row `grader.notes` is the judge's prose summary — useful for spotting
   tone / structure issues.
4. `candidate_answer` is preserved verbatim — owner can re-read what the model
   actually said.

---

## Pitfalls / known limitations

- **Judge is one Sonnet 4.6 call, no swap-debias** unlike `scripts/eval/run-eval.ts`.
  Position bias is small for this rubric style (per-criterion, not pairwise),
  but if you see systematic over-grading consider adding a swap pass later.
- **Demo-tier cap.** `SUPABASE_ANON_KEY` candidate calls are clamped to 500
  output tokens with 3 req/min throttle. For full evals use
  `SUPABASE_SERVICE_ROLE_KEY` — service-role bypasses the demo guard.
  (See memory: `lesson_anon_jwt_bypass.md`, `lesson_demo_anon_restored.md`.)
- **Production endpoint.** Runner hits PRODUCTION `claude-proxy` by default.
  Override with `ADVOCAT_SUPABASE_URL=https://<staging>.supabase.co` to run
  against staging without burning prod budget.
- **No RAG context, no case_id.** Runner sends bare `messages` only — this
  measures the *base chat* quality, not the document-attached or active-case
  flow. Those need separate eval suites.
- **No streaming.** `stream: false` — eval doesn't exercise SSE path.
- **Q/A IDs are stable.** Never renumber existing question IDs; that would
  invalidate historical `results/*.json`. Always append new IDs at the end.

---

## Owner action items (Dmitri / Sofia)

1. Read every question in `questions/*.json`. The 30 starters were drafted by
   a coding agent using current Advocat memory (TLS, VÕS, PKS conventions),
   but the founders are the authority — fix every `must_include` /
   `must_not_include` you disagree with.
2. Add `test/eval/results/` to `.gitignore` if you don't want run artefacts
   checked in (the eval-level `.gitignore` in `eval/` is precedent).
3. Pick one of Haiku or Sonnet as the **baseline** and rename the run JSON to
   `baseline.json`; future runs `--compare`-diff against it.
4. Decide whether to run weekly (via the existing scheduled-trigger
   infrastructure, see memory `reference_scheduled_triggers.md`).
