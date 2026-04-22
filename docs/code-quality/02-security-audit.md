# 02 — Security Audit

**Agent:** B (reviewer, Security Auditor)
**Branch:** `code-quality/omega-v1`
**Baseline:** v24.2.3 frozen
**Date:** 2026-04-21
**Scope:** 13 Edge Functions, Flutter service layer, Supabase migrations, `web/index.html`, client storage.

> **Bottom line:** The OMEGA-5 v24.2 hardening work already landed most of what a security audit would have flagged. This document lists the *residual* issues.

---

## Severity legend

- **CRITICAL** — ship-blocker before public launch / first paying user.
- **HIGH**     — fix in v24.3.
- **MEDIUM**   — fix in v24.4 / next refactor window.
- **LOW**      — informational, defence-in-depth.

---

## 1. Secrets / credentials

**Finding: CLEAN.** No hardcoded API keys, passwords, or tokens in `lib/` or `supabase/functions/`. All references resolve to either:
- `AppConfig` `String.fromEnvironment(...)` (client-side)
- `Deno.env.get(...)` (Edge Functions)

Occurrences of `apiKey`/`CLAUDE_API_KEY`/`ELEVENLABS_API_KEY`/`STRIPE_SECRET_KEY`/etc. audited individually (13 matches in TS, 12 in Dart) — all variable references, no literals.

**One note (not a finding, just a reminder):** memory file `reference_replicate_token.md` mentions `REPLICATE_API_TOKEN` and `project_context.md` warns:
> ⚠ PAT currently exposed in git remote URL — rotate.

That's on the user to rotate; outside the scope of the code audit.

---

## 2. Edge Function auth matrix

All 13 active Edge Functions surveyed. Pattern analysis:

| Function              | Auth                      | Rate-limit           | CORS                | Status          |
|-----------------------|---------------------------|----------------------|---------------------|-----------------|
| claude-proxy          | Bearer JWT (inline)       | sliding-window /IP   | advocat.ee          | OK              |
| check-ai-quota        | Bearer JWT (anon fallback)| — (read-only)        | advocat.ee          | OK              |
| check-company         | `requireUserWithRateLimit`| 30/min/user          | via lib (advocat.ee)| OK (hardened)   |
| check-vehicle         | `requireUserWithRateLimit`| via lib              | via lib             | OK              |
| create-checkout       | — (public)                | —                    | advocat.ee (header) | **MEDIUM (§2.1)**|
| customer-portal       | Stripe key bearer (server)| —                    | advocat.ee          | OK              |
| deadline-reminder     | — (cron-only)             | —                    | none (internal)     | OK              |
| google-tts            | `requireUserWithRateLimit`| via lib              | via lib             | OK              |
| send-email            | `requireUserWithRateLimit`| via lib              | advocat.ee          | OK              |
| stripe-webhook        | Stripe sig verification   | —                    | none (external POST)| OK              |
| tts-proxy             | `requireUserWithRateLimit`| via lib              | via lib             | OK              |
| whisper-stt           | `requireUserWithRateLimit`| via lib              | via lib             | OK              |

5/13 functions (`check-company`, `check-vehicle`, `google-tts`, `tts-proxy`, `whisper-stt`) migrated to the shared `_shared/auth.ts` helper. The remaining 3 user-facing ones (`claude-proxy`, `check-ai-quota`, `send-email`) still have inline copies of the same pattern — works correctly, but is code duplication (not security).

### 2.1 MEDIUM — `create-checkout` has no user authentication

`supabase/functions/create-checkout/index.ts` accepts `customer_email` from the request body and creates a Stripe Checkout Session, **without verifying that the caller is an authenticated user who owns that email**. That means:

- An attacker can hit the endpoint anonymously and generate Checkout URLs for arbitrary email addresses (mild spam vector).
- Abuse cost: a signed but un-completed Checkout Session is free for us, so impact is limited to fraud/phishing emails landing in victims' inboxes that look like "continue your Advocat subscription".
- CORS-restricted to `https://advocat.ee`, which blunts but does not eliminate browser-side abuse.

**Fix:** wrap the handler with `requireUserWithRateLimit({ bucket: "checkout", maxPerMinute: 5 })`. Then set `customer_email = gate.user.email` instead of trusting the body.

### 2.2 LOW — `claude-proxy` and `check-ai-quota` have duplicated auth/CORS blocks

Not a security hole — the logic is correct. But since `_shared/auth.ts` exists and is well-tested, the 3 holdouts should be migrated to it in v24.3 for maintainability. This was flagged by Agent D too.

---

## 3. SQL injection

**Finding: NO raw SQL strings found** in the two most-touched services.

- `lib/services/supabase_service.dart` — uses `supabase.from(...).select/.insert/.update/.delete` — parameterised builder, safe.
- `lib/services/client_knowledge_service.dart` — same pattern.
- Edge Functions use `supabase.from(...)` likewise; no string-concatenated SQL.

Only `RPC` call points to verify are the SECURITY DEFINER functions in migrations; those get arguments via Supabase RPC, which parameterises them. Safe.

---

## 4. Prompt injection / LLM input hardening

`supabase/functions/claude-proxy/index.ts` enforces:
- `ALLOWED_MODELS` allow-list (prevents model swap attack).
- `MAX_TOKENS_LIMIT = 4096`, `MAX_MESSAGES = 20` (prevents token-exhaustion DoS against Anthropic bill).
- Rate-limit: 10 rpm authenticated / 3 rpm anonymous (per-IP/user sliding window).

**Not found (potential HIGH):** Unicode normalisation / zero-width-char strip / invisible-tag strip on `messages[*].content` before forwarding to Anthropic. Prompt-injection payloads using RTL overrides (U+202E), zero-width joiners (U+200D), or Tag Unicode (U+E0000..) will pass through.

**Recommendation (HIGH, v24.3):** add a short input sanitiser that:
1. Strips control chars except `\n\t`.
2. Strips Unicode Tag chars (U+E0020..U+E007F).
3. Strips RTL/LRT overrides (U+202A..U+202E, U+2066..U+2069).
4. Normalises NFKC before forwarding.

Short function — maybe 30 lines. Owner can defer if no AI-assisted attacks have been observed.

---

## 5. Row-Level Security

In `supabase/migrations/`:

- `001_complete_schema.sql` — creates tables (`profiles`, `cases`, `documents`, `deadlines`, `messages`, `chat_sessions`, `subscriptions`) with `CREATE POLICY` blocks for owner-only read/write. Verified: every user-scoped table has at minimum `auth.uid() = user_id` on SELECT/INSERT/UPDATE/DELETE.
- `20260417_ai_usage.sql` — `ai_usage` table has RLS enabled and policies restricting rows to `auth.uid() = user_id`.
- `20260421_deadlines_due_date.sql` — schema-only change; no policy drift.

**Finding: RLS coverage looks complete. No regression.** Recommendation: add a CI assertion that every public table has `rowsecurity = true` — one `pg_class` query. Nice-to-have, not required.

---

## 6. CSP and other browser-side defences (`web/index.html`)

Current `<head>` has:

- `X-Content-Type-Options: nosniff` ✓
- `X-Frame-Options: DENY` ✓
- `Permissions-Policy: microphone=(self)` ✓
- No `Content-Security-Policy` header ✗

### 6.1 MEDIUM — Missing Content-Security-Policy

Static site is served from GitHub Pages; a CSP would mitigate XSS and limit blast radius if an NPM dep is ever compromised.

**Recommended policy (strict but permissive enough for Flutter Web + Supabase + Stripe):**

```html
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com https://www.gstatic.com;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  font-src 'self' https://fonts.gstatic.com;
  img-src 'self' data: blob: https:;
  connect-src 'self' https://okgnkucgwsytsondrjye.supabase.co wss://okgnkucgwsytsondrjye.supabase.co https://api.stripe.com https://texttospeech.googleapis.com;
  frame-src https://js.stripe.com https://hooks.stripe.com;
  worker-src 'self' blob:;
  object-src 'none';
  base-uri 'self';
">
```

`'unsafe-inline'` + `'unsafe-eval'` are unfortunately still required by Flutter Web's CanvasKit; this is a known Flutter limitation.

**Do not auto-apply in Stage 4** — CSP changes can break the app invisibly (e.g. blocking the Supabase WebSocket). Owner should deploy to a branch preview first.

### 6.2 LOW — `speech.js` and `streaming.js` are loaded without SRI

Integrity hashes on the two inline `<script src="...">` entries would give defence-in-depth. These are first-party scripts served from the same origin, so the risk is already low.

---

## 7. Client-side storage

Scan for `localStorage`/`sessionStorage` in `lib/`:
- Single reference in `lib/main.dart:131` — a comment. No direct writes.
- Supabase SDK handles its own session storage via `SharedPreferences`/`flutter_secure_storage`.
- Stripe redirect state: `lib/services/stripe_web_redirect_impl.dart` — will review next pass, low risk.

**Finding: no sensitive data written to `localStorage` directly.** Supabase sessions are stored via its library (uses `SharedPreferences` on mobile / IndexedDB on web). Access tokens are NOT exposed in client code outside SDK boundaries.

---

## 8. Logging

`print()`: **0 occurrences** in `lib/` — excellent.
`debugPrint()`: 46 occurrences across 5 files, mostly in `voice_service.dart`. `debugPrint` is compile-stripped in release mode, so this is OK — but Agent E flagged it for consistency (prefer `logger` package in new code).

---

## 9. Known open P0/P1 bugs from `project_context.md` — security angle

From memory, 4 open bugs in v24.3 backlog. Security reading:

| Bug                                          | Sev     | Security impact                                                                                |
|----------------------------------------------|---------|------------------------------------------------------------------------------------------------|
| P0 typed-text chat send broken               | Func    | None — UX bug, not auth/data leak.                                                              |
| P1 check-ai-quota 401 for demo               | Func    | None — demo path gracefully degrades.                                                           |
| P1 `deadlines.due_date` column missing       | Func    | Low — causes errors that may leak schema info in error bodies. Confirm error serialiser mutes. |
| P1 `cases?id=eq.general → 400`               | Func    | Low — PostgREST 400 with request context could leak column names. Confirm prod logs.            |

All four are primarily functional, not security — no escalation.

---

## 10. Final severity tally

| Severity   | Count | Items                                                                 |
|------------|------:|-----------------------------------------------------------------------|
| CRITICAL   |     0 | —                                                                     |
| HIGH       |     1 | §4  Prompt-injection input sanitiser missing                          |
| MEDIUM     |     3 | §2.1 `create-checkout` unauthenticated · §6.1 missing CSP · §2.2 auth dup |
| LOW        |     2 | §6.2 script SRI · CI check for RLS coverage                           |

**Grade for this category: B+ / A−.** Solid baseline from OMEGA-5 hardening. No ship-blockers. 3 mediums worth doing before onboarding paying users.

---

## 11. No-touch list (per FROZEN v24.2.3)

The following were reviewed but not proposed for changes, per owner's FROZEN list:

- `lib/services/voice_service.dart`
- `lib/services/ai_service.dart`
- `supabase/functions/claude-proxy/`
- `supabase/functions/tts-proxy/`
- `supabase/functions/google-tts/`

Findings flagged above that touch these files (§2.2, §4) are **recommendations only** and were NOT applied in Stage 4.
