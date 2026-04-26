#!/usr/bin/env python3
"""
Stripe webhook signature helper for prod_smoke.sh contract test.

Stripe signs webhooks as `t=<unix_ts>,v1=<hex_hmac_sha256(secret, "t.body")>`.
This script reads the webhook secret from STRIPE_TEST_WEBHOOK_KEY (env), takes
the JSON body on stdin (or as argv[1]), and prints the full signature header
value to stdout.

Usage from bash:
    BODY='{"type":"checkout.session.completed",...}'
    SIG=$(STRIPE_TEST_WEBHOOK_KEY=whsec_test_xxx \
          python3 sign_stripe_event.py <<< "$BODY")
    curl -H "stripe-signature: $SIG" -d "$BODY" .../stripe-webhook

Exit codes:
    0  signature printed to stdout
    1  STRIPE_TEST_WEBHOOK_KEY env var missing
    2  empty body
"""
import hashlib
import hmac
import os
import sys
import time


def main() -> int:
    secret = os.environ.get("STRIPE_TEST_WEBHOOK_KEY", "").strip()
    if not secret:
        print("error: STRIPE_TEST_WEBHOOK_KEY env var not set", file=sys.stderr)
        return 1

    if len(sys.argv) > 1:
        body = sys.argv[1]
    else:
        body = sys.stdin.read()

    if not body:
        print("error: empty body", file=sys.stderr)
        return 2

    # Optional override for tests that need to forge an old timestamp;
    # production smoke runs use "now" so the webhook won't be rejected as
    # stale (the function rejects events older than 300s).
    ts_env = os.environ.get("STRIPE_TEST_TIMESTAMP", "").strip()
    timestamp = int(ts_env) if ts_env else int(time.time())

    signed_payload = f"{timestamp}.{body}".encode("utf-8")
    sig = hmac.new(
        secret.encode("utf-8"),
        signed_payload,
        hashlib.sha256,
    ).hexdigest()

    sys.stdout.write(f"t={timestamp},v1={sig}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
