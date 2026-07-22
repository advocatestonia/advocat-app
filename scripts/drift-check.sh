#!/usr/bin/env bash
# =============================================================================
# drift-check.sh — git ↔ prod ↔ client drift-detection gate.
# =============================================================================
#
# This is the control that would have caught the June 2026 outage (16 edge
# functions committed to git but HTTP 404 in prod), the zombie functions
# (deployed in prod but deleted from git), and the phantom endpoints (client
# code invoking functions that are not deployed).
#
# Self-calibrating: no hardcoded function counts or names. Four lists:
#
#   LIST A (git)      — function dirs in supabase/functions (excl. _shared,
#                       _tests, any _* dir, non-dirs).
#   LIST B (prod)     — deployed edge functions, read-only:
#                       1) installed `supabase` CLI if available,
#                       2) Supabase Management API with $SUPABASE_ACCESS_TOKEN,
#                       3) `npx supabase` as last resort.
#   LIST C (client)   — function names invoked from lib/ (functions.invoke,
#                       callEdgeFunction, _invoke wrappers, resolved consts)
#                       plus fetch-style .../functions/v1/<name> in lib/ + web/.
#   MIGRATIONS        — local supabase/migrations versions vs applied versions
#                       in prod (supabase_migrations.schema_migrations).
#
# Drift classes reported:
#   1. UNDEPLOYED  = A − B  (committed but 404 in prod — June-2026 outage class)
#   2. ZOMBIE      = B − A  (running in prod, no source in git)
#   3. PHANTOM     = C − B  (client invokes a function not deployed; the subset
#                            also missing from git is flagged separately)
#   4. MIGRATION   = local-not-applied + applied-not-local
#
# Exit codes: 0 = no drift, 1 = drift detected, 2 = configuration/API error.
#
# Usage:
#   scripts/drift-check.sh              # full check against prod (read-only)
#   scripts/drift-check.sh --offline    # local-only lists (A, C, local
#                                       # migrations); no network, no creds
#
# Env: PROJECT_REF (default okgnkucgwsytsondrjye), SUPABASE_ACCESS_TOKEN.
# This script is strictly READ-ONLY against prod.
# =============================================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_REF="${PROJECT_REF:-okgnkucgwsytsondrjye}"
FUNCTIONS_DIR="$ROOT/supabase/functions"
MIGRATIONS_DIR="$ROOT/supabase/migrations"
LIB_DIR="$ROOT/lib"
WEB_DIR="$ROOT/web"

OFFLINE=0
[ "${1:-}" = "--offline" ] && OFFLINE=1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail_config() {
  echo "CONFIG ERROR: $1" >&2
  exit 2
}

json_slugs() {
  # stdin: JSON array of objects with a "slug" (Mgmt API / CLI) field.
  if command -v jq >/dev/null 2>&1; then
    jq -r '.[].slug // empty' 2>/dev/null
  else
    python3 -c 'import json,sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for row in data if isinstance(data, list) else []:
    slug = row.get("slug") or row.get("name")
    if slug: print(slug)'
  fi
}

# -----------------------------------------------------------------------------
# LIST A — functions in git
# -----------------------------------------------------------------------------
[ -d "$FUNCTIONS_DIR" ] || fail_config "functions dir not found: $FUNCTIONS_DIR"
find "$FUNCTIONS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '_*' \
  -exec basename {} \; | sort -u > "$TMP/git_fns.txt"

# -----------------------------------------------------------------------------
# LIST B — functions deployed in prod (READ-ONLY)
# -----------------------------------------------------------------------------
fetch_deployed() {
  # 1) Installed supabase CLI (uses its own login or SUPABASE_ACCESS_TOKEN).
  if command -v supabase >/dev/null 2>&1; then
    if supabase functions list --project-ref "$PROJECT_REF" -o json \
        > "$TMP/cli.json" 2>/dev/null; then
      json_slugs < "$TMP/cli.json" | sort -u > "$TMP/prod_fns.txt"
      [ -s "$TMP/prod_fns.txt" ] && return 0
    fi
  fi
  # 2) Supabase Management API (curl only — works in CI).
  if [ -n "${SUPABASE_ACCESS_TOKEN:-}" ]; then
    local http
    http=$(curl -sS -o "$TMP/api.json" -w '%{http_code}' \
      -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
      "https://api.supabase.com/v1/projects/$PROJECT_REF/functions") || return 1
    [ "$http" = "200" ] || { echo "Management API /functions HTTP $http" >&2; return 1; }
    json_slugs < "$TMP/api.json" | sort -u > "$TMP/prod_fns.txt"
    [ -s "$TMP/prod_fns.txt" ] && return 0
  fi
  # 3) npx supabase as a last resort (slow first run).
  if command -v npx >/dev/null 2>&1; then
    if npx --yes supabase functions list --project-ref "$PROJECT_REF" -o json \
        > "$TMP/npx.json" 2>/dev/null; then
      json_slugs < "$TMP/npx.json" | sort -u > "$TMP/prod_fns.txt"
      [ -s "$TMP/prod_fns.txt" ] && return 0
    fi
  fi
  return 1
}

# -----------------------------------------------------------------------------
# LIST C — functions invoked from the client
# -----------------------------------------------------------------------------
build_client_list() {
  : > "$TMP/client_raw.txt"

  # (a) Literal first argument of invoke wrappers, multi-line aware:
  #     functions.invoke('name'…)  callEdgeFunction('name'…)  _invoke('name'…)
  #     Takes the first path segment ('referral/code' -> 'referral').
  find "$LIB_DIR" -name '*.dart' -print0 2>/dev/null | xargs -0 perl -0777 -ne '
    while (/(?:functions\s*\.\s*invoke|callEdgeFunction|\b_invoke)\s*\(\s*["\x27]([a-z][a-z0-9-]*)(?:\/[^"\x27]*)?["\x27]/gs) {
      print "$1\n";
    }' >> "$TMP/client_raw.txt" 2>/dev/null

  # (b) Identifier / interpolated first argument — collect identifiers, then
  #     resolve them against `IDENT = '<fn-name>'` const declarations in lib/.
  find "$LIB_DIR" -name '*.dart' -print0 2>/dev/null | xargs -0 perl -0777 -ne '
    while (/(?:functions\s*\.\s*invoke|callEdgeFunction|\b_invoke)\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,)]/gs) {
      print "$1\n";
    }
    while (/(?:functions\s*\.\s*invoke|callEdgeFunction|\b_invoke)\s*\(\s*["\x27]\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/gs) {
      print "$1\n";
    }' 2>/dev/null | sort -u > "$TMP/client_idents.txt"

  : > "$TMP/client_unresolved.txt"
  while IFS= read -r ident; do
    [ -n "$ident" ] || continue
    resolved=$(grep -rhoE "\b${ident}[[:space:]]*=[[:space:]]*'[a-z][a-z0-9-]*'" \
      "$LIB_DIR" --include='*.dart' 2>/dev/null \
      | sed -E "s/.*'([a-z][a-z0-9-]*)'/\1/" | sort -u)
    if [ -n "$resolved" ]; then
      printf '%s\n' "$resolved" >> "$TMP/client_raw.txt"
    else
      printf '%s\n' "$ident" >> "$TMP/client_unresolved.txt"
    fi
  done < "$TMP/client_idents.txt"

  # (c) fetch-style URLs .../functions/v1/<name> in lib/ and web/.
  grep -rhoE 'functions/v1/[A-Za-z0-9_-]+' "$LIB_DIR" "$WEB_DIR" 2>/dev/null \
    | sed -E 's|functions/v1/||' >> "$TMP/client_raw.txt"

  sort -u "$TMP/client_raw.txt" | grep -E '^[a-z][a-z0-9-]*$' > "$TMP/client_fns.txt" || true
}

# -----------------------------------------------------------------------------
# Migrations — local versions vs applied versions
# -----------------------------------------------------------------------------
build_local_migrations() {
  [ -d "$MIGRATIONS_DIR" ] || fail_config "migrations dir not found: $MIGRATIONS_DIR"
  find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sql' -exec basename {} .sql \; \
    | sed -E 's/^([0-9]+).*/\1/' | grep -E '^[0-9]+$' | sort -u > "$TMP/local_migrations.txt"
}

fetch_applied_migrations() {
  [ -n "${SUPABASE_ACCESS_TOKEN:-}" ] || return 1
  local http
  http=$(curl -sS -o "$TMP/mig.json" -w '%{http_code}' \
    -X POST "https://api.supabase.com/v1/projects/$PROJECT_REF/database/query" \
    -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"query":"select version from supabase_migrations.schema_migrations order by version;"}') || return 1
  [ "$http" = "200" ] || [ "$http" = "201" ] || { echo "Management API /database/query HTTP $http" >&2; return 1; }
  if command -v jq >/dev/null 2>&1; then
    jq -r '.[].version // empty' < "$TMP/mig.json" | sort -u > "$TMP/applied_migrations.txt"
  else
    python3 -c 'import json,sys
for row in json.load(sys.stdin):
    v = row.get("version")
    if v: print(v)' < "$TMP/mig.json" | sort -u > "$TMP/applied_migrations.txt"
  fi
}

# -----------------------------------------------------------------------------
# Build lists
# -----------------------------------------------------------------------------
build_client_list
build_local_migrations

if [ "$OFFLINE" = "1" ]; then
  echo "=== drift-check (OFFLINE — local lists only, no prod comparison) ==="
  echo "LIST A (git functions):      $(wc -l < "$TMP/git_fns.txt" | tr -d ' ')"
  echo "LIST C (client-invoked):     $(wc -l < "$TMP/client_fns.txt" | tr -d ' ')"
  echo "Local migration versions:    $(wc -l < "$TMP/local_migrations.txt" | tr -d ' ')"
  echo
  echo "--- LIST A ---"; cat "$TMP/git_fns.txt"
  echo "--- LIST C ---"; cat "$TMP/client_fns.txt"
  if [ -s "$TMP/client_unresolved.txt" ]; then
    echo "--- unresolved dynamic invocations (identifiers, informational) ---"
    cat "$TMP/client_unresolved.txt"
  fi
  exit 0
fi

fetch_deployed || fail_config \
  "cannot list deployed functions — need installed supabase CLI login or SUPABASE_ACCESS_TOKEN"
fetch_applied_migrations || fail_config \
  "cannot read applied migrations — need SUPABASE_ACCESS_TOKEN for Management API"

# -----------------------------------------------------------------------------
# Diffs
# -----------------------------------------------------------------------------
comm -23 "$TMP/git_fns.txt"    "$TMP/prod_fns.txt" > "$TMP/undeployed.txt"   # A − B
comm -13 "$TMP/git_fns.txt"    "$TMP/prod_fns.txt" > "$TMP/zombies.txt"      # B − A
comm -23 "$TMP/client_fns.txt" "$TMP/prod_fns.txt" > "$TMP/phantoms.txt"     # C − B
comm -23 "$TMP/phantoms.txt"   "$TMP/git_fns.txt"  > "$TMP/phantoms_nogit.txt"
comm -23 "$TMP/local_migrations.txt" "$TMP/applied_migrations.txt" > "$TMP/mig_pending.txt"
comm -13 "$TMP/local_migrations.txt" "$TMP/applied_migrations.txt" > "$TMP/mig_unknown.txt"

count() { wc -l < "$1" | tr -d ' '; }
print_list() { sed 's/^/    - /' "$1"; }

DRIFT=0

echo "==============================================================="
echo " DRIFT CHECK — project $PROJECT_REF — $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "==============================================================="
echo " LIST A git functions:    $(count "$TMP/git_fns.txt")"
echo " LIST B prod functions:   $(count "$TMP/prod_fns.txt")"
echo " LIST C client-invoked:   $(count "$TMP/client_fns.txt")"
echo " Migrations local/applied: $(count "$TMP/local_migrations.txt") / $(count "$TMP/applied_migrations.txt")"
echo

echo "[1] UNDEPLOYED (in git, NOT deployed — June-2026 outage class): $(count "$TMP/undeployed.txt")"
if [ -s "$TMP/undeployed.txt" ]; then print_list "$TMP/undeployed.txt"; DRIFT=1; fi
echo

echo "[2] ZOMBIES (deployed in prod, NOT in git): $(count "$TMP/zombies.txt")"
if [ -s "$TMP/zombies.txt" ]; then print_list "$TMP/zombies.txt"; DRIFT=1; fi
echo

echo "[3] PHANTOMS (invoked by client, NOT deployed): $(count "$TMP/phantoms.txt")"
if [ -s "$TMP/phantoms.txt" ]; then
  print_list "$TMP/phantoms.txt"
  DRIFT=1
  if [ -s "$TMP/phantoms_nogit.txt" ]; then
    echo "    of which also missing from git (no source at all):"
    print_list "$TMP/phantoms_nogit.txt"
  fi
fi
echo

echo "[4] MIGRATION GHOSTS:"
echo "    local but NOT applied in prod: $(count "$TMP/mig_pending.txt")"
if [ -s "$TMP/mig_pending.txt" ]; then print_list "$TMP/mig_pending.txt"; DRIFT=1; fi
echo "    applied in prod but NOT local: $(count "$TMP/mig_unknown.txt")"
if [ -s "$TMP/mig_unknown.txt" ]; then print_list "$TMP/mig_unknown.txt"; DRIFT=1; fi
echo

if [ -s "$TMP/client_unresolved.txt" ]; then
  echo "[i] Unresolved dynamic invocations (informational, not counted as drift):"
  print_list "$TMP/client_unresolved.txt"
  echo
fi

if [ "$DRIFT" = "1" ]; then
  echo "RESULT: DRIFT DETECTED — see sections above. Exit 1."
  exit 1
fi
echo "RESULT: no drift. git == prod == client == migrations. Exit 0."
exit 0
