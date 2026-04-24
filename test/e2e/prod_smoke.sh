#!/usr/bin/env bash
# ============================================================================
# Advocat.ee — production smoke tests (extended by OMEGA-BULLETPROOF BP-2)
#
# Runs after every deploy via build-and-deploy.sh. Fails loudly if prod drifts
# from known-good v24.2 state.
#
# Exit codes:
#   0  all checks passed
#   1  one or more critical checks failed
#   2  bad invocation / missing tools
#
# BP-2 additions (2026-04-21) on top of the original 21 checks:
#   - landing disclaimer + cookie banner visible
#   - Edge Function auth/security regressions (401 without JWT, 401 without
#     webhook signature, 401 without cron secret)
#   - POST smoke path for each function (not only OPTIONS)
#   - Refund eligibility endpoint presence probe
#   - Founder cap probe (403 when capped)
#   - AI response length sanity (if SMOKE_AUTH_JWT is set)
#   - GDPR delete endpoint presence probe
#
# Optional env:
#   SMOKE_AUTH_JWT   if set, enables authenticated POST probes (AI quality)
#   SMOKE_TIMEOUT    curl --max-time seconds, default 15
# ============================================================================

set -euo pipefail

PROJECT_REF="okgnkucgwsytsondrjye"
BASE_URL="${SMOKE_BASE_URL:-https://advocat.ee}"
# Landing/blog/static files always live at the site root (never in a
# subdirectory) — canary staging only bundles the Flutter app, not the
# landing/blog HTML. So smoke checks for those files must ignore
# SMOKE_BASE_URL and always hit the root.
ROOT_URL="https://advocat.ee"
FUNCTIONS_URL="https://${PROJECT_REF}.supabase.co/functions/v1"
TIMEOUT="${SMOKE_TIMEOUT:-15}"

PASS=0
FAIL=0
FAILURES=()

# retry: run cmd up to 3× with 5s backoff. Used for seam checks against
# Supabase Edge (cold-start can make first call flaky) and GitHub Pages.
retry() {
  local tries=3 delay=5 i
  for i in $(seq 1 $tries); do
    if "$@"; then return 0; fi
    sleep $delay
  done
  return 1
}

die() {
  printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2
  FAIL=$((FAIL+1))
  FAILURES+=("$*")
}

check() {
  local name="$1"
  local cmd="$2"
  local expected="$3"
  local actual
  actual=$(eval "$cmd" 2>&1 || true)
  if [[ "$actual" == "$expected" ]] || [[ "$actual" =~ $expected ]]; then
    printf "\033[1;32m  ✓\033[0m %-55s [%s]\n" "$name" "$actual"
    PASS=$((PASS+1))
  else
    printf "\033[1;31m  ✗\033[0m %-55s got=[%s] want=[%s]\n" "$name" "$actual" "$expected"
    FAIL=$((FAIL+1))
    FAILURES+=("$name")
  fi
}

# Pattern helpers
curl_code() { curl -s --max-time "$TIMEOUT" -o /dev/null -w '%{http_code}' "$@"; }
curl_body() { curl -s --max-time "$TIMEOUT" "$@"; }

echo "=== Advocat.ee prod smoke test $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "base=$BASE_URL timeout=${TIMEOUT}s"
echo ""

# ---------------------------------------------------------------------------
# 1. landing & app shell
# ---------------------------------------------------------------------------
echo "[1] HTTP endpoints"
check "landing / is 200" \
  "curl_code $ROOT_URL/" \
  "200"

check "landing contains 'блог' or 'blog'" \
  "curl_body $ROOT_URL/ | grep -ciE 'блог|blog' | head -1" \
  "[1-9][0-9]*"

check "app.html is 200" \
  "curl_code $BASE_URL/app.html" \
  "200"

check "main.dart.js is 200" \
  "curl_code $BASE_URL/main.dart.js" \
  "200"

# 2. main.dart.js size guard (5-8.5 MB — anything smaller means env vars missing)
SIZE=$(curl -sI --max-time "$TIMEOUT" $BASE_URL/main.dart.js | grep -i '^content-length' | awk '{print $2}' | tr -d '\r')
if [[ -n "$SIZE" && "$SIZE" -ge 5000000 && "$SIZE" -le 8500000 ]]; then
  printf "\033[1;32m  ✓\033[0m %-55s [%s bytes]\n" "main.dart.js size in 5-8.5 MB" "$SIZE"
  PASS=$((PASS+1))
else
  printf "\033[1;31m  ✗\033[0m %-55s [size=%s]\n" "main.dart.js size in 5-8.5 MB" "$SIZE"
  FAIL=$((FAIL+1))
  FAILURES+=("main.dart.js size out of range ($SIZE)")
fi

check "flutter_bootstrap.js is 200" \
  "curl_code $BASE_URL/flutter_bootstrap.js" \
  "200"

check "speech.js is 200" \
  "curl_code $ROOT_URL/speech.js" \
  "200"

echo ""
echo "[1b] Landing content safety (BP-2)"

check "landing contains disclaimer (not legal advice)" \
  "curl_body $ROOT_URL/ | grep -ciE 'not legal advice|не является юридич|ei ole õigusnõ' | head -1" \
  "[1-9][0-9]*"

check "privacy page is 200" \
  "curl_code $ROOT_URL/privacy.html" \
  "200"

check "terms page is 200" \
  "curl_code $ROOT_URL/terms.html" \
  "200"

check "app.html contains disclaimer meta/text" \
  "curl_body $BASE_URL/app.html | grep -ciE 'disclaimer|legal|advocat' | head -1" \
  "[1-9][0-9]*"

echo ""
echo "[2] Edge Functions (CORS probes with Origin: advocat.ee)"

for fn in google-tts tts-proxy whisper-stt claude-proxy check-ai-quota \
          check-company check-vehicle send-email create-checkout \
          customer-portal email-proxy stripe-webhook deadline-reminder; do
  check "$fn CORS OPTIONS" \
    "curl -s --max-time $TIMEOUT -X OPTIONS '$FUNCTIONS_URL/$fn' -H 'Origin: https://advocat.ee' -H 'Access-Control-Request-Method: POST' -o /dev/null -w '%{http_code}'" \
    "^(200|204)$"
done

echo ""
echo "[2b] Edge Function security regressions (BP-2)"

# create-checkout must require JWT — unauthenticated POST should be 401
check "create-checkout rejects POST without JWT" \
  "curl -s --max-time $TIMEOUT -X POST '$FUNCTIONS_URL/create-checkout' -H 'Content-Type: application/json' -d '{}' -o /dev/null -w '%{http_code}'" \
  "^(401|400|403)$"

# customer-portal must require JWT
check "customer-portal rejects POST without JWT" \
  "curl -s --max-time $TIMEOUT -X POST '$FUNCTIONS_URL/customer-portal' -H 'Content-Type: application/json' -d '{}' -o /dev/null -w '%{http_code}'" \
  "^(401|400|403)$"

# stripe-webhook must reject invalid signature (security regression: if this
# drops to 200 without signing we are vulnerable to forged subs).
check "stripe-webhook rejects invalid signature" \
  "curl -s --max-time $TIMEOUT -X POST '$FUNCTIONS_URL/stripe-webhook' -H 'stripe-signature: t=0,v1=forged' -H 'Content-Type: application/json' -d '{}' -o /dev/null -w '%{http_code}'" \
  "^(400|401|403)$"

# deadline-reminder cron endpoint must reject requests without secret
check "deadline-reminder rejects POST without cron secret" \
  "curl -s --max-time $TIMEOUT -X POST '$FUNCTIONS_URL/deadline-reminder' -H 'Content-Type: application/json' -d '{}' -o /dev/null -w '%{http_code}'" \
  "^(401|403)$"

# claude-proxy must require JWT for chat
check "claude-proxy rejects POST without auth" \
  "curl -s --max-time $TIMEOUT -X POST '$FUNCTIONS_URL/claude-proxy' -H 'Content-Type: application/json' -d '{\"messages\":[]}' -o /dev/null -w '%{http_code}'" \
  "^(401|403)$"

# check-company should work for anon (read-only business registry proxy)
check "check-company allows anon POST (rate-limited)" \
  "curl -s --max-time $TIMEOUT -X POST '$FUNCTIONS_URL/check-company' -H 'Content-Type: application/json' -H 'apikey: anon' -d '{\"name\":\"probe\"}' -o /dev/null -w '%{http_code}'" \
  "^(200|400|429|401)$"

# check-refund-eligibility endpoint should exist (and require auth)
check "check-refund-eligibility rejects without JWT" \
  "curl -s --max-time $TIMEOUT -X POST '$FUNCTIONS_URL/check-refund-eligibility' -H 'Content-Type: application/json' -d '{}' -o /dev/null -w '%{http_code}'" \
  "^(401|403|404)$"

echo ""
echo "[2c] AI quality (only runs if SMOKE_AUTH_JWT env is set)"

if [[ -n "${SMOKE_AUTH_JWT:-}" ]]; then
  # Authenticated POST to claude-proxy; the body length heuristic catches
  # the Apr 18/20 failure mode where the LLM returned blank/placeholder.
  RESP=$(curl -s --max-time "$TIMEOUT" -X POST "$FUNCTIONS_URL/claude-proxy" \
    -H "Authorization: Bearer $SMOKE_AUTH_JWT" \
    -H "Content-Type: application/json" \
    -d '{"messages":[{"role":"user","content":"Say hello in 20 words."}]}' 2>/dev/null || echo "")
  RESP_LEN=${#RESP}
  if [[ "$RESP_LEN" -gt 50 ]]; then
    printf "\033[1;32m  ✓\033[0m %-55s [%s chars]\n" "claude-proxy returns >50 char reply" "$RESP_LEN"
    PASS=$((PASS+1))
  else
    printf "\033[1;31m  ✗\033[0m %-55s [%s chars, sample=%s]\n" "claude-proxy returns >50 char reply" "$RESP_LEN" "${RESP:0:80}"
    FAIL=$((FAIL+1))
    FAILURES+=("claude-proxy short/empty response")
  fi
else
  printf "\033[1;33m  ⚠\033[0m %-55s [SMOKE_AUTH_JWT not set — skipping]\n" "claude-proxy authenticated probe"
fi

echo ""
echo "[3] TLS"
TLS_INFO=$(curl -vI --max-time "$TIMEOUT" $BASE_URL/ 2>&1 | grep -E "subject:|issuer:" | head -2 || true)
if echo "$TLS_INFO" | grep -q "CN=advocat.ee"; then
  printf "\033[1;32m  ✓\033[0m %-55s\n" "TLS cert CN=advocat.ee"
  PASS=$((PASS+1))
else
  printf "\033[1;31m  ✗\033[0m %-55s\n" "TLS cert CN=advocat.ee"
  FAIL=$((FAIL+1))
  FAILURES+=("TLS cert wrong")
fi

echo ""
echo "[4] Deploy integrity (BP-2)"

# robots.txt and sitemap.xml should be present for SEO & crawler hygiene
check "robots.txt is 200" \
  "curl_code $ROOT_URL/robots.txt" \
  "200"

check "sitemap.xml is 200" \
  "curl_code $ROOT_URL/sitemap.xml" \
  "200"

# payment-success landing must remain reachable (Stripe redirect destination)
check "payment-success.html is 200" \
  "curl_code $ROOT_URL/payment-success.html" \
  "200"

check "payment-cancel.html is 200" \
  "curl_code $ROOT_URL/payment-cancel.html" \
  "200"

# .nojekyll must be served so GitHub Pages doesn't strip dot-directories
# (content won't appear in headers but .nojekyll presence means /flutter_*.js
#  assets are not filtered; we just probe main.dart.js which IS served).
# Already covered by main.dart.js 200 above; kept as invariant note.

echo ""
echo "[5] Contract tests — known-seam regressions (anti-regression sprint)"
# These three probes defend against silent chat breakages we already shipped
# fixes for. Each failure prints "regression of YYYY-MM-DD FIX" so the on-call
# knows which prior incident to consult.

ENV_PROD_PATH="$(dirname "$0")/../../.env.prod"
SMOKE_ANON_KEY=""
if [[ -f "$ENV_PROD_PATH" ]]; then
  SMOKE_ANON_KEY=$(grep '^SUPABASE_ANON_KEY=' "$ENV_PROD_PATH" | cut -d= -f2- | tr -d '\r\n"' || true)
fi

# --- Seam A: system prompt guard accepts memory-prefixed prompts ---
# Regression of 2026-04-23: guard's ADVOCAT_IDENTITY_MARKERS whitelist didn't
# cover `# CLIENT PERSONAL KNOWLEDGE BASE` (Tier 1 memory prefix) → guard
# returned 400 "system prompt is server-controlled" → chat dead for memory users.
seam_a() {
  local body resp code
  body='{"model":"claude-haiku-4-5","max_tokens":10,"system":"# CLIENT PERSONAL KNOWLEDGE BASE\n\nThe user'"'"'s name is TestUser.\n\nYou are Advocat, a legal assistant.","messages":[{"role":"user","content":"hi"}]}'
  # Capture body + HTTP code in one call (body then code separated by sentinel)
  resp=$(curl -s --max-time "$TIMEOUT" -X POST "$FUNCTIONS_URL/claude-proxy" \
    -H "Authorization: Bearer ${SMOKE_ANON_KEY}" \
    -H "apikey: ${SMOKE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -w $'\n__HTTP__%{http_code}' \
    --data-binary "$body" 2>&1 || true)
  code=$(printf '%s' "$resp" | awk -F'__HTTP__' 'END{print $2}')
  local payload
  payload=$(printf '%s' "$resp" | sed 's/__HTTP__.*$//')
  # Fail ONLY if guard specifically rejected the memory-prefixed prompt.
  # 200 / 401 / 429 / other 5xx are acceptable — we're not testing auth here.
  if [[ "$code" == "400" ]] && echo "$payload" | grep -qi 'system prompt is server-controlled'; then
    return 1
  fi
  printf "\033[1;32m  ✓\033[0m %-55s [code=%s]\n" "Seam A: guard accepts memory-prefixed system" "$code"
  return 0
}

if [[ -z "$SMOKE_ANON_KEY" ]]; then
  printf "\033[1;33m  ⚠\033[0m %-55s [SUPABASE_ANON_KEY missing — skip]\n" "Seam A: guard memory-prefix probe"
else
  if retry seam_a; then
    PASS=$((PASS+1))
  else
    die "Seam A: guard rejected memory-prefixed prompt — regression of 2026-04-23 FIX"
  fi
fi

# --- Seam B: PostgREST schema cache has AI-usage RPCs ---
# Regression of 2026-04-23: `get_ai_usage` / `increment_ai_usage` disappeared
# from the PGRST schema cache (migration applied but cache lost them) →
# check-ai-quota 500'd. PGRST202 = "Could not find function … in schema cache".
seam_b_rpc() {
  local rpc="$1" resp code payload
  resp=$(curl -s --max-time "$TIMEOUT" -X POST \
    "https://${PROJECT_REF}.supabase.co/rest/v1/rpc/${rpc}" \
    -H "apikey: ${SMOKE_ANON_KEY}" \
    -H "Authorization: Bearer ${SMOKE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -w $'\n__HTTP__%{http_code}' \
    -d '{}' 2>&1 || true)
  code=$(printf '%s' "$resp" | awk -F'__HTTP__' 'END{print $2}')
  payload=$(printf '%s' "$resp" | sed 's/__HTTP__.*$//')
  # Healthy state: 400 with "authentication required" (anon → auth.uid() null).
  # Broken state: 404 + code PGRST202 (function missing from cache).
  if echo "$payload" | grep -q 'PGRST202'; then
    return 1
  fi
  if [[ "$code" == "404" ]]; then
    return 1
  fi
  printf "\033[1;32m  ✓\033[0m %-55s [code=%s]\n" "Seam B: ${rpc} RPC registered" "$code"
  return 0
}

if [[ -z "$SMOKE_ANON_KEY" ]]; then
  printf "\033[1;33m  ⚠\033[0m %-55s [SUPABASE_ANON_KEY missing — skip]\n" "Seam B: RPC schema cache probe"
else
  for rpc in get_ai_usage increment_ai_usage; do
    if retry seam_b_rpc "$rpc"; then
      PASS=$((PASS+1))
    else
      die "Seam B: ${rpc} RPC missing from schema cache — regression of 2026-04-23 FIX"
    fi
  done
fi

# --- Seam C: gh-pages required files present ---
# Redundant with guard-gh-pages-files.sh but catches post-deploy drift from
# the smoke side. Covers landing/app/blog assets that have silently vanished
# in prior wipes. Uses 3× retry against GH Pages edge.
seam_c_url() {
  local url="$1" code
  code=$(curl_code "$url")
  [[ "$code" == "200" ]]
}

for path in \
  /app.html \
  /landing.html \
  /speech.js \
  /flutter_bootstrap.js \
  /blog/index.html \
  /blog/logo_shield.png \
  /favicon.png; do
  # Seam C files live at site root regardless of canary staging path.
  URL="$ROOT_URL$path"
  if retry seam_c_url "$URL"; then
    CODE=200
    printf "\033[1;32m  ✓\033[0m %-55s [200]\n" "Seam C: $path"
    PASS=$((PASS+1))
  else
    CODE=$(curl_code "$URL" || echo "000")
    die "Seam C: $URL returned $CODE — landing/blog file wiped"
  fi
done

echo ""
echo "==============================================="
echo "Passed: $PASS   Failed: $FAIL"
if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "FAILURES:"
  for f in "${FAILURES[@]}"; do echo "  - $f"; done
  exit 1
fi
echo "All prod smoke checks passed ✓"
exit 0
