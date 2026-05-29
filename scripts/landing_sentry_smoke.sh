#!/usr/bin/env bash
# ============================================================================
# Advocat — landing Sentry integration smoke (2026-05-29)
# ============================================================================
#
# Purpose
#   Catch the four classes of regression that would silently disable
#   Sentry monitoring on the landing pages:
#
#     1) Someone removes the <script src="/_sentry_config.js"> tag from a
#        landing page (so the placeholder never gets injected → no DSN).
#     2) Someone removes the SRI integrity attribute on the CDN tag
#        (CDN tampering / version downgrade not detected).
#     3) Someone removes the PII scrubber (`maskAllText`) from
#        _sentry_init.js (replays leak user PII to Sentry).
#     4) Someone removes browser.sentry-cdn.com from the index CSP
#        (CDN bundle blocked → Sentry undefined → init silent-fail).
#
# Pass criterion: every grep below must match. Any miss → exit 1.
#
# Usage
#   ./scripts/landing_sentry_smoke.sh                 # source-tree check
#   WEB_DIR=build/web ./scripts/landing_sentry_smoke.sh  # post-build check
#
# Wire-up
#   Run from the same place as halt_rail_smoke.sh — pre-deploy guard in
#   scripts/canary-deploy.sh or as a pre-commit hook. NOT a runtime probe
#   (no network calls), so it's safe to run unconditionally and fast.
# ============================================================================
set -euo pipefail

WEB_DIR="${WEB_DIR:-web}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

log()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }
fail() { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; exit 1; }

require_file() {
  local f="$1"
  [[ -f "$f" ]] || fail "missing file: $f"
}

require_grep() {
  local needle="$1" file="$2" label="$3"
  if grep -q -- "$needle" "$file" 2>/dev/null; then
    ok "$label  ($file)"
  else
    fail "$label  ($file — pattern not found: $needle)"
  fi
}

log "Sentry landing-integration smoke — checking $WEB_DIR/"

# ---- Required files exist -------------------------------------------------
require_file "$WEB_DIR/_sentry_config.js"
require_file "$WEB_DIR/_sentry_init.js"
require_file "$WEB_DIR/index.html"
require_file "$WEB_DIR/for-firms.html"
require_file "$WEB_DIR/demo.html"
ok "all 5 required files present"

# ---- _sentry_config.js carries the placeholders (or substituted DSN) ------
# In the source tree the placeholders are present; in a post-deploy build/web
# tree the placeholders may have been sed-replaced. We accept either: the
# DSN identifier "__SENTRY_DSN__" must be assigned to window.
require_grep "window.__SENTRY_DSN__" "$WEB_DIR/_sentry_config.js" \
  "DSN binding present"

# ---- _sentry_init.js has the PII scrubbers --------------------------------
require_grep "maskAllText"      "$WEB_DIR/_sentry_init.js" "replay: maskAllText"
require_grep "blockAllMedia"    "$WEB_DIR/_sentry_init.js" "replay: blockAllMedia"
require_grep "maskAllInputs"    "$WEB_DIR/_sentry_init.js" "replay: maskAllInputs"
require_grep "beforeSend"       "$WEB_DIR/_sentry_init.js" "beforeSend hook wired"
require_grep "beforeBreadcrumb" "$WEB_DIR/_sentry_init.js" "beforeBreadcrumb hook wired"
require_grep "scrubPii"         "$WEB_DIR/_sentry_init.js" "PII scrubber defined"
require_grep "scrubUrl"         "$WEB_DIR/_sentry_init.js" "URL scrubber defined"
require_grep "replaysSessionSampleRate: 0.0" "$WEB_DIR/_sentry_init.js" \
  "idle replays OFF (cost guard)"

# ---- All 3 landing pages reference the 3 Sentry tags ----------------------
for page in index.html for-firms.html demo.html; do
  require_grep "/_sentry_config.js"            "$WEB_DIR/$page" "$page: config tag"
  require_grep "browser.sentry-cdn.com/8.42.0" "$WEB_DIR/$page" "$page: pinned CDN bundle"
  require_grep "integrity=\"sha384-"           "$WEB_DIR/$page" "$page: SRI hash present"
  require_grep "/_sentry_init.js"              "$WEB_DIR/$page" "$page: init tag"
done

# ---- CSP allows Sentry CDN + ingest (index only — others have no CSP meta) -
require_grep "browser.sentry-cdn.com" "$WEB_DIR/index.html" \
  "CSP script-src includes Sentry CDN"
require_grep "ingest.sentry.io" "$WEB_DIR/index.html" \
  "CSP connect-src includes Sentry ingest"

ok "all Sentry integration smoke checks passed"
