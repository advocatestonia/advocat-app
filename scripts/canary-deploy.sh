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
CHANGED_FNS=()
if [[ -n "$LAST_PROD" ]]; then
  CHANGED_FILES=$(git diff --name-only "$LAST_PROD"...HEAD -- 'supabase/functions/' 2>/dev/null || true)
  # If any _shared module changed, redeploy all functions that import it.
  # _shared changes are invisible to the per-function diff but affect all dependents.
  if echo "$CHANGED_FILES" | grep -q 'supabase/functions/_shared/'; then
    log "_shared module(s) changed — redeploying all dependent functions"
    while IFS= read -r fn; do
      [[ -n "$fn" ]] && CHANGED_FNS+=("$fn")
    done < <(ls supabase/functions/ | grep -v '^_' | sort -u)
  else
    # Extract function names: supabase/functions/<name>/... — skip _shared
    if [[ -n "$CHANGED_FILES" ]]; then
      while IFS= read -r line; do
        fn=$(echo "$line" | sed 's|supabase/functions/||' | cut -d/ -f1)
        [[ -n "$fn" && "$fn" != _* ]] && CHANGED_FNS+=("$fn")
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
run "flutter build web --release --dart-define-from-file=.env.prod"

[[ -f build/web/main.dart.js ]] || die "main.dart.js missing after build"
MAIN_SIZE=$(wc -c < build/web/main.dart.js)
[[ $MAIN_SIZE -ge 5000000 && $MAIN_SIZE -le 9500000 ]] \
  || die "main.dart.js size ($MAIN_SIZE) outside 5-9.5 MB"
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
sleep 10  # let GitHub Pages flush

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
sleep 10

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
