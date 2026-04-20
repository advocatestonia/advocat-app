# Advocat.ee — deploy playbook (v24.2 and up)

This document is the single source of truth for how to build, deploy, and roll back
Advocat.ee. Created 2026-04-20 after the three prod-breakage incidents on
Apr 18 and Apr 20. Stored alongside `scripts/build-and-deploy.sh`,
`scripts/rollback.sh`, and `test/e2e/prod_smoke.sh`.

**If in doubt, do NOT hand-craft `flutter build web` commands.** Use the scripts.

## TL;DR

```bash
# deploy new version
./scripts/build-and-deploy.sh

# rollback to last known-good
./scripts/rollback.sh v24.2-frozen-2026-04-20

# re-run smoke tests against current prod
./test/e2e/prod_smoke.sh
```

## Architecture

```
advocat.ee (GitHub Pages, branch gh-pages)
├── /           (index.html, landing)              ← HAND-MAINTAINED, DO NOT OVERWRITE
├── /app.html   (Flutter shell for /app route)     ← built by flutter build web
├── /main.dart.js                                  ← built by flutter build web
├── /flutter_bootstrap.js                          ← built by flutter build web
├── /speech.js, /streaming.js                      ← static assets in web/
├── /blog/, /privacy.html, /terms.html, etc.       ← HAND-MAINTAINED
└── /assets/    (Flutter assets, legal corpora)    ← built by flutter build web

Supabase (project ref okgnkucgwsytsondrjye)
├── Auth                (Google OAuth via Supabase-managed provider)
├── Edge Functions (13) (source in supabase/functions/)
└── Postgres + RLS      (migrations in supabase/migrations/)
```

## Required tooling

| Tool | Version | Why |
|---|---|---|
| Flutter | 3.41.6 stable | Must match toolchain of frozen build; newer versions produce different main.dart.js sizes |
| Dart | 3.11.4 (bundled) | |
| Supabase CLI | >= 2.84 | `supabase functions deploy` |
| `SUPABASE_ACCESS_TOKEN` | set in `~/.zshrc` | Required for functions deploy |
| git | any | |
| curl | any | smoke tests |
| rsync | any | deploy |

## First-time setup

```bash
# 1. Pull the repo & ensure on main
cd /Users/ai.place/Advocat/app/advocat_project
git checkout main
git pull

# 2. Create .env.prod (copy example, fill values)
cp .env.prod.example .env.prod
# Edit .env.prod, fill:
#   SUPABASE_ANON_KEY         (from Supabase Dashboard > API > anon public)
#   STRIPE_PUBLISHABLE_KEY    (from Stripe Dashboard > Developers > API keys)
# Do NOT change SUPABASE_URL — default is correct.

# 3. Verify it's gitignored
grep -E "^\.env\.prod" .gitignore       # must output .env.prod

# 4. Verify SUPABASE_ACCESS_TOKEN in shell
source ~/.zshrc
echo ${#SUPABASE_ACCESS_TOKEN}          # should be ~44

# 5. Dry-run the deploy script first time
./scripts/build-and-deploy.sh --dry-run

# 6. When ready, for real
./scripts/build-and-deploy.sh
```

## What the deploy script does (and why)

1. **Preflight**: assert clean worktree, on `main`, `SUPABASE_ACCESS_TOKEN` present,
   `.env.prod` has non-empty `SUPABASE_ANON_KEY`, `.env.prod` is gitignored, tools
   installed. **The missing `SUPABASE_ANON_KEY` check is the one that would have
   prevented the Apr 18 and Apr 20 incidents.**

2. **Build**: `flutter build web --release --dart-define-from-file=.env.prod`.
   This is the ONLY supported way — hand-crafting `--dart-define=K=V` flags is
   error-prone (the Apr 18 deploy forgot `SUPABASE_ANON_KEY`, resulting in an
   empty key baked into main.dart.js → Supabase client never initialized →
   Google OAuth + chat silently dead).

3. **Size sanity**: main.dart.js must be 5-8.5 MB. If smaller, env vars are empty.
   If larger, build bloat — investigate.

4. **Anon-key proof**: script greps the bundle for the first 30 chars of
   `SUPABASE_ANON_KEY` and fails if not found. Confirms the key actually baked in.

5. **Deploy to gh-pages** via `git worktree`:
   - rsync `build/web/` → worktree, **excluding** landing files (index.html,
     landing*.html, blog/, privacy.html, terms.html, lawyers.html, payment-*.html,
     sitemap.xml, robots.txt, CNAME, .nojekyll)
   - commit + `git push github gh-pages`
   - (this preserves the hand-edited landing byte-for-byte, as per commit `06e4d226`)

6. **Deploy all 13 Edge Functions** via `supabase functions deploy`.

7. **Prod smoke** (`test/e2e/prod_smoke.sh`): curl every critical asset and
   CORS-probe every Edge Function. Fails loudly if anything is off.

## Rollback

The frozen known-good state is git tag `v24.2-frozen-2026-04-20` pointing at
commit `06e4d226a4b4a42b3d328d5bccd9889ad93df900` on `gh-pages`.

```bash
./scripts/rollback.sh v24.2-frozen-2026-04-20
```

Note that the rollback script only resets `gh-pages`. Edge Functions are NOT
automatically reverted. If a function regressed, check out the source at the
matching `main` SHA and run `./scripts/build-and-deploy.sh --skip-smoke` or
deploy that one function manually.

## Common failure modes (historical)

| Date | Symptom | Root cause | Fix |
|---|---|---|---|
| 2026-04-18 | LateInitializationError on /chat | Supabase client never initialized because `SUPABASE_ANON_KEY` not baked in | Add `--dart-define=SUPABASE_ANON_KEY=<jwt>` to build |
| 2026-04-20 morning | Google OAuth + chat silently broken | Same as above | Rebuild with proper `--dart-define-from-file=.env.prod` |
| 2026-04-20 noon | Robot voices instead of Chirp3-HD | Edge Functions `google-tts`/`tts-proxy`/`whisper-stt` rejected demo users (no JWT) with 401 | Added `anonymousPerMinute: 5` fallthrough in `_shared/auth.ts`; deployed v18/v14/v4 |

All three incidents would have been caught by `test/e2e/prod_smoke.sh` running
automatically after deploy. That's now mandatory — step 7 of the deploy script.

## DO NOT

- Do not run `flutter build web --release` without `--dart-define-from-file=.env.prod`.
- Do not hand-edit files on the `gh-pages` branch (use the deploy script).
- Do not commit `.env.prod`, `.env`, or any file containing `SUPABASE_ANON_KEY`.
- Do not `git push --force` to `gh-pages` except through `scripts/rollback.sh`.
- Do not bypass `prod_smoke.sh` (unless you have a justified reason and ran it manually).
- Do not deploy Edge Functions from a dirty working tree (source must match what's committed).
- Do not update Flutter version without first testing on a throwaway deploy — build sizes change.

## Known open issues as of 2026-04-20 freeze

- Git remote `github` URL contains a raw PAT (`ghp_…`). Rotate + move to credential helper.
- No `supabase/config.toml` — all functions use default `verify_jwt=true`; the
  anonymous fallthrough is implemented in `_shared/auth.ts` instead. This is
  correct for current anon-via-anon-key usage pattern.
- No CI. All deploys are manual via this script. Next step: GitHub Actions
  workflow that runs `prod_smoke.sh` on every push to `gh-pages`.
