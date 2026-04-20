#!/usr/bin/env bash
# ============================================================================
# Advocat.ee — rollback script
#
# Resets gh-pages to a known-good tag and re-deploys (optionally) Edge Functions
# from that commit's source.
#
# Usage:
#   ./scripts/rollback.sh                       # rollback to v24.2-frozen-2026-04-20
#   ./scripts/rollback.sh v24.2-frozen-2026-04-20
#   ./scripts/rollback.sh <any-tag-or-sha>
#   ./scripts/rollback.sh --dry-run <tag>
# ============================================================================

set -euo pipefail

log()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }
die()  { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; exit 1; }

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

TAG="${1:-v24.2-frozen-2026-04-20}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

# Resolve tag/sha to a commit SHA that exists
git fetch --tags github 2>/dev/null || true
if ! TARGET_SHA=$(git rev-parse --verify "$TAG^{commit}" 2>/dev/null); then
  die "Tag/commit '$TAG' not found"
fi
ok "Rolling back to: $TAG ($TARGET_SHA)"

# This tag must point at a gh-pages-shape tree (not main).
# Safety check: it must contain main.dart.js and app.html at root.
if ! git ls-tree "$TARGET_SHA" main.dart.js app.html >/dev/null 2>&1; then
  die "Commit $TARGET_SHA does not look like a gh-pages snapshot (missing main.dart.js/app.html at root)"
fi
ok "Target commit is a valid gh-pages snapshot"

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

log "Resetting github/gh-pages to $TARGET_SHA"
WORKTREE=$(mktemp -d -t advocat-rollback.XXXXXX)
trap 'git worktree remove --force "$WORKTREE" 2>/dev/null || true; rm -rf "$WORKTREE"' EXIT

run "git fetch github gh-pages"
run "git worktree add -B gh-pages-rollback \"$WORKTREE\" \"$TARGET_SHA\""
cd "$WORKTREE"
run "git push github HEAD:gh-pages --force-with-lease"
cd "$REPO_ROOT"

ok "gh-pages force-pushed to $TARGET_SHA"

# ----------------------------------------------------------------------------
# Verify
# ----------------------------------------------------------------------------
log "Verifying rollback via prod smoke"
sleep 10   # allow GitHub Pages / Fastly to flush cache a bit
if [[ -x "test/e2e/prod_smoke.sh" ]]; then
  run "test/e2e/prod_smoke.sh"
else
  CODE=$(curl -s -o /dev/null -w "%{http_code}" https://advocat.ee/)
  [[ "$CODE" == "200" ]] || die "prod landing returned $CODE after rollback"
  ok "prod landing returns 200"

  CODE=$(curl -s -o /dev/null -w "%{http_code}" https://advocat.ee/app.html)
  [[ "$CODE" == "200" ]] || die "prod app.html returned $CODE after rollback"
  ok "prod app.html returns 200"
fi

log "Rollback complete."
echo ""
echo "gh-pages is now at: $TARGET_SHA"
echo "NOTE: Edge Functions were NOT redeployed automatically."
echo "If you need to roll those back, check out the matching main SHA and run:"
echo "    ./scripts/build-and-deploy.sh --skip-functions=0 --skip-smoke"
