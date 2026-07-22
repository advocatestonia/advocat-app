# Smart-ID auth spike — SK demo environment (2026-07-17)

**Status: WORKING.** Full RP API **v3** round-trip proven against the free SK
demo environment, from a Deno/Supabase edge function, with cryptographic
verification of the result. Not deployed, not wired to prod auth (by design —
feeds the AUTH-ARCH decision, plan item 1.7).

Code: `supabase/functions/smartid-auth-spike/` (self-contained, no `_shared`
imports, zero external deps — WebCrypto + BigInt only).

---

## 1. How to run

```bash
cd supabase/functions/smartid-auth-spike

# Offline tests (pure logic + live-captured fixtures; deterministic, no network)
deno task test                     # 22 passed | 0 failed | 2 ignored

# Live E2E against SK demo (network)
deno task test:live                # adds: 2 live tests → both pass

# Serve the spike locally
deno run --allow-net index.ts      # plain Deno, listens on :8000
# or through the edge runtime:
supabase functions serve smartid-auth-spike --no-verify-jwt
```

Happy path via HTTP (verified working 2026-07-17, output below is real):

```bash
# Notification flow (auto-OK demo account, no phone):
curl -s -X POST localhost:8000/start -d '{"flow":"notification"}'
#  → {"spikeSessionId":"…","verificationCode":"6331",…}   ← VC shown to user
curl -s "localhost:8000/result?id=<spikeSessionId>"
#  → {"state":"COMPLETE","endResult":"OK","verification":{"ok":true,
#     "signatureValid":true,"certChainValid":true,"certInValidityWindow":true,
#     "certificateLevel":"QUALIFIED","identity":{"etsiIdentifier":"PNOEE-40504040001",
#     "country":"EE","personalCode":"40504040001","givenName":"OK","surname":"TEST",
#     "documentNumber":"PNOEE-40504040001-DEM2-Q"}}}

# Device-link QR flow (mock service plays the phone):
curl -s -X POST localhost:8000/start -d '{"flow":"qr"}'
curl -s -X POST localhost:8000/simulate-app -d '{"id":"<spikeSessionId>"}'   # may need 1 retry
curl -s "localhost:8000/result?id=<spikeSessionId>"
#  → same shape, identity PNOEE-40404040009
```

## 2. API research summary (RP API v3.2.3, current)

| Parameter        | DEMO value                                                                            |
| ---------------- | ------------------------------------------------------------------------------------- |
| Base URL         | `https://sid.demo.sk.ee/smart-id-rp/v3/`                                              |
| relyingPartyUUID | `00000000-0000-4000-8000-000000000000` (public, free)                                 |
| relyingPartyName | `DEMO`                                                                                |
| **schemeName**   | **`smart-id-demo`** (LIVE = `smart-id`) — used inside both HMAC payloads              |
| Mock service     | `https://sid.demo.sk.ee/mock/device-link` (simulates the phone)                       |
| Docs             | https://sk-eid.github.io/smart-id-documentation/ (OpenAPI: `/_/static/RP-API_V3.yml`) |

- Two flow families: **device-link** (QR / Web2App / App2App — recommended,
  phishing-resistant) and **notification** (user types personal code, RP shows
  a 4-digit VC). v3 auth uses signature protocol **ACSP_V2** with
  `rsassa-pss`/SHA-512 (PKCS#1 v1.5 deprecated).
- Init endpoints used: `POST /v3/authentication/notification/etsi/{PNOEE-…}` (needs
  `vcType:"numeric4"`), `POST /v3/authentication/device-link/anonymous`.
  Result: `GET /v3/session/{sessionID}?timeoutMs=…` (long-poll ≤120 s).
- **VC formula** (notification): `int(SHA-256(rpChallenge_raw)[-2:]) mod 10000`,
  zero-padded to 4 — verified against a live session.
- **ACSP_V2 message** (RP must reconstruct + verify signature over it):
  `schemeName|ACSP_V2|serverRandom|rpChallenge|userChallenge|B64(rpName)|B64(brokeredRpName)|B64(SHA256(interactionsB64))|interactionTypeUsed|initialCallbackUrl|flowType`
- **authCode** (device links): `BASE64URL(HMAC-SHA256(b64decode(sessionSecret),
schemeName|ACSP_V2|rpChallenge|B64(rpName)|B64(brokeredRpName)|interactionsB64|initialCallbackUrl|unprotectedDeviceLink))`
- Auto-responding test accounts (no phone): notification `PNOEE-40504040001`
  (→ OK), device-link `PNOEE-40404040009-MOCK-Q` (→ OK via mock), plus
  USER_REFUSED / WRONG_VC / TIMEOUT accounts. Full list:
  https://sk-eid.github.io/smart-id-documentation/test_accounts.html

## 3. What works (proven)

1. **Notification flow E2E live**: init → poll → `OK` → ACSP_V2 signature
   verified → cert chain verified against pinned demo CA → identity extracted.
2. **Device-link QR flow E2E live**: anonymous init → QR link built with
   correct authCode → mock "scans" it → `OK` → same full verification
   (`flowType:"QR"` signed into the message). The authCode implementation is
   byte-proven: the live SK core accepted it (wrong variants end
   `PROTOCOL_FAILURE`).
3. **Cert chain**: end-user cert (RSA-6144, subject
   `serialNumber=PNOEE-…, givenName, surname, C`) verifies under pinned
   **TEST of SK ID Solutions EID-Q 2024E** (ECDSA P-384/SHA-384) — minimal
   in-house X.509/DER parser, no deps.
4. **Negative paths tested offline**: tampered rpChallenge, wrong schemeName,
   non-OK endResult, non-issuer CA pin, expired clock — all rejected.

Test output (verbatim, 2026-07-17):

```
deno task test
ok | 22 passed | 0 failed | 2 ignored (157ms)

SMARTID_SPIKE_LIVE=1 deno test --allow-read --allow-net --allow-env tests/e2e_live_test.ts
LIVE notification flow: auto-OK account → verified identity ... ok (6s)
LIVE device-link QR flow via mock service → verified identity ... ok (10s)
ok | 2 passed | 0 failed (17s)
```

## 4. Traps discovered (cost real debugging time)

1. **`schemeName` differs per environment** and is baked into BOTH HMACs.
   Demo = `smart-id-demo`. With `smart-id` the ACSP_V2 check fails and
   device-link sessions die with `PROTOCOL_FAILURE`. Docs bury this in the
   environments table.
2. **Deno WebCrypto cannot verify imported RSA keys > 4096 bits**
   (`"public key error: SPKI cryptographic key data malformed"`, Deno 2.7.12,
   both RSA-PSS and PKCS1). Smart-ID certs are **RSA-6144** ⇒ WebCrypto alone
   cannot verify Smart-ID signatures in Supabase edge functions. The spike
   ships a manual RFC 8017 RSASSA-PSS verifier (`lib/rsa_pss.ts`, BigInt
   modexp, ~1 ms) cross-validated against WebCrypto at 2048 bits and against a
   live SK signature at 6144. A canary test flips red the day Deno fixes this.
3. **QR `elapsedSeconds` timing is enforced**: links "from the future" (or too
   stale) are silently ignored → session ends `TIMEOUT` with zero diagnostics.
   The demo mock is additionally flaky here; behave like a real rotating QR —
   recompute the link with current elapsedSeconds and re-submit (1 retry
   normally suffices).
4. **`interactions` must stay byte-stable**: the Base64 string sent at init is
   hashed into ACSP_V2 and HMAC'd into authCode. Store the encoded string;
   re-serializing JSON later (key order/whitespace) breaks verification.
5. Notification auth **requires `vcType:"numeric4"`** (v3 addition, easy 400).

## 5. What the demo could NOT simulate

- **Real phone UX** (push arrival, PIN pad, biometrics) — mock only produces
  predefined outcomes. Manual testing with the demo Smart-ID app + a
  registered demo account is possible but not headless.
- **Web2App/App2App callback leg** — mock does GET our `initialCallbackUrl`
  with `userChallengeVerifier`/`sessionSecretDigest`, but that needs a
  publicly reachable HTTPS endpoint; not exercised (QR + notification were).
  Callback verification logic would need its own spike day.
- **Smart-ID Basic (ADVANCED) accounts** — the public DEMO RP UUID has no
  access (SK: write to support@sk.ee).
- **Production trust chain + revocation** (LIVE CAs, OCSP) and **source-IP /
  RP-credential binding** (LIVE returns 401 unless the RP is registered).

## 6. Minting a Supabase session (path B, documented — NOT wired)

After `verification.ok`, identity = `{country, personalCode, givenName, surname}`:

1. `smartid_identities` table: `etsi_identifier (unique) → user_id`.
2. Lookup; if new → `supabase.auth.admin.createUser({ email:
"<uuid>@smartid.local", email_confirm: true, user_metadata: {…identity} })`
   - insert mapping row.
3. Mint session server-side: `admin.generateLink({ type: "magiclink", email })`
   → extract `hashed_token` → `verifyOtp({ type: "email", token_hash })` →
   returns `access_token`/`refresh_token` → hand to the Flutter client
   (same 5-layer activation invariants as the payment flow apply).
4. Needs SERVICE_ROLE key inside the fn; sessions store must move from the
   spike's in-memory Map to a DB table (edge isolates are stateless).

## 7. Effort estimate for the AUTH-ARCH decision

**Path B — own bridge (this spike grown up):**

- Protocol + crypto: **already done and tested** (hardest 60-70% of the work;
  survives as-is — the modules are pure and environment-parameterized).
- Remaining engineering: DB-backed session store + session minting (~1 day
  agent-time), Flutter UI (QR render/rotate, VC screen, polling) (~1-2 days),
  LIVE trust store + revocation decision + secrets wiring (~1 day),
  rate-limiting/abuse + security review (~1 day). **≈ 4-5 agent-days.**
- Non-engineering long pole: **SK commercial contract** — register our own
  relyingPartyUUID/Name (setup + monthly + per-transaction fees, typical lead
  time 1-3 weeks), IP/HTTPS-pinning setup for LIVE.
- Scope caveat: covers **Smart-ID only**. Mobile-ID (different SK API) and
  ID-card (Web eID) would each be a comparable additional bridge.

**Path A — broker (eID Easy / Signicat / similar OIDC aggregator):**

- One integration ⇒ Smart-ID + Mobile-ID + ID-card (+ LV/LT eIDs) at once;
  zero protocol/crypto maintenance; their compliance burden.
- BUT Supabase has no generic OIDC provider slot, so path A **still needs the
  same session-minting glue** from §6 behind a redirect/webhook handler
  (~1-2 agent-days total) — unless we pay for a broker that Supabase natively
  supports (Keycloak detour adds an extra moving part).
- Recurring per-auth fees (order of €0.03-0.15/auth + monthly minimums) vs
  SK-direct fees for path B.

**Spike verdict to feed the decision:** path B is _technically de-risked_ —
nothing in the protocol blocks us on Supabase Edge (the one real blocker,
RSA-6144 vs Deno WebCrypto, is solved in-tree). The decision is now purely
commercial/scope: one eID method direct-with-SK (B) vs three methods + fees
via broker (A). If Mobile-ID + ID-card are must-haves for launch, A wins on
time-to-market; if Smart-ID alone suffices for EE beachhead, B is ~a week of
engineering plus SK paperwork and has no per-auth margin leak.

---

_Spike artifacts: fixtures under `fixtures/` are captured from live demo
sessions (public SK test accounts — no real PII). CA pin:
`lib/sk_demo_ca.ts` (TEST EID-Q 2024E, sha256 in file header)._
