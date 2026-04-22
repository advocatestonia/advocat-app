# Founder's Beta pricing + refund — FINAL (in progress)

**Branch:** `feature/founder-beta-pricing`
**Started:** 2026-04-22
**Status:** Phase 1 (Foundation) COMPLETE. Phases 2–5 remaining, see below.
**Owner:** aiplacest@gmail.com (Dmitri / Sofia Sulga)

---

## 1. Scope confirmed by owner (2026-04-21)

- **Basic €14.99/mo flat** (no intro discount, no Pro tier in UI for now).
- **Refund:** 14 days OR 7 AI responses — whichever comes first.
- **Consent modal** on first AI session with Art. 16(m) waiver copy.
- **Founder's Beta v1.0** badge, 25-user cap first month.

---

## 2. What shipped in Phase 1 (this session)

4 commits on `feature/founder-beta-pricing`, all green, no regression.

### 2.1 Commit `d34be75` — pure Dart policy
- `lib/services/refund_eligibility.dart` (new)
- `test/services/refund_eligibility_test.dart` (new, 14 tests)
- Pure evaluator: `RefundPolicy.evaluate({subscribedAt, messagesUsed, now})`
  returns `RefundEvaluation { eligible, reason, deadline, messagesRemaining }`.
- `reason` ∈ `{eligible, deadlinePassed, messageLimitReached}`.
- Constants: `messageCap = 7`, `withdrawalDays = 14`.
- Boundary tests: microsecond past 14d, negative clock skew, both-fail precedence.

### 2.2 Commit `174475c` — shared Deno policy (contract)
- `supabase/functions/_shared/refund_policy.ts` (new)
- `supabase/functions/_shared/__tests__/refund_policy_test.ts` (new, 10 tests)
- Mirrors Dart side 1:1 so Edge Functions and client use the same rule.
- Exports: `evaluateRefund`, `computeDeadline`, `MESSAGE_CAP`, `WITHDRAWAL_DAYS`.

### 2.3 Commit `c8007d7` — 5 idempotent migrations
All files under `supabase/migrations/`, all use `IF NOT EXISTS` /
`pg_constraint` / `pg_policies` guards. Safe to re-apply.

| File | Purpose |
|---|---|
| `20260422_refund_eligibility.sql` | `alter table subscriptions` add `refund_eligible`, `refund_deadline`, `messages_used_count`, `first_message_at` + nonneg check + backfill |
| `20260422_increment_message_count.sql` | SECURITY DEFINER RPC atomic `++ messages_used_count` + lazy `first_message_at` + auto-flip `refund_eligible=false` at 7 |
| `20260422_refund_consents.sql` | Audit log table for CRD Art. 16(m) waivers (user_id + ip_hash + user_agent) |
| `20260422_beta_cap.sql` | `app_config` KV store, seeded with `beta_cap = {max_paying_users:25, active:true, badge_text:"Founder's Beta v1.0"}` |
| `20260422_waitlist.sql` | `waitlist(email unique, source, notified_at)` for beta-cap overflow |

**Owner action to deploy:** `supabase db push` (reviews every `IF NOT
EXISTS` first). No destructive operations; running twice is a no-op.

### 2.4 Commit `0734b0e` — check-refund-eligibility Edge Function
- `supabase/functions/check-refund-eligibility/index.ts` (new)
- `supabase/functions/check-refund-eligibility/__tests__/eligibility_test.ts` (new, 10 tests)
- Read-only endpoint, JWT gate + rate-limit 10/min, imports shared policy.
- Response: `{ eligible, reason, deadline, messages_used, messages_remaining, subscription_id }`.
- 404 for free-tier users (no active subscription).

---

## 3. Regression snapshot

| Suite | Before | After | Delta |
|---|---|---|---|
| `flutter test` | 1181 | **1195** | +14 |
| `deno test --allow-all` (supabase/functions) | 98 | **118** | +20 |
| `flutter analyze` | clean | (not re-run, additive-only changes) | — |

All tests green. Zero files modified outside new feature scope.

---

## 4. What's NOT done yet (Phases 2–5)

The task brief covers 11 work areas. The remaining 7 were not attempted in
this session due to two reasons:

1. **Parallel agents kept switching git branches** under my feet (reflog
   shows `feature/estonia-max`, `safety/bulletproof`, `fix/estonian-corpus`
   checkouts during this session). A longer session risks losing commits.
2. **Rule #0.1** — consilium output never auto-deploys to prod. The UI
   changes (subscription_screen, landing badge, consent modal widget) need
   visual sign-off before they land in committed form.

### 4.1 Still to write (owner-approved scope)

**Phase 2 — consent logging** (Edge Function + widget)
- `supabase/functions/log-refund-consent/index.ts` + 5+ Deno tests
- IP hash via SHA-256 + server pepper; rate-limit 3/min.
- `lib/features/subscription/widgets/refund_consent_modal.dart` + 4+ widget tests
- Shown 1× when `first_message_at is null` after first paid AI send.
- Full-screen modal, RU/EN/ET copy, checkbox + "Начать" button.

**Phase 3 — message counting hook**
- Wire `increment_message_count()` RPC into `ai_service.dart` after each
  successful Claude response. File is FROZEN per voice_service rule — must
  be minimal call, guarded by `ref.read(currentUserProvider)?.tier == basic`.
- 3+ service tests for the hook.

**Phase 4 — Founder's Beta cap enforcement**
- Modify `supabase/functions/create-checkout/index.ts`: before creating
  Stripe session, read `app_config.beta_cap` + count `subscriptions where
  status='active'`; if full return 403 with waitlist CTA. 4+ Deno tests.
- New `supabase/functions/join-waitlist/index.ts` + 5+ Deno tests.

**Phase 5 — UI changes**
- `lib/features/settings/screens/subscription_screen.dart`: hide Pro tier
  card (keep code for v-next re-enable), add Founder's Beta badge, show
  "14-day refund or 7 AI responses — whichever comes first" below Basic.
- `index.html` landing: add beta badge near pricing block (must keep
  `landing.html` byte-identical to avoid repeat of 2026-04-20 outage —
  Rule #0.1).
- ARB strings in `lib/l10n/app_{en,ru,et,fi}.arb` + `flutter gen-l10n`.

**Phase 6 — legal copy**
- `app/docs/TERMS_OF_SERVICE.md`: rewrite "Refund Policy" section with
  the 14d-OR-7-responses language + Art. 16(m) citation.
- `app/docs/PRIVACY_POLICY.md`: add IP-hash note for `refund_consents`.

---

## 5. Owner Stripe Dashboard actions (do NOT delegate — owner only)

Per Rule #5 (don't auto-change external services) — the task lists these
for owner's checklist:

- [ ] In Stripe → Products → **Advocat Pro (€29.99)**: make sure the price
      is active but **no UI surfaces it** (we just hide the card, not the
      price). No deletion.
- [ ] In Stripe → Products → **Legal Counsel (€14.99)**: confirm price is
      active for monthly recurring EUR. Same as today — no change.
- [ ] Stripe webhook endpoint must forward `customer.subscription.created`
      (currently forwards `completed`/`updated`/`deleted`/`invoice.payment_failed`).
      Path: `https://okgnkucgwsytsondrjye.supabase.co/functions/v1/stripe-webhook`
      Event list: `checkout.session.completed`, `customer.subscription.created`,
      `customer.subscription.updated`, `customer.subscription.deleted`,
      `invoice.payment_failed`.

---

## 6. Supabase migrations — command

```bash
cd /Users/ai.place/Advocat/app/advocat_project
supabase db push --project-ref okgnkucgwsytsondrjye
```

Migrations applied in filename order. Each is idempotent. Expected
output: 5 new tables/alters, 1 RPC, 0 destructive statements.

---

## 7. No PR created (per task spec)

Branch is `feature/founder-beta-pricing`. To open the PR once Phases 2–6
are also done:

```bash
git push -u github feature/founder-beta-pricing
gh pr create \
  --base main \
  --title "feat: Founder's Beta pricing + refund policy" \
  --body-file docs/pricing-v2/FINAL.md
```

**Do NOT push or create the PR until all 6 phases are green.**

---

## 8. Safety notes for next session

- Other parallel agents were switching branches mid-session (see git
  reflog `HEAD@{1..10}`). Before resuming, run
  `git status && git branch --show-current` and verify you're on
  `feature/founder-beta-pricing` *before every* Write/Edit.
- `lib/services/ai_service.dart` is FROZEN — touch with surgical precision.
- `lib/services/voice_service.dart`, `supabase/functions/tts-proxy`,
  `supabase/functions/google-tts` are FROZEN — do NOT touch.
- `test/e2e/prod_smoke.sh` is currently modified by another session — do
  NOT commit that file from this branch.
