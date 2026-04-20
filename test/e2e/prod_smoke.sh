#!/usr/bin/env bash
# ============================================================================
# Advocat.ee — production smoke tests
#
# Runs after every deploy via build-and-deploy.sh. Fails loudly if prod drifts
# from known-good v24.2 state.
#
# Exit codes:
#   0  all checks passed
#   1  one or more critical checks failed
#   2  bad invocation / missing tools
# ============================================================================

set -euo pipefail

PROJECT_REF="okgnkucgwsytsondrjye"
BASE_URL="https://advocat.ee"
FUNCTIONS_URL="https://${PROJECT_REF}.supabase.co/functions/v1"

PASS=0
FAIL=0
FAILURES=()

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

echo "=== Advocat.ee prod smoke test $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo ""

# ---------------------------------------------------------------------------
# 1. landing & app shell
# ---------------------------------------------------------------------------
echo "[1] HTTP endpoints"
check "landing / is 200" \
  "curl -s -o /dev/null -w '%{http_code}' $BASE_URL/" \
  "200"

check "landing contains 'блог' or 'blog'" \
  "curl -s $BASE_URL/ | grep -ciE 'блог|blog' | head -1" \
  "[1-9][0-9]*"

check "app.html is 200" \
  "curl -s -o /dev/null -w '%{http_code}' $BASE_URL/app.html" \
  "200"

check "main.dart.js is 200" \
  "curl -s -o /dev/null -w '%{http_code}' $BASE_URL/main.dart.js" \
  "200"

# 2. main.dart.js size guard (5-8.5 MB — anything smaller means env vars missing)
SIZE=$(curl -sI $BASE_URL/main.dart.js | grep -i '^content-length' | awk '{print $2}' | tr -d '\r')
if [[ -n "$SIZE" && "$SIZE" -ge 5000000 && "$SIZE" -le 8500000 ]]; then
  printf "\033[1;32m  ✓\033[0m %-55s [%s bytes]\n" "main.dart.js size in 5-8.5 MB" "$SIZE"
  PASS=$((PASS+1))
else
  printf "\033[1;31m  ✗\033[0m %-55s [size=%s]\n" "main.dart.js size in 5-8.5 MB" "$SIZE"
  FAIL=$((FAIL+1))
  FAILURES+=("main.dart.js size out of range ($SIZE)")
fi

check "flutter_bootstrap.js is 200" \
  "curl -s -o /dev/null -w '%{http_code}' $BASE_URL/flutter_bootstrap.js" \
  "200"

check "speech.js is 200" \
  "curl -s -o /dev/null -w '%{http_code}' $BASE_URL/speech.js" \
  "200"

echo ""
echo "[2] Edge Functions (CORS probes with Origin: advocat.ee)"

for fn in google-tts tts-proxy whisper-stt claude-proxy check-ai-quota \
          check-company check-vehicle send-email create-checkout \
          customer-portal email-proxy stripe-webhook deadline-reminder; do
  check "$fn CORS OPTIONS" \
    "curl -s -X OPTIONS '$FUNCTIONS_URL/$fn' -H 'Origin: https://advocat.ee' -H 'Access-Control-Request-Method: POST' -o /dev/null -w '%{http_code}'" \
    "^(200|204)$"
done

echo ""
echo "[3] TLS"
TLS_INFO=$(curl -vI $BASE_URL/ 2>&1 | grep -E "subject:|issuer:" | head -2 || true)
if echo "$TLS_INFO" | grep -q "CN=advocat.ee"; then
  printf "\033[1;32m  ✓\033[0m %-55s\n" "TLS cert CN=advocat.ee"
  PASS=$((PASS+1))
else
  printf "\033[1;31m  ✗\033[0m %-55s\n" "TLS cert CN=advocat.ee"
  FAIL=$((FAIL+1))
  FAILURES+=("TLS cert wrong")
fi

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
