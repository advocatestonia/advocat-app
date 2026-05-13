# Advocat — Flutter app + Supabase backend

Production code for [advocat.ee](https://advocat.ee). Flutter web client, ~35 Supabase Edge Functions, Postgres + pgvector, Stripe billing, optional Typst PDF worker.

For the surrounding workspace (investor materials, cases, content, eval data) see the outer repo `Advocat/`.

## Quick start

```sh
# 1. Install git hooks (one-time)
./scripts/install-hooks.sh

# 2. Get Flutter deps
flutter pub get

# 3. Run unit + widget tests
flutter test

# 4. Run the web app locally
flutter run -d chrome --web-port 8000
```

The git hook setup points `git` at `.githooks/`, enabling:

- pre-commit: ~15s fast-test guard
- pre-push: full `analyze + test` gate
- prod-lock: blocks direct `gh-pages` pushes (see [`scripts/prod-lock.sh`](scripts/prod-lock.sh))

## Architecture (1-paragraph version)

Flutter web shell talks to **Supabase Edge Functions** (Deno) for everything stateful: auth, chat, contract review, email agent, deadlines, payments. The `claude-proxy` function routes chat turns through one of three pipelines depending on the question — fast Haiku passthrough, full **legal_planner** (planner → executor → critique → red-team → subtraction), or **consilium** (parallel domain experts + strategic positions synthesised by Sonnet). Citations use `[[ref:slug:para]]` markers grounded against `law_chunks` (pgvector). Contract Review uploads pass through `pdf-parser` → planner → `contract-review` → `typst-worker` (Railway microservice) → signed Supabase Storage URL.

Full architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Deploy

```sh
./scripts/canary-deploy.sh
```

This is the **only** sanctioned path to prod. It runs preflight, builds with `--dart-define-from-file=.env.prod`, deploys to staging, runs smoke tests, then promotes to `gh-pages`. Direct `git push gh-pages` is blocked by the prod-lock hook.

Deploy playbook + rollback procedure: [`docs/DEPLOY.md`](docs/DEPLOY.md).

To force-deploy when smoke fails (rare — last-resort during incidents):

```sh
FORCE_DEPLOY_REASON="explain why" ./scripts/canary-deploy.sh
```

## Testing

```sh
flutter test                            # unit + widget
flutter test test/e2e/                  # Flutter integration
deno test supabase/functions/_tests/    # edge fn unit tests
deno test --allow-net eval/runner.ts    # email-triage eval harness
```

For chat answer-quality regression, use the outer-repo suite:

```sh
cd ..  # back to Advocat/
deno run -A scripts/eval/run-eval.ts --full
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the eval-suite split.

## Project rules

- **Canary deploy only.** Never bypass smoke without `FORCE_DEPLOY_REASON`.
- **TDD on legal logic.** RED test before any non-trivial change to `_shared/*`.
- **No secrets in tracked files.** `.env.prod` is gitignored; production secrets live in Supabase + GitHub Actions.
- See [`CLAUDE.md`](CLAUDE.md) for the full agent-binding ruleset.
