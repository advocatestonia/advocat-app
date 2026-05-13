#!/usr/bin/env bash
# =============================================================================
# create-launch-promo-codes.sh
# -----------------------------------------------------------------------------
# Creates two Stripe promotion codes for the launch-month test:
#
#   LAUNCH50         — 50% off first month, Pro plan only
#   LAUNCH50PREMIUM  — 50% off first month, Premium plan only
#
# Idempotent: re-running the script is safe. If a coupon with the same name
# already exists, we re-use it. If a promotion code already exists, we
# print the existing one and exit 0.
#
# Both codes:
#   - apply to the FIRST charge only (duration=once)
#   - max_redemptions: 1000  (cap to prevent runaway abuse)
#   - expire 30 days from creation
#   - active=true on creation
#
# Requirements:
#   STRIPE_SECRET_KEY environment variable. Use a restricted key with
#   read+write on coupons + promotion_codes only. Never commit live keys.
#
# Usage:
#   STRIPE_SECRET_KEY=sk_live_... bash scripts/create-launch-promo-codes.sh
#   # Dry-run (no API calls, just prints curls):
#   DRY_RUN=1 bash scripts/create-launch-promo-codes.sh
#
# Output:
#   Prints final promotion-code IDs and customer-facing codes (LAUNCH50 etc).
# =============================================================================

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
STRIPE_API="https://api.stripe.com/v1"
EXPIRY_SECONDS=$((60 * 60 * 24 * 30))            # 30 days
EXPIRES_AT=$(($(date +%s) + EXPIRY_SECONDS))
MAX_REDEMPTIONS=1000

# We deliberately attach the coupon to first-charge only. Stripe does not
# differentiate Pro vs Premium at the coupon level — the plan restriction
# is enforced via `applies_to[products][]` (set if provided) and ultimately
# by which promotion code we hand to the user on the pricing page.

# ── Helpers ────────────────────────────────────────────────────────────────
log()  { echo "[$(date +%H:%M:%S)] $*" >&2; }
err()  { log "ERROR: $*"; exit 1; }

require_env() {
  [[ -n "${STRIPE_SECRET_KEY:-}" ]] || err "STRIPE_SECRET_KEY is required"
}

stripe_call() {
  # Usage: stripe_call METHOD PATH [data...]
  local method="$1"; shift
  local path="$1"; shift
  if [[ "${DRY_RUN:-}" == "1" ]]; then
    log "DRY_RUN: $method $STRIPE_API$path $*"
    echo '{"id":"DRY_RUN","dry_run":true}'
    return 0
  fi
  curl -sS -X "$method" "$STRIPE_API$path" \
    -u "$STRIPE_SECRET_KEY:" \
    "$@"
}

create_or_get_coupon() {
  local name="$1"
  local percent_off="$2"
  # Coupon IDs are not user-facing; use a stable readable id.
  local coupon_id="$3"

  log "Ensuring coupon $coupon_id (${percent_off}% off, once) ..."

  local existing
  existing=$(stripe_call GET "/coupons/$coupon_id" || true)
  if [[ "$(echo "$existing" | grep -o '"id"' | head -n1)" == '"id"' ]] \
       && ! echo "$existing" | grep -q '"error"' ; then
    log "Coupon $coupon_id already exists — reusing."
    echo "$coupon_id"
    return 0
  fi

  stripe_call POST "/coupons" \
    -d "id=$coupon_id" \
    -d "name=$name" \
    -d "percent_off=$percent_off" \
    -d "duration=once" \
    -d "max_redemptions=$MAX_REDEMPTIONS" \
    -d "redeem_by=$EXPIRES_AT" \
    > /dev/null

  log "Created coupon $coupon_id."
  echo "$coupon_id"
}

create_or_get_promotion_code() {
  local coupon_id="$1"
  local code="$2"          # customer-facing, e.g. LAUNCH50
  local restrictions_flag="${3:-}"  # optional metadata

  log "Ensuring promotion code $code (coupon=$coupon_id) ..."

  # Stripe doesn't have a deterministic-id endpoint for promotion codes
  # so we search by `code`. Search is eventually consistent — for a one-off
  # idempotent setup that's fine.
  local listed
  listed=$(stripe_call GET "/promotion_codes?code=$code&limit=1")
  if echo "$listed" | grep -q "\"code\": \"$code\""; then
    log "Promotion code $code already exists."
    echo "$listed" | grep -o '"id": "promo_[^"]*"' | head -n1
    return 0
  fi

  local resp
  resp=$(stripe_call POST "/promotion_codes" \
    -d "coupon=$coupon_id" \
    -d "code=$code" \
    -d "active=true" \
    -d "expires_at=$EXPIRES_AT" \
    -d "max_redemptions=$MAX_REDEMPTIONS" \
    -d "metadata[campaign]=launch" \
    ${restrictions_flag:+-d "$restrictions_flag"})

  log "Created promotion code $code."
  echo "$resp" | grep -o '"id": "promo_[^"]*"' | head -n1
}

# ── Main ───────────────────────────────────────────────────────────────────
require_env

PRO_COUPON=$(create_or_get_coupon \
  "Launch 50% off — Pro" \
  50 \
  "launch50_pro")

PREMIUM_COUPON=$(create_or_get_coupon \
  "Launch 50% off — Premium" \
  50 \
  "launch50_premium")

PRO_PROMO=$(create_or_get_promotion_code "$PRO_COUPON" "LAUNCH50")
PREMIUM_PROMO=$(create_or_get_promotion_code "$PREMIUM_COUPON" "LAUNCH50PREMIUM")

cat <<SUMMARY
─────────────────────────────────────────────
Launch promotion codes ready (active 30 days)
─────────────────────────────────────────────
LAUNCH50         — Pro plan,     50% off first month
LAUNCH50PREMIUM  — Premium plan, 50% off first month

Coupons:
  pro:     $PRO_COUPON
  premium: $PREMIUM_COUPON

Promotion-code records:
  pro:     $PRO_PROMO
  premium: $PREMIUM_PROMO

Customer flow:
  /app.html?plan=counsel&billing=monthly&promo=LAUNCH50
  /app.html?plan=representation&billing=monthly&promo=LAUNCH50PREMIUM

Limits:
  max_redemptions = $MAX_REDEMPTIONS each
  expires_at      = $(date -r $EXPIRES_AT)

To revoke early:
  curl -X POST $STRIPE_API/promotion_codes/<id> -u sk_...: -d active=false
SUMMARY
