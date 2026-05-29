#!/usr/bin/env bash
# ============================================================================
# Advocat.ee — canary deploy script (OMEGA-BULLETPROOF BP-4)
# ============================================================================
#
# Goal: never push a broken build straight to advocat.ee. Instead:
#
#   1. build
#   2. push to a staging path (advocat.ee/staging/) on the same gh-pages repo
#   3. run prod_smoke.sh against the staging base URL
#   4. if green, promote staging → root (prod)
#   5. re-run prod_smoke.sh against prod
#   6. if prod smoke fails → auto-rollback via rollback.sh
#
# Why a staging path (not a separate domain)?
#   * GitHub Pages only serves one domain per repo.
#   * We can publish /staging/ as an unlinked subfolder, hit it with
#     SMOKE_BASE_URL=https://advocat.ee/staging, and discover the Apr-18
#     class of bugs (missing dart-define, oversize bundle, broken CORS)
#     before touching the customer-facing root.
#
# Usage:
#   ./scripts/canary-deploy.sh                  # full canary
#   ./scripts/canary-deploy.sh --staging-only   # stop after step 3
#   ./scripts/canary-deploy.sh --dry-run        # print, don't push
#
# Env:
#   ROLLBACK_TAG        tag to roll back to if prod smoke fails
#                       (default: v24.2-frozen-2026-04-20)
#   NOTIFY_EMAIL        set to receive "deployed" / "rolled back" mails
#                       (requires `mail` CLI; no-op if missing)
# ============================================================================

set -euo pipefail

# Rule 8: no production deploys 22:00-09:00 Tallinn, no weekends.
# Override with FORCE_DEPLOY_REASON env var.
if [[ -z "${FORCE_DEPLOY_REASON:-}" ]]; then
  TS_LOCAL=$(TZ='Europe/Tallinn' date +%u%H)
  DOW=${TS_LOCAL:0:1}
  HOUR=${TS_LOCAL:1:2}
  HOUR=$((10#$HOUR))
  if [[ "$DOW" -ge 6 ]]; then
    echo "✗ Weekend deploy blocked. Set FORCE_DEPLOY_REASON=\"...\" to override." >&2
    exit 1
  fi
  if [[ "$HOUR" -ge 22 ]] || [[ "$HOUR" -lt 9 ]]; then
    echo "✗ Night deploy blocked (22:00-09:00 Tallinn). Set FORCE_DEPLOY_REASON=\"...\" to override." >&2
    exit 1
  fi
fi

STAGING_ONLY=0
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --staging-only) STAGING_ONLY=1 ;;
    --dry-run)      DRY_RUN=1 ;;
    --help|-h)
      grep -E '^#' "$0" | head -35
      exit 0
      ;;
    *) echo "Unknown flag: $arg" >&2; exit 2 ;;
  esac
done

log()   { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m  ⚠\033[0m %s\n" "$*"; }
die()   { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; exit 1; }

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

notify() {
  local subject="$1"
  local body="$2"
  if [[ -n "${NOTIFY_EMAIL:-}" ]] && command -v mail >/dev/null 2>&1; then
    echo "$body" | mail -s "$subject" "$NOTIFY_EMAIL" || true
  fi
  echo ""
  echo ">>> NOTIFY: $subject"
  echo "$body"
  echo ""
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

# Rule 9: acquire prod lock before touching gh-pages.
PROD_LOCK_AGENT="canary-$$-$(hostname)"
trap './scripts/prod-lock.sh release "'"$PROD_LOCK_AGENT"'" >/dev/null 2>&1 || true' EXIT
./scripts/prod-lock.sh acquire "$PROD_LOCK_AGENT"

ROLLBACK_TAG="${ROLLBACK_TAG:-v24.2-frozen-2026-04-20}"
STAGING_URL="https://advocat.ee/staging"
PROD_URL="https://advocat.ee"

# ---------------------------------------------------------------------------
# 0. preflight (same as build-and-deploy)
# ---------------------------------------------------------------------------
log "Canary preflight"

CUR_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")
[[ "$CUR_BRANCH" == "main" ]] || die "Must be on 'main', got '$CUR_BRANCH'"
ok "on branch: main"

if ! git diff --quiet; then
  die "Unstaged changes present — commit or stash first"
fi
ok "worktree clean"

[[ -f ".env.prod" ]] || die ".env.prod missing"
ok ".env.prod present"

command -v flutter >/dev/null || die "flutter not installed"
command -v curl >/dev/null || die "curl not installed"
command -v supabase >/dev/null || die "supabase CLI not installed"

# ---------------------------------------------------------------------------
# 0. deploy any changed Edge Functions BEFORE the frontend build, so the
#    staging smoke (which hits the same Supabase project as prod) probes the
#    new server-side logic alongside the new client. Skipped when no
#    supabase/functions/*/index.ts has changed since the last gh-pages tip.
# ---------------------------------------------------------------------------
log "Checking for changed Edge Functions"
PROJECT_REF="${SUPABASE_PROJECT_REF:-okgnkucgwsytsondrjye}"
LAST_PROD=$(git rev-parse github/gh-pages 2>/dev/null || echo "")
# gh-pages is an ORPHAN branch (built web assets, no shared history with main),
# so `git merge-base github/gh-pages HEAD` is empty and a three-dot diff
# (LAST_PROD...HEAD) aborts with "no merge base" — silently yielding zero
# changed functions and skipping every edge-fn deploy. Treat "branch missing"
# AND "no merge base" identically: over-deploy ALL functions (safe).
MERGE_BASE=""
if [[ -n "$LAST_PROD" ]]; then
  MERGE_BASE=$(git merge-base github/gh-pages HEAD 2>/dev/null || echo "")
fi
CHANGED_FNS=()
if [[ -z "$LAST_PROD" || -z "$MERGE_BASE" ]]; then
  warn "No merge base with github/gh-pages (orphan branch) — deploying ALL edge functions (safe over-deploy)"
  while IFS= read -r fn; do
    # Only deploy directories (real edge fns). Skip _shared, _tests, import_map.json, IMPORT_MAP_README.md, etc.
    [[ -n "$fn" && -d "supabase/functions/$fn" ]] && CHANGED_FNS+=("$fn")
  done < <(ls supabase/functions/ | grep -v '^_' | sort -u)
else
  CHANGED_FILES=$(git diff --name-only "$MERGE_BASE"..HEAD -- 'supabase/functions/' 2>/dev/null || true)
  # If any _shared module changed, redeploy all functions that import it.
  # _shared changes are invisible to the per-function diff but affect all dependents.
  if echo "$CHANGED_FILES" | grep -q 'supabase/functions/_shared/'; then
    log "_shared module(s) changed — redeploying all dependent functions"
    while IFS= read -r fn; do
      [[ -n "$fn" && -d "supabase/functions/$fn" ]] && CHANGED_FNS+=("$fn")
    done < <(ls supabase/functions/ | grep -v '^_' | sort -u)
  else
    # Extract function names: supabase/functions/<name>/... — skip _shared, top-level files (import_map.json etc).
    if [[ -n "$CHANGED_FILES" ]]; then
      while IFS= read -r line; do
        fn=$(echo "$line" | sed 's|supabase/functions/||' | cut -d/ -f1)
        # Must be: non-empty, not _-prefixed, AND an actual directory (not a top-level file like import_map.json).
        [[ -n "$fn" && "$fn" != _* && -d "supabase/functions/$fn" ]] && CHANGED_FNS+=("$fn")
      done < <(echo "$CHANGED_FILES" | grep 'supabase/functions/' | grep -v '_shared' | sort -u || true)
      # Deduplicate
      if [[ ${#CHANGED_FNS[@]} -gt 0 ]]; then
        IFS=$'\n' read -r -d '' -a CHANGED_FNS < <(printf '%s\n' "${CHANGED_FNS[@]}" | sort -u && printf '\0') || true
      fi
    fi
  fi
fi
if [[ ${#CHANGED_FNS[@]} -eq 0 ]]; then
  ok "No Edge Function changes detected"
else
  for fn in "${CHANGED_FNS[@]}"; do
    log "Deploying Edge Function: $fn"
    run "supabase functions deploy \"$fn\" --project-ref \"$PROJECT_REF\""
  done
  ok "Deployed ${#CHANGED_FNS[@]} Edge Function(s): ${CHANGED_FNS[*]}"
fi

# ---------------------------------------------------------------------------
# 1. build once (we'll rsync twice — to /staging/ then to /)
# ---------------------------------------------------------------------------
log "Building Flutter web (release)"
run "flutter clean"
run "flutter pub get"

# Sentry release tracking (owner-flagged P0). DSN comes from the host env
# so it's never committed; if absent we warn and skip — the app gracefully
# falls back to its existing error_boundary + telemetry_sink path.
SENTRY_DEFINES=""
if [[ -n "${SENTRY_DSN:-}" ]]; then
  SENTRY_RELEASE="${APP_VERSION:-$(git rev-parse --short HEAD)}"
  SENTRY_DEFINES="--dart-define=SENTRY_DSN=${SENTRY_DSN}"
  SENTRY_DEFINES="${SENTRY_DEFINES} --dart-define=SENTRY_ENV=${SENTRY_ENV:-production}"
  SENTRY_DEFINES="${SENTRY_DEFINES} --dart-define=APP_VERSION=${SENTRY_RELEASE}"
  ok "Sentry enabled for build (release=${SENTRY_RELEASE})"
  # TODO(deploy): upload source maps to Sentry post-build for readable
  # stack traces. Tracked as a separate task; see
  # lib/core/services/error_reporter.dart docstring.
else
  warn "SENTRY_DSN not set — building without Sentry (graceful degradation)"
fi

run "flutter build web --release --dart-define-from-file=.env.prod ${SENTRY_DEFINES}"

[[ -f build/web/main.dart.js ]] || die "main.dart.js missing after build"
MAIN_SIZE=$(wc -c < build/web/main.dart.js)
[[ $MAIN_SIZE -ge 5000000 && $MAIN_SIZE -le 10500000 ]] \
  || die "main.dart.js size ($MAIN_SIZE) outside 5-10.5 MB"
ok "main.dart.js OK ($MAIN_SIZE bytes)"

# ---------------------------------------------------------------------------
# 2. push to gh-pages/staging/
# ---------------------------------------------------------------------------
log "Deploying canary to gh-pages:/staging/"

WORKTREE=$(mktemp -d -t advocat-canary.XXXXXX)
trap 'git worktree remove --force "$WORKTREE" 2>/dev/null || true; rm -rf "$WORKTREE"; ./scripts/prod-lock.sh release "'"$PROD_LOCK_AGENT"'" >/dev/null 2>&1 || true' EXIT

run "git fetch github gh-pages"
run "git worktree add \"$WORKTREE\" github/gh-pages"

mkdir -p "$WORKTREE/staging"
run "rsync -av --delete build/web/ \"$WORKTREE/staging/\""

# ----- SPA deep-link stubs (2026-05-27) ------------------------------------
# GitHub Pages serves static files only — a request to /drafts returns 404
# unless we ship a real HTML file at that path. We copy the persistent
# Flutter shell (app.html, kept at gh-pages root and never overwritten by
# rsync) to every SPA deep-link the prod_smoke.sh probes.
#
# Files ending in `.html` are preferred over `<route>/index.html` because
# GitHub Pages issues a 301 from `/drafts` → `/drafts/` when only the
# directory form exists. The smoke uses plain curl without -L, so a 301
# fails the 200 check. With `drafts.html` GH Pages serves `/drafts` → 200
# directly (same trick as `/landing` → `landing.html`).
#
# Keep the route list in sync with web/404.html SPA_ROUTES and
# lib/config/router.dart. Smoke-critical paths must appear here verbatim.
# ---------------------------------------------------------------------------
spa_stub_target() {
  local target="$1"
  local shell="$target/app.html"
  # If the staging dir didn't get an app.html via rsync (build doesn't emit
  # one — it's a persistent gh-pages file), source it from the worktree root.
  if [[ ! -f "$shell" && -f "$WORKTREE/app.html" ]]; then
    cp "$WORKTREE/app.html" "$shell"
  fi
  if [[ ! -f "$shell" ]]; then
    warn "No app.html found in $target or $WORKTREE — skipping SPA stubs"
    return
  fi
  # Smoke-probed deep-links (5 paths) + nested directories so /drafts/new
  # and /vault/add resolve via the .html extension fallback.
  mkdir -p "$target/drafts" "$target/vault"
  cp "$shell" "$target/drafts.html"
  cp "$shell" "$target/vault.html"
  cp "$shell" "$target/contract-review.html"
  cp "$shell" "$target/drafts/new.html"
  cp "$shell" "$target/drafts/00000000-0000-0000-0000-000000000000.html"
  cp "$shell" "$target/vault/add.html"
  ok "SPA stubs written under $target"
}

spa_stub_target "$WORKTREE/staging"

# ----- Sentry DSN substitution (2026-05-29) --------------------------------
# web/_sentry_config.js ships with placeholder tokens
# (__SENTRY_DSN_PLACEHOLDER__ / __APP_VERSION_PLACEHOLDER__). After every
# rsync into a gh-pages worktree we substitute the placeholders in-place
# BEFORE the git commit so the file GitHub Pages serves carries the real
# DSN + release SHA. The source tree under web/ is never touched.
#
# Behaviour matrix:
#   SENTRY_DSN set    → placeholders replaced, Sentry initialises in browser
#   SENTRY_DSN unset  → placeholders preserved, _sentry_init.js exits silent
#                       (landing keeps working — graceful degradation)
#
# Note: this complements the Flutter-side --dart-define=SENTRY_DSN above.
# The Flutter app shell (app.html / main.dart.js) reads from dart-defines;
# the landing HTML pages (index/for-firms/demo) read from the substituted
# _sentry_config.js. Both must use the same DSN env var.
# ---------------------------------------------------------------------------
sentry_substitute() {
  local target_dir="$1"
  local cfg="$target_dir/_sentry_config.js"
  if [[ ! -f "$cfg" ]]; then
    warn "No _sentry_config.js under $target_dir — skipping landing Sentry substitution"
    return
  fi
  if [[ -z "${SENTRY_DSN:-}" ]]; then
    warn "SENTRY_DSN unset — leaving landing placeholders (Sentry stays dormant)"
    return
  fi
  local sha
  sha=$(cd "$REPO_ROOT" && git rev-parse --short HEAD)
  # Escape any literal | in the DSN before piping it through sed's | delim.
  local dsn_safe="${SENTRY_DSN//|/\\|}"
  # macOS sed needs the .bak suffix after -i; GNU sed accepts it too.
  run "sed -i.bak \"s|__SENTRY_DSN_PLACEHOLDER__|$dsn_safe|g\" \"$cfg\""
  run "sed -i.bak \"s|__APP_VERSION_PLACEHOLDER__|$sha|g\" \"$cfg\""
  run "rm -f \"$cfg.bak\""
  ok "Landing Sentry DSN injected → $cfg (release=$sha)"
}

sentry_substitute "$WORKTREE/staging"

cd "$WORKTREE"
git add -A staging/
if git diff --cached --quiet; then
  warn "No changes in staging/ — skipping commit"
else
  BUILD_HASH=$(cd "$REPO_ROOT" && git rev-parse --short HEAD)
  run "git commit -m \"canary: staging build from $BUILD_HASH\""
  run "git push github HEAD:gh-pages"
  ok "staging pushed"
fi
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 3. smoke staging
# ---------------------------------------------------------------------------
log "Running smoke against staging ($STAGING_URL)"
# Wait for GH Pages CDN edges to flush the new staging push. Poll the
# main shell file (staging/app.html) up to 90s before bailing, matching
# the prod-promote CDN poll below.
log "Waiting for GitHub Pages CDN to flush staging (max 90s)..."
for i in $(seq 1 18); do
  PROBE_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$STAGING_URL/drafts.html" 2>/dev/null || echo "000")
  if [[ "$PROBE_CODE" == "200" ]]; then
    ok "CDN ready after ${i}x5s (staging/drafts.html → 200)"
    break
  fi
  sleep 5
done

if SMOKE_BASE_URL="$STAGING_URL" ./test/e2e/prod_smoke.sh; then
  ok "staging smoke green"
else
  die "staging smoke FAILED — NOT promoting to prod. Fix and re-run."
fi

if [[ $STAGING_ONLY -eq 1 ]]; then
  log "--staging-only set — stopping here. Staging URL: $STAGING_URL"
  exit 0
fi

# ---------------------------------------------------------------------------
# 4. promote staging → prod root (same build, write to /)
# ---------------------------------------------------------------------------
log "Promoting canary to prod root"

run "git worktree remove --force \"$WORKTREE\" 2>/dev/null || true"
rm -rf "$WORKTREE"
WORKTREE=$(mktemp -d -t advocat-promote.XXXXXX)
trap 'git worktree remove --force "$WORKTREE" 2>/dev/null || true; rm -rf "$WORKTREE"; ./scripts/prod-lock.sh release "'"$PROD_LOCK_AGENT"'" >/dev/null 2>&1 || true' EXIT

run "git worktree add \"$WORKTREE\" github/gh-pages"

# Preserve landing files (same list as build-and-deploy.sh — NEVER change).
LANDING_FILES=(
  index.html
  landing.html
  landing_v2.html
  landing_polished.html
  landing_premium.html
  landing-v24-backup.html
  blog
  privacy.html
  terms.html
  lawyers.html
  payment-success.html
  payment-cancel.html
  sitemap.xml
  robots.txt
  CNAME
  .nojekyll
  staging           # keep the staging snapshot around
  tools             # SEO lead-magnet calculators (deployed directly to gh-pages)
)
RSYNC_EXCLUDE=()
for f in "${LANDING_FILES[@]}"; do
  RSYNC_EXCLUDE+=(--exclude="$f")
done
run "rsync -av ${RSYNC_EXCLUDE[*]} build/web/ \"$WORKTREE/\""

# SPA deep-link stubs at prod root. Same logic as staging — copies of
# app.html under stable per-route file names so the smoke's curl_code probe
# returns 200 without following redirects.
spa_stub_target "$WORKTREE"

# Inject Sentry DSN into the prod-root copy of _sentry_config.js. Same
# function as staging; safe to skip when SENTRY_DSN is unset (Sentry
# stays dormant in browser, no events sent).
sentry_substitute "$WORKTREE"

# Guard: required gh-pages files must exist and be non-empty before commit.
if [[ $DRY_RUN -eq 0 ]]; then
  "$REPO_ROOT/scripts/guard-gh-pages-files.sh" "$WORKTREE"
fi

cd "$WORKTREE"
if git diff --quiet; then
  warn "No changes to promote (prod already matches this build)"
else
  BUILD_HASH=$(cd "$REPO_ROOT" && git rev-parse --short HEAD)
  run "git add -A"
  run "git commit -m \"deploy: promoted canary $BUILD_HASH\""
  run "git push github HEAD:gh-pages"
  ok "prod updated"
fi
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 5. verify prod smoke + auto-rollback on failure
# ---------------------------------------------------------------------------
log "Running smoke against prod ($PROD_URL)"
# GH Pages can take 30-60s to flush new files to its CDN edges. The
# previous 10s caused false-negative prod smokes (and a spurious auto-
# rollback) on 2026-05-27 when the 5 new SPA stubs hadn't propagated yet.
# Poll /drafts.html (a smoke-critical new file) until it's served, capped
# at 90s, then run the smoke. Falls back to the original sleep if the
# poll itself errors.
log "Waiting for GitHub Pages CDN to flush new build (max 90s)..."
for i in $(seq 1 18); do
  PROBE_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$PROD_URL/drafts.html" 2>/dev/null || echo "000")
  if [[ "$PROBE_CODE" == "200" ]]; then
    ok "CDN ready after ${i}x5s (drafts.html → 200)"
    break
  fi
  sleep 5
done

if SMOKE_BASE_URL="$PROD_URL" ./test/e2e/prod_smoke.sh; then
  ok "prod smoke green"
  notify "Advocat canary deploy OK" \
    "Build $(git rev-parse --short HEAD) promoted to prod. Smoke green."
else
  warn "PROD SMOKE FAILED — rolling back to $ROLLBACK_TAG"
  if [[ -x "scripts/rollback.sh" ]]; then
    if scripts/rollback.sh "$ROLLBACK_TAG"; then
      notify "Advocat auto-rollback triggered" \
        "Prod smoke failed after canary promotion. Rolled back to $ROLLBACK_TAG."
      exit 1
    else
      notify "Advocat auto-rollback FAILED" \
        "Prod smoke failed AND rollback.sh failed. Manual intervention required."
      die "rollback.sh itself failed — manual intervention required"
    fi
  else
    die "scripts/rollback.sh missing — cannot auto-rollback"
  fi
fi

log "Canary deploy complete."
echo ""
echo "Staging was: $STAGING_URL"
echo "Prod now:    $PROD_URL"
echo "Rollback:    ./scripts/rollback.sh $ROLLBACK_TAG"
