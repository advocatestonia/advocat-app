# Deploy Instructions — OMEGA-MERGE-DEPLOY v2

**Prepared state**: `main` contains the four merged feature branches. A
separate branch `pricing-final/phase-2-6` contains pricing Phases 2-6
implementation (consent modal, message counter hook, beta cap
enforcement, UI cleanup, ToS updates). The owner decides whether to
deploy main-only first (safer) or merge pricing-final to main first then
deploy everything (one big release).

Both options are documented below. The default recommendation is **Option
B (main only first, pricing-final as a follow-up)** — it lets the Phase
1-4 merged work (corpus, estonia-max, bulletproof, pricing-foundation)
soak in production before the user-visible consent modal + beta cap
changes go live.

---

## Pre-flight (both options)

```bash
# 1. Confirm you are on the right commit
cd /Users/ai.place/Advocat/app/advocat_project
git fetch github
git log --oneline -3 main
# Expected: a9b47d7 (pricing-phase-1) as the pre-pricing-final tip, or
#          47f68b9 (pricing-phase-6) if pricing-final already merged.

# 2. Confirm no uncommitted changes
git status

# 3. PAT rotation (if not already done this week)
#    The github remote uses a personal access token embedded in the URL.
#    Rotate it if the last rotation was >90 days ago.

# 4. Run a final regression locally (optional but recommended)
flutter test
cd supabase/functions && deno test --allow-all && cd ../..
flutter build web --release
ls -lh build/web/main.dart.js  # 5-8.5 MB target
```

## Option A — Deploy everything now (main + pricing-final merged)

### A-1. Merge pricing-final into main

```bash
git checkout main
git pull github main
git merge --no-ff pricing-final/phase-2-6 -m "merge: pricing-final/phase-2-6 — consent modal, msg counter, beta cap, UI, ToS"
flutter test          # target: ~1320 tests
flutter analyze       # target: 53 issues, 0 errors
flutter build web --release
ls -lh build/web/main.dart.js  # ~6.3 MB

TAG="v2-post-pricing-final-$(date +%Y%m%d-%H%M%S)"
git tag "$TAG"
git push github main
git push github "$TAG"
```

### A-2. Continue with A-3 (Supabase) below.

## Option B — Deploy main first, pricing-final later (recommended)

### B-1. main deploy first (Phase 1-4 of merge-deploy-v2)

Jump straight to A-3 below — main already contains the four merged
branches plus pricing Phase 1 foundation. The consent modal is not yet
wired into the first-AI-response path (no reference in chat_screen), so
the foundation is inert until Phase 2-6 lands.

Later, after soak, merge pricing-final and repeat A-3 for the new
artifacts.

## A-3 / B-3 — Supabase (DB + Edge Functions)

### SQL preflight

```bash
# In the Supabase dashboard SQL editor (or `supabase db diff`):
# verify these migrations are still pending if they haven't been pushed
# yet. ALL are idempotent (CREATE IF NOT EXISTS, ON CONFLICT DO NOTHING).
#   - 20260421_app_errors_event_kind.sql          (from BULLETPROOF)
#   - 20260422_refund_eligibility.sql             (from PRICING-P1)
#   - 20260422_refund_consents.sql                (from PRICING-P1)
#   - 20260422_beta_cap.sql                       (from PRICING-P1)
#   - 20260422_waitlist.sql                       (from PRICING-P1)
#   - 20260422_increment_message_count.sql        (from PRICING-P1)

supabase db push
# If using the CLI with a project ref:
#   supabase link --project-ref <ref>
#   supabase db push
```

### Secrets

```bash
# Required for log-refund-consent. Rotates the IP-hash pepper; rotating
# it invalidates all prior hashes (intentional privacy feature).
supabase secrets set IP_HASH_PEPPER=$(openssl rand -hex 16)

# CRON_SECRET if not already set (used by deadline-reminder / other
# scheduled functions — unchanged by this release).
# supabase secrets set CRON_SECRET=$(openssl rand -hex 32)
```

### Edge Functions deploy

For Option A (everything merged):
```bash
supabase functions deploy log-refund-consent
supabase functions deploy join-waitlist
supabase functions deploy create-checkout    # updated with beta cap
# Already deployed previously, no changes needed:
#   check-refund-eligibility (from PRICING-P1 merge — deploy if not yet live)
```

For Option B (main only):
```bash
# Only PRICING-P1's edge function is new in main:
supabase functions deploy check-refund-eligibility
# (Later, on pricing-final deploy: log-refund-consent, join-waitlist,
#  create-checkout)
```

## A-4 / B-4 — Web (Flutter)

```bash
cd /Users/ai.place/Advocat/app/advocat_project
./scripts/build-and-deploy.sh
# This runs flutter build web --release and pushes to gh-pages.
# Verify advocat.ee serves the new main.dart.js size (~6.3 MB).
```

## A-5 / B-5 — Smoke tests

```bash
# Extended prod smoke from the BULLETPROOF branch:
./test/e2e/prod_smoke.sh
# Expected: 38/38 green (up from ~24 pre-bulletproof, +14 from
# extended smoke additions).
```

Manual UX checks (ALL deploys):
1. Log in, visit Settings → Subscription
2. Confirm the **Founder's Beta badge** appears (if pricing-final merged)
3. Confirm **only Free + Basic plans are listed** (no €29.99 Pro tier)
4. Confirm **refund policy line** "14-day refund or 7 AI responses"
   appears under the badge
5. Click upgrade to Basic — Stripe Checkout should open (unless 25-user
   cap reached; in that case toast "Founder's Beta is full")
6. After paying (in a test account) go to chat — the consent modal
   should appear on the first AI message attempt. Tick the checkbox,
   press Begin, verify you can send a message.
7. Open the ToS page (Settings → Terms) — confirm section 7.5 mentions
   both cutoffs and cites Arts. 9 and 16(m).

## Rollback

Quick rollback points (all pushed to github):

| Tag | State |
|-----|-------|
| `v2-backup-before-merge-20260422-203954` | pre-merge (main @ 52c76e8) |
| `v2-after-corpus-20260422-204531` | after Phase 1 (corpus fix) |
| `v2-after-estonia-max-20260422-205357` | after Phase 2 (estonia-max) |
| `v2-after-bulletproof-20260422-210113` | after Phase 3 (bulletproof) |
| `v2-after-pricing-p1-20260422-210441` | after Phase 4 (pricing P1, current main) |
| `v2-pricing-final-ready-20260422-213459` | tip of pricing-final/phase-2-6 |

Emergency revert of everything:
```bash
git reset --hard v2-backup-before-merge-20260422-203954
git push github main --force-with-lease   # only if truly necessary
```

Revert pricing-final only after merge to main:
```bash
# Find the merge commit, then:
git revert -m 1 <merge-commit-sha>
git push github main
```

(No `supabase db` rollback is strictly necessary because the migrations
are idempotent / additive. You may disable the Edge Functions from the
dashboard if needed.)
