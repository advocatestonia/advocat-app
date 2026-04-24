#!/usr/bin/env bash
#
# install-hooks.sh — Point git at the repo's shared hooks directory.
#
# Run once from the repo root after cloning:
#   ./scripts/install-hooks.sh
#
# This sets core.hooksPath to `.githooks/` (repo-relative). Hooks live under
# version control, so every dev gets the same pre-commit / pre-push checks.

set -euo pipefail

# Resolve repo root from this script's location, so it works from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "✗ Not inside a git repository: ${REPO_ROOT}" >&2
  exit 1
fi

HOOKS_DIR=".githooks"

if [[ ! -d "${HOOKS_DIR}" ]]; then
  echo "✗ Hooks directory not found: ${REPO_ROOT}/${HOOKS_DIR}" >&2
  exit 1
fi

# Ensure hook files are executable (fresh clones on some systems may strip +x).
chmod +x "${HOOKS_DIR}"/* 2>/dev/null || true

git config core.hooksPath "${HOOKS_DIR}"

echo "✓ git core.hooksPath → ${HOOKS_DIR}"
echo "✓ pre-commit  : ${HOOKS_DIR}/pre-commit  (fast tests, ≤60s)"
echo "✓ pre-push    : ${HOOKS_DIR}/pre-push    (analyze + full tests, ≤5min)"
echo ""
echo "To bypass in an emergency: git commit --no-verify   (NOT recommended)"
