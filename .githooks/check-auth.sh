#!/usr/bin/env bash
#
# check-auth.sh — Wave-1 security audit (2026-05-28) regression guard.
# =============================================================================
#
# Purpose: prevent the `anon_jwt_bypass` regression class from re-emerging.
# Five edge functions (send-email, gmail-label, email-triage, landmark-search,
# claude-proxy) historically shipped one of these anti-patterns:
#
#   * Bare `supabase.auth.getUser(token)` with no role/aud check, which
#     admits forged or anon-key-shaped tokens as authenticated users.
#   * "Accept any non-empty Authorization header" comments (literal
#     pre-f8f6a58 regression).
#   * Per-isolate `Map<>` rate limiters that reset on cold start, defeating
#     the documented cap.
#
# This hook asserts that every `supabase/functions/*/index.ts` either:
#   (a) imports `requireUserWithRateLimit` from `_shared/auth.ts`, OR
#   (b) presents itself as a service-role-only fn (signature: matches the
#       SUPABASE_SERVICE_ROLE_KEY bearer comparison pattern), OR
#   (c) is a cron-only fn (uses `checkCronSecret`), OR
#   (d) is explicitly listed in the allowlist below as a legitimate exception.
#
# A function failing all four checks is presumed regressed. Block the commit.
#
# Bypass in an emergency with: git commit --no-verify  (NOT recommended).
# =============================================================================

set -u

# Locate the supabase/functions root regardless of where the hook fires from.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FN_DIR="${REPO_ROOT}/app/advocat_project/supabase/functions"
if [[ ! -d "${FN_DIR}" ]]; then
  # No edge fns in this tree — nothing to assert.
  exit 0
fi

# Allowlist of fn names that are intentionally exempt (with rationale).
# Keep this list as small as possible; each entry should have a comment
# explaining WHY this fn does not need requireUserWithRateLimit.
ALLOWLIST=(
  # _shared/ is a module dir, not an edge fn. Skip.
  "_shared"
  # Hello-world / health-check style fns that intentionally accept any
  # request and return a constant. Add here on a case-by-case basis.
)

# Patterns that indicate the fn has a legitimate auth gate.
# Either:
#   (a) imports requireUserWithRateLimit
#   (b) compares Authorization header against SUPABASE_SERVICE_ROLE_KEY
#       (internal-call / service-role-only fn)
#   (c) uses checkCronSecret (cron-only fn)
#   (d) explicit `requireUserWithRateLimit` call (defensive — covers
#       fns that re-export the helper from a sibling file).
AUTH_PATTERNS=(
  "requireUserWithRateLimit"
  "SUPABASE_SERVICE_ROLE_KEY"
  "checkCronSecret"
)

FAILED=()
SCANNED=0

# Iterate every immediate subdirectory of FN_DIR. The shape is
# supabase/functions/<fn-name>/index.ts.
for fn_path in "${FN_DIR}"/*/; do
  fn_name="$(basename "${fn_path}")"

  # Skip allowlisted dirs.
  skip=0
  for allowed in "${ALLOWLIST[@]}"; do
    if [[ "${fn_name}" == "${allowed}" ]]; then
      skip=1
      break
    fi
  done
  if [[ ${skip} -eq 1 ]]; then
    continue
  fi

  index_file="${fn_path}index.ts"
  if [[ ! -f "${index_file}" ]]; then
    continue
  fi

  SCANNED=$((SCANNED + 1))

  # Look for ANY of the auth-gate patterns. If none match, the fn is
  # presumed to lack the gate.
  matched=0
  for pat in "${AUTH_PATTERNS[@]}"; do
    if grep -q -F "${pat}" "${index_file}"; then
      matched=1
      break
    fi
  done

  if [[ ${matched} -eq 0 ]]; then
    FAILED+=("${fn_name}")
  fi
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo ""
  echo "✗ check-auth.sh — auth-gate regression detected (Wave-1 audit guard)"
  echo ""
  echo "The following edge functions appear to lack an auth gate. Each MUST"
  echo "either import requireUserWithRateLimit, compare the bearer against"
  echo "SUPABASE_SERVICE_ROLE_KEY (service-role-only), or use checkCronSecret"
  echo "(cron-only). See docs/security_audit_2026-05-28/findings/"
  echo "01_edge_functions_security.md §P0-02, §P1-09, §P1-10, §P1-11 for"
  echo "the regression class history."
  echo ""
  for fn in "${FAILED[@]}"; do
    echo "  - supabase/functions/${fn}/index.ts"
  done
  echo ""
  echo "If one of these is legitimately exempt, add it to the ALLOWLIST in"
  echo "this script with a comment explaining why."
  echo ""
  echo "Bypass: git commit --no-verify (NOT recommended)."
  exit 1
fi

echo "✓ check-auth.sh — scanned ${SCANNED} edge fn(s), all gated."
exit 0
