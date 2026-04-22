# Launch readiness scorecard v2

**Date:** 2026-04-21
**Branch:** `launch/wave1`
**Versus baseline:** OMEGA-SEC (Grade B), OMEGA-COMPLIANCE (25%), OMEGA-UX (62%), OMEGA-BUSINESS (56/100)

Each dimension scored **0-100**. Overall = weighted average.

| Dimension          | Weight | Before Wave 1 | After Wave 1 | Notes                                        |
|--------------------|--------|---------------|---------------|----------------------------------------------|
| Technical          | 20%    | 78            | **88**        | +10: wave1-1 CRITICAL legal fixes, +1 migration, +18 tests, 0 regressions |
| Legal              | 20%    | 60            | **80**        | +20: 4 CRITICAL fixes + UPL audit + lawyer-review checklist ready |
| Compliance / GDPR  | 15%    | 55            | **78**        | +23: cookie banner, GDPR Art. 15/17 regression lock, DPA checklist ready |
| UX / Accessibility | 15%    | 62            | **84**        | +22: 7 Tier-A fixes (focus rings, 44×44, iOS no-zoom, autofill, localised paywall) |
| Business           | 15%    | 56            | **72**        | +16: final messaging (EN/ET/RU) drafted, checklist done, pricing locked |
| Ops                | 15%    | 60            | **76**        | +16: error boundary + opt-in telemetry framework + incident playbook |
| **Overall**        | 100%   | **63**        | **80**        | **+17 points** |

---

## Closed-beta readiness (up to 1000 users)

**Verdict: GO — pending ~2 hours of owner-action clicks.**

All technical, UX, and compliance **code** is in place. The gap between "code ready" and "users can sign up" is:

1. Apply 1 migration (5 minutes — `supabase db push`).
2. Deploy 1 updated edge function (10 minutes — `supabase functions deploy deadline-reminder`).
3. Build + deploy with `./scripts/build-and-deploy.sh` (10 minutes).
4. Run `./test/e2e/prod_smoke.sh` — expect 21/21 (10 minutes).
5. Sign 5 DPAs in provider dashboards (60-90 minutes — *technically* not blocking but strongly recommended before real users arrive).

**Total owner time to GO:** 100-120 minutes. Can launch closed-beta **same day** the owner commits to these steps.

## Public-launch readiness (unlimited, paid ads)

**Verdict: NO-GO — 4-6 weeks out.**

Additional blockers for public launch:
- Lawyer review of Privacy + ToS (1h @ €300-€450, 1-2 weeks calendar lag).
- 2 weeks of closed-beta telemetry to validate no critical GDPR / churn / cost issues.
- VAT OSS registration in e-MTA (2-3 business days).
- Uptime monitoring set up.
- Telemetry opt-in toggle surfaced in Settings UI.
- Welcome email templates shipped in `send-email` edge function.

---

## Top-5 remaining risks (unchanged from checklist.md, restated for clarity)

1. **Lawyer review not yet done** — highest risk; mitigation = book within 2 weeks of closed-beta.
2. **DPAs not yet signed** — biggest paper risk; mitigation = 1-2h of owner clicks.
3. **Sulga case conflict of interest** — product owner using own product on own case; mitigation = transparency note in About.
4. **Untranslated ARB keys in 14 non-core locales** — falls back to EN; mitigation = crowd-translate post-launch.
5. **No external uptime monitoring** — mitigation = UptimeRobot free tier (10 min).

## What went unexpectedly well

- **GDPR export/delete flows already fully implemented** — audit-only lift, zero new code needed.
- **Error boundary already existed from army/wave3-c3** — we only had to wire the sink.
- **Existing `.arb` infrastructure** — localising the paywall took 20 minutes, not 2 hours.
- **1068 → 1090 tests with 0 regressions** — clean TDD discipline paid off.
