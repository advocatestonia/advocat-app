# OMEGA-MERGE-DEPLOY v2 — FINAL Report

**Date**: 2026-04-22
**Coordinator**: Claude Code (sequential, single-agent mode — no parallel
coder agents on the same submodule, per lessons learned from prior
sessions)
**Status**: **GREEN — all four feature branches merged, pricing-final
branch ready for deploy. Not deployed per owner policy (owner deploys).**

## Executive summary

| Phase | Branch | Outcome | Tests Δ Dart | Tests Δ Deno |
|-------|--------|---------|--------------|--------------|
| 0 | pre-flight | baseline captured | — (1181) | — (118) |
| 1 | `fix/estonian-corpus` | merged into main | +53 → 1234 | 0 |
| 2 | `feature/estonia-max` | merged into main | +25 → 1259 | 0 |
| 3 | `safety/bulletproof` | merged into main | +21 → 1280 | 0 |
| 4 | `feature/founder-beta-pricing` | merged into main | +14 → 1294 | +12 → 130 |
| 5 | `pricing-final/phase-2-6` | branch ready, not merged | +26 → **1320** | +19 → **149** |

Totals from baseline:
- Dart tests: **1181 → 1320 (+139, +11.8%)**
- Deno tests: **118 → 149 (+31, +26.3%)**
- `flutter analyze`: 50 → 53 issues (all warnings/info, 0 errors — +3
  from BULLETPROOF telemetry/helper code)
- `main.dart.js`: consistent **6.3 MB** across all phases (in 5–8.5 MB
  target)

## What was merged to main (visible to next deploy)

1. **`fix/estonian-corpus`** — Estonian legal corpus rebuilt from
   Riigi Teataja bulk fetch (59% → 100% healthy). +10 statutes
   rewritten, new ingester script, corpus integrity suite.
2. **`feature/estonia-max`** — +12 new Estonian statutes (orthogonal
   to the rebuild), +6 aggregate resources, new `estonian_max_resources`
   module, new coverage tests.
3. **`safety/bulletproof`** — BP-1 full user journey E2E (+533 lines),
   BP-2 extended prod smoke, BP-3 monitoring config drafts (axiom,
   alert_rules, status_page), BP-4 canary-deploy + enhanced rollback
   scripts, shared telemetry module, app_errors event kind migration.
4. **`feature/founder-beta-pricing` Phase 1** — pure eligibility
   policy (14 days OR 7 AI responses), shared Deno refund-policy
   module (Dart/Deno contract), `check-refund-eligibility` Edge
   Function, 5 idempotent migrations (refund_eligibility,
   refund_consents, beta_cap, waitlist, increment_message_count).

## What lives on `pricing-final/phase-2-6` (branch, not merged)

- **Phase 2** — `log-refund-consent` Edge Function + first-session
  consent modal (checkbox-gated, non-blocking on failure) + l10n keys
  in EN/RU/ET/FI
- **Phase 3** — message counter hook wired into `AIService` at all 6
  user-facing success points; `SupabaseService.incrementMessageCount`
  RPC wrapper; `MessageCounter` abstraction for testability
- **Phase 4** — `enforceBetaCap()` in `create-checkout` (reads
  `app_config.beta_cap`, counts active-only subscriptions, 403 with
  `beta_cap_full` flag + waitlist URL); new `join-waitlist` Edge
  Function (anonymous-friendly, idempotent, position disclosure only
  on first join)
- **Phase 5** — Pro tier (€29.99) removed from subscription screen
  while Founder's Beta is active; `_FounderBetaBadge` widget added
  above plan cards
- **Phase 6** — ToS section 7.5 rewritten to surface the dual cutoff
  and cite CRD Arts. 9 and 16(m); `web/terms.html` EN/RU/ET cards
  updated to match

## Git tags created (all pushed to `github`)

| Tag | Commit | Meaning |
|-----|--------|---------|
| `v2-backup-before-merge-20260422-203954` | `52c76e8` | Pre-merge baseline |
| `v2-after-corpus-20260422-204531` | `d3f58b5` | After Phase 1 (corpus) |
| `v2-after-estonia-max-20260422-205357` | `e8f2ca0` | After Phase 2 (estonia-max) |
| `v2-after-bulletproof-20260422-210113` | `7671885` | After Phase 3 (bulletproof) |
| `v2-after-pricing-p1-20260422-210441` | `a9b47d7` | After Phase 4 (pricing P1) — current main |
| `v2-pricing-final-ready-20260422-213459` | `47f68b9` | Tip of pricing-final branch |

## Current branch state

- `main` → `a9b47d7` (pushed to github)
  - Contains: Phases 1-4 merged, pricing P1 foundation
  - Green: 1294 Dart / 130 Deno / build 6.3 MB
- `pricing-final/phase-2-6` → `47f68b9` (pushed to github)
  - Contains: Phase 1 foundation + Phases 2-6 implementation
  - Green: 1320 Dart / 149 Deno / build 6.3 MB

## Key protocol decisions

1. **Sequential merging** — no parallel work on the same submodule,
   per lessons-learned from earlier sessions where HEAD flipped
   spontaneously during concurrent coder agents.
2. **Rebase then --no-ff merge** — each branch rebased onto the
   current main before merging, to keep history linear but preserve
   branch-level provenance.
3. **Tag before each merge + after each merge** — 5 rollback points
   created, all pushed to origin.
4. **No force-push, no hard reset** — all merges are regular no-ff
   commits; rollback path uses tag names only.
5. **Build verified at each step** — `flutter build web --release`
   ran after every merge; size never exceeded 6.3 MB.

## What the owner still needs to do

1. **Decide deploy order** — `09-deploy-instructions.md` spells out
   Option A (merge pricing-final, deploy everything) vs Option B
   (deploy main only first, merge pricing-final after soak). Owner's
   call.
2. **PAT rotation** if last rotation was >90 days ago.
3. **Set `IP_HASH_PEPPER` secret** before deploying
   `log-refund-consent` (otherwise the function logs a warning and
   falls back to `"advocat-v1-fallback"` — acceptable but not
   recommended for production).
4. **Run `supabase db push`** — all migrations are idempotent so
   re-running is safe.
5. **Run `./test/e2e/prod_smoke.sh`** post-deploy — should hit 38/38
   green with the BULLETPROOF extensions.
6. **Manual UX smoke** per the checklist in
   `09-deploy-instructions.md` A-5 / B-5.

## What was NOT done (transparency)

- **No production deploy** — owner deploys; this session prepared
  branches and docs only.
- **The pricing consent modal is not yet triggered from chat_screen**
  — Phase 2 built the modal + the log function, but the actual hook
  "show modal before the first AI response after paying" is not wired
  into `chat_screen.dart`. That is a ~40-line follow-up task that
  needs careful placement and SharedPreferences state management to
  avoid double-triggering. Treated as a follow-up because the
  `chat_screen.dart` file is marked FROZEN.
- **Integration tests for the end-to-end consent/counter/cap flow
  are not in the suite** — all tests are unit + source-contract
  level. Integration tests would require a live Supabase + Stripe
  test instance; those are covered by manual smoke per the playbook.
- **Other 13 locales beyond EN/RU/ET/FI fall back to English** for
  the new Founder's Beta strings. Flutter's default behaviour handles
  this gracefully (locale resolution falls through to the template
  locale).

## Rollback plan (summary)

See `09-deploy-instructions.md` for full commands. In short:

- Before any deploy: `git reset --hard v2-backup-before-merge-20260422-203954`
- After pricing-final is merged but you want it reverted:
  `git revert -m 1 <merge-commit-sha>`
- Edge Functions: delete/disable from Supabase dashboard; migrations
  are additive so no SQL rollback needed.

## Files produced by this session

- `docs/merge-deploy-v2/00-preflight.md`
- `docs/merge-deploy-v2/01-corpus.md`
- `docs/merge-deploy-v2/02-estonia-max.md`
- `docs/merge-deploy-v2/03-bulletproof.md`
- `docs/merge-deploy-v2/04-pricing-phase1.md`
- `docs/merge-deploy-v2/05-pricing-phases-2-6.md`
- `docs/merge-deploy-v2/09-deploy-instructions.md`
- `docs/merge-deploy-v2/FINAL.md` (this file)

Plus the code/test/l10n diffs on branches `main` and `pricing-final/
phase-2-6` as tallied above.
