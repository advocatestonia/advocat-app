# Pkg 8 — Email Agent eval suite (scaffold)

Regression harness for the **email-triage** edge function across prompt
versions (v1.1-final ↔ v1.2.1-final), seeded with the 5 Sulga test cases
from `track_A_v1.2_prompt.md` §5.

## Why this exists, and how it relates to the workspace eval

Two eval suites live in this repo:

| Suite | Path | Target | Trigger |
|---|---|---|---|
| Chat answer quality (rubric/judge) | `Advocat/scripts/eval/run-eval.ts` + `Advocat/data/eval/` | `claude-proxy` chat outputs | Pre-deploy / nightly |
| **Email triage block contract (this suite)** | `app/advocat_project/eval/` | `email-triage` edge fn outputs | Manual, post-staging-deploy of a new prompt version |

The chat suite is judge-rubric on legal-answer quality. This suite is
contract-oriented: did the prompt version produce the right `<triage>`,
`<draft>`, `<memory_update>` blocks for these specific Sulga inputs?

`legal_planner.dart` references "the Pkg 8 eval suite reads bucketing by
treatment" — that's the workspace chat suite. This email suite
complements it for the Email Agent track (Track A v1.2).

## Layout

```
eval/
├── README.md                # this file
├── .gitignore               # gitignores results/
├── fixtures/                # 5 input fixtures (JSON)
│   ├── sulga_test_23_HAO_paatos.json       # Rule 31 forum precheck
│   ├── sulga_test_24_posti_dimitri.json    # Rule 32 + 34
│   ├── sulga_test_25_kaannytys_lang.json   # Rule 33 + 34
│   ├── sulga_test_26_identity_stack.json   # Rule 34 pattern flag
│   └── sulga_test_27_poytakirja_parsed.json# Rule 35 sub-rules a-g
├── expected/                # human-readable PASS criteria per fixture
│   └── sulga_test_2{3,4,5,6,7}_*.md
├── runner.ts                # Deno script
└── results/                 # gitignored runner output
```

## Run

```bash
# from app/advocat_project (this directory)
deno run --allow-net --allow-env --allow-read --allow-write \
  eval/runner.ts \
  --prompt-version v1.2.1-final \
  --fixture all

# single fixture
deno run --allow-net --allow-env --allow-read --allow-write \
  eval/runner.ts \
  --prompt-version v1.1-final \
  --fixture sulga_test_23_HAO_paatos
```

Compare `results/<fixture>.v1.1-final.json` ↔ `results/<fixture>.v1.2.1-final.json`
to see what Rules 31-35 added.

## Required env vars

| Var | Purpose | Required for stub | Required for real run |
|---|---|---|---|
| `SUPABASE_URL` | Staging Supabase project URL | no | yes |
| `SUPABASE_ANON_KEY` | Bearer for edge fn | no | yes |
| `SUPABASE_SERVICE_ROLE_KEY` | DB insert of fixture threads | no | yes (strategy A) |
| `EMAIL_AGENT_PROMPT_VERSION` | Backend prompt selector reads this from Supabase secrets | n/a | must already be set in Supabase secrets matching `--prompt-version` |
| `ANTHROPIC_API_KEY` | (Future) semantic-diff judge | no | optional |

## How the runner works (and what's still TODO)

1. Loads fixture JSON (thread + headers + attachments metadata + active_case overlay + user question).
2. Calls `email-triage` edge fn — see `runner.ts` strategy (A) vs (B) comment block. **Currently stubbed** because the edge fn pulls thread by `thread_id` from `email_inbox_threads`, so a real run requires a staging-DB insert flow (owner: implement post-deploy).
3. Extracts `<triage>`, `<draft>`, `<memory_update>` etc. blocks from response.
4. Diffs against per-fixture expectation regex set in `runner.ts EXPECTATIONS` (derived from `expected/<fixture>.md` PASS criteria).
5. Writes `results/<fixture>.<version>.json` with: blocks, latency, edge_fn_status, expected_met, pass.
6. Prints `PASS` / `FAIL` / `ERROR` per fixture; exits non-zero if any fail.

## Caveats (this is scaffolding)

- **Stub callEmailTriage:** runner.ts currently returns a stubbed response. Owner must wire either strategy (A) staging-DB-insert or (B) pure-logic-call before a meaningful run. See runner.ts `TODO(staging-insert)` comment.
- **Regex-only expectation diff:** PASS criteria are matched by regex on extracted blocks. This catches structural regressions (forum mismatch, missing tracking number) but not nuance ("does the §114 paragraph actually argue erityisen painava syy?"). For nuance, `TODO(semantic)`: wire a Sonnet judge step.
- **No CI integration:** intentionally manual. Real runs hit Anthropic via the prompt + each call costs real money. Run before flipping `EMAIL_AGENT_PROMPT_VERSION` Supabase secret to `v1.2.1-final` in prod.
- **Fixture data is synthetic:** binary attachments referenced in metadata (PDF, PNG) are not committed — tests verify behaviour assuming the calling layer parsed them and surfaced structured fields in `active_case_overlay.case_facts`. Real PDFs / OCR are out of scope.

## Adding a new fixture

1. Pick a real Sulga thread or a v1.3 test seed from a future track_A.
2. Anonymize where applicable (this is owner's case, so less sensitive).
3. Write fixture JSON to `fixtures/<id>.json` matching the schema of existing fixtures.
4. Write expected behaviour to `expected/<id>.md` with PASS/Anti-PASS criteria.
5. Add an entry to `EXPECTATIONS` in `runner.ts` with regex checks.
6. Run once with `--prompt-version v1.2.1-final` and review `results/<id>.v1.2.1-final.json` to calibrate regex (false positives common on first pass).
7. Commit fixture + expected + runner update together.

## Source authority

The 5 seed fixtures (Tests 23-27) trace verbatim to:
`business/email_agent_handoff_2026-05-06/v2.1_consilium/track_A_v1.2_prompt.md` §5.

If §5 is updated in v1.3, regenerate fixtures from the new spec — don't hand-edit.

## Pkg 8 owner action item (post-staging-deploy)

After deploying email-triage with `EMAIL_AGENT_PROMPT_VERSION=v1.2.1-final` to staging:

```bash
cd app/advocat_project
SUPABASE_URL=https://<staging-project>.supabase.co \
SUPABASE_ANON_KEY=<key> \
SUPABASE_SERVICE_ROLE_KEY=<key> \
deno run --allow-net --allow-env --allow-read --allow-write \
  eval/runner.ts --prompt-version v1.2.1-final --fixture all
```

Compare results to a baseline run on `v1.1-final`. PASS-gate before
flipping the Supabase secret in prod.
