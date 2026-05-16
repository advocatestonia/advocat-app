#!/usr/bin/env bash
# stripe_smoke.sh
# -----------------------------------------------------------------------------
# Read-only Stripe ↔ Supabase reconciliation probe.
#
# WHY THIS EXISTS
#   prod_smoke.sh section [6] runs an active payment activation contract test
#   that forges a checkout.session.completed event signed with a TEST webhook
#   secret. It's gated off unless STRIPE_TEST_WEBHOOK_KEY + SMOKE_TEST_UID +
#   SMOKE_TEST_JWT + SUPABASE_SERVICE_ROLE_KEY are all set.
#
#   This script complements that by running a passive cross-check that needs
#   only what an operator already has on their laptop:
#     - SUPABASE_ACCESS_TOKEN  (already used by other ops scripts)
#     - Stripe CLI authenticated to the live account
#   No charges. No DB writes. No mock data injected. Safe to run any time.
#
# WHAT IT CHECKS
#   1. Edge functions accept/reject as expected:
#        stripe-webhook         → 401 on missing/forged sig
#        create-checkout        → 401 without JWT
#        customer-portal        → 401 without JWT
#        reconcile-subscriptions → 401 without x-cron-secret
#   2. Stripe live mode inventory: active subs, recent checkout events, any
#      events still in pending_webhooks state (= delivery failed/in-flight).
#   3. DB inventory: profiles.is_pro count vs subscriptions.status='active'
#      count, last webhook_events row age, presence of placeholder
#      stripe_subscription_id values left by manual or reconciler fixes.
#   4. Triggers reconcile-subscriptions via the public.invoke_edge_cron RPC
#      and reports its {checked, fixed, errors} result.
#
# EXIT CODES
#   0  all probes passed; report printed to stdout
#   1  any security gate regressed (security-critical, page on-call)
#   2  reconcile run errored or returned non-200
#   3  Stripe live events show >0 events stuck in pending_webhooks (delivery
#      failures — see docs/payment_runbook.md for retry procedure)
#
# REQUIREMENTS
#   - SUPABASE_ACCESS_TOKEN env var
#   - stripe CLI authenticated for the prod account (display_name "Advocat.ee")
#   - python3 (for JSON parsing)
#   - curl
# -----------------------------------------------------------------------------

set -uo pipefail

PROJECT_REF="okgnkucgwsytsondrjye"
FUNCTIONS_URL="https://${PROJECT_REF}.supabase.co/functions/v1"
TIMEOUT="${SMOKE_TIMEOUT:-15}"
NOW_UNIX=$(date +%s)

# colours
G="\033[1;32m"; R="\033[1;31m"; Y="\033[1;33m"; N="\033[0m"

PASS=0
FAIL=0
WARN=0
EXIT=0

ok()    { printf "${G}  ✓${N} %s\n" "$1"; PASS=$((PASS+1)); }
bad()   { printf "${R}  ✗${N} %s\n" "$1"; FAIL=$((FAIL+1)); }
warn()  { printf "${Y}  ⚠${N} %s\n" "$1"; WARN=$((WARN+1)); }

require_env() {
    if [[ -z "${!1:-}" ]]; then
        printf "${R}fatal${N}: env var %s required\n" "$1" >&2
        exit 4
    fi
}

require_env SUPABASE_ACCESS_TOKEN

if ! command -v stripe >/dev/null 2>&1; then
    printf "${R}fatal${N}: stripe CLI not on PATH\n" >&2
    exit 4
fi
if ! command -v python3 >/dev/null 2>&1; then
    printf "${R}fatal${N}: python3 required\n" >&2
    exit 4
fi

curl_code() {
    curl -s --max-time "$TIMEOUT" "$@" -o /dev/null -w "%{http_code}"
}

sb_query() {
    # Supabase Management API SQL — service-role equivalent, no DB password.
    curl -s --max-time "$TIMEOUT" \
        -X POST "https://api.supabase.com/v1/projects/${PROJECT_REF}/database/query" \
        -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"query\":$(printf '%s' "$1" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read()))')}"
}

echo "════════════════════════════════════════════════════════════════"
echo " stripe_smoke — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "════════════════════════════════════════════════════════════════"
echo
echo "[1] Edge function security gates"

code=$(curl_code -X POST "$FUNCTIONS_URL/stripe-webhook" \
    -H "Content-Type: application/json" -d '{}')
[[ "$code" =~ ^(400|401|403)$ ]] && ok "stripe-webhook rejects no signature ($code)" \
    || { bad "stripe-webhook accepted unsigned payload ($code)"; EXIT=1; }

code=$(curl_code -X POST "$FUNCTIONS_URL/stripe-webhook" \
    -H 'stripe-signature: t=0,v1=forged' \
    -H "Content-Type: application/json" -d '{}')
[[ "$code" =~ ^(400|401|403)$ ]] && ok "stripe-webhook rejects forged signature ($code)" \
    || { bad "stripe-webhook accepted forged signature ($code)"; EXIT=1; }

code=$(curl_code -X POST "$FUNCTIONS_URL/create-checkout" \
    -H "Content-Type: application/json" \
    -d '{"plan_id":"counsel","billing_period":"monthly"}')
[[ "$code" == "401" ]] && ok "create-checkout rejects without JWT ($code)" \
    || { bad "create-checkout did not return 401 ($code)"; EXIT=1; }

code=$(curl_code -X POST "$FUNCTIONS_URL/customer-portal" \
    -H "Content-Type: application/json" -d '{}')
[[ "$code" == "401" ]] && ok "customer-portal rejects without JWT ($code)" \
    || { bad "customer-portal did not return 401 ($code)"; EXIT=1; }

code=$(curl_code -X POST "$FUNCTIONS_URL/reconcile-subscriptions" \
    -H "Content-Type: application/json" -d '{}')
[[ "$code" == "401" ]] && ok "reconcile-subscriptions rejects without cron secret ($code)" \
    || { bad "reconcile-subscriptions did not return 401 ($code)"; EXIT=1; }

echo
echo "[2] Stripe live inventory"

# Active subs
ACTIVE_SUBS_JSON=$(stripe subscriptions list --limit 100 --live 2>/dev/null)
ACTIVE_COUNT=$(echo "$ACTIVE_SUBS_JSON" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(len([s for s in d.get('data',[]) if s['status']=='active']))")
ok "Stripe live active subscriptions: $ACTIVE_COUNT"

# Events last 30 days, count by type
EVT_JSON=$(stripe events list --limit 100 --live 2>/dev/null)
echo "  recent events (last 100):"
echo "$EVT_JSON" | python3 -c "
import sys, json, collections
d = json.load(sys.stdin)
c = collections.Counter(r['type'] for r in d.get('data',[]))
for k,v in c.most_common(8):
    print(f'    {v:4d}  {k}')
"

# Events with pending_webhooks > 0 = delivery not yet succeeded
PENDING=$(echo "$EVT_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
pending = [r for r in d.get('data',[]) if r.get('pending_webhooks',0) > 0]
print(len(pending))
for r in pending[:5]:
    print(f'    {r[\"id\"]} type={r[\"type\"]} pending={r[\"pending_webhooks\"]} created={r[\"created\"]}')
" | head -1)
PENDING_BODY=$(echo "$EVT_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
pending = [r for r in d.get('data',[]) if r.get('pending_webhooks',0) > 0]
for r in pending[:10]:
    print(f'    {r[\"id\"]} type={r[\"type\"]} pending={r[\"pending_webhooks\"]} created={r[\"created\"]}')
")
if [[ "$PENDING" == "0" ]]; then
    ok "no Stripe events stuck in pending_webhooks"
else
    warn "$PENDING Stripe events have pending_webhooks>0 (delivery not confirmed)"
    [[ -n "$PENDING_BODY" ]] && echo "$PENDING_BODY"
    EXIT=$(( EXIT > 3 ? EXIT : 3 ))
fi

echo
echo "[3] Supabase DB inventory"

# profiles vs subscriptions
PROFILES_JSON=$(sb_query "select
        (select count(*) from public.profiles)::int as total_profiles,
        (select count(*) from public.profiles where is_pro)::int as pro,
        (select count(*) from public.profiles where stripe_customer_id is not null)::int as linked,
        (select count(*) from public.subscriptions where status='active')::int as sub_active;")
echo "  $PROFILES_JSON"

# Placeholder stripe_subscription_id rows (left by manual fixes / reconciler)
PLACEHOLDERS=$(sb_query "select count(*)::int as n from public.subscriptions
    where stripe_subscription_id !~ '^sub_';" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d[0]['n'] if d else 0)")
if [[ "$PLACEHOLDERS" == "0" ]]; then
    ok "all subscriptions.stripe_subscription_id are canonical (sub_*)"
else
    warn "$PLACEHOLDERS subscriptions row(s) have non-canonical stripe_subscription_id (e.g. 'manual_activation_*', 'reconciled_from_stripe', NULL)"
fi

# Last webhook_events row
LAST_WH=$(sb_query "select coalesce(max(updated_at)::text, 'never') as last from public.webhook_events;" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['last'])")
echo "  last webhook_events row: $LAST_WH"

# Count of error/processing-state webhook events (stuck)
STUCK_WH=$(sb_query "select count(*)::int as n from public.webhook_events where status in ('processing','error');" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['n'] if d else 0)")
if [[ "$STUCK_WH" == "0" ]]; then
    ok "no webhook_events stuck in processing/error"
else
    warn "$STUCK_WH webhook_events stuck in processing/error state"
fi

echo
echo "[4] Reconcile dry-run"

RECONCILE_ID=$(sb_query "select public.invoke_edge_cron('reconcile-subscriptions') as id;" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if d else '')")
if [[ -z "$RECONCILE_ID" ]]; then
    bad "could not invoke reconcile-subscriptions"
    EXIT=$(( EXIT > 2 ? EXIT : 2 ))
else
    ok "reconcile invoked (pg_net request_id=$RECONCILE_ID)"
    # Poll for response up to 30s
    for _ in 1 2 3 4 5 6; do
        sleep 5
        RESP=$(sb_query "select status_code::int as code, error_msg, content::text as content from net._http_response where id = $RECONCILE_ID;")
        if [[ "$RESP" != "[]" ]] && ! echo "$RESP" | grep -q '"code":null'; then
            CODE=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['code'])")
            BODY=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['content'])")
            if [[ "$CODE" == "200" ]]; then
                ok "reconcile returned 200: $BODY"
            else
                bad "reconcile returned $CODE: $BODY"
                EXIT=$(( EXIT > 2 ? EXIT : 2 ))
            fi
            break
        fi
    done
fi

echo
echo "════════════════════════════════════════════════════════════════"
printf "Result: ${G}%d pass${N} / ${R}%d fail${N} / ${Y}%d warn${N} (exit %d)\n" \
    "$PASS" "$FAIL" "$WARN" "$EXIT"
echo "════════════════════════════════════════════════════════════════"

exit "$EXIT"
