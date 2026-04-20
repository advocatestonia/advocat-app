#!/usr/bin/env bash
# ============================================================================
# Advocat.ee — build & deploy script (v24.2+)
#
# One script, deterministic, fails-loud. Replaces the ad-hoc process that
# broke prod on Apr 18 and Apr 20 2026.
#
# Usage:
#   ./scripts/build-and-deploy.sh                 # full: build + push gh-pages + deploy functions + smoke
#   ./scripts/build-and-deploy.sh --skip-functions  # skip edge functions (web-only deploy)
#   ./scripts/build-and-deploy.sh --skip-smoke      # skip final prod smoke
#   ./scripts/build-and-deploy.sh --dry-run         # print what would happen, don't push
#
# Requirements (asserted in preflight):
#   - On branch main with clean working tree
#   - SUPABASE_ACCESS_TOKEN in env (`source ~/.zshrc` if using login shell)
#   - .env.prod present with SUPABASE_ANON_KEY and STRIPE_PUBLISHABLE_KEY
#   - Flutter 3.41.6 (or pin your version to match last working build)
#   - supabase CLI installed
#   - git remote `github` exists and points to advocatestonia/advocat-app
# ============================================================================

set -euo pipefail

# -- flags --------------------------------------------------------------------
SKIP_FUNCTIONS=0
SKIP_SMOKE=0
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --skip-functions) SKIP_FUNCTIONS=1 ;;
    --skip-smoke)     SKIP_SMOKE=1 ;;
    --dry-run)        DRY_RUN=1 ;;
    --help|-h)
      grep -E '^#' "$0" | head -30
      exit 0
      ;;
    *) echo "Unknown flag: $arg" >&2; exit 2 ;;
  esac
done

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

log()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m  ⚠\033[0m %s\n" "$*"; }
die()  { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; exit 1; }

# cd to repo root (two levels up if invoked from scripts/)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

# ============================================================================
# 0. PREFLIGHT
# ============================================================================
log "Preflight checks"

# branch
CUR_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")
[[ "$CUR_BRANCH" == "main" ]] || die "Must be on 'main' branch, got '$CUR_BRANCH'"
ok "on branch: main"

# clean worktree (allow staged, forbid unstaged)
if ! git diff --quiet; then
  die "Unstaged changes present — commit or stash first (git diff)"
fi
ok "worktree clean"

# SUPABASE_ACCESS_TOKEN
if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  # try to source from zshrc
  if [[ -f "$HOME/.zshrc" ]]; then
    # shellcheck disable=SC1091
    export SUPABASE_ACCESS_TOKEN=$(grep -oE 'SUPABASE_ACCESS_TOKEN=[^ ]*' "$HOME/.zshrc" 2>/dev/null | head -1 | cut -d= -f2 | tr -d '"')
  fi
fi
[[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]] || die "SUPABASE_ACCESS_TOKEN not set (source ~/.zshrc)"
ok "SUPABASE_ACCESS_TOKEN set (${#SUPABASE_ACCESS_TOKEN} chars)"

# .env.prod
[[ -f ".env.prod" ]] || die ".env.prod missing — copy .env.prod.example and fill"
# assert critical keys have values
grep -qE '^SUPABASE_ANON_KEY=.+' .env.prod || die ".env.prod: SUPABASE_ANON_KEY is empty"
grep -qE '^STRIPE_PUBLISHABLE_KEY=.+' .env.prod || warn ".env.prod: STRIPE_PUBLISHABLE_KEY empty (payments disabled)"
ok ".env.prod has SUPABASE_ANON_KEY"

# .env.prod gitignored
if ! grep -qE '^\.env\.prod($|\s)' .gitignore; then
  die ".env.prod is not in .gitignore — refusing to run"
fi
ok ".env.prod is gitignored"

# toolchain
command -v flutter >/dev/null || die "flutter not installed"
command -v supabase >/dev/null || die "supabase CLI not installed"
command -v git >/dev/null || die "git not installed"
FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
ok "flutter: $FLUTTER_VER"

# remote
git remote get-url github >/dev/null 2>&1 || die "git remote 'github' not configured"
ok "git remote 'github' ok"

# ============================================================================
# 1. BUILD
# ============================================================================
log "Building Flutter web (release, --dart-define-from-file=.env.prod)"

run "flutter clean"
run "flutter pub get"
run "flutter build web --release --dart-define-from-file=.env.prod"

# verify build
[[ -f build/web/main.dart.js ]] || die "build/web/main.dart.js missing after build"
MAIN_SIZE=$(wc -c < build/web/main.dart.js)
ok "main.dart.js built: $MAIN_SIZE bytes"

# sanity: size should be 5-8 MB. If smaller, env vars likely missing.
if [[ $MAIN_SIZE -lt 5000000 || $MAIN_SIZE -gt 8500000 ]]; then
  die "main.dart.js size ($MAIN_SIZE) outside 5-8.5 MB — something's wrong"
fi
ok "size in expected range (5-8.5 MB)"

# smoke: anon key should appear baked in (not for comparison — just presence)
ANON_KEY_VALUE=$(grep -E '^SUPABASE_ANON_KEY=' .env.prod | cut -d= -f2-)
# first 30 chars of anon key JWT — look for it in the bundle
ANON_KEY_HEAD="${ANON_KEY_VALUE:0:30}"
if [[ -n "$ANON_KEY_HEAD" ]] && ! grep -q "$ANON_KEY_HEAD" build/web/main.dart.js; then
  die "SUPABASE_ANON_KEY NOT baked into main.dart.js — build will fail on prod (this is what broke Apr 18+20)"
fi
ok "SUPABASE_ANON_KEY is baked into main.dart.js"

# ============================================================================
# 2. DEPLOY TO gh-pages (preserves landing!)
# ============================================================================
log "Deploying to gh-pages via worktree"

WORKTREE=$(mktemp -d -t advocat-deploy.XXXXXX)
trap 'git worktree remove --force "$WORKTREE" 2>/dev/null || true; rm -rf "$WORKTREE"' EXIT

run "git fetch github gh-pages"
run "git worktree add \"$WORKTREE\" github/gh-pages"

# critical: DO NOT overwrite these landing/static files
# (per commit 06e4d226 — they are preserved byte-for-byte)
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
)

# rsync build/web/ -> worktree, excluding landing
RSYNC_EXCLUDE=()
for f in "${LANDING_FILES[@]}"; do
  RSYNC_EXCLUDE+=(--exclude="$f")
done
run "rsync -av ${RSYNC_EXCLUDE[*]} build/web/ \"$WORKTREE/\""

# commit
cd "$WORKTREE"
if git diff --quiet; then
  warn "No changes to deploy (build identical to current gh-pages)"
else
  BUILD_HASH=$(cd "$REPO_ROOT" && git rev-parse --short HEAD)
  BUILD_VER=$(grep -E '^version:' "$REPO_ROOT/pubspec.yaml" | awk '{print $2}' || echo "unknown")
  run "git add -A"
  run "git commit -m \"deploy: $BUILD_VER build from $BUILD_HASH\""
  run "git push github gh-pages"
  ok "pushed to github/gh-pages"
fi
cd "$REPO_ROOT"

# ============================================================================
# 3. DEPLOY EDGE FUNCTIONS
# ============================================================================
if [[ $SKIP_FUNCTIONS -eq 0 ]]; then
  log "Deploying Supabase Edge Functions"

  FUNCTIONS=(
    claude-proxy
    google-tts
    tts-proxy
    whisper-stt
    check-company
    check-vehicle
    check-ai-quota
    send-email
    stripe-webhook
    create-checkout
    customer-portal
    deadline-reminder
    email-proxy
  )

  for fn in "${FUNCTIONS[@]}"; do
    if [[ -d "supabase/functions/$fn" ]]; then
      run "supabase functions deploy \"$fn\" --project-ref okgnkucgwsytsondrjye --no-verify-jwt"
      ok "$fn deployed"
    else
      warn "$fn source missing; skipping"
    fi
  done
else
  warn "Edge Function deploy skipped (--skip-functions)"
fi

# ============================================================================
# 4. PROD SMOKE TESTS
# ============================================================================
if [[ $SKIP_SMOKE -eq 0 ]]; then
  log "Running prod smoke tests"
  if [[ -x "test/e2e/prod_smoke.sh" ]]; then
    run "test/e2e/prod_smoke.sh"
  else
    warn "test/e2e/prod_smoke.sh not found; running inline basic checks"

    # landing
    CODE=$(curl -s -o /dev/null -w "%{http_code}" https://advocat.ee/)
    [[ "$CODE" == "200" ]] || die "landing returned $CODE"
    ok "advocat.ee/ → 200"

    # app shell
    CODE=$(curl -s -o /dev/null -w "%{http_code}" https://advocat.ee/app.html)
    [[ "$CODE" == "200" ]] || die "app.html returned $CODE"
    ok "advocat.ee/app.html → 200"

    # main.dart.js size
    LIVE_SIZE=$(curl -sI https://advocat.ee/main.dart.js | grep -i '^content-length' | awk '{print $2}' | tr -d '\r')
    if [[ -z "$LIVE_SIZE" || "$LIVE_SIZE" -lt 5000000 || "$LIVE_SIZE" -gt 8500000 ]]; then
      die "prod main.dart.js size ($LIVE_SIZE) outside 5-8.5 MB"
    fi
    ok "advocat.ee/main.dart.js size $LIVE_SIZE (in range)"

    # google-tts CORS
    CODE=$(curl -s -X OPTIONS "https://okgnkucgwsytsondrjye.supabase.co/functions/v1/google-tts" \
      -H "Origin: https://advocat.ee" \
      -H "Access-Control-Request-Method: POST" \
      -o /dev/null -w "%{http_code}")
    [[ "$CODE" =~ ^(200|204)$ ]] || die "google-tts CORS returned $CODE"
    ok "google-tts CORS → $CODE"
  fi
  ok "smoke tests passed"
else
  warn "Smoke tests skipped (--skip-smoke)"
fi

log "Deploy complete."
echo ""
echo "If prod breaks, rollback:  ./scripts/rollback.sh"
