#!/usr/bin/env bash
# ============================================================================
# Advocat.ee — rollback script (extended by OMEGA-BULLETPROOF BP-4)
#
# Resets gh-pages to a known-good tag, re-runs prod smoke to VERIFY the
# rollback actually restored prod, and optionally records the bad commit
# in a local ledger so it's not re-deployed by mistake.
#
# Usage:
#   ./scripts/rollback.sh                       # rollback to v24.2-frozen-2026-04-20
#   ./scripts/rollback.sh v24.2-frozen-2026-04-20
#   ./scripts/rollback.sh <any-tag-or-sha>
#   ./scripts/rollback.sh --dry-run <tag>
#   ./scripts/rollback.sh --mark-bad <bad-sha> <good-tag>
#   ./scripts/rollback.sh --sql-down <migration-name> <good-tag>
#
# Exit codes:
#   0  rollback done AND prod smoke green
#   1  rollback pushed but prod smoke still failing (manual check needed)
#   2  usage / missing tools / bad tag
#   3  rollback aborted — target tag is not a valid gh-pages snapshot
# ============================================================================

set -euo pipefail

log()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m  ⚠\033[0m %s\n" "$*"; }
die()  { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; exit "${2:-1}"; }

DRY_RUN=0
MARK_BAD=""
SQL_DOWN=""

# Parse flags (positional args follow)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=1; shift ;;
    --mark-bad) MARK_BAD="$2"; shift 2 ;;
    --sql-down) SQL_DOWN="$2"; shift 2 ;;
    --help|-h)  grep -E '^#' "$0" | head -25; exit 0 ;;
    -*)         die "Unknown flag: $1" 2 ;;
    *)          break ;;
  esac
done

TAG="${1:-v24.2-frozen-2026-04-20}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

# ---------------------------------------------------------------------------
# Resolve target
# ---------------------------------------------------------------------------
git fetch --tags github 2>/dev/null || true
if ! TARGET_SHA=$(git rev-parse --verify "$TAG^{commit}" 2>/dev/null); then
  die "Tag/commit '$TAG' not found" 2
fi
ok "Rolling back to: $TAG ($TARGET_SHA)"

# Target must be a gh-pages shape.
if ! git ls-tree "$TARGET_SHA" main.dart.js app.html >/dev/null 2>&1; then
  die "Commit $TARGET_SHA does not look like a gh-pages snapshot" 3
fi
ok "Target commit is a valid gh-pages snapshot"

# ---------------------------------------------------------------------------
# Record the bad commit (BP-4 addition)
# ---------------------------------------------------------------------------
BAD_LEDGER="$REPO_ROOT/docs/ROLLBACK_LOG.txt"
if [[ -n "$MARK_BAD" ]]; then
  if git rev-parse --verify "$MARK_BAD^{commit}" >/dev/null 2>&1; then
    BAD_SHA=$(git rev-parse "$MARK_BAD^{commit}")
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    mkdir -p "$(dirname "$BAD_LEDGER")"
    echo "$TS  bad=$BAD_SHA  rolled-back-to=$TARGET_SHA" >> "$BAD_LEDGER"
    ok "Recorded bad commit in $BAD_LEDGER"
  else
    warn "--mark-bad $MARK_BAD did not resolve; skipping ledger entry"
  fi
fi

# ---------------------------------------------------------------------------
# Force-push gh-pages back to target (use worktree to avoid touching cwd)
# ---------------------------------------------------------------------------
log "Resetting github/gh-pages to $TARGET_SHA"
WORKTREE=$(mktemp -d -t advocat-rollback.XXXXXX)
trap 'git worktree remove --force "$WORKTREE" 2>/dev/null || true; rm -rf "$WORKTREE"' EXIT

run "git fetch github gh-pages"
run "git worktree add -B gh-pages-rollback \"$WORKTREE\" \"$TARGET_SHA\""
cd "$WORKTREE"
run "git push github HEAD:gh-pages --force-with-lease"
cd "$REPO_ROOT"

ok "gh-pages force-pushed to $TARGET_SHA"

# ---------------------------------------------------------------------------
# Optional SQL down (BP-4 addition)
# ---------------------------------------------------------------------------
if [[ -n "$SQL_DOWN" ]]; then
  # .down.sql files live in migrations_down/ (moved out of migrations/ so the
  # CLI no longer parses them); fall back to the old location just in case.
  DOWN_SQL="$REPO_ROOT/supabase/migrations_down/${SQL_DOWN}.down.sql"
  [[ -f "$DOWN_SQL" ]] || DOWN_SQL="$REPO_ROOT/supabase/migrations/${SQL_DOWN}.down.sql"
  if [[ -f "$DOWN_SQL" ]]; then
    log "Running SQL down: $DOWN_SQL"
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "+ supabase db push (dry run)"
    else
      if command -v supabase >/dev/null 2>&1 && [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
        supabase db execute --project-ref okgnkucgwsytsondrjye --file "$DOWN_SQL" \
          || warn "SQL down failed — inspect manually"
      else
        warn "supabase CLI or SUPABASE_ACCESS_TOKEN missing — SQL down NOT applied"
      fi
    fi
  else
    warn "--sql-down $SQL_DOWN: no corresponding ${SQL_DOWN}.down.sql found"
  fi
fi

# ---------------------------------------------------------------------------
# VERIFY rollback actually worked (BP-4 addition)
# ---------------------------------------------------------------------------
log "Verifying rollback via prod smoke"
sleep 10   # allow GitHub Pages / Fastly to flush cache
if [[ -x "test/e2e/prod_smoke.sh" ]]; then
  if run "test/e2e/prod_smoke.sh"; then
    ok "prod smoke GREEN after rollback"
  else
    warn "prod smoke still failing after rollback — manual intervention required"
    echo ""
    echo "Things to check:"
    echo "  - GitHub Pages rebuild delay: wait 2-3 min and re-run smoke manually"
    echo "  - Edge Functions may still be on new versions (smoke probes them too)"
    echo "  - Cached CDN copies — try hard refresh / curl with -H 'Cache-Control: no-cache'"
    exit 1
  fi
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
[[ -n "$MARK_BAD" ]] && echo "Bad commit recorded in: $BAD_LEDGER"
