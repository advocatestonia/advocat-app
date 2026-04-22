# BP-4 — Canary deploy + rollback automation

## What changed

### NEW: `scripts/canary-deploy.sh`

One command that:

1. Builds `flutter web --release --dart-define-from-file=.env.prod`
2. Pushes the build to `gh-pages:/staging/` (served at
   `https://advocat.ee/staging/`)
3. Runs `test/e2e/prod_smoke.sh` with `SMOKE_BASE_URL=https://advocat.ee/staging`
4. If staging smoke fails → **abort, prod untouched**
5. If staging smoke green → promotes the same build bits to prod root
6. Re-runs `prod_smoke.sh` against prod
7. If prod smoke fails → **invokes `scripts/rollback.sh` automatically**
   (target: `ROLLBACK_TAG` env or `v24.2-frozen-2026-04-20`)
8. Emails owner on final outcome (if `NOTIFY_EMAIL` set & `mail` CLI present)

Flags:
- `--staging-only` — stop after step 3 (manual promotion)
- `--dry-run` — print everything, push nothing

### UPDATED: `scripts/rollback.sh`

Backwards-compatible. Old invocation (`./scripts/rollback.sh` or
`./scripts/rollback.sh <tag>`) still works exactly the same.

New additions:
- **Verifies rollback worked**. Runs `prod_smoke.sh` post-rollback and
  exits non-zero if smoke still fails (previous behaviour: exited 0
  based only on the push succeeding).
- `--mark-bad <sha>` flag appends a line to `docs/ROLLBACK_LOG.txt`:
  `<ts>  bad=<sha>  rolled-back-to=<tag>`. Cheap audit trail.
- `--sql-down <migration-name>` optional flag runs a matching
  `supabase/migrations/<name>.down.sql` if present. Safe no-op if the
  down file is missing or the Supabase CLI / token is not configured.
- Structured exit codes:
  - `0` rollback ok AND smoke green
  - `1` rollback pushed BUT smoke still failing (needs manual review)
  - `2` usage / missing tools / bad tag
  - `3` target is not a valid gh-pages snapshot

## Topology

```
            ┌────────────────────────────────────────┐
            │             canary-deploy.sh           │
            └──────────────────┬─────────────────────┘
                               │
              ┌────────────────┴───────────────────┐
              │  step 1 build (same bits for both) │
              └────────────────┬───────────────────┘
                               │
           ┌───────────────────┼────────────────────┐
           ▼                                        ▼
   gh-pages:/staging/                        gh-pages:/
   advocat.ee/staging/                       advocat.ee/
   (prod_smoke) ───────[ green ]─────►       (prod_smoke)
           │                                       │
           │ [ red ]                               │ [ red ]
           ▼                                       ▼
      ABORT prod                          rollback.sh --mark-bad HEAD
      unchanged                           → tag v24.2-frozen-2026-04-20
                                          → re-smoke prod
```

## Safety mechanisms

- **Staging is served from the same domain as prod.** That means `CORS`,
  `CSP`, and the Edge Function `Origin: advocat.ee` allow-list behave
  identically. A separate staging domain would have to be added to each
  Edge Function's CORS list — too many moving parts for a small team.
- **Landing files list preserved byte-for-byte.** The promote step
  reuses the same `LANDING_FILES` exclude list as `build-and-deploy.sh`.
  Drift between those two lists is the #1 way to accidentally overwrite
  the hand-maintained landing HTML. If a future contributor adds a
  landing file, they must update **both** scripts.
- **`--force-with-lease`** on gh-pages push protects against overwriting
  a concurrent push.
- **Worktree isolation.** All gh-pages operations happen in a mktemp
  worktree so the operator's cwd stays on `main` with a clean tree.
- **Sleep-before-smoke.** 10s sleep lets GitHub Pages / Fastly flush
  before we probe, reducing false negatives from stale CDN copies.

## What is NOT automated

- **Edge Function rollback.** rollback.sh only resets gh-pages; Edge
  Functions stay at their current versions. If an EF regressed you must
  checkout the matching main SHA and re-run `build-and-deploy.sh
  --skip-functions=0 --skip-smoke`.
- **Supabase migration rollback.** `--sql-down` is opt-in and requires a
  hand-written `.down.sql` per migration. None exist yet; writing them
  is future work.
- **DNS / CDN flush.** We rely on GH Pages + Cloudflare proxy to flush
  on their own within ~10s.

## Operational runbook

### Deploy new release
```bash
git checkout main && git pull --ff-only
./scripts/canary-deploy.sh          # stages → smokes → promotes → smokes
```

### Deploy to staging only (manual review)
```bash
./scripts/canary-deploy.sh --staging-only
# open https://advocat.ee/staging/  for eyeballs test
```

### Emergency rollback
```bash
./scripts/rollback.sh                            # default: last frozen tag
./scripts/rollback.sh <sha-or-tag>               # arbitrary target
./scripts/rollback.sh --mark-bad HEAD~1 <tag>    # record bad commit
./scripts/rollback.sh --sql-down 20260422_bad <tag>   # also run .down.sql
```

### Inspect rollback history
```bash
cat docs/ROLLBACK_LOG.txt
```

## Tested?

- `bash -n` syntax-ok on both scripts (no runtime test against prod
  from this branch — bulletproof infra must NOT deploy).
- The canary script calls the same executables (`flutter`, `rsync`,
  `git worktree`, `curl`) that `build-and-deploy.sh` has been using
  successfully since v24.2.
