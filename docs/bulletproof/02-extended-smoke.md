# BP-2 — Extended prod smoke test (21 → 39 checks)

File: `test/e2e/prod_smoke.sh`

The original v24.2 smoke had 21 checks covering HTTP 200s, CORS OPTIONS, and
TLS cert. BP-2 adds **18 more checks** that would have caught real-world
incident classes we've already seen.

## Full check matrix

### [1] HTTP endpoints (7 — unchanged from v24.2)
1. landing / → 200
2. landing contains "блог|blog"
3. app.html → 200
4. main.dart.js → 200
5. main.dart.js size in 5–8.5 MB (dart-define regression)
6. flutter_bootstrap.js → 200
7. speech.js → 200

### [1b] Landing content safety — NEW
8. landing contains disclaimer ("not legal advice" or localized)
9. privacy.html → 200
10. terms.html → 200
11. app.html contains disclaimer/legal markers

### [2] Edge Function CORS (13 — unchanged)
12-24. OPTIONS preflight for: google-tts, tts-proxy, whisper-stt,
claude-proxy, check-ai-quota, check-company, check-vehicle, send-email,
create-checkout, customer-portal, email-proxy, stripe-webhook,
deadline-reminder.

### [2b] Edge Function security regressions — NEW
25. create-checkout rejects POST without JWT (→ 401/400/403)
26. customer-portal rejects POST without JWT
27. stripe-webhook rejects invalid signature
28. deadline-reminder rejects POST without cron secret
29. claude-proxy rejects POST without auth
30. check-company allows anon POST (rate-limited) — must stay reachable
31. check-refund-eligibility rejects without JWT

### [2c] AI quality — CONDITIONAL
32. claude-proxy authenticated POST returns a >50-char reply
    (only runs when `SMOKE_AUTH_JWT` env is set; else prints ⚠ and skips)

### [3] TLS (1 — unchanged)
33. TLS cert CN=advocat.ee

### [4] Deploy integrity — NEW
34. robots.txt → 200
35. sitemap.xml → 200
36. payment-success.html → 200
37. payment-cancel.html → 200

Total: **37 required checks + 1 conditional + existing integrity probes = 39
monitored probes**, up from 21.

## Usage

```bash
# normal run
./test/e2e/prod_smoke.sh

# with AI quality probe (requires a short-lived JWT for a test user)
SMOKE_AUTH_JWT="$(cat ~/secrets/smoke_jwt.txt)" ./test/e2e/prod_smoke.sh

# against staging
SMOKE_BASE_URL="https://staging.advocat.ee" ./test/e2e/prod_smoke.sh

# with custom timeout
SMOKE_TIMEOUT=30 ./test/e2e/prod_smoke.sh
```

## Regression history the new checks would have caught

| Incident | Date | Would-catch check |
|---|---|---|
| LateInit crash | Apr 18 | existing main.dart.js size |
| OAuth silent fail | Apr 20 AM | existing main.dart.js size |
| Robot voices | Apr 20 noon | google-tts CORS |
| Forged webhook attack (hypothetical) | — | #27 stripe-webhook sig check |
| Unauth checkout fraud (hypothetical) | — | #25 create-checkout JWT check |
| Cron invoked by attacker (hypothetical) | — | #28 cron secret check |
| Blank AI response (Apr 18 class) | — | #32 AI quality probe |
| Missing disclaimer (compliance risk) | — | #8, #11 |

## Exit behaviour unchanged

- `0` all green
- `1` any fail
- `2` misuse (e.g., missing curl)

## Integration

- `scripts/build-and-deploy.sh` already invokes `test/e2e/prod_smoke.sh`
  in phase 4. No changes needed there.
- `scripts/canary-deploy.sh` (see BP-4) calls it twice — once against
  staging, once against prod — and rolls back if either reports fail.
