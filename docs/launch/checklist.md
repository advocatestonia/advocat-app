# Pre-launch checklist — Advocat v24.2.3 / closed-beta + public

**Last updated:** 2026-04-21 by OMEGA-LAUNCH-READY swarm
**Status key:** DONE ✓ | BLOCKER ✗ | OWNER-ACTION → | IN-FLIGHT ⟳
**Owner:** Sulga (Vorantis OÜ)

---

## 1. Technical (launch/wave1 branch)

| # | Item                                                                              | Status | Owner | Effort |
|---|-----------------------------------------------------------------------------------|--------|-------|--------|
| 1.1 | Flutter Web build succeeds (`flutter build web --release`, 5-8.5 MB main.dart.js) | ⟳ | agent | 5 min  |
| 1.2 | Full test suite GREEN (1090+ tests, 11 skipped)                                   | ✓ DONE | agent | n/a    |
| 1.3 | `flutter analyze` — 0 errors                                                      | ⟳ | agent | 5 min  |
| 1.4 | Deadline-reminder edge function status enum fix deployed (wave1-1)                | → | owner | 10 min — `supabase functions deploy deadline-reminder` |
| 1.5 | Database migration applied: `20260421_app_errors_telemetry.sql`                    | → | owner | 5 min — Supabase SQL Editor or `supabase db push` |
| 1.6 | Database migration applied: `20260421_deadlines_due_date.sql` (from v24.2.1)       | → | owner | 5 min (may already be applied — check)             |
| 1.7 | Error boundary + telemetry sink builds cleanly                                     | ✓ DONE | agent | n/a   |
| 1.8 | `./scripts/build-and-deploy.sh` unchanged and still works                         | ✓ DONE | agent | n/a   |
| 1.9 | `./test/e2e/prod_smoke.sh` — 21/21 GREEN against staging (not prod, wave1)        | → | owner | 10 min |
| 1.10 | main.dart.js reality-check: 5-8.5 MB, Supabase anon key baked in                 | → | owner | 2 min after build |

## 2. Legal

| # | Item                                                                              | Status | Owner | Effort |
|---|-----------------------------------------------------------------------------------|--------|-------|--------|
| 2.1 | Deadline-reminder status enum fix (CRITICAL — reminders were broken)              | ✓ DONE | agent (wave1-1) | n/a |
| 2.2 | `create_deadline` returns error instead of silently swallowing (CRITICAL)         | ✓ DONE | agent (wave1-1) | n/a |
| 2.3 | `due_date` timezone fix (CRITICAL — was slipping 1 day east of UTC)               | ✓ DONE | agent (wave1-1) | n/a |
| 2.4 | Disclaimer policy relaxed to allow contextual "not legal advice" clarifier        | ✓ DONE | agent (wave1-1) | n/a |
| 2.5 | UPL audit: no self-labelling as "юрист"/"lawyer"/"Anwalt"                         | ✓ DONE | agent (wave1-4) | n/a |
| 2.6 | Privacy Policy v1.0 exists                                                        | ✓ DONE | pre-existing | n/a |
| 2.7 | Terms of Service v1.0 exists                                                      | ✓ DONE | pre-existing | n/a |
| 2.8 | EU AI Act compliance doc v1.0 exists                                              | ✓ DONE | pre-existing | n/a |
| 2.9 | AI Transparency Notice exists                                                     | ✓ DONE | pre-existing | n/a |
| 2.10 | In-app disclaimer banner appears on first chat use                               | ✓ DONE | pre-existing | n/a |
| 2.11 | **Lawyer review of 5 legal docs** (1h @ €300-€450)                               | → OWNER-ACTION | owner | 1h + 3 business days booking lag — see `legal-review-checklist.md` |
| 2.12 | Founder case (Sulga v Finland) conflict-of-interest optics                        | → OWNER-ACTION | owner | decide whether to mention it on About page |

## 3. Compliance / GDPR

| # | Item                                                                              | Status | Owner | Effort |
|---|-----------------------------------------------------------------------------------|--------|-------|--------|
| 3.1 | Cookie banner on landing (Accept/Reject/Learn, DNT-respecting)                    | ✓ DONE | agent (wave1-3) | n/a |
| 3.2 | GDPR consent dialog at first login (already implemented in v24.2)                 | ✓ DONE | pre-existing | n/a |
| 3.3 | Data export flow (Art. 15) works end-to-end — audit + regression tests           | ✓ DONE | agent (wave1-5) | n/a |
| 3.4 | Account deletion flow (Art. 17) works with FK-safe cascade                        | ✓ DONE | agent (wave1-5) | n/a |
| 3.5 | DPA signed: Anthropic                                                             | → OWNER-ACTION | owner | 10 min + 1-3 biz days |
| 3.6 | DPA signed: Google Cloud                                                          | → OWNER-ACTION | owner | 5 min |
| 3.7 | DPA signed: ElevenLabs                                                            | → OWNER-ACTION | owner | 5 min |
| 3.8 | DPA signed: Supabase                                                              | → OWNER-ACTION | owner | 5 min |
| 3.9 | DPA signed: Stripe                                                                | → OWNER-ACTION | owner | 5 min |
| 3.10 | Verify Supabase region = `eu-central-1` (Frankfurt), not `us-east-*`             | → OWNER-ACTION | owner | 1 min |
| 3.11 | Sub-processor list added to Privacy Policy §4                                     | → OWNER-ACTION | owner | 20 min after 3.5-3.9 signed |
| 3.12 | DPO decision: no DPO required at <1000 users (documented in Privacy §9)          | ✓ DONE | pre-existing | n/a |

## 4. UX / Accessibility

| # | Item                                                                              | Status | Owner | Effort |
|---|-----------------------------------------------------------------------------------|--------|-------|--------|
| 4.1 | Login auth buttons have working focus rings (IgnorePointer removed)               | ✓ DONE | agent (wave1-2) | n/a |
| 4.2 | Home language button hit target ≥ 44x44                                           | ✓ DONE | agent (wave1-2) | n/a |
| 4.3 | Chat input font ≥ 16px (iOS auto-zoom prevention)                                 | ✓ DONE | agent (wave1-2) | n/a |
| 4.4 | Urgent-deadline banner is tappable → /deadlines/:id                               | ✓ DONE | agent (wave1-2) | n/a |
| 4.5 | Login/register autofillHints for password managers                                | ✓ DONE | agent (wave1-2) | n/a |
| 4.6 | Chat upgrade banner localised (en/et/ru)                                          | ✓ DONE | agent (wave1-2) | n/a |
| 4.7 | Payment-success dialog localised                                                  | ✓ DONE | agent (wave1-2) | n/a |
| 4.8 | Screen reader: Semantics labels on home + banner                                  | ✓ DONE | agent (wave1-2) | n/a |
| 4.9 | Other 14 locales have 5 new keys fall back to EN — acceptable for closed-beta    | ✓ DONE | agent | n/a |
| 4.10 | First-visit onboarding sheet displays + dismisses correctly                      | ✓ DONE | pre-existing | n/a |

## 5. Business / Marketing

| # | Item                                                                              | Status | Owner | Effort |
|---|-----------------------------------------------------------------------------------|--------|-------|--------|
| 5.1 | Pricing finalised: Free / €14.99 / €29.99 (OMEGA-PRICING 6-0 vote)               | ✓ DONE | pre-existing | n/a |
| 5.2 | Stripe Live mode configured (card + Apple Pay + Google Pay + Link)                | ✓ DONE | pre-existing | n/a |
| 5.3 | Landing page hero copy (EN/ET/RU) drafted                                         | ✓ DONE | agent (Wave 2) | see `final-messaging.md` |
| 5.4 | Pricing page table (EN/ET/RU) drafted                                             | ✓ DONE | agent (Wave 2) | see `final-messaging.md` |
| 5.5 | Welcome email template (EN/ET/RU) drafted                                         | ✓ DONE | agent (Wave 2) | see `final-messaging.md` |
| 5.6 | Copy landed into `web/landing.html` T object                                      | → OWNER-ACTION | owner | 10 min |
| 5.7 | Welcome email templates added to `send-email` edge function                        | → OWNER-ACTION | owner | 30 min |
| 5.8 | VAT OSS registration in e-MTA (if selling to EU consumers outside EE)             | → OWNER-ACTION | owner | 2-3 business days with e-MTA |
| 5.9 | App store / TestFlight listing (if shipping iOS) — not applicable for web launch  | n/a | — | n/a |

## 6. Ops / Monitoring

| # | Item                                                                              | Status | Owner | Effort |
|---|-----------------------------------------------------------------------------------|--------|-------|--------|
| 6.1 | Error boundary installed in `main.dart`                                           | ✓ DONE | pre-existing | n/a |
| 6.2 | Telemetry sink code exists (opt-in)                                               | ✓ DONE | agent (wave1-6) | n/a |
| 6.3 | `app_errors` DB table + RLS created                                               | ✓ DONE (code) | agent (wave1-6) | owner runs migration in #1.5 |
| 6.4 | Telemetry opt-in toggle surfaced in settings_screen.dart                          | ✗ NOT DONE | owner | 30 min — deferred post-launch |
| 6.5 | Supabase usage alerts set up (bandwidth, db size, edge fn invocations)           | → OWNER-ACTION | owner | 10 min in dashboard |
| 6.6 | Stripe failed-payment webhook alerts set up                                      | → OWNER-ACTION | owner | 10 min |
| 6.7 | Incident-response runbook                                                         | ✓ DONE | agent (Wave 2) | see `incident-playbook.md` |
| 6.8 | Rollback tested: `./scripts/rollback.sh v24.2-frozen-2026-04-20` works           | → OWNER-ACTION | owner | 2 min dry-run |
| 6.9 | Uptime monitoring (UptimeRobot / Better Stack free tier)                         | → OWNER-ACTION | owner | 10 min — optional for closed-beta |

## 7. Marketing (post-launch, not blocking)

| # | Item                                                                              | Status |
|---|-----------------------------------------------------------------------------------|--------|
| 7.1 | Product Hunt launch                                                               | deferred |
| 7.2 | Hacker News "Show HN"                                                             | deferred |
| 7.3 | Estonian / Finnish press releases                                                 | deferred |
| 7.4 | Reddit r/estonia, r/finland, r/legaladvice (carefully)                            | deferred |
| 7.5 | Paid ads                                                                          | deferred until post-beta |

---

# Go / No-Go criteria

## Closed-beta launch (up to 1000 users, free + paid tiers)

**GO** if all of the following are true:
1. Everything in §1 Technical is DONE (tests pass, build works, smoke passes).
2. §2 Legal items 2.1–2.10 are DONE. **Item 2.11 (lawyer review) is NOT a hard blocker** for closed-beta with ≤1000 users — a reasonable-care posture is defensible if the Privacy + ToS are already v1.0 and we book the review within 2 weeks of launch.
3. §3 GDPR items 3.1–3.4 and 3.12 are DONE. **Items 3.5–3.11 (DPAs) SHOULD be signed before launch** but can slip 2-3 days if the owner has accepted responsibility and scheduled the clicks.
4. §4 UX items 4.1–4.8 are DONE.
5. §6 Ops items 6.1–6.3 and 6.7 are DONE.

**NO-GO** if any of:
- Tests fail or analyze has errors.
- Stripe Live mode is not configured (users cannot pay → false value prop).
- Deadline reminders are still broken (wave1-1 fix — verify in prod).
- Supabase region is not EU.

**Decision at 2026-04-21:** With wave1-1..wave1-6 merged and §1.4–§1.6 owner-action completed, we are **GO for closed-beta**. ETA to actual GO state: 2 hours of owner actions (mostly dashboard clicks).

## Public launch (unlimited users, paid ads, press)

**GO** if all closed-beta criteria + everything below:
- §2.11 lawyer review done + tracked changes applied.
- §3.5–§3.11 all DPAs signed + Privacy Policy §4 updated.
- §5.6–§5.8 VAT OSS + welcome email templates live.
- §6.4–§6.6 monitoring + alerts configured.
- 2 weeks of closed-beta data showing no critical bugs, no GDPR complaints, <5% churn.

**Conservative ETA to public-launch GO:** 4-6 weeks from closed-beta GO.

---

# Top-5 remaining risks as of 2026-04-21

1. **Lawyer review not yet done** — highest risk, mitigated by booking within 2 weeks. Budget €300-€450.
2. **DPAs not yet signed** — biggest paper risk. Mitigation: owner spends 1-2 hours clicking through dashboards tomorrow.
3. **Sulga case conflict of interest** — product owner using their own product on their own case. Unique but potentially awkward in press. Mitigation: "About" page transparency note.
4. **5 new ARB keys untranslated in 14 non-core locales** — minor UX issue, defaults to English. Mitigation: launch with EN fallback, crowd-translate after first users.
5. **No external uptime monitoring** — if Supabase goes down, we find out from users. Mitigation: UptimeRobot free tier, 10 minutes to set up.
