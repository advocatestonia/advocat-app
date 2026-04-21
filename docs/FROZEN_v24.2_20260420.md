# FROZEN — v24.2 — 2026-04-20

**Git tag:** `v24.2-frozen-2026-04-20` → `06e4d226a4b4a42b3d328d5bccd9889ad93df900` (gh-pages HEAD)
**Frozen at:** 2026-04-20 18:53 EEST, after three prod incidents today that were all
traced back to a single missing `--dart-define=SUPABASE_ANON_KEY`.

## 🔒 DO NOT CHANGE (until v24.3 release)

1. Do not push to `gh-pages` except through `scripts/build-and-deploy.sh`.
2. Do not redeploy the 3 Edge Functions edited at noon (`google-tts v18`, `tts-proxy v14`, `whisper-stt v4`) without first stashing the `anonymousPerMinute: 5` line in `supabase/functions/_shared/auth.ts` — that change is what made Chirp3-HD voices play for demo users.
3. Do not update the Flutter toolchain (currently `3.41.6 stable`, Dart `3.11.4`) without running the full regression suite first. Build size must stay within 5-8.5 MB.
4. Do not add or remove `dart-define` keys in the production build without updating `.env.prod.example` and the preflight checks in `scripts/build-and-deploy.sh`.
5. Do not touch the landing HTML files on `gh-pages` (`index.html`, `landing*.html`, `blog/`, `privacy.html`, `terms.html`, `lawyers.html`, `payment-*.html`, `sitemap.xml`, `robots.txt`, `CNAME`, `.nojekyll`). They are hand-maintained and preserved by the deploy script.

## Captured state

### Deployed assets (sha256, gh-pages @ 06e4d226)

| File | Size | sha256 |
|---|---|---|
| `index.html` | 45,995 | `2eadb67fd5bf1144f4837c114c54dfc7aa78d38aae9d1b919996b3435151c326` |
| `app.html` | 1,872 | `5554c52e5adee4b4823df48159edbff8bdf34a4c19a331441f64b0446b43c590` |
| `main.dart.js` | 6,790,439 | `73677d6efe34cf9a7f28ea1c2c4e7dfc96ce537222457fdab0ea72d52eb8c080` |
| `flutter_bootstrap.js` | 9,975 | `7c7f0e9dfb00704f92430b65ea82eb274b9ea0212a76f070604838905bb4510b` |
| `speech.js` | 15,860 | `4880da2c64ed55beab0c2f40dd5a95c03917f086ea6a58d7131f419e6566f5bb` |
| `flutter.js` | 9,553 | `a483fd28f51ed2fadd0da3fade5b672eba56310d549d736ce62eabf624a6a578` |
| `flutter_service_worker.js` | 784 | `a131df5ca46154cc4eb79044f7f5a14029c2f8bfccf8cef34e3ec3b5a9f5a88c` |

### Edge Functions (Supabase project `okgnkucgwsytsondrjye`)

| Name | Version | Updated (UTC) | CORS OPTIONS |
|---|---|---|---|
| `claude-proxy` | 14 | 2026-04-12 15:01:56 | 200 |
| `create-checkout` | 12 | 2026-04-12 16:56:49 | 200 |
| `tts-proxy` | 14 | **2026-04-20 15:16:58** | 204 |
| `email-proxy` | 5 | 2026-04-10 08:55:11 | 204 |
| `google-tts` | 18 | **2026-04-20 15:16:58** | 204 |
| `stripe-webhook` | 6 | 2026-04-18 13:42:19 | 204 |
| `customer-portal` | 4 | 2026-04-12 12:31:17 | 200 |
| `check-company` | 7 | 2026-04-18 13:42:19 | 204 |
| `deadline-reminder` | 1 | 2026-04-12 17:10:59 | 200 |
| `check-vehicle` | 1 | 2026-04-18 13:42:19 | 204 |
| `send-email` | 1 | 2026-04-18 13:42:19 | 200 |
| `check-ai-quota` | 1 | 2026-04-18 13:42:19 | 200 |
| `whisper-stt` | 4 | **2026-04-20 15:16:58** | 204 |

### SQL migrations

- `001_complete_schema.sql` (18,021 B)
- `002_seed_data.sql` (16,568 B)
- `20260417_ai_usage.sql` (4,405 B)

⚠ Prod DB has drift vs migrations: `deadlines.due_date` column is missing — see P1 in `.consilium-17042026/freeze/T2-auth.md`.

### Dart-define env vars (from `.env.prod`)

Required: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STRIPE_PUBLISHABLE_KEY`, `PRODUCTION=true`
Optional: `STRIPE_MERCHANT_ID` (has default `merchant.com.ailegaldefense`)

No `GOOGLE_CLIENT_ID` as a dart-define — Google OAuth is configured server-side in Supabase Auth.

### Toolchain

- Flutter 3.41.6 stable, Dart 3.11.4
- Supabase CLI 2.84.2

### Scripts & tests in this freeze

| Path | Purpose | Status |
|---|---|---|
| `scripts/build-and-deploy.sh` | Production build + deploy + smoke | executable, syntax-ok |
| `scripts/rollback.sh` | Rollback gh-pages to a tag | executable, syntax-ok |
| `test/e2e/prod_smoke.sh` | 21 prod HTTP/CORS/TLS checks | executable, **21/21 GREEN at freeze** |
| `test/integration/v242_regression_test.dart` | Dart-define wiring assertions | ready to run with `flutter test --dart-define-from-file=.env.prod` |
| `docs/DEPLOY.md` | Deploy playbook | current |
| `.env.prod.example` | Env template | current; `.env.prod` is gitignored |

## Lessons from Apr 18 + Apr 20 incidents

1. **Apr 18 LateInit crash**: `flutter build web` without `--dart-define=SUPABASE_ANON_KEY` → Supabase client never initialized → any code touching `Supabase.instance` throws LateInitializationError. Symptom: chat crashes.
2. **Apr 20 morning OAuth dead**: same root cause, different symptom: `signInWithOAuth()` call against an uninitialized Supabase client silently fails.
3. **Apr 20 noon robot voices**: `google-tts`/`tts-proxy`/`whisper-stt` Edge Functions rejected demo users with 401 (no JWT). Browser fell back to the OS's default web-speech voices. Fix: add `anonymousPerMinute: 5` fallthrough in `_shared/auth.ts`.

All three were **caught zero minutes** by smoke tests because there weren't any. That's fixed now.

## Rollback

```bash
./scripts/rollback.sh v24.2-frozen-2026-04-20
```

This force-pushes `gh-pages` back to the frozen commit after a safety check that the target commit is a valid gh-pages snapshot. Does not touch Edge Functions — if one regressed, redeploy manually from matching `main` SHA.

## Next deploy

```bash
./scripts/build-and-deploy.sh
```

It will refuse to run if: worktree dirty, not on main, `SUPABASE_ACCESS_TOKEN` missing, `.env.prod` missing or anon key empty, `.env.prod` not gitignored. After build it greps `main.dart.js` for the anon key — if missing, aborts **before** push. Then smoke-tests.
