#!/usr/bin/env bash
# ============================================================================
# Advocat.ee — prod lock (Rule 9)
#
# Mutex on the gh-pages branch so two deploys cannot stomp each other.
#
# Usage:
#   ./scripts/prod-lock.sh acquire <agent-id>
#   ./scripts/prod-lock.sh release <agent-id>
#   ./scripts/prod-lock.sh check
#
# Lock file: `.prod-lock` on the `gh-pages` branch.
# Format:    {agent_id}\n{iso8601_timestamp}\n
# Staleness: older than 30 min => treated as free.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
LOCK_FILE=".prod-lock"
STALE_SECONDS=1800  # 30 min
REMOTE="github"
BRANCH="gh-pages"

die()  { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; exit 1; }
ok()   { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }

sub="${1:-}"
agent="${2:-}"

[[ -n "$sub" ]] || die "usage: prod-lock.sh {acquire|release|check} [agent-id]"

cd "$REPO_ROOT"

# iso8601 in UTC (portable: macOS date + GNU date both accept -u +%FT%TZ)
_now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# convert iso8601 to epoch (macOS BSD date first, fallback to GNU)
_iso_to_epoch() {
  local iso="$1"
  # macOS BSD date
  if date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso" +%s 2>/dev/null; then
    return
  fi
  # GNU date
  date -u -d "$iso" +%s 2>/dev/null || echo 0
}

_mk_worktree() {
  local wt
  wt=$(mktemp -d -t advocat-prodlock.XXXXXX)
  git fetch "$REMOTE" "$BRANCH" >/dev/null 2>&1 || die "git fetch $REMOTE $BRANCH failed"
  git worktree add -f "$wt" "$REMOTE/$BRANCH" >/dev/null 2>&1 || die "git worktree add failed"
  echo "$wt"
}

_cleanup_worktree() {
  local wt="$1"
  git worktree remove --force "$wt" 2>/dev/null || true
  rm -rf "$wt"
}

_read_lock() {
  # prints "holder|ts|epoch|stale(0|1)" if lock exists, nothing otherwise
  local wt="$1"
  if [[ ! -f "$wt/$LOCK_FILE" ]]; then
    return 0
  fi
  local holder ts epoch now stale
  holder=$(sed -n '1p' "$wt/$LOCK_FILE" 2>/dev/null || echo "")
  ts=$(sed -n '2p' "$wt/$LOCK_FILE" 2>/dev/null || echo "")
  [[ -n "$holder" && -n "$ts" ]] || return 0
  epoch=$(_iso_to_epoch "$ts")
  now=$(date -u +%s)
  stale=0
  if [[ "$epoch" -gt 0 ]] && [[ $((now - epoch)) -gt $STALE_SECONDS ]]; then
    stale=1
  fi
  printf "%s|%s|%s|%s\n" "$holder" "$ts" "$epoch" "$stale"
}

cmd_check() {
  local wt info
  wt=$(_mk_worktree)
  trap "_cleanup_worktree '$wt'" EXIT
  info=$(_read_lock "$wt" || true)
  if [[ -z "$info" ]]; then
    echo "free"
    return 0
  fi
  local holder ts stale
  holder=$(echo "$info" | awk -F'|' '{print $1}')
  ts=$(echo "$info" | awk -F'|' '{print $2}')
  stale=$(echo "$info" | awk -F'|' '{print $4}')
  if [[ "$stale" == "1" ]]; then
    echo "free (stale lock from $holder at $ts ignored)"
  else
    echo "held by $holder since $ts"
  fi
}

cmd_acquire() {
  [[ -n "$agent" ]] || die "agent-id required for acquire"
  local wt info
  wt=$(_mk_worktree)
  trap "_cleanup_worktree '$wt'" EXIT

  info=$(_read_lock "$wt" || true)
  if [[ -n "$info" ]]; then
    local holder ts stale
    holder=$(echo "$info" | awk -F'|' '{print $1}')
    ts=$(echo "$info" | awk -F'|' '{print $2}')
    stale=$(echo "$info" | awk -F'|' '{print $4}')
    if [[ "$stale" != "1" ]]; then
      die "prod held by $holder since $ts"
    fi
  fi

  # write new lock
  {
    printf "%s\n" "$agent"
    _now_iso
  } > "$wt/$LOCK_FILE"

  ( cd "$wt" \
      && git add "$LOCK_FILE" \
      && git -c user.email=prod-lock@advocat.ee -c user.name=prod-lock commit -m "prod-lock: acquire by $agent" >/dev/null \
      && git push "$REMOTE" "HEAD:$BRANCH" >/dev/null 2>&1 ) \
    || die "failed to push lock acquire"

  ok "prod lock acquired by $agent"
}

cmd_release() {
  [[ -n "$agent" ]] || die "agent-id required for release"
  local wt info holder
  wt=$(_mk_worktree)
  trap "_cleanup_worktree '$wt'" EXIT

  info=$(_read_lock "$wt" || true)
  if [[ -z "$info" ]]; then
    ok "no lock to release"
    return 0
  fi
  holder=$(echo "$info" | awk -F'|' '{print $1}')
  if [[ "$holder" != "$agent" ]]; then
    die "cannot release: lock held by $holder, not $agent"
  fi

  ( cd "$wt" \
      && git rm -f "$LOCK_FILE" >/dev/null \
      && git -c user.email=prod-lock@advocat.ee -c user.name=prod-lock commit -m "prod-lock: release by $agent" >/dev/null \
      && git push "$REMOTE" "HEAD:$BRANCH" >/dev/null 2>&1 ) \
    || die "failed to push lock release"

  ok "prod lock released by $agent"
}

case "$sub" in
  acquire) cmd_acquire ;;
  release) cmd_release ;;
  check)   cmd_check ;;
  *) die "unknown subcommand: $sub (use acquire|release|check)" ;;
esac
