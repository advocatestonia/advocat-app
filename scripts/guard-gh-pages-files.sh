#!/usr/bin/env bash
# ============================================================================
# Advocat.ee — gh-pages required-files guard
#
# Usage:
#   ./scripts/guard-gh-pages-files.sh <path-to-gh-pages-worktree>
#
# Asserts every file below exists and is non-empty. Exits 1 with a list of
# offenders if anything is missing or empty.
# ============================================================================

set -euo pipefail

WT="${1:-}"
if [[ -z "$WT" || ! -d "$WT" ]]; then
  echo "usage: guard-gh-pages-files.sh <path-to-gh-pages-worktree>" >&2
  exit 2
fi

REQUIRED=(
  app.html
  landing.html
  landing_v2.html
  speech.js
  flutter_bootstrap.js
  main.dart.js
  favicon.png
  CNAME
  blog/index.html
  blog/logo_shield.png
  demo.html
  og/sample-review.pdf
)

MISSING=()
EMPTY=()

for f in "${REQUIRED[@]}"; do
  p="$WT/$f"
  if [[ ! -e "$p" ]]; then
    MISSING+=("$f")
  elif [[ ! -s "$p" ]]; then
    EMPTY+=("$f")
  fi
done

if [[ ${#MISSING[@]} -gt 0 || ${#EMPTY[@]} -gt 0 ]]; then
  echo "✗ guard-gh-pages-files: required files failed check in $WT" >&2
  if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "  missing:" >&2
    for f in "${MISSING[@]}"; do echo "    - $f" >&2; done
  fi
  if [[ ${#EMPTY[@]} -gt 0 ]]; then
    echo "  empty:" >&2
    for f in "${EMPTY[@]}"; do echo "    - $f" >&2; done
  fi
  exit 1
fi

echo "✓ guard-gh-pages-files: all required files present and non-empty"
