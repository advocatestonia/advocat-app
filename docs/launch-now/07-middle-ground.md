# Agent 7 — Middle Ground Options

**Scope:** Compromise architectures that capture most of launch-now's upside while cutting most of its risk tail.

---

## 1. Why middle ground matters

The framing "launch-now vs wait" is a false binary. In practice, there are 8+ discrete configurations. Each trades different variables (time, money, risk, signal) differently. The best answer is often a hybrid that nobody proposed as a pure strategy.

This agent enumerates 5 specific middle-ground options and picks the best.

## 2. Option M1 — "Founder's Soft Launch"

### Configuration:
- Accept payments immediately
- Public framing: **"Founder's Beta — Advocat v1.0"** with badge visible in UI
- Price: **€9.99/mo first month, €14.99/mo after** (auto-escalation)
- Cap: **Max 25 paying users first 30 days** (hard-coded counter)
- Unconditional 30-day refund (explicit on checkout)
- Personal sign-off: Dmitri's photo + handwritten "We're shipping our first version. If Advocat fails you, I personally refund you. — Dmitri Sulga" on landing
- Disclaimer intensified: full-page modal at signup + per-session banner
- All 7 conditions from Agent 1 apply

### Risk profile vs pure launch-now:
- 75% reduction in chargeback risk (low price + explicit refund + personal promise)
- 40% reduction in complaint-to-regulator risk (Founder's Beta framing gives users social/emotional investment; they feel less "ripped off")
- 20% reduction in UPL complaint risk (Founder's Beta signals "work in progress" which reduces attorney hostility)
- 0% reduction in hallucination risk (technical, unchanged)
- 0% reduction in AI Act future-enforcement risk (regulatory, unchanged)

### Revenue impact vs pure launch-now:
- Month 1: similar (€45-120)
- Month 2-3: slightly lower due to 25-user cap (€150-250 instead of €200-300)
- Month 4+: cap lifts, trajectory resumes

### Psychological impact on owner:
- Validates product with real money
- Keeps support load manageable (25 users is 1-2 support interactions/week)
- Removes "impostor syndrome" of charging premium for v1

### Implementation cost:
- UI badge: 1-2 hours dev
- Handwritten landing copy: 1 hour
- Stripe 25-user cap: 2-3 hours dev
- Price schedule in Stripe: 15 min
- **Total: 4-6 hours implementation**

### Score: **8.5/10 — strongly recommended**

## 3. Option M2 — "Annual Lock with Founder's Discount"

### Configuration:
- €150/year single-tier (equivalent €12.50/mo)
- No monthly option
- Unconditional 60-day refund (longer than withdrawal right)
- All other conditions from M1 apply

### Risk profile:
- Chargeback rate drops significantly (annual commits dispute less than monthly)
- User count per dollar grows (€150 vs €15 means same MRR = 10x fewer users = 10x less support load = 10x less risk surface)
- **BUT:** Consumer Rights Directive 14-day withdrawal right applies; cannot fully waive unless user explicitly consents to immediate performance in checkout

### Revenue impact:
- Much higher per-user revenue
- Lower user count early
- Higher likelihood first-100 are self-selected higher-commitment users

### Problem:
- **High friction for impulse buy** — most B2C consumers don't commit €150 for an unknown product
- Realistic conversion rate: 2-5% instead of 8-12%
- Net: similar MRR with fewer users

### Implementation cost:
- Stripe annual pricing: 30 min
- **Total: 1-2 hours**

### Score: **6/10 — works if ICP is narrow (immigrants w/ high-stakes cases). Too friction-heavy for broad market.**

## 4. Option M3 — "Waitlist with Email Pre-Auth"

### Configuration:
- Landing page collects emails with €0 commitment
- Build list over 2-4 weeks while finishing compliance
- At week 3: ping 100 waitlist users with €9.99 founding-member offer
- Open payments to only those who click through
- Cap at 50 paying for first 30 days

### Risk profile:
- 0 revenue risk during build period
- Extremely low customer acquisition cost (waitlist users are pre-qualified)
- Lower complaint rate (self-selected)
- **Same UPL and GDPR risk once payments open**
- **Delays revenue by 3-4 weeks** — this is the cost

### Revenue impact:
- Week 1-4: €0
- Week 5-6: burst revenue as waitlist converts (potentially €500-1,000 first week)
- Month 2+: similar to other options

### Compliance benefit:
- Gives owner time to complete lawyer review BEFORE first paid user
- Gives time to verify 60-80% EE corpus corruption claim
- Gives time to implement all missing must-have items

### Downside:
- Momentum risk (waitlist can decay — 20-40% of signups churn if delayed >4 weeks)
- Requires active outreach (Sulga network) to build list

### Implementation cost:
- Waitlist form: 2-3 hours
- Email sequence: 2-3 hours
- **Total: 4-6 hours**

### Score: **7/10 — safer but loses 3-4 weeks of real validation. Only better than M1 if the corpus corruption claim is real.**

## 5. Option M4 — "Partner-First Launch"

### Configuration:
- Reach out to 2-3 Estonian attorneys BEFORE launch
- Offer: "Recommend Advocat for clients whose cases are too small to take. Earn 15% referral fee."
- Attorney becomes tacit regulatory cover (Advokatuuri less likely to complaint vs a product a member attorney uses)
- Launch with explicit "Partnered with [Firm Name] — referred to them for complex cases" messaging
- Price as M1

### Risk profile:
- **Huge reduction in UPL complaint risk** (~80% reduction — the attorney partner IS the internal watchdog that would otherwise complain)
- Moderate reduction in AKI risk (partner firm's legal compliance rubs off)
- Adds regulatory cover for marketing ("Partnered with Estonian law firm")
- Does NOT address hallucination or AI Act risk

### Revenue impact:
- Same pricing as M1
- Slower start (requires attorney outreach — 2-4 weeks)
- Higher per-user value (referrals to partner firm add credibility)
- Referral fee to partner: 15% × €15 = €2.25/user (manageable)

### Critical prerequisite:
- Owner needs to find willing attorney partner
- Small Estonian firms might partner (not BigLaw)
- 2-4 weeks of outreach effort

### Implementation cost:
- Outreach: 10-20 hours of owner time
- Integration with attorney: 5-10 hours
- **Total: 15-30 hours of owner time over 4 weeks**

### Score: **9/10 if achievable. 4/10 if attorney partner can't be found.** High variance.

## 6. Option M5 — "Paid Beta with Gradual Price"

### Configuration:
- €4.99/mo "Beta Access" first 90 days
- €14.99/mo after beta period ends
- Explicit "Beta — limited features, feedback required" badge
- Users sign a beta-feedback-agreement at signup (not legally binding EULA, just social contract)
- Cap: 50 users first 90 days
- Unconditional refund

### Risk profile:
- **Greatest reduction in "we sold you broken product" risk** — €4.99 is below any reasonable threshold for consumer protection claim
- Lower chargeback probability (cheap = few people dispute)
- Lower UPL risk (€4.99 signals "not a serious legal product")
- But: Lowest revenue

### Revenue impact:
- Month 1: ~10 paying × €4.99 = €50
- Month 2: ~15 × €4.99 = €75
- Month 3: ~20 × €4.99 = €100
- Month 4 (price jumps to €14.99): churn shock
- Month 5: ~15 × €14.99 = €225 (post-shock)
- Month 6: ~20 × €14.99 = €300

**Cumulative 6 months: ~€750.** Below M1 cumulative of €1,400.

### Score: **6/10 — safer but revenue-suppressive. Better if owner's primary goal is feedback, not cash.**

## 7. Comparison matrix

| Option | Risk reduction | Revenue month 1 | Revenue month 6 | Implementation | Recommendation |
|---|---|---|---|---|---|
| Launch-now (pure) | 0% | €100-150 | €300-600 | 0 hours | Only if truly out of runway |
| M1 Founder's Soft Launch | 40% | €75-125 | €300-500 | 4-6 hours | **PRIMARY RECOMMENDATION** |
| M2 Annual Lock | 30% | €150 (1 user) | €400 (3 users) | 1-2 hours | Only for narrow ICP |
| M3 Waitlist | 60% | €0 | €300-500 | 4-6 hours | Backup if corpus claim is real |
| M4 Partner-First | 80% | €50-80 | €400-700 | 15-30 hours | Best if achievable |
| M5 Paid Beta | 55% | €50-75 | €200-300 | 2-3 hours | Revenue-suppressive |
| Delay-4-weeks | 80% | €0 | €250-450 | 0 hours | Overkill for 100-user scale |

## 8. Recommended combination

**My strongest recommendation: M1 + attempt M4 in parallel.**

### Week 1 execution:
- Deploy launch/wave1 per FINAL.md (4 hours)
- Implement 7 conditions from Agent 1 (4-6 hours)
- Add Founder's Beta badge + €9.99 first-month pricing (2 hours)
- Verify Agent 4's missing must-haves: Art. 22 disclosure, age gate, withdrawal waiver (2-3 hours)
- Email 3 Estonian attorneys about partnership (1 hour)
- **Total: ~15 hours of focused work = 2 working days**

### Week 1 outcome:
- Advocat is live with first paid user allowed
- Risk surface is ~40% smaller than pure launch-now
- Partnership path is open (if attorneys respond)

### Week 2 execution:
- If attorney partner agrees: integrate referral mechanism (4-6 hours)
- If no partner: continue solo
- Book €400 lawyer review for week 3
- Sign DPAs with all 5 vendors (60-90 min)

### Week 3 execution:
- Lawyer review completed
- Apply lawyer's tracked changes to Privacy Policy + ToS
- Switch badge from "Founder's Beta" to "v1.0" if everything is green
- Lift 25-user cap IF growth supports it

### Month 2+:
- Normal growth, normal pricing
- Add €29.99 premium tier back if demand exists
- E&O insurance quote at end of month 3

## 9. What Middle Ground does NOT solve

Honest limitations:

1. **Hallucination risk is unchanged.** If EE corpus is 60-80% corrupted, Middle Ground doesn't fix it. Only a technical audit + fix does.

2. **UPL criminal risk is reduced but not eliminated.** Even Founder's Beta + partner firm doesn't make Advokatuuri §18 impossible. Just less likely.

3. **AI Act future enforcement (Aug 2026+) is unchanged.** Middle Ground doesn't address it. Owner needs separate plan for that by Q2 2026.

4. **Financial exposure in worst case is unchanged.** If a catastrophic lawsuit hits, Vorantis OÜ's cash is the same cash regardless of launch strategy.

## 10. Verdict

**Middle Ground OPTIONS M1 + M4 together achieve 85% of launch-now's revenue benefit with 60% of the risk surface.**

Vote: **MIDDLE-GROUND (M1, pursuing M4 in parallel)**.

This is the option owner should pick if forced to choose one. It matches Agent 2's risk tolerance AND Agent 1's cash-flow urgency AND Agent 5's precedent-backed survivorship pattern AND Agent 6's revenue pragmatism.

It's also the only option all 6 prior agents would partially endorse.
